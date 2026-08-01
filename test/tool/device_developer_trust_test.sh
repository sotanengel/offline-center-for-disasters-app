#!/usr/bin/env bash
# tool/device/ensure_developer_trust.sh の前提チェック。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TRUST="${ROOT}/tool/device/ensure_developer_trust.sh"
LIB="${ROOT}/tool/device/lib.sh"

pass=0
fail=0

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

assert_file_executable "ensure_developer_trust.sh is executable" "${TRUST}"

if grep -q "VPNとデバイス管理" "${LIB}"; then
  echo "PASS: trust guide text present"
  pass=$((pass + 1))
else
  echo "FAIL: trust guide text missing in lib.sh" >&2
  fail=$((fail + 1))
fi

if [[ "${fail}" -gt 0 ]]; then
  echo "${pass} passed, ${fail} failed" >&2
  exit 1
fi

echo "${pass} passed, ${fail} failed"
