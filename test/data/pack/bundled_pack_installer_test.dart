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

  test('同梱パックを Application Support 相当へコピーする', () async {
    const payload = [1, 2, 3, 4];
    final bundle = _FakeAssetBundle({
      BundledPackInstaller.assetPathFor('tokyo'): Uint8List.fromList(payload),
    });

    await BundledPackInstaller.ensureInstalled(root, bundle: bundle);

    final dest = File(p.join(root.path, 'tokyo', 'pack.sqlite'));
    expect(await dest.exists(), isTrue);
    expect(await dest.readAsBytes(), payload);
  });

  test('既存パックがある場合は上書きしない', () async {
    final existing = File(p.join(root.path, 'tokyo', 'pack.sqlite'));
    await existing.parent.create(recursive: true);
    await existing.writeAsBytes([9, 9, 9]);

    final bundle = _FakeAssetBundle({
      BundledPackInstaller.assetPathFor('tokyo'): Uint8List.fromList([1]),
    });
    await BundledPackInstaller.ensureInstalled(root, bundle: bundle);

    expect(await existing.readAsBytes(), [9, 9, 9]);
  });

  test('asset 不在時は例外を投げずスキップする', () async {
    await BundledPackInstaller.ensureInstalled(
      root,
      bundle: _FakeAssetBundle(const {}),
    );
    expect(
      File(p.join(root.path, 'tokyo', 'pack.sqlite')).existsSync(),
      isFalse,
    );
  });
}
