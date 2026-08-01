import 'package:flutter_test/flutter_test.dart';

import 'package:offline_center_for_disasters/core/result/result.dart';
import 'package:offline_center_for_disasters/data/guidance/kb_guidance_service.dart';
import 'package:offline_center_for_disasters/data/llm/fake_llm_engine.dart';
import 'package:offline_center_for_disasters/data/llm/guide_reranker.dart';
import 'package:offline_center_for_disasters/data/search/bm25_index.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/situation_slots.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AI リランキング: 候補外 ID は破棄され有効 ID のみ返る', () async {
    final kb = await KbGuidanceService.create();
    expect(kb.allCards, isNotEmpty);
    final ids = kb.allCards.take(5).map((c) => c.id).toList();
    final reranker = GuideReranker(
      FakeLlmEngine(
        available: true,
        rerankResult: Ok([ids.first, 'G-INVALID', ids.last]),
      ),
    );
    final service = KbGuidanceService(
      cards: kb.allCards,
      index: Bm25Index.fromTexts([
        for (final c in kb.allCards)
          (id: c.id, text: '${c.title} ${c.steps.join(' ')}', tags: c.tags),
      ]),
      reranker: reranker,
    );
    final r = await service.search(
      slots: const SituationSlots(
        disasterType: DisasterType.tsunami,
        guideTags: ['tsunami_evacuation'],
      ),
      type: DisasterType.tsunami,
      limit: 8,
    );
    expect(r, isA<Ok>());
    final cards = (r as Ok).value;
    expect(cards.every((c) => ids.contains(c.id)), isTrue);
    expect(cards.any((c) => c.id == 'G-INVALID'), isFalse);
  });
}
