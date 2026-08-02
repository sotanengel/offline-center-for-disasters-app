"""kbgen テスト用フィクスチャ。"""

from __future__ import annotations

from pathlib import Path

FIXTURE_DIR = Path(__file__).resolve().parent / "fixtures"


def sample_pages() -> list[tuple[int, str]]:
    return [
        (
            1,
            "心肺蘇生の基本\n"
            "意識がない人を発見したら、まず周囲の安全を確認する。\n"
            "119番または消防署に通報し、胸骨の真ん中を強く押す。\n"
            "人工呼吸は口と口で行い、胸が上がる程度に息を吹き込む。\n"
            "AEDがあれば電極パッドを貼り、音声案内に従う。",
        ),
        (
            2,
            "止血の方法\n"
            "出血している場合は直接圧迫を行う。\n"
            "きれいなガーゼや布で傷口を押さえ、15分以上圧迫を続ける。\n"
            "四肢の出血では患部を心臓より高く上げる。",
        ),
    ]
