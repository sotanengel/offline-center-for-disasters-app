"""OpenStreetMap データから歩行用道路グラフ（§14.2 nodes/edges）を構築する。

- 対象: 徒歩通行可能な highway 種別のみ（motorway 等は除外）
- エッジ: way 内の連続ノード対。双方向（徒歩のため oneway は無視）
- geometry: ポリライン符号化 BLOB（packgen.polyline）
"""
from __future__ import annotations

import math
import sqlite3
from pathlib import Path

import osmium

from packgen.polyline import encode_polyline
from packgen.schema import init_db

# 徒歩ネットワークに含める highway 値
WALKABLE_HIGHWAYS = {
    "footway", "pedestrian", "path", "cycleway", "living_street", "track",
    "residential", "unclassified", "service",
    "tertiary", "secondary", "primary",
    "steps",
}

# way_type: 0:footway 1:residential 2:primary 3:steps 4:underpass 5:crossing
def _way_type(tags) -> int:
    highway = tags.get("highway", "")
    if highway == "steps":
        return 3
    if tags.get("tunnel") in ("yes", "1", "true"):
        return 4
    if tags.get("footway") == "crossing":
        return 5
    if highway in ("footway", "pedestrian", "path", "cycleway", "living_street", "track"):
        return 0
    if highway == "primary":
        return 2
    return 1


def _width_class(tags) -> int:
    try:
        width = float(tags.get("width", ""))
    except ValueError:
        return 0
    if width < 1.5:
        return 1
    if width <= 4.0:
        return 2
    return 3


def haversine_m(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """2 点間の距離 [m]（球面近似）。"""
    r = 6_371_000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lng2 - lng1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


class _WayCollector(osmium.SimpleHandler):
    """pass 1: 徒歩 way と参照ノード ID を収集する。"""

    def __init__(self):
        super().__init__()
        self.ways: list[tuple[list[int], dict]] = []
        self.node_ids: set[int] = set()

    def way(self, w):
        highway = w.tags.get("highway")
        if highway not in WALKABLE_HIGHWAYS:
            return
        refs = [n.ref for n in w.nodes]
        if len(refs) < 2:
            return
        tags = {t.k: t.v for t in w.tags}
        self.ways.append((refs, tags))
        self.node_ids.update(refs)


class _NodeCollector(osmium.SimpleHandler):
    """pass 2: 参照されるノードの座標のみ収集する。"""

    def __init__(self, wanted: set[int]):
        super().__init__()
        self.wanted = wanted
        self.coords: dict[int, tuple[float, float]] = {}

    def node(self, n):
        if n.id in self.wanted:
            self.coords[n.id] = (n.location.lat, n.location.lon)


def build_graph(db_path: str | Path, osm_path: str | Path) -> sqlite3.Connection:
    """OSM ファイル（.osm / .osm.pbf）から nodes/edges を構築する。"""
    db_path = Path(db_path)
    if db_path.exists():
        db_path.unlink()
    db = init_db(db_path)
    populate_graph(db, osm_path)
    return db


def populate_graph(db: sqlite3.Connection, osm_path: str | Path) -> None:
    """既存 DB に OSM ファイルの道路グラフを書き込む。"""
    collector = _WayCollector()
    collector.apply_file(str(osm_path))

    nodes = _NodeCollector(collector.node_ids)
    nodes.apply_file(str(osm_path))
    coords = nodes.coords
    if not coords:
        return

    with db:
        db.executemany(
            "INSERT INTO nodes (id, lat, lng) VALUES (?, ?, ?)",
            ((nid, lat, lng) for nid, (lat, lng) in coords.items()),
        )
        edge_rows = []
        for refs, tags in collector.ways:
            way_type = _way_type(tags)
            width_class = _width_class(tags)
            has_steps = 1 if tags.get("highway") == "steps" else 0
            is_lit = 1 if tags.get("lit") == "yes" else 0
            name = tags.get("name")
            for a, b in zip(refs, refs[1:]):
                if a not in coords or b not in coords:
                    continue
                lat1, lng1 = coords[a]
                lat2, lng2 = coords[b]
                length = haversine_m(lat1, lng1, lat2, lng2)
                geom = encode_polyline([(lat1, lng1), (lat2, lng2)])
                edge_rows.append(
                    (a, b, length, geom, way_type, width_class, has_steps, is_lit, name)
                )
        db.executemany(
            """
            INSERT INTO edges
              (from_node, to_node, length_m, geometry, way_type, width_class,
               has_steps, is_lit, landmark_name)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            edge_rows,
        )
