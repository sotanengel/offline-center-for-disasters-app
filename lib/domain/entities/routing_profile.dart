import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'routing_profile.freezed.dart';

/// §9.2 エッジコスト式のパラメータ（DestinationPolicy が災害種別ごとに解決）。
/// 値 999 に相当する「通行不可」は forbid* フラグで表現する。
@freezed
abstract class RoutingProfile with _$RoutingProfile {
  const factory RoutingProfile({
    /// mobility = normal / slow / assisted / wheelchair → 1.25 / 0.8 / 0.6 / 0.7
    @Default(1.25) double speedMps,

    /// どの hz_* 属性を「該当災害の想定区域内」とみなすか
    @Default(HazardEdgeKind.none) HazardEdgeKind hazardField,

    /// 想定区域内ペナルティ（既定 4.0 = 実質回避）
    @Default(4.0) double hazardZonePenalty,

    /// 土砂災害特別警戒区域を通行不可（999）にする
    @Default(false) bool landslideSpecialForbidden,

    /// アンダーパス・地下道を禁止（浸水系: 999）
    @Default(false) bool forbidUnderpass,

    /// アンダーパス・地下道のペナルティ（その他: 2.0）
    @Default(0) double underpassPenalty,

    /// 河川隣接 20m 以内（浸水系: 0.5）
    @Default(0) double riverNearPenalty,

    /// 幅員 < 4m（earthquake 時: 0.8）
    @Default(0) double narrowPenalty,

    /// 階段エッジ禁止（mobility ≠ normal: 999）
    @Default(false) bool forbidSteps,

    /// 幅員 < 1.5m 禁止（mobility = wheelchair: 999）
    @Default(false) bool forbidNarrowWheelchair,

    /// 日没後かどうか（街灯なしエッジに nightPenalty を適用）
    @Default(false) bool isNight,
    @Default(0.3) double nightPenalty,
  }) = _RoutingProfile;
}
