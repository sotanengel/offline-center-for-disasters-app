#!/usr/bin/env bash
# tools/out/ に存在する地域パックの一覧を表示する。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUT_DIR="${ROOT}/tools/out"

# packgen.config.REGIONS と同一順（関東4県）
REGIONS=(chiba kanagawa saitama tokyo)

total=0
ready=0

printf "%-12s %8s %s\n" "REGION" "SIZE" "STATUS"
printf "%-12s %8s %s\n" "------" "----" "------"

for region in "${REGIONS[@]}"; do
  pack="${OUT_DIR}/${region}/pack.sqlite"
  if [[ -f "${pack}" ]]; then
    size="$(du -h "${pack}" | awk '{print $1}')"
    printf "%-12s %8s %s\n" "${region}" "${size}" "ready"
    ready=$((ready + 1))
    total=$((total + 1))
  else
    printf "%-12s %8s %s\n" "${region}" "-" "missing"
    total=$((total + 1))
  fi
done

echo ""
echo "ready=${ready}/${total} (out_dir=${OUT_DIR})"
if [[ "${ready}" -lt "${total}" ]]; then
  echo "generate: cd tools && uv run python -m packgen.build_pack --all"
  exit 1
fi
