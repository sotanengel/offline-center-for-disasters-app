import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/result/result.dart';
import 'package:offline_center_for_disasters/data/assistant/assistant_kb_loader.dart';
import 'package:offline_center_for_disasters/data/assistant/assistant_kb_search.dart';
import 'package:offline_center_for_disasters/data/assistant/assistant_search_tool.dart';
import 'package:offline_center_for_disasters/data/llm/fake_llm_engine.dart';
import 'package:offline_center_for_disasters/data/llm/llm_errors.dart';
import 'package:offline_center_for_disasters/domain/entities/assistant_chat.dart';
import 'package:offline_center_for_disasters/domain/usecases/assistant_chat_usecase.dart';

void main() {
  late AssistantChatUseCase useCase;
  late FakeLlmEngine llm;
  late AssistantSearchTool searchTool;

  setUp(() {
    final chunksRaw = File(
      'assets/kb/assistant/chunks.json',
    ).readAsStringSync();
    final sourcesRaw = File(
      'assets/kb/assistant/sources.json',
    ).readAsStringSync();
    final bundle = AssistantKbLoader.loadFromJson(
      chunksJson: jsonDecode(chunksRaw) as Map<String, dynamic>,
      sourcesJson: jsonDecode(sourcesRaw) as Map<String, dynamic>,
    );
    searchTool = AssistantSearchTool(AssistantKbSearch.fromBundle(bundle));
    llm = FakeLlmEngine(available: true);
    useCase = AssistantChatUseCase(llm: llm, searchTool: searchTool);
  });

  test('必ず検索を実行してから回答する', () async {
    final result = await useCase.ask(userMessage: '止血の方法を教えて');
    expect(result, isA<AssistantChatAnswer>());
    final answer = result as AssistantChatAnswer;
    expect(answer.searchExecuted, isTrue);
    expect(answer.chunks, isNotEmpty);
    expect(llm.searchPlanCallCount, 1);
    expect(llm.assistantAnswerCallCount, 1);
  });

  test('該当なしのとき NoResults', () async {
    useCase = AssistantChatUseCase(llm: llm, searchTool: _EmptySearchTool());
    final result = await useCase.ask(userMessage: '止血の方法');
    expect(result, isA<AssistantChatNoResults>());
    expect((result as AssistantChatNoResults).searchExecuted, isTrue);
  });

  test('LLM 不可時は Degraded でチャンク提示', () async {
    llm.available = false;
    final result = await useCase.ask(userMessage: '止血の方法を教えて');
    expect(result, isA<AssistantChatDegraded>());
    expect((result as AssistantChatDegraded).searchExecuted, isTrue);
    expect(result.chunks, isNotEmpty);
  });

  test('guard 不合格時は Degraded', () async {
    llm.assistantAnswerResult = Ok(
      AssistantAnswer(answer: '必ず助かります。', citedChunkIds: ['invalid']),
    );
    final result = await useCase.ask(userMessage: '止血の方法を教えて');
    expect(result, isA<AssistantChatDegraded>());
  });

  test('LLM 回答失敗時は Degraded', () async {
    llm.assistantAnswerResult = const Err(LlmError.parseFailed);
    final result = await useCase.ask(userMessage: '止血の方法を教えて');
    expect(result, isA<AssistantChatDegraded>());
  });
}

class _EmptySearchTool extends AssistantSearchTool {
  _EmptySearchTool()
    : super(
        AssistantKbSearch.fromBundle(
          AssistantKbLoader.loadFromJson(
            chunksJson: const {'version': '1.0', 'chunks': []},
            sourcesJson: const {
              'version': '1.0',
              'categories': [],
              'sources': [],
            },
          ),
        ),
      );

  @override
  List<AssistantChunk> searchAssistantKb(
    AssistantSearchRequest request, {
    int limit = 5,
  }) => [];
}
