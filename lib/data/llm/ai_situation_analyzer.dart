import '../../core/result/result.dart';
import '../../domain/entities/situation_slots.dart';
import '../../domain/services/situation_analyzer.dart';
import 'llm_engine.dart';

/// AI-2: [LlmEngine.extractSlots] ラッパ。
class AiSituationAnalyzer implements SituationAnalyzer {
  AiSituationAnalyzer(this._engine);

  final LlmEngine _engine;

  @override
  Future<Result<SituationSlots, SituationAnalyzerError>> analyze(
    String rawInput,
  ) async {
    if (!await _engine.isAvailable()) {
      return const Err(SituationAnalyzerError.unavailable);
    }
    final result = await _engine.extractSlots(rawInput);
    return switch (result) {
      Ok(value: final slots) => Ok(slots),
      Err() => const Err(SituationAnalyzerError.unavailable),
    };
  }
}
