from kbgen.chunk import chunk_pages
from kbgen.sources import ASSISTANT_SOURCES


def _sample_pages():
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
            "出血している場合は直接圧迫を行う。きれいなガーゼや布で傷口を押さえ、"
            "15分以上圧迫を続ける。上記を繰り返しても止血しない場合は止血帯を使用する。"
            "四肢の出血では患部を心臓より高く上げ、患者を安静に保つ。",
        ),
    ]


def test_chunk_pages_produces_searchable_chunks():
    source = ASSISTANT_SOURCES[0]
    chunks = chunk_pages(source, _sample_pages())
    assert len(chunks) >= 2
    assert all(len(c.content) >= 40 for c in chunks)
    assert any("心肺蘇生" in c.content or "心肺蘇生" in c.title for c in chunks)
    assert any("止血" in c.content or "止血" in c.title for c in chunks)


def test_chunk_ids_are_unique():
    source = ASSISTANT_SOURCES[0]
    chunks = chunk_pages(source, _sample_pages())
    ids = [c.id for c in chunks]
    assert len(ids) == len(set(ids))
