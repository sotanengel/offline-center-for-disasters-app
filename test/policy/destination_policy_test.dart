import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/hazard_context.dart';
import 'package:offline_center_for_disasters/domain/entities/shelter.dart';
import 'package:offline_center_for_disasters/domain/entities/user_state.dart';
import 'package:offline_center_for_disasters/domain/policies/destination_policy.dart';

/// §4.1 決定表のテーブル駆動テスト（§20.1 MUST）
void main() {
  const policy = DestinationPolicy();
  const noHazard = HazardContext();
  const user = UserState();

  Shelter base({
    String id = 'S',
    bool okTsunami = false,
    bool okFlood = false,
    bool okLandslide = false,
    bool okStormSurge = false,
    bool okEarthquake = false,
    bool okFire = false,
    bool okVolcano = false,
    bool isAllHazard = false,
    double elevationM = 10.0,
    PlaceClass placeClass = PlaceClass.unknownOrBuilding,
    double? usableFloorHeightM,
  }) {
    return Shelter(
      id: id,
      name: id,
      lat: 35.0,
      lng: 139.0,
      elevationM: elevationM,
      okTsunami: okTsunami,
      okFlood: okFlood,
      okLandslide: okLandslide,
      okStormSurge: okStormSurge,
      okEarthquake: okEarthquake,
      okFire: okFire,
      okVolcano: okVolcano,
      isAllHazard: isAllHazard,
      placeClass: placeClass,
      usableFloorHeightM: usableFloorHeightM,
    );
  }

  group('§20.1-1: 津波選択時に ok_tsunami=0 の避難所が候補に入らない', () {
    const ctx = HazardContext(inTsunamiZone: true, tsunamiDepthM: 2.0);
    final query = policy.buildQuery(DisasterType.tsunami, ctx, user);

    test('ok_tsunami=1 かつ標高十分 → 候補', () {
      expect(
        query.matches(base(okTsunami: true, elevationM: 20.0), noHazard),
        isTrue,
      );
    });
    test('ok_tsunami=0 → 除外（標高が十分でも）', () {
      expect(
        query.matches(base(okTsunami: false, elevationM: 50.0), noHazard),
        isFalse,
      );
    });
  });

  group('§20.1-2: 津波選択時に 標高 < 想定浸水深+5m の場所が選ばれない', () {
    const ctx = HazardContext(inTsunamiZone: true, tsunamiDepthM: 3.0);
    final query = policy.buildQuery(DisasterType.tsunami, ctx, user);

    test('標高 7.9m < 3+5 → 除外', () {
      expect(
        query.matches(base(okTsunami: true, elevationM: 7.9), noHazard),
        isFalse,
      );
    });
    test('標高 8.0m = 3+5 → 候補', () {
      expect(
        query.matches(base(okTsunami: true, elevationM: 8.0), noHazard),
        isTrue,
      );
    });
    test('津波避難ビルは利用階高さが基準を満たせば候補', () {
      expect(
        query.matches(
          base(
            okTsunami: true,
            elevationM: 2.0,
            placeClass: PlaceClass.tsunamiBuilding,
            usableFloorHeightM: 12.0,
          ),
          noHazard,
        ),
        isTrue,
      );
    });
    test('津波避難ビルでも利用階高さが不足なら除外', () {
      expect(
        query.matches(
          base(
            okTsunami: true,
            elevationM: 2.0,
            placeClass: PlaceClass.tsunamiBuilding,
            usableFloorHeightM: 5.0,
          ),
          noHazard,
        ),
        isFalse,
      );
    });
  });

  group('§20.1-3: 土砂選択時に特別警戒区域内の避難所が選ばれない', () {
    final query = policy.buildQuery(DisasterType.landslide, noHazard, user);

    test('警戒区域（class=1）内 → 除外', () {
      const atShelter = HazardContext(landslideClass: 1);
      expect(query.matches(base(okLandslide: true), atShelter), isFalse);
    });
    test('特別警戒区域（class=2）内 → 除外', () {
      const atShelter = HazardContext(landslideClass: 2);
      expect(query.matches(base(okLandslide: true), atShelter), isFalse);
    });
    test('区域外 → 候補', () {
      expect(query.matches(base(okLandslide: true), noHazard), isTrue);
    });
    test('ok_landslide=0 → 区域外でも除外', () {
      expect(query.matches(base(okLandslide: false), noHazard), isFalse);
    });
  });

  group('§20.1-4: 地震選択時に建物系ではなくオープンスペースが優先される', () {
    final query = policy.buildQuery(DisasterType.earthquake, noHazard, user);

    test('広域空地 → 候補', () {
      expect(
        query.matches(
          base(okEarthquake: true, placeClass: PlaceClass.openSpace),
          noHazard,
        ),
        isTrue,
      );
    });
    test('建物（クラス不明/建物）→ 除外（建物内へ誘導しない MUST）', () {
      expect(query.matches(base(okEarthquake: true), noHazard), isFalse);
    });
    test('ok_earthquake=0 の空地 → 除外', () {
      expect(
        query.matches(
          base(okEarthquake: false, placeClass: PlaceClass.openSpace),
          noHazard,
        ),
        isFalse,
      );
    });
  });

  group('§4.1 洪水: 浸水想定域外 or 十分な階数', () {
    final query = policy.buildQuery(DisasterType.flood, noHazard, user);

    test('浸水想定域外 → 候補', () {
      expect(query.matches(base(okFlood: true), noHazard), isTrue);
    });
    test('浸水想定域内・階数情報なし → 除外', () {
      const atShelter = HazardContext(inFloodZone: true, floodDepthM: 1.0);
      expect(query.matches(base(okFlood: true), atShelter), isFalse);
    });
    test('浸水想定域内・十分な利用階高さ → 候補', () {
      const atShelter = HazardContext(inFloodZone: true, floodDepthM: 1.0);
      expect(
        query.matches(base(okFlood: true, usableFloorHeightM: 6.0), atShelter),
        isTrue,
      );
    });
    test('ok_flood=0 → 除外', () {
      expect(query.matches(base(okFlood: false), noHazard), isFalse);
    });
  });

  group('§20.1-6: unknown 選択時にオールハザード避難場所のみが候補になる', () {
    final query = policy.buildQuery(DisasterType.unknown, noHazard, user);

    test('is_all_hazard=1 → 候補', () {
      expect(query.matches(base(isAllHazard: true), noHazard), isTrue);
    });
    test('全フラグ立っていても is_all_hazard=0 なら除外', () {
      expect(
        query.matches(
          base(
            okTsunami: true,
            okFlood: true,
            okLandslide: true,
            okStormSurge: true,
            okEarthquake: true,
            okFire: true,
            okVolcano: true,
            // isAllHazard: false（派生列が正しく計算されていない異常系）
          ),
          noHazard,
        ),
        isFalse,
      );
    });
    test('個別フラグのみの避難所は除外', () {
      expect(query.matches(base(okEarthquake: true), noHazard), isFalse);
    });
  });

  group('§4.1 その他の種別', () {
    test('高潮: ok_storm_surge + 想定域外', () {
      final query = policy.buildQuery(DisasterType.stormSurge, noHazard, user);
      expect(query.matches(base(okStormSurge: true), noHazard), isTrue);
      const atShelter = HazardContext(inStormSurgeZone: true, stormSurgeM: 2.0);
      expect(query.matches(base(okStormSurge: true), atShelter), isFalse);
    });
    test('火災: ok_fire + 広域空地', () {
      final query = policy.buildQuery(DisasterType.fire, noHazard, user);
      expect(
        query.matches(
          base(okFire: true, placeClass: PlaceClass.openSpace),
          noHazard,
        ),
        isTrue,
      );
      expect(query.matches(base(okFire: true), noHazard), isFalse);
    });
    test('噴火: ok_volcano のみ必須', () {
      final query = policy.buildQuery(DisasterType.volcano, noHazard, user);
      expect(query.matches(base(okVolcano: true), noHazard), isTrue);
      expect(query.matches(base(okVolcano: false), noHazard), isFalse);
    });
  });

  group('§9.2 ルーティングプロファイル（決定表の経路側）', () {
    const normal = UserState();
    const wheelchair = UserState(mobility: Mobility.wheelchair);

    test('mobility 別の速度', () {
      expect(
        policy.buildRoutingProfile(DisasterType.flood, normal, false).speedMps,
        1.25,
      );
      expect(
        policy
            .buildRoutingProfile(
              DisasterType.flood,
              const UserState(mobility: Mobility.slow),
              false,
            )
            .speedMps,
        0.8,
      );
      expect(
        policy
            .buildRoutingProfile(
              DisasterType.flood,
              const UserState(mobility: Mobility.assisted),
              false,
            )
            .speedMps,
        0.6,
      );
      expect(
        policy
            .buildRoutingProfile(DisasterType.flood, wheelchair, false)
            .speedMps,
        0.7,
      );
    });

    test('§20.1-5 へ繋がる: 洪水ではアンダーパス禁止（999 相当）', () {
      final profile = policy.buildRoutingProfile(
        DisasterType.flood,
        normal,
        false,
      );
      expect(profile.forbidUnderpass, isTrue);
    });
    test('浸水系以外はアンダーパスはペナルティ 2.0', () {
      final profile = policy.buildRoutingProfile(
        DisasterType.earthquake,
        normal,
        false,
      );
      expect(profile.forbidUnderpass, isFalse);
      expect(profile.underpassPenalty, 2.0);
    });
    test('wheelchair は階段・幅員1.5m未満を禁止', () {
      final profile = policy.buildRoutingProfile(
        DisasterType.flood,
        wheelchair,
        false,
      );
      expect(profile.forbidSteps, isTrue);
      expect(profile.forbidNarrowWheelchair, isTrue);
    });
    test('土砂災害では特別警戒区域エッジを通行不可にする', () {
      final profile = policy.buildRoutingProfile(
        DisasterType.landslide,
        normal,
        false,
      );
      expect(profile.landslideSpecialForbidden, isTrue);
    });
    test('浸水系は河川近接ペナルティ 0.5', () {
      expect(
        policy
            .buildRoutingProfile(DisasterType.tsunami, normal, false)
            .riverNearPenalty,
        0.5,
      );
    });
    test('地震は狭路ペナルティ 0.8', () {
      expect(
        policy
            .buildRoutingProfile(DisasterType.earthquake, normal, false)
            .narrowPenalty,
        0.8,
      );
    });
    test('夜間は nightPenalty が有効', () {
      final profile = policy.buildRoutingProfile(
        DisasterType.flood,
        normal,
        true,
      );
      expect(profile.isNight, isTrue);
      expect(profile.nightPenalty, 0.3);
    });
  });
}
