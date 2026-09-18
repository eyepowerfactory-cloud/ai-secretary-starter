#!/bin/bash
# Codex 「許可を求めない」設定（Mac）
#  ~/.codex/config.toml を退避してから、無いキーだけを足す（Windows 版 ensure_codex_config.ps1 と同じ規則）。
#   - approval_policy / sandbox_mode はトップレベルなので、最初の [テーブル] より前＝先頭に挿入
#   - [sandbox_workspace_write] は無ければ末尾に追記
#  インストール等は一切しない。
DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="$DIR/setup_log.txt"
CODEXDIR="$HOME/.codex"
CFG="$CODEXDIR/config.toml"
TPL="$DIR/assets/config.toml"
echo "===== codex permissions setup $(date) =====" > "$LOG"

echo "================================================="
echo "  Codex 「許可を求めない」設定 (Mac)"
echo "================================================="
echo
echo "Codex が作業のたびに「許可しますか?」と聞いてくるのを止めます。"
echo "作業フォルダの外への書き込みだけは自動で止まります (安全側)。"
echo
echo "対象ファイル: $CFG"
echo "今ある設定 (MCP・プロファイル・モデル指定など) は消さず、無いキーだけ足します。"
echo "実行前の内容は config.toml.backup に退避します。所要時間は数秒です。"
echo
read -r -p "Enter キーで開始します (やめるときはこのウィンドウを閉じてください) "

if [ ! -f "$TPL" ]; then
  echo "assets フォルダが見つかりません。zip を展開したフォルダごと置いて、その中から実行してください。"
  read -r -p "Enter で閉じます "; exit 1
fi
mkdir -p "$CODEXDIR"
if [ ! -f "$CFG" ]; then
  cp "$TPL" "$CFG"
  echo "[1/2] config.toml はまだ無いので、新しく作りました。"
  echo "[2/2] 設定を書き込みました。"
else
  cp "$CFG" "$CFG.backup"
  echo "[1/2] 既存の設定を config.toml.backup に退避しました。"
  PRE=""
  grep -Eq '^[[:space:]]*approval_policy[[:space:]]*=' "$CFG" || PRE="${PRE}approval_policy = \"never\"\n"
  grep -Eq '^[[:space:]]*sandbox_mode[[:space:]]*=' "$CFG"    || PRE="${PRE}sandbox_mode = \"workspace-write\"\n"
  TMP="$(mktemp)"
  if [ -n "$PRE" ]; then
    printf "%b" "$PRE" > "$TMP"
  fi
  cat "$CFG" >> "$TMP"
  if ! grep -Eq '^[[:space:]]*\[sandbox_workspace_write\]' "$CFG"; then
    printf "\n[sandbox_workspace_write]\nnetwork_access = true\n" >> "$TMP"
  fi
  if cp "$TMP" "$CFG" 2>> "$LOG"; then
    echo "[2/2] 設定を書き込みました。"
  else
    echo "       設定の追記に失敗しました。setup_log.txt を配布元にお送りください。"
    read -r -p "Enter で閉じます "; exit 1
  fi
  rm -f "$TMP"
fi
echo
echo "================================================="
echo "  完了! 反映のしかた"
echo "================================================="
echo "  ・ターミナル (codex コマンド) で使っている場合"
echo "      → いったん終了して、もう一度 codex を起動すると反映されます。"
echo "  ・Codex デスクトップアプリで使っている場合"
echo "      → アプリを一度終了して開き直してください。"
echo
echo "  入った設定: approval_policy = \"never\" / sandbox_mode = \"workspace-write\""
echo "              [sandbox_workspace_write] network_access = true"
echo "  元に戻したいときは、同じフォルダの「元に戻す.command」を実行してください。"
echo "================================================="
echo
read -r -p "Enter で閉じます "
exit 0
