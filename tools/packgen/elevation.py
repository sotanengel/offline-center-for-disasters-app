"""国土地理院 標高タイル（DEM PNG）から標高を取得する。

DEM PNG 形式: 画素値 x = R*65536 + G*256 + B。x < 2^23 なら標高 h = x * 0.01 [m]、
x == 2^23 は無効値。タイルは Web メルカトルの XYZ 形式（z=14 が最大解像度）。
"""
from __future__ import annotations

import io
import math
from pathlib import Path

import numpy as np
import requests
from PIL import Image

DEM_TILE_URL = "https://cyberjapandata2.gsi.go.jp/general/dem/tiles/{z}/{x}/{y}.png"
TILE_SIZE = 256


def decode_dem_png(data: bytes) -> np.ndarray:
    """DEM PNG バイト列を標高 [m] の 2 次元配列（無効値は NaN）にデコードする。"""
    img = np.asarray(Image.open(io.BytesIO(data)).convert("RGB"), dtype=np.uint32)
    x = img[..., 0] * 65536 + img[..., 1] * 256 + img[..., 2]
    return np.where(x < 2**23, x * 0.01, np.nan)


def latlng_to_tile_pixel(lat: float, lng: float, z: int) -> tuple[int, int, int, int]:
    """緯度経度 → (タイル x, タイル y, ピクセル x, ピクセル y)。"""
    n = 2**z
    xt = (lng + 180.0) / 360.0 * n
    lat_rad = math.radians(min(max(lat, -85.05112878), 85.05112878))
    yt = (1.0 - math.log(math.tan(lat_rad) + 1.0 / math.cos(lat_rad)) / math.pi) / 2.0 * n
    x, y = int(xt), int(yt)
    px = min(int((xt - x) * TILE_SIZE), TILE_SIZE - 1)
    py = min(int((yt - y) * TILE_SIZE), TILE_SIZE - 1)
    return x, y, px, py


def _default_fetcher(z: int, x: int, y: int) -> bytes:
    resp = requests.get(DEM_TILE_URL.format(z=z, x=x, y=y), timeout=30)
    resp.raise_for_status()
    return resp.content


class ElevationProvider:
    """タイルキャッシュ付きの標高参照。fetcher を差し替えてテスト可能。"""

    def __init__(self, cache_dir: str | Path, fetcher=None, zoom: int = 14):
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.fetcher = fetcher or _default_fetcher
        self.zoom = zoom
        self._tile_cache: tuple[int, int, np.ndarray] | None = None

    def _tile(self, x: int, y: int) -> np.ndarray | None:
        if self._tile_cache and self._tile_cache[0] == x and self._tile_cache[1] == y:
            return self._tile_cache[2]
        path = self.cache_dir / f"{self.zoom}_{x}_{y}.png"
        if not path.exists():
            try:
                data = self.fetcher(self.zoom, x, y)
            except Exception:
                return None
            path.write_bytes(data)
        try:
            arr = decode_dem_png(path.read_bytes())
        except Exception:
            return None
        self._tile_cache = (x, y, arr)
        return arr

    def elevation_at(self, lat: float, lng: float) -> float | None:
        x, y, px, py = latlng_to_tile_pixel(lat, lng, self.zoom)
        tile = self._tile(x, y)
        if tile is None:
            return None
        value = float(tile[py, px])
        return None if math.isnan(value) else value

    def batch_elevation(self, points: list[tuple[float, float]]) -> list[float | None]:
        """大量地点の標高をタイル単位でまとめて取得する（タイル順にソートして
        デコード済み配列を使い回す）。"""
        indexed = []
        for i, (lat, lng) in enumerate(points):
            x, y, px, py = latlng_to_tile_pixel(lat, lng, self.zoom)
            indexed.append((x, y, px, py, i))
        indexed.sort()
        out: list[float | None] = [None] * len(points)
        current: tuple[int, int] | None = None
        arr = None
        for x, y, px, py, i in indexed:
            if (x, y) != current:
                arr = self._tile(x, y)
                current = (x, y)
            if arr is None:
                continue
            value = float(arr[py, px])
            out[i] = None if math.isnan(value) else value
        return out
