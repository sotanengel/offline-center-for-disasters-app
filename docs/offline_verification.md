# オフライン動作確認手順（§20.5）

アプリの実行パス（`lib/`）にネットワーク通信は含まれません。以下は実機またはシミュレータでの手動確認手順です。

## 前提

- iPhone SE（第3世代）相当のシミュレータを推奨（性能下限）
- データパックは事前に同梱またはローカル配置済み

## 手順

1. **機内モードを ON** にする（設定 → 機内モード）
2. アプリを起動する（`flutter run -d <UDID>` または Xcode から）
3. **S-01 ホーム**: 災害タイル 7 種（津波〜噴火）が表示されること
4. **津波タイルを 1 タップ** → S-02 結果サマリへ遷移
5. **「案内を開始する」**（72dp）をタップ → S-03 経路案内へ遷移
6. 地図領域に Polyline が表示されること（タイル DL 不要）

## 自動テスト

```bash
# ユニット / ウィジェット
flutter analyze && flutter test

# lib/ オフライン import 静的チェック
tool/check_offline_imports.sh

# シミュレータ integration_test（要 boot.sh）
tool/sim/boot.sh
flutter test integration_test -d <UDID>
```

## CI

`.github/workflows/ci.yml` の `offline-imports` ジョブが `lib/` の http/dio 等 import を禁止します。
