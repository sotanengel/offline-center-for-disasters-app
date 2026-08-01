#!/usr/bin/env bash
# 生成済み pack.sqlite を実機上のアプリ Application Support に配置する。
# 使い方: tool/device/install_pack.sh [region] [UDID|device-name]
#
# 前提:
#   - flutter build ios / flutter install でアプリが実機に入っていること
#   - tools/out/<region>/pack.sqlite が生成済みであること
#   - 実機が USB 接続・ペアリング・Developer Mode 有効であること
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

REGION="${1:-tokyo}"
DEVICE="${2:-}"
PACK_SRC="${ROOT}/tools/out/${REGION}/pack.sqlite"
BUNDLE_ID="${DEVICE_APP_BUNDLE_ID:-dev.offlinecenter.offlineCenterForDisasters}"
DEST_REL="Library/Application Support/packs/${REGION}/pack.sqlite"
COPY_TIMEOUT="${DEVICE_PACK_COPY_TIMEOUT:-600}"

log() {
  echo "[device] $*"
}

if [[ ! -f "${PACK_SRC}" ]]; then
  log "error missing ${PACK_SRC}; run: cd tools && uv run python -m packgen.build_pack --region ${REGION}"
  exit 1
fi

if [[ -z "${DEVICE}" ]]; then
  DEVICE="$(flutter devices 2>/dev/null | awk '/ios.*mobile/ && $0 !~ /simulator/ { print $NF; exit }' | tr -d '•' | xargs || true)"
fi
if [[ -z "${DEVICE}" ]]; then
  log "error no connected iOS device; pass UDID or device name as 2nd argument"
  exit 1
fi

if ! xcrun devicectl list devices 2>/dev/null | grep -Fq "${DEVICE}"; then
  # flutter devices の UDID 行など、devicectl list に無い形式の場合はそのまま devicectl に渡す
  :
fi

log "copy region=${REGION} device=${DEVICE} size=$(du -h "${PACK_SRC}" | awk '{print $1}')"
xcrun devicectl device copy to \
  --device "${DEVICE}" \
  --source "${PACK_SRC}" \
  --destination "${DEST_REL}" \
  --domain-type appDataContainer \
  --domain-identifier "${BUNDLE_ID}" \
  --timeout "${COPY_TIMEOUT}"

log "installed region=${REGION} dest=${DEST_REL} bundle=${BUNDLE_ID}"
