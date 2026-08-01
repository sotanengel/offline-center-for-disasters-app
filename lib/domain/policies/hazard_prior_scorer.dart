import 'dart:math' as math;

import '../entities/disaster_candidate.dart';
import '../entities/enums.dart';
import '../entities/hazard_context.dart';

/// §3.4-a ハザードプライアのスコア式（AI 不使用・決定論、MUST）。
///
/// score(tsunami)    = (想定域内 ? 100 : 0) + max(0, 40 - 海岸距離km*10)
/// score(flood)      = (想定域内 ? 100 : 0) + max(0, 30 - 河川距離km*15)
/// score(landslide)  = (特別警戒区域 ? 100 : 0) + (警戒区域 ? 70 : 0)
/// score(stormSurge) = (想定域内 ? 100 : 0)
/// score(volcano)    = (警戒地域内 ? 100 : 0)
/// score(earthquake) = 30
/// score(fire)       = (木造密集 ? 60 : 20)
class HazardPriorScorer {
  /// 同点時の固定順（決定性担保）。
  static const _tieBreakOrder = [
    DisasterType.tsunami,
    DisasterType.flood,
    DisasterType.landslide,
    DisasterType.earthquake,
    DisasterType.stormSurge,
    DisasterType.fire,
    DisasterType.volcano,
  ];

  /// スコア降順（同点は固定順）の 7 種別すべてを返す。
  List<DisasterCandidate> rank(HazardContext ctx) {
    final scores = {
      DisasterType.tsunami:
          (ctx.inTsunamiZone ? 100 : 0) + _coastBonus(ctx.distCoastM),
      DisasterType.flood:
          (ctx.inFloodZone ? 100 : 0) + _riverBonus(ctx.distRiverM),
      DisasterType.landslide:
          (ctx.landslideClass == 2 ? 100 : 0) +
          (ctx.landslideClass == 1 ? 70 : 0),
      DisasterType.stormSurge: ctx.inStormSurgeZone ? 100 : 0,
      DisasterType.volcano: ctx.volcanoClass > 0 ? 100 : 0,
      DisasterType.earthquake: 30,
      DisasterType.fire: ctx.denseWood ? 60 : 20,
    };
    final candidates = [
      for (final type in _tieBreakOrder)
        DisasterCandidate(type: type, score: scores[type]!, context: ctx),
    ];
    candidates.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return _tieBreakOrder
          .indexOf(a.type)
          .compareTo(_tieBreakOrder.indexOf(b.type));
    });
    return candidates;
  }

  int _coastBonus(int? distCoastM) {
    if (distCoastM == null) return 0;
    return math.max(0, 40 - (distCoastM / 1000 * 10).floor());
  }

  int _riverBonus(int? distRiverM) {
    if (distRiverM == null) return 0;
    return math.max(0, 30 - (distRiverM / 1000 * 15).floor());
  }
}
