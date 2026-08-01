import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/result/result.dart';

/// 地域データパックの取得元（§12 / Issue #12: 初版は assets / ローカル）。
abstract interface class PackSource {
  Future<Result<List<String>, PackSourceError>> listInstalledRegions();
  Future<Result<void, PackSourceError>> deleteRegion(String regionKey);
  Future<Result<void, PackSourceError>> downloadRegion(
    String regionKey, {
    void Function(double progress)? onProgress,
  });
}

enum PackSourceError {
  notFound,
  insufficientStorage,
  networkUnavailable,
  unavailable,
}

/// テスト用: 固定の地域セットを返す。
class LocalPackSource implements PackSource {
  LocalPackSource(this._existingRegions);
  final Set<String> _existingRegions;

  @override
  Future<Result<List<String>, PackSourceError>> listInstalledRegions() async {
    return Ok(_existingRegions.toList()..sort());
  }

  @override
  Future<Result<void, PackSourceError>> deleteRegion(String regionKey) async {
    if (!_existingRegions.contains(regionKey)) {
      return const Err(PackSourceError.notFound);
    }
    _existingRegions.remove(regionKey);
    return const Ok(null);
  }

  @override
  Future<Result<void, PackSourceError>> downloadRegion(
    String regionKey, {
    void Function(double progress)? onProgress,
  }) async {
    return const Err(PackSourceError.networkUnavailable);
  }
}

/// Application Support/packs/*/pack.sqlite を列挙する実装。
class FilesystemPackSource implements PackSource {
  FilesystemPackSource(this.packsRoot);

  final Directory packsRoot;

  @override
  Future<Result<List<String>, PackSourceError>> listInstalledRegions() async {
    try {
      if (!await packsRoot.exists()) {
        return const Ok([]);
      }
      final regions = <String>[];
      await for (final entity in packsRoot.list()) {
        if (entity is! Directory) continue;
        final packFile = File(p.join(entity.path, 'pack.sqlite'));
        if (await packFile.exists()) {
          regions.add(p.basename(entity.path));
        }
      }
      regions.sort();
      return Ok(regions);
    } on Object {
      return const Err(PackSourceError.unavailable);
    }
  }

  @override
  Future<Result<void, PackSourceError>> deleteRegion(String regionKey) async {
    final dir = Directory(p.join(packsRoot.path, regionKey));
    if (!await dir.exists()) {
      return const Err(PackSourceError.notFound);
    }
    try {
      await dir.delete(recursive: true);
      return const Ok(null);
    } on Object {
      return const Err(PackSourceError.unavailable);
    }
  }

  @override
  Future<Result<void, PackSourceError>> downloadRegion(
    String regionKey, {
    void Function(double progress)? onProgress,
  }) async {
    return const Err(PackSourceError.networkUnavailable);
  }
}
