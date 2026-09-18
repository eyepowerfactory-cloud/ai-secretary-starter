# AI秘書スターター（ai-secretary-starter）

Claude Code または Codex を「AI秘書」として使い始めるためのセットアップキットです。
**インストールは小さなスクリプト、設定は Claude Code / Codex 自身がこのリポジトリを読んで行う**、という2段構えになっています。

## 使い方（4パターン）

| | Claude Code | Codex |
|---|---|---|
| **Windows** | `install-claude.bat` をダブルクリック | `install-codex.bat` をダブルクリック |
| **Mac** | ターミナルに ①Claude の1行を貼る | ターミナルに ②Codex の1行を貼る |

- Windows の BAT は `dist/` の zip に入っています（すべて展開してから実行）。「WindowsによってPCが保護されました」と出たら「詳細情報」→「実行」
- Mac の1行:
  - ① Claude Code: `bash <(curl -fsSL https://raw.githubusercontent.com/eyepowerfactory-cloud/ai-secretary-starter/main/install/mac/install.sh) claude`
  - ② Codex: `bash <(curl -fsSL https://raw.githubusercontent.com/eyepowerfactory-cloud/ai-secretary-starter/main/install/mac/install.sh) codex`
  - ダブルクリックしたい場合は `dist/` の Mac 用 zip の `.command`（初回は右クリック →「開く」）

インストールが終わると、デスクトップの **AI** フォルダで Claude Code / Codex が起動し、セットアップが自動で始まります。

### すでに Claude Code / Codex が入っている人
インストールは不要です。デスクトップに **AI** フォルダを作り、そのフォルダで Claude Code（アプリなら Code タブ）または Codex を開いて、次の1行を貼ってください。

- Claude Code:
  `https://github.com/eyepowerfactory-cloud/ai-secretary-starter を今いるフォルダの .kit に git clone して（すでにあれば git pull）、.kit/setup-claude.md の通りにこのパソコンをセットアップして`
- Codex:
  `https://github.com/eyepowerfactory-cloud/ai-secretary-starter を今いるフォルダの .kit に git clone して（すでにあれば git pull）、.kit/setup-codex.md の通りにこのパソコンをセットアップして`

⚠️ Claude アプリでは、左上の `</>`（**Code**）を選んでから貼ってください。チャットや Cowork の画面ではパソコンの設定ができません。

## しくみ

```
install/            インストールだけ（Git と Claude Code / Codex。設定はしない）
  windows/install-claude.bat, install-codex.bat
  mac/install.sh（＋ダブルクリック用 .command）
setup-claude.md     Claude Code が読んで進める手順書（Windows / Mac 共通）
setup-codex.md      Codex が読んで進める手順書（Windows / Mac 共通）
scripts/            手順書から AI が実行する、決まった処理
  windows/apply.ps1   AI フォルダ・スキル・許可設定のマージ・入口・点検表
  mac/apply.sh        同上（Mac）
config/             許可を求めない設定のテンプレート（Claude: settings.json / Codex: config.toml）
starter/            秘書の中身（CLAUDE.md / AGENTS.md / tasks.md / memory / スキル4つ）
```

- 設定ファイルは上書きせず**マージ**します（既存の許可・MCP・モデル設定は残り、元のファイルは `.backup` に退避）
- 最後に点検表（`SETUP_CHECK.md`）がすべて OK になるまで「完了」にしません

## 旧版
2026年9月までの BAT 一式（setup1.bat など）は `legacy/v1/` にあります。
