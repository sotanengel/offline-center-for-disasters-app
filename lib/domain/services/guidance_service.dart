import '../../core/result/result.dart';
import '../entities/enums.dart';
import '../entities/guide_card.dart';
import '../entities/situation_slots.dart';

/// ガイド検索のエラー種別（§12 縮退で「一般原則 4 カードのみ」に落ちる判定に使う）。
enum GuidanceServiceError { kbMissing, kbCorrupted, unavailable }

/// §11.1 監修済み KB からのガイド検索（決定論。AI-3/AI-4 は対象外）。
///
/// この PR ではインタフェースのみ。KB とスコアラの実装は PR-8（#10）。
abstract interface class GuidanceService {
  /// [slots] と [type] に合致するガイドカードを [limit] 件以下で返す。
  /// KB 破損時は §3.6 の一般原則 4 カードで縮退することを実装が保証すること。
  Future<Result<List<GuideCard>, GuidanceServiceError>> search({
    required SituationSlots slots,
    required DisasterType type,
    int limit,
  });
}
