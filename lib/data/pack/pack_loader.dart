import 'dart:io';

import 'package:drift/drift.dart';

import '../../core/geo/geo_bounds.dart';
import '../../core/geo/geo_point.dart';
import '../../core/result/result.dart';
import '../../domain/entities/hazard_context.dart';
import '../../domain/entities/shelter_query.dart';
import '../../data/routing/road_graph.dart';
import 'evacuation_pack.dart';
import 'graph_loader.dart';
import 'hazard_grid_repository.dart';
import 'pack_database.dart';
import 'shelter_finder.dart';

/// パック検証エラー（§14.5: 破損・非互換パックで起動不能にしない）。
class PackError {
  const PackError(this.message);
  final String message;

  @override
  String toString() => 'PackError: $message';
}

/// 開いた地域パック一式（§14 スキーマ）。
class DataPack implements EvacuationPack {
  DataPack._(this.db, this.metadata);

  /// テスト用（メモリ DB など）。
  factory DataPack.test(PackDatabase db, Map<String, String> metadata) =>
      DataPack._(db, metadata);

  final PackDatabase db;

  /// metadata テーブル（region / schema / sources / notes / bbox 等）
  final Map<String, String> metadata;

  late final HazardGridRepository hazardGrid = HazardGridRepository(db);
  late final ShelterFinder shelterFinder = ShelterFinder(db, hazardGrid);
  late final GraphLoader graphLoader = GraphLoader(db);

  @override
  List<String> get regionKeys {
    final region = metadata['region'];
    return region == null ? const [] : [region];
  }

  @override
  Future<HazardContext> contextAt(GeoPoint p) => hazardGrid.contextAt(p);

  @override
  Future<ShelterSearchResult> findShelters({
    required GeoPoint origin,
    required ShelterQuery query,
  }) => shelterFinder.find(origin: origin, query: query);

  @override
  Future<RoadGraph> loadGraph({GeoBounds? bounds}) =>
      graphLoader.load(bounds: bounds);

  @override
  Future<void> close() => db.close();
}

/// 地域パック（pack.sqlite）を開き、整合性を検証する。
///
/// パックは tools/packgen が生成した読み取り専用の完成品であり、
/// アプリ側ではスキーマ作成・マイグレーションを行わない。
class PackLoader {
  static const _requiredTables = {
    'shelters',
    'shelters_rtree',
    'nodes',
    'edges',
    'hazard_grid',
    'metadata',
  };

  static const _requiredMetadataKeys = {'region', 'schema'};

  static Future<Result<DataPack, PackError>> open(String path) {
    return guard(() async {
      final file = File(path);
      if (!file.existsSync()) {
        throw const PackError('パックファイルが存在しません');
      }
      final db = PackDatabase.file(file);
      try {
        await _validate(db);
        final metadata = await _readMetadata(db);
        return DataPack._(db, metadata);
      } catch (_) {
        await db.close();
        rethrow;
      }
    }, (e) => PackError(e is PackError ? e.message : '$e'));
  }

  static Future<void> _validate(DatabaseConnectionUser db) async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type IN ('table','view')",
        )
        .get();
    final tables = rows.map((r) => r.data['name'] as String).toSet();
    for (final required in _requiredTables) {
      if (!tables.contains(required)) {
        throw PackError('必須テーブル $required がありません');
      }
    }
  }

  static Future<Map<String, String>> _readMetadata(
    DatabaseConnectionUser db,
  ) async {
    final rows = await db.customSelect('SELECT key, value FROM metadata').get();
    final metadata = {
      for (final r in rows) r.data['key'] as String: r.data['value'] as String,
    };
    for (final key in _requiredMetadataKeys) {
      if (!metadata.containsKey(key)) {
        throw PackError('metadata.$key がありません');
      }
    }
    return metadata;
  }
}
