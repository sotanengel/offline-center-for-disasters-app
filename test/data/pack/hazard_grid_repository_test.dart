import 'package:offline_center_for_disasters/data/pack/pack_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/data/pack/hazard_grid_repository.dart';

import 'pack_fixture.dart';

/// §14.3 ハザードグリッドの 1 行参照（ハザードプライア・判定コンテキスト用）
void main() {
  late PackDatabase db;
  late HazardGridRepository repo;

  setUp(() async {
    db = createFixtureExecutor();
    await createSchema(db);
    repo = HazardGridRepository(db);
  });

  tearDown(() => db.close());

  test('cell_id は tools/packgen と同一のエンコード（1/2000 度グリッド）', () {
    expect(
      HazardGridRepository.cellIdFor(const GeoPoint(35.0, 139.0)),
      (35.0 * 2000).floor() * 1000000 + (139.0 * 2000).floor(),
    );
  });

  test('セル 1 行を HazardContext へ変換する', () async {
    final id = (35.0 * 2000).floor() * 1000000 + (139.0 * 2000).floor();
    await insertHazardCell(
      db,
      cellId: id,
      elevationM: 12.5,
      floodDepthM: 3.0,
      tsunamiDepthM: 5.0,
      landslideClass: 2,
      stormSurgeM: 1.5,
      volcanoClass: 1,
      distCoastM: 800,
      distRiverM: 120,
      denseWood: 1,
    );
    final ctx = await repo.contextAt(const GeoPoint(35.0, 139.0));
    expect(ctx.inFloodZone, isTrue);
    expect(ctx.floodDepthM, 3.0);
    expect(ctx.inTsunamiZone, isTrue);
    expect(ctx.tsunamiDepthM, 5.0);
    expect(ctx.landslideClass, 2);
    expect(ctx.inStormSurgeZone, isTrue);
    expect(ctx.stormSurgeM, 1.5);
    expect(ctx.volcanoClass, 1);
    expect(ctx.distCoastM, 800);
    expect(ctx.distRiverM, 120);
    expect(ctx.denseWood, isTrue);
    expect(ctx.currentElevationM, 12.5);
  });

  test('深さ 0 は区域外（inXxxZone=false）', () async {
    final id = (35.0 * 2000).floor() * 1000000 + (139.0 * 2000).floor();
    await insertHazardCell(db, cellId: id);
    final ctx = await repo.contextAt(const GeoPoint(35.0, 139.0));
    expect(ctx.inFloodZone, isFalse);
    expect(ctx.inTsunamiZone, isFalse);
    expect(ctx.inStormSurgeZone, isFalse);
    expect(ctx.landslideClass, 0);
  });

  test('グリッドに無い地点は既定値（区域外）として扱う', () async {
    final ctx = await repo.contextAt(const GeoPoint(36.0, 140.0));
    expect(ctx.inFloodZone, isFalse);
    expect(ctx.inTsunamiZone, isFalse);
    expect(ctx.currentElevationM, isNull);
  });
}
