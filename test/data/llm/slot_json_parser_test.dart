import 'package:flutter_test/flutter_test.dart';

import 'package:offline_center_for_disasters/core/result/result.dart';
import 'package:offline_center_for_disasters/data/llm/llm_errors.dart';
import 'package:offline_center_for_disasters/data/llm/slot_json_parser.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';

void main() {
  const parser = SlotJsonParser();

  test('津波入力をパースする', () {
    const raw = '''
{"intent":"route","disaster_type":"tsunami","disaster_type_evidence":"津波","urgency":"immediate","guide_tags":["tsunami_evacuation"]}
''';
    final r = parser.parse(raw);
    expect(r, isA<Ok>());
    final slots = (r as Ok).value;
    expect(slots.disasterType, DisasterType.tsunami);
    expect(slots.disasterTypeEvidence, '津波');
    expect(slots.intent, Intent.route);
    expect(slots.source, SlotSource.ai);
  });

  test('不正 JSON は parseFailed', () {
    final r = parser.parse('not json');
    expect(r, isA<Err>());
    expect((r as Err).error, LlmError.parseFailed);
  });

  test('リランキング ID パース', () {
    final ids = parseRerankIds('{"ids":["G-1","G-2","G-X"]}', [
      'G-1',
      'G-2',
      'G-3',
    ]);
    expect(ids, ['G-1', 'G-2']);
  });
}
