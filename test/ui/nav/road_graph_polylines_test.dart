import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/data/routing/graph_edge.dart';
import 'package:offline_center_for_disasters/data/routing/road_graph.dart';
import 'package:offline_center_for_disasters/ui/nav/road_graph_polylines.dart';

void main() {
  const p1 = GeoPoint(35.68, 139.76);
  const p2 = GeoPoint(35.681, 139.761);
  const p3 = GeoPoint(35.682, 139.762);

  RoadGraph graphOf(List<GraphEdge> edges, Map<int, GeoPoint> nodes) {
    return RoadGraph(nodes: nodes, edges: edges);
  }

  test('空グラフは空リストを返す', () {
    final graph = RoadGraph(nodes: const {}, edges: const []);
    expect(roadGraphToPolylines(graph), isEmpty);
  });

  test('geometry なしエッジは端点間の直線 Polyline になる', () {
    final graph = graphOf(
      [const GraphEdge(id: 1, fromNode: 1, toNode: 2, lengthM: 100)],
      {1: p1, 2: p2},
    );
    final polylines = roadGraphToPolylines(graph);
    expect(polylines, hasLength(1));
    expect(polylines.first.points, hasLength(2));
    expect(polylines.first.points.first.latitude, p1.lat);
    expect(polylines.first.points.last.latitude, p2.lat);
    expect(polylines.first.strokeWidth, kRoadGraphStrokeWidth);
    expect(polylines.first.color, kRoadGraphPolylineColor);
  });

  test('geometry ありエッジは形状点を Polyline に使う', () {
    final graph = graphOf(
      [
        GraphEdge(
          id: 1,
          fromNode: 1,
          toNode: 3,
          lengthM: 200,
          geometry: const [p1, p2, p3],
        ),
      ],
      {1: p1, 3: p3},
    );
    final polylines = roadGraphToPolylines(graph);
    expect(polylines, hasLength(1));
    expect(polylines.first.points, hasLength(3));
    expect(polylines.first.points[1].latitude, p2.lat);
  });

  test('端点ノード欠落エッジはスキップする', () {
    final graph = graphOf(
      [const GraphEdge(id: 1, fromNode: 1, toNode: 99, lengthM: 100)],
      {1: p1},
    );
    expect(roadGraphToPolylines(graph), isEmpty);
  });
}
