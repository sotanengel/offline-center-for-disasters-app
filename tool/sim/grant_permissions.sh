#!/usr/bin/env bash
# シミュレータ起動時の権限ダイアログを抑止するため、テスト用に権限を事前付与する。
# 使い方: tool/sim/grant_permissions.sh [UDID]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

BUNDLE_ID="${SIM_APP_BUNDLE_ID:-dev.offlinecenter.offlineCenterForDisasters}"
UDID="${1:-}"

if [[ -z "${UDID}" ]]; then
  UDID="$(xcrun simctl list devices booted | grep -oE '[0-9A-Fa-f-]{36}' | head -1 || true)"
fi
if [[ -z "${UDID}" ]]; then
  sim_log_error "permissions" "no booted simulator; run tool/sim/boot.sh first"
  exit "${SIM_EXIT_SHUTDOWN}"
fi

sim_log_info "permissions" "udid=${UDID} bundle=${BUNDLE_ID}"

grant() {
  local service="$1"
  if xcrun simctl privacy "${UDID}" grant "${service}" "${BUNDLE_ID}" 2>/dev/null; then
    sim_log_info "permissions" "granted service=${service}"
  else
    sim_log_warn "permissions" "grant failed service=${service}"
  fi
}

grant location
grant location-always
grant microphone
grant motion

# シミュレータ / 統合テスト想定座標（kDefaultOrigin と整合）
if xcrun simctl location "${UDID}" set 35.687741,139.850977 2>/dev/null; then
  sim_log_info "permissions" "location_set=35.687741,139.850977"
else
  sim_log_warn "permissions" "simctl location set failed"
fi

sim_log_info "permissions" "done"
