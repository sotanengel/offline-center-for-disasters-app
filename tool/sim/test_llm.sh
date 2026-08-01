#!/usr/bin/env bash
# LFM2.5 実推論 integration テスト（@Tags real_llm）。
# 初回は LFM2-350M（約 250MB）の DL が発生する。
# 使い方: tool/sim/test_llm.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

cd "${ROOT}"

sim_log_info "test_llm" "start root=${ROOT}"

sim_log_info "test_llm" "booting simulator"
DEVICE_UDID="$(tool/sim/boot.sh | tail -1)"
sim_log_info "test_llm" "device=${DEVICE_UDID}"

tool/sim/grant_permissions.sh "${DEVICE_UDID}" || true

tool/sim/bootstrap_leap_sdk.sh

sim_log_info "test_llm" "prebuild app+pack"
flutter build ios --simulator --debug >/dev/null
xcrun simctl install "${DEVICE_UDID}" "${ROOT}/build/ios/iphonesimulator/Runner.app"
tool/sim/install_pack.sh tokyo "${DEVICE_UDID}" || true

sim_log_info "test_llm" "phase=real_llm integration"
sim_watchdog_start "${DEVICE_UDID}"
flutter_log="$(mktemp /tmp/ocd-flutter-llm.XXXXXX)"
flutter_exit=0
flutter test integration_test/lfm25_real_inference_test.dart -d "${DEVICE_UDID}" \
  --tags real_llm 2>&1 | tee "${flutter_log}" || flutter_exit=$?
sim_watchdog_stop

category="$(sim_classify_flutter_log "${flutter_log}" "${WATCHDOG_LOG:-}")"
sim_log_info "test_llm" "category=${category} flutter_exit=${flutter_exit}"

if [[ "${category}" == "SUCCESS" && "${flutter_exit}" -eq 0 ]]; then
  rm -f "${flutter_log}"
  sim_log_info "test_llm" "passed"
  exit "${SIM_EXIT_OK}"
fi

sim_print_failure_guide "${category}"
tail -30 "${flutter_log}" >&2 || true
rm -f "${flutter_log}"
exit "$(sim_category_exit_code "${category}")"
