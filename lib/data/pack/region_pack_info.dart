import '../../core/geo/geo_bounds.dart';

/// 導入済み地域パックのメタ情報（パスと bbox）。
class RegionPackInfo {
  const RegionPackInfo({
    required this.regionKey,
    required this.path,
    required this.bbox,
  });

  final String regionKey;
  final String path;
  final GeoBounds bbox;
}
