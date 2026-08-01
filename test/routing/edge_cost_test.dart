import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/data/routing/edge_cost.dart';
import 'package:offline_center_for_disasters/data/routing/graph_edge.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/routing_profile.dart';

/// §9.2 エッジコスト式の係数テスト（値は要件表どおり）
void main() {
  const base = RoutingProfile(); // speed 1.25, ペナルティ全て 0/無効

  GraphEdge edge({
    double lengthM = 100,
    WayType wayType = WayType.residential,
    WidthClass widthClass = WidthClass.wide,
    int hasSteps = 0,
    int isLit = 1,
    int hzFloodDepth = 0,
    int hzTsunamiDepth = 0,
    int hzLandslide = 0,
    int hzStormSurge = 0,
    int hzVolcano = 0,
    int nearRiver = 0,
  }) {
    return GraphEdge(
      id: 1,
      fromNode: 1,
      toNode: 2,
      lengthM: lengthM,
      wayType: wayType,
      widthClass: widthClass,
      hasSteps: hasSteps,
      isLit: isLit,
      hzFloodDepth: hzFloodDepth,
      hzTsunamiDepth: hzTsunamiDepth,
      hzLandslide: hzLandslide,
      hzStormSurge: hzStormSurge,
      hzVolcano: hzVolcano,
      nearRiver: nearRiver,
    );
  }

  test('平時: cost = length / speed', () {
    expect(traversalCostSec(edge(lengthM: 125), base), closeTo(100, 1e-9));
  });

  group('hazard_penalty', () {
    test('該当災害の想定区域内は 4.0（実質回避 → ×5）', () {
      const p = RoutingProfile(hazardField: HazardEdgeKind.flood);
      expect(
        traversalCostSec(edge(hzFloodDepth: 2), p),
        closeTo(100 / 1.25 * 5, 1e-9),
      );
    });

    test('他災害の hz 属性は無関係（flood 指定で tsunami は加算しない）', () {
      const p = RoutingProfile(hazardField: HazardEdgeKind.flood);
      expect(traversalCostSec(edge(hzTsunamiDepth: 3), p), closeTo(80, 1e-9));
    });

    test('土砂災害特別警戒区域（landslide 時）は通行不可', () {
      const p = RoutingProfile(
        hazardField: HazardEdgeKind.landslide,
        landslideSpecialForbidden: true,
      );
      expect(traversalCostSec(edge(hzLandslide: 2), p), isNull);
    });

    test('土砂災害「警戒区域」(1) は禁止ではなく想定区域内 4.0', () {
      const p = RoutingProfile(
        hazardField: HazardEdgeKind.landslide,
        landslideSpecialForbidden: true,
      );
      expect(
        traversalCostSec(edge(hzLandslide: 1), p),
        closeTo(100 / 1.25 * 5, 1e-9),
      );
    });

    test('河川隣接 20m 以内（浸水系）は +0.5', () {
      const p = RoutingProfile(
        hazardField: HazardEdgeKind.flood,
        riverNearPenalty: 0.5,
      );
      expect(
        traversalCostSec(edge(nearRiver: 1), p),
        closeTo(100 / 1.25 * 1.5, 1e-9),
      );
    });

    test('幅員 < 4m（earthquake 時）は +0.8（narrow/medium 両方）', () {
      const p = RoutingProfile(narrowPenalty: 0.8);
      expect(
        traversalCostSec(edge(widthClass: WidthClass.narrow), p),
        closeTo(80 * 1.8, 1e-9),
      );
      expect(
        traversalCostSec(edge(widthClass: WidthClass.medium), p),
        closeTo(80 * 1.8, 1e-9),
      );
      expect(
        traversalCostSec(edge(widthClass: WidthClass.wide), p),
        closeTo(80, 1e-9),
      );
    });
  });

  group('barrier_penalty', () {
    test('階段エッジ かつ mobility ≠ normal は通行不可', () {
      const p = RoutingProfile(forbidSteps: true, speedMps: 0.7);
      expect(traversalCostSec(edge(wayType: WayType.steps), p), isNull);
      expect(traversalCostSec(edge(hasSteps: 1), p), isNull);
    });

    test('階段エッジでも normal ならペナルティなし', () {
      expect(
        traversalCostSec(edge(wayType: WayType.steps), base),
        closeTo(80, 1e-9),
      );
    });

    test('幅員 < 1.5m かつ wheelchair は通行不可', () {
      const p = RoutingProfile(forbidNarrowWheelchair: true, speedMps: 0.7);
      expect(traversalCostSec(edge(widthClass: WidthClass.narrow), p), isNull);
      expect(
        traversalCostSec(edge(widthClass: WidthClass.medium), p),
        isNotNull,
      );
    });

    test('アンダーパス・地下道（浸水系）は通行不可', () {
      const p = RoutingProfile(forbidUnderpass: true);
      expect(traversalCostSec(edge(wayType: WayType.underpass), p), isNull);
    });

    test('踏切・地下道（その他）は 2.0', () {
      const p = RoutingProfile(underpassPenalty: 2.0);
      expect(
        traversalCostSec(edge(wayType: WayType.underpass), p),
        closeTo(80 * 3, 1e-9),
      );
      expect(
        traversalCostSec(edge(wayType: WayType.crossing), p),
        closeTo(80 * 3, 1e-9),
      );
    });
  });

  group('night_penalty', () {
    test('日没後 かつ 街灯なし は 0.3', () {
      const p = RoutingProfile(isNight: true);
      expect(traversalCostSec(edge(isLit: 0), p), closeTo(80 * 1.3, 1e-9));
    });

    test('日没後でも街灯ありなら無効 / 昼なら無効', () {
      const p = RoutingProfile(isNight: true);
      expect(traversalCostSec(edge(isLit: 1), p), closeTo(80, 1e-9));
      expect(
        traversalCostSec(edge(isLit: 0), const RoutingProfile()),
        closeTo(80, 1e-9),
      );
    });
  });

  test('複合: hazard×barrier×night は乗算で合成される', () {
    const p = RoutingProfile(
      hazardField: HazardEdgeKind.flood,
      underpassPenalty: 2.0,
      isNight: true,
    );
    // ×5 (hazard) ×3 (barrier) ×1.3 (night)
    expect(
      traversalCostSec(
        edge(hzFloodDepth: 1, wayType: WayType.underpass, isLit: 0),
        p,
      ),
      closeTo(80 * 5 * 3 * 1.3, 1e-9),
    );
  });
}
