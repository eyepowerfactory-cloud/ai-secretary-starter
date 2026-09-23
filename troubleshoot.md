# つまずいたときの切り分け・修復（AI が読む手順書）

この手順書は、**セットアップが途中で止まったパソコン**を、その場で AI（Claude Code / Codex）が
切り分けて直すためのものです。相手は**パソコンにくわしくない方**です。

## この手順書の進め方（AI へ）

- **日本語で、やさしく、1回に1つだけ**お願いする。専門用語は使わない（「PATH」→「ソフトの置き場所の登録」）。
- **待たせない**。1つ実行したら、何をしていて、あとどれくらいかかるかを1行で伝える。
- **勝手に何かを消さない**。ファイルの削除・設定の初期化は、必ず理由を説明して「消してよいですか」と聞いてから。
- **できないことは正直に言う**。3回試してだめなら Phase 4（講師に送る）へ進む。無限に試さない。
- 管理者パスワードが必要な操作は、**本人に画面を見てもらって**「はい」を押してもらう。

---

## Phase 0. いまの状態を知る

1. 診断ファイルを読む（`診断.bat` が作るもの）。どちらかにある。
   - `%TEMP%\ai-secretary-diagnose.txt`
   - デスクトップの `AI秘書_診断結果.txt`
2. 無ければ自分で調べる。
   ```
   where winget & where git & where claude & where codex
   ```
3. インストールのログ `%TEMP%\ai-secretary-install.log` の最後の20行を読む。
4. わかったことを**3行以内**で本人に伝える。例：「Git は入っています。Claude Code がまだです。ウイルス対策に止められた形跡があります。」

---

## Phase 1. 症状を1つに決める

診断の結果を、下の表のどれか1つに当てはめる。迷ったら本人に「黒い画面はどこまで進みましたか」と聞く。

| 症状 | 見分け方 | 行き先 |
|---|---|---|
| ファイルが消えた・画面が勝手に閉じた | 診断の「ウイルス対策が止めたもの」に記録がある／bat が見当たらない | Phase 2-A |
| Git で止まる | ログが `[1/4]` で終わっている | Phase 2-B |
| CLI（claude / codex）が入らない | `where claude` も `where codex` も「なし」 | Phase 2-C |
| 入っているのに「認識されません」と出る | インストールは成功しているのに `where` で見つからない | Phase 2-D |
| ログインできない | CLI は起動するが認証で止まる | Phase 2-E |
| AI フォルダ・設定が無い／壊れた | `.kit` や `AI` フォルダが無い | Phase 2-F |

---

## Phase 2. 手当て

### 2-A. ウイルス対策に止められた
1. 本人に**そのまま伝える**：「ウイルスではありません。念のため止められています」。不安にさせない。
2. **いちばん速い道は、bat を使わずに入れ直すこと**。Phase 2-C に進む。
3. bat を戻したいときだけ、本人に画面操作をしてもらう（AI は代行できない）。
   スタート →「Windows セキュリティ」→「ウイルスと脅威の防止」→「保護の履歴」→
   該当の項目 →「操作」→「復元」または「デバイスで許可」。
4. **同じ止まり方を繰り返させない**。復元した bat をもう一度動かすのではなく、2-C の1行ずつの方法に切り替える。

### 2-B. Git のところで止まる
1. 「画面いちばん下のタスクバーで、盾のアイコンが点滅していませんか」と聞く。あれば押して「はい」。
2. 止まったままなら、いったん中止（黒い画面を閉じる）してもらい、次を実行する。
   ```
   winget install -e --id Git.Git --source winget --accept-package-agreements --accept-source-agreements
   ```
3. `winget が認識されません` と出たら → Microsoft Store の「アプリ インストーラー」を更新してもらう。
   それも無理なら Git は飛ばしてよい。**Git が無くても先に進める**
   （`.kit` は zip をダウンロードして展開する方法で用意できる）。

### 2-C. CLI が入らない（claude / codex）
上から順に試す。1つ成功したら次へ行かない。

**Claude Code**
```
winget install -e --id Anthropic.ClaudeCode --source winget --accept-package-agreements --accept-source-agreements
```
```
curl -fsSL https://claude.ai/install.cmd -o "%TEMP%\claude-install.cmd" && "%TEMP%\claude-install.cmd"
```

**Codex**
```
winget install -e --id OpenAI.Codex --source winget --accept-package-agreements --accept-source-agreements
```
```
npm i -g @openai/codex
```
（`npm` が無い場合は先に Node.js：`winget install -e --id OpenJS.NodeJS.LTS --source winget --accept-package-agreements --accept-source-agreements`）

終わったら**必ず新しい黒い画面を開いてから** `claude --version` / `codex --version` を確認する
（同じ画面のままだと、入れたばかりのソフトが見つからない）。

### 2-D. 入っているのに「認識されません」
1. 黒い画面を**閉じて開き直す**。これで直ることがほとんど。
2. それでもだめなら、置き場所を直接確かめる。
   - Claude Code: `%USERPROFILE%\.local\bin\claude.exe`
   - Codex: `%LOCALAPPDATA%\Programs\OpenAI\Codex\bin\codex.exe`
3. あるのに見つからないときは、**本人の環境変数 PATH に1行足す**。理由を説明して同意をとってから実行する。
   ```
   setx PATH "%PATH%;%USERPROFILE%\.local\bin"
   ```
   実行後は黒い画面を開き直す。
4. パソコンの再起動で直ることもある。2回直らなければ Phase 4。

### 2-E. ログインできない
- Claude Code: `claude` → `/login` → ブラウザでサインイン。**Claude の有料プラン（Pro）が必要**。
  契約していない場合は、ここで先に契約してもらう（月払いを選んでもらう）。
- Codex: `codex` → ChatGPT アカウントでサインイン。
- ブラウザが開かない場合は、表示された URL を本人にコピーしてもらい、手で開いてもらう。
- サインイン後、`claude` の `/status`（Codex は `codex login status`）で確認する。

### 2-F. AI フォルダ・`.kit` が無い
1. デスクトップに `AI` フォルダを作る（無ければ）。
2. その中で `.kit` を用意する。
   ```
   git clone https://github.com/eyepowerfactory-cloud/ai-secretary-starter .kit
   ```
   Git が無ければ、`https://github.com/eyepowerfactory-cloud/ai-secretary-starter/archive/refs/heads/main.zip`
   をダウンロードして展開し、中身を `.kit` という名前のフォルダに置く。
3. 用意できたら Phase 3 へ。

---

## Phase 3. 元の道に戻す

直ったら、**最初からやり直さない**。途中から戻す。

1. `.kit/setup-claude.md`（Codex なら `.kit/setup-codex.md`）を読む。
2. `AI` フォルダと `SETUP_CHECK.md` の中身を見て、**どこまで終わっているか**を判断する。
3. 終わっていない Phase から再開する。すでに終わっている作業はやり直さない。
4. 最後に、その手順書の最終点検（ALL_OK）まで通す。

---

## Phase 4. 直らないときは、きれいに引き継ぐ

3回試してだめなとき、または本人が疲れているときは、**そこでやめる**。粘らない。

1. 下の形で**講師に送る文面**を作り、画面に出す（本人がコピーして LINE に貼れるように、記号や罫線は使わない）。

```
AI秘書のセットアップでつまずきました。
どこまで進んだか: （例）Claude Code のインストールまで
症状: （例）黒い画面が勝手に閉じる
試したこと: （例）winget で入れ直し、再起動
いまの状態: winget あり / git あり / claude なし / codex なし
```

2. `%TEMP%\ai-secretary-diagnose.txt`（またはデスクトップの `AI秘書_診断結果.txt`）も一緒に送るよう伝える。
3. 本人に「ここまでで十分です。あとはこちらで調べます」と伝えて終わる。**安心させて終わること。**
