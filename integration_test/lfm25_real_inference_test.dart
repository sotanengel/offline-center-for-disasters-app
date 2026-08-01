@Tags(['real_llm'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offline_center_for_disasters/app/providers.dart';
import 'package:offline_center_for_disasters/data/llm/ai_situation_analyzer.dart';
import 'package:offline_center_for_disasters/data/llm/composite_situation_analyzer.dart';
import 'package:offline_center_for_disasters/data/llm/llm_errors.dart';
import 'package:offline_center_for_disasters/data/rule/rule_situation_analyzer.dart';
import 'package:offline_center_for_disasters/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/real_llm_assertions.dart';
import '../test/helpers/real_llm_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  RealLlmHarness? harness;
  String? skipReason;
  var modelDownloaded = false;

  setUpAll(() async {
    if (!RealLlmHarness.supportedPlatform) {
      skipReason = 'iOS のみ（liquid_ai）';
      return;
    }
    harness = await RealLlmHarness.tryCreate(useMockPrefs: false);
    if (harness == null) {
      skipReason = 'RealLlmHarness を作成できません';
      return;
    }

    modelDownloaded = await harness!.ensureModelDownloaded();
    if (!modelDownloaded) {
      skipReason =
          'LFM2-350M の DL に失敗: ${harness!.downloader.lastFailureDetail ?? 'unknown'}';
      return;
    }

    final ready = await harness!.ensureModelReady();
    if (!ready) {
      if (harness!.isSimulatorMemoryBlocked) {
        skipReason = 'シミュレータでは Leap SDK のメモリチェック不可（実機で extractSlots を実行）';
        return;
      }
      skipReason =
          'LFM2-350M のロードに失敗: ${harness!.lastError ?? LlmError.modelNotLoaded}'
          '${harness!.lastFailureDetail != null ? ' (${harness!.lastFailureDetail})' : ''}';
      harness = null;
    }
  });

  tearDownAll(() async {
    await harness?.dispose();
  });

  test('LFM2-350M モデルをダウンロードできる', () {
    if (skipReason != null && !modelDownloaded) {
      fail(skipReason!);
    }
    expect(modelDownloaded, isTrue);
  });

  test('LeapLlmEngine 実推論 extractSlots smoke', () async {
    if (skipReason != null || harness == null) {
      // ignore: avoid_print
      print('SKIP: ${skipReason ?? 'harness null'}');
      return;
    }
    await runLeapLlmEngineSmokeTests(harness!.engine);
  });

  testWidgets('自由文 → LFM2.5 実推論 → 津波スロットが結果画面に反映', (tester) async {
    if (skipReason != null || harness == null) {
      // ignore: avoid_print
      print('SKIP: ${skipReason ?? 'harness null'}');
      return;
    }

    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final prefs = await SharedPreferences.getInstance();
    final engine = harness!.engine;
    final analyzer = CompositeSituationAnalyzer(
      llm: AiSituationAnalyzer(engine),
      rule: await RuleSituationAnalyzer.create(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          llmEngineProvider.overrideWithValue(engine),
          situationAnalyzerProvider.overrideWithValue(analyzer),
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

    final deadline = DateTime.now().add(const Duration(seconds: 90));
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.textContaining('津波').evaluate().length >= 2) break;
      if (find.byKey(const Key('destination_summary')).evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.textContaining('津波'), findsWidgets);
  });
}
