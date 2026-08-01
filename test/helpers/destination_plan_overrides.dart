import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_center_for_disasters/app/providers.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/domain/entities/route_result.dart';
import 'package:offline_center_for_disasters/domain/entities/shelter.dart';
import 'package:offline_center_for_disasters/domain/usecases/destination_planner.dart';

/// テスト用: [destinationPlanProvider] を実パックなしで成功させる。
Override destinationPlanProviderOverride({
  String shelterName = '千代田区立神田小学校',
  double distanceM = 1200,
}) {
  return destinationPlanProvider.overrideWith(
    (ref, slots) async => DestinationPlan(
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
    ),
  );
}
