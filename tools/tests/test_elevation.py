"""国土地理院 標高タイル（DEM PNG）デコードと標高付与のテスト。"""
import io

import numpy as np
import pytest
from PIL import Image

from packgen.elevation import (
    ElevationProvider,
    decode_dem_png,
    latlng_to_tile_pixel,
)

Z = 14


def _make_dem_png(elevations: np.ndarray) -> bytes:
    """標高 [m] の 2 次元配列から GSI DEM PNG 形式のバイト列を作る。"""
    h, w = elevations.shape
    img = np.zeros((h, w, 3), dtype=np.uint8)
    valid = ~np.isnan(elevations)
    x = np.where(valid, np.round(elevations / 0.01), 2**23).astype(np.uint32)
    img[..., 0] = (x // 65536) % 256
    img[..., 1] = (x // 256) % 256
    img[..., 2] = x % 256
    buf = io.BytesIO()
    Image.fromarray(img, "RGB").save(buf, format="PNG")
    return buf.getvalue()


def test_decode_dem_png():
    elevations = np.full((256, 256), 12.34)
    elevations[0, 0] = np.nan  # 無効値
    data = _make_dem_png(elevations)
    decoded = decode_dem_png(data)
    assert decoded.shape == (256, 256)
    assert decoded[100, 100] == pytest.approx(12.34, abs=0.01)
    assert np.isnan(decoded[0, 0])


def test_latlng_to_tile_pixel_origin():
    # 北西端 (z タイル (0,0) の北西隅) はピクセル (0,0)
    lat = 85.05112878
    lng = -180.0
    x, y, px, py = latlng_to_tile_pixel(lat, lng, 0)
    assert (x, y) == (0, 0)
    assert (px, py) == (0, 0)


def test_elevation_at_with_stub_fetcher(tmp_path):
    elevations = np.full((256, 256), 42.0)
    png = _make_dem_png(elevations)

    provider = ElevationProvider(
        cache_dir=tmp_path / "dem", fetcher=lambda z, x, y: png
    )
    h = provider.elevation_at(35.681, 139.767)
    assert h == pytest.approx(42.0, abs=0.01)


def test_elevation_caches_tiles(tmp_path):
    elevations = np.full((256, 256), 10.0)
    png = _make_dem_png(elevations)
    calls = []

    def fetcher(z, x, y):
        calls.append((z, x, y))
        return png

    provider = ElevationProvider(cache_dir=tmp_path / "dem", fetcher=fetcher)
    provider.elevation_at(35.681, 139.767)
    provider.elevation_at(35.682, 139.768)  # 同タイル内
    assert len(calls) == 1


def test_fetch_failure_tracked_not_swallowed(tmp_path):
    """タイル取得失敗は握り潰さず、失敗カウンタと成功カウンタで観測できること。

    現状の実装は Exception を全て呑んで None を返し、キャッシュにも書かず、
    ログにも残さないので、全ノードが NULL 標高になっても検知できなかった（P0）。
    """
    def fetcher(z, x, y):
        raise RuntimeError("simulated network failure")

    provider = ElevationProvider(cache_dir=tmp_path / "dem", fetcher=fetcher)
    assert provider.elevation_at(35.681, 139.767) is None
    assert provider.elevation_at(35.700, 139.800) is None
    assert provider.failure_count >= 2
    assert provider.success_count == 0


def test_fetch_success_tracked_and_cached(tmp_path):
    elevations = np.full((256, 256), 5.5)
    png = _make_dem_png(elevations)
    provider = ElevationProvider(
        cache_dir=tmp_path / "dem", fetcher=lambda z, x, y: png
    )
    provider.elevation_at(35.681, 139.767)
    assert provider.success_count == 1
    assert provider.failure_count == 0
    # キャッシュへ書き出されている（後続の別プロセスからも読める）
    cached = list((tmp_path / "dem").glob("*.png"))
    assert len(cached) == 1


def test_failure_rate_helper(tmp_path):
    """成功と失敗が混在する場合の失敗率が正しく計算できる。"""
    elevations = np.full((256, 256), 3.0)
    png = _make_dem_png(elevations)
    call = {"n": 0}

    def flaky(z, x, y):
        call["n"] += 1
        if call["n"] % 2 == 0:
            raise RuntimeError("boom")
        return png

    provider = ElevationProvider(cache_dir=tmp_path / "dem", fetcher=flaky)
    for i in range(6):
        provider.elevation_at(35.6 + i * 0.05, 139.7 + i * 0.05)
    # 6 タイル取得（別タイル毎）。3 成功 / 3 失敗を想定
    assert provider.success_count + provider.failure_count == 6
    assert 0.0 < provider.failure_rate < 1.0
