import '../../core/geo/geo_bounds.dart';
import '../../core/geo/geo_point.dart';
import '../../domain/entities/hazard_context.dart';
import '../../domain/entities/shelter_query.dart';
import '../../data/routing/road_graph.dart';
import 'shelter_finder.dart';

/// 単一/複数地域パックの共通面（避難先決定・経路用）。
abstract interface class EvacuationPack {
  Future<HazardContext> contextAt(GeoPoint p);

  Future<ShelterSearchResult> findShelters({
    required GeoPoint origin,
    required ShelterQuery query,
  });

  Future<RoadGraph> loadGraph({GeoBounds? bounds});

  Future<void> close();

  /// 構成する地域キー（表示・デバッグ用）。
  List<String> get regionKeys;
}
