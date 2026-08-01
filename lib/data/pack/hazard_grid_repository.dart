import 'package:drift/drift.dart';

import '../../core/geo/geo_point.dart';
import '../../domain/entities/hazard_context.dart';

/// §14.3 ハザードグリッドの参照（1 行 lookup。ハザードプライア・
/// 判定コンテキスト・ShelterQuery.matches の避難所所在地判定に使う）。
///
/// cell_id エンコードは tools/packgen/hazard.py と同一（1/2000 度グリッド）。
class HazardGridRepository {
  HazardGridRepository(this._db);

  final DatabaseConnectionUser _db;

  static const _gridScale = 2000;

  static int cellIdFor(GeoPoint p) =>
      (p.lat * _gridScale).floor() * 1000000 + (p.lng * _gridScale).floor();

  /// 指定地点のハザードコンテキストを返す。
  /// グリッドに無い地点は区域外（既定値）として扱う。
  Future<HazardContext> contextAt(GeoPoint p) async {
    final rows = await _db
        .customSelect(
          'SELECT elevation_m, flood_depth_m, tsunami_depth_m,'
          ' landslide_class, storm_surge_m, volcano_class,'
          ' dist_coast_m, dist_river_m, dense_wood'
          ' FROM hazard_grid WHERE cell_id = ?',
          variables: [Variable.withInt(cellIdFor(p))],
        )
        .get();
    if (rows.isEmpty) return const HazardContext();
    final r = rows.first.data;
    final flood = (r['flood_depth_m'] as num?)?.toDouble() ?? 0;
    final tsunami = (r['tsunami_depth_m'] as num?)?.toDouble() ?? 0;
    final surge = (r['storm_surge_m'] as num?)?.toDouble() ?? 0;
    return HazardContext(
      inFloodZone: flood > 0,
      floodDepthM: flood,
      inTsunamiZone: tsunami > 0,
      tsunamiDepthM: tsunami,
      landslideClass: (r['landslide_class'] as num?)?.toInt() ?? 0,
      inStormSurgeZone: surge > 0,
      stormSurgeM: surge,
      volcanoClass: (r['volcano_class'] as num?)?.toInt() ?? 0,
      distCoastM: (r['dist_coast_m'] as num?)?.toInt(),
      distRiverM: (r['dist_river_m'] as num?)?.toInt(),
      denseWood: ((r['dense_wood'] as num?)?.toInt() ?? 0) != 0,
      currentElevationM: (r['elevation_m'] as num?)?.toDouble(),
    );
  }
}
