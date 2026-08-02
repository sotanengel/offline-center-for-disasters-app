import '../../core/result/result.dart';
import '../../domain/entities/assistant_chat.dart';
import '../../domain/entities/guide_card.dart';
import '../../domain/entities/situation_slots.dart';
import 'llm_engine.dart';
import 'llm_errors.dart';

/// LEAP SDK スタブ（SDK 非対応環境・テスト用）。
class LeapStubEngine implements LlmEngine {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<Result<SituationSlots, LlmError>> extractSlots(String input) async {
    return const Err(LlmError.unavailable);
  }

  @override
  Future<Result<List<String>, LlmError>> rerankGuideIds({
    required List<String> candidateIds,
    required SituationSlots ctx,
  }) async {
    return const Err(LlmError.unavailable);
  }

  @override
  Future<Result<String, LlmError>> generatePhrase({
    required GuideCard card,
    required SituationSlots ctx,
  }) async {
    return const Err(LlmError.unavailable);
  }

  @override
  Future<Result<AssistantSearchRequest, LlmError>> planAssistantSearch({
    required String userMessage,
    required List<ChatTurn> history,
  }) async {
    return const Err(LlmError.unavailable);
  }

  @override
  Future<Result<AssistantAnswer, LlmError>> generateAssistantAnswer({
    required String userMessage,
    required List<AssistantChunk> chunks,
  }) async {
    return const Err(LlmError.unavailable);
  }

  @override
  Future<void> unload() async {}
}
