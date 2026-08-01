import '../../core/result/result.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/guide_card.dart';
import '../../domain/entities/situation_slots.dart';
import '../../domain/services/guidance_service.dart';
import '../search/bm25_index.dart';
import '../llm/guide_reranker.dart';
import 'kb_loader.dart';

/// §11.1 KB + BM25 による [GuidanceService] 実装（PR-8 / F-07）。
class KbGuidanceService implements GuidanceService {
  KbGuidanceService({
    required List<GuideCard> cards,
    required Bm25Index index,
    GuideReranker? reranker,
  }) : _cards = cards,
       _index = index,
       _reranker = reranker,
       _byId = {for (final c in cards) c.id: c};

  final List<GuideCard> _cards;
  final Bm25Index _index;
  final GuideReranker? _reranker;
  final Map<String, GuideCard> _byId;

  static Future<KbGuidanceService> create() async {
    final cards = await KbLoader.load();
    if (cards.isEmpty) {
      return _fallback();
    }
    final index = Bm25Index.fromTexts([
      for (final c in cards)
        (
          id: c.id,
          text: '${c.title} ${c.steps.join(' ')} ${c.tags.join(' ')}',
          tags: c.tags,
        ),
    ]);
    return KbGuidanceService(cards: cards, index: index);
  }

  static KbGuidanceService _fallback({GuideReranker? reranker}) {
    final cards = KbLoader.generalPrinciples();
    return KbGuidanceService(
      cards: cards,
      index: Bm25Index.fromTexts([]),
      reranker: reranker,
    );
  }

  @override
  Future<Result<List<GuideCard>, GuidanceServiceError>> search({
    required SituationSlots slots,
    required DisasterType type,
    int limit = 10,
  }) async {
    final query = [
      slots.disasterTypeEvidence,
      ...slots.guideTags,
      if (type != DisasterType.unknown) type.name,
    ].where((s) => s.isNotEmpty).join(' ');

    final ids = _index.search(
      query,
      tagFilter: slots.guideTags,
      limit: limit * 2,
    );

    final results = <GuideCard>[];
    for (final id in ids) {
      final card = _byId[id];
      if (card == null) continue;
      if (type != DisasterType.unknown &&
          card.disasterTypes.isNotEmpty &&
          !card.disasterTypes.contains(type)) {
        continue;
      }
      results.add(card);
      if (results.length >= limit) break;
    }

    if (results.isEmpty) {
      final filtered =
          _cards
              .where(
                (c) =>
                    type == DisasterType.unknown ||
                    c.disasterTypes.isEmpty ||
                    c.disasterTypes.contains(type),
              )
              .toList()
            ..sort((a, b) => a.priority.compareTo(b.priority));
      final fallback = filtered.take(limit).toList();
      return Ok(await _maybeRerank(fallback, slots));
    }
    return Ok(await _maybeRerank(results, slots));
  }

  Future<List<GuideCard>> _maybeRerank(
    List<GuideCard> cards,
    SituationSlots slots,
  ) async {
    final reranker = _reranker;
    if (reranker == null || cards.length <= 3) return cards;
    return reranker.rerank(candidates: cards, slots: slots);
  }

  List<GuideCard> generalPrinciplesOnly() => KbLoader.generalPrinciples();

  List<GuideCard> get allCards => List.unmodifiable(_cards);
}

/// KB 読込失敗時は一般原則 4 カードで縮退するローダ。
class KbGuidanceServiceLoader implements GuidanceService {
  KbGuidanceServiceLoader({GuideReranker? reranker}) : _reranker = reranker;

  final GuideReranker? _reranker;
  KbGuidanceService? _inner;

  Future<KbGuidanceService> _service() async {
    if (_inner != null) return _inner!;
    try {
      final cards = await KbLoader.load();
      if (cards.isEmpty) {
        _inner = KbGuidanceService._fallback(reranker: _reranker);
      } else {
        final index = Bm25Index.fromTexts([
          for (final c in cards)
            (
              id: c.id,
              text: '${c.title} ${c.steps.join(' ')} ${c.tags.join(' ')}',
              tags: c.tags,
            ),
        ]);
        _inner = KbGuidanceService(
          cards: cards,
          index: index,
          reranker: _reranker,
        );
      }
    } catch (_) {
      _inner = KbGuidanceService._fallback(reranker: _reranker);
    }
    return _inner!;
  }

  @override
  Future<Result<List<GuideCard>, GuidanceServiceError>> search({
    required SituationSlots slots,
    required DisasterType type,
    int limit = 10,
  }) async {
    return (await _service()).search(slots: slots, type: type, limit: limit);
  }
}
