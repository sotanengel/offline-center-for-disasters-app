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
import 'package:offline_center_for_disasters/domain/usecases/assistant_chat_usecase.dart';
import 'package:offline_center_for_disasters/ui/assistant/assistant_screen.dart';
import 'package:offline_center_for_disasters/ui/assistant/widgets/chat_message_bubble.dart';

AssistantKbBundle _loadBundle() {
  return AssistantKbLoader.loadFromJson(
    chunksJson:
        jsonDecode(File('assets/kb/assistant/chunks.json').readAsStringSync())
            as Map<String, dynamic>,
    sourcesJson:
        jsonDecode(File('assets/kb/assistant/sources.json').readAsStringSync())
            as Map<String, dynamic>,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('質問送信で回答または資料が表示される', (tester) async {
    final bundle = _loadBundle();
    final fakeLlm = FakeLlmEngine(available: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assistantKbBundleProvider.overrideWith((ref) async => bundle),
          assistantKbSearchProvider.overrideWith(
            (ref) async => AssistantKbSearch.fromBundle(bundle),
          ),
          assistantSearchToolProvider.overrideWith(
            (ref) async =>
                AssistantSearchTool(AssistantKbSearch.fromBundle(bundle)),
          ),
          assistantChatUseCaseProvider.overrideWith(
            (ref) async => AssistantChatUseCase(
              llm: fakeLlm,
              searchTool: AssistantSearchTool(
                AssistantKbSearch.fromBundle(bundle),
              ),
            ),
          ),
          llmEngineProvider.overrideWithValue(fakeLlm),
        ],
        child: const MaterialApp(home: AssistantScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('assistant_input')), '止血の方法');
    await tester.tap(find.byKey(const Key('assistant_send')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.byType(ChatMessageBubble), findsWidgets);
    expect(fakeLlm.searchPlanCallCount, greaterThanOrEqualTo(1));
  });

  testWidgets('資料を見るでブラウザ画面へ遷移', (tester) async {
    final bundle = _loadBundle();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assistantKbBundleProvider.overrideWith((ref) async => bundle),
        ],
        child: const MaterialApp(home: AssistantScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_knowledge_browser')));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('資料一覧'), findsOneWidget);
  });
}
