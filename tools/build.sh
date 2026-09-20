#!/bin/bash
# 配布 zip のビルド（v2: インストールだけ版）
#   dist/AI秘書インストール_{Windows,Mac}_{ClaudeCode,Codex}.zip を作る
#   - Windows の BAT は CP932 + CRLF（日本語 Windows の cmd.exe 向け）。括弧チェックに通らなければ止まる
#   - ps1 は BOM 付き UTF-8 でなければ止まる（PowerShell 5.1 が日本語を読み違えるため）
#   - zip は UTF-8 ファイル名フラグ付き・実行権限保持（make_zip.py）
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tools/lint_bat.py install/windows/*.bat
for f in scripts/windows/*.ps1; do
  head -c 3 "$f" | xxd -p | grep -q '^efbbbf$' || { echo "NG: BOM がありません: $f"; exit 1; }
done
bash -n install/mac/install.sh scripts/mac/apply.sh

crlf() { perl -pe 's/\r?\n/\r\n/'; }
bom_crlf() { printf '\xEF\xBB\xBF'; crlf; }
REFERRAL="https://claude.ai/referral/HqNMYnZKXw"
mkdir -p dist
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

win_zip() { # agent label
  local a="$1" label="$2" name="AI秘書インストール_Windows_$2"
  local d="$TMP/$name"; mkdir -p "$d"
  local plan=""
  if [ "$a" = "claude" ]; then plan="
■ Claude の有料プラン
  ${label} を使うには Claude の有料プラン Pro が必要です。
  まだの方は、インストールより先に下のリンクから登録してください。
  ${REFERRAL}
"; fi
  iconv -f UTF-8 -t CP932 "install/windows/install-${a}.bat" | crlf > "$d/install-${a}.bat"
  bom_crlf > "$d/はじめにお読みください.txt" <<EOF
AI秘書インストール（Windows / ${label}）

■ 手順
  1. この zip を右クリック →「すべて展開」
  2. 展開したフォルダの install-${a}.bat をダブルクリック
     「WindowsによってPCが保護されました」と出たら「詳細情報」→「実行」
  3. 黒い画面の案内どおりに Enter を押す（5分ほど）
  4. 最後の Enter で ${label} が起動し、セットアップが自動で始まります
     はじめてのときはログイン画面が出るので、案内に従ってください

${plan}
■ このファイルがやること
  Git と ${label} を入れて、デスクトップに AI フォルダを作るだけです。
  設定（許可を求めない設定・秘書のスキル・デスクトップの入口）は、
  起動した ${label} が GitHub の手順書を読んで行います。

■ すでに ${label} が入っている人
  このファイルは不要です。デスクトップに AI フォルダを作り、そこで ${label} を開いて、
  講師から送られた1行を貼ってください。

■ うまくいかないとき
  %TEMP%\\ai-secretary-install.log を講師に送ってください。
EOF
  python3 tools/make_zip.py "$d" "dist/$name.zip"
  echo "built: dist/$name.zip"
}

mac_zip() { # agent label
  local a="$1" label="$2" name="AI秘書インストール_Mac_$2"
  local d="$TMP/$name"; mkdir -p "$d"
  local plan=""
  if [ "$a" = "claude" ]; then plan="
■ Claude の有料プラン
  ${label} を使うには Claude の有料プラン Pro が必要です。
  まだの方は、インストールより先に下のリンクから登録してください。
  ${REFERRAL}
"; fi
  cp install/mac/install.sh "install/mac/install-${a}.command" "$d/"
  chmod +x "$d/install.sh" "$d/install-${a}.command"
  cat > "$d/はじめにお読みください.txt" <<EOF
AI秘書インストール（Mac / ${label}）

■ いちばん簡単な方法（おすすめ）
  「ターミナル」を開いて、講師から送られた1行を貼って Enter。
  （この zip は使いません）

■ この zip を使う方法
  1. zip をダブルクリックして展開
  2. install-${a}.command を「右クリック →開く」（初回だけ。ダブルクリックだと止められます）
  3. ターミナルの案内どおりに Enter を押す（5分ほど）
  4. 最後の Enter で ${label} が起動し、セットアップが自動で始まります

${plan}
■ このファイルがやること
  Git（Xcode コマンドラインツール）と ${label} を入れて、デスクトップに AI フォルダを作るだけです。
  設定は、起動した ${label} が GitHub の手順書を読んで行います。
EOF
  python3 tools/make_zip.py "$d" "dist/$name.zip"
  echo "built: dist/$name.zip"
}

win_zip claude ClaudeCode
win_zip codex Codex
mac_zip claude ClaudeCode
mac_zip codex Codex
