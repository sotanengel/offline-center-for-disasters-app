import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offline_center_for_disasters/app/providers.dart';
import 'package:offline_center_for_disasters/core/result/result.dart';
import 'package:offline_center_for_disasters/data/llm/ai_situation_analyzer.dart';
import 'package:offline_center_for_disasters/data/llm/fake_llm_engine.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/situation_slots.dart';
import 'package:offline_center_for_disasters/domain/services/situation_analyzer.dart';
import 'package:offline_center_for_disasters/ui/result/result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/destination_plan_overrides.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LLM モックで津波スロットが結果画面に反映される', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fake = FakeLlmEngine(
      available: true,
      slotsResult: const Ok(
        SituationSlots(
          disasterType: DisasterType.tsunami,
          disasterTypeEvidence: '津波',
          source: SlotSource.ai,
        ),
      ),
    );
    final analyzer = AiSituationAnalyzer(fake);
    final result = await analyzer.analyze('津波が来る');
    expect(result, isA<Ok<SituationSlots, SituationAnalyzerError>>());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          llmEngineProvider.overrideWithValue(fake),
          situationAnalyzerProvider.overrideWithValue(analyzer),
          destinationPlanProviderOverride(),
        ],
        child: MaterialApp(home: ResultScreen(slots: (result as Ok).value)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('津波'), findsWidgets);
    expect(find.byKey(const Key('destination_summary')), findsOneWidget);
  });
}
