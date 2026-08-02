"""packgen.merge_pack のテスト。"""
from __future__ import annotations

import json
import math
import sqlite3
from pathlib import Path

import pytest

from packgen.config import REGIONS
from packgen.merge_pack import (
    BUNDLED_PACK_KEY,
    DEFAULT_MERGE_REGIONS,
    merge_packs,
    union_bbox,
)
from packgen.schema import init_db
from packgen.validate_pack import validate_pack


def _haversine_m(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    r = 6_371_000.0
    p = math.pi / 180.0
    a = (
        math.sin((lat2 - lat1) * p / 2) ** 2
        + math.cos(lat1 * p) * math.cos(lat2 * p) * math.sin((lng2 - lng1) * p / 2) ** 2
    )
    return 2 * r * math.asin(math.sqrt(a))


def _insert_shelter(
    db: sqlite3.Connection,
    *,
    sid: str,
    name: str,
    lat: float,
    lng: float,
    elevation_m: float,
    ok_tsunami: int = 1,
) -> None:
    with db:
        cur = db.execute(
            """
            INSERT INTO shelters (
              id, name, lat, lng, elevation_m, ok_tsunami,
              ok_flood, ok_landslide, ok_storm_surge, ok_earthquake,
              ok_fire, ok_inland_flood, ok_volcano, is_all_hazard, is_shelter
            ) VALUES (?, ?, ?, ?, ?, ?, 0, 0, 0, 0, 0, 0, 0, 0, 1)
            """,
            (sid, name, lat, lng, elevation_m, ok_tsunami),
        )
        db.execute(
            "INSERT INTO shelters_rtree (id, minLat, maxLat, minLng, maxLng)"
            " VALUES (?, ?, ?, ?, ?)",
            (cur.lastrowid, lat, lat, lng, lng),
        )


def _minimal_region_pack(
    path: Path,
    *,
    region: str,
    bbox: tuple[float, float, float, float],
    shelter: tuple[str, str, float, float, float],
    node_base: int,
) -> None:
    db = init_db(path)
    sid, name, lat, lng, elev = shelter
    _insert_shelter(db, sid=sid, name=name, lat=lat, lng=lng, elevation_m=elev)
    n1, n2 = node_base, node_base + 1
    with db:
        db.execute(
            "INSERT INTO nodes (id, lat, lng, elevation_m) VALUES (?, ?, ?, 10)",
            (n1, lat, lng),
        )
        db.execute(
            "INSERT INTO nodes (id, lat, lng, elevation_m) VALUES (?, ?, ?, 10)",
            (n2, lat + 0.001, lng),
        )
        db.execute(
            "INSERT INTO edges (from_node, to_node, length_m) VALUES (?, ?, 100.0)",
            (n1, n2),
        )
        db.execute(
            """
            INSERT INTO hazard_grid (
              cell_id, elevation_m, flood_depth_m, tsunami_depth_m,
              landslide_class, storm_surge_m
            ) VALUES (1, 5.0, 0.5, 0.5, 1, 0.5)
            """
        )
        db.executemany(
            "INSERT INTO metadata (key, value) VALUES (?, ?)",
            [
                ("region", region),
                ("schema", "spec-§14 v1"),
                ("bbox", json.dumps(bbox)),
                ("sources", json.dumps([f"test-{region}"])),
            ],
        )
    db.close()


def _nearest_tsunami_shelter(pack: Path, origin: tuple[float, float], min_elev: float = 5.0):
    lat, lng = origin
    db = sqlite3.connect(pack)
    db.row_factory = sqlite3.Row
    rows = db.execute(
        "SELECT name, lat, lng, elevation_m FROM shelters WHERE ok_tsunami = 1"
    ).fetchall()
    best = None
    for row in rows:
        elev = row["elevation_m"]
        if elev is None or elev < min_elev:
            continue
        d = _haversine_m(lat, lng, row["lat"], row["lng"])
        if best is None or d < best[0]:
            best = (d, row["name"])
    db.close()
    return best


def test_union_bbox_covers_all_configured_regions() -> None:
    bbox = union_bbox(DEFAULT_MERGE_REGIONS)
    for key in DEFAULT_MERGE_REGIONS:
        min_lng, min_lat, max_lng, max_lat = REGIONS[key].bbox
        assert bbox[0] <= min_lng
        assert bbox[1] <= min_lat
        assert bbox[2] >= max_lng
        assert bbox[3] >= max_lat


def test_merge_two_regions_combines_shelters_and_dedups_graph(tmp_path: Path) -> None:
    tokyo = tmp_path / "tokyo.sqlite"
    chiba = tmp_path / "chiba.sqlite"
    out = tmp_path / "bundled.sqlite"

    _minimal_region_pack(
        tokyo,
        region="tokyo",
        bbox=(138.93, 35.49, 139.93, 35.91),
        shelter=("tokyo-far", "台場区民センター", 35.63, 139.777, 5.12),
        node_base=100,
    )
    _minimal_region_pack(
        chiba,
        region="chiba",
        bbox=(139.70, 34.89, 140.89, 35.91),
        shelter=("chiba-near", "真間山弘法寺", 35.73992, 139.90783, 20.97),
        node_base=200,
    )

    for pack in (tokyo, chiba):
        db = sqlite3.connect(pack)
        with db:
            db.execute(
                "INSERT OR REPLACE INTO nodes (id, lat, lng, elevation_m)"
                " VALUES (999, 35.73, 139.90, 8.0)"
            )
            db.execute(
                "INSERT INTO edges (from_node, to_node, length_m) VALUES (999, ?, 50.0)",
                (100 if "tokyo" in str(pack) else 200,),
            )
        db.close()

    report = merge_packs([tokyo, chiba], out, required_regions=("tokyo", "chiba"))
    assert report["ok"] is True
    assert report["counts"]["shelters"] == 2
    assert report["counts"]["nodes"] == 5
    assert report["counts"]["edges"] == 4

    merged = sqlite3.connect(out)
    meta = dict(merged.execute("SELECT key, value FROM metadata").fetchall())
    merged.close()
    assert meta["region"] == BUNDLED_PACK_KEY
    assert json.loads(meta["merged_from"]) == ["tokyo", "chiba"]

    validation = validate_pack(out, allowed_missing_hazards=["volcano"])
    assert validation["ok"] is True

    ichikawa = (35.7284921, 139.9000146)
    nearest = _nearest_tsunami_shelter(out, ichikawa)
    assert nearest is not None
    assert nearest[1] == "真間山弘法寺"
    assert nearest[0] < 2000


def test_merge_requires_all_requested_regions(tmp_path: Path) -> None:
    only = tmp_path / "tokyo.sqlite"
    out = tmp_path / "bundled.sqlite"
    _minimal_region_pack(
        only,
        region="tokyo",
        bbox=(138.93, 35.49, 139.93, 35.91),
        shelter=("t1", "東京", 35.6, 139.7, 10.0),
        node_base=100,
    )
    with pytest.raises(FileNotFoundError):
        merge_packs([only], out, required_regions=DEFAULT_MERGE_REGIONS)


@pytest.mark.slow
def test_merge_real_bundled_packs_if_present(tmp_path: Path) -> None:
    """tools/out に 4 県実データがある環境での統合 smoke test。"""
    root = Path(__file__).resolve().parents[1] / "out"
    inputs = [root / region / "pack.sqlite" for region in DEFAULT_MERGE_REGIONS]
    if not all(p.exists() for p in inputs):
        pytest.skip("4 県実パック未生成")

    out = tmp_path / "bundled.sqlite"
    report = merge_packs(inputs, out)
    assert report["ok"] is True
    assert report["counts"]["shelters"] > 10_000

    ichikawa = (35.7284921, 139.9000146)
    nearest = _nearest_tsunami_shelter(out, ichikawa)
    assert nearest is not None
    assert nearest[0] < 3000
    assert "台場" not in nearest[1]
