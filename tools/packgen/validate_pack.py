"""生成パックの検証。スキーマ適合・整合性・件数・欠損率を検査し JSON レポートを返す。"""
from __future__ import annotations

import argparse
import json
import sqlite3
import sys
from pathlib import Path

REQUIRED_TABLES = ["shelters", "shelters_rtree", "nodes", "edges", "hazard_grid", "metadata"]

ALL_FLAGS = [
    "ok_flood", "ok_landslide", "ok_storm_surge", "ok_earthquake",
    "ok_tsunami", "ok_fire", "ok_inland_flood", "ok_volcano",
]

# 各ハザード種別 → hazard_grid の対応列（NULL/0 検査用）
HAZARD_COLUMNS = {
    "flood": "flood_depth_m",
    "tsunami": "tsunami_depth_m",
    "landslide": "landslide_class",
    "storm_surge": "storm_surge_m",
    "volcano": "volcano_class",
}


from packgen.config import ALLOWED_MISSING_HAZARDS


def _allowed_missing_for_pack(pack_path: str | Path) -> list[str] | None:
    """metadata.region から県別許容欠損ハザードを解決する。region 不明時は None。"""
    db = sqlite3.connect(str(pack_path))
    try:
        row = db.execute(
            "SELECT value FROM metadata WHERE key = 'region'"
        ).fetchone()
    finally:
        db.close()
    if row is None:
        return None
    return list(ALLOWED_MISSING_HAZARDS.get(row[0], ()))


def validate_pack(
    pack_path: str | Path,
    *,
    elevation_null_rate_threshold: float | None = None,
    allowed_missing_hazards: list[str] | tuple[str, ...] | None = None,
) -> dict:
    """パックを検証する。

    Args:
        elevation_null_rate_threshold: nodes.elevation_m と shelters.elevation_m の
            NULL 率がこの値を超えたら NG。None なら未検査。
        allowed_missing_hazards: hazard_grid で該当列が全て 0 でも良いハザード種別。
            例: 埼玉の 'storm_surge'、東京・埼玉の 'tsunami'。
    """
    errors: list[str] = []
    report: dict = {"pack": str(pack_path), "ok": False, "counts": {}, "errors": errors}
    # allowed_missing_hazards が明示指定された場合のみ、種別ごとの 0 セル検査を有効化。
    # None（既定）では hazard_grid の総件数のみ検査する（後方互換）。
    enforce_hazard_kinds = allowed_missing_hazards is not None
    allowed_missing = set(allowed_missing_hazards or [])

    db = sqlite3.connect(str(pack_path))
    tables = {
        r[0]
        for r in db.execute(
            "SELECT name FROM sqlite_master WHERE type IN ('table','virtual table')"
        )
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
        if count == 0:
            # hazard_grid も含めて 0 件は許容しない（P0: 東京パックが 0 セルだった不具合）
            errors.append(f"{table} が 0 件です")

    # ハザード種別ごとの件数を報告し、許容種別以外で 0 件なら NG
    hazard_counts: dict[str, int] = {}
    for kind, column in HAZARD_COLUMNS.items():
        n = db.execute(
            f"SELECT COUNT(*) FROM hazard_grid WHERE {column} IS NOT NULL AND {column} > 0"
        ).fetchone()[0]
        hazard_counts[kind] = n
        if enforce_hazard_kinds and n == 0 and kind not in allowed_missing:
            errors.append(f"hazard_grid.{column}: {kind} が 1 件も見つかりません")
    report["hazard_counts"] = hazard_counts

    # 標高 NULL 率
    if elevation_null_rate_threshold is not None:
        elev_stats: dict[str, dict[str, float]] = {}
        for table in ("nodes", "shelters"):
            total = db.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
            if total == 0:
                continue
            null_n = db.execute(
                f"SELECT COUNT(*) FROM {table} WHERE elevation_m IS NULL"
            ).fetchone()[0]
            rate = null_n / total
            elev_stats[table] = {"total": total, "null": null_n, "null_rate": rate}
            if rate > elevation_null_rate_threshold:
                errors.append(
                    f"{table}.elevation_m の NULL 率 {rate:.1%} が閾値 "
                    f"{elevation_null_rate_threshold:.0%} を超過（NULL={null_n}/{total}）"
                )
        report["elevation_stats"] = elev_stats

    # R*Tree と shelters の件数一致
    rtree = db.execute("SELECT COUNT(*) FROM shelters_rtree").fetchone()[0]
    if rtree != report["counts"]["shelters"]:
        errors.append(
            f"shelters_rtree ({rtree}) と shelters ({report['counts']['shelters']}) の件数不一致"
        )

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

    # is_all_hazard 派生列の一貫性
    cond = " AND ".join(f"{f} = 1" for f in ALL_FLAGS)
    bad = db.execute(
        f"SELECT COUNT(*) FROM shelters WHERE is_all_hazard != CASE WHEN {cond} THEN 1 ELSE 0 END"
    ).fetchone()[0]
    if bad:
        errors.append(f"is_all_hazard の不整合が {bad} 件")

    # 座標の妥当性
    bad_coord = db.execute(
        "SELECT COUNT(*) FROM shelters WHERE lat < 20 OR lat > 46 OR lng < 122 OR lng > 154"
    ).fetchone()[0]
    if bad_coord:
        errors.append(f"範囲外座標の shelters が {bad_coord} 件")

    report["ok"] = not errors
    return report


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="生成パックの検証")
    parser.add_argument("packs", nargs="+", help="pack.sqlite ファイル群")
    parser.add_argument(
        "--elevation-null-rate", type=float, default=0.1,
        help="標高 NULL 率の許容上限（既定 0.1 = 10%%）",
    )
    parser.add_argument(
        "--allow-missing",
        action="append",
        default=None,
        help="ハザード欠損を許容する種別（未指定時は metadata.region から自動）",
    )
    args = parser.parse_args(argv)
    failed = False
    for path in args.packs:
        allowed = args.allow_missing
        if allowed is None:
            allowed = _allowed_missing_for_pack(path)
        report = validate_pack(
            path,
            elevation_null_rate_threshold=args.elevation_null_rate,
            allowed_missing_hazards=allowed,
        )
        print(json.dumps(report, ensure_ascii=False, indent=2))
        failed = failed or not report["ok"]
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
