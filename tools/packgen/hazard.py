"""国土数値情報のハザード GML（JPGIS 2.1 / GML 3.2）を hazard_grid（§14.3）へ変換する。

グリッド: 緯度・経度をそれぞれ 1/2000 度（約 50m）で分割したセル。
cell_id = floor(lat*2000) * 1_000_000 + floor(lng*2000)（int64、決定論的）。

## 実 GML の構造
本モジュールが扱う国土数値情報の GML は 2 段構造を取る:

    <gml:Curve gml:id="cXXXXX">
      <gml:segments>
        <gml:LineStringSegment><gml:posList>lat lng lat lng ...</gml:posList></...>
      </...>
    </gml:Curve>
    <gml:Surface gml:id="aXXXXX">
      <gml:patches><gml:PolygonPatch>
        <gml:exterior><gml:Ring>
          <gml:curveMember xlink:href="#cXXXXX"/>
        </gml:Ring></gml:exterior>
        <gml:interior>...</gml:interior>  <!-- 任意、複数可 -->
      </gml:PolygonPatch></gml:patches>
    </gml:Surface>
    <ksj:ExpectedFloodArea gml:id="...">
      <ksj:bounds xlink:href="#aXXXXX"/>
      <ksj:waterDepth>12</ksj:waterDepth>  <!-- 属性 -->
      ...
    </ksj:ExpectedFloodArea>

Curve→Surface→フィーチャ の順に走査し、xlink:href で解決する。

## interior（穴）の扱い
浸水想定区域データにおいて、多くの interior は「調査対象外」「地物抜け」
であって『安全な島』を保証するものではない。本ライブラリでは人命優先で
**穴も浸水区域として扱う**（Polygon の exterior のみで内外判定する）。

## 洪水浸水深コード（A31）→ m
公式コード表 https://nlftp.mlit.go.jp/ksj/gml/codelist/WaterDepthCd.html:
    5段階: 11=<0.5 12=0.5-1 13=1-2 14=2-5 15=>=5
    7段階: 21=<0.5 22=0.5-1 23=1-2 24=2-3 25=3-4 26=4-5 27=>=5

保守的（人命優先）に**ランク上限**を採用（15/27 は 5m 超を代表値 10.0m）。

## 高潮浸水深区分（A49）
`classificationOfWaterDepth` は CharacterString（例: "3m 以上 5m 未満"）。
`_parse_depth_class_text` で上限値を数値化する。

## 土砂災害警戒区域（A33 v2）
`ksj:coz` = 区域コード。1:警戒(指定済) 2:特別警戒(指定済) 3:警戒(指定前) 4:特別警戒(指定前)。
指定前(3,4)も保守的に指定済相当に格上げする（1→1, 3→1, 2→2, 4→2）。
"""
from __future__ import annotations

import logging
import math
import re
import sqlite3
import xml.etree.ElementTree as ET
from pathlib import Path

from shapely.geometry import Polygon
from shapely import contains_xy, prepare

logger = logging.getLogger(__name__)

GRID_SCALE = 2000  # 1/2000 度 ≈ 50m メッシュ

# 旧 A31 系（1-6 のランクコード）: 後方互換フィクスチャ用
RANK_TO_DEPTH_M = {1: 0.5, 2: 3.0, 3: 5.0, 4: 10.0, 5: 20.0, 6: 25.0}

# 公式 WaterDepthCd（洪水浸水想定区域 A31）— 保守的な上限 m
WATER_DEPTH_CODE_TO_M = {
    # 5段階（11-15）
    11: 0.5, 12: 1.0, 13: 2.0, 14: 5.0, 15: 10.0,
    # 7段階（21-27）
    21: 0.5, 22: 1.0, 23: 2.0, 24: 3.0, 25: 4.0, 26: 5.0, 27: 10.0,
}

# A33 coz: 区域コード → landslide_class（指定前も指定済相当に格上げ）
COZ_TO_LANDSLIDE_CLASS = {1: 1, 2: 2, 3: 1, 4: 2}

XLINK_NS = "http://www.w3.org/1999/xlink"


def cell_id_for(lat: float, lng: float) -> int:
    return math.floor(lat * GRID_SCALE) * 1_000_000 + math.floor(lng * GRID_SCALE)


def cell_center(cell_id: int) -> tuple[float, float]:
    lat_key, lng_key = divmod(cell_id, 1_000_000)
    return (lat_key + 0.5) / GRID_SCALE, (lng_key + 0.5) / GRID_SCALE


def _local(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def _parse_poslist(text: str) -> list[tuple[float, float]]:
    """posList（「緯度 経度」の空白区切り列）→ shapely 用 (lng, lat) 列。"""
    nums = [float(v) for v in text.split()]
    return [(nums[i + 1], nums[i]) for i in range(0, len(nums) - 1, 2)]


def _read_xml_text(path: str | Path) -> str:
    """XML をバイト列からデコードする。

    国土数値情報の GML は Shift_JIS の場合があり、ElementTree は
    マルチバイトエンコーディング宣言を直接扱えないため自前でデコードする。
    """
    raw = Path(path).read_bytes()
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        text = raw.decode("cp932")
    return re.sub(r'(<\?xml[^>]*?)encoding="[^"]*"', r"\1", text, count=1)


def _get_xlink_href(el) -> str | None:
    """{xlink}href または href 属性を取得。"""
    return el.get(f"{{{XLINK_NS}}}href") or el.get("href")


def _norm_gml_id(ref: str | None) -> str | None:
    """xlink:href / gml:id を辞書キー用に正規化（# 除去 + 小文字化）。

    A49 等では gml:id="Cv1_0" と href="#cv1_0" のように大文字小文字が
    一致しない実データがあるため、参照解決は常に小文字で行う。
    """
    if not ref:
        return None
    return ref.lstrip("#").lower()


def _collect_curves(root) -> dict[str, list[tuple[float, float]]]:
    """gml:id → 座標列（[(lng, lat), ...]）を全収集。"""
    curves: dict[str, list[tuple[float, float]]] = {}
    for curve in root.iter():
        if _local(curve.tag) != "Curve":
            continue
        cid = _norm_gml_id(
            curve.get("{http://www.opengis.net/gml/3.2}id") or curve.get("id")
        )
        if not cid:
            continue
        coords: list[tuple[float, float]] = []
        for pos in curve.iter():
            if _local(pos.tag) == "posList" and pos.text:
                coords.extend(_parse_poslist(pos.text))
        if coords:
            curves[cid] = coords
    return curves


def _expand_curve_aliases(
    root, curves: dict[str, list[tuple[float, float]]]
) -> dict[str, list[tuple[float, float]]]:
    """OrientableCurve の id → baseCurve 先の Curve 座標をエイリアスとして追加。

    A40 津波 GML では curveMember が #_Cv0_0（OrientableCurve）を指し、
    実座標は #Cv0_0（Curve）側にある。
    """
    expanded = dict(curves)
    for oc in root.iter():
        if _local(oc.tag) != "OrientableCurve":
            continue
        oid = _norm_gml_id(
            oc.get("{http://www.opengis.net/gml/3.2}id") or oc.get("id")
        )
        if not oid:
            continue
        for child in oc:
            if _local(child.tag) != "baseCurve":
                continue
            href = _get_xlink_href(child)
            cid = _norm_gml_id(href)
            if cid and cid in curves:
                expanded[oid] = curves[cid]
            break
    return expanded


def _resolve_ring(ring_el, curves) -> list[tuple[float, float]] | None:
    """gml:Ring 要素配下の curveMember@xlink を解決して座標列を返す。"""
    coords: list[tuple[float, float]] = []
    for member in ring_el.iter():
        if _local(member.tag) != "curveMember":
            continue
        href = _get_xlink_href(member)
        if not href:
            # 埋め込み Curve があるかもしれない
            for inner in member.iter():
                if _local(inner.tag) == "posList" and inner.text:
                    coords.extend(_parse_poslist(inner.text))
            continue
        cid = _norm_gml_id(href)
        ref = curves.get(cid) if cid else None
        if ref:
            coords.extend(ref)
    if len(coords) >= 4:
        return coords
    return None


def _collect_surfaces(root, curves) -> dict[str, Polygon]:
    """gml:id → shapely Polygon を全収集（interior は保守的に埋める）。"""
    surfaces: dict[str, Polygon] = {}
    for surface in root.iter():
        if _local(surface.tag) != "Surface":
            continue
        sid = _norm_gml_id(
            surface.get("{http://www.opengis.net/gml/3.2}id") or surface.get("id")
        )
        if not sid:
            continue
        # 最初の PolygonPatch のみを採用（実 GML は 1 パッチが常態）
        for patch in surface.iter():
            if _local(patch.tag) != "PolygonPatch":
                continue
            exterior_coords: list[tuple[float, float]] | None = None
            for child in patch:
                name = _local(child.tag)
                if name == "exterior":
                    for ring in child:
                        if _local(ring.tag) == "Ring":
                            exterior_coords = _resolve_ring(ring, curves)
                            break
                    if exterior_coords:
                        break
            if not exterior_coords or len(exterior_coords) < 4:
                continue
            # interior は保守判断で無視（穴も浸水扱い → exterior のみで内外判定）
            try:
                polygon = Polygon(exterior_coords)
                if polygon.is_valid and not polygon.is_empty:
                    surfaces[sid] = polygon
            except (ValueError, TypeError):
                logger.warning("surface %s: 無効なポリゴンをスキップ", sid)
            break
    return surfaces


def _iter_features(gml_path: str | Path):
    """GML から (属性 dict, Polygon) を列挙する。

    2 段解決（Curve→Surface→フィーチャ）に加え、旧来の gml:featureMember
    直下に埋め込まれた gml:Polygon（テストフィクスチャ）も後方互換で扱う。
    """
    root = ET.fromstring(_read_xml_text(gml_path))

    # 1) 旧 featureMember 形式（後方互換）
    for member in root.iter():
        if _local(member.tag) != "featureMember":
            continue
        for feature in member:
            attrs, polygon = _feature_attrs_and_embedded_polygon(feature)
            if polygon is not None:
                yield attrs, polygon

    # 2) 実 JPGIS 構造: Curve → Surface → *Area@bounds
    curves = _expand_curve_aliases(root, _collect_curves(root))
    if not curves:
        return
    surfaces = _collect_surfaces(root, curves)
    if not surfaces:
        return

    # フィーチャ = ksj:名前空間下で bounds@xlink 子を持つ要素
    for feature in root.iter():
        if _local(feature.tag) in {
            "Dataset", "featureMember", "Curve", "Surface", "boundedBy",
            "EnvelopeWithTimePeriod",
        }:
            continue
        bounds = None
        attrs: dict[str, str] = {}
        for child in feature:
            name = _local(child.tag)
            if name == "bounds":
                href = _get_xlink_href(child)
                if href:
                    bounds = _norm_gml_id(href)
            elif child.text and child.text.strip():
                attrs[name] = child.text.strip()
        if bounds is None:
            continue
        polygon = surfaces.get(bounds)
        if polygon is None:
            continue
        yield attrs, polygon


def _feature_attrs_and_embedded_polygon(feature):
    """旧 featureMember 形式（gml:Polygon 直下埋め込み）から (attrs, polygon) を返す。"""
    attrs: dict[str, str] = {}
    polygon = None
    for el in feature.iter():
        name = _local(el.tag)
        if name == "posList" and el.text and polygon is None:
            ring = _parse_poslist(el.text)
            if len(ring) >= 4:
                try:
                    p = Polygon(ring)
                    if p.is_valid:
                        polygon = p
                except (ValueError, TypeError):
                    pass
        elif el.text and el.text.strip():
            attrs[name] = el.text.strip()
    return attrs, polygon


def _find_rank(attrs: dict[str, str]) -> int | None:
    for name, value in attrs.items():
        lower = name.lower()
        if "depthrank" in lower or lower.endswith("rank"):
            try:
                return int(float(value))
            except ValueError:
                continue
    return None


def _find_water_depth_code(attrs: dict[str, str]) -> int | None:
    """A31 の waterDepth（11-15 / 21-27）を取得。"""
    for name, value in attrs.items():
        if name.lower() != "waterdepth":
            continue
        try:
            return int(float(value))
        except ValueError:
            continue
    return None


def _find_landslide_class(attrs: dict[str, str]) -> int | None:
    """A33 の区域コード coz を landslide_class(1/2) にマップ。

    旧フィクスチャの areaClass や *class もサポート（後方互換）。
    """
    # 実 A33: coz
    if "coz" in attrs:
        try:
            code = int(float(attrs["coz"]))
        except ValueError:
            code = None
        if code is not None and code in COZ_TO_LANDSLIDE_CLASS:
            return COZ_TO_LANDSLIDE_CLASS[code]
    # 旧フィクスチャ: areaClass / *Class
    for name, value in attrs.items():
        if name.lower() == "coz":
            continue
        if "class" in name.lower():
            try:
                cls = int(float(value))
            except ValueError:
                continue
            if cls in (1, 2):
                return cls
    return None


def _find_depth_m(attrs: dict[str, str]) -> float | None:
    """浸水深がメートル値で直接格納されている場合に取得する。"""
    for name, value in attrs.items():
        lower = name.lower()
        if "depth" in lower and "rank" not in lower and "classif" not in lower:
            try:
                return float(value)
            except ValueError:
                continue
    return None


_M_RANGE = re.compile(r"([0-9]+(?:\.[0-9]+)?)\s*m")


def _parse_depth_class_text(text: str) -> float | None:
    """『5m 以上 10m 未満』『20m 以上』『0.3m 未満』等を上限 m に変換。

    保守判断: 『X 以上』（上限なし）は既存 RANK_TO_DEPTH_M[6]=25.0 と整合する 25.0m を採用。
    """
    if not text:
        return None
    matches = _M_RANGE.findall(text)
    if not matches:
        return None
    nums = [float(m) for m in matches]
    has_less_than = "未満" in text
    has_greater_or_equal = "以上" in text
    if len(nums) == 1:
        if has_less_than and not has_greater_or_equal:
            # "0.5m 未満" 等 → 上限そのまま
            return nums[0]
        if has_greater_or_equal and not has_less_than:
            # "20m 以上" → 代表値 25.0m
            return max(nums[0], 25.0) if nums[0] >= 20 else nums[0]
        return nums[0]
    # "3m 以上 5m 未満" → 上限 = nums[-1]
    return nums[-1]


def _find_classification_of_water_depth(attrs: dict[str, str]) -> float | None:
    """A49 高潮 / A40 津波の classificationOfWaterDepth（CharacterString）を m 値に。"""
    for name, value in attrs.items():
        lower = name.lower()
        # A40 実データに cassificationOfWaterDepth（l 欠落）の typo あり
        if (
            "classificationofwaterdepth" in lower
            or "cassificationofwaterdepth" in lower
            or "classifyofwaterdepth" in lower
        ):
            m = _parse_depth_class_text(value)
            if m is not None:
                return m
    return None


def _cells_covered_by(polygon: Polygon) -> list[int]:
    """ポリゴンが覆うセル ID 列（セル中心の包含判定、ベクトル化）。"""
    minx, miny, maxx, maxy = polygon.bounds
    lat_key0 = math.floor(miny * GRID_SCALE)
    lat_key1 = math.floor(maxy * GRID_SCALE)
    lng_key0 = math.floor(minx * GRID_SCALE)
    lng_key1 = math.floor(maxx * GRID_SCALE)
    if (lat_key1 - lat_key0 + 1) * (lng_key1 - lng_key0 + 1) > 20_000_000:
        # 巨大ポリゴンは帯状に分割してメモリを抑える
        cells: list[int] = []
        for lat_key in range(lat_key0, lat_key1 + 1):
            cells.extend(_cells_in_band(polygon, lat_key, lng_key0, lng_key1))
        return cells
    return _cells_in_band(
        polygon, None, lng_key0, lng_key1, lat_key0=lat_key0, lat_key1=lat_key1
    )


def _cells_in_band(polygon, lat_key, lng_key0, lng_key1, lat_key0=None, lat_key1=None):
    import numpy as np

    if lat_key is not None:
        lat_keys = [lat_key]
    else:
        lat_keys = list(range(lat_key0, lat_key1 + 1))
    lng_keys = list(range(lng_key0, lng_key1 + 1))
    prepare(polygon)
    out: list[int] = []
    for lk in lat_keys:
        ys = np.full(len(lng_keys), (lk + 0.5) / GRID_SCALE)
        xs = np.array([(gk + 0.5) / GRID_SCALE for gk in lng_keys])
        mask = contains_xy(polygon, xs, ys)
        for gk, hit in zip(lng_keys, mask):
            if hit:
                out.append(lk * 1_000_000 + gk)
    return out


def _upsert_cells(db: sqlite3.Connection, column: str, values: list[tuple[int, float]]):
    if not values:
        return
    db.executemany(
        f"""
        INSERT INTO hazard_grid (cell_id, {column}) VALUES (?, ?)
        ON CONFLICT(cell_id) DO UPDATE SET
          {column} = MAX(hazard_grid.{column}, excluded.{column})
        """,
        values,
    )


def _import(db, gml_path, column, value_of) -> int:
    cells: dict[int, float] = {}
    for attrs, polygon in _iter_features(gml_path):
        value = value_of(attrs)
        if value is None:
            continue
        for cid in _cells_covered_by(polygon):
            if cid not in cells or cells[cid] < value:
                cells[cid] = value
    with db:
        _upsert_cells(db, column, sorted(cells.items()))
    return len(cells)


def _flood_depth_value(attrs: dict[str, str]) -> float | None:
    """洪水: waterDepth コード（新）→ depthRank（旧）→ 直接 m 値 の順で解決。"""
    code = _find_water_depth_code(attrs)
    if code is not None:
        m = WATER_DEPTH_CODE_TO_M.get(code)
        if m is not None:
            return m
    rank = _find_rank(attrs)
    if rank is not None:
        m = RANK_TO_DEPTH_M.get(rank)
        if m is not None:
            return m
    return _find_depth_m(attrs)


def _classification_or_rank_value(attrs: dict[str, str]) -> float | None:
    """高潮/津波: 直接 m 値 → classificationOfWaterDepth 文字列 → waterDepth コード → 旧 rank。"""
    depth = _find_depth_m(attrs)
    if depth is not None:
        return depth
    classified = _find_classification_of_water_depth(attrs)
    if classified is not None:
        return classified
    code = _find_water_depth_code(attrs)
    if code is not None:
        m = WATER_DEPTH_CODE_TO_M.get(code)
        if m is not None:
            return m
    rank = _find_rank(attrs)
    if rank is not None:
        return RANK_TO_DEPTH_M.get(rank)
    return None


def import_flood_gml(db: sqlite3.Connection, gml_path: str | Path) -> int:
    """洪水浸水想定区域 GML を取り込む。ランクは上限値に保守変換。"""
    return _import(db, gml_path, "flood_depth_m", _flood_depth_value)


def import_storm_surge_gml(db: sqlite3.Connection, gml_path: str | Path) -> int:
    """高潮浸水想定区域 GML（A49）を取り込む。"""
    return _import(db, gml_path, "storm_surge_m", _classification_or_rank_value)


def import_tsunami_gml(db: sqlite3.Connection, gml_path: str | Path) -> int:
    """津波浸水想定 GML（A40）を取り込む。"""
    return _import(db, gml_path, "tsunami_depth_m", _classification_or_rank_value)


def import_landslide_gml(db: sqlite3.Connection, gml_path: str | Path) -> int:
    """土砂災害警戒区域 GML（A33 v2）を取り込む（1: 警戒 / 2: 特別警戒）。"""
    return _import(db, gml_path, "landslide_class", _find_landslide_class)
