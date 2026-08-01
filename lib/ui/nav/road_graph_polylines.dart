import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/routing/graph_edge.dart';
import '../../data/routing/road_graph.dart';

/// 道路グラフ描画用の Polyline スタイル（§13 超軽量モード）。
const kRoadGraphPolylineColor = Color(0xFFB0B0B0);
const kRoadGraphStrokeWidth = 1.5;

/// [graph] の各エッジを flutter_map 用 [Polyline] に変換する。
List<Polyline> roadGraphToPolylines(RoadGraph graph) {
  final polylines = <Polyline>[];
  for (final edge in graph.edges) {
    final points = _edgeLatLngs(graph, edge);
    if (points.length < 2) continue;
    polylines.add(
      Polyline(
        points: points,
        strokeWidth: kRoadGraphStrokeWidth,
        color: kRoadGraphPolylineColor,
      ),
    );
  }
  return polylines;
}

List<LatLng> _edgeLatLngs(RoadGraph graph, GraphEdge edge) {
  final geometry = edge.geometry;
  if (geometry != null && geometry.isNotEmpty) {
    return [for (final p in geometry) LatLng(p.lat, p.lng)];
  }
  final from = graph.nodes[edge.fromNode];
  final to = graph.nodes[edge.toNode];
  if (from == null || to == null) return const [];
  return [LatLng(from.lat, from.lng), LatLng(to.lat, to.lng)];
}
