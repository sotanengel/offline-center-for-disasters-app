import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// アプリ同梱（assets/packs）の地域パックを Application Support へ展開する。
///
/// 初回起動時のみコピーし、既に [packsRoot]/[region]/pack.sqlite がある場合は
/// スキップする（§12: 同梱 / ローカル）。
class BundledPackInstaller {
  BundledPackInstaller._();

  /// 同梱対象の region キー（build 時に assets/packs/ へ配置される）。
  static const bundledRegions = ['tokyo'];

  static String assetPathFor(String regionKey) =>
      'assets/packs/$regionKey/pack.sqlite';

  /// 同梱パックを [packsRoot] へ展開する。asset 不在時は静かにスキップ。
  static Future<void> ensureInstalled(
    Directory packsRoot, {
    AssetBundle? bundle,
  }) async {
    final assetBundle = bundle ?? rootBundle;
    await packsRoot.create(recursive: true);

    for (final region in bundledRegions) {
      final destFile = File(p.join(packsRoot.path, region, 'pack.sqlite'));
      if (await destFile.exists()) continue;

      final assetPath = assetPathFor(region);
      ByteData data;
      try {
        data = await assetBundle.load(assetPath);
      } on Object {
        continue;
      }

      await destFile.parent.create(recursive: true);
      await destFile.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }
  }
}
