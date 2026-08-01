"""パック検証（validate_pack）のテスト。"""
import pytest

from packgen.schema import init_db
from packgen.validate_pack import validate_pack


def _minimal_pack(tmp_path):
    db = init_db(tmp_path / "pack.sqlite")
    with db:
        db.execute(
            "INSERT INTO shelters (id, name, lat, lng, ok_tsunami) VALUES ('A', 'test', 35.6, 139.7, 1)"
        )
        db.execute(
            "INSERT INTO shelters_rtree (id, minLat, maxLat, minLng, maxLng)"
            " VALUES (1, 35.6, 35.6, 139.7, 139.7)"
        )
        db.execute("INSERT INTO nodes (id, lat, lng) VALUES (1, 35.6, 139.7)")
        db.execute("INSERT INTO nodes (id, lat, lng) VALUES (2, 35.6005, 139.7005)")
        db.execute(
            "INSERT INTO edges (from_node, to_node, length_m) VALUES (1, 2, 65.0)"
        )
        db.execute(
            "INSERT INTO hazard_grid (cell_id, flood_depth_m) VALUES (1, 0.5)"
        )
        db.execute("INSERT INTO metadata (key, value) VALUES ('region', 'tokyo')")
    return db


def test_valid_pack_passes(tmp_path):
    db = _minimal_pack(tmp_path)
    db.close()
    report = validate_pack(tmp_path / "pack.sqlite")
    assert report["ok"] is True
    assert report["counts"]["shelters"] == 1


def test_empty_pack_fails(tmp_path):
    db = init_db(tmp_path / "empty.sqlite")
    db.close()
    report = validate_pack(tmp_path / "empty.sqlite")
    assert report["ok"] is False
    assert any("shelters" in e for e in report["errors"])


def test_orphan_edges_fail(tmp_path):
    db = _minimal_pack(tmp_path)
    with db:
        db.execute(
            "INSERT INTO edges (from_node, to_node, length_m) VALUES (1, 999, 10.0)"
        )
    db.close()
    report = validate_pack(tmp_path / "pack.sqlite")
    assert report["ok"] is False
    assert any("edges" in e for e in report["errors"])


def test_empty_hazard_grid_fails(tmp_path):
    """hazard_grid が空のパックは NG（P0 で東京パックが 0 セルだった回帰）。"""
    db = _minimal_pack(tmp_path)
    with db:
        db.execute("DELETE FROM hazard_grid")
    db.close()
    report = validate_pack(tmp_path / "pack.sqlite")
    assert report["ok"] is False
    assert any("hazard_grid" in e for e in report["errors"])


def test_high_elevation_null_rate_fails(tmp_path):
    """nodes.elevation_m の NULL 率が閾値を超えたら NG。"""
    db = _minimal_pack(tmp_path)
    with db:
        db.execute("UPDATE nodes SET elevation_m = NULL")
    db.close()
    report = validate_pack(
        tmp_path / "pack.sqlite", elevation_null_rate_threshold=0.1
    )
    assert report["ok"] is False
    assert any("elevation_m" in e for e in report["errors"])


def test_allowed_missing_hazard_kinds(tmp_path):
    """埼玉のように高潮/津波データが無い県では allowed_missing 指定で pass。"""
    db = _minimal_pack(tmp_path)
    with db:
        db.execute("UPDATE nodes SET elevation_m = 10.0")
        db.execute("UPDATE shelters SET elevation_m = 10.0")
        # 洪水・土砂は埼玉にもあるので登録
        db.execute(
            "INSERT INTO hazard_grid (cell_id, landslide_class) VALUES (2, 2)"
        )
    db.close()
    report = validate_pack(
        tmp_path / "pack.sqlite",
        elevation_null_rate_threshold=0.1,
        allowed_missing_hazards=["storm_surge", "tsunami", "volcano"],
    )
    assert report["ok"] is True, report["errors"]


def test_tokyo_auto_allowed_missing_via_metadata(tmp_path):
    """metadata.region=tokyo では tsunami/volcano 欠損を CLI 既定で許容。"""
    db = _minimal_pack(tmp_path)
    with db:
        db.execute("UPDATE nodes SET elevation_m = 10.0")
        db.execute("UPDATE shelters SET elevation_m = 10.0")
        db.execute(
            "INSERT INTO hazard_grid (cell_id, landslide_class, storm_surge_m)"
            " VALUES (2, 2, 0.5)"
        )
    db.close()
    from packgen.validate_pack import _allowed_missing_for_pack

    allowed = _allowed_missing_for_pack(tmp_path / "pack.sqlite")
    assert set(allowed or []) == {"tsunami", "volcano"}
    report = validate_pack(
        tmp_path / "pack.sqlite",
        elevation_null_rate_threshold=0.1,
        allowed_missing_hazards=allowed,
    )
    assert report["ok"] is True, report["errors"]


def test_all_hazard_flag_consistency(tmp_path):
    db = _minimal_pack(tmp_path)
    with db:
        # 全フラグ未満なのに is_all_hazard=1 の不正行
        db.execute(
            "INSERT INTO shelters (id, name, lat, lng, ok_tsunami, is_all_hazard)"
            " VALUES ('B', 'bad', 35.6, 139.7, 1, 1)"
        )
    db.close()
    report = validate_pack(tmp_path / "pack.sqlite")
    assert report["ok"] is False
    assert any("is_all_hazard" in e for e in report["errors"])
