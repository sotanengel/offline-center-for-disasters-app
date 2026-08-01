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

  /// [points] すべてを覆い、[marginKm] だけ外側に広げた bbox。
  ///
  /// 経路グラフを「現在地から半径 N km」で読むと範囲が広くなりすぎるため
  /// （東京パックの半径 12km で 61 万ノード）、現在地と避難先が確定した後に
  /// 両者を覆う最小範囲だけ読むために使う（§16.1）。
  factory GeoBounds.covering(
    List<GeoPoint> points, {
    required double marginKm,
  }) {
    if (points.isEmpty) {
      throw ArgumentError.value(points, 'points', 'must not be empty');
    }
    var minLat = points.first.lat;
    var maxLat = points.first.lat;
    var minLng = points.first.lng;
    var maxLng = points.first.lng;
    for (final p in points.skip(1)) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }

    // 度換算は aroundPoint と同じ近似を使う。
    final latMargin = marginKm / 110.94;
    final cosLat = math.cos(((minLat + maxLat) / 2) * math.pi / 180);
    final lngMargin = cosLat.abs() < 1e-6
        ? 180.0
        : marginKm / (111.32 * cosLat.abs());

    return GeoBounds(
      minLat: minLat - latMargin,
      maxLat: maxLat + latMargin,
      minLng: minLng - lngMargin,
      maxLng: maxLng + lngMargin,
    );
  }

  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  bool contains(GeoPoint p) =>
      p.lat >= minLat && p.lat <= maxLat && p.lng >= minLng && p.lng <= maxLng;

  /// 矩形同士が重なる（境界接触を含む）か。
  bool intersects(GeoBounds other) =>
      minLat <= other.maxLat &&
      maxLat >= other.minLat &&
      minLng <= other.maxLng &&
      maxLng >= other.minLng;

  /// metadata.bbox JSON `[minLng, minLat, maxLng, maxLat]` を解釈する。
  static GeoBounds? tryParseBboxJson(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith('[') || !trimmed.endsWith(']')) return null;
    final parts = trimmed
        .substring(1, trimmed.length - 1)
        .split(',')
        .map((s) => double.tryParse(s.trim()))
        .toList();
    if (parts.length != 4 || parts.any((v) => v == null)) return null;
    final minLng = parts[0]!;
    final minLat = parts[1]!;
    final maxLng = parts[2]!;
    final maxLat = parts[3]!;
    if (minLat > maxLat || minLng > maxLng) return null;
    return GeoBounds(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
    );
  }

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
