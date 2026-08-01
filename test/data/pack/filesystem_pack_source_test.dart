import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/result/result.dart';
import 'package:offline_center_for_disasters/data/pack/pack_source.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('packs_src_');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('FilesystemPackSource は packs/*/pack.sqlite を列挙する', () async {
    for (final region in ['tokyo', 'kanagawa']) {
      final dir = Directory(p.join(root.path, region));
      await dir.create(recursive: true);
      await File(p.join(dir.path, 'pack.sqlite')).writeAsBytes([0]);
    }
    await Directory(p.join(root.path, 'empty')).create();

    final source = FilesystemPackSource(root);
    final result = await source.listInstalledRegions();
    expect(result, isA<Ok<List<String>, PackSourceError>>());
    final regions = (result as Ok<List<String>, PackSourceError>).value;
    expect(regions, ['kanagawa', 'tokyo']);
  });

  test('パックが無いディレクトリは空一覧', () async {
    final source = FilesystemPackSource(root);
    final result = await source.listInstalledRegions();
    expect((result as Ok<List<String>, PackSourceError>).value, isEmpty);
  });
}
