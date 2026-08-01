import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/app/providers.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/situation_slots.dart';
import 'package:offline_center_for_disasters/domain/usecases/destination_plan_progress.dart';
import 'package:offline_center_for_disasters/domain/usecases/destination_planner.dart';

import '../helpers/fake_evacuation_pack.dart';

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
      expect(bounds.maxLat - bounds.minLat, lessThan(0.06));
    });

    test('§4.4 / Q10 の 20km 拡大先でも両端を含む', () {
      const farShelter = GeoPoint(35.8678, 139.850977);
      final bounds = routeGraphBoundsFor(origin, farShelter);
      expect(bounds.contains(origin), isTrue);
      expect(bounds.contains(farShelter), isTrue);
    });
  });

  group('onProgress', () {
    test('packMissing でも hazardContext まで報告する', () async {
      const slots = SituationSlots(
        disasterType: DisasterType.earthquake,
        source: SlotSource.tile,
      );
      final reported = <DestinationPlanProgress>[];
      await const DestinationPlanner().plan(
        slots: slots,
        origin: kDefaultOrigin,
        onProgress: reported.add,
      );
      expect(reported, contains(DestinationPlanProgress.hazardContext));
    });

    test('探索〜完了まで順序通りに報告する', () async {
      const slots = SituationSlots(
        disasterType: DisasterType.earthquake,
        source: SlotSource.tile,
      );
      final reported = <DestinationPlanProgress>[];
      await const DestinationPlanner().plan(
        slots: slots,
        origin: kDefaultOrigin,
        pack: FakeEvacuationPack(),
        onProgress: reported.add,
      );
      expect(reported.map((p) => p.label), [
        DestinationPlanProgress.hazardContext.label,
        DestinationPlanProgress.shelterSearch.label,
      ]);
    });
  });
}
