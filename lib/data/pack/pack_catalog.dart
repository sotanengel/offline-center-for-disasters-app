import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/geo/geo_bounds.dart';
import '../../core/result/result.dart';
import 'pack_loader.dart';
import 'region_pack_info.dart';

/// 導入済みパックの region / bbox を読み取る。
class PackCatalog {
  /// [packsRoot]/[region]/pack.sqlite を開き、壊れているものはスキップする。
  static Future<List<RegionPackInfo>> scan(Directory packsRoot) async {
    if (!await packsRoot.exists()) return const [];
    final infos = <RegionPackInfo>[];
    await for (final entity in packsRoot.list()) {
      if (entity is! Directory) continue;
      final regionKey = p.basename(entity.path);
      final packPath = p.join(entity.path, 'pack.sqlite');
      if (!File(packPath).existsSync()) continue;
      final opened = await PackLoader.open(packPath);
      switch (opened) {
        case Ok(value: final pack):
          try {
            final bboxRaw = pack.metadata['bbox'];
            final bbox = bboxRaw == null
                ? null
                : GeoBounds.tryParseBboxJson(bboxRaw);
            final region = pack.metadata['region'] ?? regionKey;
            if (bbox != null) {
              infos.add(
                RegionPackInfo(regionKey: region, path: packPath, bbox: bbox),
              );
            }
          } finally {
            await pack.close();
          }
        case Err():
          break;
      }
    }
    infos.sort((a, b) => a.regionKey.compareTo(b.regionKey));
    return infos;
  }
}
