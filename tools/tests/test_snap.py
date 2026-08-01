"""避難所 → 道路グラフ最近傍ノードのスナップ（nearest_node_id）テスト。"""
from packgen.schema import init_db
from packgen.snap import snap_shelters_to_nodes


def _db_with_graph(tmp_path):
    db = init_db(tmp_path / "pack.sqlite")
    with db:
        # 格子状のノード（約 100m 間隔）
        for i in range(10):
            db.execute(
                "INSERT INTO nodes (id, lat, lng) VALUES (?, ?, ?)",
                (i, 35.000, 139.000 + i * 0.001),
            )
        db.execute(
            "INSERT INTO shelters (id, name, lat, lng) VALUES ('A', '近い', 35.0001, 139.0031)"
        )
        db.execute(
            "INSERT INTO shelters (id, name, lat, lng) VALUES ('B', '遠い', 36.500, 141.000)"
        )
    return db


def test_snap_finds_nearest_node(tmp_path):
    db = _db_with_graph(tmp_path)
    snap_shelters_to_nodes(db)
    nearest = dict(db.execute("SELECT id, nearest_node_id FROM shelters").fetchall())
    assert nearest["A"] == 3  # 139.003 に最も近い
    assert nearest["B"] is None  # 範囲外はスナップしない


def test_snap_is_idempotent(tmp_path):
    db = _db_with_graph(tmp_path)
    snap_shelters_to_nodes(db)
    snap_shelters_to_nodes(db)
    nearest = dict(db.execute("SELECT id, nearest_node_id FROM shelters").fetchall())
    assert nearest["A"] == 3
