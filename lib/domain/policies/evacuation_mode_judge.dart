import '../entities/enums.dart';
import '../entities/environment.dart';
import '../entities/hazard_context.dart';

/// §14.4 インタフェース（§4.3 の実体）
abstract interface class EvacuationModeJudge {
  EvacuationMode judge({
    required DisasterType type,
    required HazardContext ctx,
    required Environment env,
    required Duration? estimatedTravelTime,
    Mobility mobility,
  });
}

/// §4.3 水平避難 / 垂直避難の判定（決定論、MUST）
///
/// - 階数が不明な場合は「推奨」ではなく「選択肢として併記」（verticalOptional）
/// - 水位が unknown の場合は根拠なしとして none 相当に扱う
class EvacuationModeJudgeImpl implements EvacuationModeJudge {
  const EvacuationModeJudgeImpl();

  @override
  EvacuationMode judge({
    required DisasterType type,
    required HazardContext ctx,
    required Environment env,
    required Duration? estimatedTravelTime,
    Mobility mobility = Mobility.normal,
  }) {
    final (inZone, depthM) = switch (type) {
      DisasterType.flood => (ctx.inFloodZone, ctx.floodDepthM),
      DisasterType.stormSurge => (ctx.inStormSurgeZone, ctx.stormSurgeM),
      DisasterType.tsunami => (ctx.inTsunamiZone, ctx.tsunamiDepthM),
      _ => (false, 0.0),
    };
    final isWaterHazard =
        type == DisasterType.flood ||
        type == DisasterType.stormSurge ||
        type == DisasterType.tsunami;
    if (!isWaterHazard || !inZone) {
      // 浸水想定域外: その場に留まる or 状況により水平避難
      return EvacuationMode.stayOrHorizontal;
    }

    // required_floor = ceil(想定浸水深 / 3.0) + 1（1 層 3m 概算）
    final requiredFloor = (depthM / 3.0).ceil() + 1;
    final declaredFloor = env.floor;
    if (declaredFloor == null) {
      // 階数不明: 断定しない（MUST）
      return EvacuationMode.verticalOptional;
    }

    final grace = ctx.graceTime;
    final travelExceeded =
        estimatedTravelTime != null &&
        grace != null &&
        estimatedTravelTime > grace;
    final waterNotNone =
        env.waterLevel != WaterLevel.none &&
        env.waterLevel != WaterLevel.unknown;

    if (declaredFloor >= requiredFloor &&
        (travelExceeded || mobility != Mobility.normal || waterNotNone)) {
      // 垂直避難を推奨（経路案内を主表示にしてはならない）
      return EvacuationMode.verticalRecommended;
    }
    return EvacuationMode.horizontal;
  }
}
