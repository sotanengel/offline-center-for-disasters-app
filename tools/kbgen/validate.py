"""assistant KB JSON の検証。"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .sources import ASSISTANT_SOURCES, CATEGORY_LABELS

MIN_CHUNK_COUNT = 50
REQUIRED_SOURCE_IDS = {s.id for s in ASSISTANT_SOURCES}
VALID_CATEGORIES = set(CATEGORY_LABELS.keys())


class ValidationError(Exception):
    pass


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def validate_sources(data: dict[str, Any]) -> None:
    sources = data.get("sources")
    _require(isinstance(sources, list), "sources must be a list")
    ids = set()
    for item in sources:
        _require(isinstance(item, dict), "each source must be an object")
        sid = item.get("id")
        _require(isinstance(sid, str) and sid, "source.id required")
        _require(sid not in ids, f"duplicate source id: {sid}")
        ids.add(sid)
        _require(item.get("category") in VALID_CATEGORIES, f"invalid category: {sid}")
        _require(isinstance(item.get("title"), str) and item["title"], f"title required: {sid}")
        _require(isinstance(item.get("url"), str) and item["url"], f"url required: {sid}")
    _require(
        REQUIRED_SOURCE_IDS.issubset(ids),
        f"missing sources: {sorted(REQUIRED_SOURCE_IDS - ids)}",
    )


def validate_chunks(data: dict[str, Any], sources_path: Path | None = None) -> None:
    chunks = data.get("chunks")
    _require(isinstance(chunks, list), "chunks must be a list")
    _require(len(chunks) >= MIN_CHUNK_COUNT, f"need >= {MIN_CHUNK_COUNT} chunks")

    source_ids = REQUIRED_SOURCE_IDS
    if sources_path and sources_path.exists():
        with sources_path.open(encoding="utf-8") as f:
            src = json.load(f)
        validate_sources(src)
        source_ids = {s["id"] for s in src["sources"]}

    seen: set[str] = set()
    for item in chunks:
        _require(isinstance(item, dict), "each chunk must be an object")
        cid = item.get("id")
        _require(isinstance(cid, str) and cid, "chunk.id required")
        _require(cid not in seen, f"duplicate chunk id: {cid}")
        seen.add(cid)
        _require(item.get("sourceId") in source_ids, f"unknown sourceId: {cid}")
        _require(item.get("category") in VALID_CATEGORIES, f"invalid category: {cid}")
        _require(isinstance(item.get("title"), str) and item["title"], f"title required: {cid}")
        content = item.get("content")
        _require(isinstance(content, str) and len(content.strip()) >= 40, f"content too short: {cid}")
        tags = item.get("tags")
        _require(isinstance(tags, list) and tags, f"tags required: {cid}")


def validate_assistant_kb(
    chunks_path: Path,
    sources_path: Path | None = None,
) -> None:
    with chunks_path.open(encoding="utf-8") as f:
        chunks_data = json.load(f)
    validate_chunks(chunks_data, sources_path)
    if sources_path:
        with sources_path.open(encoding="utf-8") as f:
            sources_data = json.load(f)
        validate_sources(sources_data)
