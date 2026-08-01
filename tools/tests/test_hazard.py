"""国土数値情報 GML → hazard_grid（§14.3）変換テスト。

実 GML（JPGIS 2.1 / GML 3.2）は 2 段構造:
    gml:Curve(id=cN, posList) → gml:Surface(id=aN, patches が curveMember@xlink で Curve 参照)
    ksj:*Area(bounds@xlink で Surface 参照, 属性は waterDepth/coz 等)
本テストではその構造を縮小模倣したフィクスチャで各インポータを検証する。
"""
import textwrap

import pytest

from packgen.hazard import (
    cell_id_for,
    cell_center,
    import_flood_gml,
    import_landslide_gml,
    import_storm_surge_gml,
    import_tsunami_gml,
)
from packgen.schema import init_db


# --- 旧来の featureMember 形式フィクスチャ（後方互換性の維持）---
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

GML_LANDSLIDE_LEGACY = """<?xml version="1.0" encoding="UTF-8"?>
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


# --- 実 A31-12 GML の縮小模倣（Curve → Surface → ExpectedFloodArea @bounds）---
def _flood_area_gml(water_depth_code: int) -> str:
    """洪水浸水想定区域（A31）を模した GML を返す。"""
    return textwrap.dedent(f"""\
        <?xml version="1.0" encoding="UTF-8"?>
        <ksj:Dataset gml:id="A31Dataset"
                    xmlns:ksj="http://nlftp.mlit.go.jp/ksj/schemas/ksj-app"
                    xmlns:gml="http://www.opengis.net/gml/3.2"
                    xmlns:xlink="http://www.w3.org/1999/xlink">
        <gml:Curve gml:id="c00001">
         <gml:segments>
          <gml:LineStringSegment>
           <gml:posList>
            35.0000 139.0000
            35.0000 139.0010
            35.0010 139.0010
            35.0010 139.0000
            35.0000 139.0000
           </gml:posList>
          </gml:LineStringSegment>
         </gml:segments>
        </gml:Curve>
        <gml:Surface gml:id="a00001">
         <gml:patches>
          <gml:PolygonPatch>
           <gml:exterior>
            <gml:Ring>
             <gml:curveMember xlink:href="#c00001"/>
            </gml:Ring>
           </gml:exterior>
          </gml:PolygonPatch>
         </gml:patches>
        </gml:Surface>
        <ksj:ExpectedFloodArea gml:id="fld_00001">
         <ksj:bounds xlink:href="#a00001"/>
         <ksj:waterDepth>{water_depth_code}</ksj:waterDepth>
         <ksj:creatingBody>テスト河川砂防課</ksj:creatingBody>
        </ksj:ExpectedFloodArea>
        </ksj:Dataset>
    """)


# --- 実 A33-18 GML の縮小模倣 ---
def _landslide_gml(coz_value: int) -> str:
    """土砂災害警戒区域（A33 v2）を模した GML を返す。"""
    return textwrap.dedent(f"""\
        <?xml version="1.0" encoding="UTF-8"?>
        <ksj:Dataset gml:id="A33Dataset"
                    xmlns:ksj="http://nlftp.mlit.go.jp/ksj/schemas/ksj-app"
                    xmlns:gml="http://www.opengis.net/gml/3.2"
                    xmlns:xlink="http://www.w3.org/1999/xlink">
        <gml:Curve gml:id="cv1_0">
         <gml:segments>
          <gml:LineStringSegment>
           <gml:posList>
            35.0000 139.0000
            35.0000 139.0010
            35.0010 139.0010
            35.0010 139.0000
            35.0000 139.0000
           </gml:posList>
          </gml:LineStringSegment>
         </gml:segments>
        </gml:Curve>
        <gml:Surface gml:id="sf1">
         <gml:patches>
          <gml:PolygonPatch>
           <gml:exterior>
            <gml:Ring>
             <gml:curveMember xlink:href="#cv1_0"/>
            </gml:Ring>
           </gml:exterior>
          </gml:PolygonPatch>
         </gml:patches>
        </gml:Surface>
        <ksj:SedimentRelatedDisasterWarningAreasPolygon gml:id="wp1">
         <ksj:cop>2</ksj:cop>
         <ksj:coz>{coz_value}</ksj:coz>
         <ksj:cus>0</ksj:cus>
         <ksj:bounds xlink:href="#sf1"/>
        </ksj:SedimentRelatedDisasterWarningAreasPolygon>
        </ksj:Dataset>
    """)


def _storm_surge_gml(classification: str) -> str:
    """高潮浸水想定区域（A49）を模した GML を返す。classificationOfWaterDepth は文字列。"""
    return textwrap.dedent(f"""\
        <?xml version="1.0" encoding="UTF-8"?>
        <ksj:Dataset gml:id="A49Dataset"
                    xmlns:ksj="http://nlftp.mlit.go.jp/ksj/schemas/ksj-app"
                    xmlns:gml="http://www.opengis.net/gml/3.2"
                    xmlns:xlink="http://www.w3.org/1999/xlink">
        <gml:Curve gml:id="c1">
         <gml:segments>
          <gml:LineStringSegment>
           <gml:posList>
            35.0000 139.0000
            35.0000 139.0010
            35.0010 139.0010
            35.0010 139.0000
            35.0000 139.0000
           </gml:posList>
          </gml:LineStringSegment>
         </gml:segments>
        </gml:Curve>
        <gml:Surface gml:id="s1">
         <gml:patches>
          <gml:PolygonPatch>
           <gml:exterior>
            <gml:Ring>
             <gml:curveMember xlink:href="#c1"/>
            </gml:Ring>
           </gml:exterior>
          </gml:PolygonPatch>
         </gml:patches>
        </gml:Surface>
        <ksj:AreasExpectedToBeFloodedByStormSurges gml:id="ss1">
         <ksj:bounds xlink:href="#s1"/>
         <ksj:prefectureName>東京都</ksj:prefectureName>
         <ksj:prefectureCode>13</ksj:prefectureCode>
         <ksj:classificationOfWaterDepth>{classification}</ksj:classificationOfWaterDepth>
        </ksj:AreasExpectedToBeFloodedByStormSurges>
        </ksj:Dataset>
    """)


def _polygon_with_hole_gml() -> str:
    """exterior + interior（穴）を持つ Surface を模した GML。

    保守判断: 浸水想定区域では穴（interior）も『安全な島』とは限らない
    （地形抜けや報告未整備の可能性）。人命優先で区域全体を浸水扱いにする。
    """
    return textwrap.dedent("""\
        <?xml version="1.0" encoding="UTF-8"?>
        <ksj:Dataset gml:id="A31Dataset"
                    xmlns:ksj="http://nlftp.mlit.go.jp/ksj/schemas/ksj-app"
                    xmlns:gml="http://www.opengis.net/gml/3.2"
                    xmlns:xlink="http://www.w3.org/1999/xlink">
        <gml:Curve gml:id="cext">
         <gml:segments>
          <gml:LineStringSegment>
           <gml:posList>
            35.0000 139.0000 35.0000 139.0040 35.0040 139.0040 35.0040 139.0000 35.0000 139.0000
           </gml:posList>
          </gml:LineStringSegment>
         </gml:segments>
        </gml:Curve>
        <gml:Curve gml:id="cint">
         <gml:segments>
          <gml:LineStringSegment>
           <gml:posList>
            35.0015 139.0015 35.0015 139.0025 35.0025 139.0025 35.0025 139.0015 35.0015 139.0015
           </gml:posList>
          </gml:LineStringSegment>
         </gml:segments>
        </gml:Curve>
        <gml:Surface gml:id="asf">
         <gml:patches>
          <gml:PolygonPatch>
           <gml:exterior>
            <gml:Ring>
             <gml:curveMember xlink:href="#cext"/>
            </gml:Ring>
           </gml:exterior>
           <gml:interior>
            <gml:Ring>
             <gml:curveMember xlink:href="#cint"/>
            </gml:Ring>
           </gml:interior>
          </gml:PolygonPatch>
         </gml:patches>
        </gml:Surface>
        <ksj:ExpectedFloodArea gml:id="fld_hole">
         <ksj:bounds xlink:href="#asf"/>
         <ksj:waterDepth>12</ksj:waterDepth>
        </ksj:ExpectedFloodArea>
        </ksj:Dataset>
    """)


# --- セル ID の性質 ---

def test_cell_id_encoding_roundtrip():
    lat, lng = 35.68123, 139.76712
    cid = cell_id_for(lat, lng)
    clat, clng = cell_center(cid)
    assert abs(clat - lat) <= 1 / 4000 + 1e-9
    assert abs(clng - lng) <= 1 / 4000 + 1e-9


def test_cell_id_is_deterministic_and_distinct():
    assert cell_id_for(35.0, 139.0) == cell_id_for(35.0, 139.0)
    assert cell_id_for(35.0, 139.0) != cell_id_for(35.0006, 139.0)
    assert cell_id_for(35.0, 139.0) != cell_id_for(35.0, 139.0006)


# --- 旧 featureMember 形式（後方互換性）---

def test_legacy_feature_member_flood_still_supported(tmp_path):
    db = init_db(tmp_path / "pack.sqlite")
    gml = tmp_path / "flood.xml"
    gml.write_text(GML_FIXTURE)
    import_flood_gml(db, gml)
    rows = db.execute("SELECT flood_depth_m FROM hazard_grid").fetchall()
    assert len(rows) > 0
    # legacy: depthRankMax=2 → 旧 6段階マップで 3.0m
    assert all(depth == 3.0 for (depth,) in rows)


def test_legacy_landslide_area_class_still_supported(tmp_path):
    db = init_db(tmp_path / "pack.sqlite")
    gml = tmp_path / "landslide.xml"
    gml.write_text(GML_LANDSLIDE_LEGACY)
    import_landslide_gml(db, gml)
    rows = db.execute("SELECT landslide_class FROM hazard_grid").fetchall()
    assert len(rows) > 0
    assert all(cls == 2 for (cls,) in rows)


def test_shift_jis_gml_is_imported(tmp_path):
    """国土数値情報の実データは Shift_JIS の場合がある（回帰）。"""
    db = init_db(tmp_path / "pack.sqlite")
    gml = tmp_path / "flood_sjis.xml"
    sjis = GML_FIXTURE.replace(
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<?xml version="1.0" encoding="Shift_JIS"?>',
    ).replace(
        "<ksj:depthRankMax>2</ksj:depthRankMax>",
        "<ksj:depthRankMax>2</ksj:depthRankMax><ksj:name>荒川浸水想定</ksj:name>",
    )
    gml.write_bytes(sjis.encode("cp932"))
    import_flood_gml(db, gml)
    rows = db.execute("SELECT flood_depth_m FROM hazard_grid").fetchall()
    assert len(rows) > 0
    assert all(depth == 3.0 for (depth,) in rows)


# --- 実 JPGIS 構造（Curve/Surface/bounds@xlink）---

def test_jpgis_flood_area_via_bounds_xlink(tmp_path):
    db = init_db(tmp_path / "pack.sqlite")
    gml = tmp_path / "flood.xml"
    gml.write_text(_flood_area_gml(water_depth_code=12))
    import_flood_gml(db, gml)
    rows = db.execute("SELECT flood_depth_m FROM hazard_grid").fetchall()
    assert len(rows) > 0
    # 12: 0.5〜1.0m → 保守的に上限 1.0m
    assert all(depth == 1.0 for (depth,) in rows)


@pytest.mark.parametrize(
    "code, depth",
    [(11, 0.5), (12, 1.0), (13, 2.0), (14, 5.0), (15, 10.0)],
)
def test_flood_water_depth_code_5tier(tmp_path, code, depth):
    """5段階コード 11-15 の保守変換（上限 m 値。15=5m超の代表 10.0m）。"""
    db = init_db(tmp_path / f"pack_{code}.sqlite")
    gml = tmp_path / f"flood_{code}.xml"
    gml.write_text(_flood_area_gml(water_depth_code=code))
    import_flood_gml(db, gml)
    rows = db.execute("SELECT flood_depth_m FROM hazard_grid").fetchall()
    assert len(rows) > 0
    assert all(d == pytest.approx(depth) for (d,) in rows)


@pytest.mark.parametrize(
    "code, depth",
    [(21, 0.5), (22, 1.0), (23, 2.0), (24, 3.0), (25, 4.0), (26, 5.0), (27, 10.0)],
)
def test_flood_water_depth_code_7tier(tmp_path, code, depth):
    """7段階コード 21-27 の保守変換（上限 m 値。27=5m超の代表 10.0m）。"""
    db = init_db(tmp_path / f"pack_{code}.sqlite")
    gml = tmp_path / f"flood_{code}.xml"
    gml.write_text(_flood_area_gml(water_depth_code=code))
    import_flood_gml(db, gml)
    rows = db.execute("SELECT flood_depth_m FROM hazard_grid").fetchall()
    assert len(rows) > 0
    assert all(d == pytest.approx(depth) for (d,) in rows)


@pytest.mark.parametrize(
    "coz, expected_class",
    [(1, 1), (2, 2), (3, 1), (4, 2)],
)
def test_landslide_coz_maps_to_class(tmp_path, coz, expected_class):
    """A33 の区域コード coz を landslide_class(1/2) にマップ。
    指定前(3,4)も保守的に指定済扱いにする（人命優先）。
    """
    db = init_db(tmp_path / f"pack_{coz}.sqlite")
    gml = tmp_path / f"ls_{coz}.xml"
    gml.write_text(_landslide_gml(coz_value=coz))
    import_landslide_gml(db, gml)
    rows = db.execute("SELECT landslide_class FROM hazard_grid").fetchall()
    assert len(rows) > 0
    assert all(cls == expected_class for (cls,) in rows)


def test_flood_polygon_with_interior_is_conservatively_covered(tmp_path):
    """穴（interior）を持つ Surface でも保守的に区域全体を浸水セル化する。"""
    db = init_db(tmp_path / "pack.sqlite")
    gml = tmp_path / "flood.xml"
    gml.write_text(_polygon_with_hole_gml())
    import_flood_gml(db, gml)
    rows = db.execute(
        "SELECT cell_id, flood_depth_m FROM hazard_grid ORDER BY cell_id"
    ).fetchall()
    assert len(rows) > 0
    assert all(depth == 1.0 for _, depth in rows)
    # 穴の中心 (35.0020, 139.0020) セルが含まれる
    hole_center = cell_id_for(35.0020, 139.0020)
    assert any(cid == hole_center for cid, _ in rows)


def test_storm_surge_a49_mixed_case_curve_surface_ids(tmp_path):
    """A49 実データ: gml:id='Cv1_0' と href='#cv1_0' の大文字小文字不一致を解決する。"""
    xml = textwrap.dedent("""\
        <?xml version="1.0" encoding="UTF-8"?>
        <ksj:Dataset gml:id="A49Dataset"
                    xmlns:ksj="http://nlftp.mlit.go.jp/ksj/schemas/ksj-app"
                    xmlns:gml="http://www.opengis.net/gml/3.2"
                    xmlns:xlink="http://www.w3.org/1999/xlink">
        <gml:Curve gml:id="Cv1_0">
         <gml:segments>
          <gml:LineStringSegment>
           <gml:posList>
            35.0000 139.0000
            35.0000 139.0010
            35.0010 139.0010
            35.0010 139.0000
            35.0000 139.0000
           </gml:posList>
          </gml:LineStringSegment>
         </gml:segments>
        </gml:Curve>
        <gml:Surface gml:id="Sf1">
         <gml:patches>
          <gml:PolygonPatch>
           <gml:exterior>
            <gml:Ring>
             <gml:curveMember xlink:href="#cv1_0"/>
            </gml:Ring>
           </gml:exterior>
          </gml:PolygonPatch>
         </gml:patches>
        </gml:Surface>
        <ksj:AreasExpectedToBeFloodedByStormSurges gml:id="ss1">
         <ksj:bounds xlink:href="#sf1"/>
         <ksj:classificationOfWaterDepth>3m 以上 5m 未満</ksj:classificationOfWaterDepth>
        </ksj:AreasExpectedToBeFloodedByStormSurges>
        </ksj:Dataset>
    """)
    db = init_db(tmp_path / "pack.sqlite")
    gml = tmp_path / "surge_mixed_case.xml"
    gml.write_text(xml)
    n = import_storm_surge_gml(db, gml)
    assert n > 0


def test_storm_surge_a49_classification_string(tmp_path):
    db = init_db(tmp_path / "pack.sqlite")
    gml = tmp_path / "surge.xml"
    gml.write_text(_storm_surge_gml("3m 以上 5m 未満"))
    import_storm_surge_gml(db, gml)
    rows = db.execute("SELECT storm_surge_m FROM hazard_grid").fetchall()
    assert len(rows) > 0
    assert all(m == pytest.approx(5.0) for (m,) in rows)


@pytest.mark.parametrize(
    "text, expected_m",
    [
        ("0.3m 未満", 0.3),
        ("0.3m 以上 0.5m 未満", 0.5),
        ("0.5m 未満", 0.5),
        ("0.5m 以上 1m 未満", 1.0),
        ("1m 以上 3m 未満", 3.0),
        ("0.5m 以上 3m 未満", 3.0),
        ("3m 以上 5m 未満", 5.0),
        ("5m 以上 10m 未満", 10.0),
        ("10m 以上 20m 未満", 20.0),
        ("20m 以上", 25.0),
    ],
)
def test_storm_surge_classification_variants(tmp_path, text, expected_m):
    db = init_db(tmp_path / f"pack_{expected_m}.sqlite")
    gml = tmp_path / f"ss_{expected_m}.xml"
    gml.write_text(_storm_surge_gml(text))
    import_storm_surge_gml(db, gml)
    rows = db.execute("SELECT storm_surge_m FROM hazard_grid").fetchall()
    assert len(rows) > 0
    assert all(m == pytest.approx(expected_m) for (m,) in rows)


def test_tsunami_classification_string_falls_back_to_upper_bound(tmp_path):
    """A40 津波の CharacterString ランクも同じパーサで扱える。"""
    xml = textwrap.dedent("""\
        <?xml version="1.0" encoding="UTF-8"?>
        <ksj:Dataset gml:id="A40Dataset"
                    xmlns:ksj="http://nlftp.mlit.go.jp/ksj/schemas/ksj-app"
                    xmlns:gml="http://www.opengis.net/gml/3.2"
                    xmlns:xlink="http://www.w3.org/1999/xlink">
        <gml:Curve gml:id="c1">
         <gml:segments><gml:LineStringSegment><gml:posList>
          35.0000 139.0000 35.0000 139.0010 35.0010 139.0010 35.0010 139.0000 35.0000 139.0000
         </gml:posList></gml:LineStringSegment></gml:segments>
        </gml:Curve>
        <gml:Surface gml:id="s1"><gml:patches><gml:PolygonPatch>
         <gml:exterior><gml:Ring><gml:curveMember xlink:href="#c1"/></gml:Ring></gml:exterior>
        </gml:PolygonPatch></gml:patches></gml:Surface>
        <ksj:TsunamiInundationAssumption gml:id="ts1">
         <ksj:bounds xlink:href="#s1"/>
         <ksj:classificationOfWaterDepth>5m 以上 10m 未満</ksj:classificationOfWaterDepth>
        </ksj:TsunamiInundationAssumption>
        </ksj:Dataset>
    """)
    db = init_db(tmp_path / "pack.sqlite")
    gml = tmp_path / "ts.xml"
    gml.write_text(xml)
    import_tsunami_gml(db, gml)
    rows = db.execute("SELECT tsunami_depth_m FROM hazard_grid").fetchall()
    assert len(rows) > 0
    assert all(m == pytest.approx(10.0) for (m,) in rows)


def test_flood_and_landslide_merge_into_same_cells(tmp_path):
    db = init_db(tmp_path / "pack.sqlite")
    f1 = tmp_path / "flood.xml"
    f2 = tmp_path / "landslide.xml"
    f1.write_text(_flood_area_gml(water_depth_code=12))
    f2.write_text(_landslide_gml(coz_value=2))
    import_flood_gml(db, f1)
    import_landslide_gml(db, f2)
    row = db.execute(
        "SELECT flood_depth_m, landslide_class FROM hazard_grid"
    ).fetchone()
    assert row == (1.0, 2)
