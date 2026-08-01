import 'dart:math' as math;

import 'geo_point.dart';

/// 緯度経度の矩形範囲（bbox）。
/// GraphLoader などの範囲絞り込みクエリに使う。
class GeoBounds {
  const GeoBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  }) : assert(minLat <= maxLat, 'minLat must be <= maxLat'),
       assert(minLng <= maxLng, 'minLng must be <= maxLng');

  factory GeoBounds.aroundPoint(GeoPoint center, {required double radiusKm}) {
    // 度換算 (Haversine の近似。ShelterFinder と同じ換算)
    final latDelta = radiusKm / 110.94;
    final cosLat = math.cos(center.lat * math.pi / 180);
    // 高緯度で cos が極端に小さくなるとき、経度幅は 180° を上限にクランプ。
    final lngDelta = cosLat.abs() < 1e-6
        ? 180.0
        : radiusKm / (111.32 * cosLat.abs());
    return GeoBounds(
      minLat: center.lat - latDelta,
      maxLat: center.lat + latDelta,
      minLng: center.lng - lngDelta,
      maxLng: center.lng + lngDelta,
    );
  }

  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  bool contains(GeoPoint p) =>
      p.lat >= minLat && p.lat <= maxLat && p.lng >= minLng && p.lng <= maxLng;

  @override
  bool operator ==(Object other) =>
      other is GeoBounds &&
      other.minLat == minLat &&
      other.maxLat == maxLat &&
      other.minLng == minLng &&
      other.maxLng == maxLng;

  @override
  int get hashCode => Object.hash(minLat, maxLat, minLng, maxLng);

  @override
  String toString() =>
      'GeoBounds(lat=[$minLat,$maxLat], lng=[$minLng,$maxLng])';
}
