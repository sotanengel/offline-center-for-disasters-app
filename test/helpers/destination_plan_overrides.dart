import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_center_for_disasters/app/providers.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/domain/entities/route_result.dart';
import 'package:offline_center_for_disasters/domain/entities/shelter.dart';
import 'package:offline_center_for_disasters/domain/entities/situation_slots.dart';
import 'package:offline_center_for_disasters/domain/usecases/destination_plan_progress.dart';
import 'package:offline_center_for_disasters/domain/usecases/destination_planner.dart';

/// テスト用: [destinationPlanProvider] を実パックなしで成功させる。
Override destinationPlanProviderOverride({
  String shelterName = '千代田区立神田小学校',
  double distanceM = 1200,
}) {
  final plan = DestinationPlan(
    origin: kDefaultOrigin,
    shelter: Shelter(
      id: 'test-shelter',
      name: shelterName,
      lat: 35.688741,
      lng: 139.851977,
      elevationM: 15,
      okEarthquake: true,
      nearestNodeId: 1,
    ),
    distanceM: distanceM,
    route: RouteResult(
      targetId: 'test-shelter',
      costSeconds: 600,
      distanceM: distanceM,
      polyline: [kDefaultOrigin, const GeoPoint(35.688741, 139.851977)],
      instructions: const [],
    ),
  );
  return destinationPlanProvider.overrideWith(
    () => _StubDestinationPlanNotifier(plan),
  );
}

/// テスト用: 探索中のプログレス表示を検証する。
Override destinationPlanLoadingOverride({
  DestinationPlanProgress progress = DestinationPlanProgress.shelterSearch,
}) {
  return destinationPlanProvider.overrideWith(
    () => _StubDestinationPlanNotifier.loading(progress),
  );
}

class _StubDestinationPlanNotifier extends DestinationPlanNotifier {
  _StubDestinationPlanNotifier._(this._initial);

  factory _StubDestinationPlanNotifier(DestinationPlan plan) =>
      _StubDestinationPlanNotifier._(DestinationPlanReady(plan));

  factory _StubDestinationPlanNotifier.loading(
    DestinationPlanProgress progress,
  ) => _StubDestinationPlanNotifier._(DestinationPlanLoading(progress));

  final DestinationPlanState _initial;

  @override
  DestinationPlanState build(SituationSlots slots) => _initial;
}
