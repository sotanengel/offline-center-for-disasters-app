import '../../domain/entities/assistant_chat.dart';
import '../search/bm25_index.dart';
import 'assistant_kb_loader.dart';

/// アシスタント KB の BM25 検索。
class AssistantKbSearch {
  AssistantKbSearch._(this._index, this._byId);

  final Bm25Index _index;
  final Map<String, AssistantChunk> _byId;

  factory AssistantKbSearch.fromBundle(AssistantKbBundle bundle) {
    final byId = {for (final c in bundle.chunks) c.id: c};
    final index = Bm25Index.fromTexts([
      for (final c in bundle.chunks)
        (id: c.id, text: c.searchText, tags: c.tags),
    ]);
    return AssistantKbSearch._(index, byId);
  }

  List<AssistantChunk> search(
    String query, {
    String? category,
    int limit = 5,
    double minScore = 1.0,
  }) {
    final tagFilter = category == null ? const <String>[] : [category];
    final scored = _index.searchScored(
      query,
      tagFilter: tagFilter,
      limit: limit,
      minScore: minScore,
    );
    return [
      for (final hit in scored)
        if (_byId[hit.id] != null) _byId[hit.id]!,
    ];
  }

  List<AssistantChunk> allChunks({String? category}) {
    if (category == null) return _byId.values.toList();
    return _byId.values.where((c) => c.category == category).toList();
  }
}
