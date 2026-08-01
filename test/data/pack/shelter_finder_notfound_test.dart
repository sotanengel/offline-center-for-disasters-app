import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/data/pack/hazard_grid_repository.dart';
import 'package:offline_center_for_disasters/data/pack/pack_database.dart';
import 'package:offline_center_for_disasters/data/pack/shelter_finder.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/shelter_query.dart';

import 'pack_fixture.dart';

/// §4.4: 拡大半径でも 0 件なら notFound=true, expandedRadius=false。
void main() {
  late PackDatabase db;
  late ShelterFinder finder;

  setUp(() async {
    db = createFixtureExecutor();
    await createSchema(db);
    finder = ShelterFinder(db, HazardGridRepository(db));
  });

  tearDown(() => db.close());

  test('全件 0 のとき notFound=true / expandedRadius=false', () async {
    final r = await finder.find(
      origin: const GeoPoint(35.0, 139.0),
      query: const ShelterQuery(disasterType: DisasterType.volcano),
    );
    expect(r.shelters, isEmpty);
    expect(r.notFound, isTrue);
    expect(r.expandedRadius, isFalse);
  });

  test('初期半径内で見つかれば notFound=false / expandedRadius=false', () async {
    await insertShelter(
      db,
      rowid: 1,
      id: 'near',
      lat: 35.001,
      lng: 139.0,
      okVolcano: 1,
    );
    final r = await finder.find(
      origin: const GeoPoint(35.0, 139.0),
      query: const ShelterQuery(disasterType: DisasterType.volcano),
    );
    expect(r.notFound, isFalse);
    expect(r.expandedRadius, isFalse);
  });

  test('拡大半径でのみ見つかれば notFound=false / expandedRadius=true', () async {
    await insertShelter(
      db,
      rowid: 1,
      id: 'far',
      lat: 35.05,
      lng: 139.0,
      okVolcano: 1,
    );
    final r = await finder.find(
      origin: const GeoPoint(35.0, 139.0),
      query: const ShelterQuery(disasterType: DisasterType.volcano),
    );
    expect(r.notFound, isFalse);
    expect(r.expandedRadius, isTrue);
  });
}
