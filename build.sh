#!/bin/bash
# 配布物ビルド: kit/ + starter/ -> dist/AI秘書セットアップキット_Windows_<ver>.zip
#  - setup1.bat は CP932 + CRLF（日本語Windowsのcmd.exe向け）
#  - txt/ps1 は UTF-8 BOM + CRLF（メモ帳／PowerShell向け）
#  - starter/ は assets/starter に同梱（BATが ~/.claude/skills と Desktop/AI へ配置）
set -euo pipefail
cd "$(dirname "$0")"
VERSION="${1:-v1.0}"
NAME="AI秘書セットアップキット_Windows_${VERSION}"
OUT="dist/$NAME"
rm -rf "$OUT" "dist/${NAME}.zip"
mkdir -p "$OUT/assets"

crlf() { perl -pe 's/\r?\n/\r\n/'; }
bom_crlf() { printf '\xEF\xBB\xBF'; crlf; }

iconv -f UTF-8 -t CP932 kit/setup1.bat | crlf > "$OUT/setup1.bat"
bom_crlf < "kit/はじめにお読みください.txt" > "$OUT/はじめにお読みください.txt"
bom_crlf < kit/assets/make_shortcuts.ps1 > "$OUT/assets/make_shortcuts.ps1"
cp kit/assets/settings.json "$OUT/assets/settings.json"
rsync -a --exclude '.DS_Store' starter/ "$OUT/assets/starter/"

python3 kit/make_zip.py "$OUT" "dist/${NAME}.zip"
echo "build ok: dist/${NAME}.zip"
unzip -l "dist/${NAME}.zip" | tail -n +4 | head -30

# ---- 設定のみ版（Claude Code / MCP 導入済みの人向け: インストール工程なし）----
NAME2="AI秘書セットアップキット_Windows_設定のみ_${VERSION}"
OUT2="dist/$NAME2"
rm -rf "$OUT2" "dist/${NAME2}.zip"
mkdir -p "$OUT2/assets"
iconv -f UTF-8 -t CP932 kit/setup1-settings-only.bat | crlf > "$OUT2/setup1-settings-only.bat"
bom_crlf < "kit/はじめにお読みください_設定のみ.txt" > "$OUT2/はじめにお読みください.txt"
bom_crlf < kit/assets/make_shortcuts.ps1 > "$OUT2/assets/make_shortcuts.ps1"
bom_crlf < kit/assets/merge_settings.ps1 > "$OUT2/assets/merge_settings.ps1"
cp kit/assets/settings.json "$OUT2/assets/settings.json"
rsync -a --exclude '.DS_Store' starter/ "$OUT2/assets/starter/"
python3 kit/make_zip.py "$OUT2" "dist/${NAME2}.zip"
echo "build ok: dist/${NAME2}.zip"
