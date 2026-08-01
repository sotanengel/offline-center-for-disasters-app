#!/usr/bin/env bash
# シミュレータ診断・ログ共通ライブラリ（source 専用）
#
# 終了コード（tool/sim/test.sh 等）:
#   0  成功
#   1  ユニット/ウィジェットテスト失敗
#   10 iOS ランタイム不在
#   11 シミュレータデバイス未作成
#   12 シミュレータ Shutdown（ビルド中の落ち等）
#   13 シミュレータ起動失敗
#   20 Xcode ビルド失敗
#   21 アプリインストール失敗（Shutdown 以外）
#   30 integration テスト assertion 失敗
#   31 アプリクラッシュ
#   99 不明

readonly SIM_EXIT_OK=0
readonly SIM_EXIT_UNIT_TEST=1
readonly SIM_EXIT_RUNTIME_MISSING=10
readonly SIM_EXIT_DEVICE_MISSING=11
readonly SIM_EXIT_SHUTDOWN=12
readonly SIM_EXIT_BOOT_FAILED=13
readonly SIM_EXIT_BUILD_FAILED=20
readonly SIM_EXIT_INSTALL_FAILED=21
readonly SIM_EXIT_INTEGRATION_FAILED=30
readonly SIM_EXIT_APP_CRASH=31
readonly SIM_EXIT_DYLD_CRASH=32
readonly SIM_EXIT_TCC_CRASH=33
readonly SIM_EXIT_UNKNOWN=99

sim_log() {
  local level="$1"
  local category="$2"
  local message="$3"
  echo "[sim] level=${level} category=${category} msg=${message}"
}

sim_log_info() { sim_log "info" "$1" "$2"; }
sim_log_warn() { sim_log "warn" "$1" "$2"; }
sim_log_error() { sim_log "error" "$1" "$2"; }

# simctl list devices の 1 行から状態を抽出する。
sim_parse_device_state() {
  local line="$1"
  if [[ -z "${line}" ]]; then
    echo "Missing"
    return
  fi
  if [[ "${line}" == *"(Booted)"* ]]; then
    echo "Booted"
  elif [[ "${line}" == *"(Shutdown)"* ]]; then
    echo "Shutdown"
  elif [[ "${line}" == *"(Shutting Down)"* ]]; then
    echo "ShuttingDown"
  elif [[ "${line}" == *"(Creating)"* ]]; then
    echo "Creating"
  else
    echo "Unknown"
  fi
}

sim_device_line() {
  local udid="$1"
  xcrun simctl list devices 2>/dev/null | grep -F "${udid}" | head -1 || true
}

sim_device_state() {
  local udid="$1"
  sim_parse_device_state "$(sim_device_line "${udid}")"
}

sim_latest_runtime() {
  xcrun simctl list runtimes available 2>/dev/null \
    | grep -o 'com.apple.CoreSimulator.SimRuntime.iOS[^ ]*' \
    | sort -V \
    | tail -1 \
    || true
}

# 構造化ヘルスレポートを stdout に出力。終了コードは SIM_EXIT_*。
sim_health_check() {
  local udid="${1:-}"
  local runtime
  runtime="$(sim_latest_runtime)"
  if [[ -z "${runtime}" ]]; then
    sim_log_error "health" "iOS runtime not found; run xcodebuild -downloadPlatform iOS"
    return "${SIM_EXIT_RUNTIME_MISSING}"
  fi
  sim_log_info "health" "runtime=${runtime}"

  if [[ -z "${udid}" ]]; then
    sim_log_warn "health" "udid not specified"
    return "${SIM_EXIT_OK}"
  fi

  local line state
  line="$(sim_device_line "${udid}")"
  state="$(sim_parse_device_state "${line}")"
  sim_log_info "health" "udid=${udid} state=${state} line=${line:-<missing>}"

  case "${state}" in
    Booted) return "${SIM_EXIT_OK}" ;;
    Shutdown | ShuttingDown)
      sim_log_error "health" "simulator is ${state} (may have crashed during build)"
      return "${SIM_EXIT_SHUTDOWN}"
      ;;
    Missing)
      sim_log_error "health" "device udid=${udid} not found"
      return "${SIM_EXIT_DEVICE_MISSING}"
      ;;
    *)
      sim_log_warn "health" "unexpected state=${state}"
      return "${SIM_EXIT_UNKNOWN}"
      ;;
  esac
}

# flutter test ログとウォッチドッグログから失敗種別を判定（stdout に category 名）。
sim_classify_flutter_log() {
  local flutter_log="$1"
  local watchdog_log="${2:-}"

  if [[ -f "${watchdog_log}" ]] && grep -q 'state=Shutdown\|state=ShuttingDown' "${watchdog_log}" 2>/dev/null; then
    echo "SIM_SHUTDOWN"
    return
  fi

  if [[ ! -f "${flutter_log}" ]]; then
    echo "UNKNOWN"
    return
  fi

  if grep -q 'All tests passed!' "${flutter_log}"; then
    echo "SUCCESS"
    return
  fi

  if grep -qE 'Unable to resolve module|Failed to build iOS app|Xcode build failed|Error \(Xcode\):' "${flutter_log}"; then
    echo "BUILD_FAILED"
    return
  fi

  if grep -q 'Unable to lookup in current state: Shutdown' "${flutter_log}" \
    || grep -q 'domain=com.apple.CoreSimulator.SimError, code=405' "${flutter_log}"; then
    echo "SIM_SHUTDOWN"
    return
  fi

  if grep -qE 'Library not loaded:|Namespace DYLD|fatalDyldError|inference_engine\.framework' "${flutter_log}"; then
    echo "DYLD_CRASH"
    return
  fi

  if grep -qE 'Namespace TCC|NSSpeechRecognitionUsageDescription|privacy-sensitive data without a usage description' "${flutter_log}"; then
    echo "TCC_CRASH"
    return
  fi

  if grep -qE 'The application crashed|Lost connection to device|SpringBoard crashed' "${flutter_log}"; then
    echo "APP_CRASH"
    return
  fi

  if grep -q 'Unable to install' "${flutter_log}" \
    || grep -q 'Unable to start the app on the device' "${flutter_log}"; then
    echo "INSTALL_FAILED"
    return
  fi

  if grep -qE '\+[0-9]+ -[1-9]:|Some tests failed\.' "${flutter_log}"; then
    echo "TEST_ASSERTION_FAILED"
    return
  fi

  echo "UNKNOWN"
}

sim_category_exit_code() {
  case "$1" in
    SUCCESS) echo "${SIM_EXIT_OK}" ;;
    BUILD_FAILED) echo "${SIM_EXIT_BUILD_FAILED}" ;;
    SIM_SHUTDOWN) echo "${SIM_EXIT_SHUTDOWN}" ;;
    INSTALL_FAILED) echo "${SIM_EXIT_INSTALL_FAILED}" ;;
    TEST_ASSERTION_FAILED) echo "${SIM_EXIT_INTEGRATION_FAILED}" ;;
    APP_CRASH) echo "${SIM_EXIT_APP_CRASH}" ;;
    DYLD_CRASH) echo "${SIM_EXIT_DYLD_CRASH}" ;;
    TCC_CRASH) echo "${SIM_EXIT_TCC_CRASH}" ;;
    *) echo "${SIM_EXIT_UNKNOWN}" ;;
  esac
}

sim_print_failure_guide() {
  local category="$1"
  case "${category}" in
    SIM_SHUTDOWN)
      sim_log_error "diagnosis" \
        "シミュレータがビルド中に Shutdown になりました。Simulator.app の再起動後 tool/sim/boot.sh を実行してください。"
      sim_log_info "diagnosis" "確認: xcrun simctl list devices booted"
      ;;
    BUILD_FAILED)
      sim_log_error "diagnosis" "Xcode ビルド失敗です。シミュレータ状態とは無関係です。flutter build ios --simulator のログを確認してください。"
      ;;
    INSTALL_FAILED)
      sim_log_error "diagnosis" "ビルド成功後のインストール失敗です。tool/sim/health.sh で状態を確認してください。"
      ;;
    TEST_ASSERTION_FAILED)
      sim_log_error "diagnosis" "アプリは起動しましたがテスト assertion が失敗しました（シミュレータ落ちではありません）。"
      ;;
    APP_CRASH)
      sim_log_error "diagnosis" "テスト中にアプリまたは SpringBoard がクラッシュした可能性があります。"
      sim_log_info "diagnosis" "確認: ~/Library/Logs/DiagnosticReports/ の最新 Runner*.ips"
      ;;
    DYLD_CRASH)
      sim_log_error "diagnosis" \
        "起動直後の dyld クラッシュです（シミュレータ落ちではありません）。LEAP SDK の inference_engine 等フレームワーク同梱を確認してください。"
      sim_log_info "diagnosis" "確認: ios/Podfile の Inference-Engine* pod、pod install 後 Runner.app/Frameworks/"
      sim_check_latest_runner_crash
      ;;
    TCC_CRASH)
      sim_log_error "diagnosis" \
        "TCC プライバシー違反クラッシュです（シミュレータ落ちではありません）。Info.plist の UsageDescription キーを確認してください。"
      sim_log_info "diagnosis" "例: NSSpeechRecognitionUsageDescription, NSMicrophoneUsageDescription"
      sim_check_latest_runner_crash
      ;;
    *)
      sim_log_error "diagnosis" "原因不明。flutter ログ全体を確認してください。"
      ;;
  esac
}

WATCHDOG_PID=""
WATCHDOG_LOG=""

sim_watchdog_start() {
  local udid="$1"
  WATCHDOG_LOG="$(mktemp /tmp/ocd-sim-watchdog.XXXXXX)"
  (
    local prev
    prev="$(sim_device_state "${udid}")"
    sim_log_info "watchdog" "start udid=${udid} initial_state=${prev}" >>"${WATCHDOG_LOG}"
    while true; do
      sleep 2
      local cur
      cur="$(sim_device_state "${udid}")"
      if [[ "${cur}" != "${prev}" ]]; then
        sim_log_warn "watchdog" "state=${cur} at=$(date -u +%Y-%m-%dT%H:%M:%SZ) (was ${prev})" >>"${WATCHDOG_LOG}"
        prev="${cur}"
      fi
    done
  ) &
  WATCHDOG_PID=$!
  sim_log_info "watchdog" "pid=${WATCHDOG_PID} log=${WATCHDOG_LOG}"
}

sim_watchdog_stop() {
  if [[ -n "${WATCHDOG_PID}" ]]; then
    kill "${WATCHDOG_PID}" 2>/dev/null || true
    wait "${WATCHDOG_PID}" 2>/dev/null || true
    WATCHDOG_PID=""
  fi
  if [[ -n "${WATCHDOG_LOG}" && -f "${WATCHDOG_LOG}" ]]; then
    sim_log_info "watchdog" "log follows:"
    cat "${WATCHDOG_LOG}" || true
  fi
}

# DiagnosticReports の最新 Runner クラッシュから dyld 原因を要約する。
sim_check_latest_runner_crash() {
  local crash_dir="${HOME}/Library/Logs/DiagnosticReports"
  local latest
  latest="$(ls -t "${crash_dir}"/Runner*.ips "${crash_dir}"/Runner*.crash 2>/dev/null | head -1 || true)"
  if [[ -z "${latest}" ]]; then
    sim_log_warn "diagnosis" "Runner クラッシュレポートが見つかりません"
    return
  fi
  sim_log_info "diagnosis" "latest_crash=${latest}"
  if grep -q 'inference_engine.framework' "${latest}" 2>/dev/null; then
    sim_log_error "diagnosis" "missing_library=inference_engine.framework (Leap-SDK 依存)"
  fi
  if grep -q 'Namespace DYLD' "${latest}" 2>/dev/null; then
    sim_log_error "diagnosis" "termination=DYLD (dynamic linker failure at launch)"
  fi
  if grep -q 'Namespace TCC' "${latest}" 2>/dev/null; then
    sim_log_error "diagnosis" "termination=TCC (missing Info.plist UsageDescription)"
    grep -oE 'NSSpeech[A-Za-z]+UsageDescription|NSMicrophoneUsageDescription|NSLocation[A-Za-z]+UsageDescription' "${latest}" 2>/dev/null \
      | sort -u \
      | while read -r key; do
        sim_log_error "diagnosis" "missing_key=${key}"
      done || true
  fi
}
