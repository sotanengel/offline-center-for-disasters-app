import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/data/pack/pack_database.dart';
import 'package:offline_center_for_disasters/core/result/result.dart';
import 'package:offline_center_for_disasters/data/pack/pack_loader.dart';

import 'pack_fixture.dart';

/// パックローダの整合性検証（§14.5: 破損・非互換パックで起動不能にしない）
void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pack_test');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  Future<File> writePack(
    String name,
    Future<void> Function(PackDatabase db) seed,
  ) async {
    final file = File('${tmp.path}/$name');
    final db = PackDatabase.file(file);
    await seed(db);
    await db.close();
    return file;
  }

  test('正常なパックを開くと metadata が読める', () async {
    final file = await writePack('ok.sqlite', (db) async {
      await createSchema(db);
      await insertMetadata(db, 'region', 'tokyo');
      await insertMetadata(db, 'schema', 'spec-§14 v1');
    });
    final result = await PackLoader.open(file.path);
    final pack = switch (result) {
      Ok(value: final p) => p,
      Err(error: final e) => fail('開けるはずのパックが失敗: $e'),
    };
    expect(pack.metadata['region'], 'tokyo');
    expect(pack.metadata['schema'], 'spec-§14 v1');
    await pack.close();
  });

  test('必須テーブル欠損は Err（起動不能にしない）', () async {
    final file = await writePack('broken.sqlite', (db) async {
      db.customStatement(
        'CREATE TABLE metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      );
      await insertMetadata(db, 'region', 'tokyo');
    });
    final result = await PackLoader.open(file.path);
    expect(result, isA<Err<dynamic, dynamic>>());
    switch (result) {
      case Err(error: final e):
        expect(e.message, contains('shelters'));
      case Ok():
        fail('必須テーブル欠損で成功してはならない');
    }
  });

  test('metadata の region 欠損は Err', () async {
    final file = await writePack('nometa.sqlite', (db) async {
      await createSchema(db);
    });
    final result = await PackLoader.open(file.path);
    expect(result, isA<Err<dynamic, dynamic>>());
  });

  test('存在しないファイルは Err', () async {
    final result = await PackLoader.open('${tmp.path}/missing.sqlite');
    expect(result, isA<Err<dynamic, dynamic>>());
  });
}
