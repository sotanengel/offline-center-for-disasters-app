import '../../domain/entities/assistant_chat.dart';
import 'assistant_kb_search.dart';

/// LLM から呼び出される KB 検索ツール。
class AssistantSearchTool {
  const AssistantSearchTool(this._search);

  final AssistantKbSearch _search;

  /// `search_assistant_kb` ツール相当。
  List<AssistantChunk> searchAssistantKb(
    AssistantSearchRequest request, {
    int limit = 5,
  }) {
    final q = request.query.trim();
    if (q.isEmpty) return [];
    return _search.search(q, category: request.category, limit: limit);
  }
}
