"""OSM → 道路グラフ（§14.2 nodes/edges）変換テスト。"""
import pytest

from packgen.osm_graph import build_graph, haversine_m

OSM_FIXTURE = """<?xml version='1.0' encoding='UTF-8'?>
<osm version="0.6" generator="test">
  <node id="1" lat="35.0000" lon="139.0000"/>
  <node id="2" lat="35.0000" lon="139.0010"/>
  <node id="3" lat="35.0010" lon="139.0010"/>
  <node id="4" lat="35.0010" lon="139.0000"/>
  <node id="5" lat="35.0020" lon="139.0000"/>
  <way id="100">
    <nd ref="1"/><nd ref="2"/><nd ref="3"/>
    <tag k="highway" v="residential"/>
    <tag k="name" v="テスト通り"/>
    <tag k="width" v="5.5"/>
    <tag k="lit" v="yes"/>
  </way>
  <way id="101">
    <nd ref="3"/><nd ref="4"/>
    <tag k="highway" v="steps"/>
  </way>
  <way id="102">
    <nd ref="4"/><nd ref="5"/>
    <tag k="highway" v="footway"/>
    <tag k="tunnel" v="yes"/>
  </way>
  <way id="103">
    <nd ref="1"/><nd ref="5"/>
    <tag k="highway" v="motorway"/>
  </way>
  <way id="104">
    <nd ref="2"/><nd ref="4"/>
    <tag k="highway" v="footway"/>
    <tag k="width" v="1.2"/>
  </way>
</osm>
"""


@pytest.fixture()
def graph_db(tmp_path):
    osm_path = tmp_path / "region.osm"
    osm_path.write_text(OSM_FIXTURE)
    return build_graph(tmp_path / "pack.sqlite", osm_path)


def test_excludes_non_walkable_ways(graph_db):
    # motorway (way 103) は歩行ネットワークから除外する
    way_types = {r[0] for r in graph_db.execute("SELECT DISTINCT way_type FROM edges")}
    assert 3 in {r[0] for r in graph_db.execute("SELECT way_type FROM edges")}  # steps
    node5_edges = graph_db.execute(
        "SELECT COUNT(*) FROM edges WHERE from_node=5 OR to_node=5"
    ).fetchone()[0]
    # node5 へは footway(102) のみ（motorway 103 は除外）
    assert node5_edges == 1


def test_edge_attributes(graph_db):
    rows = graph_db.execute(
        "SELECT way_type, width_class, has_steps, is_lit, landmark_name FROM edges"
    ).fetchall()
    # residential: way_type=1, width 5.5m → class 3, lit=1, name あり
    assert (1, 3, 0, 1, "テスト通り") in rows
    # steps: way_type=3, has_steps=1
    assert any(r[0] == 3 and r[2] == 1 for r in rows)
    # tunnel=yes → underpass: way_type=4
    assert any(r[0] == 4 for r in rows)
    # width 1.2m → width_class=1
    assert any(r[1] == 1 for r in rows)


def test_edge_count_and_referential_integrity(graph_db):
    # way100: 2エッジ, way101: 1, way102: 1, way104: 1 → 計5
    assert graph_db.execute("SELECT COUNT(*) FROM edges").fetchone()[0] == 5
    orphan = graph_db.execute(
        """
        SELECT COUNT(*) FROM edges e
        WHERE NOT EXISTS (SELECT 1 FROM nodes n WHERE n.id = e.from_node)
           OR NOT EXISTS (SELECT 1 FROM nodes n WHERE n.id = e.to_node)
        """
    ).fetchone()[0]
    assert orphan == 0


def test_edge_length_is_positive_and_geometry_decodes(graph_db):
    from packgen.polyline import decode_polyline

    for length, geom in graph_db.execute("SELECT length_m, geometry FROM edges"):
        assert length > 0
        points = decode_polyline(geom)
        assert len(points) == 2  # 連続ノード対


def test_haversine():
    # 赤道付近 1 度 ≈ 111.2km
    d = haversine_m(0.0, 0.0, 0.0, 1.0)
    assert 110_000 < d < 112_000
