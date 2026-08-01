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

/// 初版: ローカルに存在するパックのみ列挙（DL は未実装で Err）。
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
