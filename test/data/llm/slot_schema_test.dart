import 'package:flutter_test/flutter_test.dart';

import 'package:offline_center_for_disasters/data/llm/schemas/slot_schema.dart';

void main() {
  test('§8.1 guide_tags 語彙が定義されている', () {
    expect(SlotSchema.allowedGuideTags, contains('tsunami_evacuation'));
    expect(SlotSchema.allowedGuideTags.length, greaterThanOrEqualTo(10));
  });

  test('jsonInstruction に intent と urgency が含まれる', () {
    expect(SlotSchema.jsonInstruction, contains('"intent"'));
    expect(SlotSchema.jsonInstruction, contains('"urgency"'));
    expect(SlotSchema.jsonInstruction, contains('disaster_type_evidence'));
  });
}
