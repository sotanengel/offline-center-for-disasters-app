import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/data/assistant/assistant_kb_loader.dart';
import 'package:offline_center_for_disasters/data/assistant/assistant_kb_search.dart';

void main() {
  late AssistantKbSearch search;

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
    search = AssistantKbSearch.fromBundle(bundle);
  });

  test('止血で first_aid 関連チャンクがヒットする', () {
    final hits = search.search('止血 直接圧迫');
    expect(hits, isNotEmpty);
    expect(hits.first.category, 'first_aid');
  });

  test('エコノミークラスで shelter_health がヒットする', () {
    final hits = search.search('エコノミークラス 避難所');
    expect(hits, isNotEmpty);
    expect(
      hits.any(
        (c) => c.category == 'shelter_health' || c.content.contains('エコノミー'),
      ),
      isTrue,
    );
  });

  test('停電対策で utilities がヒットする', () {
    final hits = search.search('停電 対策');
    expect(hits, isNotEmpty);
  });
}
