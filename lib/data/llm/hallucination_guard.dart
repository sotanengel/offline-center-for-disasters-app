import '../../domain/entities/guide_card.dart';
import '../../domain/entities/situation_slots.dart';

/// §5.3 ハルシネーションガード（決定論検証）。
class HallucinationGuard {
  const HallucinationGuard();

  static final _numberPattern = RegExp(r'\d+');

  static final _unsafePhrases = ['必ず助かります', '安全です', '大丈夫です', '必ず安全'];

  /// 生成文が表示可能なら true。
  bool isAllowed({
    required String generated,
    required GuideCard card,
    required SituationSlots slots,
    Duration? generationTime,
  }) {
    if (generated.length > 80) return false;
    if (generationTime != null && generationTime.inSeconds > 3) return false;

    for (final phrase in _unsafePhrases) {
      if (generated.contains(phrase)) return false;
    }

    final cardText =
        '${card.title} ${card.steps.join(' ')} ${card.warning ?? ''}';
    for (final match in _numberPattern.allMatches(generated)) {
      if (!cardText.contains(match.group(0)!)) {
        final floor = slots.environment.floor;
        if (floor == null || !generated.contains('$floor')) {
          return false;
        }
      }
    }

    // 固有名詞: カードにない 3 文字以上の連続漢字/カタカナ塊を簡易検出
    final properNounPattern = RegExp(r'[\u4E00-\u9FFF\u30A0-\u30FF]{3,}');
    for (final match in properNounPattern.allMatches(generated)) {
      final word = match.group(0)!;
      if (!cardText.contains(word) && word != card.title) {
        return false;
      }
    }

    return true;
  }
}
