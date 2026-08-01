import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offline_center_for_disasters/app/providers.dart';
import 'package:offline_center_for_disasters/core/result/result.dart';
import 'package:offline_center_for_disasters/data/llm/fake_llm_engine.dart';
import 'package:offline_center_for_disasters/data/llm/leap_stub_engine.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/situation_slots.dart';
import 'package:offline_center_for_disasters/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('自由文解析ボタンが表示される', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          llmEngineProvider.overrideWithValue(LeapStubEngine()),
        ],
        child: const app.OfflineCenterApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('analyze_free_text_button')),
    );
    expect(find.byKey(const Key('analyze_free_text_button')), findsOneWidget);
  });

  testWidgets('LLM モックで津波スロットが結果画面に反映される', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          llmEngineProvider.overrideWithValue(fake),
        ],
        child: const app.OfflineCenterApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('free_text_input')), '津波が来る');
    await tester.ensureVisible(
      find.byKey(const Key('analyze_free_text_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('analyze_free_text_button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('津波'), findsWidgets);
  });
}
