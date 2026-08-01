import 'dart:io';

import 'package:drift/drift.dart';

import '../../core/result/result.dart';
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
class DataPack {
  DataPack._(this.db, this.metadata);

  final PackDatabase db;

  /// metadata テーブル（region / schema / sources / notes / bbox 等）
  final Map<String, String> metadata;

  late final HazardGridRepository hazardGrid = HazardGridRepository(db);
  late final ShelterFinder shelterFinder = ShelterFinder(db, hazardGrid);
  late final GraphLoader graphLoader = GraphLoader(db);

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
