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
