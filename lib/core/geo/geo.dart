import 'dart:math' as math;

import 'geo_point.dart';

const double _earthRadiusM = 6371000;

/// Haversine による 2 点間の大圏距離 [m]。
double haversineM(GeoPoint a, GeoPoint b) {
  final dLat = _rad(b.lat - a.lat);
  final dLng = _rad(b.lng - a.lng);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(a.lat)) *
          math.cos(_rad(b.lat)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusM * math.asin(math.sqrt(h));
}

/// a から b への初期方位角 [度]。北=0、時計回り 0〜360。
double bearingDeg(GeoPoint a, GeoPoint b) {
  final lat1 = _rad(a.lat);
  final lat2 = _rad(b.lat);
  final dLng = _rad(b.lng - a.lng);
  final y = math.sin(dLng) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

/// 方位差を (-180, 180] に正規化する。正=右回り（§9.3 の Δθ）。
double normalizeTurnDeg(double diff) {
  var d = diff % 360;
  if (d <= -180) d += 360;
  if (d > 180) d -= 360;
  return d;
}

double _rad(double deg) => deg * math.pi / 180;
