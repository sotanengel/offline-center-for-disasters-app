/// 各層のエラーハンドリング用 Result 型（§12 フォールバック設計の基盤）。
///
/// 例外を跨がず、呼び出し側で劣化動作を選択できるようにする。
sealed class Result<T, E> {
  const Result();

  /// 値変換（成功時のみ写像。失敗はそのまま伝播）。
  Result<U, E> map<U>(U Function(T value) f) => switch (this) {
    Ok(value: final v) => Ok<U, E>(f(v)),
    Err(error: final e) => Err<U, E>(e),
  };

  /// エラー変換（失敗時のみ写像。成功はそのまま伝播）。
  Result<T, F> mapErr<F>(F Function(E error) f) => switch (this) {
    Ok(value: final v) => Ok<T, F>(v),
    Err(error: final e) => Err<T, F>(f(e)),
  };

  /// 成功/失敗の分岐関数（両方の値を同一型 [R] に写像する）。
  R fold<R>({
    required R Function(T value) ok,
    required R Function(E error) err,
  }) => switch (this) {
    Ok(value: final v) => ok(v),
    Err(error: final e) => err(e),
  };

  bool get isOk => this is Ok<T, E>;

  bool get isErr => this is Err<T, E>;

  /// 成功時の値。失敗なら null（元が nullable な T の場合は区別できないため注意）。
  T? get valueOrNull => switch (this) {
    Ok(value: final v) => v,
    Err() => null,
  };
}

final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);
  final T value;
}

final class Err<T, E> extends Result<T, E> {
  const Err(this.error);
  final E error;
}

/// 処理を実行し、例外を [Err] に変換する（[onError] でエラー値へ写像）。
Future<Result<T, E>> guard<T, E>(
  Future<T> Function() body,
  E Function(Object error) onError,
) async {
  try {
    return Ok(await body());
  } catch (e) {
    return Err(onError(e));
  }
}
