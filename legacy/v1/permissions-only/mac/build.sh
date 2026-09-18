#!/bin/bash
# Mac 版「許可を求めない設定」単体キット（Claude / Codex 別 zip）
#   dist/ClaudeCode_許可を求めない設定_Mac_<ver>.zip
#   dist/Codex_許可を求めない設定_Mac_<ver>.zip
#  - .command は UTF-8 / LF のまま・実行権限付き（make_zip.py が unix 属性を保持）
#  - assets の settings.json / config.toml は原本（kit/assets・codex/kit/assets）からビルド時コピー
set -euo pipefail
cd "$(dirname "$0")"
VERSION="${1:-v1.0}"
DIST="../../dist"

build_one() {
  local name="$1" cmd="$2" restore="$3" readme="$4" asset_src="$5" asset_name="$6" extra="${7:-}"
  local out="$DIST/$name"
  rm -rf "$out" "$DIST/$name.zip"
  mkdir -p "$out/assets"
  cp "$cmd" "$out/$cmd"
  cp "$restore" "$out/元に戻す.command"
  cp "$readme" "$out/はじめにお読みください.txt"
  cp "$asset_src" "$out/assets/$asset_name"
  [ -n "$extra" ] && cp "$extra" "$out/assets/"
  chmod 755 "$out"/*.command
  python3 ../../kit/make_zip.py "$out" "$DIST/$name.zip"
  echo "build ok: dist/$name.zip"
}

build_one "ClaudeCode_許可を求めない設定_Mac_${VERSION}" \
  claude-no-permission-prompt.command "元に戻す（Claude）.command" "はじめにお読みください_Claude.txt" \
  ../../kit/assets/settings.json settings.json assets/merge_settings.js

build_one "Codex_許可を求めない設定_Mac_${VERSION}" \
  codex-no-permission-prompt.command "元に戻す（Codex）.command" "はじめにお読みください_Codex.txt" \
  ../../codex/kit/assets/config.toml config.toml
