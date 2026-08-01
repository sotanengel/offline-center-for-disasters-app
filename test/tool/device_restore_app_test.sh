#!/usr/bin/env bash
# 実機テスト後にアプリを復元することの回帰テスト。
#
# flutter test -d <device> は実行後にアプリをアンインストールする。そのまま放置すると
# そのデベロッパの最後のアプリが消えてプロファイルごと端末から外れ、次回実行時に
# 必ず「信頼されていないデベロッパ」へ戻る（手動タップが毎回必要になる）。
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=../../tool/device/lib.sh
source "${ROOT}/tool/device/lib.sh"

pass=0
fail=0

check() {
  local name="$1"
  if eval "$2"; then
    echo "PASS: ${name}"
    pass=$((pass + 1))
  else
    echo "FAIL: ${name}"
    fail=$((fail + 1))
  fi
}

check "device_restore_app が定義されている" \
  'declare -f device_restore_app >/dev/null'

check "device_app_installed が定義されている" \
  'declare -f device_app_installed >/dev/null'

check "test.sh がテスト後にアプリを復元する" \
  'grep -q "device_restore_app" "${ROOT}/tool/device/test.sh"'

check "復元は失敗しても実行を止めない（trap で必ず通る）" \
  'grep -qE "trap .*device_restore_app" "${ROOT}/tool/device/test.sh"'

check "アンインストールされる旨がコメントされている" \
  'grep -q "アンインストール" "${ROOT}/tool/device/lib.sh"'

echo "${pass} passed, ${fail} failed"
[[ "${fail}" -eq 0 ]]
