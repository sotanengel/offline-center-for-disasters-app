import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/geo/geo_bounds.dart';
import 'package:offline_center_for_disasters/data/pack/graph_loader.dart';
import 'package:offline_center_for_disasters/data/pack/pack_database.dart';

import 'pack_fixture.dart';

/// GraphLoader.load(bounds:) の範囲絞り込み。
///
/// §16.1 の経路探索メモリ制約対応: 全県数百万ノードから
/// 現在地周辺のみを取り出せることを確認する。
void main() {
  late PackDatabase db;

  setUp(() async {
    db = createFixtureExecutor();
    await createSchema(db);
    // ノード 1..4 を配置
    //  1: (35.000, 139.000) — 中心付近
    //  2: (35.001, 139.001) — 中心付近
    //  3: (35.050, 139.050) — 範囲外
    //  4: (35.000, 139.002) — 中心付近
    db.customStatement(
      'INSERT INTO nodes (id, lat, lng, elevation_m) VALUES'
      ' (1, 35.000, 139.000, 10),'
      ' (2, 35.001, 139.001, 11),'
      ' (3, 35.050, 139.050, 12),'
      ' (4, 35.000, 139.002, 13)',
    );
    db.customStatement(
      'INSERT INTO edges (id, from_node, to_node, length_m, way_type, width_class)'
      ' VALUES'
      ' (10, 1, 2, 100, 1, 3),'
      ' (11, 2, 4, 100, 1, 3),'
      // 範囲内→範囲外に跨るエッジは除外される
      ' (12, 2, 3, 500, 1, 3),'
      // 完全に範囲外
      ' (13, 3, 3, 0,   1, 3)',
    );
  });

  tearDown(() => db.close());

  test('bounds 指定で範囲外ノードが含まれないこと', () async {
    final graph = await GraphLoader(db).load(
      bounds: const GeoBounds(
        minLat: 34.999,
        maxLat: 35.010,
        minLng: 138.999,
        maxLng: 139.010,
      ),
    );
    expect(graph.nodes.keys, unorderedEquals([1, 2, 4]));
  });

  test('bounds 内両端のエッジのみ含まれる', () async {
    final graph = await GraphLoader(db).load(
      bounds: const GeoBounds(
        minLat: 34.999,
        maxLat: 35.010,
        minLng: 138.999,
        maxLng: 139.010,
      ),
    );
    expect(graph.edges.map((e) => e.id), unorderedEquals([10, 11]));
  });

  test('bounds 省略時は従来通り全件ロード', () async {
    final graph = await GraphLoader(db).load();
    expect(graph.nodes.length, 4);
    expect(graph.edges.length, 4);
  });

  test('bounds 内にノードが 0 件のときは空の RoadGraph', () async {
    final graph = await GraphLoader(db).load(
      bounds: const GeoBounds(
        minLat: 30.0,
        maxLat: 30.1,
        minLng: 130.0,
        maxLng: 130.1,
      ),
    );
    expect(graph.nodes, isEmpty);
    expect(graph.edges, isEmpty);
  });
}
