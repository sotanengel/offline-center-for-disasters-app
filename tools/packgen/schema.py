"""要件定義書 §14.1〜14.3 の SQLite スキーマ定義。"""
from __future__ import annotations

import sqlite3
from pathlib import Path

SCHEMA_SQL = """
CREATE TABLE shelters (
  id             TEXT PRIMARY KEY,
  name           TEXT NOT NULL,
  name_kana      TEXT,
  lat            REAL NOT NULL,
  lng            REAL NOT NULL,
  elevation_m    REAL,
  address        TEXT,
  -- 指定緊急避難場所の災害種別フラグ（法定8種別）
  ok_flood        INTEGER NOT NULL DEFAULT 0,
  ok_landslide    INTEGER NOT NULL DEFAULT 0,
  ok_storm_surge  INTEGER NOT NULL DEFAULT 0,
  ok_earthquake   INTEGER NOT NULL DEFAULT 0,
  ok_tsunami      INTEGER NOT NULL DEFAULT 0,
  ok_fire         INTEGER NOT NULL DEFAULT 0,
  ok_inland_flood INTEGER NOT NULL DEFAULT 0,
  ok_volcano      INTEGER NOT NULL DEFAULT 0,
  -- 派生列（パック生成時に計算）
  is_all_hazard   INTEGER NOT NULL DEFAULT 0,
  place_class     INTEGER,
  usable_floor_height_m REAL,
  is_shelter      INTEGER NOT NULL DEFAULT 0,
  barrier_free    INTEGER NOT NULL DEFAULT 0,
  capacity        INTEGER,
  nearest_node_id INTEGER,
  note            TEXT
);
CREATE VIRTUAL TABLE shelters_rtree USING rtree(id, minLat, maxLat, minLng, maxLng);
CREATE INDEX idx_shelters_allhazard ON shelters(is_all_hazard);

CREATE TABLE nodes (
  id INTEGER PRIMARY KEY, lat REAL NOT NULL, lng REAL NOT NULL, elevation_m REAL
);

CREATE TABLE edges (
  id          INTEGER PRIMARY KEY,
  from_node   INTEGER NOT NULL,
  to_node     INTEGER NOT NULL,
  length_m    REAL NOT NULL,
  geometry    BLOB,
  way_type    INTEGER,     -- 0:footway 1:residential 2:primary 3:steps 4:underpass 5:crossing
  width_class INTEGER,     -- 0:unknown 1:<1.5m 2:1.5-4m 3:>4m
  has_steps   INTEGER DEFAULT 0,
  is_lit      INTEGER DEFAULT 0,
  -- 事前計算済みハザード属性
  hz_flood_depth   INTEGER DEFAULT 0,  -- 0:なし 1:<0.5m 2:0.5-3m 3:3-5m 4:>5m
  hz_tsunami_depth INTEGER DEFAULT 0,
  hz_landslide     INTEGER DEFAULT 0,  -- 0:なし 1:警戒区域 2:特別警戒区域
  hz_storm_surge   INTEGER DEFAULT 0,
  hz_volcano       INTEGER DEFAULT 0,
  near_river       INTEGER DEFAULT 0,
  dense_wood       INTEGER DEFAULT 0,
  landmark_name    TEXT
);
CREATE INDEX idx_edges_from ON edges(from_node);
CREATE INDEX idx_edges_to   ON edges(to_node);

CREATE TABLE hazard_grid (
  cell_id          INTEGER PRIMARY KEY,
  elevation_m      REAL,
  flood_depth_m    REAL DEFAULT 0,
  tsunami_depth_m  REAL DEFAULT 0,
  landslide_class  INTEGER DEFAULT 0,
  storm_surge_m    REAL DEFAULT 0,
  volcano_class    INTEGER DEFAULT 0,
  dist_coast_m     INTEGER,
  dist_river_m     INTEGER,
  dense_wood       INTEGER DEFAULT 0
);

-- パックの出典・バージョン情報（§21 ライセンス表示用）
CREATE TABLE metadata (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
"""


def init_db(path: str | Path) -> sqlite3.Connection:
    """スキーマを初期化した SQLite コネクションを返す。"""
    db = sqlite3.connect(str(path))
    db.executescript(SCHEMA_SQL)
    return db
