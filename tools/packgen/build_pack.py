"""地域データパック生成オーケストレータ。

使い方:
  python -m packgen.build_pack --region tokyo
  python -m packgen.build_pack --all

生成物: tools/out/<region>/pack.sqlite（§14 スキーマ + metadata）
"""
from __future__ import annotations

import argparse
import json
import logging
import sqlite3
import subprocess
import sys
import zipfile
from datetime import datetime, timezone
from pathlib import Path

import requests

from packgen.config import (
    ALLOWED_MISSING_HAZARDS,
    DEM_PREFLIGHT_URL,
    ELEVATION_SOURCE,
    HAZARD_SERIES,
    OSM_PBF_URL,
    OSM_SOURCE,
    REGIONS,
    SHELTERS_SOURCE,
    SHELTERS_URL,
    STORM_SURGE_SERIES,
    TSUNAMI_SERIES,
    Region,
    hazard_url,
)
from packgen.download import DownloadError, download
from packgen.elevation import ElevationProvider
from packgen.hazard import (
    cell_id_for,
    import_flood_gml,
    import_landslide_gml,
    import_storm_surge_gml,
    import_tsunami_gml,
)
from packgen.osm_graph import populate_graph
from packgen.schema import init_db
from packgen.shelters import import_shelters_csv
from packgen.snap import snap_shelters_to_nodes
from packgen.validate_pack import validate_pack

TOOLS_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = TOOLS_DIR / "data"
OUT_DIR = TOOLS_DIR / "out"

# 標高取得の失敗率上限（超えたらビルド NG）
ELEVATION_FAILURE_RATE_THRESHOLD = 0.10
# 標高 NULL 率の上限（validate_pack で検査）
ELEVATION_NULL_RATE_THRESHOLD = 0.10

logging.basicConfig(
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    level=logging.INFO,
)
logger = logging.getLogger("packgen.build")


def log(msg: str) -> None:
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}", flush=True)


def preflight_dem() -> None:
    """DEM タイル配信サーバへの疎通を確認する（1 タイルだけ取得）。"""
    log(f"標高タイル疎通確認: {DEM_PREFLIGHT_URL}")
    try:
        resp = requests.get(DEM_PREFLIGHT_URL, timeout=15)
    except requests.RequestException as e:
        raise RuntimeError(f"DEM プリフライト失敗（ネットワーク不可）: {e}") from e
    if resp.status_code >= 400:
        raise RuntimeError(
            f"DEM プリフライト失敗: HTTP {resp.status_code} ({DEM_PREFLIGHT_URL})"
        )
    log(f"DEM プリフライト OK（{len(resp.content)} bytes）")


def ensure_osm_extract(region: Region) -> Path:
    """全国 PBF を取得し、県 bbox で切り出した PBF を返す（キャッシュあり）。"""
    pbf = DATA_DIR / "japan-latest.osm.pbf"
    if not pbf.exists():
        log("全国 OSM PBF をダウンロード中（約 2.5GB）...")
        download(OSM_PBF_URL, pbf)
    out = DATA_DIR / f"region-{region.key}.osm.pbf"
    if out.exists():
        return out
    min_lng, min_lat, max_lng, max_lat = region.bbox
    log(f"{region.key}: bbox 切り出し {region.bbox}")
    subprocess.run(
        [
            "osmium", "extract",
            "-b", f"{min_lng},{min_lat},{max_lng},{max_lat}",
            "-s", "complete_ways",
            "-o", str(out), "--overwrite",
            str(pbf),
        ],
        check=True,
    )
    return out


def _gml_files(zip_path: Path, dest_dir: Path) -> list[Path]:
    dest_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(zip_path) as z:
        z.extractall(dest_dir)
    return sorted(p for p in dest_dir.rglob("*") if p.suffix.lower() in (".xml", ".gml"))


def _fill_elevations(
    db: sqlite3.Connection, provider: ElevationProvider, region: Region
) -> None:
    """shelters / nodes / hazard_grid の elevation_m をバッチで埋める。"""
    targets = [
        ("shelters", "rowid"),
        ("nodes", "id"),
        ("hazard_grid", "cell_id"),
    ]
    for table, idcol in targets:
        if table == "hazard_grid":
            rows = db.execute(
                f"SELECT {idcol} FROM {table} WHERE elevation_m IS NULL"
            ).fetchall()
            points = []
            ids = []
            from packgen.hazard import cell_center
            for (cid,) in rows:
                lat, lng = cell_center(cid)
                ids.append(cid)
                points.append((lat, lng))
        else:
            rows = db.execute(
                f"SELECT {idcol}, lat, lng FROM {table} WHERE elevation_m IS NULL"
            ).fetchall()
            ids = [r[0] for r in rows]
            points = [(r[1], r[2]) for r in rows]
        if not ids:
            continue
        log(f"{region.key}: {table} の標高取得（{len(ids)} 件）...")
        done = 0
        chunk = 100_000
        for i in range(0, len(ids), chunk):
            sub_ids = ids[i : i + chunk]
            values = provider.batch_elevation(points[i : i + chunk])
            with db:
                db.executemany(
                    f"UPDATE {table} SET elevation_m = ? WHERE {idcol} = ?",
                    ((v, k) for k, v in zip(sub_ids, values) if v is not None),
                )
            done += len(sub_ids)
            log(
                f"{region.key}: {table} 標高 {done}/{len(ids)} "
                f"(fetch success={provider.success_count} "
                f"fail={provider.failure_count} "
                f"missing={provider.missing_count})"
            )


def _apply_edge_hazards(db: sqlite3.Connection) -> int:
    """エッジ中点のグリッドセルから hz_* 属性を付与する（§9.2 事前計算）。"""
    grid = {}
    for row in db.execute(
        "SELECT cell_id, flood_depth_m, tsunami_depth_m, landslide_class,"
        " storm_surge_m, volcano_class FROM hazard_grid"
    ):
        grid[row[0]] = row[1:]
    if not grid:
        return 0
    nodes = {
        r[0]: (r[1], r[2])
        for r in db.execute("SELECT id, lat, lng FROM nodes")
    }

    def depth_class(m: float | None) -> int:
        if not m or m <= 0:
            return 0
        if m < 0.5:
            return 1
        if m < 3.0:
            return 2
        if m <= 5.0:
            return 3
        return 4

    updated = 0
    with db:
        for eid, a, b in db.execute("SELECT id, from_node, to_node FROM edges"):
            pa, pb = nodes.get(a), nodes.get(b)
            if not pa or not pb:
                continue
            mid = ((pa[0] + pb[0]) / 2, (pa[1] + pb[1]) / 2)
            cell = grid.get(cell_id_for(*mid))
            if not cell:
                continue
            flood, tsunami, landslide, surge, volcano = cell
            db.execute(
                """
                UPDATE edges SET hz_flood_depth=?, hz_tsunami_depth=?, hz_landslide=?,
                  hz_storm_surge=?, hz_volcano=? WHERE id=?
                """,
                (
                    depth_class(flood),
                    depth_class(tsunami),
                    int(landslide or 0),
                    1 if (surge or 0) > 0 else 0,
                    int(volcano or 0),
                    eid,
                ),
            )
            updated += 1
    return updated


def _download_and_import_hazard(
    db: sqlite3.Connection,
    dataset: str,
    series: str,
    label: str,
    pref_code: str,
    importer,
    kind: str,
    notes: list[str],
    sources: list[str],
    region_key: str,
) -> int:
    zip_path = DATA_DIR / "hazard" / f"{series}_{pref_code}.zip"
    try:
        if not zip_path.exists():
            download(hazard_url(dataset, series, pref_code), zip_path)
    except DownloadError as e:
        notes.append(f"{kind}: 取得失敗（{e}）")
        return 0
    dest = DATA_DIR / "hazard" / f"{series}_{pref_code}"
    cells = 0
    for gml in _gml_files(zip_path, dest):
        cells += importer(db, gml)
    log(f"{region_key}: {kind} グリッド {cells} セル")
    sources.append(label)
    return cells


def build_region(region: Region, *, skip_download: bool = False) -> dict:
    out_dir = OUT_DIR / region.key
    out_dir.mkdir(parents=True, exist_ok=True)
    pack = out_dir / "pack.sqlite"
    if pack.exists():
        pack.unlink()
    db = init_db(pack)
    sources: list[str] = []
    notes: list[str] = []

    # 1. 避難所
    csv_path = DATA_DIR / "shelters" / "mergeFromCity_2.csv"
    if not csv_path.exists():
        log("指定緊急避難場所 全国 CSV をダウンロード中...")
        download(SHELTERS_URL, csv_path)
    count = import_shelters_csv(db, csv_path, prefecture_names=(region.pref_name,))
    log(f"{region.key}: 避難所 {count} 件")
    sources.append(SHELTERS_SOURCE)

    # 2. 道路グラフ
    extract = ensure_osm_extract(region)
    log(f"{region.key}: 道路グラフ構築中...")
    populate_graph(db, extract)
    n_nodes = db.execute("SELECT COUNT(*) FROM nodes").fetchone()[0]
    n_edges = db.execute("SELECT COUNT(*) FROM edges").fetchone()[0]
    log(f"{region.key}: ノード {n_nodes} / エッジ {n_edges}")
    sources.append(OSM_SOURCE)

    # 3. ハザードグリッド
    # 3-1. 全県共通（洪水・土砂）
    hazard_importers = {
        "flood": import_flood_gml,
        "landslide": import_landslide_gml,
    }
    for kind, (dataset, series, label) in HAZARD_SERIES.items():
        _download_and_import_hazard(
            db, dataset, series, label, region.pref_code,
            hazard_importers[kind], kind, notes, sources, region.key,
        )
    # 3-2. 高潮（A49、県別シリーズ）
    if region.key in STORM_SURGE_SERIES:
        dataset, series, label = STORM_SURGE_SERIES[region.key]
        _download_and_import_hazard(
            db, dataset, series, label, region.pref_code,
            import_storm_surge_gml, "storm_surge", notes, sources, region.key,
        )
    else:
        notes.append("storm_surge: 国土数値情報に当該県の高潮データ無し（0 埋め）")
    # 3-3. 津波（A40、県別シリーズ）
    if region.key in TSUNAMI_SERIES:
        dataset, series, label = TSUNAMI_SERIES[region.key]
        _download_and_import_hazard(
            db, dataset, series, label, region.pref_code,
            import_tsunami_gml, "tsunami", notes, sources, region.key,
        )
    else:
        notes.append("tsunami: 国土数値情報に当該県のデータ無し（0 埋め）")

    # 4. 標高
    provider = ElevationProvider(DATA_DIR / "dem")
    _fill_elevations(db, provider, region)
    stats = provider.stats()
    log(f"{region.key}: 標高取得統計 {stats}")
    if stats["failure_rate"] > ELEVATION_FAILURE_RATE_THRESHOLD:
        raise RuntimeError(
            f"{region.key}: 標高タイル取得失敗率 {stats['failure_rate']:.1%} が閾値 "
            f"{ELEVATION_FAILURE_RATE_THRESHOLD:.0%} を超過しました。ネットワーク/エンドポイント要確認。"
        )
    sources.append(ELEVATION_SOURCE)

    # 5. 避難所 → 最近傍ノード
    snapped = snap_shelters_to_nodes(db)
    log(f"{region.key}: 避難所スナップ {snapped} 件")

    # 6. エッジへのハザード属性付与
    updated = _apply_edge_hazards(db)
    log(f"{region.key}: ハザード属性付与エッジ {updated} 件")

    # 7. メタデータ
    with db:
        db.executemany(
            "INSERT OR REPLACE INTO metadata (key, value) VALUES (?, ?)",
            [
                ("region", region.key),
                ("pref_name", region.pref_name),
                ("generated_at", datetime.now(timezone.utc).isoformat()),
                ("schema", "spec-§14 v1"),
                ("sources", json.dumps(sources, ensure_ascii=False)),
                ("notes", json.dumps(notes, ensure_ascii=False)),
                ("bbox", json.dumps(region.bbox)),
                ("elevation_stats", json.dumps(stats)),
            ],
        )
    db.commit()
    db.close()

    report = validate_pack(
        pack,
        elevation_null_rate_threshold=ELEVATION_NULL_RATE_THRESHOLD,
        allowed_missing_hazards=list(ALLOWED_MISSING_HAZARDS.get(region.key, ())),
    )
    report["notes"] = notes
    report["elevation_fetch_stats"] = stats
    (out_dir / "report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2)
    )
    log(f"{region.key}: 完了 ok={report['ok']} → {pack}")
    return report


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="地域データパック生成")
    parser.add_argument("--region", choices=sorted(REGIONS), help="対象県")
    parser.add_argument("--all", action="store_true", help="全県生成")
    parser.add_argument(
        "--skip-dem-preflight", action="store_true",
        help="DEM 疎通チェックをスキップ（オフラインテスト用）",
    )
    args = parser.parse_args(argv)

    if not args.all and not args.region:
        parser.error("--region または --all を指定してください")

    if not args.skip_dem_preflight:
        preflight_dem()

    keys = sorted(REGIONS) if args.all else [args.region]
    ok = True
    for key in keys:
        report = build_region(REGIONS[key])
        ok = ok and report["ok"]
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
