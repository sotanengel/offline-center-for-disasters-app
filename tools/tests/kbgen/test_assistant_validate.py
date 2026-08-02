import json
from pathlib import Path

import pytest

from kbgen.validate import ValidationError, validate_assistant_kb, validate_chunks


def _minimal_sources() -> dict:
    return {
        "version": "1.0",
        "sources": [
            {
                "id": "fdma_oukyu",
                "title": "消防庁 応急手当",
                "url": "https://example.com/a.pdf",
                "category": "first_aid",
                "publisher": "消防庁",
            },
            {
                "id": "tfd_first_aid",
                "title": "東京消防庁",
                "url": "https://example.com/b.pdf",
                "category": "first_aid",
                "publisher": "東京消防庁",
            },
            {
                "id": "mhlw_guideline_110606",
                "title": "厚労省ガイドライン",
                "url": "https://example.com/c.pdf",
                "category": "shelter_health",
                "publisher": "厚労省",
            },
            {
                "id": "mhlw_disaster_0415",
                "title": "被災地健康",
                "url": "https://example.com/d.pdf",
                "category": "shelter_health",
                "publisher": "厚労省",
            },
            {
                "id": "bousai_teiden",
                "title": "停電対策",
                "url": "https://example.com/e.html",
                "category": "utilities",
                "publisher": "内閣府",
            },
            {
                "id": "tokyo_kb_ch2",
                "title": "第2章",
                "url": "https://example.com/f.pdf",
                "category": "post_disaster_action",
                "publisher": "東京都",
            },
            {
                "id": "tokyo_kb_ch3",
                "title": "第3章",
                "url": "https://example.com/g.pdf",
                "category": "post_disaster_action",
                "publisher": "東京都",
            },
            {
                "id": "tokyo_tb_tips",
                "title": "Tips",
                "url": "https://example.com/h.pdf",
                "category": "disaster_tips",
                "publisher": "東京都",
            },
        ],
    }


def _chunk(cid: str, source_id: str, title: str, content: str) -> dict:
    return {
        "id": cid,
        "sourceId": source_id,
        "title": title,
        "category": "first_aid",
        "tags": ["first_aid", "止血"],
        "content": content,
        "pageRef": "p.1",
    }


def test_validate_rejects_too_few_chunks(tmp_path: Path):
    chunks_path = tmp_path / "chunks.json"
    chunks_path.write_text(
        json.dumps({"version": "1.0", "chunks": []}, ensure_ascii=False),
        encoding="utf-8",
    )
    with pytest.raises(ValidationError, match="need >="):
        validate_assistant_kb(chunks_path)


def test_validate_accepts_minimal_valid_set(tmp_path: Path):
    sources_path = tmp_path / "sources.json"
    chunks_path = tmp_path / "chunks.json"
    sources_path.write_text(json.dumps(_minimal_sources(), ensure_ascii=False), encoding="utf-8")

    chunks = []
    for i in range(50):
        chunks.append(
            _chunk(
                f"fdma_oukyu_{i:03d}",
                "fdma_oukyu",
                f"止血の手順 {i}",
                "出血している場合は直接圧迫を行い、15分以上圧迫を続ける。" * 2,
            )
        )
    chunks_path.write_text(
        json.dumps({"version": "1.0", "chunks": chunks}, ensure_ascii=False),
        encoding="utf-8",
    )
    validate_assistant_kb(chunks_path, sources_path)


def test_validate_rejects_duplicate_chunk_ids(tmp_path: Path):
    chunks = [
        _chunk("dup", "fdma_oukyu", "a", "content " * 20),
        _chunk("dup", "fdma_oukyu", "b", "content " * 20),
    ]
    for i in range(48):
        chunks.append(
            _chunk(
                f"other_{i:03d}",
                "fdma_oukyu",
                f"t{i}",
                "content " * 20,
            )
        )
    data = {"version": "1.0", "chunks": chunks}
    with pytest.raises(ValidationError, match="duplicate"):
        validate_chunks(data)
