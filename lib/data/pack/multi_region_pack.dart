import '../../core/geo/geo.dart';
import '../../core/geo/geo_bounds.dart';
import '../../core/geo/geo_point.dart';
import '../../domain/entities/hazard_context.dart';
import '../../domain/entities/shelter.dart';
import '../../domain/entities/shelter_query.dart';
import '../../data/routing/graph_edge.dart';
import '../../data/routing/road_graph.dart';
import 'evacuation_pack.dart';
import 'pack_loader.dart';
import 'shelter_finder.dart';

/// 複数県パックを 1 つの [EvacuationPack] として扱う（県境対応）。
class MultiRegionPack implements EvacuationPack {
  MultiRegionPack(this.packs)
    : assert(packs.isNotEmpty, 'packs must not be empty');

  final List<DataPack> packs;

  @override
  List<String> get regionKeys => [
    for (final p in packs) p.metadata['region'] ?? 'unknown',
  ];

  @override
  Future<HazardContext> contextAt(GeoPoint p) async {
    HazardContext? merged;
    for (final pack in packs) {
      final ctx = await pack.hazardGrid.contextAt(p);
      merged = merged == null ? ctx : _maxHazard(merged, ctx);
    }
    return merged ?? const HazardContext();
  }

  @override
  Future<ShelterSearchResult> findShelters({
    required GeoPoint origin,
    required ShelterQuery query,
  }) async {
    final matched = <(Shelter, double)>[];
    var anyExpanded = false;
    var bestRadius = query.radiusKm;

    for (final pack in packs) {
      final part = await pack.shelterFinder.find(origin: origin, query: query);
      if (part.notFound) continue;
      bestRadius = part.radiusKmUsed;
      if (part.expandedRadius) anyExpanded = true;
      for (final s in part.shelters) {
        matched.add((s, haversineM(origin, GeoPoint(s.lat, s.lng))));
      }
    }

    if (matched.isEmpty) {
      return const ShelterSearchResult(
        shelters: [],
        radiusKmUsed: 10.0,
        notFound: true,
        expandedRadius: false,
      );
    }

    matched.sort((a, b) {
      final d = a.$2.compareTo(b.$2);
      return d != 0 ? d : a.$1.id.compareTo(b.$1.id);
    });

    // 同一 ID は起きない想定だが、念のためユニーク化
    final seen = <String>{};
    final shelters = <Shelter>[];
    for (final (s, _) in matched) {
      if (seen.add(s.id)) shelters.add(s);
      if (shelters.length >= 20) break;
    }

    return ShelterSearchResult(
      shelters: shelters,
      radiusKmUsed: bestRadius,
      notFound: false,
      expandedRadius: anyExpanded,
    );
  }

  @override
  Future<RoadGraph> loadGraph({GeoBounds? bounds}) async {
    final nodes = <int, GeoPoint>{};
    final edgeByPair = <(int, int), GraphEdge>{};
    var nextId = 1;

    for (final pack in packs) {
      final part = await pack.graphLoader.load(bounds: bounds);
      nodes.addAll(part.nodes);
      for (final e in part.edges) {
        final a = e.fromNode < e.toNode ? e.fromNode : e.toNode;
        final b = e.fromNode < e.toNode ? e.toNode : e.fromNode;
        final key = (a, b);
        if (edgeByPair.containsKey(key)) continue;
        edgeByPair[key] = GraphEdge(
          id: nextId++,
          fromNode: e.fromNode,
          toNode: e.toNode,
          lengthM: e.lengthM,
          geometry: e.geometry,
          wayType: e.wayType,
          widthClass: e.widthClass,
          hasSteps: e.hasSteps,
          isLit: e.isLit,
          hzFloodDepth: e.hzFloodDepth,
          hzTsunamiDepth: e.hzTsunamiDepth,
          hzLandslide: e.hzLandslide,
          hzStormSurge: e.hzStormSurge,
          hzVolcano: e.hzVolcano,
          nearRiver: e.nearRiver,
          denseWood: e.denseWood,
          landmarkName: e.landmarkName,
        );
      }
    }

    return RoadGraph(nodes: nodes, edges: edgeByPair.values.toList());
  }

  @override
  Future<void> close() async {
    for (final pack in packs) {
      await pack.close();
    }
  }

  static HazardContext _maxHazard(HazardContext a, HazardContext b) {
    final flood = a.floodDepthM >= b.floodDepthM
        ? a.floodDepthM
        : b.floodDepthM;
    final tsunami = a.tsunamiDepthM >= b.tsunamiDepthM
        ? a.tsunamiDepthM
        : b.tsunamiDepthM;
    final surge = a.stormSurgeM >= b.stormSurgeM
        ? a.stormSurgeM
        : b.stormSurgeM;
    final landslide = a.landslideClass >= b.landslideClass
        ? a.landslideClass
        : b.landslideClass;
    final volcano = a.volcanoClass >= b.volcanoClass
        ? a.volcanoClass
        : b.volcanoClass;
    return HazardContext(
      inFloodZone: flood > 0 || a.inFloodZone || b.inFloodZone,
      floodDepthM: flood,
      inTsunamiZone: tsunami > 0 || a.inTsunamiZone || b.inTsunamiZone,
      tsunamiDepthM: tsunami,
      landslideClass: landslide,
      inStormSurgeZone: surge > 0 || a.inStormSurgeZone || b.inStormSurgeZone,
      stormSurgeM: surge,
      volcanoClass: volcano,
      distCoastM: _minNullable(a.distCoastM, b.distCoastM),
      distRiverM: _minNullable(a.distRiverM, b.distRiverM),
      denseWood: a.denseWood || b.denseWood,
      currentElevationM: a.currentElevationM ?? b.currentElevationM,
      graceTime: a.graceTime ?? b.graceTime,
    );
  }

  static int? _minNullable(int? a, int? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a <= b ? a : b;
  }
}
