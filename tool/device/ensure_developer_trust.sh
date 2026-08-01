#!/usr/bin/env bash
# 実機で開発者証明書が信頼済みか確認する。
# 使い方: tool/device/ensure_developer_trust.sh [UDID|device-name]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

DEVICE="${1:-}"
BUNDLE_ID="${DEVICE_APP_BUNDLE_ID:-dev.offlinecenter.offlineCenterForDisasters}"

if [[ -z "${DEVICE}" ]]; then
  DEVICE="$(flutter devices 2>/dev/null | awk '/ios.*mobile/ && $0 !~ /simulator/ { print $NF; exit }' | tr -d '•' | xargs || true)"
fi
if [[ -z "${DEVICE}" ]]; then
  device_log "error no connected iOS device"
  exit "${DEVICE_EXIT_NO_DEVICE}"
fi

device_assert_developer_trusted "${DEVICE}" "${BUNDLE_ID}"
