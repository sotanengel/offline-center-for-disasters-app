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

## 同梱用統合パック（bundled）

県別生成後、リリースビルド時に 1 ファイルへマージします（アプリ実行時は都道府県を意識しない）。

```bash
cd tools
uv run python -m packgen.merge_pack
# 出力: tools/out/bundled/pack.sqlite（metadata.merged_from に含まれる県を記録）

# アプリ assets へ配置（4県 out が前提）
tool/build/prepare_bundled_packs.sh
```

`--region` でマージ対象県を指定可能（将来の県追加時は `packgen.config.REGIONS` に追加して merge）。

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
