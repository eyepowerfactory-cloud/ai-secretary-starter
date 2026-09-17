#!/bin/bash
# Codex の設定を変更前に戻す（Mac）: ~/.codex/config.toml.backup → config.toml
CFG="$HOME/.codex/config.toml"
echo "================================================="
echo "  Codex の設定を、変更前の状態に戻します"
echo "================================================="
echo
if [ ! -f "$CFG.backup" ]; then
  echo "退避ファイル config.toml.backup が見つかりません。"
  echo "変更前に config.toml が無かった場合は、次のファイルを削除すれば元どおりです:"
  echo "  $CFG"
  echo
  read -r -p "Enter で閉じます "; exit 1
fi
echo "$CFG.backup を config.toml に戻します。"
read -r -p "Enter で実行します (やめるときはこのウィンドウを閉じてください) "
if cp "$CFG.backup" "$CFG"; then
  echo "戻しました。Codex を起動し直すと反映されます。"
else
  echo "戻せませんでした。Codex を終了してからもう一度お試しください。"
  read -r -p "Enter で閉じます "; exit 1
fi
echo
read -r -p "Enter で閉じます "
exit 0
