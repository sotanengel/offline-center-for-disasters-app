#!/usr/bin/env bash
# tool/device/install_pack.sh の前提チェックを検証する。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="${ROOT}/tool/device/install_pack.sh"

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

assert_file_executable() {
  local name="$1"
  local path="$2"
  if [[ -x "${path}" ]]; then
    echo "PASS: ${name}"
    pass=$((pass + 1))
  else
    echo "FAIL: ${name} (not executable: ${path})" >&2
    fail=$((fail + 1))
  fi
}

assert_file_executable "install_pack.sh is executable" "${SCRIPT}"

set +e
output="$("${SCRIPT}" missing-region 2>&1)"
status=$?
set -e

assert_eq "missing pack exits non-zero" "1" "${status}"
if [[ "${output}" == *"missing tools/out/missing-region/pack.sqlite"* ]] \
  || [[ "${output}" == *"tools/out/missing-region/pack.sqlite"* ]]; then
  echo "PASS: missing pack error message"
  pass=$((pass + 1))
else
  echo "FAIL: missing pack error message (output=${output})" >&2
  fail=$((fail + 1))
fi

if [[ "${fail}" -gt 0 ]]; then
  echo "${pass} passed, ${fail} failed" >&2
  exit 1
fi

echo "${pass} passed, ${fail} failed"
