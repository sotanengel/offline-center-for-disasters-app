#!/usr/bin/env bash
# 生成済み全地域パックを実機へ順次配置する。
# 使い方: tool/device/install_all_packs.sh [UDID|device-name]
#
# 約 1.6GB（関東4県）。USB 接続を維持すること。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVICE="${1:-}"

# packgen.config.REGIONS と同一順
REGIONS=(chiba kanagawa saitama tokyo)

"${SCRIPT_DIR}/list_packs.sh" >/dev/null

for region in "${REGIONS[@]}"; do
  "${SCRIPT_DIR}/install_pack.sh" "${region}" "${DEVICE}"
done

echo "[device] all packs installed regions=${REGIONS[*]}"
