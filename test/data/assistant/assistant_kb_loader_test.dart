import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/data/assistant/assistant_kb_loader.dart';

void main() {
  test('assistant KB は50件以上のチャンクを読み込める', () {
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
    expect(bundle.chunks.length, greaterThanOrEqualTo(50));
    expect(bundle.sources.length, 8);
    expect(bundle.categories.length, 5);
    expect(bundle.chunks.first.content.isNotEmpty, isTrue);
  });
}
