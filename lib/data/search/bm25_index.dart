import 'dart:math';

/// 日本語 bi-gram トークナイズ + BM25 スコアリング（§11.1 決定論部分）。
class Bm25Index {
  Bm25Index._(this._docs, this._avgLen, this._df, this._docLens);

  final List<_Doc> _docs;
  final double _avgLen;
  final Map<String, int> _df;
  final List<int> _docLens;

  static const _k1 = 1.2;
  static const _b = 0.75;

  factory Bm25Index.fromTexts(
    List<({String id, String text, List<String> tags})> items,
  ) {
    final docs = <_Doc>[];
    final df = <String, int>{};
    var totalLen = 0;
    for (final item in items) {
      final tokens = _tokenize(item.text);
      totalLen += tokens.length;
      for (final t in tokens.toSet()) {
        df[t] = (df[t] ?? 0) + 1;
      }
      docs.add(_Doc(id: item.id, tokens: tokens, tags: item.tags));
    }
    final avg = docs.isEmpty ? 0.0 : totalLen / docs.length;
    return Bm25Index._(
      docs,
      avg,
      df,
      docs.map((d) => d.tokens.length).toList(),
    );
  }

  /// クエリ文字列とタグ完全一致を組み合わせてスコア降順の doc id を返す。
  List<String> search(
    String query, {
    List<String> tagFilter = const [],
    int limit = 10,
  }) {
    final qTokens = _tokenize(query);
    final n = _docs.length;
    if (n == 0) return [];

    final scores = <String, double>{};
    for (var i = 0; i < n; i++) {
      final doc = _docs[i];
      if (tagFilter.isNotEmpty && !tagFilter.any(doc.tags.contains)) {
        continue;
      }
      var score = 0.0;
      for (final term in qTokens) {
        final df = _df[term] ?? 0;
        if (df == 0) continue;
        final tf = doc.tokens.where((t) => t == term).length;
        if (tf == 0) continue;
        final idf = log((n - df + 0.5) / (df + 0.5) + 1);
        final len = _docLens[i];
        final denom =
            tf + _k1 * (1 - _b + _b * len / (_avgLen == 0 ? 1 : _avgLen));
        score += idf * (tf * (_k1 + 1)) / denom;
      }
      // タグ完全一致ボーナス
      for (final tag in tagFilter) {
        if (doc.tags.contains(tag)) score += 2.0;
      }
      if (score > 0) scores[doc.id] = score;
    }
    final ids = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));
    return ids.take(limit).toList();
  }

  static List<String> _tokenize(String text) {
    final normalized = text.toLowerCase();
    final grams = <String>{};
    for (var i = 0; i < normalized.length - 1; i++) {
      grams.add(normalized.substring(i, i + 2));
    }
    if (normalized.isNotEmpty) grams.add(normalized);
    return grams.toList();
  }
}

class _Doc {
  _Doc({required this.id, required this.tokens, required this.tags});
  final String id;
  final List<String> tokens;
  final List<String> tags;
}
