# オフライン災害対応センター（offline-center-for-disasters）

完全オフラインで、最小の入力から「今どこへ逃げるか」と「今何をするか」を提示する
災害対応アプリ（Flutter / iOS ファースト）。

- 要件の正本: `オフライン災害対応アプリ_要件定義書`（2026-07-31 版）
- 実装進捗: [docs/progress.yaml](docs/progress.yaml)（機械可読。PR ごとに更新）
- AI エージェント向け手順: [AGENTS.md](AGENTS.md)

## セットアップ

```bash
flutter pub get
pre-commit install   # コミット前フックを有効化
```

## テスト

```bash
flutter test          # ユニット / ウィジェットテスト
tool/sim/test.sh      # 上記 + iPhone シミュレータでの integration_test
```

iPhone シミュレータ操作（起動・スクリーンショット・録画）は `tool/sim/` を参照。

## データパック

避難所 DB・道路グラフ・ハザードグリッド等の地域データは `tools/` のパイプラインで
公開データ（OpenStreetMap / 国土数値情報 / 国土地理院）から生成します（対象: 東京・千葉・埼玉・神奈川）。

## ライセンス

[LICENSE](LICENSE) を参照。データ出典はアプリ内「データ出典・ライセンス」画面に明記します。
