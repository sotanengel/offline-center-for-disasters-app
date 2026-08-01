import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/data/routing/turn_by_turn_builder.dart';
import 'package:offline_center_for_disasters/domain/entities/route_result.dart';

/// §9.3 ターンバイターン: 方位差からの機械生成（LLM 不使用）
void main() {
  GeoPoint at(double lat, double lng) => GeoPoint(lat, lng);

  // 1 レッグ = (points, landmarkName)。points はレッグの向き済み折れ線。
  PathLeg leg(List<GeoPoint> points, {String? landmark}) =>
      PathLeg(points: points, landmarkName: landmark);

  group('方位差による分類', () {
    test('|Δθ| < 20° は直進に統合される', () {
      // 東→東→東（一直線）
      final instructions = TurnByTurnBuilder().build([
        leg([at(35.0, 139.0), at(35.0, 139.0005)]),
        leg([at(35.0, 139.0005), at(35.0, 139.0010)]),
        leg([at(35.0, 139.0010), at(35.0, 139.0015)]),
      ]);
      // 出発 + 直進 1 本 + 到着
      final straights = instructions
          .where((i) => i.kind == TurnKind.goStraight)
          .toList();
      expect(straights.length, 1);
      expect(straights.single.distanceM, greaterThan(120));
      expect(straights.single.text, endsWith('m 直進'));
      expect(instructions.last.kind, TurnKind.arrive);
    });

    test('20–60° は斜め右/左', () {
      // 北(0°)→ 北東寄り(45°): 右へ 45°
      final right = TurnByTurnBuilder().build([
        leg([at(35.0, 139.0), at(35.001, 139.0)]),
        leg([at(35.001, 139.0), at(35.002, 139.0012)]),
      ]);
      expect(
        right.any((i) => i.kind == TurnKind.slightRight && i.text == '斜め右'),
        isTrue,
      );

      // 北(0°)→ 北西寄り(315°): 左へ 45°
      final left = TurnByTurnBuilder().build([
        leg([at(35.0, 139.0), at(35.001, 139.0)]),
        leg([at(35.001, 139.0), at(35.002, 138.9988)]),
      ]);
      expect(
        left.any((i) => i.kind == TurnKind.slightLeft && i.text == '斜め左'),
        isTrue,
      );
    });

    test('60–135° は右折/左折', () {
      // 東(90°)→ 南(180°): 右折
      final right = TurnByTurnBuilder().build([
        leg([at(35.0, 139.0), at(35.0, 139.001)]),
        leg([at(35.0, 139.001), at(34.999, 139.001)]),
      ]);
      final turn = right.firstWhere((i) => i.kind == TurnKind.turnRight);
      expect(turn.text, '右折');

      // 東(90°)→ 北(0°): 左折
      final left = TurnByTurnBuilder().build([
        leg([at(35.0, 139.0), at(35.0, 139.001)]),
        leg([at(35.0, 139.001), at(35.001, 139.001)]),
      ]);
      expect(left.any((i) => i.kind == TurnKind.turnLeft), isTrue);
    });

    test('≥135° は引き返す', () {
      // 東→西（Uターン）
      final instructions = TurnByTurnBuilder().build([
        leg([at(35.0, 139.0), at(35.0, 139.001)]),
        leg([at(35.0, 139.001), at(35.0, 139.0)]),
      ]);
      expect(
        instructions.any((i) => i.kind == TurnKind.uturn && i.text == '引き返す'),
        isTrue,
      );
    });
  });

  group('テンプレート文言（§9.3）', () {
    test('直進は "{distance}m 直進"', () {
      final instructions = TurnByTurnBuilder().build([
        leg([at(35.0, 139.0), at(35.0, 139.001)]), // 約 91m
      ]);
      final s = instructions.firstWhere((i) => i.kind == TurnKind.goStraight);
      expect(s.text, matches(RegExp(r'^\d+m 直進$')));
    });

    test('ランドマークがある曲がり角は "{landmark}を右折"', () {
      final instructions = TurnByTurnBuilder().build([
        leg([at(35.0, 139.0), at(35.0, 139.001)]),
        leg([at(35.0, 139.001), at(34.999, 139.001)], landmark: '〇〇神社'),
      ]);
      final turn = instructions.firstWhere((i) => i.kind == TurnKind.turnRight);
      expect(turn.text, '〇〇神社を右折');
      expect(turn.landmarkName, '〇〇神社');
    });

    test('最後は到着、先頭は出発', () {
      final instructions = TurnByTurnBuilder().build([
        leg([at(35.0, 139.0), at(35.0, 139.001)]),
      ]);
      expect(instructions.first.kind, TurnKind.depart);
      expect(instructions.last.kind, TurnKind.arrive);
      expect(instructions.last.text, '到着');
    });
  });
}
