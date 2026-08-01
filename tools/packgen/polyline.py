"""Google ポリライン符号化（精度 1e-5）。edges.geometry BLOB に使用。"""
from __future__ import annotations


def _encode_value(value: int, out: bytearray) -> None:
    value = ~(value << 1) if value < 0 else value << 1
    while value >= 0x20:
        out.append((0x20 | (value & 0x1F)) + 63)
        value >>= 5
    out.append(value + 63)


def encode_polyline(points: list[tuple[float, float]]) -> bytes:
    """(lat, lng) の列をポリライン符号化して bytes で返す。"""
    out = bytearray()
    prev_lat = prev_lng = 0
    for lat, lng in points:
        ilat = round(lat * 1e5)
        ilng = round(lng * 1e5)
        _encode_value(ilat - prev_lat, out)
        _encode_value(ilng - prev_lng, out)
        prev_lat, prev_lng = ilat, ilng
    return bytes(out)


def decode_polyline(data: bytes) -> list[tuple[float, float]]:
    """ポリライン符号化 bytes を (lat, lng) の列に復元する。"""
    points: list[tuple[float, float]] = []
    index = 0
    lat = lng = 0
    n = len(data)
    while index < n:
        for coord in ("lat", "lng"):
            shift = 0
            result = 0
            while True:
                b = data[index] - 63
                index += 1
                result |= (b & 0x1F) << shift
                shift += 5
                if b < 0x20:
                    break
            delta = ~(result >> 1) if result & 1 else result >> 1
            if coord == "lat":
                lat += delta
            else:
                lng += delta
        points.append((lat / 1e5, lng / 1e5))
    return points
