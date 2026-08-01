import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/geo/geo_bounds.dart';
import '../../core/geo/geo_point.dart';
import '../../core/geo/polyline_codec.dart';
import '../routing/graph_edge.dart';
import '../routing/road_graph.dart';

/// §14.2 nodes/edges を読み、RouteEngine 用の [RoadGraph] を構築する。
class GraphLoader {
  GraphLoader(this._db);

  final DatabaseConnectionUser _db;

  /// [bounds] を渡すと、その bbox 内のノードとその両端を含むエッジのみをロードする
  /// （§16.1 メモリ・§16.3 検索時間の対策）。省略時は全件ロード（既存互換）。
  Future<RoadGraph> load({GeoBounds? bounds}) async {
    final Map<int, GeoPoint> nodes;
    final List<GraphEdge> edges;

    if (bounds == null) {
      final nodeRows = await _db
          .customSelect('SELECT id, lat, lng FROM nodes')
          .get();
      nodes = <int, GeoPoint>{
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
      edges = [for (final row in edgeRows) _rowToEdge(row.data)];
    } else {
      final nodeRows = await _db
          .customSelect(
            'SELECT id, lat, lng FROM nodes'
            ' WHERE lat BETWEEN ? AND ? AND lng BETWEEN ? AND ?',
            variables: [
              Variable.withReal(bounds.minLat),
              Variable.withReal(bounds.maxLat),
              Variable.withReal(bounds.minLng),
              Variable.withReal(bounds.maxLng),
            ],
          )
          .get();
      nodes = <int, GeoPoint>{
        for (final r in nodeRows)
          (r.data['id'] as num).toInt(): GeoPoint(
            (r.data['lat'] as num).toDouble(),
            (r.data['lng'] as num).toDouble(),
          ),
      };
      if (nodes.isEmpty) {
        return RoadGraph(nodes: const {}, edges: const []);
      }
      // 両端ノードが bbox 内にあるエッジのみを取得する。
      //
      // 以前はヒットしたノード ID を IN 句にバインドしていたが、バインド
      // 変数がノード数に比例して増える（東京パックの近傍ケースで 11 万件
      // → 22 万バインド）。デスクトップでは SQLite のバインド変数上限を
      // 超えて SqliteException（too many SQL variables）になり、実機の
      // iOS 標準 SQLite ではエラーにはならないが大量のバインド処理その
      // ものが致命的に遅く、S-02 が実機で完了しなかった（2026-08-02）。
      // bbox 条件を nodes 側の JOIN として書き、バインド変数を bbox の
      // 8 個だけに固定する（ヒット件数に依存しない）。
      final edgeRows = await _db
          .customSelect(
            'SELECT e.id, e.from_node, e.to_node, e.length_m, e.geometry,'
            ' e.way_type, e.width_class, e.has_steps, e.is_lit,'
            ' e.hz_flood_depth, e.hz_tsunami_depth, e.hz_landslide,'
            ' e.hz_storm_surge, e.hz_volcano, e.near_river, e.dense_wood,'
            ' e.landmark_name'
            ' FROM edges e'
            ' JOIN nodes n1 ON e.from_node = n1.id'
            ' JOIN nodes n2 ON e.to_node = n2.id'
            ' WHERE n1.lat BETWEEN ? AND ? AND n1.lng BETWEEN ? AND ?'
            ' AND n2.lat BETWEEN ? AND ? AND n2.lng BETWEEN ? AND ?',
            variables: [
              Variable.withReal(bounds.minLat),
              Variable.withReal(bounds.maxLat),
              Variable.withReal(bounds.minLng),
              Variable.withReal(bounds.maxLng),
              Variable.withReal(bounds.minLat),
              Variable.withReal(bounds.maxLat),
              Variable.withReal(bounds.minLng),
              Variable.withReal(bounds.maxLng),
            ],
          )
          .get();
      edges = [for (final row in edgeRows) _rowToEdge(row.data)];
    }

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
