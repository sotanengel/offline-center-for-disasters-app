import '../../core/geo/geo_bounds.dart';
import '../../core/geo/geo_point.dart';
import 'region_pack_info.dart';

/// §4.4 の拡大半径（10km）を既定とし、現在地周辺と重なるパックを選ぶ。
const kActivePackRadiusKm = 10.0;

/// 現在地の探索半径と bbox が交差する導入済みパックを返す（regionKey 昇順）。
List<RegionPackInfo> selectActiveRegions({
  required GeoPoint origin,
  required List<RegionPackInfo> installed,
  double radiusKm = kActivePackRadiusKm,
}) {
  final search = GeoBounds.aroundPoint(origin, radiusKm: radiusKm);
  final hit = installed.where((r) => r.bbox.intersects(search)).toList()
    ..sort((a, b) => a.regionKey.compareTo(b.regionKey));
  return hit;
}
