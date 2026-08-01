#!/usr/bin/env bash
# tools/out の pack.sqlite を assets/packs/ にコピーし、flutter build で同梱できるようにする。
#
# 使い方:
#   tool/build/prepare_bundled_packs.sh
#   BUNDLED_PACK_REGIONS="tokyo chiba" tool/build/prepare_bundled_packs.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REGIONS="${BUNDLED_PACK_REGIONS:-tokyo}"

log() {
  echo "[prepare-bundled-packs] $*"
}

cd "${ROOT}"
for region in ${REGIONS}; do
  src="${ROOT}/tools/out/${region}/pack.sqlite"
  dest_dir="${ROOT}/assets/packs/${region}"
  dest="${dest_dir}/pack.sqlite"
  if [[ ! -f "${src}" ]]; then
    log "error missing ${src}"
    log "run: cd tools && uv run python -m packgen.build_pack --region ${region}"
    exit 1
  fi
  mkdir -p "${dest_dir}"
  log "copy region=${region} size=$(du -h "${src}" | awk '{print $1}')"
  cp "${src}" "${dest}"
done

log "done regions=${REGIONS}"
