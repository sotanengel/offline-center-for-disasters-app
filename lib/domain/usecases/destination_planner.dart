import '../../core/geo/geo.dart';
import '../../core/geo/geo_point.dart';
import '../../domain/entities/hazard_context.dart';
import '../../domain/entities/route_result.dart';
import '../../domain/entities/shelter.dart';
import '../../domain/entities/situation_slots.dart';
import '../../domain/policies/destination_policy.dart';
import '../../data/pack/pack_loader.dart';
import '../../domain/services/route_engine.dart';

/// S-02 避難先候補 + 経路のプレビュー（§9.1 / §4.4）。
class DestinationPlan {
  const DestinationPlan({
    required this.origin,
    this.shelter,
    this.distanceM,
    this.shelterContext = const HazardContext(),
    this.route,
    this.packMissing = false,
    this.notFound = false,
    this.routeTimedOut = false,
    this.expandedRadius = false,
  });

  final GeoPoint origin;
  final Shelter? shelter;
  final double? distanceM;
  final HazardContext shelterContext;
  final RouteResult? route;
  final bool packMissing;
  final bool notFound;
  final bool routeTimedOut;
  final bool expandedRadius;

  bool get hasShelter => shelter != null;
}

/// 現在地・スロット・パックから避難先と経路を決定する。
class DestinationPlanner {
  const DestinationPlanner({DestinationPolicy? policy})
    : _policy = policy ?? const DestinationPolicy();

  final DestinationPolicy _policy;

  Future<DestinationPlan> plan({
    required SituationSlots slots,
    required GeoPoint origin,
    DataPack? pack,
    RouteEngine? routeEngine,
  }) async {
    if (pack == null) {
      return DestinationPlan(origin: origin, packMissing: true);
    }

    final originCtx = await pack.hazardGrid.contextAt(origin);
    final query = _policy.buildQuery(
      slots.disasterType,
      originCtx,
      slots.userState,
    );
    final search = await pack.shelterFinder.find(origin: origin, query: query);

    if (search.notFound || search.shelters.isEmpty) {
      return DestinationPlan(
        origin: origin,
        notFound: true,
        expandedRadius: search.expandedRadius,
      );
    }

    final shelter = search.shelters.first;
    final distanceM = haversineM(origin, GeoPoint(shelter.lat, shelter.lng));
    final shelterContext = await pack.hazardGrid.contextAt(
      GeoPoint(shelter.lat, shelter.lng),
    );

    RouteResult? route;
    var timedOut = false;
    if (routeEngine != null && shelter.nearestNodeId != null) {
      final profile = _policy.buildRoutingProfile(
        slots.disasterType,
        slots.userState,
        false,
      );
      final routes = await routeEngine.findRoutesToMany(
        origin: origin,
        candidates: [shelter],
        profile: profile,
      );
      timedOut = routes.timedOut;
      route = routes.routes[shelter.id];
    }

    return DestinationPlan(
      origin: origin,
      shelter: shelter,
      distanceM: distanceM,
      shelterContext: shelterContext,
      route: route,
      routeTimedOut: timedOut,
      expandedRadius: search.expandedRadius,
    );
  }
}

/// 距離 [m] を表示用文字列にする。
String formatDistanceM(double distanceM) {
  if (distanceM >= 1000) {
    return '${(distanceM / 1000).toStringAsFixed(1)}km';
  }
  return '${distanceM.round()}m';
}
