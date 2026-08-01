import '../../core/result/result.dart';
import '../../domain/entities/situation_slots.dart';
import '../../domain/services/situation_analyzer.dart';

/// §12: LLM → Rule フォールバック合成。
class CompositeSituationAnalyzer implements SituationAnalyzer {
  CompositeSituationAnalyzer({
    required SituationAnalyzer llm,
    required SituationAnalyzer rule,
  }) : _llm = llm,
       _rule = rule;

  final SituationAnalyzer _llm;
  final SituationAnalyzer _rule;

  @override
  Future<Result<SituationSlots, SituationAnalyzerError>> analyze(
    String rawInput,
  ) async {
    final text = rawInput.trim();
    if (text.isEmpty) {
      return const Err(SituationAnalyzerError.empty);
    }

    final llmResult = await _llm.analyze(text);
    if (llmResult is Ok<SituationSlots, SituationAnalyzerError>) {
      return llmResult;
    }
    return _rule.analyze(text);
  }
}
