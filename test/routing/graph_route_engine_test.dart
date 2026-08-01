import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/data/routing/graph_route_engine.dart';
import 'package:offline_center_for_disasters/data/routing/graph_edge.dart';
import 'package:offline_center_for_disasters/domain/entities/route_result.dart';
import 'package:offline_center_for_disasters/domain/entities/routing_profile.dart';
import 'package:offline_center_for_disasters/domain/entities/shelter.dart';

/// §14.4 RouteEngine（Isolate 実行）の結合テスト
void main() {
  // 0(35.000,139.000) -[100m]-> 1 -[100m]-> 2
  // 0 -[300m]-> 2（遠回り）
  final nodes = <int, GeoPoint>{
    0: const GeoPoint(35.0, 139.0),
    1: const GeoPoint(35.0, 139.0011),
    2: const GeoPoint(35.0, 139.0022),
  };
  final edges = <GraphEdge>[
    const GraphEdge(
      id: 1,
      fromNode: 0,
      toNode: 1,
      lengthM: 100,
      wayType: WayType.residential,
      widthClass: WidthClass.wide,
    ),
    const GraphEdge(
      id: 2,
      fromNode: 1,
      toNode: 2,
      lengthM: 100,
      wayType: WayType.residential,
      widthClass: WidthClass.wide,
    ),
    const GraphEdge(
      id: 3,
      fromNode: 0,
      toNode: 2,
      lengthM: 300,
      wayType: WayType.primary,
      widthClass: WidthClass.wide,
    ),
  ];

  Shelter shelter(String id, int? nodeId, double lat, double lng) =>
      Shelter(id: id, name: id, lat: lat, lng: lng, nearestNodeId: nodeId);

  test('候補全件の経路が 1 回の呼び出しで返る（§9.1）', () async {
    final engine = GraphRouteEngine(nodes: nodes, edges: edges);
    final results = await engine.findRoutesToMany(
      origin: const GeoPoint(35.0, 139.0),
      candidates: [
        shelter('S1', 1, 35.0, 139.0011),
        shelter('S2', 2, 35.0, 139.0022),
      ],
      profile: const RoutingProfile(),
    );
    expect(results.keys, containsAll(['S1', 'S2']));
    // S2 は 0→1→2 (200m) が 0→2 (300m) より安い
    expect(results['S2']!.costSeconds, closeTo(200 / 1.25, 1e-6));
    expect(results['S2']!.distanceM, closeTo(200, 1e-6));
    expect(results['S2']!.polyline.length, greaterThanOrEqualTo(3));
    expect(results['S2']!.instructions.first.kind, TurnKind.depart);
    expect(results['S2']!.instructions.last.kind, TurnKind.arrive);
  });

  test('nearest_node_id 未スナップの候補は結果に含めない', () async {
    final engine = GraphRouteEngine(nodes: nodes, edges: edges);
    final results = await engine.findRoutesToMany(
      origin: const GeoPoint(35.0, 139.0),
      candidates: [
        shelter('S1', null, 35.0, 139.0011),
        shelter('S2', 2, 35.0, 139.0022),
      ],
      profile: const RoutingProfile(),
    );
    expect(results.containsKey('S1'), isFalse);
    expect(results.containsKey('S2'), isTrue);
  });

  test('決定性: 2 回呼んで同一結果（§20.4 MUST）', () async {
    final engine = GraphRouteEngine(nodes: nodes, edges: edges);
    Future<List<double>> run() async {
      final r = await engine.findRoutesToMany(
        origin: const GeoPoint(35.0, 139.0),
        candidates: [shelter('S2', 2, 35.0, 139.0022)],
        profile: const RoutingProfile(),
      );
      return [r['S2']!.costSeconds, r['S2']!.distanceM];
    }

    expect(await run(), await run());
  });
}
