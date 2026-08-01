#!/usr/bin/env bash
# シミュレータのヘルスチェック（起動状態・ランタイム・UDID）。
# 使い方:
#   tool/sim/health.sh [UDID]
# UDID 省略時は booted デバイスを列挙する。
# 終了コード: tool/sim/lib.sh の SIM_EXIT_* を参照。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

if [[ $# -ge 1 ]]; then
  sim_health_check "$1"
  exit $?
fi

sim_log_info "health" "scanning booted simulators"
BOOTED=$(xcrun simctl list devices booted 2>/dev/null | grep -oE '[0-9A-Fa-f-]{36}' || true)
if [[ -z "${BOOTED}" ]]; then
  sim_log_error "health" "no booted simulator (state=Shutdown or Simulator.app not running)"
  exit "${SIM_EXIT_SHUTDOWN}"
fi

while IFS= read -r udid; do
  [[ -z "${udid}" ]] && continue
  sim_health_check "${udid}" || exit $?
done <<<"${BOOTED}"

sim_log_info "health" "all booted simulators OK"
exit "${SIM_EXIT_OK}"
