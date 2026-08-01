import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../core/geo/geo.dart';
import '../../core/geo/geo_point.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/shelter.dart';
import '../../domain/entities/shelter_query.dart';
import 'hazard_grid_repository.dart';

/// ShelterFinder の探索結果。
class ShelterSearchResult {
  const ShelterSearchResult({
    required this.shelters,
    required this.radiusKmUsed,
    required this.notFound,
    required this.expandedRadius,
  });

  /// 直線距離昇順・最大 20 件（§9.1 手順4）。0 件なら空。
  final List<Shelter> shelters;

  /// 実際に使った半径 [km]（§4.4 / Q10: 10 → 20 に拡大したかの記録用）。
  final double radiusKmUsed;

  /// 拡大半径でも 0 件だったこと。true のときは避難先を断定表示しない（§4.4）。
  final bool notFound;

  /// §4.4 / Q10: 初期半径で 0 件となり 20km へ拡大し、拡大側で見つかったか。
  /// [notFound] が true のときは常に false。
  final bool expandedRadius;
}

/// §9.1 手順2〜4: R*Tree 半径検索 → 属性フィルタ（§4.1）→ 距離順 20 件。
/// §4.4 / Q10: 0 件なら半径を 10km → 20km に拡大して再探索（それでも 0 件なら空）。
class ShelterFinder {
  ShelterFinder(this._db, this._hazardGrid);

  final DatabaseConnectionUser _db;
  final HazardGridRepository _hazardGrid;

  static const _maxCandidates = 20;
  static const _expandedRadiusKm = 20.0;
  static const _yieldEveryCandidates = 10;

  Future<ShelterSearchResult> find({
    required GeoPoint origin,
    required ShelterQuery query,
  }) async {
    var attempt = 0;
    for (final radiusKm in [query.radiusKm, _expandedRadiusKm]) {
      attempt++;
      final candidates = await _bboxQuery(origin, radiusKm);
      final matched = <(Shelter, double)>[];
      var processed = 0;
      for (final shelter in candidates) {
        final atShelter = await _hazardGrid.contextAt(
          GeoPoint(shelter.lat, shelter.lng),
        );
        if (query.matches(shelter, atShelter)) {
          matched.add((
            shelter,
            haversineM(origin, GeoPoint(shelter.lat, shelter.lng)),
          ));
        }
        processed++;
        if (processed % _yieldEveryCandidates == 0) {
          await Future<void>.delayed(Duration.zero);
        }
      }
      if (matched.isNotEmpty) {
        // 決定性: 距離昇順、同距離は id 昇順
        matched.sort((a, b) {
          final d = a.$2.compareTo(b.$2);
          return d != 0 ? d : a.$1.id.compareTo(b.$1.id);
        });
        return ShelterSearchResult(
          shelters: matched.take(_maxCandidates).map((e) => e.$1).toList(),
          radiusKmUsed: radiusKm,
          notFound: false,
          // 拡大 (2 回目) で見つかったときのみ true。
          expandedRadius: attempt > 1,
        );
      }
      if (radiusKm >= _expandedRadiusKm) break;
    }
    return const ShelterSearchResult(
      shelters: [],
      radiusKmUsed: _expandedRadiusKm,
      notFound: true,
      expandedRadius: false,
    );
  }

  /// shelters_rtree による bbox 検索（緯度経度を度に換算）。
  Future<List<Shelter>> _bboxQuery(GeoPoint origin, double radiusKm) async {
    final latDelta = radiusKm / 110.94;
    final lngDelta = radiusKm / (111.32 * math.cos(origin.lat * math.pi / 180));
    final rows = await _db
        .customSelect(
          'SELECT s.rowid AS rowid, s.* FROM shelters_rtree r'
          ' JOIN shelters s ON s.rowid = r.id'
          ' WHERE r.maxLat >= ? AND r.minLat <= ?'
          ' AND r.maxLng >= ? AND r.minLng <= ?',
          variables: [
            Variable.withReal(origin.lat - latDelta),
            Variable.withReal(origin.lat + latDelta),
            Variable.withReal(origin.lng - lngDelta),
            Variable.withReal(origin.lng + lngDelta),
          ],
        )
        .get();
    return rows.map((r) => _rowToShelter(r.data)).toList();
  }

  Shelter _rowToShelter(Map<String, Object?> r) {
    bool flag(String col) => ((r[col] as num?)?.toInt() ?? 0) != 0;
    return Shelter(
      id: r['id'] as String,
      name: r['name'] as String,
      lat: (r['lat'] as num).toDouble(),
      lng: (r['lng'] as num).toDouble(),
      elevationM: (r['elevation_m'] as num?)?.toDouble(),
      okFlood: flag('ok_flood'),
      okLandslide: flag('ok_landslide'),
      okStormSurge: flag('ok_storm_surge'),
      okEarthquake: flag('ok_earthquake'),
      okTsunami: flag('ok_tsunami'),
      okFire: flag('ok_fire'),
      okInlandFlood: flag('ok_inland_flood'),
      okVolcano: flag('ok_volcano'),
      isAllHazard: flag('is_all_hazard'),
      placeClass: PlaceClass.values.firstWhere(
        (c) => c.code == (r['place_class'] as num?)?.toInt(),
        orElse: () => PlaceClass.unknownOrBuilding,
      ),
      usableFloorHeightM: (r['usable_floor_height_m'] as num?)?.toDouble(),
      isShelter: flag('is_shelter'),
      barrierFree: flag('barrier_free'),
      capacity: (r['capacity'] as num?)?.toInt(),
      nearestNodeId: (r['nearest_node_id'] as num?)?.toInt(),
      note: r['note'] as String?,
    );
  }
}
