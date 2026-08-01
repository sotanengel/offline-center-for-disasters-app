import '../../core/result/result.dart';
import '../../domain/entities/guide_card.dart';
import '../../domain/entities/situation_slots.dart';
import 'hallucination_guard.dart';
import 'llm_engine.dart';
import 'llm_errors.dart';

/// AI-3: ガイドカード ID リランキング。
class GuideReranker {
  GuideReranker(this._engine);

  final LlmEngine _engine;

  Future<List<GuideCard>> rerank({
    required List<GuideCard> candidates,
    required SituationSlots slots,
  }) async {
    if (candidates.length <= 3) return candidates;
    final limited = candidates.take(8).toList();
    final ids = limited.map((c) => c.id).toList();
    final result = await _engine.rerankGuideIds(candidateIds: ids, ctx: slots);
    if (result is! Ok<List<String>, LlmError>) {
      return limited.take(3).toList();
    }
    final ranked = result.value;
    if (ranked.isEmpty) return limited.take(3).toList();
    final byId = {for (final c in limited) c.id: c};
    final out = <GuideCard>[];
    for (final id in ranked) {
      final card = byId[id];
      if (card != null) out.add(card);
    }
    return out.isEmpty ? limited.take(3).toList() : out;
  }
}

/// AI-4: 当てはめ文生成 + ガード。
class PhraseGenerator {
  PhraseGenerator(this._engine, {HallucinationGuard? guard})
    : _guard = guard ?? const HallucinationGuard();

  final LlmEngine _engine;
  final HallucinationGuard _guard;

  Future<String?> generate({
    required GuideCard card,
    required SituationSlots slots,
  }) async {
    final sw = Stopwatch()..start();
    final result = await _engine.generatePhrase(card: card, ctx: slots);
    sw.stop();
    if (result is! Ok<String, LlmError>) return null;
    final text = result.value;
    if (_guard.isAllowed(
      generated: text,
      card: card,
      slots: slots,
      generationTime: sw.elapsed,
    )) {
      return text;
    }
    return null;
  }
}
