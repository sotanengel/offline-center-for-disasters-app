"""中断・再開に対応したダウンローダ。"""
from __future__ import annotations

from pathlib import Path

import requests


class DownloadError(Exception):
    pass


def download(
    url: str,
    dest: str | Path,
    *,
    session=None,
    expected_size: int | None = None,
    timeout: int = 60,
) -> Path:
    """url を dest へ保存する。既に完全なファイルがあればスキップし、
    部分的なファイルがあれば Range リクエストで再開する。
    """
    dest = Path(dest)
    dest.parent.mkdir(parents=True, exist_ok=True)
    session = session or requests.Session()

    if dest.exists():
        size = dest.stat().st_size
        if expected_size is not None and size == expected_size:
            return dest
        if expected_size is None and size > 0:
            return dest  # サイズ不明の場合は存在をもって完了とみなす
    else:
        size = 0

    headers = {}
    mode = "wb"
    if size > 0 and expected_size is not None and size < expected_size:
        headers["Range"] = f"bytes={size}-"
        mode = "ab"

    resp = session.get(url, headers=headers, stream=True, timeout=timeout)
    if resp.status_code >= 400:
        raise DownloadError(f"HTTP {resp.status_code}: {url}")
    # Range 非対応で 200 が返った場合は最初から書き直す
    if mode == "ab" and resp.status_code == 200:
        mode = "wb"
    with open(dest, mode) as f:
        for chunk in resp.iter_content(chunk_size=1 << 20):
            f.write(chunk)
    return dest
