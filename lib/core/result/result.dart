/// 各層のエラーハンドリング用 Result 型（§12 フォールバック設計の基盤）。
///
/// 例外を跨がず、呼び出し側で劣化動作を選択できるようにする。
sealed class Result<T, E> {
  const Result();
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
