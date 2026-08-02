"""複数県パックを 1 つの同梱用統合パック（bundled）にマージする。

都道府県ごとの生成物を build 時に 1 ファイルへまとめる。地域キーは bundled 固定で、
merged_from に含まれる県を記録する（将来の県追加に対応）。

使い方:
  python -m packgen.merge_pack
  python -m packgen.merge_pack --output tools/out/bundled/pack.sqlite
  python -m packgen.merge_pack --region tokyo --region chiba
"""
from __future__ import annotations

import argparse
import json
import logging
import sqlite3
import sys
from datetime import datetime, timezone
from pathlib import Path

from packgen.config import ALLOWED_MISSING_HAZARDS, REGIONS
from packgen.schema import init_db
from packgen.validate_pack import validate_pack

TOOLS_DIR = Path(__file__).resolve().parent.parent
OUT_DIR = TOOLS_DIR / "out"

BUNDLED_PACK_KEY = "bundled"

# 同梱 merge の既定対象（packgen.config.REGIONS の全県。CLI --region で上書き可）
DEFAULT_MERGE_REGIONS: tuple[str, ...] = tuple(sorted(REGIONS.keys()))

SHELTER_COLUMNS: tuple[str, ...] = (
    "id",
    "name",
    "name_kana",
    "lat",
    "lng",
    "elevation_m",
    "address",
    "ok_flood",
    "ok_landslide",
    "ok_storm_surge",
    "ok_earthquake",
    "ok_tsunami",
    "ok_fire",
    "ok_inland_flood",
    "ok_volcano",
    "is_all_hazard",
    "place_class",
    "usable_floor_height_m",
    "is_shelter",
    "barrier_free",
    "capacity",
    "nearest_node_id",
    "note",
)

EDGE_COLUMNS: tuple[str, ...] = (
    "from_node",
    "to_node",
    "length_m",
    "geometry",
    "way_type",
    "width_class",
    "has_steps",
    "is_lit",
    "hz_flood_depth",
    "hz_tsunami_depth",
    "hz_landslide",
    "hz_storm_surge",
    "hz_volcano",
    "near_river",
    "dense_wood",
    "landmark_name",
)

HAZARD_COLUMNS: tuple[str, ...] = (
    "elevation_m",
    "flood_depth_m",
    "tsunami_depth_m",
    "landslide_class",
    "storm_surge_m",
    "volcano_class",
    "dist_coast_m",
    "dist_river_m",
    "dense_wood",
)

logger = logging.getLogger("packgen.merge")


def union_bbox(region_keys: tuple[str, ...]) -> tuple[float, float, float, float]:
    """複数県 bbox の外接矩形 (min_lng, min_lat, max_lng, max_lat)。"""
    boxes = [REGIONS[k].bbox for k in region_keys if k in REGIONS]
    if not boxes:
        raise ValueError(f"unknown regions: {region_keys}")
    return (
        min(b[0] for b in boxes),
        min(b[1] for b in boxes),
        max(b[2] for b in boxes),
        max(b[3] for b in boxes),
    )


def merged_allowed_missing_hazards(region_keys: tuple[str, ...]) -> tuple[str, ...]:
    """統合パック検証で許容する欠損ハザード（県別設定の和集合）。"""
    allowed: set[str] = set()
    for key in region_keys:
        allowed.update(ALLOWED_MISSING_HAZARDS.get(key, ()))
    return tuple(sorted(allowed))


def _max_hazard(a: dict[str, object | None], b: dict[str, object | None]) -> dict[str, object | None]:
    """MultiRegionPack._maxHazard と同等の安全側マージ。"""
    flood = max(float(a.get("flood_depth_m") or 0), float(b.get("flood_depth_m") or 0))
    tsunami = max(float(a.get("tsunami_depth_m") or 0), float(b.get("tsunami_depth_m") or 0))
    surge = max(float(a.get("storm_surge_m") or 0), float(b.get("storm_surge_m") or 0))
    landslide = max(int(a.get("landslide_class") or 0), int(b.get("landslide_class") or 0))
    volcano = max(int(a.get("volcano_class") or 0), int(b.get("volcano_class") or 0))

    def _min_nullable(x: object | None, y: object | None) -> object | None:
        if x is None:
            return y
        if y is None:
            return x
        return min(int(x), int(y))

    dense = int(a.get("dense_wood") or 0) or int(b.get("dense_wood") or 0)
    elev_a = a.get("elevation_m")
    elev_b = b.get("elevation_m")
    elevation_m = elev_a if elev_a is not None else elev_b

    return {
        "cell_id": a["cell_id"],
        "elevation_m": elevation_m,
        "flood_depth_m": flood,
        "tsunami_depth_m": tsunami,
        "landslide_class": landslide,
        "storm_surge_m": surge,
        "volcano_class": volcano,
        "dist_coast_m": _min_nullable(a.get("dist_coast_m"), b.get("dist_coast_m")),
        "dist_river_m": _min_nullable(a.get("dist_river_m"), b.get("dist_river_m")),
        "dense_wood": dense,
    }


def _rebuild_shelters_rtree(db: sqlite3.Connection) -> None:
    with db:
        db.execute("DELETE FROM shelters_rtree")
        db.execute(
            """
            INSERT INTO shelters_rtree (id, minLat, maxLat, minLng, maxLng)
            SELECT rowid, lat, lat, lng, lng FROM shelters
            """
        )


def _copy_shelters(src: sqlite3.Connection, dst: sqlite3.Connection) -> int:
    cols = ", ".join(SHELTER_COLUMNS)
    rows = src.execute(f"SELECT {cols} FROM shelters").fetchall()
    placeholders = ", ".join("?" for _ in SHELTER_COLUMNS)
    sql = f"INSERT OR IGNORE INTO shelters ({cols}) VALUES ({placeholders})"
    with dst:
        dst.executemany(sql, rows)
    return len(rows)


def _copy_nodes(src: sqlite3.Connection, dst: sqlite3.Connection) -> int:
    rows = src.execute("SELECT id, lat, lng, elevation_m FROM nodes").fetchall()
    with dst:
        dst.executemany(
            "INSERT OR REPLACE INTO nodes (id, lat, lng, elevation_m) VALUES (?, ?, ?, ?)",
            rows,
        )
    return len(rows)


def _merge_edges(src_paths: list[Path], dst: sqlite3.Connection) -> int:
    seen: set[tuple[int, int]] = set()
    next_id = 1
    cols = ", ".join(EDGE_COLUMNS)
    placeholders = ", ".join("?" for _ in EDGE_COLUMNS)
    insert_sql = f"INSERT INTO edges (id, {cols}) VALUES (?, {placeholders})"
    batch: list[tuple[object, ...]] = []

    for path in src_paths:
        src = sqlite3.connect(str(path))
        try:
            for row in src.execute(f"SELECT {cols} FROM edges"):
                data = dict(zip(EDGE_COLUMNS, row, strict=True))
                a = min(int(data["from_node"]), int(data["to_node"]))
                b = max(int(data["from_node"]), int(data["to_node"]))
                key = (a, b)
                if key in seen:
                    continue
                seen.add(key)
                batch.append((next_id, *[data[c] for c in EDGE_COLUMNS]))
                next_id += 1
                if len(batch) >= 5000:
                    with dst:
                        dst.executemany(insert_sql, batch)
                    batch.clear()
        finally:
            src.close()

    if batch:
        with dst:
            dst.executemany(insert_sql, batch)
    return next_id - 1


def _merge_hazard_grid(src_paths: list[Path], dst: sqlite3.Connection) -> int:
    merged: dict[int, dict[str, object | None]] = {}
    select_cols = ", ".join(["cell_id", *HAZARD_COLUMNS])

    for path in src_paths:
        src = sqlite3.connect(str(path))
        try:
            for row in src.execute(f"SELECT {select_cols} FROM hazard_grid"):
                data = dict(zip(["cell_id", *HAZARD_COLUMNS], row, strict=True))
                cell_id = int(data["cell_id"])
                if cell_id in merged:
                    merged[cell_id] = _max_hazard(merged[cell_id], data)
                else:
                    merged[cell_id] = data
        finally:
            src.close()

    cols = ", ".join(["cell_id", *HAZARD_COLUMNS])
    placeholders = ", ".join("?" for _ in range(1 + len(HAZARD_COLUMNS)))
    sql = f"INSERT INTO hazard_grid ({cols}) VALUES ({placeholders})"
    rows = [tuple(cell[c] for c in ["cell_id", *HAZARD_COLUMNS]) for cell in merged.values()]
    with dst:
        dst.executemany(sql, rows)
    return len(rows)


def _collect_metadata(
    src_paths: list[Path],
    merged_regions: tuple[str, ...],
) -> dict[str, str]:
    sources: list[str] = []
    notes: list[str] = []
    for path in src_paths:
        src = sqlite3.connect(str(path))
        try:
            meta = dict(src.execute("SELECT key, value FROM metadata").fetchall())
            region = meta.get("region", path.parent.name)
            pref = REGIONS.get(region)
            if pref:
                notes.append(f"merged from {pref.pref_name} ({region})")
            raw_sources = meta.get("sources")
            if raw_sources:
                try:
                    sources.extend(json.loads(raw_sources))
                except json.JSONDecodeError:
                    sources.append(raw_sources)
            allowed = ALLOWED_MISSING_HAZARDS.get(region, ())
            if allowed:
                notes.append(f"{region}: allowed_missing={','.join(allowed)}")
        finally:
            src.close()

    pref_names = [REGIONS[r].pref_name for r in merged_regions if r in REGIONS]
    bbox = union_bbox(merged_regions)

    return {
        "region": BUNDLED_PACK_KEY,
        "pref_name": "・".join(pref_names),
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "schema": "spec-§14 v1",
        "sources": json.dumps(sorted(set(sources)), ensure_ascii=False),
        "notes": json.dumps(notes, ensure_ascii=False),
        "bbox": json.dumps(list(bbox)),
        "merged_from": json.dumps(list(merged_regions)),
    }


def merge_packs(
    inputs: list[Path],
    output: Path,
    *,
    required_regions: tuple[str, ...] = DEFAULT_MERGE_REGIONS,
    elevation_null_rate_threshold: float = 0.10,
) -> dict:
    """複数 pack.sqlite を 1 つに統合し、検証レポートを返す。"""
    if output.exists():
        output.unlink()

    output.parent.mkdir(parents=True, exist_ok=True)
    dst = init_db(output)

    input_by_region: dict[str, Path] = {}
    for path in inputs:
        src = sqlite3.connect(str(path))
        try:
            row = src.execute("SELECT value FROM metadata WHERE key='region'").fetchone()
        finally:
            src.close()
        region = row[0] if row else path.parent.name
        input_by_region[region] = path

    missing = [r for r in required_regions if r not in input_by_region]
    if missing:
        raise FileNotFoundError(
            f"統合に必要な県パックが不足: {missing}. "
            f"cd tools && uv run python -m packgen.build_pack --all"
        )

    ordered = [input_by_region[r] for r in required_regions if r in input_by_region]
    if len(ordered) < len(inputs):
        extras = [p for p in inputs if p not in ordered]
        ordered.extend(extras)

    shelter_total = 0
    node_total = 0
    for path in ordered:
        src = sqlite3.connect(str(path))
        try:
            shelter_total += _copy_shelters(src, dst)
            node_total += _copy_nodes(src, dst)
        finally:
            src.close()

    _rebuild_shelters_rtree(dst)
    edge_total = _merge_edges(ordered, dst)
    hazard_total = _merge_hazard_grid(ordered, dst)

    metadata = _collect_metadata(ordered, required_regions)
    with dst:
        dst.executemany(
            "INSERT INTO metadata (key, value) VALUES (?, ?)",
            list(metadata.items()),
        )
    dst.commit()
    dst.close()

    report = validate_pack(
        output,
        elevation_null_rate_threshold=elevation_null_rate_threshold,
        allowed_missing_hazards=list(merged_allowed_missing_hazards(required_regions)),
    )
    report["merge"] = {
        "inputs": [str(p) for p in ordered],
        "shelter_rows_read": shelter_total,
        "node_rows_read": node_total,
        "edges_deduped": edge_total,
        "hazard_cells_merged": hazard_total,
    }
    logger.info("merge complete ok=%s output=%s", report["ok"], output)
    return report


def main(argv: list[str]) -> int:
    logging.basicConfig(
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
        level=logging.INFO,
    )
    parser = argparse.ArgumentParser(description="県別パックを同梱用統合パックへマージ")
    parser.add_argument(
        "--output",
        type=Path,
        default=OUT_DIR / BUNDLED_PACK_KEY / "pack.sqlite",
        help="出力 pack.sqlite",
    )
    parser.add_argument(
        "--input",
        type=Path,
        action="append",
        default=None,
        help="入力 pack.sqlite（未指定時は tools/out/<region>/pack.sqlite）",
    )
    parser.add_argument(
        "--region",
        action="append",
        dest="regions",
        choices=sorted(REGIONS.keys()),
        help="マージ対象県（複数指定可。未指定時は config.REGIONS 全件）",
    )
    args = parser.parse_args(argv)

    regions = tuple(args.regions) if args.regions else DEFAULT_MERGE_REGIONS

    if args.input:
        inputs = args.input
    else:
        inputs = [OUT_DIR / region / "pack.sqlite" for region in regions]

    for path in inputs:
        if not path.exists():
            logger.error("missing input: %s", path)
            return 1

    report = merge_packs(inputs, args.output, required_regions=regions)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
