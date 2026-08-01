import 'dart:typed_data';

import 'package:offline_center_for_disasters/data/pack/pack_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/geo/polyline_codec.dart';
import 'package:offline_center_for_disasters/data/pack/graph_loader.dart';
import 'package:offline_center_for_disasters/data/routing/graph_edge.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';

import 'pack_fixture.dart';

/// §14.2 nodes/edges → RoadGraph のロード
void main() {
  late PackDatabase db;

  setUp(() async {
    db = createFixtureExecutor();
    await createSchema(db);
  });

  tearDown(() => db.close());

  test('nodes/edges から RoadGraph を構築する', () async {
    db.customStatement(
      'INSERT INTO nodes (id, lat, lng, elevation_m) VALUES (1, 35.0, 139.0, 10),'
      ' (2, 35.0, 139.001, 11), (3, 35.001, 139.001, 12)',
    );
    final geometry = Uint8List.fromList(
      encodePolyline(const [
        GeoPoint(35.0, 139.0),
        GeoPoint(35.0, 139.0005),
        GeoPoint(35.0, 139.001),
      ]).codeUnits,
    );
    db.customStatement(
      'INSERT INTO edges (id, from_node, to_node, length_m, geometry, way_type,'
      ' width_class, has_steps, is_lit, hz_flood_depth, near_river, landmark_name)'
      ' VALUES (10, 1, 2, 95.5, ?, 1, 3, 0, 1, 2, 1, ?)',
      [geometry, 'テスト神社'],
    );
    db.customStatement(
      'INSERT INTO edges (id, from_node, to_node, length_m, geometry, way_type,'
      ' width_class) VALUES (11, 2, 3, 100, NULL, 3, 1)',
    );

    final graph = await GraphLoader(db).load();
    expect(graph.nodes.length, 3);
    expect(graph.nodes[1], const GeoPoint(35.0, 139.0));
    expect(graph.edges.length, 2);

    final e10 = graph.edges.firstWhere((e) => e.id == 10);
    expect(e10.lengthM, 95.5);
    expect(e10.wayType, WayType.residential);
    expect(e10.widthClass, WidthClass.wide);
    expect(e10.hzFloodDepth, 2);
    expect(e10.nearRiver, 1);
    expect(e10.landmarkName, 'テスト神社');
    expect(e10.geometry!.length, 3);
    expect(e10.geometry![1].lng, closeTo(139.0005, 1e-6));

    final e11 = graph.edges.firstWhere((e) => e.id == 11);
    expect(e11.wayType, WayType.steps);
    expect(e11.widthClass, WidthClass.narrow);
    expect(e11.geometry, isNull);

    // 双方向に張られている（徒歩のため oneway 無視）
    expect(graph.edgesOf(3).single.id, 11);
    expect(graph.edgesOf(1).single.id, 10);
  });
}
