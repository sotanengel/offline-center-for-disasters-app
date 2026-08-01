#!/usr/bin/env bash
# tool/device/lib.sh の device_run_with_timeout の回帰テスト。
# 実機テストが無期限にハングしないこと（開発者未信頼で固まる事故の再発防止）を担保する。
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=../../tool/device/lib.sh
source "${ROOT}/tool/device/lib.sh"

pass=0
fail=0

check() {
  local name="$1" expected="$2" actual="$3"
  if [[ "${expected}" == "${actual}" ]]; then
    echo "PASS: ${name}"
    pass=$((pass + 1))
  else
    echo "FAIL: ${name} (expected=${expected} actual=${actual})"
    fail=$((fail + 1))
  fi
}

# 1) 制限内に終わるコマンドは終了コードをそのまま返す
status=0
device_run_with_timeout 5 "true" || status=$?
check "fast command returns 0" 0 "${status}"

# 2) 失敗するコマンドは非ゼロをそのまま伝播する
status=0
device_run_with_timeout 5 "exit 3" || status=$?
check "failing command propagates exit code" 3 "${status}"

# 3) 制限を超えたコマンドは打ち切られ DEVICE_EXIT_TIMEOUT を返す
start="$(date +%s)"
status=0
device_run_with_timeout 2 "sleep 30" || status=$?
elapsed=$(($(date +%s) - start))
check "slow command times out" "${DEVICE_EXIT_TIMEOUT}" "${status}"
if (( elapsed < 10 )); then
  echo "PASS: timeout kills promptly (${elapsed}s)"
  pass=$((pass + 1))
else
  echo "FAIL: timeout kills promptly (elapsed=${elapsed}s)"
  fail=$((fail + 1))
fi

# 4) 起動停滞（＝開発者未信頼の典型症状）をログから検知できる
tmp_log="$(mktemp "${TMPDIR:-/tmp}/ocd-stall-test.XXXXXX")"

printf 'Installing and launching...\nXcode is taking longer than expected to start debugging the app.\n' >"${tmp_log}"
if device_log_indicates_launch_stall "${tmp_log}"; then
  echo "PASS: detects Xcode debug-attach stall"
  pass=$((pass + 1))
else
  echo "FAIL: detects Xcode debug-attach stall"
  fail=$((fail + 1))
fi

printf 'Error launching application on sota.\n' >"${tmp_log}"
if device_log_indicates_launch_stall "${tmp_log}"; then
  echo "PASS: detects launch error"
  pass=$((pass + 1))
else
  echo "FAIL: detects launch error"
  fail=$((fail + 1))
fi

# osascript -15 (Xcode オートメーション権限) は未信頼と別原因として判別できること。
# 2026-08-02 実機検証で、この文言を「未信頼」と誤って案内したため回帰させない。
printf 'Error executing osascript: -15\nCould not run build/ios/iphoneos/Runner.app\n' >"${tmp_log}"
if device_log_indicates_automation_permission_denied "${tmp_log}"; then
  echo "PASS: distinguishes Xcode automation permission error"
  pass=$((pass + 1))
else
  echo "FAIL: distinguishes Xcode automation permission error"
  fail=$((fail + 1))
fi

# 正常進行しているログを誤検知しない
printf 'Installing and launching...\n00:04 +1: S-01 ホームが表示される\n' >"${tmp_log}"
if device_log_indicates_launch_stall "${tmp_log}"; then
  echo "FAIL: healthy log must not be flagged"
  fail=$((fail + 1))
else
  echo "PASS: healthy log not flagged"
  pass=$((pass + 1))
fi

rm -f "${tmp_log}"

echo "${pass} passed, ${fail} failed"
[[ "${fail}" -eq 0 ]]
