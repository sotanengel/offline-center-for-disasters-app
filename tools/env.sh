#!/usr/bin/env bash
# Takumi Guard ミラー経由でパッケージを取得するための環境変数を設定する。
# 使い方: source tools/env.sh
# トークンは ~/.config/pip/pip.conf から読み取り、リポジトリには保存しない。
PIPCONF="${HOME}/.config/pip/pip.conf"
if [[ ! -f "${PIPCONF}" ]]; then
  echo "警告: ${PIPCONF} が見つかりません。Takumi Guard の設定を確認してください。" >&2
  return 0 2>/dev/null || exit 0
fi
export UV_INDEX_URL="$(grep -o 'index-url = .*' "${PIPCONF}" | sed 's/index-url = //')"
export PIP_INDEX_URL="${UV_INDEX_URL}"
echo "UV_INDEX_URL を Takumi Guard ミラーに設定しました（ホスト: $(echo "${UV_INDEX_URL}" | sed -E 's|https://[^@]*@([^/]*)/.*|\1|')）"
