#!/usr/bin/env bash
# §20.5: lib/ 実行パスにネットワーク通信ライブラリを含めない静的チェック。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$ROOT/lib"

FORBIDDEN=(
  'package:http/'
  'package:dio/'
  'package:chopper/'
  'package:retrofit/'
  'dart:io.*HttpClient'
)

failed=0
for pattern in "${FORBIDDEN[@]}"; do
  if rg -n "$pattern" "$LIB" --glob '*.dart' 2>/dev/null; then
    echo "ERROR: 禁止 import を検出: $pattern" >&2
    failed=1
  fi
done

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "OK: lib/ にネットワーク通信 import はありません"
