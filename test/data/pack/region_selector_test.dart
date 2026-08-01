import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/geo/geo_bounds.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/data/pack/region_pack_info.dart';
import 'package:offline_center_for_disasters/data/pack/region_selector.dart';

void main() {
  // tools/packgen/config.py と同一 bbox
  final tokyo = RegionPackInfo(
    regionKey: 'tokyo',
    path: '/packs/tokyo/pack.sqlite',
    bbox: GeoBounds(
      minLat: 35.49,
      maxLat: 35.91,
      minLng: 138.93,
      maxLng: 139.93,
    ),
  );
  final kanagawa = RegionPackInfo(
    regionKey: 'kanagawa',
    path: '/packs/kanagawa/pack.sqlite',
    bbox: GeoBounds(
      minLat: 35.10,
      maxLat: 35.68,
      minLng: 138.92,
      maxLng: 139.81,
    ),
  );
  final saitama = RegionPackInfo(
    regionKey: 'saitama',
    path: '/packs/saitama/pack.sqlite',
    bbox: GeoBounds(
      minLat: 35.74,
      maxLat: 36.29,
      minLng: 138.68,
      maxLng: 139.91,
    ),
  );

  test('県境付近では tokyo と kanagawa の両方が active になる', () {
    // 町田〜川崎付近（両 bbox の重なり帯）
    const origin = GeoPoint(35.55, 139.45);
    final active = selectActiveRegions(
      origin: origin,
      radiusKm: 10,
      installed: [tokyo, kanagawa, saitama],
    );
    expect(active.map((e) => e.regionKey), containsAll(['tokyo', 'kanagawa']));
    expect(active.map((e) => e.regionKey), isNot(contains('saitama')));
  });

  test('神奈川から十分離れた都内では tokyo のみ（saitama 未導入時）', () {
    // 10km 半径が kanagawa.maxLat(35.68) に届かない北寄り
    const origin = GeoPoint(35.80, 139.70);
    final active = selectActiveRegions(
      origin: origin,
      radiusKm: 10,
      installed: [tokyo, kanagawa],
    );
    expect(active.map((e) => e.regionKey).toList(), ['tokyo']);
  });

  test('導入パックが無ければ空', () {
    final active = selectActiveRegions(
      origin: const GeoPoint(35.55, 139.45),
      radiusKm: 10,
      installed: const [],
    );
    expect(active, isEmpty);
  });
}
