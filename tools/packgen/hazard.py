"""国土数値情報のハザード GML（JPGIS2.1）を hazard_grid（§14.3）へ変換する。

グリッド: 緯度・経度をそれぞれ 1/2000 度（約 50m）で分割したセル。
cell_id = floor(lat*2000) * 1_000_000 + floor(lng*2000)（int64、決定論的）。

浸水深ランク（国土数値情報 A31 系の定義）→ 代表値は人命優先で **ランク上限** を採用:
  1: <0.5m → 0.5 / 2: 0.5-3m → 3.0 / 3: 3-5m → 5.0 /
  4: 5-10m → 10.0 / 5: 10-20m → 20.0 / 6: >=20m → 25.0
"""
from __future__ import annotations

import math
import re
import sqlite3
import xml.etree.ElementTree as ET
from pathlib import Path

from shapely.geometry import Polygon
from shapely import contains_xy, prepare

GRID_SCALE = 2000  # 1/2000 度 ≈ 50m メッシュ

RANK_TO_DEPTH_M = {1: 0.5, 2: 3.0, 3: 5.0, 4: 10.0, 5: 20.0, 6: 25.0}


def cell_id_for(lat: float, lng: float) -> int:
    return math.floor(lat * GRID_SCALE) * 1_000_000 + math.floor(lng * GRID_SCALE)


def cell_center(cell_id: int) -> tuple[float, float]:
    lat_key, lng_key = divmod(cell_id, 1_000_000)
    return (lat_key + 0.5) / GRID_SCALE, (lng_key + 0.5) / GRID_SCALE


def _local(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def _parse_poslist(text: str) -> list[tuple[float, float]]:
    """posList（緯度 経度 の空白区切り列）→ shapely 用 (lng, lat) 列。"""
    nums = [float(v) for v in text.split()]
    return [(nums[i + 1], nums[i]) for i in range(0, len(nums) - 1, 2)]


_ENCODING_DECL = re.compile(rb'(<\?xml[^>]*?)encoding="[^"]*"')


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
    # エンコーディング宣言を除去（str 解析時に宣言があると ValueError になる）
    return re.sub(r'(<\?xml[^>]*?)encoding="[^"]*"', r"\1", text, count=1)


def _iter_features(gml_path: str | Path):
    """GML から (属性dict, Polygon) を列挙する。属性名は名前空間を除去して比較。"""
    tree = ET.ElementTree(ET.fromstring(_read_xml_text(gml_path)))
    for member in tree.iter():
        if _local(member.tag) != "featureMember":
            continue
        for feature in member:
            attrs: dict[str, str] = {}
            polygon = None
            for el in feature.iter():
                name = _local(el.tag)
                if name == "posList" and el.text:
                    ring = _parse_poslist(el.text)
                    if len(ring) >= 4:
                        polygon = Polygon(ring)
                elif el.text and el.text.strip():
                    attrs[name] = el.text.strip()
            if polygon is not None and polygon.is_valid:
                yield attrs, polygon


def _find_rank(attrs: dict[str, str]) -> int | None:
    for name, value in attrs.items():
        lower = name.lower()
        if "depthrank" in lower or lower.endswith("rank"):
            try:
                return int(float(value))
            except ValueError:
                continue
    return None


def _find_class(attrs: dict[str, str]) -> int | None:
    for name, value in attrs.items():
        if "class" in name.lower():
            try:
                return int(float(value))
            except ValueError:
                continue
    return None


def _find_depth_m(attrs: dict[str, str]) -> float | None:
    """浸水深がメートル値で直接格納されている場合に取得する。"""
    for name, value in attrs.items():
        lower = name.lower()
        if "depth" in lower and "rank" not in lower:
            try:
                return float(value)
            except ValueError:
                continue
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
    return _cells_in_band(polygon, None, lng_key0, lng_key1,
                          lat_key0=lat_key0, lat_key1=lat_key1)


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


def import_flood_gml(db: sqlite3.Connection, gml_path: str | Path) -> int:
    """洪水浸水想定区域 GML を取り込む。ランクは上限値に保守変換。"""
    return _import(db, gml_path, "flood_depth_m",
                   lambda a: RANK_TO_DEPTH_M.get(_find_rank(a) or -1))


def import_storm_surge_gml(db: sqlite3.Connection, gml_path: str | Path) -> int:
    """高潮浸水想定区域 GML を取り込む。"""
    return _import(db, gml_path, "storm_surge_m",
                   lambda a: RANK_TO_DEPTH_M.get(_find_rank(a) or -1))


def import_tsunami_gml(db: sqlite3.Connection, gml_path: str | Path) -> int:
    """津波浸水想定 GML を取り込む。メートル値を優先、無ければランク変換。"""
    def value_of(attrs):
        depth = _find_depth_m(attrs)
        if depth is not None:
            return depth
        return RANK_TO_DEPTH_M.get(_find_rank(attrs) or -1)

    return _import(db, gml_path, "tsunami_depth_m", value_of)


def import_landslide_gml(db: sqlite3.Connection, gml_path: str | Path) -> int:
    """土砂災害警戒区域 GML を取り込む（1: 警戒区域 / 2: 特別警戒区域）。"""
    return _import(db, gml_path, "landslide_class",
                   lambda a: _find_class(a))
