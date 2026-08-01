#!/usr/bin/env bash
# 起動中のシミュレータのスクリーンショットを保存する。
# 使い方: tool/sim/screenshot.sh [出力ディレクトリ] [ファイル名プレフィックス]
# 出力: 保存したファイルパスを最終行に表示する。
set -euo pipefail

OUT_DIR="${1:-screenshots}"
PREFIX="${2:-shot}"
mkdir -p "${OUT_DIR}"
FILE="${OUT_DIR}/${PREFIX}-$(date +%Y%m%d-%H%M%S).png"
xcrun simctl io booted screenshot "${FILE}"
echo "${FILE}"
