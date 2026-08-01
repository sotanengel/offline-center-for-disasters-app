"""国土地理院「避難所等データダウンロードサイト」の指定緊急避難場所 CSV を
shelters テーブル（§14.1）へ変換する。

CSV 仕様（都道府県別、Shift_JIS）:
  NO,共通ID,施設・場所名,住所,洪水,崖崩れ、土石流及び地滑り,高潮,地震,津波,
  大規模な火事,内水氾濫,火山現象,指定避難所との住所同一,緯度,経度,備考
"""
from __future__ import annotations

import csv
import sqlite3
from pathlib import Path

# CSV 列名 → shelters フラグ列（法定 8 種別）
FLAG_COLUMNS = {
    "洪水": "ok_flood",
    "崖崩れ、土石流及び地滑り": "ok_landslide",
    "高潮": "ok_storm_surge",
    "地震": "ok_earthquake",
    "津波": "ok_tsunami",
    "大規模な火事": "ok_fire",
    "内水氾濫": "ok_inland_flood",
    "火山現象": "ok_volcano",
}

ALL_FLAG_COLUMNS = list(FLAG_COLUMNS.values())


def _flag(value: str | None) -> int:
    return 1 if (value or "").strip() == "1" else 0


def _parse_float(value: str | None) -> float | None:
    try:
        return float((value or "").strip())
    except ValueError:
        return None


def _open_text(csv_path: str | Path):
    """UTF-8 を既定とし、失敗したら Shift_JIS（cp932）で開き直す。"""
    try:
        f = open(csv_path, encoding="utf-8", newline="")
        f.read(4096)
        f.seek(0)
        return f
    except UnicodeDecodeError:
        f.close()
        return open(csv_path, encoding="cp932", newline="")


def iter_shelter_rows(
    csv_path: str | Path,
    prefecture_names: tuple[str, ...] | None = None,
):
    """CSV を 1 行ずつ読み、shelters 挿入用 dict を返す。座標欠落行はスキップ。

    全国統合 CSV（都道府県名及び市町村名 列あり）の場合、prefecture_names で
    対象県に絞り込める。列が無い県別 CSV ではフィルタを適用しない。
    """
    with _open_text(csv_path) as f:
        for row in csv.DictReader(f):
            if prefecture_names and "都道府県名及び市町村名" in row:
                location = row.get("都道府県名及び市町村名") or ""
                if not any(location.startswith(p) for p in prefecture_names):
                    continue
            lat = _parse_float(row.get("緯度"))
            lng = _parse_float(row.get("経度"))
            if lat is None or lng is None:
                continue
            common_id = (row.get("共通ID") or "").strip()
            no = (row.get("NO") or "").strip()
            flags = {col: _flag(row.get(name)) for name, col in FLAG_COLUMNS.items()}
            yield {
                "id": common_id or f"row-{no}",
                "name": (row.get("施設・場所名") or "").strip() or "名称不明",
                "lat": lat,
                "lng": lng,
                "address": (row.get("住所") or "").strip() or None,
                "note": (row.get("備考") or "").strip() or None,
                "is_shelter": _flag(row.get("指定避難所との住所同一")),
                "is_all_hazard": 1 if all(flags.values()) else 0,
                **flags,
            }


def import_shelters_csv(
    db: sqlite3.Connection,
    csv_path: str | Path,
    prefecture_names: tuple[str, ...] | None = None,
) -> int:
    """CSV を shelters / shelters_rtree に取り込む。取込件数を返す。"""
    columns = [
        "id", "name", "lat", "lng", "address", "note", "is_shelter",
        "is_all_hazard", *ALL_FLAG_COLUMNS,
    ]
    placeholders = ", ".join("?" for _ in columns)
    sql = f"INSERT OR REPLACE INTO shelters ({', '.join(columns)}) VALUES ({placeholders})"
    count = 0
    with db:
        for row in iter_shelter_rows(csv_path, prefecture_names):
            # R*Tree のキーは整数必須のため、shelters の rowid を対応付ける
            cur = db.execute(sql, [row[c] for c in columns])
            db.execute(
                "INSERT OR REPLACE INTO shelters_rtree (id, minLat, maxLat, minLng, maxLng)"
                " VALUES (?, ?, ?, ?, ?)",
                (cur.lastrowid, row["lat"], row["lat"], row["lng"], row["lng"]),
            )
            count += 1
    return count
