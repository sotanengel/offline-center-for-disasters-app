import '../../core/geo/geo_point.dart';
import '../entities/disaster_candidate.dart';

/// §3.4-a / §14.4: 現在地から災害種別の事前確率を返す（AI 不使用）。
abstract interface class HazardPrior {
  /// スコア降順の候補リスト（7 種別すべて。低スコアも除外しない）。
  Future<List<DisasterCandidate>> rank(GeoPoint origin);
}
