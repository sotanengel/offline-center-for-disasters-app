#!/usr/bin/env bash
# 起動中のシミュレータの画面録画を開始/停止する。
# 使い方:
#   tool/sim/record.sh start [出力ファイル]   # 録画開始（バックグラウンド）
#   tool/sim/record.sh stop                   # 録画停止
set -euo pipefail

PID_FILE="/tmp/ocd-sim-record.pid"
OUT_FILE="/tmp/ocd-sim-record.mov"

case "${1:-}" in
  start)
    OUT_FILE="${2:-${OUT_FILE}}"
    xcrun simctl io booted recordVideo "${OUT_FILE}" &
    echo $! > "${PID_FILE}"
    echo "録画開始: ${OUT_FILE} (PID: $(cat "${PID_FILE}"))"
    ;;
  stop)
    if [[ -f "${PID_FILE}" ]]; then
      kill -SIGINT "$(cat "${PID_FILE}")" || true
      rm -f "${PID_FILE}"
      echo "録画停止: ${OUT_FILE}"
    else
      echo "録画は開始されていません" >&2
      exit 1
    fi
    ;;
  *)
    echo "使い方: $0 {start [出力ファイル]|stop}" >&2
    exit 1
    ;;
esac
