#!/usr/bin/env bash
# 実機上で integration_test を実行する。
# 使い方: tool/device/test.sh [UDID|device-name]
#
# 前提: USB 接続・Developer Mode・Personal Team 署名（ios/Flutter/Personal.xcconfig）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=../sim/lib.sh
source "${SCRIPT_DIR}/../sim/lib.sh"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

DEVICE="${1:-}"
REGION="${DEVICE_TEST_REGION:-tokyo}"
# 実機 integration の壁時計上限（既定 10 分）。超えたらハングとみなして打ち切る。
DEVICE_INTEGRATION_TIMEOUT_SEC="${DEVICE_INTEGRATION_TIMEOUT_SEC:-600}"

cd "${ROOT}"

if [[ -z "${DEVICE}" ]]; then
  DEVICE="$(flutter devices 2>/dev/null | awk '/ios.*mobile/ && $0 !~ /simulator/ { print $NF; exit }' | tr -d '•' | xargs || true)"
fi
if [[ -z "${DEVICE}" ]]; then
  sim_log_error "device-test" "no connected iOS device; pass UDID as 1st argument"
  exit 1
fi

sim_log_info "device-test" "device=${DEVICE} region=${REGION}"

echo "=== tool 診断テスト ==="
bash test/tool/sim_classify_test.sh
bash test/tool/info_plist_privacy_test.sh
bash test/tool/device_install_pack_test.sh
bash test/tool/device_list_packs_test.sh
bash test/tool/device_developer_trust_test.sh
bash test/tool/device_timeout_test.sh
bash test/tool/device_restore_app_test.sh

sim_log_info "device-test" "phase=unit"
if ! flutter test --exclude-tags real_llm; then
  sim_log_error "device-test" "phase=unit result=fail"
  exit "${SIM_EXIT_UNIT_TEST}"
fi

sim_log_info "device-test" "phase=prebuild app+pack"
flutter build ios --debug
# flutter install は「古い版をアンインストール」するため、Personal Team の
# デベロッパプロファイルごと消えて信頼が毎回解除される。既に入っている場合は
# 再インストールせず、flutter test 側のインストールに任せる。
if device_app_installed "${DEVICE}"; then
  sim_log_info "device-test" "app already installed; skip reinstall (信頼の解除を避けるため)"
else
  flutter install -d "${DEVICE}"
fi
"${SCRIPT_DIR}/install_pack.sh" "${REGION}" "${DEVICE}"

sim_log_info "device-test" "phase=developer-trust"
if ! "${SCRIPT_DIR}/ensure_developer_trust.sh" "${DEVICE}"; then
  sim_log_error "device-test" "developer certificate not trusted; see guide above"
  exit 12
fi

sim_log_info "device-test" "phase=integration"
# flutter test はこの後アプリをアンインストールする。放置すると開発者プロファイルごと
# 消えて次回が必ず未信頼になるため、どの経路で抜けても必ず入れ直す。
trap 'device_restore_app "${DEVICE}" "${REGION}" "${SCRIPT_DIR}"' EXIT
flutter_log="$(mktemp /tmp/ocd-device-integration.XXXXXX)"
flutter_exit=0
# flutter test は自身でアプリを再インストールするため、上の信頼チェック後に
# 再び「未信頼のデベロッパ」状態へ戻ることがある。その場合アプリが起動できず
# 無期限にハングするので、必ず壁時計で打ち切る。
# 壁時計の 10 分を待たずに、起動停滞を見つけ次第すぐ打ち切る監視。
stall_marker="$(mktemp "${TMPDIR:-/tmp}/ocd-stall.XXXXXX")"
rm -f "${stall_marker}"
(
  while true; do
    sleep 5
    if device_log_indicates_launch_stall "${flutter_log}"; then
      : >"${stall_marker}"
      pkill -f "flutter_tools.snapshot test" 2>/dev/null || true
      exit 0
    fi
  done
) &
stall_watch_pid=$!

device_run_with_timeout "${DEVICE_INTEGRATION_TIMEOUT_SEC}" \
  "flutter test integration_test -d '${DEVICE}' --exclude-tags real_llm --timeout 180s 2>&1 | tee '${flutter_log}'" \
  || flutter_exit=$?

kill "${stall_watch_pid}" 2>/dev/null || true
wait "${stall_watch_pid}" 2>/dev/null || true

if [[ -e "${stall_marker}" ]]; then
  rm -f "${stall_marker}"
  sim_log_error "device-test" "アプリを起動できず停滞したため中断しました（開発者未信頼の典型症状）"
  device_print_trust_guide
  rm -f "${flutter_log}"
  exit "${DEVICE_EXIT_NOT_TRUSTED}"
fi
rm -f "${stall_marker}"

if [[ "${flutter_exit}" -eq "${DEVICE_EXIT_TIMEOUT}" ]]; then
  sim_log_error "device-test" \
    "integration timed out after ${DEVICE_INTEGRATION_TIMEOUT_SEC}s (ハングではなく失敗として打ち切り)"
  # 最有力原因は再インストールによる開発者信頼の解除。実際に確かめて案内する。
  if ! "${SCRIPT_DIR}/ensure_developer_trust.sh" "${DEVICE}"; then
    sim_log_error "device-test" "原因: 再インストールで開発者信頼が解除されています。上の手順で信頼してから再実行してください。"
    rm -f "${flutter_log}"
    exit "${DEVICE_EXIT_NOT_TRUSTED}"
  fi
  sim_log_error "device-test" "開発者信頼は有効。テスト側のハングとして flutter log tail を確認してください:"
  tail -40 "${flutter_log}" >&2 || true
  rm -f "${flutter_log}"
  exit "${DEVICE_EXIT_TIMEOUT}"
fi

category="$(sim_classify_flutter_log "${flutter_log}")"
sim_log_info "device-test" "phase=integration category=${category} flutter_exit=${flutter_exit}"

if [[ "${category}" == "SUCCESS" ]]; then
  rm -f "${flutter_log}"
  sim_log_info "device-test" "all phases passed"
  exit "${SIM_EXIT_OK}"
fi

sim_print_failure_guide "${category}"
sim_log_error "device-test" "flutter log tail:"
tail -40 "${flutter_log}" >&2 || true
rm -f "${flutter_log}"
exit "$(sim_category_exit_code "${category}")"
