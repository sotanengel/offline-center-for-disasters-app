import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/data/pack/hazard_grid_repository.dart';
import 'package:offline_center_for_disasters/data/pack/pack_database.dart';
import 'package:offline_center_for_disasters/data/pack/pack_hazard_prior.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/policies/hazard_prior_scorer.dart';

import 'pack_fixture.dart';

/// §3.4-a: パックの hazard_grid + Scorer で HazardPrior が動くこと。
void main() {
  late PackDatabase db;
  late PackHazardPrior prior;

  setUp(() async {
    db = createFixtureExecutor();
    await createSchema(db);
    prior = PackHazardPrior(HazardGridRepository(db), HazardPriorScorer());
  });

  tearDown(() => db.close());

  test('津波想定域のセルでは tsunami が最上位', () async {
    final cellId = HazardGridRepository.cellIdFor(const GeoPoint(35.0, 139.0));
    await insertHazardCell(db, cellId: cellId, tsunamiDepthM: 3.0);
    final ranks = await prior.rank(const GeoPoint(35.0, 139.0));
    expect(ranks, isNotEmpty);
    expect(ranks.first.type, DisasterType.tsunami);
  });

  test('セル無しでも 7 種別分は返す (既定コンテキストで採点)', () async {
    final ranks = await prior.rank(const GeoPoint(35.0, 139.0));
    // Scorer が返す種別数と一致 (7)
    expect(ranks.length, 7);
  });
}
