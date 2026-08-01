import '../../core/geo/geo.dart';
import '../../core/geo/geo_point.dart';
import 'graph_edge.dart';

/// 道路グラフ（§14.2 nodes/edges のメモリ表現）。エッジは双方向に張る。
class RoadGraph {
  RoadGraph({required Map<int, GeoPoint> nodes, required List<GraphEdge> edges})
    : nodes = Map.unmodifiable(nodes),
      edges = List.unmodifiable(edges) {
    final adj = <int, List<GraphEdge>>{};
    for (final e in edges) {
      adj.putIfAbsent(e.fromNode, () => []).add(e);
      adj.putIfAbsent(e.toNode, () => []).add(e);
    }
    _adjacency = Map.unmodifiable(
      adj.map((k, v) => MapEntry(k, List<GraphEdge>.unmodifiable(v))),
    );
  }

  final Map<int, GeoPoint> nodes;
  final List<GraphEdge> edges;
  late final Map<int, List<GraphEdge>> _adjacency;

  List<GraphEdge> edgesOf(int nodeId) =>
      _adjacency[nodeId] ?? const <GraphEdge>[];

  /// 出発地スナップ用の最近接ノード（§9.1 手順1の前段）。見つからなければ null。
  int? nearestNode(GeoPoint origin) {
    int? best;
    var bestD = double.infinity;
    for (final entry in nodes.entries) {
      final d = haversineM(origin, entry.value);
      if (d < bestD) {
        bestD = d;
        best = entry.key;
      }
    }
    return best;
  }
}
