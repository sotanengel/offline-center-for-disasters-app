"""抽出テキストを検索用チャンクに分割する。"""

from __future__ import annotations

import re
from dataclasses import dataclass

from .sources import SourceCategory, SourceDef

MIN_CHUNK_LEN = 80
TARGET_CHUNK_LEN = 400
MAX_CHUNK_LEN = 650

_HEADING_RE = re.compile(
    r"^(第[0-9一二三四五六七八九十]+[章節]|"
    r"[0-9０-９]+[\.．、]\s*|"
    r"[●■◆▶▷]|"
    r".{2,20}(?:について|のポイント|の方法|の手順|の予防|の対策|の基本))$"
)


@dataclass(frozen=True)
class ChunkDraft:
    id: str
    source_id: str
    title: str
    category: SourceCategory
    tags: list[str]
    content: str
    page_ref: str | None


def _normalize(text: str) -> str:
    text = text.replace("\u3000", " ")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def _split_paragraphs(text: str) -> list[str]:
    parts = re.split(r"\n+", _normalize(text))
    return [p.strip() for p in parts if p.strip()]


def _is_body_paragraph(para: str) -> bool:
    return len(para) >= 20 or _is_heading(para)


def _is_heading(line: str) -> bool:
    s = line.strip()
    if len(s) < 4 or len(s) > 40:
        return False
    if _HEADING_RE.match(s):
        return True
    if s.endswith("）") and len(s) <= 30:
        return True
    return False


def _guess_tags(title: str, content: str, category: SourceCategory) -> list[str]:
    tags = [category]
    keywords = [
        "止血",
        "心肺蘇生",
        "AED",
        "応急手当",
        "避難所",
        "感染症",
        "エコノミークラス",
        "熱中症",
        "低体温",
        "一酸化炭素",
        "停電",
        "断水",
        "トイレ",
        "血栓",
        "避難",
        "火災",
        "地震",
        "津波",
        "水",
        "食料",
        "衛生",
    ]
    blob = f"{title} {content}"
    for kw in keywords:
        if kw in blob and kw not in tags:
            tags.append(kw)
    return tags[:8]


def _flush_buffer(
    *,
    source: SourceDef,
    seq: int,
    heading: str,
    parts: list[str],
    page: int,
) -> ChunkDraft | None:
    content = "\n".join(parts).strip()
    if len(content) < MIN_CHUNK_LEN:
        return None
    title = heading if heading else content[:40].rstrip("。、 ") + "…"
    chunk_id = f"{source.id}_{seq:03d}"
    return ChunkDraft(
        id=chunk_id,
        source_id=source.id,
        title=title[:80],
        category=source.category,
        tags=_guess_tags(title, content, source.category),
        content=content[:MAX_CHUNK_LEN],
        page_ref=f"p.{page}",
    )


def chunk_pages(source: SourceDef, pages: list[tuple[int, str]]) -> list[ChunkDraft]:
    drafts: list[ChunkDraft] = []
    seq = 1
    heading = source.title
    buffer: list[str] = []
    page = 1

    def flush() -> None:
        nonlocal seq, buffer, page
        draft = _flush_buffer(
            source=source,
            seq=seq,
            heading=heading,
            parts=buffer,
            page=page,
        )
        if draft:
            drafts.append(draft)
            seq += 1
        buffer = []

    for page_num, page_text in pages:
        page = page_num
        for para in _split_paragraphs(page_text):
            if _is_heading(para):
                flush()
                heading = para
                continue
            if not _is_body_paragraph(para):
                continue
            buffer.append(para)
            joined = "\n".join(buffer)
            if len(joined) >= TARGET_CHUNK_LEN:
                flush()

    flush()

    # 長すぎる段落を強制分割
    final: list[ChunkDraft] = []
    for d in drafts:
        if len(d.content) <= MAX_CHUNK_LEN:
            final.append(d)
            continue
        start = 0
        part = 1
        while start < len(d.content):
            piece = d.content[start : start + MAX_CHUNK_LEN]
            if len(piece) >= MIN_CHUNK_LEN:
                final.append(
                    ChunkDraft(
                        id=f"{d.id}_p{part}",
                        source_id=d.source_id,
                        title=f"{d.title} ({part})",
                        category=d.category,
                        tags=d.tags,
                        content=piece,
                        page_ref=d.page_ref,
                    )
                )
                part += 1
            start += MAX_CHUNK_LEN

    return final
