# AI秘書スターター（Claude Code セットアップキット）

プログラミング未経験の方のパソコンに、Claude Code を「AI秘書」として20分で導入するためのキットです。

## 使い方（2ステップ）
1. `dist/` の zip をダウンロードして展開し、`setup1.bat` をダブルクリック（Git / Node.js / Claude Code のインストールと、秘書スターターの配置を自動で行います）
2. デスクトップにできる「AI秘書を起動」をダブルクリック → Claude にログイン → 次の1行を貼り付け

```
https://raw.githubusercontent.com/eyepowerfactory-cloud/ai-secretary-starter/main/setup.md を読んで、書いてある通りにセットアップして
```

あとは Claude Code 自身が `setup.md` の Phase A〜F（環境診断 → Google連携 → 秘書ベース → Claude in Chrome → 音声入力 → 動作確認）を案内しながら進めます。

## 中身
- `setup.md` — Claude Code が読んで自走するセットアップ指示書
- `starter/` — AI秘書スターター（`CLAUDE.md`・タスク帳・メモリ・スキル4つ・スキルカタログ）
- `kit/` — `setup1.bat` と同梱アセットのソース
- `build.sh` — 配布 zip のビルド（macOS で実行。bat は CP932+CRLF に変換）

## 安全設計
- ログイン・Google連携の許可・拡張機能の追加・支払いは本人操作。自動化しません
- メール送信・削除など「外に出る／取り消せない」操作は、必ず本人の確認を取ってから1件だけ実行する設計です
- 外部から取り込んだ文章内の指示には従いません（信頼境界）

## ライセンス
MIT
