import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_center_for_disasters/core/geo/geo_bounds.dart';
import 'package:offline_center_for_disasters/core/geo/geo_point.dart';
import 'package:offline_center_for_disasters/data/pack/hazard_grid_repository.dart';
import 'package:offline_center_for_disasters/data/pack/multi_region_pack.dart';
import 'package:offline_center_for_disasters/data/pack/pack_database.dart';
import 'package:offline_center_for_disasters/data/pack/pack_loader.dart';
import 'package:offline_center_for_disasters/domain/entities/enums.dart';
import 'package:offline_center_for_disasters/domain/entities/shelter_query.dart';

import 'pack_fixture.dart';

Future<DataPack> _openPack({
  required String region,
  required String bboxJson,
  required Future<void> Function(PackDatabase db) seed,
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = createFixtureExecutor();
  await createSchema(db);
  await insertMetadata(db, 'region', region);
  await insertMetadata(db, 'schema', 'spec-§14 v1');
  await insertMetadata(db, 'bbox', bboxJson);
  await seed(db);
  return DataPack.test(db, {
    'region': region,
    'schema': 'spec-§14 v1',
    'bbox': bboxJson,
  });
}

void main() {
  test('避難所検索は複数パックを距離順にマージする', () async {
    final tokyo = await _openPack(
      region: 'tokyo',
      bboxJson: '[138.93,35.49,139.93,35.91]',
      seed: (db) async {
        await insertShelter(
          db,
          rowid: 1,
          id: 'E1310100001201',
          name: '東京側避難所',
          lat: 35.56,
          lng: 139.45,
          okVolcano: 1,
          nearestNodeId: 100,
        );
      },
    );
    final kanagawa = await _openPack(
      region: 'kanagawa',
      bboxJson: '[138.92,35.10,139.81,35.68]',
      seed: (db) async {
        await insertShelter(
          db,
          rowid: 1,
          id: 'E1410000001201',
          name: '神奈川側避難所',
          lat: 35.54,
          lng: 139.45,
          okVolcano: 1,
          nearestNodeId: 200,
        );
      },
    );
    addTearDown(() async {
      await tokyo.close();
      await kanagawa.close();
    });

    final multi = MultiRegionPack([tokyo, kanagawa]);
    const origin = GeoPoint(35.55, 139.45);
    final result = await multi.findShelters(
      origin: origin,
      query: const ShelterQuery(
        disasterType: DisasterType.volcano,
        radiusKm: 3,
      ),
    );

    expect(result.notFound, isFalse);
    expect(result.shelters.map((s) => s.name).toList(), [
      '神奈川側避難所', // 35.54 の方が近い
      '東京側避難所',
    ]);
  });

  test('グラフ合成は OSM ノードを共有しエッジ ID 衝突を解消する', () async {
    final tokyo = await _openPack(
      region: 'tokyo',
      bboxJson: '[138.93,35.49,139.93,35.91]',
      seed: (db) async {
        db.customStatement(
          'INSERT INTO nodes (id, lat, lng) VALUES'
          ' (1, 35.55, 139.45), (2, 35.551, 139.45)',
        );
        db.customStatement(
          'INSERT INTO edges (id, from_node, to_node, length_m)'
          ' VALUES (1, 1, 2, 100)',
        );
      },
    );
    final kanagawa = await _openPack(
      region: 'kanagawa',
      bboxJson: '[138.92,35.10,139.81,35.68]',
      seed: (db) async {
        db.customStatement(
          'INSERT INTO nodes (id, lat, lng) VALUES'
          ' (2, 35.551, 139.45), (3, 35.552, 139.45)',
        );
        // 県内連番 ID=1 は東京側と衝突するが (2,3) 辺は別物
        db.customStatement(
          'INSERT INTO edges (id, from_node, to_node, length_m)'
          ' VALUES (1, 2, 3, 110)',
        );
      },
    );
    addTearDown(() async {
      await tokyo.close();
      await kanagawa.close();
    });

    final multi = MultiRegionPack([tokyo, kanagawa]);
    final graph = await multi.loadGraph(
      bounds: const GeoBounds(
        minLat: 35.54,
        maxLat: 35.56,
        minLng: 139.44,
        maxLng: 139.46,
      ),
    );

    expect(graph.nodes.keys.toSet(), {1, 2, 3});
    expect(graph.edges.length, 2);
    expect(graph.edges.map((e) => e.id).toSet().length, 2);
    // 県をまたいで 1-2-3 と辿れる
    expect(graph.edgesOf(2).length, 2);
  });

  test('ハザードは複数パックの最大値を安全側で採用する', () async {
    final cellId = HazardGridRepository.cellIdFor(
      const GeoPoint(35.55, 139.45),
    );
    final tokyo = await _openPack(
      region: 'tokyo',
      bboxJson: '[138.93,35.49,139.93,35.91]',
      seed: (db) async {
        await insertHazardCell(db, cellId: cellId, floodDepthM: 1.0);
      },
    );
    final kanagawa = await _openPack(
      region: 'kanagawa',
      bboxJson: '[138.92,35.10,139.81,35.68]',
      seed: (db) async {
        await insertHazardCell(db, cellId: cellId, floodDepthM: 2.5);
      },
    );
    addTearDown(() async {
      await tokyo.close();
      await kanagawa.close();
    });

    final multi = MultiRegionPack([tokyo, kanagawa]);
    final ctx = await multi.contextAt(const GeoPoint(35.55, 139.45));
    expect(ctx.inFloodZone, isTrue);
    expect(ctx.floodDepthM, 2.5);
  });
}
