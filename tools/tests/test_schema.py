"""§14.1〜14.3 のスキーマ適合テスト。"""
import sqlite3

from packgen.schema import init_db


def _columns(db: sqlite3.Connection, table: str) -> set[str]:
    return {row[1] for row in db.execute(f"PRAGMA table_info({table})")}


def test_shelters_table_has_required_columns(tmp_path):
    db = init_db(tmp_path / "pack.sqlite")
    cols = _columns(db, "shelters")
    required = {
        "id", "name", "name_kana", "lat", "lng", "elevation_m", "address",
        "ok_flood", "ok_landslide", "ok_storm_surge", "ok_earthquake",
        "ok_tsunami", "ok_fire", "ok_inland_flood", "ok_volcano",
        "is_all_hazard", "place_class", "usable_floor_height_m",
        "is_shelter", "barrier_free", "capacity", "nearest_node_id", "note",
    }
    assert required <= cols


def test_road_graph_tables_have_required_columns(tmp_path):
    db = init_db(tmp_path / "pack.sqlite")
    assert {"id", "lat", "lng", "elevation_m"} <= _columns(db, "nodes")
    edge_cols = _columns(db, "edges")
    required = {
        "id", "from_node", "to_node", "length_m", "geometry", "way_type",
        "width_class", "has_steps", "is_lit",
        "hz_flood_depth", "hz_tsunami_depth", "hz_landslide",
        "hz_storm_surge", "hz_volcano", "near_river", "dense_wood",
        "landmark_name",
    }
    assert required <= edge_cols


def test_hazard_grid_table_has_required_columns(tmp_path):
    db = init_db(tmp_path / "pack.sqlite")
    cols = _columns(db, "hazard_grid")
    required = {
        "cell_id", "elevation_m", "flood_depth_m", "tsunami_depth_m",
        "landslide_class", "storm_surge_m", "volcano_class",
        "dist_coast_m", "dist_river_m", "dense_wood",
    }
    assert required <= cols


def test_shelters_rtree_virtual_table_exists(tmp_path):
    db = init_db(tmp_path / "pack.sqlite")
    row = db.execute(
        "SELECT name FROM sqlite_master WHERE name='shelters_rtree'"
    ).fetchone()
    assert row is not None


def test_metadata_table_exists(tmp_path):
    db = init_db(tmp_path / "pack.sqlite")
    assert {"key", "value"} <= _columns(db, "metadata")
