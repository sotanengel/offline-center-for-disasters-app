import '../../core/result/result.dart';
import '../../domain/entities/assistant_chat.dart';
import '../../domain/entities/guide_card.dart';
import '../../domain/entities/situation_slots.dart';
import 'llm_engine.dart';
import 'llm_errors.dart';

/// テスト用 LLM エンジン（決定論的応答）。
class FakeLlmEngine implements LlmEngine {
  FakeLlmEngine({
    this.available = true,
    this.slotsResult,
    this.rerankResult,
    this.phraseResult,
    this.searchPlanResult,
    this.assistantAnswerResult,
    this.extractDelay = Duration.zero,
    this.shouldTimeout = false,
    this.parseFailCount = 0,
  });

  bool available;
  Result<SituationSlots, LlmError>? slotsResult;
  Result<List<String>, LlmError>? rerankResult;
  Result<String, LlmError>? phraseResult;
  Result<AssistantSearchRequest, LlmError>? searchPlanResult;
  Result<AssistantAnswer, LlmError>? assistantAnswerResult;
  Duration extractDelay;
  bool shouldTimeout;
  int parseFailCount;

  int extractCallCount = 0;
  int rerankCallCount = 0;
  int phraseCallCount = 0;
  int searchPlanCallCount = 0;
  int assistantAnswerCallCount = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<Result<SituationSlots, LlmError>> extractSlots(String input) async {
    extractCallCount++;
    if (shouldTimeout) {
      await Future<void>.delayed(const Duration(seconds: 6));
      return const Err(LlmError.timeout);
    }
    if (extractDelay > Duration.zero) {
      await Future<void>.delayed(extractDelay);
    }
    if (parseFailCount > 0) {
      parseFailCount--;
      return const Err(LlmError.parseFailed);
    }
    return slotsResult ?? const Err(LlmError.unavailable);
  }

  @override
  Future<Result<List<String>, LlmError>> rerankGuideIds({
    required List<String> candidateIds,
    required SituationSlots ctx,
  }) async {
    rerankCallCount++;
    return rerankResult ?? Ok(candidateIds.take(3).toList());
  }

  @override
  Future<Result<String, LlmError>> generatePhrase({
    required GuideCard card,
    required SituationSlots ctx,
  }) async {
    phraseCallCount++;
    return phraseResult ?? const Ok('状況に合わせて確認してください。');
  }

  @override
  Future<Result<AssistantSearchRequest, LlmError>> planAssistantSearch({
    required String userMessage,
    required List<ChatTurn> history,
  }) async {
    searchPlanCallCount++;
    return searchPlanResult ?? Ok(AssistantSearchRequest(query: userMessage));
  }

  @override
  Future<Result<AssistantAnswer, LlmError>> generateAssistantAnswer({
    required String userMessage,
    required List<AssistantChunk> chunks,
  }) async {
    assistantAnswerCallCount++;
    if (assistantAnswerResult != null) return assistantAnswerResult!;
    if (chunks.isEmpty) return const Err(LlmError.parseFailed);
    return Ok(
      AssistantAnswer(
        answer: '${chunks.first.title}に関する情報を確認してください。',
        citedChunkIds: [chunks.first.id],
      ),
    );
  }

  @override
  Future<void> unload() async {}
}
