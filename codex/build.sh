#!/bin/bash
# Codex版 配布物ビルド: codex/kit + 共用 starter -> dist/AI秘書セットアップキット_Windows_Codex_<ver>.zip
set -euo pipefail
cd "$(dirname "$0")"
VERSION="${1:-v1.0}"
NAME="AI秘書セットアップキット_Windows_Codex_${VERSION}"
OUT="../dist/$NAME"
rm -rf "$OUT" "../dist/${NAME}.zip"
mkdir -p "$OUT/assets/starter"

crlf() { perl -pe 's/\r?\n/\r\n/'; }
bom_crlf() { printf '\xEF\xBB\xBF'; crlf; }

iconv -f UTF-8 -t CP932 kit/setup1-codex.bat | crlf > "$OUT/setup1-codex.bat"
bom_crlf < "kit/はじめにお読みください.txt" > "$OUT/はじめにお読みください.txt"
bom_crlf < kit/assets/make_shortcuts_codex.ps1 > "$OUT/assets/make_shortcuts_codex.ps1"
cp kit/assets/config.toml "$OUT/assets/config.toml"
cp web/setup-codex.md "$OUT/assets/SETUP.md"
# 共用スターター（tasks/catalog/memory/skills）+ Codex固有の AGENTS.md
rsync -a --exclude '.DS_Store' --exclude 'CLAUDE.md' ../starter/ "$OUT/assets/starter/"
cp starter/AGENTS.md "$OUT/assets/starter/AGENTS.md"

python3 ../kit/make_zip.py "$OUT" "../dist/${NAME}.zip"
echo "build ok: dist/${NAME}.zip"
