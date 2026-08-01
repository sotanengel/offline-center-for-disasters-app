"""Google ポリライン符号化（geometry BLOB 用）のテスト。"""
from packgen.polyline import decode_polyline, encode_polyline


def test_encode_known_value():
    # Google 公式ドキュメントの例: (38.5, -120.2), (40.7, -120.95), (43.252, -126.453)
    points = [(38.5, -120.2), (40.7, -120.95), (43.252, -126.453)]
    assert encode_polyline(points) == b"_p~iF~ps|U_ulLnnqC_mqNvxq`@"


def test_roundtrip():
    points = [(35.681, 139.767), (35.682, 139.768), (35.0, 135.0)]
    decoded = decode_polyline(encode_polyline(points))
    assert len(decoded) == len(points)
    for (lat, lng), (dlat, dlng) in zip(points, decoded):
        assert abs(lat - dlat) < 1e-5
        assert abs(lng - dlng) < 1e-5


def test_empty():
    assert encode_polyline([]) == b""
    assert decode_polyline(b"") == []
