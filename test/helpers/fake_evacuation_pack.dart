import 'package:offline_center_for_disasters/core/geo/geo_bounds.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/data/pack/evacuation_pack.dart';
import 'package:offline_center_for_disasters/data/pack/shelter_finder.dart';
import 'package:offline_center_for_disasters/data/routing/graph_edge.dart';
import 'package:offline_center_for_disasters/data/routing/road_graph.dart';
import 'package:offline_center_for_disasters/domain/entities/hazard_context.dart';
import 'package:offline_center_for_disasters/domain/entities/shelter_query.dart';

/// テスト用の [EvacuationPack] スタブ。
class FakeEvacuationPack implements EvacuationPack {
  FakeEvacuationPack({RoadGraph? graph, this.regionKeys = const ['test']})
    : graph = graph ?? RoadGraph(nodes: const {}, edges: const []);

  final RoadGraph graph;
  @override
  final List<String> regionKeys;

  @override
  Future<void> close() async {}

  @override
  Future<HazardContext> contextAt(GeoPoint p) async => const HazardContext();

  @override
  Future<ShelterSearchResult> findShelters({
    required GeoPoint origin,
    required ShelterQuery query,
  }) async {
    return const ShelterSearchResult(
      shelters: [],
      radiusKmUsed: 3,
      notFound: true,
      expandedRadius: false,
    );
  }

  @override
  Future<RoadGraph> loadGraph({GeoBounds? bounds}) async => graph;
}

/// テスト用の最小道路グラフ（2 本のエッジ）。
RoadGraph sampleRoadGraphForNavTest() {
  const p1 = GeoPoint(35.687741, 139.850977);
  const p2 = GeoPoint(35.688241, 139.851477);
  const p3 = GeoPoint(35.688741, 139.851977);
  return RoadGraph(
    nodes: {1: p1, 2: p2, 3: p3},
    edges: [
      const GraphEdge(id: 1, fromNode: 1, toNode: 2, lengthM: 100),
      const GraphEdge(id: 2, fromNode: 2, toNode: 3, lengthM: 100),
    ],
  );
}
