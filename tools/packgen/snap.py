"""避難所を道路グラフの最近傍ノードにスナップする（nearest_node_id 事前計算）。"""
from __future__ import annotations

import math
import sqlite3

# バケット幅（度）。約 1km 四方
_BUCKET = 0.01
# 探索の最大距離 [m]
_MAX_SNAP_M = 2000.0


def _bucket(lat: float, lng: float) -> tuple[int, int]:
    return (math.floor(lat / _BUCKET), math.floor(lng / _BUCKET))


def _dist_m(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    r = 6_371_000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lng2 - lng1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def snap_shelters_to_nodes(db: sqlite3.Connection, max_snap_m: float = _MAX_SNAP_M) -> int:
    """各避難所の最近傍ノードを探し nearest_node_id を更新する。スナップ件数を返す。"""
    buckets: dict[tuple[int, int], list[tuple[int, float, float]]] = {}
    for nid, lat, lng in db.execute("SELECT id, lat, lng FROM nodes"):
        buckets.setdefault(_bucket(lat, lng), []).append((nid, lat, lng))

    snapped = 0
    with db:
        for sid, lat, lng in db.execute("SELECT rowid, lat, lng FROM shelters"):
            blat, blng = _bucket(lat, lng)
            best: tuple[float, int] | None = None
            # 2km のスナップ閾値をカバーするため周囲 2 リング（約 5km 四方）を全探索
            for dlat in range(-2, 3):
                for dlng in range(-2, 3):
                    for nid, nlat, nlng in buckets.get((blat + dlat, blng + dlng), []):
                        d = _dist_m(lat, lng, nlat, nlng)
                        if best is None or d < best[0]:
                            best = (d, nid)
            if best is not None and best[0] <= max_snap_m:
                db.execute(
                    "UPDATE shelters SET nearest_node_id = ? WHERE rowid = ?",
                    (best[1], sid),
                )
                snapped += 1
    return snapped
