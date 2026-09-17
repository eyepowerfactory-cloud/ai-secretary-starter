#!/bin/bash
# 「許可を求めない」設定だけの単体キット → dist/ClaudeCode_許可を求めない設定_Windows_<ver>.zip
#  - assets/settings.json と assets/merge_settings.ps1 は kit/assets から毎回コピー（原本は kit 側）
set -euo pipefail
cd "$(dirname "$0")"
VERSION="${1:-v1.0}"
NAME="ClaudeCode_許可を求めない設定_Windows_${VERSION}"
OUT="../dist/$NAME"
rm -rf "$OUT" "../dist/${NAME}.zip"
mkdir -p "$OUT/assets" assets
cp ../kit/assets/settings.json ../kit/assets/merge_settings.ps1 assets/
crlf() { perl -pe 's/\r?\n/\r\n/'; }
bom_crlf() { printf '\xEF\xBB\xBF'; crlf; }
iconv -f UTF-8 -t CP932 claude-no-permission-prompt.bat | crlf > "$OUT/claude-no-permission-prompt.bat"
iconv -f UTF-8 -t CP932 "元に戻す.bat" | crlf > "$OUT/元に戻す.bat"
bom_crlf < "はじめにお読みください.txt" > "$OUT/はじめにお読みください.txt"
bom_crlf < assets/merge_settings.ps1 > "$OUT/assets/merge_settings.ps1"
cp assets/settings.json "$OUT/assets/settings.json"
python3 ../kit/make_zip.py "$OUT" "../dist/${NAME}.zip"
echo "build ok: dist/${NAME}.zip"
