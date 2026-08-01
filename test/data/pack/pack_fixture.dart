import 'package:offline_center_for_disasters/data/pack/pack_database.dart';

/// テスト用の合成パック（§14 スキーマ）をメモリ SQLite に構築する。
///
/// 本物のパックは tools/packgen が生成するが、ここではリポジトリ層の
/// 振る舞い検証に必要な最小限の行のみを投入する。
PackDatabase createFixtureExecutor() => PackDatabase.memory();

Future<void> createSchema(PackDatabase db) async {
  final statements = '''
CREATE TABLE shelters (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  name_kana TEXT,
  lat REAL NOT NULL,
  lng REAL NOT NULL,
  elevation_m REAL,
  address TEXT,
  ok_flood INTEGER NOT NULL DEFAULT 0,
  ok_landslide INTEGER NOT NULL DEFAULT 0,
  ok_storm_surge INTEGER NOT NULL DEFAULT 0,
  ok_earthquake INTEGER NOT NULL DEFAULT 0,
  ok_tsunami INTEGER NOT NULL DEFAULT 0,
  ok_fire INTEGER NOT NULL DEFAULT 0,
  ok_inland_flood INTEGER NOT NULL DEFAULT 0,
  ok_volcano INTEGER NOT NULL DEFAULT 0,
  is_all_hazard INTEGER NOT NULL DEFAULT 0,
  place_class INTEGER,
  usable_floor_height_m REAL,
  is_shelter INTEGER NOT NULL DEFAULT 0,
  barrier_free INTEGER NOT NULL DEFAULT 0,
  capacity INTEGER,
  nearest_node_id INTEGER,
  note TEXT
);
CREATE VIRTUAL TABLE shelters_rtree USING rtree(id, minLat, maxLat, minLng, maxLng);
CREATE TABLE nodes (
  id INTEGER PRIMARY KEY, lat REAL NOT NULL, lng REAL NOT NULL, elevation_m REAL
);
CREATE TABLE edges (
  id INTEGER PRIMARY KEY,
  from_node INTEGER NOT NULL,
  to_node INTEGER NOT NULL,
  length_m REAL NOT NULL,
  geometry BLOB,
  way_type INTEGER,
  width_class INTEGER,
  has_steps INTEGER DEFAULT 0,
  is_lit INTEGER DEFAULT 0,
  hz_flood_depth INTEGER DEFAULT 0,
  hz_tsunami_depth INTEGER DEFAULT 0,
  hz_landslide INTEGER DEFAULT 0,
  hz_storm_surge INTEGER DEFAULT 0,
  hz_volcano INTEGER DEFAULT 0,
  near_river INTEGER DEFAULT 0,
  dense_wood INTEGER DEFAULT 0,
  landmark_name TEXT
);
CREATE TABLE hazard_grid (
  cell_id INTEGER PRIMARY KEY,
  elevation_m REAL,
  flood_depth_m REAL DEFAULT 0,
  tsunami_depth_m REAL DEFAULT 0,
  landslide_class INTEGER DEFAULT 0,
  storm_surge_m REAL DEFAULT 0,
  volcano_class INTEGER DEFAULT 0,
  dist_coast_m INTEGER,
  dist_river_m INTEGER,
  dense_wood INTEGER DEFAULT 0
);
CREATE TABLE metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL);
''';
  for (final stmt in statements.split(';')) {
    final s = stmt.trim();
    if (s.isNotEmpty) db.customStatement(s);
  }
  // VACUUM 的な flush は不要（memory DB）
}

Future<void> insertShelter(
  PackDatabase db, {
  required int rowid,
  required String id,
  required double lat,
  required double lng,
  String name = 'テスト避難所',
  double? elevationM,
  int okTsunami = 0,
  int okFlood = 0,
  int okEarthquake = 0,
  int okFire = 0,
  int okLandslide = 0,
  int okVolcano = 0,
  int isAllHazard = 0,
  int? placeClass,
  double? usableFloorHeightM,
  int? nearestNodeId,
}) async {
  db.customStatement(
    'INSERT INTO shelters (id, name, lat, lng, elevation_m, ok_tsunami,'
    ' ok_flood, ok_earthquake, ok_fire, ok_landslide, ok_volcano, is_all_hazard,'
    ' place_class, usable_floor_height_m, nearest_node_id)'
    ' VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      id,
      name,
      lat,
      lng,
      elevationM,
      okTsunami,
      okFlood,
      okEarthquake,
      okFire,
      okLandslide,
      okVolcano,
      isAllHazard,
      placeClass,
      usableFloorHeightM,
      nearestNodeId,
    ],
  );
  // shelters_rtree.id は shelters.rowid（packgen.shelters と同じ規約）
  db.customStatement(
    'INSERT INTO shelters_rtree (id, minLat, maxLat, minLng, maxLng)'
    ' VALUES (?, ?, ?, ?, ?)',
    [rowid, lat, lat, lng, lng],
  );
}

Future<void> insertHazardCell(
  PackDatabase db, {
  required int cellId,
  double? elevationM,
  double floodDepthM = 0,
  double tsunamiDepthM = 0,
  int landslideClass = 0,
  double stormSurgeM = 0,
  int volcanoClass = 0,
  int? distCoastM,
  int? distRiverM,
  int denseWood = 0,
}) async {
  db.customStatement(
    'INSERT INTO hazard_grid (cell_id, elevation_m, flood_depth_m,'
    ' tsunami_depth_m, landslide_class, storm_surge_m, volcano_class,'
    ' dist_coast_m, dist_river_m, dense_wood)'
    ' VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      cellId,
      elevationM,
      floodDepthM,
      tsunamiDepthM,
      landslideClass,
      stormSurgeM,
      volcanoClass,
      distCoastM,
      distRiverM,
      denseWood,
    ],
  );
}

Future<void> insertMetadata(PackDatabase db, String key, String value) async {
  db.customStatement('INSERT INTO metadata (key, value) VALUES (?, ?)', [
    key,
    value,
  ]);
}
