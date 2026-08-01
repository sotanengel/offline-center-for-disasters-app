#!/usr/bin/env bash
# tool/sim/lib.sh の失敗分類ロジックを検証する。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=../../tool/sim/lib.sh
source "${ROOT}/tool/sim/lib.sh"

TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

pass=0
fail=0

assert_eq() {
  local name="$1"
  local expected="$2"
  local actual="$3"
  if [[ "${expected}" == "${actual}" ]]; then
    echo "PASS: ${name}"
    pass=$((pass + 1))
  else
    echo "FAIL: ${name} (expected=${expected}, actual=${actual})" >&2
    fail=$((fail + 1))
  fi
}

# --- sim_parse_device_state ---
assert_eq "parse Booted" "Booted" "$(sim_parse_device_state 'iPhone SE (D4EB4DD2-AE35-4309-A672-575E7907333F) (Booted)')"
assert_eq "parse Shutdown" "Shutdown" "$(sim_parse_device_state 'iPhone SE (D4EB4DD2-AE35-4309-A672-575E7907333F) (Shutdown)')"
assert_eq "parse Missing" "Missing" "$(sim_parse_device_state '')"

# --- sim_classify_flutter_log ---

cat >"${TMP}/build_fail.log" <<'EOF'
Running Xcode build...
Xcode build done.                                           12.3s
Failed to build iOS app
Error (Xcode): Unable to resolve module dependency: 'LeapSDK'
EOF
assert_eq "classify build" "BUILD_FAILED" "$(sim_classify_flutter_log "${TMP}/build_fail.log" "${TMP}/empty_watch")"

cat >"${TMP}/sim_shutdown.log" <<'EOF'
Running Xcode build...
Xcode build done.                                           12.3s
Unable to install /path/Runner.app on D4EB4DD2-AE35-4309-A672-575E7907333F.
ProcessException: Process exited abnormally with exit code 149:
Unable to lookup in current state: Shutdown
Failed to load "/path/test.dart": Unable to start the app on the device.
EOF
assert_eq "classify sim shutdown on install" "SIM_SHUTDOWN" "$(sim_classify_flutter_log "${TMP}/sim_shutdown.log" "${TMP}/empty_watch")"

touch "${TMP}/empty_watch"
cat >"${TMP}/test_fail.log" <<'EOF'
Running Xcode build...
Xcode build done.                                           10.0s
00:05 +1 -1: test name [E]
  Expected: exactly one matching candidate
  Actual: Found 0 widgets
00:05 +1 -1: Some tests failed.
EOF
assert_eq "classify assertion fail" "TEST_ASSERTION_FAILED" "$(sim_classify_flutter_log "${TMP}/test_fail.log" "${TMP}/empty_watch")"

cat >"${TMP}/tcc_crash.log" <<'EOF'
Running Xcode build...
Xcode build done.                                           10.0s
00:03 +0 -1: loading test.dart [E]
  Failed to load: Unable to start the app on the device.
Namespace TCC
NSSpeechRecognitionUsageDescription
privacy-sensitive data without a usage description
EOF
assert_eq "classify tcc missing usage description" "TCC_CRASH" "$(sim_classify_flutter_log "${TMP}/tcc_crash.log" "${TMP}/empty_watch")"

cat >"${TMP}/dyld_crash.log" <<'EOF'
Running Xcode build...
Xcode build done.                                           10.0s
00:00 +0 -1: loading test.dart [E]
  Failed to load: Unable to start the app on the device.
Library not loaded: @rpath/inference_engine.framework/inference_engine
Termination Reason: Namespace DYLD, Code 1, Library missing
EOF
assert_eq "classify dyld missing library" "DYLD_CRASH" "$(sim_classify_flutter_log "${TMP}/dyld_crash.log" "${TMP}/empty_watch")"

cat >"${TMP}/app_crash.log" <<'EOF'
Running Xcode build...
Xcode build done.                                           10.0s
00:03 +0 -1: loading test.dart [E]
  Failed to load: The application crashed.
EOF
assert_eq "classify app crash" "APP_CRASH" "$(sim_classify_flutter_log "${TMP}/app_crash.log" "${TMP}/empty_watch")"

echo "[watchdog] state=Shutdown at=2026-08-01T12:00:00" >"${TMP}/watch_shutdown.log"
cat >"${TMP}/ok_but_watch.log" <<'EOF'
Running Xcode build...
Xcode build done.                                           10.0s
Unable to install /path/Runner.app
EOF
assert_eq "watchdog overrides install" "SIM_SHUTDOWN" "$(sim_classify_flutter_log "${TMP}/ok_but_watch.log" "${TMP}/watch_shutdown.log")"

cat >"${TMP}/success.log" <<'EOF'
Running Xcode build...
Xcode build done.                                           10.0s
00:10 +3: All tests passed!
EOF
assert_eq "classify success" "SUCCESS" "$(sim_classify_flutter_log "${TMP}/success.log" "${TMP}/empty_watch")"

if [[ "${fail}" -gt 0 ]]; then
  echo "${fail} test(s) failed" >&2
  exit 1
fi
echo "All ${pass} classification tests passed."
