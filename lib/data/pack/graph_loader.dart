import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/geo/geo_point.dart';
import '../../core/geo/polyline_codec.dart';
import '../routing/graph_edge.dart';
import '../routing/road_graph.dart';

/// §14.2 nodes/edges を読み、RouteEngine 用の [RoadGraph] を構築する。
class GraphLoader {
  GraphLoader(this._db);

  final DatabaseConnectionUser _db;

  Future<RoadGraph> load() async {
    final nodeRows = await _db
        .customSelect('SELECT id, lat, lng FROM nodes')
        .get();
    final nodes = <int, GeoPoint>{
      for (final r in nodeRows)
        (r.data['id'] as num).toInt(): GeoPoint(
          (r.data['lat'] as num).toDouble(),
          (r.data['lng'] as num).toDouble(),
        ),
    };

    final edgeRows = await _db
        .customSelect(
          'SELECT id, from_node, to_node, length_m, geometry, way_type,'
          ' width_class, has_steps, is_lit, hz_flood_depth, hz_tsunami_depth,'
          ' hz_landslide, hz_storm_surge, hz_volcano, near_river, dense_wood,'
          ' landmark_name FROM edges',
        )
        .get();
    final edges = [for (final row in edgeRows) _rowToEdge(row.data)];
    return RoadGraph(nodes: nodes, edges: edges);
  }

  GraphEdge _rowToEdge(Map<String, Object?> r) {
    return GraphEdge(
      id: (r['id'] as num).toInt(),
      fromNode: (r['from_node'] as num).toInt(),
      toNode: (r['to_node'] as num).toInt(),
      lengthM: (r['length_m'] as num).toDouble(),
      geometry: _decodeGeometry(r['geometry']),
      wayType: WayType.fromCode((r['way_type'] as num?)?.toInt()),
      widthClass: WidthClass.fromCode((r['width_class'] as num?)?.toInt()),
      hasSteps: (r['has_steps'] as num?)?.toInt() ?? 0,
      isLit: (r['is_lit'] as num?)?.toInt() ?? 0,
      hzFloodDepth: (r['hz_flood_depth'] as num?)?.toInt() ?? 0,
      hzTsunamiDepth: (r['hz_tsunami_depth'] as num?)?.toInt() ?? 0,
      hzLandslide: (r['hz_landslide'] as num?)?.toInt() ?? 0,
      hzStormSurge: (r['hz_storm_surge'] as num?)?.toInt() ?? 0,
      hzVolcano: (r['hz_volcano'] as num?)?.toInt() ?? 0,
      nearRiver: (r['near_river'] as num?)?.toInt() ?? 0,
      denseWood: (r['dense_wood'] as num?)?.toInt() ?? 0,
      landmarkName: r['landmark_name'] as String?,
    );
  }

  List<GeoPoint>? _decodeGeometry(Object? blob) {
    if (blob is! Uint8List || blob.isEmpty) return null;
    return decodePolyline(utf8.decode(blob));
  }
}
