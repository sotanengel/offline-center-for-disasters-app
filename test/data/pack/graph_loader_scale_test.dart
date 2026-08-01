import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/geo/geo_bounds.dart';
import 'package:offline_center_for_disasters/data/pack/graph_loader.dart';
import 'package:offline_center_for_disasters/data/pack/pack_database.dart';

import 'pack_fixture.dart';

/// GraphLoader.load(bounds:) の大規模データでの回帰テスト（§16.1）。
///
/// 2026-08-02 実機検証で判明: bbox 内エッジを
/// `WHERE from_node IN (...) AND to_node IN (...)` で絞り込むと、
/// バインド変数がヒットしたノード数に比例して増える（東京パックの現在地
/// 近傍で 11 万ノード → バインド変数 22 万個）。SQL 自体は高速でも、
/// これだけの数のプレースホルダを個別にバインドする Dart 側の処理が
/// 実機の debug 実行では致命的に遅く、S-02 が完了しなかった。
/// 玩具データ（数件）のテストではこの規模依存のバグを検知できないため、
/// 大規模合成データで壁時計時間を検証する。
void main() {
  late PackDatabase db;

  setUp(() async {
    db = createFixtureExecutor();
    await createSchema(db);

    // 331x331 グリッド ≒ 109,561 ノード（実機で観測した 110,115 件に近い規模）。
    // 各ノードから右・下の隣接ノードへ辺を張り、双方向格子状の道路網を模す。
    const gridSize = 331;
    final buffer = StringBuffer(
      'INSERT INTO nodes (id, lat, lng, elevation_m) VALUES ',
    );
    var first = true;
    for (var y = 0; y < gridSize; y++) {
      for (var x = 0; x < gridSize; x++) {
        final id = y * gridSize + x;
        final lat = 35.60 + y * 0.0003;
        final lng = 139.75 + x * 0.0003;
        if (!first) buffer.write(',');
        first = false;
        buffer.write('($id, $lat, $lng, 10)');
      }
    }
    db.customStatement(buffer.toString());

    final edgeBuffer = StringBuffer(
      'INSERT INTO edges (id, from_node, to_node, length_m, way_type, width_class) VALUES ',
    );
    var edgeId = 0;
    var edgeFirst = true;
    for (var y = 0; y < gridSize; y++) {
      for (var x = 0; x < gridSize; x++) {
        final id = y * gridSize + x;
        if (x + 1 < gridSize) {
          final right = id + 1;
          if (!edgeFirst) edgeBuffer.write(',');
          edgeFirst = false;
          edgeBuffer.write('(${edgeId++}, $id, $right, 20, 1, 3)');
        }
        if (y + 1 < gridSize) {
          final down = id + gridSize;
          if (!edgeFirst) edgeBuffer.write(',');
          edgeFirst = false;
          edgeBuffer.write('(${edgeId++}, $id, $down, 20, 1, 3)');
        }
      }
    }
    db.customStatement(edgeBuffer.toString());
  });

  tearDown(() => db.close());

  test(
    '11 万ノード規模でも bbox ロードが数秒で終わる（§16.1 実機性能要件）',
    () async {
      // ほぼ全域を覆う bbox（実機の近傍ケースに相当する規模を再現する）。
      final bounds = const GeoBounds(
        minLat: 35.59,
        maxLat: 35.71,
        minLng: 139.74,
        maxLng: 139.86,
      );

      final stopwatch = Stopwatch()..start();
      final graph = await GraphLoader(db).load(bounds: bounds);
      stopwatch.stop();

      expect(graph.nodes.length, greaterThan(100000));
      // 2026-08-02 実機検証: 同規模のバインド変数を伴う IN 句方式は
      // 実機で 10 分以上かかっても完了しなかった。デスクトップの
      // テスト実行でも、規模に比例して遅くなる実装なら数秒を超えて
      // 検知できるはずの閾値を設定する。
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(5000),
        reason:
            'GraphLoader.load はノード数に比例したバインド変数を使う実装だと'
            '実機で致命的に遅くなる（§16.1）。JOIN ベースなど件数に依存しない'
            'クエリで絞り込むこと。',
      );
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
