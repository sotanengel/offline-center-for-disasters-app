import '../../core/geo/geo.dart';
import '../../core/geo/geo_bounds.dart';
import '../../core/geo/geo_point.dart';
import '../../domain/entities/hazard_context.dart';
import '../../domain/entities/route_result.dart';
import '../../domain/entities/shelter.dart';
import '../../domain/entities/situation_slots.dart';
import '../../domain/policies/destination_policy.dart';
import '../../data/pack/evacuation_pack.dart';
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

/// 経路グラフを読む範囲に足すマージン [km]。
///
/// 経路は直線ではないため、現在地と避難先を結ぶ矩形より少し広く取る。
const kRouteGraphMarginKm = 1.5;

/// 経路探索のためにロードすべきグラフ範囲（§16.1）。
///
/// 現在地から半径 12km を一律で読むと東京パックで 61 万ノードになり、
/// 実機では 70 秒経っても避難先サマリの描画に至らなかった。避難先が
/// 確定してから両点を覆う範囲だけ読むことで、通常ケースを小さく保つ。
GeoBounds routeGraphBoundsFor(GeoPoint origin, GeoPoint destination) =>
    GeoBounds.covering([origin, destination], marginKm: kRouteGraphMarginKm);

/// 避難先が確定した後に、その範囲のグラフを読んで RouteEngine を作る。
typedef RouteEngineFactory = Future<RouteEngine?> Function(GeoBounds bounds);

/// 現在地・スロット・パックから避難先と経路を決定する。
class DestinationPlanner {
  const DestinationPlanner({DestinationPolicy? policy})
    : _policy = policy ?? const DestinationPolicy();

  final DestinationPolicy _policy;

  Future<DestinationPlan> plan({
    required SituationSlots slots,
    required GeoPoint origin,
    EvacuationPack? pack,
    RouteEngine? routeEngine,
    RouteEngineFactory? routeEngineFactory,
  }) async {
    if (pack == null) {
      return DestinationPlan(origin: origin, packMissing: true);
    }

    final originCtx = await pack.contextAt(origin);
    final query = _policy.buildQuery(
      slots.disasterType,
      originCtx,
      slots.userState,
    );
    final search = await pack.findShelters(origin: origin, query: query);

    if (search.notFound || search.shelters.isEmpty) {
      return DestinationPlan(
        origin: origin,
        notFound: true,
        expandedRadius: search.expandedRadius,
      );
    }

    final shelter = search.shelters.first;
    final distanceM = haversineM(origin, GeoPoint(shelter.lat, shelter.lng));
    final shelterContext = await pack.contextAt(
      GeoPoint(shelter.lat, shelter.lng),
    );

    // 避難先が決まってからグラフを読む（§16.1）。全県ぶんも「現在地から半径 12km」も
    // 実機では重すぎるため、現在地と避難先を覆う範囲だけに絞る。
    var engine = routeEngine;
    if (engine == null && routeEngineFactory != null) {
      final bounds = routeGraphBoundsFor(
        origin,
        GeoPoint(shelter.lat, shelter.lng),
      );
      engine = await routeEngineFactory(bounds);
    }

    RouteResult? route;
    var timedOut = false;
    if (engine != null && shelter.nearestNodeId != null) {
      final profile = _policy.buildRoutingProfile(
        slots.disasterType,
        slots.userState,
        false,
      );
      final routes = await engine.findRoutesToMany(
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
