import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/data/pack/bundled_pack_installer.dart';
import 'package:path/path.dart' as p;

class _FakeAssetBundle extends AssetBundle {
  _FakeAssetBundle(this._files);

  final Map<String, Uint8List> _files;

  @override
  Future<ByteData> load(String key) async {
    final bytes = _files[key];
    if (bytes == null) {
      throw FlutterError('Asset not found: $key');
    }
    return ByteData.sublistView(bytes);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    throw UnimplementedError();
  }

  @override
  void evict(String key) {}
}

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('bundled_pack_');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('同梱 bundled パックを Application Support 相当へコピーする', () async {
    const payload = [1, 2, 3, 4];
    final bundle = _FakeAssetBundle({
      BundledPackInstaller.assetPathFor('bundled'): Uint8List.fromList(payload),
    });

    await BundledPackInstaller.ensureInstalled(root, bundle: bundle);

    final dest = File(BundledPackInstaller.packPathFor(root));
    expect(await dest.exists(), isTrue);
    expect(await dest.readAsBytes(), payload);
  });

  test('既存 bundled パックがある場合は上書きしない', () async {
    final existing = File(BundledPackInstaller.packPathFor(root));
    await existing.parent.create(recursive: true);
    await existing.writeAsBytes([9, 9, 9]);

    final bundle = _FakeAssetBundle({
      BundledPackInstaller.assetPathFor('bundled'): Uint8List.fromList([1]),
    });
    await BundledPackInstaller.ensureInstalled(root, bundle: bundle);

    expect(await existing.readAsBytes(), [9, 9, 9]);
  });

  test('bundled 導入後に legacy tokyo / kanto パックを削除する', () async {
    for (final legacy in ['tokyo', 'kanto']) {
      final legacyFile = File(p.join(root.path, legacy, 'pack.sqlite'));
      await legacyFile.parent.create(recursive: true);
      await legacyFile.writeAsBytes([7]);
    }

    final bundle = _FakeAssetBundle({
      BundledPackInstaller.assetPathFor('bundled'): Uint8List.fromList([1, 2]),
    });
    await BundledPackInstaller.ensureInstalled(root, bundle: bundle);

    expect(File(BundledPackInstaller.packPathFor(root)).existsSync(), isTrue);
    expect(Directory(p.join(root.path, 'tokyo')).existsSync(), isFalse);
    expect(Directory(p.join(root.path, 'kanto')).existsSync(), isFalse);
  });

  test('asset 不在時は例外を投げずスキップする', () async {
    await BundledPackInstaller.ensureInstalled(
      root,
      bundle: _FakeAssetBundle(const {}),
    );
    expect(File(BundledPackInstaller.packPathFor(root)).existsSync(), isFalse);
  });
}
