import '../../domain/entities/enums.dart';
import '../../domain/entities/routing_profile.dart';
import 'graph_edge.dart';

/// §9.2 エッジコスト式（純粋関数）。
///
/// cost = length_m / speed_mps
///      × (1 + hazard_penalty)
///      × (1 + barrier_penalty)
///      × (1 + night_penalty)
///
/// 通行不可（表の 999）に相当する場合は null を返す。
/// ハザード判定はパック生成時に事前計算された hz_* 属性のみを使う（MUST）。
double? traversalCostSec(GraphEdge e, RoutingProfile p) {
  // --- 通行不可判定（barrier 999 / 土砂特別警戒区域） ---
  if (e.isSteps && p.forbidSteps) return null;
  if (e.widthClass == WidthClass.narrow && p.forbidNarrowWheelchair) {
    return null;
  }
  if (e.wayType == WayType.underpass && p.forbidUnderpass) return null;
  if (e.hzLandslide == 2 && p.landslideSpecialForbidden) return null;

  // --- hazard_penalty（加算で合成） ---
  var hazard = 0.0;
  if (_inHazardZone(e, p.hazardField)) hazard += p.hazardZonePenalty;
  if (e.nearRiver != 0) hazard += p.riverNearPenalty;
  if (e.widthClass == WidthClass.narrow || e.widthClass == WidthClass.medium) {
    hazard += p.narrowPenalty;
  }

  // --- barrier_penalty ---
  var barrier = 0.0;
  if (e.wayType == WayType.underpass || e.wayType == WayType.crossing) {
    barrier += p.underpassPenalty;
  }

  // --- night_penalty（日没後 かつ 街灯なし） ---
  final night = (p.isNight && e.isLit == 0) ? p.nightPenalty : 0.0;

  return e.lengthM / p.speedMps * (1 + hazard) * (1 + barrier) * (1 + night);
}

bool _inHazardZone(GraphEdge e, HazardEdgeKind kind) {
  return switch (kind) {
    HazardEdgeKind.none => false,
    HazardEdgeKind.flood => e.hzFloodDepth > 0,
    HazardEdgeKind.tsunami => e.hzTsunamiDepth > 0,
    HazardEdgeKind.landslide => e.hzLandslide > 0,
    HazardEdgeKind.stormSurge => e.hzStormSurge > 0,
    HazardEdgeKind.volcano => e.hzVolcano > 0,
    HazardEdgeKind.any =>
      e.hzFloodDepth > 0 ||
          e.hzTsunamiDepth > 0 ||
          e.hzLandslide > 0 ||
          e.hzStormSurge > 0 ||
          e.hzVolcano > 0,
  };
}
