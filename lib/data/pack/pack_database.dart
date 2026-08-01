import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// 地域パック（pack.sqlite）への読み取りアクセス。
///
/// パックは tools/packgen が生成した完成品であり、アプリ側では
/// スキーマ作成・マイグレーションを行わない（allTables は空、migration は no-op）。
class PackDatabase extends GeneratedDatabase {
  PackDatabase(super.connection);

  factory PackDatabase.file(File file) =>
      PackDatabase(DatabaseConnection(NativeDatabase(file)));

  factory PackDatabase.memory() =>
      PackDatabase(DatabaseConnection(NativeDatabase.memory()));

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy();
}
