import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/geo/geo_bounds.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';

/// GeoBounds.covering — 現在地と避難先の両方を覆う最小 bbox（§16.1）。
///
/// 経路グラフを「現在地半径 12km」で読むと東京パックで 61 万ノードとなり
/// 実機では 70 秒経っても描画に至らなかった。避難先を先に確定してから
/// 両点を覆う範囲だけ読むことで、通常ケースを大幅に小さくする。
void main() {
  const origin = GeoPoint(35.687741, 139.850977);

  test('両方の点を含む', () {
    const shelter = GeoPoint(35.700, 139.870);
    final bounds = GeoBounds.covering(const [origin, shelter], marginKm: 1.0);
    expect(bounds.contains(origin), isTrue);
    expect(bounds.contains(shelter), isTrue);
  });

  test('マージン分だけ外側に広がる', () {
    const shelter = GeoPoint(35.700, 139.870);
    final tight = GeoBounds.covering(const [origin, shelter], marginKm: 0.0);
    final loose = GeoBounds.covering(const [origin, shelter], marginKm: 2.0);
    expect(loose.minLat, lessThan(tight.minLat));
    expect(loose.maxLat, greaterThan(tight.maxLat));
    expect(loose.minLng, lessThan(tight.minLng));
    expect(loose.maxLng, greaterThan(tight.maxLng));
  });

  test('1 点だけでもマージン付きの範囲になる', () {
    final bounds = GeoBounds.covering(const [origin], marginKm: 1.0);
    expect(bounds.contains(origin), isTrue);
    expect(bounds.maxLat, greaterThan(bounds.minLat));
    expect(bounds.maxLng, greaterThan(bounds.minLng));
  });

  test('近接 2 点なら県全域より遥かに小さい', () {
    const shelter = GeoPoint(35.695, 139.860);
    final bounds = GeoBounds.covering(const [origin, shelter], marginKm: 1.0);
    // 東京パックは南北約 1.2°。通常ケースはその 1/10 未満に収まること。
    expect(bounds.maxLat - bounds.minLat, lessThan(0.12));
  });

  test('空リストは例外', () {
    expect(
      () => GeoBounds.covering(const [], marginKm: 1.0),
      throwsArgumentError,
    );
  });
}
