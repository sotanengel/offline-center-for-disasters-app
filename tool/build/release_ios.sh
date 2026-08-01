#!/usr/bin/env bash
# 同梱パックを準備して iOS リリースビルドを行う。
#
# 使い方:
#   tool/build/release_ios.sh
#   tool/build/release_ios.sh && flutter install -d <UDID> --release
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

"${SCRIPT_DIR}/prepare_bundled_packs.sh"
cd "${ROOT}"
flutter pub get
flutter build ios --release
