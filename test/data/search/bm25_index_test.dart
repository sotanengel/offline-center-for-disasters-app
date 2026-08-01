import 'package:flutter_test/flutter_test.dart';

import 'package:offline_center_for_disasters/data/search/bm25_index.dart';

void main() {
  test('BM25 は同一クエリで決定的な順序を返す', () {
    final index = Bm25Index.fromTexts([
      (id: 'a', text: '津波 避難 高台', tags: ['tsunami']),
      (id: 'b', text: '地震 揺れ 机', tags: ['earthquake']),
      (id: 'c', text: '津波 海岸 離れる', tags: ['tsunami']),
    ]);
    final r1 = index.search('津波 避難', limit: 2);
    final r2 = index.search('津波 避難', limit: 2);
    expect(r1, r2);
    expect(r1, isNotEmpty);
    expect(r1.first, anyOf('a', 'c'));
  });
}
