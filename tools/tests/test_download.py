"""中断・再開対応ダウンローダのテスト。"""
import pytest

from packgen.download import DownloadError, download


class FakeResponse:
    def __init__(self, status_code, body=b"", headers=None):
        self.status_code = status_code
        self.body = body
        self.headers = headers or {}

    def iter_content(self, chunk_size):
        for i in range(0, len(self.body), chunk_size):
            yield self.body[i : i + chunk_size]

    def raise_for_status(self):
        if self.status_code >= 400:
            raise DownloadError(f"HTTP {self.status_code}")

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False


class FakeSession:
    def __init__(self, responses):
        self.responses = responses
        self.requests = []

    def get(self, url, headers=None, stream=False, timeout=None):
        self.requests.append((url, headers or {}))
        status, body = self.responses[url]
        return FakeResponse(status, body)


def test_download_writes_file(tmp_path):
    session = FakeSession({"http://x/f": (200, b"hello")})
    out = download("http://x/f", tmp_path / "f.bin", session=session)
    assert out.read_bytes() == b"hello"


def test_download_skips_when_complete(tmp_path):
    dest = tmp_path / "f.bin"
    dest.write_bytes(b"hello")
    session = FakeSession({})
    download("http://x/f", dest, session=session)
    assert session.requests == []  # 既に完全なら要求しない


def test_download_resumes_partial(tmp_path):
    dest = tmp_path / "f.bin"
    dest.write_bytes(b"hel")
    session = FakeSession({"http://x/f": (206, b"lo")})
    download("http://x/f", dest, session=session, expected_size=5)
    assert dest.read_bytes() == b"hello"
    assert session.requests[0][1].get("Range") == "bytes=3-"


def test_download_404_raises(tmp_path):
    session = FakeSession({"http://x/missing": (404, b"")})
    with pytest.raises(DownloadError):
        download("http://x/missing", tmp_path / "m.bin", session=session)
