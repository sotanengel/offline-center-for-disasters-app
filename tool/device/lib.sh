#!/usr/bin/env bash
# 実機テスト共通ライブラリ（source 専用）
set -euo pipefail

readonly DEVICE_EXIT_OK=0
readonly DEVICE_EXIT_NO_DEVICE=11
readonly DEVICE_EXIT_NOT_TRUSTED=12
readonly DEVICE_EXIT_LAUNCH_FAILED=13
readonly DEVICE_EXIT_TIMEOUT=14

device_log() {
  echo "[device] $*"
}

# 指定秒でシェルコマンドを打ち切る（macOS に timeout(1) が無いため自前実装）。
# 使い方: device_run_with_timeout <秒> <シェルコマンド文字列>
# 戻り値: コマンドの終了コード。時間切れなら DEVICE_EXIT_TIMEOUT。
#
# 実機テストは開発者未信頼などでアプリが起動できないと無期限に固まるため、
# 必ずこれで包んで「ハングではなく失敗」にする。
device_run_with_timeout() {
  local limit="$1"
  local command="$2"

  # 時間切れで打ち切ったことを wait 側へ伝える印
  local fired_marker
  fired_marker="$(mktemp "${TMPDIR:-/tmp}/ocd-timeout.XXXXXX")"
  rm -f "${fired_marker}"

  bash -c "${command}" &
  local cmd_pid=$!

  (
    local waited=0
    while ((waited < limit)); do
      sleep 1
      kill -0 "${cmd_pid}" 2>/dev/null || exit 0
      waited=$((waited + 1))
    done
    : >"${fired_marker}"
    kill -TERM "${cmd_pid}" 2>/dev/null || true
    sleep 3
    kill -KILL "${cmd_pid}" 2>/dev/null || true
  ) &
  local watchdog_pid=$!

  local cmd_status=0
  wait "${cmd_pid}" || cmd_status=$?

  kill "${watchdog_pid}" 2>/dev/null || true
  wait "${watchdog_pid}" 2>/dev/null || true

  if [[ -e "${fired_marker}" ]]; then
    rm -f "${fired_marker}"
    return "${DEVICE_EXIT_TIMEOUT}"
  fi
  rm -f "${fired_marker}"

  return "${cmd_status}"
}

# アプリが実機に既にインストールされているか。
# flutter install は「古い版をアンインストール」するため、その際に
# Personal Team のデベロッパプロファイルごと消えて信頼が解除される。
# 既に入っているなら再インストールを避けるための判定。
device_app_installed() {
  local device="$1"
  local bundle_id="${2:-dev.offlinecenter.offlineCenterForDisasters}"
  xcrun devicectl device info apps --device "${device}" 2>/dev/null \
    | grep -q "${bundle_id}"
}

# flutter のログが「アプリを起動できずに停滞している」ことを示すか。
#
# 注意: 「Xcode is taking longer than expected」は Flutter が 30 秒タイマーで
# 出す進行中の警告であり、失敗ではない（flutter_tools/lib/src/ios/devices.dart）。
# Flutter 自身はその後も待機を続けるため、ここで停滞と判定して kill すると
# 正常に進行中の起動を横から打ち切ってしまう（2026-08-02 実機検証で実際に発生）。
# 「アプリの起動に失敗した」ことが明言された行のみを停滞とみなす。
device_log_indicates_launch_stall() {
  local log_file="$1"
  [[ -f "${log_file}" ]] || return 1
  grep -qE "Error launching application|Could not run .* on |Timed out waiting for .* to start" \
    "${log_file}"
}

# テスト後にアプリとパックを入れ直し、開発者信頼を維持する。
#
# flutter test -d <device> は実行後にアプリをアンインストールする。そのデベロッパの
# 最後のアプリが消えるとプロファイルごと端末から外れ、次回は必ず「未信頼」に戻って
# 手動タップが要る。テスト直後に入れ直しておけば信頼が保たれる。
#
# 後始末なので、失敗しても呼び出し元の終了コードは変えない（常に 0）。
device_restore_app() {
  local device="$1"
  local region="${2:-tokyo}"
  local script_dir="${3:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

  if device_app_installed "${device}"; then
    device_log "restore skipped: app still installed"
    return 0
  fi

  device_log "restore: reinstalling app to keep developer profile (信頼維持)"
  if ! flutter install -d "${device}" >/dev/null 2>&1; then
    device_log "warn restore failed at flutter install"
    return 0
  fi
  if ! "${script_dir}/install_pack.sh" "${region}" "${device}" >/dev/null 2>&1; then
    device_log "warn restore failed at install_pack"
    return 0
  fi
  device_log "restore done region=${region}"
  return 0
}

# osascript（Xcode 自動操作）がエラー終了したログか。
#
# 注意: これは exitCode が非ゼロだったことしか見ておらず、原因を確定するもの
# ではない（未許可以外にも、他プロセスに kill された場合などで同じ文言が出る。
# 2026-08-02 実機検証では、停滞の誤検知による pkill が原因でこれが出たことがある）。
# 呼び出し側では「原因の可能性がある」程度の案内にとどめること。
device_log_indicates_automation_permission_denied() {
  local log_file="$1"
  [[ -f "${log_file}" ]] || return 1
  grep -qE "Error executing osascript|not allowed to send Apple events" \
    "${log_file}"
}

device_print_trust_guide() {
  cat <<'EOF'
【iPhone で開発者を信頼する（初回のみ・再インストール後も必要）】

1. iPhone の「設定」を開く
2. 「一般」→「VPNとデバイス管理」（または「デバイス管理」）
3. 「デベロッパ App」に表示されているプロフィール（例: 颯大 長原）をタップ
4. 「"颯大 長原"を信頼」→ 確認で「信頼」

信頼後、ホーム画面からアプリを一度手動で起動できることを確認してから、
Mac 側で統合テストを再実行してください。

  tool/device/test.sh <UDID>
EOF
}

# devicectl でアプリ起動を試み、開発者未信頼なら DEVICE_EXIT_NOT_TRUSTED。
device_assert_developer_trusted() {
  local device="$1"
  local bundle_id="${2:-dev.offlinecenter.offlineCenterForDisasters}"
  local output
  local cmd_status=0

  output="$(xcrun devicectl device process launch \
    --device "${device}" \
    --terminate-existing \
    "${bundle_id}" 2>&1)" || cmd_status=$?

  if [[ "${cmd_status}" -eq 0 ]]; then
    device_log "developer trust ok bundle=${bundle_id}"
    return "${DEVICE_EXIT_OK}"
  fi

  if [[ "${output}" == *"not been explicitly trusted"* ]] \
    || [[ "${output}" == *"BSErrorCodeDescription = Security"* ]] \
    || [[ "${output}" == *"invalid code signature"* ]]; then
    device_log "error developer app certificate is not trusted on device"
    device_print_trust_guide
    return "${DEVICE_EXIT_NOT_TRUSTED}"
  fi

  if [[ "${output}" == *"is not installed"* ]]; then
    device_log "error app not installed bundle=${bundle_id}; run flutter install first"
    return "${DEVICE_EXIT_LAUNCH_FAILED}"
  fi

  device_log "error app launch failed:"
  echo "${output}" >&2
  return "${DEVICE_EXIT_LAUNCH_FAILED}"
}
