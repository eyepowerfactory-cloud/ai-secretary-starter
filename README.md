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
  windows/diagnose.bat  つまずいたとき用の診断（zip では「診断.bat」）
  mac/install.sh（＋ダブルクリック用 .command）
setup-claude.md     Claude Code が読んで進める手順書（Windows / Mac 共通）
setup-codex.md      Codex が読んで進める手順書（Windows / Mac 共通）
troubleshoot.md     つまずいたときに AI が読む、切り分け・修復の手順書
scripts/            手順書から AI が実行する、決まった処理
  windows/apply.ps1   AI フォルダ・スキル・許可設定のマージ・入口・点検表
  mac/apply.sh        同上（Mac）
config/             許可を求めない設定のテンプレート（Claude: settings.json / Codex: config.toml）
starter/            秘書の中身（CLAUDE.md / AGENTS.md / tasks.md / memory / スキル4つ）
```

- 設定ファイルは上書きせず**マージ**します（既存の許可・MCP・モデル設定は残り、元のファイルは `.backup` に退避）
- 最後に点検表（`SETUP_CHECK.md`）がすべて OK になるまで「完了」にしません

## うまくいかないとき

zip の中の **「診断.bat」** をダブルクリックします（30秒・何も変更しません）。

1. いま何が入っていて何が足りないかを調べ、デスクトップの `AI秘書_診断結果.txt` に保存し、クリップボードにコピーします
2. Claude Code / Codex がすでに入っていれば、そのまま AI が起動し、`troubleshoot.md` の手順で
   **その場で切り分け → 修復 → 元の手順書への復帰** まで伴走します
3. まだ AI が入っていない場合は、コピーされた内容をそのまま講師に送ってもらえば状況が伝わります

途中で止まる代表例（ウイルス対策にブロックされた・Git で止まる・「認識されません」・ログインできない）の
手当ては、zip 同梱の「うまくいかないとき.txt」と `troubleshoot.md` に書いてあります。

## 旧版
2026年9月までの BAT 一式（setup1.bat など）は `legacy/v1/` にあります。
