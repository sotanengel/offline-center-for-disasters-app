import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/result/result.dart';
import 'package:offline_center_for_disasters/data/llm/assistant_json_parser.dart';
import 'package:offline_center_for_disasters/data/llm/llm_errors.dart';
import 'package:offline_center_for_disasters/domain/entities/assistant_chat.dart';

void main() {
  const parser = AssistantJsonParser();

  test('parseSearchPlan は tool call JSON を解釈する', () {
    const raw =
        '{"tool":"search_assistant_kb","query":"止血 方法","category":"first_aid"}';
    final result = parser.parseSearchPlan(raw);
    expect(result, isA<Ok<AssistantSearchRequest, LlmError>>());
    final req = (result as Ok<AssistantSearchRequest, LlmError>).value;
    expect(req.query, '止血 方法');
    expect(req.category, 'first_aid');
  });

  test('parseAnswer は citedChunkIds を必須とする', () {
    const raw =
        '{"answer":"直接圧迫を行ってください。","citedChunkIds":["fdma_oukyu_001"],"confidence":"high"}';
    final result = parser.parseAnswer(raw);
    expect(result, isA<Ok<AssistantAnswer, LlmError>>());
    expect((result as Ok<AssistantAnswer, LlmError>).value.citedChunkIds, [
      'fdma_oukyu_001',
    ]);
  });
}
