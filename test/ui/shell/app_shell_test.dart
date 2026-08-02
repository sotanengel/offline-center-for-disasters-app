import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/app/providers.dart';
import 'package:offline_center_for_disasters/data/assistant/assistant_kb_loader.dart';
import 'package:offline_center_for_disasters/data/assistant/assistant_kb_search.dart';
import 'package:offline_center_for_disasters/data/assistant/assistant_search_tool.dart';
import 'package:offline_center_for_disasters/data/llm/fake_llm_engine.dart';
import 'package:offline_center_for_disasters/domain/entities/disaster_candidate.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/hazard_context.dart';
import 'package:offline_center_for_disasters/domain/usecases/assistant_chat_usecase.dart';
import 'package:offline_center_for_disasters/ui/shell/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

DisasterCandidate _cand(DisasterType type, int score) =>
    DisasterCandidate(type: type, score: score, context: const HazardContext());

Future<void> pumpAppShell(WidgetTester tester) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final bundle = AssistantKbLoader.loadFromJson(
    chunksJson:
        jsonDecode(File('assets/kb/assistant/chunks.json').readAsStringSync())
            as Map<String, dynamic>,
    sourcesJson:
        jsonDecode(File('assets/kb/assistant/sources.json').readAsStringSync())
            as Map<String, dynamic>,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        disasterCandidatesProvider.overrideWith(
          (ref) async => [
            _cand(DisasterType.earthquake, 30),
            _cand(DisasterType.fire, 20),
            _cand(DisasterType.tsunami, 0),
            _cand(DisasterType.flood, 0),
            _cand(DisasterType.landslide, 0),
            _cand(DisasterType.stormSurge, 0),
            _cand(DisasterType.volcano, 0),
          ],
        ),
        hazardContextProvider.overrideWith(
          (ref) async => const HazardContext(),
        ),
        recentSelectionProvider.overrideWith((ref) async => null),
        assistantKbBundleProvider.overrideWith((ref) async => bundle),
        assistantKbSearchProvider.overrideWith(
          (ref) async => AssistantKbSearch.fromBundle(bundle),
        ),
        assistantSearchToolProvider.overrideWith(
          (ref) async =>
              AssistantSearchTool(AssistantKbSearch.fromBundle(bundle)),
        ),
        llmEngineProvider.overrideWithValue(FakeLlmEngine(available: false)),
        assistantChatUseCaseProvider.overrideWith(
          (ref) async => AssistantChatUseCase(
            llm: FakeLlmEngine(available: false),
            searchTool: AssistantSearchTool(
              AssistantKbSearch.fromBundle(bundle),
            ),
          ),
        ),
      ],
      child: const MaterialApp(home: AppShell()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('AppShell はホームとアシスタントの2タブを表示する', (tester) async {
    await pumpAppShell(tester);

    expect(find.text('ホーム'), findsOneWidget);
    expect(find.text('災害対応アシスタント'), findsWidgets);
    expect(find.text('どの災害から逃げますか？'), findsOneWidget);
  });

  testWidgets('アシスタントタブに切り替えできる', (tester) async {
    await pumpAppShell(tester);

    await tester.tap(find.text('災害対応アシスタント').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('assistant_input')), findsOneWidget);
    expect(find.text('資料を見る'), findsOneWidget);
  });
}
