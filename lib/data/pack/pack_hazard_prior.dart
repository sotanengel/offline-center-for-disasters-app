import '../../core/geo/geo_point.dart';
import '../../domain/entities/disaster_candidate.dart';
import '../../domain/entities/hazard_context.dart';
import '../../domain/policies/hazard_prior_scorer.dart';
import '../../domain/services/hazard_prior.dart';
import 'evacuation_pack.dart';
import 'hazard_grid_repository.dart';

/// §3.4-a / §14.4: パックのハザードグリッド + [HazardPriorScorer] で構成する
/// [HazardPrior] 実装。
///
/// パックの `hazard_grid` に指定地点のセルが無い場合は既定値
/// (`HazardContext()`) をコンテキストとして採点する。
class PackHazardPrior implements HazardPrior {
  PackHazardPrior(HazardGridRepository hazardGrid, HazardPriorScorer scorer)
    : this.lookup(hazardGrid.contextAt, scorer);

  PackHazardPrior.fromPack(EvacuationPack pack, HazardPriorScorer scorer)
    : this.lookup(pack.contextAt, scorer);

  const PackHazardPrior.lookup(this._lookup, this._scorer);

  final Future<HazardContext> Function(GeoPoint) _lookup;
  final HazardPriorScorer _scorer;

  @override
  Future<List<DisasterCandidate>> rank(GeoPoint origin) async {
    final ctx = await _lookup(origin);
    return _scorer.rank(ctx);
  }
}
