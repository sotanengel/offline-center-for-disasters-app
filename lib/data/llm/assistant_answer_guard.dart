import '../../domain/entities/assistant_chat.dart';

/// アシスタント回答のハルシネーションガード。
class AssistantAnswerGuard {
  const AssistantAnswerGuard();

  static final _numberPattern = RegExp(r'\d+');
  static final _unsafePhrases = ['必ず助かります', '安全です', '大丈夫です', '必ず安全', '100%'];

  bool isAllowed({
    required String answer,
    required List<AssistantChunk> chunks,
    required List<String> citedChunkIds,
  }) {
    if (answer.length > 400) return false;
    for (final phrase in _unsafePhrases) {
      if (answer.contains(phrase)) return false;
    }

    final cited = chunks
        .where((c) => citedChunkIds.contains(c.id))
        .toList(growable: false);
    if (cited.isEmpty) return false;

    final context = cited.map((c) => c.searchText).join(' ');
    for (final match in _numberPattern.allMatches(answer)) {
      if (!context.contains(match.group(0)!)) {
        return false;
      }
    }

    final properNounPattern = RegExp(r'[\u4E00-\u9FFF\u30A0-\u30FF]{3,}');
    for (final match in properNounPattern.allMatches(answer)) {
      final word = match.group(0)!;
      if (!context.contains(word)) {
        return false;
      }
    }
    return true;
  }
}
