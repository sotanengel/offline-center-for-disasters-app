import 'dart:convert';

import '../../core/result/result.dart';
import '../../domain/entities/assistant_chat.dart';
import 'llm_errors.dart';

/// AI-7 JSON パーサ。
class AssistantJsonParser {
  const AssistantJsonParser();

  Result<AssistantSearchRequest, LlmError> parseSearchPlan(String raw) {
    try {
      final map = jsonDecode(_extractJson(raw)) as Map<String, dynamic>;
      final tool = map['tool'] as String?;
      if (tool != 'search_assistant_kb') {
        return const Err(LlmError.parseFailed);
      }
      final query = (map['query'] as String?)?.trim() ?? '';
      if (query.isEmpty) return const Err(LlmError.parseFailed);
      final category = map['category'];
      return Ok(
        AssistantSearchRequest(
          query: query,
          category: category is String && category.isNotEmpty ? category : null,
        ),
      );
    } catch (_) {
      return const Err(LlmError.parseFailed);
    }
  }

  Result<AssistantAnswer, LlmError> parseAnswer(String raw) {
    try {
      final map = jsonDecode(_extractJson(raw)) as Map<String, dynamic>;
      final answer = (map['answer'] as String?)?.trim() ?? '';
      if (answer.isEmpty) return const Err(LlmError.parseFailed);
      final cited = (map['citedChunkIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
      if (cited.isEmpty) return const Err(LlmError.parseFailed);
      final confidence = (map['confidence'] as String?) ?? 'high';
      return Ok(
        AssistantAnswer(
          answer: answer,
          citedChunkIds: cited,
          confidence: confidence,
        ),
      );
    } catch (_) {
      return const Err(LlmError.parseFailed);
    }
  }

  String _extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) throw FormatException('no json');
    return raw.substring(start, end + 1);
  }
}
