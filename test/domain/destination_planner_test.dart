import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/domain/usecases/destination_planner.dart';

void main() {
  test('formatDistanceM: 1000m 以上は km 表示', () {
    expect(formatDistanceM(1200), '1.2km');
    expect(formatDistanceM(850), '850m');
  });

  group('routeGraphBoundsFor (§16.1 実機メモリ制約)', () {
    const origin = GeoPoint(35.687741, 139.850977);

    test('現在地と避難先の両方を含む', () {
      const shelter = GeoPoint(35.700, 139.870);
      final bounds = routeGraphBoundsFor(origin, shelter);
      expect(bounds.contains(origin), isTrue);
      expect(bounds.contains(shelter), isTrue);
    });

    test('通常ケース（近傍の避難先）では範囲がごく狭い', () {
      const shelter = GeoPoint(35.695, 139.860);
      final bounds = routeGraphBoundsFor(origin, shelter);
      // 半径 12km 固定だと緯度幅 0.216°（61 万ノード）になり実機で描画に至らない。
      expect(bounds.maxLat - bounds.minLat, lessThan(0.06));
    });

    test('§4.4 の 10km 拡大先でも両端を含む', () {
      // 北へ約 10km の避難先
      const farShelter = GeoPoint(35.7778, 139.850977);
      final bounds = routeGraphBoundsFor(origin, farShelter);
      expect(bounds.contains(origin), isTrue);
      expect(bounds.contains(farShelter), isTrue);
    });
  });
}
