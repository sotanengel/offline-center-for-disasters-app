/// アシスタント KB の検索チャンク。
class AssistantChunk {
  const AssistantChunk({
    required this.id,
    required this.sourceId,
    required this.title,
    required this.category,
    required this.tags,
    required this.content,
    this.pageRef,
  });

  final String id;
  final String sourceId;
  final String title;
  final String category;
  final List<String> tags;
  final String content;
  final String? pageRef;

  String get searchText => '$title $content ${tags.join(' ')}';
}

/// アシスタント KB 出典メタデータ。
class AssistantSource {
  const AssistantSource({
    required this.id,
    required this.title,
    required this.url,
    required this.category,
    required this.publisher,
  });

  final String id;
  final String title;
  final String url;
  final String category;
  final String publisher;
}

/// カテゴリ表示ラベル。
class AssistantCategory {
  const AssistantCategory({required this.id, required this.label});

  final String id;
  final String label;
}

/// チャット履歴 1 ターン。
class ChatTurn {
  const ChatTurn({required this.role, required this.text});

  final String role;
  final String text;
}

/// AI-7a: KB 検索ツール呼び出し。
class AssistantSearchRequest {
  const AssistantSearchRequest({required this.query, this.category});

  final String query;
  final String? category;
}

/// AI-7b: アシスタント回答。
class AssistantAnswer {
  const AssistantAnswer({
    required this.answer,
    required this.citedChunkIds,
    this.confidence = 'high',
  });

  final String answer;
  final List<String> citedChunkIds;
  final String confidence;
}

/// ユースケース結果。
sealed class AssistantChatResult {
  const AssistantChatResult();
}

class AssistantChatAnswer extends AssistantChatResult {
  const AssistantChatAnswer({
    required this.answer,
    required this.chunks,
    required this.searchExecuted,
    this.llmGenerated = true,
  });

  final String answer;
  final List<AssistantChunk> chunks;
  final bool searchExecuted;
  final bool llmGenerated;
}

class AssistantChatNoResults extends AssistantChatResult {
  const AssistantChatNoResults({required this.searchExecuted});

  final bool searchExecuted;
}

class AssistantChatDegraded extends AssistantChatResult {
  const AssistantChatDegraded({
    required this.chunks,
    required this.searchExecuted,
  });

  final List<AssistantChunk> chunks;
  final bool searchExecuted;
}
