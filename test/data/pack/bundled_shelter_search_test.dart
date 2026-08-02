import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/geo/geo.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/data/pack/hazard_grid_repository.dart';
import 'package:offline_center_for_disasters/data/pack/pack_loader.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/shelter_query.dart';

/// 市川付近（35.7284921, 139.9000146）で千葉側避難所が最寄りになること。
///
/// tools/out/bundled/pack.sqlite（merge 済み）が必要。
void main() {
  final bundledPath = File(
    '${Directory.current.path}/tools/out/bundled/pack.sqlite',
  );

  test('市川付近の津波避難先は千葉側（統合パック）', () async {
    if (!bundledPath.existsSync()) {
      expect(
        File(
          '${Directory.current.path}/tools/out/tokyo/pack.sqlite',
        ).existsSync(),
        isTrue,
        reason: 'bundled 未生成。cd tools && uv run python -m packgen.merge_pack',
      );
      return;
    }

    const origin = GeoPoint(35.7284921, 139.9000146);
    final opened = await PackLoader.open(bundledPath.path);
    final pack = opened.valueOrNull;
    expect(pack, isNotNull);

    try {
      final search = await pack!.shelterFinder.find(
        origin: origin,
        query: const ShelterQuery(
          disasterType: DisasterType.tsunami,
          minElevationM: 5,
        ),
      );
      expect(search.notFound, isFalse);
      expect(search.shelters, isNotEmpty);

      final nearest = search.shelters.first;
      final distanceM = haversineM(origin, GeoPoint(nearest.lat, nearest.lng));
      expect(distanceM, lessThan(3000), reason: '最寄り ${nearest.name}');
      expect(nearest.name, isNot(contains('台場')));
    } finally {
      await pack?.close();
    }
  }, tags: const ['real_pack']);

  test('HazardGridRepository は統合パックで動作する', () async {
    if (!bundledPath.existsSync()) return;

    final opened = await PackLoader.open(bundledPath.path);
    final pack = opened.valueOrNull;
    expect(pack, isNotNull);

    try {
      final repo = HazardGridRepository(pack!.db);
      final ctx = await repo.contextAt(const GeoPoint(35.7284921, 139.9000146));
      expect(ctx, isNotNull);
    } finally {
      await pack?.close();
    }
  }, tags: const ['real_pack']);
}
