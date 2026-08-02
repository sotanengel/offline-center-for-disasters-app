"""PDF / HTML からプレーンテキストを抽出する。"""

from __future__ import annotations

from pathlib import Path

import fitz
import requests
from bs4 import BeautifulSoup

from .sources import SourceDef


def download_source(source: SourceDef, cache_dir: Path) -> Path:
    cache_dir.mkdir(parents=True, exist_ok=True)
    ext = "html" if source.kind == "html" else "pdf"
    dest = cache_dir / f"{source.id}.{ext}"
    if dest.exists() and dest.stat().st_size > 0:
        return dest
    resp = requests.get(source.url, timeout=120)
    resp.raise_for_status()
    dest.write_bytes(resp.content)
    return dest


def extract_pdf_text(path: Path) -> list[tuple[int, str]]:
    doc = fitz.open(path)
    pages: list[tuple[int, str]] = []
    for i, page in enumerate(doc, start=1):
        text = page.get_text("text").strip()
        if text:
            pages.append((i, text))
    doc.close()
    return pages


def extract_html_text(path: Path) -> list[tuple[int, str]]:
    html = path.read_text(encoding="utf-8", errors="replace")
    soup = BeautifulSoup(html, "html.parser")
    for tag in soup(["script", "style", "nav", "footer", "header"]):
        tag.decompose()
    text = soup.get_text("\n", strip=True)
    return [(1, text)] if text else []


def extract_source_pages(source: SourceDef, cache_dir: Path) -> list[tuple[int, str]]:
    path = download_source(source, cache_dir)
    if source.kind == "pdf":
        return extract_pdf_text(path)
    return extract_html_text(path)
