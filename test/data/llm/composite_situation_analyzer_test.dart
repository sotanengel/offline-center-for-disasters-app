import 'package:offline_center_for_disasters/data/llm/ai_situation_analyzer.dart';
import 'package:offline_center_for_disasters/data/llm/composite_situation_analyzer.dart';
import 'package:offline_center_for_disasters/data/llm/fake_llm_engine.dart';
import 'package:offline_center_for_disasters/data/rule/rule_situation_analyzer.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/situation_slots.dart';
import 'package:offline_center_for_disasters/core/result/result.dart';
import 'package:offline_center_for_disasters/data/llm/llm_errors.dart';
import 'package:offline_center_for_disasters/domain/services/situation_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Composite: LLM 成功時は AI スロット', () async {
    const slots = SituationSlots(
      disasterType: DisasterType.tsunami,
      disasterTypeEvidence: '津波',
      source: SlotSource.ai,
    );
    final llm = FakeLlmEngine(slotsResult: const Ok(slots));
    final composite = CompositeSituationAnalyzer(
      llm: AiSituationAnalyzer(llm),
      rule: _AlwaysFailRule(),
    );
    final r = await composite.analyze('津波');
    expect((r as Ok).value.source, SlotSource.ai);
  });

  test('Composite: LLM 失敗時は Rule にフォールバック', () async {
    final llm = FakeLlmEngine(
      available: true,
      slotsResult: const Err(LlmError.timeout),
    );
    final rule = await RuleSituationAnalyzer.create();
    final composite = CompositeSituationAnalyzer(
      llm: AiSituationAnalyzer(llm),
      rule: rule,
    );
    final r = await composite.analyze('つなみが来る');
    expect(r, isA<Ok>());
    expect((r as Ok).value.source, SlotSource.rule);
  });
}

class _AlwaysFailRule implements SituationAnalyzer {
  @override
  Future<Result<SituationSlots, SituationAnalyzerError>> analyze(
    String rawInput,
  ) async {
    return const Err(SituationAnalyzerError.unavailable);
  }
}
