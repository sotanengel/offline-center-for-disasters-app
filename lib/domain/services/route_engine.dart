import '../../core/geo/geo_point.dart';
import '../entities/route_search_result.dart';
import '../entities/routing_profile.dart';
import '../entities/shelter.dart';

/// §14.4: 1 対多 Dijkstra による経路探索。
///
/// MUST NOT: 候補ごとに個別に A* を回すこと（§9.1）。
abstract interface class RouteEngine {
  /// 全候補への経路を 1 回の探索で取得する。
  /// 戻り値の routes キーは Shelter.id。到達不能・タイムアウト未発見は含まない。
  /// timedOut は §12「経路探索失敗 → 直線方位ナビ」判定に使う。
  Future<RouteSearchResult> findRoutesToMany({
    required GeoPoint origin,
    required List<Shelter> candidates,
    required RoutingProfile profile,
    Duration timeout = const Duration(seconds: 3),
  });
}
