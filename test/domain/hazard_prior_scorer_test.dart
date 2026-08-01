import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/hazard_context.dart';
import 'package:offline_center_for_disasters/domain/policies/hazard_prior_scorer.dart';

/// §3.4-a ハザードプライアのスコア式（AI 不使用の決定論）
void main() {
  int scoreOf(HazardContext ctx, DisasterType type) =>
      HazardPriorScorer().rank(ctx).firstWhere((c) => c.type == type).score;

  group('スコア式', () {
    test('津波: 想定域内 100 + 海岸距離ボーナス（max 40）', () {
      const ctx = HazardContext(inTsunamiZone: true, distCoastM: 1000);
      // 100 + max(0, 40 - 1*10) = 130
      expect(scoreOf(ctx, DisasterType.tsunami), 130);
    });

    test('津波: 域外・海岸 2km は 40 - 20 = 20', () {
      const ctx = HazardContext(distCoastM: 2000);
      expect(scoreOf(ctx, DisasterType.tsunami), 20);
    });

    test('津波: 海岸 5km 以上はボーナス 0。距離不明も 0', () {
      expect(
        scoreOf(const HazardContext(distCoastM: 5000), DisasterType.tsunami),
        0,
      );
      expect(scoreOf(const HazardContext(), DisasterType.tsunami), 0);
    });

    test('洪水: 想定域内 100 + 河川距離ボーナス（max 30）', () {
      const ctx = HazardContext(inFloodZone: true, distRiverM: 1000);
      // 100 + max(0, 30 - 1*15) = 115
      expect(scoreOf(ctx, DisasterType.flood), 115);
    });

    test('洪水: 域外・河川 1km は 15。2km 以上は 0', () {
      expect(
        scoreOf(const HazardContext(distRiverM: 1000), DisasterType.flood),
        15,
      );
      expect(
        scoreOf(const HazardContext(distRiverM: 2000), DisasterType.flood),
        0,
      );
    });

    test('土砂: 特別警戒区域 100 / 警戒区域 70 / 併存は 170', () {
      expect(
        scoreOf(const HazardContext(landslideClass: 2), DisasterType.landslide),
        100,
      );
      expect(
        scoreOf(const HazardContext(landslideClass: 1), DisasterType.landslide),
        70,
      );
      expect(
        scoreOf(const HazardContext(landslideClass: 0), DisasterType.landslide),
        0,
      );
    });

    test('高潮: 想定域内のみ 100', () {
      expect(
        scoreOf(
          const HazardContext(inStormSurgeZone: true),
          DisasterType.stormSurge,
        ),
        100,
      );
      expect(scoreOf(const HazardContext(), DisasterType.stormSurge), 0);
    });

    test('噴火: 警戒地域内のみ 100', () {
      expect(
        scoreOf(const HazardContext(volcanoClass: 1), DisasterType.volcano),
        100,
      );
      expect(scoreOf(const HazardContext(), DisasterType.volcano), 0);
    });

    test('地震: 全国どこでも 30', () {
      expect(scoreOf(const HazardContext(), DisasterType.earthquake), 30);
    });

    test('火災: 木造密集 60 / それ以外 20', () {
      expect(
        scoreOf(const HazardContext(denseWood: true), DisasterType.fire),
        60,
      );
      expect(scoreOf(const HazardContext(), DisasterType.fire), 20);
    });
  });

  group('並び順（§3.4-a: 降順、低スコアも非表示にしない）', () {
    test('想定区域内の種別が最上位になる（§20.2）', () {
      final ranked = HazardPriorScorer().rank(
        const HazardContext(inTsunamiZone: true, distCoastM: 500),
      );
      expect(ranked.first.type, DisasterType.tsunami);
    });

    test('7 種別すべてが必ず返る（低スコアでも欠落しない MUST NOT 対応）', () {
      final ranked = HazardPriorScorer().rank(const HazardContext());
      expect(ranked.length, 7);
      expect(
        ranked.map((c) => c.type),
        containsAll([
          DisasterType.tsunami,
          DisasterType.flood,
          DisasterType.landslide,
          DisasterType.earthquake,
          DisasterType.stormSurge,
          DisasterType.fire,
          DisasterType.volcano,
        ]),
      );
    });

    test('降順ソート・同点は固定順（決定性）', () {
      final ranked = HazardPriorScorer().rank(const HazardContext());
      for (var i = 0; i + 1 < ranked.length; i++) {
        expect(ranked[i].score, greaterThanOrEqualTo(ranked[i + 1].score));
      }
      // 無データ地点: earthquake(30) > fire(20) > その他(0)
      expect(ranked.first.type, DisasterType.earthquake);
      expect(ranked[1].type, DisasterType.fire);
      // 2 回呼んで同一順序
      final again = HazardPriorScorer().rank(const HazardContext());
      expect(
        ranked.map((c) => c.type).toList(),
        again.map((c) => c.type).toList(),
      );
    });

    test('コンテキストが各候補に保持される（§14.4 DisasterCandidate）', () {
      const ctx = HazardContext(inFloodZone: true, floodDepthM: 2);
      final ranked = HazardPriorScorer().rank(ctx);
      expect(ranked.every((c) => c.context == ctx), isTrue);
    });
  });
}
