import 'package:freezed_annotation/freezed_annotation.dart';

import 'route_result.dart';

part 'route_search_result.freezed.dart';

/// §9.1 RouteEngine.findRoutesToMany の戻り値。
///
/// timedOut は Isolate 内 Dijkstra が §9.1 の timeout で打ち切られたかを伝える。
/// 呼び出し側は §12 の「経路探索失敗 → 直線方位ナビ」判定に使う。
@freezed
abstract class RouteSearchResult with _$RouteSearchResult {
  const factory RouteSearchResult({
    /// Shelter.id → 経路。到達不能・タイムアウトで未発見のものは含まない。
    @Default(<String, RouteResult>{}) Map<String, RouteResult> routes,

    /// タイムアウトで打ち切られたか。true でも routes は途中経過を含む。
    @Default(false) bool timedOut,
  }) = _RouteSearchResult;

  const RouteSearchResult._();

  bool get isEmpty => routes.isEmpty;
}
