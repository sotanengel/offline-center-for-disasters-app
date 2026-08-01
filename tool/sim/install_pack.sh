#!/usr/bin/env bash
# 生成済み pack.sqlite をシミュレータ上のアプリに配置する。
# 使い方: tool/sim/install_pack.sh [region] [UDID]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

REGION="${1:-tokyo}"
UDID="${2:-}"
PACK_SRC="${ROOT}/tools/out/${REGION}/pack.sqlite"
BUNDLE_ID="${SIM_APP_BUNDLE_ID:-dev.offlinecenter.offlineCenterForDisasters}"

if [[ ! -f "${PACK_SRC}" ]]; then
  sim_log_error "pack" "missing ${PACK_SRC}; run: cd tools && uv run python -m packgen.build_pack --region ${REGION}"
  exit 1
fi

if [[ -z "${UDID}" ]]; then
  UDID="$(xcrun simctl list devices booted | grep -oE '[0-9A-Fa-f-]{36}' | head -1 || true)"
fi
if [[ -z "${UDID}" ]]; then
  sim_log_error "pack" "no booted simulator"
  exit "${SIM_EXIT_SHUTDOWN}"
fi

CONTAINER="$(xcrun simctl get_app_container "${UDID}" "${BUNDLE_ID}" data 2>/dev/null || true)"
if [[ -z "${CONTAINER}" ]]; then
  sim_log_error "pack" "app not installed on simulator; run flutter run first"
  exit 1
fi

DEST="${CONTAINER}/Library/Application Support/packs/${REGION}"
mkdir -p "${DEST}"
cp "${PACK_SRC}" "${DEST}/pack.sqlite"
sim_log_info "pack" "installed region=${REGION} dest=${DEST}/pack.sqlite size=$(du -h "${DEST}/pack.sqlite" | awk '{print $1}')"
