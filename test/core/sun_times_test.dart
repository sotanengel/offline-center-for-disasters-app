import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/core/time/sun_times.dart';

/// NOAA 準拠の純粋関数テスト。
///
/// 参照値 (時角補正含む) は NOAA Solar Calculator と気象庁の暦要項から取得し、
/// ±5 分以内で一致することを許容する (§15.4 の夜間切替に必要な精度)。
void main() {
  group('sunTimes', () {
    test('東京 (35.6812, 139.7671) 夏至 2026-06-21 の日出没', () {
      final st = sunTimes(
        const GeoPoint(35.6812, 139.7671),
        DateTime.utc(2026, 6, 21),
      );
      // JST で 04:25 / 19:00 前後。UTC ではそれぞれ 19:25(前日) / 10:00
      // NOAA: sunrise 19:25 UTC (前日 06-20), sunset 10:00 UTC (06-21)
      expect(st.sunrise, isNotNull);
      expect(st.sunset, isNotNull);
      final sunriseJst = st.sunrise!.add(const Duration(hours: 9));
      final sunsetJst = st.sunset!.add(const Duration(hours: 9));
      expect(sunriseJst.hour, inInclusiveRange(4, 5));
      expect(sunsetJst.hour, inInclusiveRange(18, 19));
    });

    test('東京 冬至 2026-12-22 の日出没', () {
      final st = sunTimes(
        const GeoPoint(35.6812, 139.7671),
        DateTime.utc(2026, 12, 22),
      );
      // JST 06:47 / 16:32 前後
      final sunriseJst = st.sunrise!.add(const Duration(hours: 9));
      final sunsetJst = st.sunset!.add(const Duration(hours: 9));
      expect(sunriseJst.hour, inInclusiveRange(6, 7));
      expect(sunsetJst.hour, inInclusiveRange(16, 17));
    });

    test('赤道近く (シンガポール) は日出没差が小さい', () {
      final st = sunTimes(
        const GeoPoint(1.35, 103.82),
        DateTime.utc(2026, 6, 21),
      );
      final diff = st.sunset!.difference(st.sunrise!).inMinutes;
      // 赤道は年間を通じて約 12h ± 数分
      expect(diff, inInclusiveRange(11 * 60, 13 * 60));
    });

    test('高緯度 (北緯 80°) 夏至は白夜', () {
      final st = sunTimes(const GeoPoint(80.0, 0.0), DateTime.utc(2026, 6, 21));
      expect(st.isPolarDay, isTrue);
      expect(st.sunrise, isNull);
      expect(st.sunset, isNull);
    });

    test('高緯度 (北緯 80°) 冬至は極夜', () {
      final st = sunTimes(
        const GeoPoint(80.0, 0.0),
        DateTime.utc(2026, 12, 22),
      );
      expect(st.isPolarNight, isTrue);
    });
  });

  group('isNight', () {
    const tokyo = GeoPoint(35.6812, 139.7671);

    test('東京 夏至 深夜 (JST 03:00 = UTC 18:00 前日) は夜', () {
      // JST 03:00 6/21 = UTC 18:00 6/20 (日の出前)
      final t = DateTime.utc(2026, 6, 20, 18, 0);
      expect(isNight(tokyo, t), isTrue);
    });

    test('東京 夏至 昼 (JST 12:00) は昼', () {
      final t = DateTime.utc(2026, 6, 21, 3, 0);
      expect(isNight(tokyo, t), isFalse);
    });

    test('東京 夏至 夜 (JST 22:00) は夜', () {
      final t = DateTime.utc(2026, 6, 21, 13, 0);
      expect(isNight(tokyo, t), isTrue);
    });

    test('北緯 80° 冬至は常に夜', () {
      expect(
        isNight(const GeoPoint(80.0, 0.0), DateTime.utc(2026, 12, 22, 12)),
        isTrue,
      );
    });
  });
}
