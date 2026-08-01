# tools/ — データパック生成パイプライン（P0）

公開データから地域データパック（SQLite）を生成します。アプリ本体は完全オフラインで
動作し、通信はこのツール側だけが行います。

対象地域: 東京 (`tokyo`) / 千葉 (`chiba`) / 埼玉 (`saitama`) / 神奈川 (`kanagawa`)

## セットアップ

```bash
source tools/env.sh   # Takumi Guard ミラーを uv/pip に設定
cd tools && uv sync
brew install osmium-tool   # OSM PBF の県別切り出しに必要
```

## パック生成

```bash
cd tools
uv run python -m packgen.build_pack --region tokyo
# 全県一括
uv run python -m packgen.build_pack --all
```

生成物: `tools/out/<region>/pack.sqlite`（スキーマは要件定義書 §14 準拠）

## 検証

```bash
uv run python -m packgen.validate_pack tools/out/tokyo/pack.sqlite
uv run pytest            # ユニットテスト
```

## データソース（§21 準拠。全てパックの metadata テーブルに出典を記録）

| データ | 出典 |
|---|---|
| 指定緊急避難場所 | 国土地理院「避難所等データダウンロードサイト」（CSV） |
| 道路 | OpenStreetMap（Geofabrik japan-latest.osm.pbf、ODbL） |
| 洪水/土砂/高潮/津波 ハザード | 国土数値情報（A31/A33/A38/A40、GML） |
| 標高 | 国土地理院 標高タイル（DEM PNG） |

## 注意

- ダウンロードした生データは `tools/data/` にキャッシュされ、中断・再開に対応します。
- 取得できないハザード種別がある場合、グリッドは 0 埋めとなり `docs/progress.yaml` に記録します。
