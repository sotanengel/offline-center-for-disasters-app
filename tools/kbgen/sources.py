"""アシスタント KB 対象資料の定義。"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

SourceCategory = Literal[
    "first_aid",
    "shelter_health",
    "utilities",
    "post_disaster_action",
    "disaster_tips",
]

SourceKind = Literal["pdf", "html"]


@dataclass(frozen=True)
class SourceDef:
    id: str
    title: str
    url: str
    category: SourceCategory
    kind: SourceKind
    publisher: str


ASSISTANT_SOURCES: tuple[SourceDef, ...] = (
    SourceDef(
        id="fdma_oukyu",
        title="消防庁 応急手当WEB講習 コンテンツ概要",
        url="https://www.fdma.go.jp/relocation/kyukyukikaku/oukyu/img/manual.pdf",
        category="first_aid",
        kind="pdf",
        publisher="消防庁",
    ),
    SourceDef(
        id="tfd_first_aid",
        title="東京消防庁「命を救う応急手当」",
        url="https://www.tfd.metro.tokyo.lg.jp/content/000035496.pdf",
        category="first_aid",
        kind="pdf",
        publisher="東京消防庁",
    ),
    SourceDef(
        id="mhlw_guideline_110606",
        title="避難所生活を過ごされる方々の健康管理に関するガイドライン",
        url="https://www.mhlw.go.jp/bunya/kenkou/dl/guideline_110606.pdf",
        category="shelter_health",
        kind="pdf",
        publisher="厚生労働省",
    ),
    SourceDef(
        id="mhlw_disaster_0415",
        title="被災地での健康を守るために",
        url="https://www.mhlw.go.jp/bunya/kenkou/hoken-sidou/dl/disaster_0415.pdf",
        category="shelter_health",
        kind="pdf",
        publisher="厚生労働省",
    ),
    SourceDef(
        id="bousai_teiden",
        title="地震直後の停電対策",
        url="https://www.bousai.go.jp/jishin/syuto/denkikasaitaisaku/teidentaisaku.html",
        category="utilities",
        kind="html",
        publisher="内閣府",
    ),
    SourceDef(
        id="tokyo_kb_ch2",
        title="東京くらし防災 第2章「いま」災害が起きたら？",
        url="https://www.bousai.metro.tokyo.lg.jp/_res/common/2023_bk/kb/kb2023_0-00_090_151.pdf",
        category="post_disaster_action",
        kind="pdf",
        publisher="東京都",
    ),
    SourceDef(
        id="tokyo_kb_ch3",
        title="東京くらし防災 第3章 発災後のくらし",
        url="https://www.bousai.metro.tokyo.lg.jp/_res/common/2023_bk/kb/kb2023_000_152_179.pdf",
        category="post_disaster_action",
        kind="pdf",
        publisher="東京都",
    ),
    SourceDef(
        id="tokyo_tb_tips",
        title="東京防災 もしもの防災Tips・知っておきたい災害知識",
        url="https://www.bousai.metro.tokyo.lg.jp/_res/common/2023_bk/tb/tb2023_208_275n.pdf",
        category="disaster_tips",
        kind="pdf",
        publisher="東京都",
    ),
)

CATEGORY_LABELS: dict[SourceCategory, str] = {
    "first_aid": "応急手当・救命",
    "shelter_health": "避難所生活での健康管理",
    "utilities": "停電・断水への即応",
    "post_disaster_action": "発災後の行動",
    "disaster_tips": "災害知識・Tips",
}
