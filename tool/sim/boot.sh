#!/usr/bin/env bash
# iPhone シミュレータを作成・起動する。
# 性能下限の再現用に既定は iPhone SE (3rd generation)。
# 使い方: tool/sim/boot.sh [デバイス名]
# 出力: 最終行に起動したシミュレータの UDID を表示する。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

DEVICE_NAME="${1:-iPhone SE (3rd generation)}"

RUNTIME="$(sim_latest_runtime)"
if [[ -z "${RUNTIME}" ]]; then
  sim_log_error "boot" "iOS runtime not found; run xcodebuild -downloadPlatform iOS"
  exit "${SIM_EXIT_RUNTIME_MISSING}"
fi
sim_log_info "boot" "runtime=${RUNTIME}"

DEVICE_UDID=$(xcrun simctl list devices available | grep -F "${DEVICE_NAME}" | head -1 | grep -oE '[0-9A-Fa-f-]{36}' || true)
if [[ -z "${DEVICE_UDID}" ]]; then
  sim_log_info "boot" "creating device name=${DEVICE_NAME}"
  DEVICE_UDID=$(xcrun simctl create "${DEVICE_NAME}" "${DEVICE_NAME}" "${RUNTIME}")
fi

STATE="$(sim_device_state "${DEVICE_UDID}")"
if [[ "${STATE}" != "Booted" ]]; then
  sim_log_info "boot" "booting udid=${DEVICE_UDID} previous_state=${STATE}"
  if ! xcrun simctl boot "${DEVICE_UDID}"; then
    sim_log_error "boot" "simctl boot failed udid=${DEVICE_UDID}"
    exit "${SIM_EXIT_BOOT_FAILED}"
  fi
fi

open -a Simulator || true
if ! xcrun simctl bootstatus "${DEVICE_UDID}" -b; then
  sim_log_error "boot" "bootstatus timeout udid=${DEVICE_UDID}"
  exit "${SIM_EXIT_BOOT_FAILED}"
fi

FINAL_STATE="$(sim_device_state "${DEVICE_UDID}")"
sim_log_info "boot" "ready udid=${DEVICE_UDID} state=${FINAL_STATE}"
"${SCRIPT_DIR}/grant_permissions.sh" "${DEVICE_UDID}" || true
echo "${DEVICE_UDID}"
