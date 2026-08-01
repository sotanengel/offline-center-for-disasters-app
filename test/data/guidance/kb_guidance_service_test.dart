import 'package:flutter_test/flutter_test.dart';

import 'package:offline_center_for_disasters/data/guidance/kb_guidance_service.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/situation_slots.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('津波クエリで津波関連カードを返す', () async {
    final svc = await KbGuidanceService.create();
    final r = await svc.search(
      slots: const SituationSlots(
        disasterType: DisasterType.tsunami,
        disasterTypeEvidence: '津波',
      ),
      type: DisasterType.tsunami,
      limit: 5,
    );
    expect(r.isOk, isTrue);
    final cards = r.valueOrNull!;
    expect(cards, isNotEmpty);
    expect(
      cards.any((c) => c.disasterTypes.contains(DisasterType.tsunami)),
      isTrue,
    );
  });
}
