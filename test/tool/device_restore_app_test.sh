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

check "アンインストールされる旨がコメントされている" \
  'grep -q "アンインストール" "${ROOT}/tool/device/lib.sh"'

# 2026-08-02 実機検証で判明: flutter test integration_test <dir> は
# ディレクトリ内のテストファイルごとにアプリを再インストールする。
# 実行終了時の 1 回だけ復元しても、途中のファイルで信頼が壊れると
# それ以降のファイルが全部巻き添えで失敗する。ファイル単位で復元・
# 信頼確認しなければ再発を防げない。
check "integration_test はファイル単位で実行される（ディレクトリ一括ではない）" \
  '! grep -qE "flutter test integration_test[^/]*-d" "${ROOT}/tool/device/test.sh"'

check "各ファイル実行後に device_restore_app を呼ぶ（for ループ内で呼ぶ）" \
  'awk "/^for test_file in/,/^done/" "${ROOT}/tool/device/test.sh" | grep -q "device_restore_app"'

check "device_restore_app が復元後に信頼を検証する" \
  'awk "/^device_restore_app\\(\\)/,/^}/" "${ROOT}/tool/device/lib.sh" | grep -q "device_assert_developer_trusted"'

check "device_restore_app は信頼結果を戻り値で伝える（trap で握りつぶさない）" \
  'awk "/^device_restore_app\\(\\)/,/^}/" "${ROOT}/tool/device/lib.sh" | grep -qE "return \\\"\\\$\\{DEVICE_EXIT_NOT_TRUSTED\\}\\\""'

check "信頼が壊れたら次のファイルへ進まず直ちに中断する" \
  '! grep -qE "trap .*device_restore_app" "${ROOT}/tool/device/test.sh" &&
   grep -qE "! device_restore_app" "${ROOT}/tool/device/test.sh"'

echo "${pass} passed, ${fail} failed"
[[ "${fail}" -eq 0 ]]
