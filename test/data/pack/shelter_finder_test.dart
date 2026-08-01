import 'package:offline_center_for_disasters/data/pack/pack_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/data/pack/hazard_grid_repository.dart';
import 'package:offline_center_for_disasters/data/pack/shelter_finder.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/shelter_query.dart';

import 'pack_fixture.dart';

/// §4.1 属性フィルタ + §4.4 半径拡大 + §9.1 手順2/4（R*Tree・最大20件）
void main() {
  const origin = GeoPoint(35.0, 139.0);

  late PackDatabase db;
  late ShelterFinder finder;

  Future<void> seed(Future<void> Function() body) async {
    db = createFixtureExecutor();
    await createSchema(db);
    await body();
    finder = ShelterFinder(db, HazardGridRepository(db));
  }

  tearDown(() => db.close());

  group('半径・件数', () {
    test('半径 10km 内の避難所のみ返る（圏外は除外）', () async {
      await seed(() async {
        // 約 1.1km 北
        await insertShelter(
          db,
          rowid: 1,
          id: 'near',
          lat: 35.01,
          lng: 139.0,
          okVolcano: 1,
        );
        // 約 12km 北（10km 圏外）
        await insertShelter(
          db,
          rowid: 2,
          id: 'far',
          lat: 35.11,
          lng: 139.0,
          okVolcano: 1,
        );
      });
      final r = await finder.find(
        origin: origin,
        query: const ShelterQuery(disasterType: DisasterType.volcano),
      );
      expect(r.shelters.map((s) => s.id), ['near']);
      expect(r.expandedRadius, isFalse);
    });

    test('§4.4 / Q10: 10km で 0 件なら 20km に拡大して再探索する', () async {
      await seed(() async {
        await insertShelter(
          db,
          rowid: 1,
          id: 'far',
          lat: 35.11,
          lng: 139.0,
          okVolcano: 1,
        );
      });
      final r = await finder.find(
        origin: origin,
        query: const ShelterQuery(disasterType: DisasterType.volcano),
      );
      expect(r.shelters.map((s) => s.id), ['far']);
      expect(r.expandedRadius, isTrue);
    });

    test('20km でも 0 件なら空を返す（避難先を断定しない）', () async {
      await seed(() async {
        await insertShelter(
          db,
          rowid: 1,
          id: 'too-far',
          lat: 35.22,
          lng: 139.0,
          okVolcano: 1,
        );
      });
      final r = await finder.find(
        origin: origin,
        query: const ShelterQuery(disasterType: DisasterType.volcano),
      );
      expect(r.shelters, isEmpty);
    });

    test('直線距離昇順・最大 20 件（§9.1 手順4）', () async {
      await seed(() async {
        for (var i = 0; i < 25; i++) {
          // 0.0001° 刻みで北へ（約 11m 間隔）
          await insertShelter(
            db,
            rowid: i + 1,
            id: 's${(i + 1).toString().padLeft(2, '0')}',
            lat: 35.0 + (i + 1) * 0.0001,
            lng: 139.0,
            okVolcano: 1,
          );
        }
      });
      final r = await finder.find(
        origin: origin,
        query: const ShelterQuery(disasterType: DisasterType.volcano),
      );
      expect(r.shelters.length, 20);
      expect(r.shelters.first.id, 's01');
      expect(r.shelters.last.id, 's20');
    });
  });

  group('§4.1 属性フィルタ', () {
    test('津波: ok_tsunami=1 かつ標高要件を満たすもののみ', () async {
      await seed(() async {
        await insertShelter(
          db,
          rowid: 1,
          id: 'ok',
          lat: 35.01,
          lng: 139.0,
          okTsunami: 1,
          elevationM: 20,
        );
        await insertShelter(
          db,
          rowid: 2,
          id: 'low',
          lat: 35.01,
          lng: 139.001,
          okTsunami: 1,
          elevationM: 5,
        );
        await insertShelter(
          db,
          rowid: 3,
          id: 'no-flag',
          lat: 35.01,
          lng: 139.002,
          elevationM: 30,
        );
      });
      final r = await finder.find(
        origin: origin,
        query: const ShelterQuery(
          disasterType: DisasterType.tsunami,
          minElevationM: 15,
        ),
      );
      expect(r.shelters.map((s) => s.id), ['ok']);
    });

    test('地震: 広い空地（place_class=1）のみ。建物内へは誘導しない（MUST）', () async {
      await seed(() async {
        await insertShelter(
          db,
          rowid: 1,
          id: 'park',
          lat: 35.01,
          lng: 139.0,
          okEarthquake: 1,
          placeClass: 1,
        );
        await insertShelter(
          db,
          rowid: 2,
          id: 'school',
          lat: 35.01,
          lng: 139.001,
          okEarthquake: 1,
          placeClass: 0,
        );
      });
      final r = await finder.find(
        origin: origin,
        query: const ShelterQuery(disasterType: DisasterType.earthquake),
      );
      expect(r.shelters.map((s) => s.id), ['park']);
    });

    test('種別不明（§3.6）: is_all_hazard=1 のみ', () async {
      await seed(() async {
        await insertShelter(
          db,
          rowid: 1,
          id: 'all',
          lat: 35.01,
          lng: 139.0,
          isAllHazard: 1,
        );
        await insertShelter(
          db,
          rowid: 2,
          id: 'tsunami-only',
          lat: 35.01,
          lng: 139.001,
          okTsunami: 1,
        );
      });
      final r = await finder.find(
        origin: origin,
        query: const ShelterQuery(disasterType: DisasterType.unknown),
      );
      expect(r.shelters.map((s) => s.id), ['all']);
    });

    test('土砂: 避難所所在地が警戒区域内なら除外する', () async {
      await seed(() async {
        await insertShelter(
          db,
          rowid: 1,
          id: 'safe',
          lat: 35.0,
          lng: 139.0,
          okLandslide: 1,
        );
        await insertShelter(
          db,
          rowid: 2,
          id: 'in-zone',
          lat: 35.01,
          lng: 139.0,
          okLandslide: 1,
        );
        // in-zone の所在地セルに landslide_class=1 を設定
        await insertHazardCell(
          db,
          cellId: (35.01 * 2000).floor() * 1000000 + (139.0 * 2000).floor(),
          landslideClass: 1,
        );
      });
      final r = await finder.find(
        origin: origin,
        query: const ShelterQuery(disasterType: DisasterType.landslide),
      );
      expect(r.shelters.map((s) => s.id), ['safe']);
    });
  });
}
