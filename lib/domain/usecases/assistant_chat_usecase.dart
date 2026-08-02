import '../../core/result/result.dart';
import '../../data/assistant/assistant_search_tool.dart';
import '../../data/llm/assistant_answer_guard.dart';
import '../../data/llm/llm_engine.dart';
import '../../domain/entities/assistant_chat.dart';

/// 災害対応アシスタントのチャットオーケストレーション。
class AssistantChatUseCase {
  AssistantChatUseCase({
    required LlmEngine llm,
    required AssistantSearchTool searchTool,
    AssistantAnswerGuard? guard,
  }) : _llm = llm,
       _searchTool = searchTool,
       _guard = guard ?? const AssistantAnswerGuard();

  final LlmEngine _llm;
  final AssistantSearchTool _searchTool;
  final AssistantAnswerGuard _guard;

  Future<AssistantChatResult> ask({
    required String userMessage,
    List<ChatTurn> history = const [],
  }) async {
    final trimmed = userMessage.trim();
    if (trimmed.isEmpty) {
      return const AssistantChatNoResults(searchExecuted: false);
    }

    var query = trimmed;
    String? category;
    if (await _llm.isAvailable()) {
      final plan = await _llm.planAssistantSearch(
        userMessage: trimmed,
        history: history,
      );
      if (plan case Ok(value: final req)) {
        query = req.query;
        category = req.category;
      }
    }

    final chunks = _searchTool.searchAssistantKb(
      AssistantSearchRequest(query: query, category: category),
    );
    if (chunks.isEmpty) {
      return const AssistantChatNoResults(searchExecuted: true);
    }

    if (!await _llm.isAvailable()) {
      return AssistantChatDegraded(
        chunks: chunks.take(3).toList(),
        searchExecuted: true,
      );
    }

    final answerResult = await _llm.generateAssistantAnswer(
      userMessage: trimmed,
      chunks: chunks,
    );
    if (answerResult case Ok(value: final ans)) {
      final cited = chunks
          .where((c) => ans.citedChunkIds.contains(c.id))
          .toList();
      final contextChunks = cited.isEmpty ? chunks.take(3).toList() : cited;
      if (_guard.isAllowed(
        answer: ans.answer,
        chunks: contextChunks,
        citedChunkIds: ans.citedChunkIds,
      )) {
        return AssistantChatAnswer(
          answer: ans.answer,
          chunks: contextChunks,
          searchExecuted: true,
        );
      }
    }

    return AssistantChatDegraded(
      chunks: chunks.take(3).toList(),
      searchExecuted: true,
    );
  }
}
