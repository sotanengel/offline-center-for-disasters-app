#!/usr/bin/env bash
# iOS Info.plist に必須プライバシー説明が含まれることを検証する。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLIST="${ROOT}/ios/Runner/Info.plist"

required_keys=(
  NSLocationWhenInUseUsageDescription
  NSMicrophoneUsageDescription
  NSSpeechRecognitionUsageDescription
  NSMotionUsageDescription
)

missing=0
for key in "${required_keys[@]}"; do
  if ! grep -q "<key>${key}</key>" "${PLIST}"; then
    echo "FAIL: missing ${key} in Info.plist" >&2
    missing=$((missing + 1))
  else
    echo "PASS: ${key}"
  fi
done

if [[ "${missing}" -gt 0 ]]; then
  exit 1
fi
echo "All privacy usage description keys present."
