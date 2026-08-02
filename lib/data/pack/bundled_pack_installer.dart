import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// アプリ同梱（assets/packs）の統合パックを Application Support へ展開する。
///
/// 初回起動時のみコピーし、既に [packsRoot]/bundled/pack.sqlite がある場合は
/// スキップする（§12: 同梱 / ローカル）。
class BundledPackInstaller {
  BundledPackInstaller._();

  /// 同梱統合パックの region キー（都道府県名ではない）。
  static const bundledPackKey = 'bundled';

  /// 同梱対象（build 時に assets/packs/bundled/ へ配置）。
  static const bundledRegions = [bundledPackKey];

  /// 旧バージョンで同梱・導入していたキー（マイグレーション用）。
  static const legacyBundledRegions = ['tokyo', 'kanto'];

  static String assetPathFor(String regionKey) =>
      'assets/packs/$regionKey/pack.sqlite';

  static String packPathFor(Directory packsRoot, [String? regionKey]) =>
      p.join(packsRoot.path, regionKey ?? bundledPackKey, 'pack.sqlite');

  /// 同梱パックを [packsRoot] へ展開する。asset 不在時は静かにスキップ。
  ///
  /// 旧単県パックのみ導入済みの端末は、統合 bundled 導入後に legacy を削除する。
  static Future<void> ensureInstalled(
    Directory packsRoot, {
    AssetBundle? bundle,
  }) async {
    final assetBundle = bundle ?? rootBundle;
    await packsRoot.create(recursive: true);

    for (final region in bundledRegions) {
      final destFile = File(packPathFor(packsRoot, region));
      if (await destFile.exists()) {
        await _removeLegacyPacksIfNeeded(packsRoot);
        continue;
      }

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
      await _removeLegacyPacksIfNeeded(packsRoot);
    }
  }

  static Future<void> _removeLegacyPacksIfNeeded(Directory packsRoot) async {
    for (final legacy in legacyBundledRegions) {
      final legacyDir = Directory(p.join(packsRoot.path, legacy));
      if (await legacyDir.exists()) {
        await legacyDir.delete(recursive: true);
      }
    }
  }
}
