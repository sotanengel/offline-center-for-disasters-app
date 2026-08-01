"""対象地域とデータソースの設定。"""
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Region:
    key: str
    pref_code: str   # 都道府県コード（11:埼玉 12:千葉 13:東京 14:神奈川）
    pref_name: str
    # (min_lng, min_lat, max_lng, max_lat)。東京は本土部のみ（離島は v1 対象外）
    bbox: tuple[float, float, float, float]


REGIONS: dict[str, Region] = {
    "saitama": Region("saitama", "11", "埼玉県", (138.68, 35.74, 139.91, 36.29)),
    "chiba": Region("chiba", "12", "千葉県", (139.70, 34.89, 140.89, 35.91)),
    "tokyo": Region("tokyo", "13", "東京都", (138.93, 35.49, 139.93, 35.91)),
    "kanagawa": Region("kanagawa", "14", "神奈川県", (138.92, 35.10, 139.81, 35.68)),
}

# 指定緊急避難場所（国土地理院 避難所等データダウンロードサイト、全国統合 CSV）
SHELTERS_URL = (
    "https://hinanmap.gsi.go.jp/hinanjocp/defaultFtpData/csv/mergeFromCity_2.csv"
)
SHELTERS_SOURCE = "国土地理院 指定緊急避難場所データ"

# OpenStreetMap（Geofabrik 日本全土。県別に bbox で切り出す）
OSM_PBF_URL = "https://download.geofabrik.de/asia/japan-latest.osm.pbf"
OSM_SOURCE = "OpenStreetMap contributors (ODbL) via Geofabrik"

# 国土数値情報ハザードデータ（県別 zip の URL を組み立てる）
NLFTP_BASE = "https://nlftp.mlit.go.jp/ksj/gml/data"


def hazard_url(dataset: str, series: str, pref_code: str) -> str:
    return f"{NLFTP_BASE}/{dataset}/{series}/{series}_{pref_code}_GML.zip"


# 洪水・土砂・高潮は 4 県共通のシリーズ
HAZARD_SERIES = {
    "flood": ("A31", "A31-12", "国土数値情報 洪水浸水想定区域データ（2012）"),
    "landslide": ("A33", "A33-18", "国土数値情報 土砂災害警戒区域データ（2018）"),
    "storm_surge": ("A38", "A38-14", "国土数値情報 高潮浸水想定区域データ（2014）"),
}

# 津波は県によって提供シリーズが異なる。東京・埼玉は国土数値情報に未提供
TSUNAMI_SERIES = {
    "chiba": ("A40", "A40-18", "国土数値情報 津波浸水想定データ（2018）"),
    "kanagawa": ("A40", "A40-16", "国土数値情報 津波浸水想定データ（2016）"),
}

ELEVATION_SOURCE = "国土地理院 標高タイル（DEM PNG）"
