#!/usr/bin/env bash
# ユニットテストと、iPhone シミュレータ上での integration_test を実行する。
# 使い方: tool/sim/test.sh
set -euo pipefail
cd "$(dirname "$0")/../.."

echo "=== flutter test (ユニット/ウィジェット) ==="
flutter test

echo "=== integration_test (iPhone シミュレータ) ==="
DEVICE_UDID=$(tool/sim/boot.sh | tail -1)
echo "デバイス: ${DEVICE_UDID}"
flutter test integration_test -d "${DEVICE_UDID}"
