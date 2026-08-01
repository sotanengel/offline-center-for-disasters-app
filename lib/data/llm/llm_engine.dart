/// §14.4 / §7 LEAP 推論エンジンの抽象化（P5 で実装差し替え）。
abstract interface class LlmEngine {
  /// 利用可能か（モデル DL 済み・ティア適合等）。
  Future<bool> isAvailable();

  /// スロット抽出（AI-2）。スタブは常に未対応。
  Future<String?> analyzeText(String input) async => null;
}

/// モデル選択（§7.1）。
enum LlmModelChoice { auto, lfm25_1200jp, lfm25_350m, lfm25_230m, off }
