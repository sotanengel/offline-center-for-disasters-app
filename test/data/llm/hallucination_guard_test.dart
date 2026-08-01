import 'package:flutter_test/flutter_test.dart';

import 'package:offline_center_for_disasters/data/llm/hallucination_guard.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/guide_card.dart';
import 'package:offline_center_for_disasters/domain/entities/situation_slots.dart';

void main() {
  const guard = HallucinationGuard();
  const card = GuideCard(
    id: 'G-1',
    title: '津波警報',
    steps: ['高台へ移動'],
    source: '気象庁',
  );

  test('80字超は破棄', () {
    expect(
      guard.isAllowed(
        generated: 'あ' * 81,
        card: card,
        slots: const SituationSlots(),
      ),
      isFalse,
    );
  });

  test('安全保証フレーズは破棄', () {
    expect(
      guard.isAllowed(
        generated: '必ず助かりますので安心してください',
        card: card,
        slots: const SituationSlots(),
      ),
      isFalse,
    );
  });

  test('根拠のない数値は破棄', () {
    expect(
      guard.isAllowed(
        generated: '999メートル先の避難所へ',
        card: card,
        slots: const SituationSlots(),
      ),
      isFalse,
    );
  });

  test('短い補足文は許可', () {
    expect(
      guard.isAllowed(
        generated: '今すぐ高台へ向かってください。',
        card: card,
        slots: const SituationSlots(disasterType: DisasterType.tsunami),
      ),
      isTrue,
    );
  });
}
