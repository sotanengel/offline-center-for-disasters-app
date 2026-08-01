import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/geo/geo.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/core/geo/polyline_codec.dart';

void main() {
  group('haversineM（§9 補助: 直線距離）', () {
    test('東京駅→新宿駅は約 6.1km', () {
      const tokyo = GeoPoint(35.681236, 139.767125);
      const shinjuku = GeoPoint(35.689521, 139.700492);
      final d = haversineM(tokyo, shinjuku);
      expect(d, greaterThan(5900));
      expect(d, lessThan(6300));
    });

    test('同一地点は 0', () {
      const p = GeoPoint(35.0, 139.0);
      expect(haversineM(p, p), 0);
    });
  });

  group('bearingDeg（ターンバイターン用方位）', () {
    test('真北は 0 度', () {
      const a = GeoPoint(35.0, 139.0);
      const b = GeoPoint(35.01, 139.0);
      expect(bearingDeg(a, b), closeTo(0, 0.5));
    });

    test('真東は 90 度', () {
      const a = GeoPoint(35.0, 139.0);
      const b = GeoPoint(35.0, 139.01);
      expect(bearingDeg(a, b), closeTo(90, 0.5));
    });

    test('真西は 270 度', () {
      const a = GeoPoint(35.0, 139.01);
      const b = GeoPoint(35.0, 139.0);
      expect(bearingDeg(a, b), closeTo(270, 0.5));
    });
  });

  group('normalizeTurnDeg（方位差の正規化）', () {
    test('350°→10° は +20°（右回り）', () {
      expect(normalizeTurnDeg(10 - 350), closeTo(20, 1e-9));
    });

    test('10°→350° は -20°（左回り）', () {
      expect(normalizeTurnDeg(350 - 10), closeTo(-20, 1e-9));
    });
  });

  group('ポリライン符号化（§14.2 geometry BLOB と互換）', () {
    test('Google 公式例を符号化できる', () {
      final encoded = encodePolyline(const [
        GeoPoint(38.5, -120.2),
        GeoPoint(40.7, -120.95),
        GeoPoint(43.252, -126.453),
      ]);
      expect(encoded, '_p~iF~ps|U_ulLnnqC_mqNvxq`@');
    });

    test('Google 公式例を復号できる', () {
      final decoded = decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
      expect(decoded.length, 3);
      expect(decoded[0].lat, closeTo(38.5, 1e-6));
      expect(decoded[0].lng, closeTo(-120.2, 1e-6));
      expect(decoded[2].lat, closeTo(43.252, 1e-6));
      expect(decoded[2].lng, closeTo(-126.453, 1e-6));
    });

    test('ラウンドトリップ（日本座標）', () {
      const points = [
        GeoPoint(35.681236, 139.767125),
        GeoPoint(35.689521, 139.700492),
        GeoPoint(35.658034, 139.701636),
      ];
      final decoded = decodePolyline(encodePolyline(points));
      expect(decoded.length, points.length);
      for (var i = 0; i < points.length; i++) {
        expect(decoded[i].lat, closeTo(points[i].lat, 1e-5));
        expect(decoded[i].lng, closeTo(points[i].lng, 1e-5));
      }
    });
  });
}
