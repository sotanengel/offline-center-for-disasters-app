import '../entities/enums.dart';
import '../entities/hazard_context.dart';
import '../entities/routing_profile.dart';
import '../entities/shelter_query.dart';
import '../entities/user_state.dart';
import 'tsunami_elevation_rule.dart';

/// §4.1 決定表: 災害種別 → 探索条件 / ルーティングプロファイル（純粋関数群）。
///
/// 条件の適用自体は [ShelterQuery.matches] が担う。
class DestinationPolicy {
  const DestinationPolicy();

  static const _elevationRule = TsunamiElevationRule();

  /// §4.1 決定表 + §4.2 高さ判定を反映した探索条件を返す。
  ShelterQuery buildQuery(
    DisasterType type,
    HazardContext ctx,
    UserState user,
  ) {
    return ShelterQuery(
      disasterType: type,
      minElevationM: type == DisasterType.tsunami
          ? _elevationRule.requiredElevationM(ctx)
          : 0,
    );
  }

  /// §9.2 のコスト係数を災害種別・移動能力・夜間から決定する。
  RoutingProfile buildRoutingProfile(
    DisasterType type,
    UserState user,
    bool isNight,
  ) {
    final speedMps = switch (user.mobility) {
      Mobility.normal => 1.25,
      Mobility.slow => 0.8,
      Mobility.assisted => 0.6,
      Mobility.wheelchair => 0.7,
      // stretcher は assisted に準ずる（§9.2 の表に無いため）
      Mobility.stretcher => 0.6,
      Mobility.unknown => 1.25,
    };

    final isWaterHazard =
        type == DisasterType.flood ||
        type == DisasterType.tsunami ||
        type == DisasterType.stormSurge;

    final hazardField = switch (type) {
      DisasterType.tsunami => HazardEdgeKind.tsunami,
      DisasterType.flood => HazardEdgeKind.flood,
      DisasterType.landslide => HazardEdgeKind.landslide,
      DisasterType.stormSurge => HazardEdgeKind.stormSurge,
      DisasterType.volcano => HazardEdgeKind.volcano,
      // §4.1 unknown: 全災害のペナルティの最大値を適用
      DisasterType.unknown => HazardEdgeKind.any,
      _ => HazardEdgeKind.none,
    };

    return RoutingProfile(
      speedMps: speedMps,
      hazardField: hazardField,
      landslideSpecialForbidden: type == DisasterType.landslide,
      forbidUnderpass: isWaterHazard,
      underpassPenalty: isWaterHazard ? 0.0 : 2.0,
      riverNearPenalty: isWaterHazard ? 0.5 : 0.0,
      narrowPenalty: type == DisasterType.earthquake ? 0.8 : 0.0,
      forbidSteps:
          user.mobility != Mobility.normal && user.mobility != Mobility.unknown,
      forbidNarrowWheelchair: user.mobility == Mobility.wheelchair,
      isNight: isNight,
    );
  }
}
