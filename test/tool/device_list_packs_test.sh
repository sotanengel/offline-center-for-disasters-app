#!/usr/bin/env bash
# tool/device/list_packs.sh / install_all_packs.sh の前提チェック。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LIST="${ROOT}/tool/device/list_packs.sh"
INSTALL_ALL="${ROOT}/tool/device/install_all_packs.sh"

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

assert_file_executable "list_packs.sh is executable" "${LIST}"
assert_file_executable "install_all_packs.sh is executable" "${INSTALL_ALL}"

if [[ -f "${ROOT}/tools/out/tokyo/pack.sqlite" ]]; then
  output="$("${LIST}" 2>&1)"
  status=$?
  assert_eq "list_packs exits zero when tokyo exists" "0" "${status}"
  if [[ "${output}" == *"tokyo"* && "${output}" == *"ready"* ]]; then
    echo "PASS: list_packs shows tokyo ready"
    pass=$((pass + 1))
  else
    echo "FAIL: list_packs output missing tokyo ready" >&2
    fail=$((fail + 1))
  fi
else
  echo "SKIP: tools/out/tokyo/pack.sqlite not present"
fi

if [[ "${fail}" -gt 0 ]]; then
  echo "${pass} passed, ${fail} failed" >&2
  exit 1
fi

echo "${pass} passed, ${fail} failed"
