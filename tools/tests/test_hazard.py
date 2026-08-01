"""国土数値情報 GML → hazard_grid（§14.3）変換テスト。"""
from packgen.hazard import (
    cell_id_for,
    cell_center,
    import_flood_gml,
    import_landslide_gml,
)
from packgen.schema import init_db

# 国土数値情報 GML (JPGIS2.1) を模したフィクスチャ。
# 0.001°×0.001° の矩形ポリゴン 1 つ（35.000-35.001, 139.000-139.001）
GML_FIXTURE = """<?xml version="1.0" encoding="UTF-8"?>
<ksj:Dataset xmlns:ksj="http://nlftp.mlit.go.jp/ksj/schemas/ksj-app"
             xmlns:gml="http://www.opengis.net/gml/3.2">
 <gml:featureMember>
  <ksj:FloodArea>
   <ksj:depthRankMax>2</ksj:depthRankMax>
   <ksj:surface>
    <gml:Polygon srsName="fguuid:jgd2011.bl">
     <gml:exterior>
      <gml:LinearRing>
       <gml:posList>35.0000 139.0000 35.0000 139.0010 35.0010 139.0010 35.0010 139.0000 35.0000 139.0000</gml:posList>
      </gml:LinearRing>
     </gml:exterior>
    </gml:Polygon>
   </ksj:surface>
  </ksj:FloodArea>
 </gml:featureMember>
</ksj:Dataset>
"""

GML_LANDSLIDE = """<?xml version="1.0" encoding="UTF-8"?>
<ksj:Dataset xmlns:ksj="http://nlftp.mlit.go.jp/ksj/schemas/ksj-app"
             xmlns:gml="http://www.opengis.net/gml/3.2">
 <gml:featureMember>
  <ksj:LandslideArea>
   <ksj:areaClass>2</ksj:areaClass>
   <ksj:surface>
    <gml:Polygon srsName="fguuid:jgd2011.bl">
     <gml:exterior>
      <gml:LinearRing>
       <gml:posList>35.0000 139.0000 35.0000 139.0010 35.0010 139.0010 35.0010 139.0000 35.0000 139.0000</gml:posList>
      </gml:LinearRing>
     </gml:exterior>
    </gml:Polygon>
   </ksj:surface>
  </ksj:LandslideArea>
 </gml:featureMember>
</ksj:Dataset>
"""


def test_cell_id_encoding_roundtrip():
    lat, lng = 35.68123, 139.76712
    cid = cell_id_for(lat, lng)
    clat, clng = cell_center(cid)
    # セル中心は元座標からセルサイズ（1/2000度）の半分以内
    assert abs(clat - lat) <= 1 / 4000 + 1e-9
    assert abs(clng - lng) <= 1 / 4000 + 1e-9


def test_cell_id_is_deterministic_and_distinct():
    assert cell_id_for(35.0, 139.0) == cell_id_for(35.0, 139.0)
    assert cell_id_for(35.0, 139.0) != cell_id_for(35.0006, 139.0)
    assert cell_id_for(35.0, 139.0) != cell_id_for(35.0, 139.0006)


def test_flood_gml_marks_grid_cells(tmp_path):
    db = init_db(tmp_path / "pack.sqlite")
    gml = tmp_path / "flood.xml"
    gml.write_text(GML_FIXTURE)
    import_flood_gml(db, gml)
    rows = db.execute(
        "SELECT cell_id, flood_depth_m FROM hazard_grid"
    ).fetchall()
    assert len(rows) > 0
    # ランク3（0.5〜3m）→ 保守的に上限 3.0m を採用
    assert all(depth == 3.0 for _, depth in rows)
    # ポリゴン外のセルは含まれない
    outside = cell_id_for(35.01, 139.01)
    assert all(cid != outside for cid, _ in rows)


def test_landslide_gml_sets_special_warning_class(tmp_path):
    db = init_db(tmp_path / "pack.sqlite")
    gml = tmp_path / "landslide.xml"
    gml.write_text(GML_LANDSLIDE)
    import_landslide_gml(db, gml)
    rows = db.execute("SELECT landslide_class FROM hazard_grid").fetchall()
    assert len(rows) > 0
    assert all(cls == 2 for (cls,) in rows)  # 特別警戒区域


def test_flood_and_landslide_merge_into_same_cells(tmp_path):
    db = init_db(tmp_path / "pack.sqlite")
    f1 = tmp_path / "flood.xml"
    f2 = tmp_path / "landslide.xml"
    f1.write_text(GML_FIXTURE)
    f2.write_text(GML_LANDSLIDE)
    import_flood_gml(db, f1)
    import_landslide_gml(db, f2)
    row = db.execute(
        "SELECT flood_depth_m, landslide_class FROM hazard_grid"
    ).fetchone()
    assert row == (3.0, 2)
