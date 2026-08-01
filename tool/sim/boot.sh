#!/usr/bin/env bash
# iPhone シミュレータを作成・起動する。
# 性能下限の再現用に既定は iPhone SE (3rd generation)。
# 使い方: tool/sim/boot.sh [デバイス名]
# 出力: 最終行に起動したシミュレータの UDID を表示する。
set -euo pipefail

DEVICE_NAME="${1:-iPhone SE (3rd generation)}"

RUNTIME=$(xcrun simctl list runtimes available | grep -o 'com.apple.CoreSimulator.SimRuntime.iOS[^ ]*' | sort -V | tail -1 || true)
if [[ -z "${RUNTIME}" ]]; then
  echo "エラー: iOS ランタイムが見つかりません。次を実行してください:" >&2
  echo "  xcodebuild -downloadPlatform iOS" >&2
  exit 1
fi

DEVICE_UDID=$(xcrun simctl list devices available | grep -F "${DEVICE_NAME}" | head -1 | grep -oE '[0-9A-Fa-f-]{36}' || true)
if [[ -z "${DEVICE_UDID}" ]]; then
  echo "シミュレータを作成します: ${DEVICE_NAME} (${RUNTIME})"
  DEVICE_UDID=$(xcrun simctl create "${DEVICE_NAME}" "${DEVICE_NAME}" "${RUNTIME}")
fi

STATE=$(xcrun simctl list devices | grep -F "${DEVICE_UDID}" | grep -o 'Booted' || true)
if [[ -z "${STATE}" ]]; then
  echo "起動します: ${DEVICE_NAME} (${DEVICE_UDID})"
  xcrun simctl boot "${DEVICE_UDID}"
fi
open -a Simulator || true
xcrun simctl bootstatus "${DEVICE_UDID}" -b
echo "${DEVICE_UDID}"
