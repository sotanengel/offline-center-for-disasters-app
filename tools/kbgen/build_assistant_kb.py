"""assistant KB をビルドして assets に書き出す。"""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from pathlib import Path

from .chunk import ChunkDraft, chunk_pages
from .extract import extract_source_pages
from .sources import ASSISTANT_SOURCES, CATEGORY_LABELS
from .validate import validate_assistant_kb


@dataclass(frozen=True)
class BuildConfig:
    cache_dir: Path
    assets_dir: Path


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def default_config() -> BuildConfig:
    root = _repo_root()
    return BuildConfig(
        cache_dir=root / "tools" / "data" / "kb_raw",
        assets_dir=root / "assets" / "kb" / "assistant",
    )


def build_sources_json() -> dict:
    return {
        "version": "1.0",
        "categories": [
            {"id": k, "label": v} for k, v in CATEGORY_LABELS.items()
        ],
        "sources": [
            {
                "id": s.id,
                "title": s.title,
                "url": s.url,
                "category": s.category,
                "publisher": s.publisher,
            }
            for s in ASSISTANT_SOURCES
        ],
    }


def _draft_to_dict(d: ChunkDraft) -> dict:
    return {
        "id": d.id,
        "sourceId": d.source_id,
        "title": d.title,
        "category": d.category,
        "tags": d.tags,
        "content": d.content,
        "pageRef": d.page_ref,
    }


def build_chunks(config: BuildConfig | None = None) -> list[ChunkDraft]:
    config = config or default_config()
    all_chunks: list[ChunkDraft] = []
    for source in ASSISTANT_SOURCES:
        pages = extract_source_pages(source, config.cache_dir)
        all_chunks.extend(chunk_pages(source, pages))
    return all_chunks


def write_assistant_kb(config: BuildConfig | None = None) -> tuple[Path, Path]:
    config = config or default_config()
    config.assets_dir.mkdir(parents=True, exist_ok=True)

    sources = build_sources_json()
    chunks = build_chunks(config)

    sources_path = config.assets_dir / "sources.json"
    chunks_path = config.assets_dir / "chunks.json"

    sources_path.write_text(
        json.dumps(sources, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    chunks_path.write_text(
        json.dumps(
            {"version": "1.0", "chunks": [_draft_to_dict(c) for c in chunks]},
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    validate_assistant_kb(chunks_path, sources_path)
    return sources_path, chunks_path


def main() -> None:
    sources_path, chunks_path = write_assistant_kb()
    chunk_count = len(json.loads(chunks_path.read_text(encoding="utf-8"))["chunks"])
    print(f"Wrote {sources_path} and {chunks_path} ({chunk_count} chunks)")


if __name__ == "__main__":
    main()
