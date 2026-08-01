import 'package:freezed_annotation/freezed_annotation.dart';

part 'hazard_context.freezed.dart';

/// ハザードグリッド 1 行に相当するコンテキスト（§14.3）。
/// 現在地・避難所所在地いずれの参照にも使う。
@freezed
abstract class HazardContext with _$HazardContext {
  const factory HazardContext({
    @Default(false) bool inFloodZone,
    @Default(0) double floodDepthM,
    @Default(false) bool inTsunamiZone,
    @Default(0) double tsunamiDepthM,

    /// 0: 区域外 1: 警戒区域 2: 特別警戒区域
    @Default(0) int landslideClass,
    @Default(false) bool inStormSurgeZone,
    @Default(0) double stormSurgeM,
    @Default(0) int volcanoClass,
    int? distCoastM,
    int? distRiverM,
    @Default(false) bool denseWood,
    double? currentElevationM,

    /// 猶予時間（津波到達想定時間等）。不明なら null。
    Duration? graceTime,
  }) = _HazardContext;
}
