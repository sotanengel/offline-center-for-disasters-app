#!/usr/bin/env bash
# Leap-SDK.xcframework が Pods に無い場合に DL する（CocoaPods git checkout 縮退対策）。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LEAP_POD="${ROOT}/ios/Pods/Leap-SDK"
XCFW="${LEAP_POD}/LeapSDK.xcframework"
URL="https://github.com/Liquid4All/leap-ios/releases/download/v0.9.4/LeapSDK.xcframework.zip"

if [[ -d "${XCFW}" ]]; then
  exit 0
fi

mkdir -p "${LEAP_POD}"
tmp="$(mktemp "${LEAP_POD}/LeapSDK.XXXXXX.zip")"
curl -fsSL -o "${tmp}" "${URL}"
unzip -qo "${tmp}" -d "${LEAP_POD}"
rm -f "${tmp}"
