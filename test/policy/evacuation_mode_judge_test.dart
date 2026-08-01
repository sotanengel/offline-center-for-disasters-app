import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/environment.dart';
import 'package:offline_center_for_disasters/domain/entities/hazard_context.dart';
import 'package:offline_center_for_disasters/domain/policies/evacuation_mode_judge.dart';

/// §4.3 水平避難 / 垂直避難の判定（決定論、MUST）
void main() {
  const judge = EvacuationModeJudgeImpl();

  group('浸水想定域外', () {
    test('その場に留まる or 水平避難（垂直は推奨しない）', () {
      final mode = judge.judge(
        type: DisasterType.flood,
        ctx: const HazardContext(),
        env: const Environment(place: PlaceType.indoor, floor: 5),
        estimatedTravelTime: const Duration(minutes: 10),
      );
      expect(mode, EvacuationMode.stayOrHorizontal);
    });
  });

  group('浸水想定域内', () {
    const ctx = HazardContext(inFloodZone: true, floodDepthM: 2.0);
    // required_floor = ceil(2.0/3.0)+1 = 2

    test('申告階数が不足 → 水平避難', () {
      final mode = judge.judge(
        type: DisasterType.flood,
        ctx: ctx,
        env: const Environment(place: PlaceType.indoor, floor: 1),
        estimatedTravelTime: const Duration(minutes: 5),
      );
      expect(mode, EvacuationMode.horizontal);
    });

    test('申告階数十分 + 移動制約あり → 垂直避難を推奨', () {
      final mode = judge.judge(
        type: DisasterType.flood,
        ctx: ctx,
        env: const Environment(place: PlaceType.indoor, floor: 3),
        estimatedTravelTime: const Duration(minutes: 5),
        mobility: Mobility.wheelchair,
      );
      expect(mode, EvacuationMode.verticalRecommended);
    });

    test('申告階数十分 + 水位が none でない → 垂直避難を推奨', () {
      final mode = judge.judge(
        type: DisasterType.flood,
        ctx: ctx,
        env: const Environment(
          place: PlaceType.indoor,
          floor: 3,
          waterLevel: WaterLevel.ankle,
        ),
        estimatedTravelTime: const Duration(minutes: 5),
      );
      expect(mode, EvacuationMode.verticalRecommended);
    });

    test('申告階数十分 + 通常移動可 + 水位なし → 水平避難', () {
      final mode = judge.judge(
        type: DisasterType.flood,
        ctx: ctx,
        env: const Environment(place: PlaceType.indoor, floor: 4),
        estimatedTravelTime: const Duration(minutes: 5),
      );
      expect(mode, EvacuationMode.horizontal);
    });

    test('階数不明 → 推奨ではなく選択肢併記（断定しない MUST）', () {
      final mode = judge.judge(
        type: DisasterType.flood,
        ctx: ctx,
        env: const Environment(place: PlaceType.indoor),
        estimatedTravelTime: const Duration(minutes: 5),
      );
      expect(mode, EvacuationMode.verticalOptional);
    });

    test('津波でも同様に判定（想定浸水深 4m → required_floor = 3）', () {
      const tsunamiCtx = HazardContext(inTsunamiZone: true, tsunamiDepthM: 4.0);
      final mode = judge.judge(
        type: DisasterType.tsunami,
        ctx: tsunamiCtx,
        env: const Environment(place: PlaceType.indoor, floor: 3),
        estimatedTravelTime: const Duration(minutes: 5),
        mobility: Mobility.slow,
      );
      expect(mode, EvacuationMode.verticalRecommended);
    });
  });

  group('浸水系以外の災害', () {
    test('地震では垂直避難の概念を適用しない', () {
      final mode = judge.judge(
        type: DisasterType.earthquake,
        ctx: const HazardContext(),
        env: const Environment(place: PlaceType.indoor, floor: 1),
        estimatedTravelTime: const Duration(minutes: 5),
      );
      expect(mode, EvacuationMode.stayOrHorizontal);
    });
  });

  group('猶予時間の扱い (§17 Q9 未決)', () {
    // Q9: 災害種別ごとの猶予時間の根拠が未決のため、graceTime=null では
    // travelExceeded=false として扱う (§4.3 の判定を creativeに埋めない)。
    test('graceTime=null かつ通常移動可 + 水位 none なら水平避難', () {
      const ctx = HazardContext(
        inFloodZone: true,
        floodDepthM: 2.0,
        // graceTime は指定せず null (既定)
      );
      final mode = judge.judge(
        type: DisasterType.flood,
        ctx: ctx,
        env: const Environment(place: PlaceType.indoor, floor: 3),
        estimatedTravelTime: const Duration(hours: 999),
      );
      // travelExceeded は null 猶予時間により常に false、
      // mobility=normal & waterLevel=none で他の垂直条件も満たさない → 水平
      expect(mode, EvacuationMode.horizontal);
    });
  });
}
