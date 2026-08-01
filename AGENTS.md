# AGENTS.md — AI コーディングエージェント向け手順書

このリポジトリは「オフライン災害対応アプリ」（Flutter / iOS ファースト）です。
要件の唯一の正本は `オフライン災害対応アプリ_要件定義書`（2026-07-31 版）であり、
進捗は `docs/progress.yaml` で機械可読に管理します。

## 絶対ルール

1. **TDD**: テストを先に書き、失敗を確認してから実装する（Red → Green → Refactor）。
2. **進捗管理**: 実装着手時に `docs/progress.yaml` の該当項目を `in_progress`、
   PR マージ時に `done` + PR 番号へ更新する。新規項目は実装前に同ファイルへ追加する。
3. **ブランチ**: 作業は必ず `main` から切った `feature/*` ブランチで行い、PR は日本語で作成する。
   コミット・PR には機能 ID（F-xx）を記載する。
4. **人命に関わる原則**: 「動くが不正確」は「動かない」より有害。仕様の創作を禁止し、
   不明点は要件定義書 §17（未決事項）に記録してから実装する。
5. **オフライン**: アプリの実行パスにネットワーク通信を含めない（データ取得は `tools/` 側の責務）。

## よく使うコマンド

```bash
# 依存インストール
flutter pub get

# コード生成（freezed / drift / json_serializable）
dart run build_runner build --delete-conflicting-outputs

# 静的解析
flutter analyze

# フォーマット
dart format .

# ユニット / ウィジェットテスト
flutter test

# iPhone シミュレータの作成・起動（既定: iPhone SE 第3世代 = 性能下限想定）
tool/sim/boot.sh

# ユニットテスト + シミュレータ上の integration_test を一括実行
tool/sim/test.sh

# シミュレータのスクリーンショット取得（引数: 出力先ディレクトリ）
tool/sim/screenshot.sh screenshots

# シミュレータの画面録画
tool/sim/record.sh start out.mov
tool/sim/record.sh stop
```

## iPhone 動作テストの流れ（AI エージェント用）

1. `tool/sim/boot.sh` でシミュレータを起動する（最終行に UDID が出る）。
   - iOS ランタイムが無い場合は `xcodebuild -downloadPlatform iOS` を先に実行する。
2. アプリを起動して確認する場合:
   `flutter run -d <UDID>`（バックグラウンド実行推奨）
3. 画面確認は `tool/sim/screenshot.sh` で画像を保存して読む。
4. 自動シナリオは `integration_test/` に追加し、`flutter test integration_test -d <UDID>` で実行する。
5. 実機相当の性能下限は iPhone SE（第3世代）を使って再現する。

## ディレクトリ構成（要件定義書 §18 準拠）

- `lib/app/` … ルーティング、テーマ、DI
- `lib/core/` … geo / isolate / result など純粋ユーティリティ
- `lib/domain/` … エンティティ、§4 ポリシー、ユースケース
- `lib/data/` … DB(drift) / routing / search / rule / llm / sensor / pack
- `lib/presentation/` … 画面（home, result, nav, guide, settings, onboarding）と widgets
- `assets/kb/` … 監修済みガイド KB（guides.json）
- `assets/dict/` … キーワード辞書（keywords.json）
- `tools/` … データパック生成パイプライン（Python / uv）
- `tool/sim/` … iPhone シミュレータ操作用スクリプト
- `test/` … policy（決定表テーブル駆動）/ golden_slots / routing / integration
- `docs/progress.yaml` … 実装進捗の正

## CI / フック

- GitHub Actions: `.github/workflows/`（pinact で SHA ピン済み、zizmor で監査）
- pre-commit: `pre-commit install` 後に有効。dart format / analyze / yaml 検査が走る。
