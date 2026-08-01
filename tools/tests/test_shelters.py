"""国土地理院 指定緊急避難場所 CSV → shelters テーブルの変換テスト。"""
import sqlite3

from packgen.schema import init_db
from packgen.shelters import import_shelters_csv

# 国土地理院の都道府県別 CSV 形式に準拠したフィクスチャ（Shift_JIS 想定）
CSV_FIXTURE = """NO,共通ID,施設・場所名,住所,洪水,崖崩れ、土石流及び地滑り,高潮,地震,津波,大規模な火事,内水氾濫,火山現象,指定避難所との住所同一,緯度,経度,備考
1,ID001,〇〇小学校,東京都千代田区1-1,1,,,1,,,,,1,35.681,139.767,
2,ID002,△△公園,東京都港区2-2,1,1,1,1,1,1,1,1,,35.650,139.740,高台
3,ID003,□□公民館,東京都新宿区3-3,,,,,,,,,,35.690,139.700,
"""


def _load(db: sqlite3.Connection, csv_path):
    import_shelters_csv(db, csv_path)
    return db.execute(
        "SELECT * FROM shelters ORDER BY id"
    ).fetchall()


def test_import_populates_flags(tmp_path):
    db = init_db(tmp_path / "pack.sqlite")
    csv_path = tmp_path / "shelters.csv"
    csv_path.write_bytes(CSV_FIXTURE.encode("cp932"))
    rows = _load(db, csv_path)
    assert len(rows) == 3

    by_id = {r[0]: r for r in rows}
    names = {r[0]: r[1] for r in db.execute("SELECT id, name FROM shelters")}
    assert names["ID001"] == "〇〇小学校"

    flags = dict(
        db.execute("SELECT id, ok_flood FROM shelters")
    )
    assert flags["ID001"] == 1
    assert flags["ID003"] == 0


def test_all_hazard_derived_column(tmp_path):
    db = init_db(tmp_path / "pack.sqlite")
    csv_path = tmp_path / "shelters.csv"
    csv_path.write_bytes(CSV_FIXTURE.encode("cp932"))
    _load(db, csv_path)
    all_hazard = dict(db.execute("SELECT id, is_all_hazard FROM shelters"))
    # ID002 は全 8 種別フラグが立つのでオールハザード避難場所（§3.6）
    assert all_hazard["ID002"] == 1
    assert all_hazard["ID001"] == 0


def test_is_shelter_from_same_address_flag(tmp_path):
    db = init_db(tmp_path / "pack.sqlite")
    csv_path = tmp_path / "shelters.csv"
    csv_path.write_bytes(CSV_FIXTURE.encode("cp932"))
    _load(db, csv_path)
    is_shelter = dict(db.execute("SELECT id, is_shelter FROM shelters"))
    assert is_shelter["ID001"] == 1
    assert is_shelter["ID002"] == 0


def test_rows_without_coordinates_are_skipped(tmp_path):
    db = init_db(tmp_path / "pack.sqlite")
    csv_path = tmp_path / "shelters.csv"
    fixture = CSV_FIXTURE + "4,ID004,座標なし施設,東京都,,,,,,,,,,,\n"
    csv_path.write_bytes(fixture.encode("cp932"))
    rows = _load(db, csv_path)
    assert len(rows) == 3


def test_rtree_is_populated(tmp_path):
    db = init_db(tmp_path / "pack.sqlite")
    csv_path = tmp_path / "shelters.csv"
    csv_path.write_bytes(CSV_FIXTURE.encode("cp932"))
    _load(db, csv_path)
    rtree_count = db.execute("SELECT COUNT(*) FROM shelters_rtree").fetchone()[0]
    shelters_count = db.execute("SELECT COUNT(*) FROM shelters").fetchone()[0]
    assert rtree_count == shelters_count == 3
