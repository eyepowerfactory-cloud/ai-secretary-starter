#!/bin/bash
# AI秘書の土台を配置して点検する（Mac）
#   セットアップ指示書（setup-claude.md / setup-codex.md）から Claude Code / Codex が実行する。人が直接叩く想定ではない。
#   - 何度実行しても同じ結果になる（既にあるファイルは上書きしない。設定はマージ）
#   - 最後に点検表を AI フォルダの SETUP_CHECK.md に書き、画面にも出す
# 使い方: bash <kit>/scripts/mac/apply.sh claude|codex [--check] [--ai-dir <path>]
#   macOS 標準の bash 3.2 / osascript だけで動く（python / node 不要）
AGENT="$1"; shift || true
CHECK_ONLY=0; AI_DIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK_ONLY=1 ;;
    --ai-dir) shift; AI_DIR="$1" ;;
  esac
  shift
done
if [ "$AGENT" != "claude" ] && [ "$AGENT" != "codex" ]; then
  echo "usage: apply.sh claude|codex [--check] [--ai-dir <path>]"; exit 2
fi

HERE="$(cd "$(dirname "$0")" && pwd)"
KIT="$(cd "$HERE/../.." && pwd)"
STARTER="$KIT/starter"
DESKTOP="$HOME/Desktop"
[ -n "$AI_DIR" ] || AI_DIR="$DESKTOP/AI"
SKILLS="morning-briefing meeting-notes doc-draft learn"

if [ "$AGENT" = "claude" ]; then
  AGENT_DIR="$HOME/.claude"; SKILL_DIR="$AGENT_DIR/skills"; CFG="$AGENT_DIR/settings.json"
  TPL="$KIT/config/claude-settings.json"; RULES="CLAUDE.md"
else
  AGENT_DIR="$HOME/.codex"; SKILL_DIR="$HOME/.agents/skills"; CFG="$AGENT_DIR/config.toml"
  TPL="$KIT/config/codex-config.toml"; RULES="AGENTS.md"
fi

echo "kit      : $KIT"
echo "desktop  : $DESKTOP"
echo "ai folder: $AI_DIR"

urlencode() { osascript -l JavaScript -e 'function run(a){return encodeURIComponent(a[0])}' "$1"; }

merge_codex_config() {
  # 無いキーだけ足す（既存の値は尊重）。トップレベルのキーは最初の [テーブル] より前＝先頭に入れる
  if [ ! -f "$CFG" ]; then cp "$TPL" "$CFG"; echo "new (copied template)"; return 0; fi
  local pre="" tmp
  grep -Eq '^[[:space:]]*approval_policy[[:space:]]*=' "$CFG" || pre="${pre}approval_policy = \"never\"\n"
  grep -Eq '^[[:space:]]*sandbox_mode[[:space:]]*=' "$CFG"    || pre="${pre}sandbox_mode = \"workspace-write\"\n"
  tmp="$(mktemp)"
  [ -n "$pre" ] && printf "%b" "$pre" > "$tmp"
  cat "$CFG" >> "$tmp"
  grep -Eq '^[[:space:]]*\[sandbox_workspace_write\]' "$CFG" || printf "\n[sandbox_workspace_write]\nnetwork_access = true\n" >> "$tmp"
  cp "$tmp" "$CFG" && rm -f "$tmp" && echo "merged"
}

if [ "$CHECK_ONLY" -eq 0 ]; then
  # 1) AI フォルダと秘書の中身（既にあるものは残す）
  mkdir -p "$AI_DIR/memory"
  for f in "$RULES" tasks.md SKILL_CATALOG.md memory/README.md memory/condition.md; do
    if [ ! -e "$AI_DIR/$f" ]; then cp "$STARTER/$f" "$AI_DIR/$f" && echo "copied   : $f"; else echo "kept     : $f"; fi
  done

  # 2) スキル4つ（既にあるものは残す）
  mkdir -p "$SKILL_DIR"
  for s in $SKILLS; do
    if [ ! -f "$SKILL_DIR/$s/SKILL.md" ]; then cp -R "$STARTER/skills/$s" "$SKILL_DIR/" && echo "skill    : installed $s"; else echo "skill    : kept $s"; fi
  done

  # 3) 許可を求めない設定（退避してからマージ）
  mkdir -p "$AGENT_DIR"
  [ -f "$CFG" ] && cp "$CFG" "$CFG.backup" && echo "backup   : $CFG.backup"
  if [ "$AGENT" = "claude" ]; then
    echo "settings : $(osascript -l JavaScript "$HERE/merge_claude_settings.js" "$CFG" "$TPL" 2>&1)"
  else
    echo "settings : $(merge_codex_config 2>&1)"
  fi

  # 4) デスクトップの入口
  if [ "$AGENT" = "claude" ]; then
    enc="$(urlencode "$AI_DIR")"
    cat > "$DESKTOP/AI秘書 (Claude).webloc" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>URL</key><string>claude://code/new?folder=$enc</string></dict></plist>
EOF
    SC="$DESKTOP/AI秘書を起動 (ターミナル).command"
    printf '#!/bin/bash\nexport PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"\ncd "%s" && exec claude\n' "$AI_DIR" > "$SC"
  else
    SC="$DESKTOP/AI秘書を起動 (Codex・ターミナル).command"
    printf '#!/bin/bash\nexport PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"\ncd "%s" && exec codex\n' "$AI_DIR" > "$SC"
  fi
  chmod +x "$SC" && echo "shortcut : created"
fi

# 5) 点検表
ROWS=""; NG=0
row() { # name ok detail
  local mark="OK"; [ "$2" = "1" ] || { mark="NG"; NG=$((NG+1)); }
  ROWS="${ROWS}${mark}|$1|$3
"
}
ver() { "$@" --version 2>/dev/null | head -1; }
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
g="$(xcode-select -p >/dev/null 2>&1 && ver git)"; row "Git" "$([ -n "$g" ] && echo 1)" "$g"
c="$(ver "$AGENT")"
if [ "$AGENT" = "claude" ]; then row "Claude Code (コマンド版)" "$([ -n "$c" ] && echo 1)" "$c"; else row "Codex (コマンド版)" "$([ -n "$c" ] && echo 1)" "$c"; fi
row "AI フォルダ" "$([ -d "$AI_DIR" ] && echo 1)" "$AI_DIR"
for f in "$RULES" tasks.md SKILL_CATALOG.md memory/condition.md; do row "  $f" "$([ -f "$AI_DIR/$f" ] && echo 1)" ""; done
for s in $SKILLS; do row "スキル $s" "$([ -f "$SKILL_DIR/$s/SKILL.md" ] && echo 1)" ""; done
if [ "$AGENT" = "claude" ]; then
  mode="$(osascript -l JavaScript -e 'ObjC.import("Foundation");function run(a){var s=$.NSString.stringWithContentsOfFileEncodingError($(a[0]),$.NSUTF8StringEncoding,null);if(s.isNil())return "not found";try{return "defaultMode="+JSON.parse(ObjC.unwrap(s)).permissions.defaultMode}catch(e){return "broken"}}' "$CFG" 2>/dev/null)"
  row "許可を求めない設定" "$([ "$mode" = "defaultMode=bypassPermissions" ] && echo 1)" "$mode"
  row "デスクトップの入口" "$([ -f "$DESKTOP/AI秘書 (Claude).webloc" ] && echo 1)" "AI秘書 (Claude).webloc"
else
  ap="$(grep -E '^[[:space:]]*approval_policy[[:space:]]*=' "$CFG" 2>/dev/null | head -1 | sed -E 's/.*"([^"]*)".*/\1/')"
  sb="$(grep -E '^[[:space:]]*sandbox_mode[[:space:]]*=' "$CFG" 2>/dev/null | head -1 | sed -E 's/.*"([^"]*)".*/\1/')"
  row "許可を求めない設定" "$([ "$ap" = "never" ] && echo 1)" "approval_policy=$ap sandbox_mode=$sb"
  row "デスクトップの入口" "$([ -f "$DESKTOP/AI秘書を起動 (Codex・ターミナル).command" ] && echo 1)" "AI秘書を起動 (Codex・ターミナル).command"
fi

if [ -d "$AI_DIR" ]; then
  {
    echo "# セットアップ点検表（$AGENT / Mac）"
    echo
    echo "- 日時: $(date '+%Y-%m-%d %H:%M')"
    echo "- デスクトップ: $DESKTOP"
    echo
    echo "| 項目 | 結果 | 詳細 |"
    echo "|---|---|---|"
    printf "%s" "$ROWS" | while IFS='|' read -r m n d; do [ -n "$m" ] && echo "| $n | $m | $d |"; done
    echo
    if [ "$NG" -eq 0 ]; then echo "結果: すべて OK"; else echo "結果: NG が $NG 件"; fi
  } > "$AI_DIR/SETUP_CHECK.md"
fi
echo
printf "%s" "$ROWS" | while IFS='|' read -r m n d; do [ -n "$m" ] && echo "[$m] $n  $d"; done
if [ "$NG" -eq 0 ]; then echo "RESULT: ALL_OK"; else echo "RESULT: NG=$NG"; fi
exit 0
