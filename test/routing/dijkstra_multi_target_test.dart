import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/data/routing/dijkstra_multi_target.dart';
import 'package:offline_center_for_disasters/data/routing/graph_edge.dart';
import 'package:offline_center_for_disasters/data/routing/road_graph.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/routing_profile.dart';

/// §9.1 1対多 Dijkstra / §20.4 経路探索テスト
void main() {
  int idSeq = 0;
  GraphEdge e(
    int a,
    int b,
    double lengthM, {
    WayType wayType = WayType.residential,
    WidthClass widthClass = WidthClass.wide,
    int hzFloodDepth = 0,
    int hzLandslide = 0,
  }) {
    return GraphEdge(
      id: idSeq++,
      fromNode: a,
      toNode: b,
      lengthM: lengthM,
      wayType: wayType,
      widthClass: widthClass,
      hzFloodDepth: hzFloodDepth,
      hzLandslide: hzLandslide,
    );
  }

  RoadGraph graphOf(List<GraphEdge> edges, {int maxNode = 100}) {
    final nodes = <int, GeoPoint>{
      for (var i = 0; i <= maxNode; i++) i: GeoPoint(35.0 + i * 1e-5, 139.0),
    };
    return RoadGraph(nodes: nodes, edges: edges);
  }

  group('基本動作', () {
    test('最短経路のコストとノード列が返る', () {
      idSeq = 0;
      final g = graphOf([e(0, 1, 100), e(1, 2, 100), e(0, 2, 300)]);
      final r = MultiTargetDijkstra(g).run(
        startNode: 0,
        targets: const {'a': 2},
        profile: const RoutingProfile(),
      );
      final p = r.found['a']!;
      expect(p.costSec, closeTo(200 / 1.25, 1e-9));
      expect(p.distanceM, closeTo(200, 1e-9));
      expect(p.nodeIds, [0, 1, 2]);
      expect(r.timedOut, isFalse);
    });

    test('1回の探索で複数ターゲットの実コストを同時に得られる（§9.1）', () {
      idSeq = 0;
      final g = graphOf([e(0, 1, 100), e(1, 2, 100), e(0, 3, 50)]);
      final r = MultiTargetDijkstra(g).run(
        startNode: 0,
        targets: const {'near': 3, 'far': 2, 'mid': 1},
        profile: const RoutingProfile(),
      );
      expect(r.found.keys, containsAll(['near', 'far', 'mid']));
      expect(r.found['near']!.costSec, closeTo(50 / 1.25, 1e-9));
      expect(r.found['far']!.costSec, closeTo(200 / 1.25, 1e-9));
    });

    test('到達不能なターゲットは結果に含まれない', () {
      idSeq = 0;
      final g = graphOf([e(0, 1, 100)]);
      final r = MultiTargetDijkstra(g).run(
        startNode: 0,
        targets: const {'ok': 1, 'unreachable': 9},
        profile: const RoutingProfile(),
      );
      expect(r.found.containsKey('ok'), isTrue);
      expect(r.found.containsKey('unreachable'), isFalse);
    });
  });

  group('§20.4 決定性（MUST）', () {
    test('同一入力に対し完全に同一の経路が返る', () {
      idSeq = 0;
      final edges = [e(0, 1, 100), e(0, 2, 100), e(1, 3, 100), e(2, 3, 100)];
      final g = graphOf(edges);
      // 同コストの菱形状: ノード番号の小さい側（0→1→3）に決定的に統一
      final r1 = MultiTargetDijkstra(g).run(
        startNode: 0,
        targets: const {'t': 3},
        profile: const RoutingProfile(),
      );
      final r2 = MultiTargetDijkstra(g).run(
        startNode: 0,
        targets: const {'t': 3},
        profile: const RoutingProfile(),
      );
      expect(r1.found['t']!.nodeIds, r2.found['t']!.nodeIds);
      expect(r1.found['t']!.nodeIds, [0, 1, 3]);
    });
  });

  group('§20.4 バリアフリー', () {
    test('mobility=wheelchair で階段エッジを含まない', () {
      idSeq = 0;
      final g = graphOf([
        e(0, 1, 100, wayType: WayType.steps), // 近道だが階段
        e(1, 3, 100),
        e(0, 2, 150), // 迂回
        e(2, 3, 150),
      ]);
      const wheelchair = RoutingProfile(
        speedMps: 0.7,
        forbidSteps: true,
        forbidNarrowWheelchair: true,
      );
      final r = MultiTargetDijkstra(
        g,
      ).run(startNode: 0, targets: const {'t': 3}, profile: wheelchair);
      expect(r.found['t']!.nodeIds, [0, 2, 3]);
      expect(r.found['t']!.costSec, closeTo(300 / 0.7, 1e-9));
    });

    test('階段しか経路がない場合は候補から外れる（安全側）', () {
      idSeq = 0;
      final g = graphOf([e(0, 1, 100, wayType: WayType.steps)]);
      const wheelchair = RoutingProfile(speedMps: 0.7, forbidSteps: true);
      final r = MultiTargetDijkstra(
        g,
      ).run(startNode: 0, targets: const {'t': 1}, profile: wheelchair);
      expect(r.found.containsKey('t'), isFalse);
    });
  });

  group('ハザード回避', () {
    test('洪水想定区域のエッジは迂回が選ばれる', () {
      idSeq = 0;
      final g = graphOf([
        e(0, 1, 100, hzFloodDepth: 2), // 近道だが浸水想定
        e(0, 2, 200),
        e(2, 1, 200), // 迂回 400m
      ]);
      const flood = RoutingProfile(hazardField: HazardEdgeKind.flood);
      final r = MultiTargetDijkstra(
        g,
      ).run(startNode: 0, targets: const {'t': 1}, profile: flood);
      // 直通: 100/1.25×5 = 400s、迂回: 400/1.25 = 320s
      expect(r.found['t']!.nodeIds, [0, 2, 1]);
    });

    test('無関係な災害種別では近道が選ばれる', () {
      idSeq = 0;
      final g = graphOf([
        e(0, 1, 100, hzFloodDepth: 2),
        e(0, 2, 200),
        e(2, 1, 200),
      ]);
      const quake = RoutingProfile(hazardField: HazardEdgeKind.none);
      final r = MultiTargetDijkstra(
        g,
      ).run(startNode: 0, targets: const {'t': 1}, profile: quake);
      expect(r.found['t']!.nodeIds, [0, 1]);
    });
  });

  group('§20.4 タイムアウト', () {
    test('巨大グラフでもタイムアウト内に必ず終了する', () {
      // 一直線 5 万ノードの鎖
      idSeq = 0;
      final edges = [
        for (var i = 0; i < 50000; i++)
          GraphEdge(
            id: i,
            fromNode: i,
            toNode: i + 1,
            lengthM: 10,
            wayType: WayType.residential,
            widthClass: WidthClass.wide,
          ),
      ];
      final g = graphOf(edges, maxNode: 50000);
      final sw = Stopwatch()..start();
      final r = MultiTargetDijkstra(g).run(
        startNode: 0,
        targets: const {'t': 50000},
        profile: const RoutingProfile(),
        timeout: const Duration(milliseconds: 1),
      );
      sw.stop();
      expect(sw.elapsed, lessThan(const Duration(seconds: 3)));
      expect(r.timedOut, isTrue);
    });
  });
}
