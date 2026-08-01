import '../../core/result/result.dart';
import '../entities/situation_slots.dart';

/// スロット抽出のエラー種別（§12 縮退の判定に使う）。
///
/// - [SituationAnalyzerError.empty]: 入力が空/空白のみ。
/// - [SituationAnalyzerError.dictionaryMissing]: 辞書が読めない / 破損。
/// - [SituationAnalyzerError.unavailable]: その他一時的な失敗。
enum SituationAnalyzerError { empty, dictionaryMissing, unavailable }

/// §8 スロット抽出（§8.3 の disaster_type / evidence 保持を実装が満たすこと）。
///
/// AI-2（LLM）実装と Rule ベース実装の共通インタフェース。
/// この PR ではインタフェースのみ定義し、Rule 実装は PR-9、AI 実装は PR-10 で行う。
abstract interface class SituationAnalyzer {
  Future<Result<SituationSlots, SituationAnalyzerError>> analyze(
    String rawInput,
  );
}
