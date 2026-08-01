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
# flutter test は「ディレクトリ一括」で渡すと、含まれるテストファイルごとに
# アプリを再インストールする。1 回でも失敗・中断すればそこで信頼が壊れ、
# 以降のファイルは巻き添えで全部失敗する（2026-08-02 実機検証で実際に発生）。
# ファイルごとに実行し、そのつど信頼を検証してから次へ進む。
overall_exit="${SIM_EXIT_OK}"
# shellcheck disable=SC2207 # 対象は ASCII のファイル名のみ
integration_files=($(grep -L "real_llm" "${ROOT}"/integration_test/*.dart))

for test_file in "${integration_files[@]}"; do
  rel_file="${test_file#"${ROOT}"/}"
  sim_log_info "device-test" "phase=integration file=${rel_file}"

  flutter_log="$(mktemp /tmp/ocd-device-integration.XXXXXX)"
  flutter_exit=0
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
    "flutter test '${rel_file}' -d '${DEVICE}' --timeout 180s 2>&1 | tee '${flutter_log}'" \
    || flutter_exit=$?

  kill "${stall_watch_pid}" 2>/dev/null || true
  wait "${stall_watch_pid}" 2>/dev/null || true

  file_failed=false
  if [[ -e "${stall_marker}" ]]; then
    rm -f "${stall_marker}"
    sim_log_error "device-test" "file=${rel_file} アプリの起動に失敗したため中断しました"
    file_failed=true
  elif [[ "${flutter_exit}" -eq "${DEVICE_EXIT_TIMEOUT}" ]]; then
    sim_log_error "device-test" \
      "file=${rel_file} timed out after ${DEVICE_INTEGRATION_TIMEOUT_SEC}s (ハングではなく失敗として打ち切り)"
    file_failed=true
  else
    category="$(sim_classify_flutter_log "${flutter_log}")"
    sim_log_info "device-test" "file=${rel_file} category=${category} flutter_exit=${flutter_exit}"
    if [[ "${category}" != "SUCCESS" ]]; then
      sim_print_failure_guide "${category}"
      overall_exit="$(sim_category_exit_code "${category}")"
    fi
  fi
  rm -f "${stall_marker}"

  # このファイルの結果に関わらず、次のファイルへ進む前に必ず入れ直して
  # 信頼を検証する。信頼が壊れていれば直ちに中断し、以降のファイルを
  # 巻き添えで失敗させない。
  if ! device_restore_app "${DEVICE}" "${REGION}" "${SCRIPT_DIR}"; then
    sim_log_error "device-test" \
      "file=${rel_file} の後で開発者信頼が失われました。以降のファイルは実行しません。"
    device_print_trust_guide
    tail -40 "${flutter_log}" >&2 || true
    rm -f "${flutter_log}"
    exit "${DEVICE_EXIT_NOT_TRUSTED}"
  fi

  if [[ "${file_failed}" == "true" ]]; then
    sim_log_error "device-test" "file=${rel_file} flutter log tail:"
    tail -40 "${flutter_log}" >&2 || true
    if [[ "${overall_exit}" -eq "${SIM_EXIT_OK}" ]]; then
      overall_exit="${DEVICE_EXIT_TIMEOUT}"
    fi
  fi
  rm -f "${flutter_log}"
done

if [[ "${overall_exit}" -eq "${SIM_EXIT_OK}" ]]; then
  sim_log_info "device-test" "all phases passed"
fi
exit "${overall_exit}"
