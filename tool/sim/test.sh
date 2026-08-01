#!/usr/bin/env bash
# ユニットテストと、iPhone シミュレータ上での integration_test を実行する。
# シミュレータ落ち・ビルド失敗・インストール失敗・assertion 失敗を exit code / ログで区別する。
# 使い方: tool/sim/test.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

cd "${ROOT}"

run_unit_tests() {
  sim_log_info "test" "phase=unit"
  if flutter test --exclude-tags real_llm; then
    sim_log_info "test" "phase=unit result=pass"
    return 0
  fi
  sim_log_error "test" "phase=unit result=fail"
  return "${SIM_EXIT_UNIT_TEST}"
}

run_integration_tests() {
  local device_udid="$1"
  local attempt="${2:-1}"
  local flutter_log
  flutter_log="$(mktemp /tmp/ocd-flutter-integration.XXXXXX)"

  sim_log_info "test" "phase=integration attempt=${attempt} udid=${device_udid}"

  if ! sim_health_check "${device_udid}"; then
    sim_log_warn "test" "pre-flight health failed; re-booting"
    device_udid="$(tool/sim/boot.sh | tail -1)"
    sim_health_check "${device_udid}" || return $?
  fi

  tool/sim/grant_permissions.sh "${device_udid}" || true

  tool/sim/bootstrap_leap_sdk.sh

  sim_log_info "test" "phase=integration prebuild app+pack"
  flutter build ios --simulator --debug >/dev/null
  xcrun simctl install "${device_udid}" "${ROOT}/build/ios/iphonesimulator/Runner.app"
  tool/sim/install_pack.sh tokyo "${device_udid}"

  sim_watchdog_start "${device_udid}"
  local flutter_exit=0
  flutter test integration_test -d "${device_udid}" --exclude-tags real_llm 2>&1 | tee "${flutter_log}" || flutter_exit=$?
  sim_watchdog_stop

  local category
  category="$(sim_classify_flutter_log "${flutter_log}" "${WATCHDOG_LOG:-}")"
  sim_log_info "test" "phase=integration category=${category} flutter_exit=${flutter_exit}"

  if [[ "${category}" == "SUCCESS" ]]; then
    rm -f "${flutter_log}"
    return 0
  fi

  sim_print_failure_guide "${category}"
  sim_log_error "test" "flutter log tail:"
  tail -30 "${flutter_log}" >&2 || true

  if [[ "${category}" == "SIM_SHUTDOWN" && "${attempt}" -lt 2 ]]; then
    sim_log_warn "test" "retrying after simulator re-boot (shutdown detected)"
    rm -f "${flutter_log}"
    tool/sim/boot.sh >/dev/null
    run_integration_tests "${device_udid}" $((attempt + 1))
    return $?
  fi

  rm -f "${flutter_log}"
  return "$(sim_category_exit_code "${category}")"
}

sim_log_info "test" "start root=${ROOT}"

echo "=== tool 診断テスト (sim classify / Info.plist) ==="
bash test/tool/sim_classify_test.sh
bash test/tool/info_plist_privacy_test.sh

if ! run_unit_tests; then
  exit "${SIM_EXIT_UNIT_TEST}"
fi

sim_log_info "test" "booting simulator"
DEVICE_UDID="$(tool/sim/boot.sh | tail -1)"
sim_log_info "test" "device=${DEVICE_UDID}"

if ! run_integration_tests "${DEVICE_UDID}"; then
  exit $?
fi

sim_log_info "test" "all phases passed"
# LFM2.5 実推論テスト: tool/sim/test_llm.sh（@Tags real_llm、モデル DL 必要）
exit "${SIM_EXIT_OK}"
