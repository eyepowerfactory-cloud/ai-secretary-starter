#!/bin/bash
# Claude Code 「許可を求めない」設定（Mac）
#  ~/.claude/settings.json を退避してから、必要な項目だけをマージする。インストール等は一切しない。
DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="$DIR/setup_log.txt"
CLAUDEDIR="$HOME/.claude"
CFG="$CLAUDEDIR/settings.json"
TPL="$DIR/assets/settings.json"
echo "===== permissions setup $(date) =====" > "$LOG"

echo "================================================="
echo "  Claude Code 「許可を求めない」設定 (Mac)"
echo "================================================="
echo
echo "Claude Code が作業のたびに「許可しますか?」と聞いてくるのを止めます。"
echo "危険な操作 (ファイルの一括削除・ディスク初期化・.env や鍵の読み取りなど) は"
echo "引き続き自動でブロックされます。"
echo
echo "対象ファイル: $CFG"
echo "今ある設定 (MCP・フック・許可リストなど) は消さず、必要な項目だけ足します。"
echo "実行前の内容は settings.json.backup に退避します。所要時間は数秒です。"
echo
read -r -p "Enter キーで開始します (やめるときはこのウィンドウを閉じてください) "

if [ ! -f "$TPL" ] || [ ! -f "$DIR/assets/merge_settings.js" ]; then
  echo "assets フォルダが見つかりません。zip を展開したフォルダごと置いて、その中から実行してください。"
  read -r -p "Enter で閉じます "; exit 1
fi
mkdir -p "$CLAUDEDIR"
if [ -f "$CFG" ]; then
  cp "$CFG" "$CFG.backup"
  echo "[1/2] 既存の設定を settings.json.backup に退避しました。"
else
  echo "[1/2] settings.json はまだ無いので、新しく作ります。"
fi
if osascript -l JavaScript "$DIR/assets/merge_settings.js" "$CFG" "$TPL" >> "$LOG" 2>&1; then
  echo "[2/2] 設定を書き込みました。"
else
  echo "       設定のマージに失敗しました。setup_log.txt を配布元にお送りください。"
  echo "       既存の settings.json はそのまま残しています。"
  read -r -p "Enter で閉じます "; exit 1
fi
echo
echo "================================================="
echo "  完了! 反映のしかた"
echo "================================================="
echo "  ・ターミナル (claude コマンド) で使っている場合"
echo "      → いったん終了して、もう一度 claude を起動すると反映されます。"
echo "  ・Claude デスクトップアプリで使っている場合"
echo "      → アプリを一度終了して開き直す。入力欄のそばのモード選択が"
echo "        「Bypass permissions」になっていれば OK です。"
echo "        出てこないときは 設定 → Claude Code → 「Allow bypass permissions mode」"
echo "        をオンにしてから、モード選択で「Bypass permissions」を選んでください。"
echo
echo "  元に戻したいときは、同じフォルダの「元に戻す.command」を実行してください。"
echo "================================================="
echo
read -r -p "Enter で閉じます "
exit 0
