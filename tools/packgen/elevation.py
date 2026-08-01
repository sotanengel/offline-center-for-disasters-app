"""国土地理院 標高タイル（DEM PNG）から標高を取得する。

DEM PNG 形式: 画素値 x = R*65536 + G*256 + B。x < 2^23 なら標高 h = x * 0.01 [m]、
x == 2^23 は無効値。タイルは Web メルカトルの XYZ 形式（z=14 が最大解像度）。

## 例外処理ポリシー（P0 修正）
以前は fetch/decode の全例外を握り潰して None を返し、キャッシュにも書かず、
ログにも残さなかった。結果、東京パックの全 3.3M ノードの elevation_m が
NULL になったが検知できないという事故が発生した（Issue #8）。

現在は:
- 例外を logger.warning に必ず記録する
- 失敗回数を `failure_count` として公開する
- 成功回数を `success_count` として公開する
- 呼び出し側は `failure_rate` を確認し、閾値超過時はビルドを失敗させる
- 成功時は必ずキャッシュに書き込む
"""
from __future__ import annotations

import io
import logging
import math
from pathlib import Path

import numpy as np
import requests
from PIL import Image

logger = logging.getLogger(__name__)

DEM_TILE_URL = "https://cyberjapandata.gsi.go.jp/xyz/dem_png/{z}/{x}/{y}.png"
TILE_SIZE = 256

# HTTP 404 = 対象タイル無し（海上・データ未整備）。これは「取得失敗」ではなく
# 「有効データ無し」なので failure_count には含めない。
_MISSING_STATUS = frozenset({404, 403})


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


class TileMissing(Exception):
    """タイル自体が提供されていない（404 等）。失敗ではなく「データ無し」。"""


def _default_fetcher(z: int, x: int, y: int) -> bytes:
    resp = requests.get(DEM_TILE_URL.format(z=z, x=x, y=y), timeout=30)
    if resp.status_code in _MISSING_STATUS:
        raise TileMissing(f"{z}/{x}/{y} not provided (HTTP {resp.status_code})")
    resp.raise_for_status()
    return resp.content


class ElevationProvider:
    """タイルキャッシュ付きの標高参照。fetcher を差し替えてテスト可能。

    Attributes:
        success_count: fetch または cache hit で有効配列を得た回数
        failure_count: fetch/decode 例外で標高を得られなかった回数
        missing_count: HTTP 404 等『タイル未提供』の回数（失敗扱いしない）
    """

    def __init__(self, cache_dir: str | Path, fetcher=None, zoom: int = 14):
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.fetcher = fetcher or _default_fetcher
        self.zoom = zoom
        self._tile_cache: tuple[int, int, np.ndarray | None] | None = None
        self.success_count = 0
        self.failure_count = 0
        self.missing_count = 0
        self._logged_failures: set[tuple[int, int]] = set()

    @property
    def failure_rate(self) -> float:
        total = self.success_count + self.failure_count
        return self.failure_count / total if total else 0.0

    def stats(self) -> dict[str, int | float]:
        return {
            "success": self.success_count,
            "failure": self.failure_count,
            "missing": self.missing_count,
            "failure_rate": self.failure_rate,
        }

    def _tile(self, x: int, y: int) -> np.ndarray | None:
        if self._tile_cache and self._tile_cache[0] == x and self._tile_cache[1] == y:
            return self._tile_cache[2]
        path = self.cache_dir / f"{self.zoom}_{x}_{y}.png"
        data: bytes | None = None
        if path.exists():
            try:
                data = path.read_bytes()
            except OSError as e:
                logger.warning("DEM cache read failed %s: %s", path, e)
        if data is None:
            try:
                data = self.fetcher(self.zoom, x, y)
            except TileMissing as e:
                self.missing_count += 1
                logger.debug("DEM tile missing %s/%s/%s: %s", self.zoom, x, y, e)
                self._tile_cache = (x, y, None)
                return None
            except Exception as e:
                self.failure_count += 1
                if (x, y) not in self._logged_failures:
                    self._logged_failures.add((x, y))
                    logger.warning(
                        "DEM fetch failed %s/%s/%s: %s", self.zoom, x, y, e
                    )
                self._tile_cache = (x, y, None)
                return None
            # 成功: 必ずキャッシュに書き込む（次回以降のリトライを不要にする）
            try:
                path.write_bytes(data)
            except OSError as e:
                logger.warning("DEM cache write failed %s: %s", path, e)
        try:
            arr = decode_dem_png(data)
        except Exception as e:
            self.failure_count += 1
            logger.warning(
                "DEM decode failed %s/%s/%s: %s", self.zoom, x, y, e
            )
            self._tile_cache = (x, y, None)
            return None
        self.success_count += 1
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
