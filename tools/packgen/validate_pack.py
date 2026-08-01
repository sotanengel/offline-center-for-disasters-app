"""生成パックの検証。スキーマ適合・整合性・件数を検査し JSON レポートを返す。"""
from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path

REQUIRED_TABLES = ["shelters", "shelters_rtree", "nodes", "edges", "hazard_grid", "metadata"]

ALL_FLAGS = [
    "ok_flood", "ok_landslide", "ok_storm_surge", "ok_earthquake",
    "ok_tsunami", "ok_fire", "ok_inland_flood", "ok_volcano",
]


def validate_pack(pack_path: str | Path) -> dict:
    errors: list[str] = []
    report = {"pack": str(pack_path), "ok": False, "counts": {}, "errors": errors}

    db = sqlite3.connect(str(pack_path))
    tables = {
        r[0] for r in db.execute("SELECT name FROM sqlite_master WHERE type IN ('table','virtual table')")
    }
    for table in REQUIRED_TABLES:
        if table not in tables:
            errors.append(f"テーブル欠落: {table}")
    if errors:
        report["ok"] = False
        return report

    for table in ["shelters", "nodes", "edges", "hazard_grid"]:
        count = db.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        report["counts"][table] = count
        if count == 0 and table != "hazard_grid":
            errors.append(f"{table} が 0 件です")

    # R*Tree と shelters の件数一致
    rtree = db.execute("SELECT COUNT(*) FROM shelters_rtree").fetchone()[0]
    if rtree != report["counts"]["shelters"]:
        errors.append(f"shelters_rtree ({rtree}) と shelters ({report['counts']['shelters']}) の件数不一致")

    # エッジの参照整合性
    orphan = db.execute(
        """
        SELECT COUNT(*) FROM edges e
        WHERE NOT EXISTS (SELECT 1 FROM nodes n WHERE n.id = e.from_node)
           OR NOT EXISTS (SELECT 1 FROM nodes n WHERE n.id = e.to_node)
        """
    ).fetchone()[0]
    if orphan:
        errors.append(f"edges に存在しないノードへの参照が {orphan} 件")

    # is_all_hazard 派生列の一貫性（全フラグ AND と一致すること）
    cond = " AND ".join(f"{f} = 1" for f in ALL_FLAGS)
    bad = db.execute(
        f"SELECT COUNT(*) FROM shelters WHERE is_all_hazard != CASE WHEN {cond} THEN 1 ELSE 0 END"
    ).fetchone()[0]
    if bad:
        errors.append(f"is_all_hazard の不整合が {bad} 件")

    # 座標の妥当性（日本国内の概略範囲）
    bad_coord = db.execute(
        "SELECT COUNT(*) FROM shelters WHERE lat < 20 OR lat > 46 OR lng < 122 OR lng > 154"
    ).fetchone()[0]
    if bad_coord:
        errors.append(f"範囲外座標の shelters が {bad_coord} 件")

    report["ok"] = not errors
    return report


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("使い方: python -m packgen.validate_pack <pack.sqlite>...")
        return 2
    failed = False
    for path in argv[1:]:
        report = validate_pack(path)
        print(json.dumps(report, ensure_ascii=False, indent=2))
        failed = failed or not report["ok"]
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
