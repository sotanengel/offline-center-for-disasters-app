/// LLM 推論エラー（§12 フォールバック判定用）。
enum LlmError {
  /// モデル未 DL / ティア D / SDK 非対応
  unavailable,

  /// 推論タイムアウト（> 5 秒）
  timeout,

  /// JSON パース 2 回失敗
  parseFailed,

  /// モデルロード失敗
  modelNotLoaded,

  /// メモリ不足
  memoryInsufficient,
}
