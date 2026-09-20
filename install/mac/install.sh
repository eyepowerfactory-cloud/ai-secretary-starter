#!/bin/bash
# AI秘書 インストール（Mac 共通本体）
#   使い方: bash install.sh claude|codex
#   ・ターミナルに1行貼る方式:  bash <(curl -fsSL https://raw.githubusercontent.com/eyepowerfactory-cloud/ai-secretary-starter/main/install/mac/install.sh) claude
#   ・ダブルクリック方式: 同じフォルダの install-claude.command / install-codex.command がこれを呼ぶ
#   やること: Git（Xcode コマンドラインツール）と Claude Code / Codex を入れ、デスクトップに AI フォルダを作り、
#            AI フォルダで Claude Code / Codex を起動してセットアップの1行を渡す。
#   設定・スキル・入口は、起動した Claude Code / Codex が GitHub から取ってきて行う。
REFERRAL="https://claude.ai/referral/HqNMYnZKXw"
AGENT="$1"
if [ "$AGENT" != "claude" ] && [ "$AGENT" != "codex" ]; then
  echo "usage: install.sh claude|codex"; exit 2
fi
REPO="https://github.com/eyepowerfactory-cloud/ai-secretary-starter"
if [ "$AGENT" = "claude" ]; then NAME="Claude Code"; DOC="setup-claude.md"; else NAME="Codex"; DOC="setup-codex.md"; fi
FIRST="Clone $REPO into a folder named .kit here - run git pull if .kit already exists. Then read .kit/$DOC and follow it step by step. Talk to me in Japanese."
LINE_JA="$REPO を今いるフォルダの .kit に git clone して（すでにあれば git pull）、.kit/$DOC の通りにこのパソコンをセットアップして"
LOG="${TMPDIR:-/tmp}/ai-secretary-install.log"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
echo "===== install $AGENT $(date) =====" > "$LOG"

pause() { read -r -p "$1" _ </dev/tty; }

echo "================================================="
echo "  AI秘書 インストール  Mac / $NAME"
echo "================================================="
echo
echo "このMacに Git と $NAME を入れます。所要時間は 5分ほどです。"
echo "設定は、このあと起動する $NAME が自分で行います。"
echo "途中でパスワードを聞かれたら、Macにログインするときのパスワードを入れてください（文字は表示されません）。"
echo
pause "Enter キーで始めます（やめるときはこのウィンドウを閉じてください） "

# ---- [0/3] Claude の有料プラン（未加入の人だけ）----
#   登録はインストールより先。あとから入ると紹介リンクが効かない。
if [ "$AGENT" = "claude" ]; then
  echo
  echo "[0/3] Claude Code を使うには Claude の有料プラン Pro が必要です。"
  printf "       まだの方は Enter で登録ページを開きます（すでに持っている人は s + Enter で飛ばす）: "
  read -r _ans </dev/tty || _ans=s
  if [ "$_ans" != "s" ]; then
    open "$REFERRAL" >/dev/null 2>&1 || true
    pause "       登録が終わったら Enter を押してください "
  fi
fi

# ---- [1/3] Git（Xcode コマンドラインツール）----
if xcode-select -p >/dev/null 2>&1 && git --version >/dev/null 2>&1; then
  echo "[1/3] Git OK"
else
  echo "[1/3] Git が入っていません。これから出てくる画面で「インストール」を押してください（10分ほどかかることがあります）。"
  xcode-select --install >> "$LOG" 2>&1
  pause "インストールが終わったら Enter を押してください "
  if git --version >/dev/null 2>&1; then echo "[1/3] Git OK"; else echo "[1/3] Git はまだ入っていませんが、先へ進みます（$NAME が別の方法で進めます）"; fi
fi

# ---- [2/3] Claude Code / Codex（公式インストーラー）----
if command -v "$AGENT" >/dev/null 2>&1; then
  echo "[2/3] $NAME OK（$("$AGENT" --version 2>/dev/null | head -1)）"
else
  echo "[2/3] $NAME をインストールしています..."
  if [ "$AGENT" = "claude" ]; then
    curl -fsSL https://claude.ai/install.sh | bash >> "$LOG" 2>&1
  else
    curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh >> "$LOG" 2>&1
  fi
  hash -r
  if ! command -v "$AGENT" >/dev/null 2>&1 && command -v brew >/dev/null 2>&1; then
    echo "       別の方法で試しています..."
    if [ "$AGENT" = "claude" ]; then brew install --cask claude-code >> "$LOG" 2>&1; else brew install --cask codex >> "$LOG" 2>&1; fi
    hash -r
  fi
  if command -v "$AGENT" >/dev/null 2>&1; then
    echo "[2/3] $NAME OK"
  else
    echo "[2/3] $NAME が入りませんでした。ログ $LOG を講師に送ってください。"
    pause "Enter で閉じます "; exit 1
  fi
fi
# 次にターミナルを開いたときも使えるように PATH を登録（無いときだけ）
PROFILE="$HOME/.zprofile"
grep -q '.local/bin' "$PROFILE" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$PROFILE"

# ---- [3/3] デスクトップに AI フォルダ ----
AIDIR="$HOME/Desktop/AI"
mkdir -p "$AIDIR"
echo "[3/3] 作業フォルダ: $AIDIR"
[ -n "$AI_SETUP_DRYRUN" ] || printf "%s" "$LINE_JA" | pbcopy

echo
echo "================================================="
echo "  準備ができました"
echo "================================================="
echo " Enter を押すと、AI フォルダで $NAME が起動して、セットアップが始まります。"
echo " はじめてのときはログイン画面が出るので、画面の案内に従ってください。"
echo
if [ "$AGENT" = "claude" ]; then
  echo " アプリで進めたい場合: このウィンドウを閉じて、Claude アプリの Code タブで"
  echo " デスクトップの AI フォルダを選び、⌘V で貼り付けて Enter。貼り付ける1行はコピー済みです。"
else
  echo " アプリで進めたい場合: このウィンドウを閉じて、Codex アプリでデスクトップの AI フォルダを開き、"
  echo " ⌘V で貼り付けて Enter。貼り付ける1行はコピー済みです。"
fi
echo "================================================="
pause "Enter で $NAME を起動します "
if [ -n "$AI_SETUP_DRYRUN" ]; then echo "DRYRUN: cd $AIDIR && $AGENT \"$FIRST\""; exit 0; fi  # テスト用
cd "$AIDIR" && exec "$AGENT" "$FIRST" </dev/tty
