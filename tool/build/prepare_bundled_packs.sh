#!/usr/bin/env bash
# tools/out の県別 pack.sqlite を統合し assets/packs/bundled/ へ配置する。
#
# 使い方:
#   tool/build/prepare_bundled_packs.sh
#
# 前提: tools/out/{chiba,kanagawa,saitama,tokyo}/pack.sqlite が生成済み
#   cd tools && uv run python -m packgen.build_pack --all
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUNDLED_OUT="${ROOT}/tools/out/bundled/pack.sqlite"
ASSET_DEST="${ROOT}/assets/packs/bundled/pack.sqlite"

log() {
  echo "[prepare-bundled-packs] $*"
}

cd "${ROOT}/tools"
for region in chiba kanagawa saitama tokyo; do
  src="${ROOT}/tools/out/${region}/pack.sqlite"
  if [[ ! -f "${src}" ]]; then
    log "error missing ${src}"
    log "run: cd tools && uv run python -m packgen.build_pack --all"
    exit 1
  fi
done

log "merge prefecture packs -> ${BUNDLED_OUT}"
uv run python -m packgen.merge_pack --output "${BUNDLED_OUT}"

mkdir -p "$(dirname "${ASSET_DEST}")"
log "copy bundled size=$(du -h "${BUNDLED_OUT}" | awk '{print $1}')"
cp "${BUNDLED_OUT}" "${ASSET_DEST}"
log "done asset=${ASSET_DEST}"
