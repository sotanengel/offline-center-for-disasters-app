import 'geo.dart';
import 'geo_point.dart';
import '../../domain/entities/route_result.dart';

/// ポリライン上の走行距離 [m]（最近傍点まで）。
double traveledDistanceM(GeoPoint current, List<GeoPoint> polyline) {
  if (polyline.length < 2) return 0;

  var alongPath = 0.0;
  var bestTraveled = 0.0;
  var bestDist = double.infinity;

  for (var i = 0; i < polyline.length - 1; i++) {
    final start = polyline[i];
    final end = polyline[i + 1];
    final segLen = haversineM(start, end);
    final closest = _closestPointOnSegment(current, start, end);
    final distToPath = haversineM(current, closest);
    final segTraveled = segLen == 0
        ? 0.0
        : haversineM(start, closest).clamp(0.0, segLen);

    if (distToPath < bestDist) {
      bestDist = distToPath;
      bestTraveled = alongPath + segTraveled;
    }
    alongPath += segLen;
  }
  return bestTraveled;
}

/// ポリライン上の残距離 [m]（最近傍点から目的地まで）。
double remainingDistanceM(GeoPoint current, List<GeoPoint> polyline) {
  if (polyline.isEmpty) return 0;
  if (polyline.length == 1) return haversineM(current, polyline.first);

  var total = 0.0;
  for (var i = 0; i < polyline.length - 1; i++) {
    total += haversineM(polyline[i], polyline[i + 1]);
  }
  return (total - traveledDistanceM(current, polyline)).clamp(0.0, total);
}

/// 走行距離に対応する現在の案内指示。
TurnInstruction? activeInstruction(
  List<TurnInstruction> instructions,
  double traveledM,
) {
  if (instructions.isEmpty) return null;

  var acc = 0.0;
  for (final inst in instructions) {
    switch (inst.kind) {
      case TurnKind.depart:
        if (traveledM <= 0) return inst;
      case TurnKind.arrive:
        return inst;
      default:
        final nextAcc = acc + inst.distanceM;
        if (traveledM < nextAcc) return inst;
        acc = nextAcc;
    }
  }
  return instructions.last;
}

GeoPoint _closestPointOnSegment(GeoPoint p, GeoPoint a, GeoPoint b) {
  final dx = b.lng - a.lng;
  final dy = b.lat - a.lat;
  final len2 = dx * dx + dy * dy;
  if (len2 == 0) return a;
  var t = ((p.lng - a.lng) * dx + (p.lat - a.lat) * dy) / len2;
  t = t.clamp(0.0, 1.0);
  return GeoPoint(a.lat + dy * t, a.lng + dx * t);
}
