import '../../domain/entities/routing_profile.dart';
import 'edge_cost.dart';
import 'road_graph.dart';

/// 1 ターゲット分の探索結果。
class DijkstraPath {
  const DijkstraPath({
    required this.nodeIds,
    required this.edgeIds,
    required this.costSec,
    required this.distanceM,
  });

  /// 開始ノード→ターゲットのノード列。
  final List<int> nodeIds;

  /// nodeIds に対応するエッジ列（長さ = nodeIds.length - 1）。
  final List<int> edgeIds;
  final double costSec;
  final double distanceM;
}

class MultiTargetResult {
  const MultiTargetResult({required this.found, required this.timedOut});

  /// targetId → 経路。到達不能・タイムアウト未発見のものは含まない。
  final Map<String, DijkstraPath> found;

  /// タイムアウトで打ち切られたか（§9.1 timeout）。
  final bool timedOut;
}

/// §9.1: 1 対多 Dijkstra。候補ごとに個別探索してはならない（MUST NOT）。
///
/// 決定性（§20.4 MUST）のため、優先度キューは (コスト, ノードID) の
/// 辞書順で tie-break し、同コストの親更新は行わない。
class MultiTargetDijkstra {
  MultiTargetDijkstra(this.graph);

  final RoadGraph graph;

  static const _timeoutCheckInterval = 512;

  MultiTargetResult run({
    required int startNode,
    required Map<String, int> targets,
    required RoutingProfile profile,
    Duration timeout = const Duration(seconds: 3),
  }) {
    final stopwatch = Stopwatch()..start();
    final remaining = <int, String>{
      for (final e in targets.entries) e.value: e.key,
    };
    final found = <String, DijkstraPath>{};
    var timedOut = false;

    final dist = <int, double>{startNode: 0};
    final distM = <int, double>{startNode: 0};
    final parentNode = <int, int>{};
    final parentEdge = <int, int>{};
    final settled = <int>{};
    final heap = _MinHeap()..push(0, startNode);

    var pops = 0;
    while (heap.isNotEmpty && remaining.isNotEmpty) {
      final (cost, node) = heap.pop();
      if (settled.contains(node)) continue;
      settled.add(node);

      final targetId = remaining.remove(node);
      if (targetId != null) {
        found[targetId] = _reconstruct(
          node,
          dist[node]!,
          distM[node]!,
          parentNode,
          parentEdge,
        );
      }

      if (++pops % _timeoutCheckInterval == 0 && stopwatch.elapsed > timeout) {
        timedOut = true;
        break;
      }

      for (final edge in graph.edgesOf(node)) {
        final next = edge.otherEnd(node);
        if (settled.contains(next)) continue;
        final edgeCost = traversalCostSec(edge, profile);
        if (edgeCost == null) continue; // 通行不可（§9.2 の 999 相当）
        final newCost = cost + edgeCost;
        final known = dist[next];
        // 等コストでは更新しない（先に確定した小さいノード番号側を採用し決定性を担保）
        if (known == null || newCost < known) {
          dist[next] = newCost;
          distM[next] = distM[node]! + edge.lengthM;
          parentNode[next] = node;
          parentEdge[next] = edge.id;
          heap.push(newCost, next);
        }
      }
    }

    return MultiTargetResult(found: found, timedOut: timedOut);
  }

  DijkstraPath _reconstruct(
    int target,
    double costSec,
    double distanceM,
    Map<int, int> parentNode,
    Map<int, int> parentEdge,
  ) {
    final nodeIds = <int>[];
    final edgeIds = <int>[];
    var cur = target;
    nodeIds.add(cur);
    while (parentNode.containsKey(cur)) {
      edgeIds.add(parentEdge[cur]!);
      cur = parentNode[cur]!;
      nodeIds.add(cur);
    }
    return DijkstraPath(
      nodeIds: nodeIds.reversed.toList(),
      edgeIds: edgeIds.reversed.toList(),
      costSec: costSec,
      distanceM: distanceM,
    );
  }
}

/// (cost, nodeId) 辞書順の二分ヒープ（決定性 tie-break 用）。
class _MinHeap {
  final List<double> _costs = [];
  final List<int> _nodes = [];

  bool get isNotEmpty => _costs.isNotEmpty;

  void push(double cost, int node) {
    _costs.add(cost);
    _nodes.add(node);
    var i = _costs.length - 1;
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (_less(i, parent)) {
        _swap(i, parent);
        i = parent;
      } else {
        break;
      }
    }
  }

  (double, int) pop() {
    final cost = _costs.first;
    final node = _nodes.first;
    final lastCost = _costs.removeLast();
    final lastNode = _nodes.removeLast();
    if (_costs.isNotEmpty) {
      _costs[0] = lastCost;
      _nodes[0] = lastNode;
      var i = 0;
      while (true) {
        final l = i * 2 + 1;
        final r = l + 1;
        var smallest = i;
        if (l < _costs.length && _less(l, smallest)) smallest = l;
        if (r < _costs.length && _less(r, smallest)) smallest = r;
        if (smallest == i) break;
        _swap(i, smallest);
        i = smallest;
      }
    }
    return (cost, node);
  }

  bool _less(int a, int b) =>
      _costs[a] < _costs[b] ||
      (_costs[a] == _costs[b] && _nodes[a] < _nodes[b]);

  void _swap(int a, int b) {
    final tc = _costs[a];
    _costs[a] = _costs[b];
    _costs[b] = tc;
    final tn = _nodes[a];
    _nodes[a] = _nodes[b];
    _nodes[b] = tn;
  }
}
