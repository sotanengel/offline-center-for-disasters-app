import 'package:flutter/foundation.dart';

import '../../core/geo/geo_point.dart';
import '../../domain/entities/route_result.dart';
import '../../domain/entities/routing_profile.dart';
import '../../domain/entities/shelter.dart';
import '../../domain/services/route_engine.dart';
import 'dijkstra_multi_target.dart';
import 'graph_edge.dart';
import 'road_graph.dart';
import 'turn_by_turn_builder.dart';

/// §9.1 の 1 対多 Dijkstra を Isolate で実行する [RouteEngine] 実装。
/// 低速機で UI を止めないため、探索はワーカ Isolate に委譲する。
class GraphRouteEngine implements RouteEngine {
  GraphRouteEngine({
    required Map<int, GeoPoint> nodes,
    required List<GraphEdge> edges,
  }) : _nodes = nodes,
       _edges = edges;

  final Map<int, GeoPoint> _nodes;
  final List<GraphEdge> _edges;

  @override
  Future<Map<String, RouteResult>> findRoutesToMany({
    required GeoPoint origin,
    required List<Shelter> candidates,
    required RoutingProfile profile,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final graph = RoadGraph(nodes: _nodes, edges: _edges);
    final start = graph.nearestNode(origin);
    if (start == null) return const {};

    // nearest_node_id 未スナップの候補は経路探索不能のため除外する
    final targets = <String, int>{
      for (final s in candidates)
        if (s.nearestNodeId != null) s.id: s.nearestNodeId!,
    };
    if (targets.isEmpty) return const {};

    final result = await compute(
      _runInIsolate,
      _RouteRequest(
        nodes: _nodes,
        edges: _edges,
        startNode: start,
        targets: targets,
        profile: profile,
        timeoutMs: timeout.inMilliseconds,
      ),
    );

    final byId = {for (final e in _edges) e.id: e};
    final out = <String, RouteResult>{};
    for (final entry in result.found.entries) {
      final path = entry.value;
      final legs = _buildLegs(path, byId, graph);
      final polyline = <GeoPoint>[for (final leg in legs) ...leg.points];
      out[entry.key] = RouteResult(
        targetId: entry.key,
        costSeconds: path.costSec,
        distanceM: path.distanceM,
        polyline: polyline,
        instructions: TurnByTurnBuilder().build(legs),
      );
    }
    return out;
  }

  List<PathLeg> _buildLegs(
    DijkstraPath path,
    Map<int, GraphEdge> byId,
    RoadGraph graph,
  ) {
    final legs = <PathLeg>[];
    for (var i = 0; i + 1 < path.nodeIds.length; i++) {
      final from = path.nodeIds[i];
      final edge = byId[path.edgeIds[i]]!;
      final oriented =
          edge.geometryFrom(from) ??
          [graph.nodes[from]!, graph.nodes[path.nodeIds[i + 1]]!];
      legs.add(PathLeg(points: oriented, landmarkName: edge.landmarkName));
    }
    return legs;
  }
}

class _RouteRequest {
  const _RouteRequest({
    required this.nodes,
    required this.edges,
    required this.startNode,
    required this.targets,
    required this.profile,
    required this.timeoutMs,
  });

  final Map<int, GeoPoint> nodes;
  final List<GraphEdge> edges;
  final int startNode;
  final Map<String, int> targets;
  final RoutingProfile profile;
  final int timeoutMs;
}

/// Isolate エントリポイント（トップレベル関数であること）。
MultiTargetResult _runInIsolate(_RouteRequest req) {
  final graph = RoadGraph(nodes: req.nodes, edges: req.edges);
  return MultiTargetDijkstra(graph).run(
    startNode: req.startNode,
    targets: req.targets,
    profile: req.profile,
    timeout: Duration(milliseconds: req.timeoutMs),
  );
}
