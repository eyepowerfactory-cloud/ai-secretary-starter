@echo off
chcp 932 >nul
setlocal
title AI秘書 インストール - Claude Code
rem ------------------------------------------------------------
rem  AI秘書 インストール (Windows / Claude Code)
rem  やること: Git と Claude Code を入れて、デスクトップに AI フォルダを作り、
rem           Claude Code を起動してセットアップの1行を渡す。
rem  設定・スキル・ショートカットは、起動した Claude Code が GitHub から取ってきて行う。
rem  注意: if/for の ( ) ブロックは使わない (括弧1文字で即終了する事故の再発防止)。
rem        変更したら tools\lint_bat.py を通すこと。
rem  v2.1 (2026-09-22): Windows セキュリティに止められない書き方に変更。
rem        - PowerShell でネットのスクリプトを直接実行する書き方をやめた (ウイルス対策が
rem          不審なスクリプトとして BAT ごと隔離し、黒い画面も落ちた)
rem        - Git / Claude Code は winget (Microsoft 公式) を先に使い、だめなときだけ公式 install.cmd
rem        - winget は --source winget 固定 (Microsoft Store 側の同意待ちで止まるのを防ぐ)
rem        - 進み具合を画面に出す (ログにだけ流すと「止まった」ように見えた)
rem        - zip の中から直接開いたら、展開を促して止める
rem ------------------------------------------------------------
set "LOG=%TEMP%\ai-secretary-install.log"
set "WG=--source winget --accept-package-agreements --accept-source-agreements"
set "REPO=https://github.com/eyepowerfactory-cloud/ai-secretary-starter"
set "REFERRAL=https://claude.ai/referral/HqNMYnZKXw"
set "FIRST=Clone %REPO% into a folder named .kit here - run git pull if .kit already exists; if git is missing, download %REPO%/archive/refs/heads/main.zip and extract it as .kit. Then read .kit/setup-claude.md and follow it step by step. Talk to me in Japanese."
set "LINE_JA=%REPO% を今いるフォルダの .kit に git clone して (すでにあれば git pull)、.kit/setup-claude.md の通りにこのパソコンをセットアップして"
echo ===== install-claude v2.1 %date% %time% ===== > "%LOG%"

rem ---- zip の中から直接開かれたら止める (一時フォルダで動き、途中で消されやすい) ----
echo %~dp0| findstr /i /c:".zip\\" >nul
if errorlevel 1 goto ZIP_OK
echo.
echo  このファイルは zip の中から開かれています。このままでは正しく動きません。
echo.
echo   1. この黒い画面を閉じる
echo   2. zip を右クリック →「すべて展開」
echo   3. 展開してできたフォルダの中の install-claude.bat をダブルクリック
echo.
pause
exit /b 1
:ZIP_OK

echo =================================================
echo   AI秘書 インストール  Windows / Claude Code
echo =================================================
echo.
echo このパソコンに Git と Claude Code を入れます。所要時間は 5分ほどです。
echo 設定は、このあと起動する Claude Code が自分で行います。
echo 途中で青い確認画面が出たら「はい」を押してください。
echo.
pause

rem ---- [0/4] Claude の有料プラン ----
rem  Claude Code は Claude の有料プラン Pro で動く。未加入の人はここで先に登録してもらう。
rem  注意: 登録はインストールより先。あとから入ると紹介リンクが効かない。
echo.
echo [0/4] Claude Code を使うには Claude の有料プラン Pro が必要です。
echo        まだの方は、いまブラウザで登録ページを開きます。
choice /c YN /n /t 30 /d N /m "       登録ページを開きますか? Y=開く / N=すでに持っている  30秒で N"
if errorlevel 2 goto PLAN_END
start "" "%REFERRAL%"
echo.
echo        ブラウザでページを開きました。登録が終わったら、
echo        この黒い画面に戻って Enter を押してください。
pause
:PLAN_END

rem ---- 使える道具を探すための PATH 読み直し ----
call :REFRESH

rem ---- [1/4] Git ----
where git >nul 2>&1
if not errorlevel 1 goto GIT_OK
where winget >nul 2>&1
if errorlevel 1 goto GIT_SKIP
echo [1/4] Git をインストールしています... 1-3分かかります
echo        下に進み具合が出ます。数字が止まって見えたら、画面の一番下のタスクバーで
echo        点滅している盾のアイコンを押して「はい」を押してください。
winget install -e --id Git.Git %WG%
echo git winget exit=%errorlevel% >> "%LOG%"
call :REFRESH
where git >nul 2>&1
if not errorlevel 1 goto GIT_OK
:GIT_SKIP
echo [1/4] Git は入りませんでした。Claude Code が別の方法で進めるので、このまま続けます。
goto GIT_END
:GIT_OK
echo [1/4] Git OK
:GIT_END

rem ---- [2/4] Claude Code 本体 (公式インストーラー) ----
where claude >nul 2>&1
if not errorlevel 1 goto CLAUDE_OK
echo [2/4] Claude Code をインストールしています... 1-3分かかります
where winget >nul 2>&1
if errorlevel 1 goto CLAUDE_CMD
winget install -e --id Anthropic.ClaudeCode %WG%
echo claude winget exit=%errorlevel% >> "%LOG%"
call :REFRESH
where claude >nul 2>&1
if not errorlevel 1 goto CLAUDE_OK
:CLAUDE_CMD
echo        公式のインストーラーで試しています...
curl -fsSL https://claude.ai/install.cmd -o "%TEMP%\claude-install.cmd"
if errorlevel 1 goto CLAUDE_NG
cmd /c ""%TEMP%\claude-install.cmd""
echo claude install.cmd exit=%errorlevel% >> "%LOG%"
del "%TEMP%\claude-install.cmd" >nul 2>&1
call :REFRESH
where claude >nul 2>&1
if not errorlevel 1 goto CLAUDE_OK
:CLAUDE_NG
echo [2/4] Claude Code が入りませんでした。パソコンを再起動して、もう一度このファイルを実行してください。
echo        それでもだめなときは、同じフォルダの「うまくいかないとき.txt」の手順で進めるか、
echo        同じフォルダの「診断.bat」をダブルクリックして、出てきた内容を講師に送ってください。
pause
exit /b 1
:CLAUDE_OK
echo [2/4] Claude Code OK

rem ---- [3/4] Claude デスクトップアプリ (任意) ----
if exist "%LOCALAPPDATA%\AnthropicClaude\claude.exe" goto APP_OK
if exist "%LOCALAPPDATA%\Programs\Claude\Claude.exe" goto APP_OK
where winget >nul 2>&1
if errorlevel 1 goto APP_END
echo [3/4] Claude デスクトップアプリも入れると、毎日はアプリの画面から使えます。
choice /c YN /n /t 30 /d N /m "       アプリを入れますか? Y=入れる / N=入れない (30秒で N)"
if errorlevel 2 goto APP_END
echo        アプリをインストールしています...
winget install -e --id Anthropic.Claude %WG%
goto APP_END
:APP_OK
echo [3/4] Claude デスクトップアプリ OK
:APP_END

rem ---- [4/4] デスクトップに AI フォルダ (OneDrive のデスクトップにも対応) ----
set "DESK="
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "DESK=%%D"
if not defined DESK set "DESK=%USERPROFILE%\Desktop"
set "AIDIR=%DESK%\AI"
if not exist "%AIDIR%" mkdir "%AIDIR%"
echo [4/4] 作業フォルダ: %AIDIR%
echo %LINE_JA%| clip

echo.
echo =================================================
echo   準備ができました
echo =================================================
echo  Enter を押すと、AI フォルダで Claude Code が起動して、セットアップが始まります。
echo  はじめてのときはログイン画面が出るので、画面の案内に従ってください。
echo.
echo  アプリで進めたい場合: この画面を閉じて、Claude アプリの Code タブで
echo  デスクトップの AI フォルダを選び、Ctrl+V で貼り付けて Enter。
echo  貼り付ける1行はコピー済みです。
echo =================================================
pause
start "AI秘書セットアップ" /d "%AIDIR%" cmd /k claude "%FIRST%"
exit /b 0

:REFRESH
set "SYSPATH="
set "USRPATH="
for /f "tokens=2,*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYSPATH=%%B"
for /f "tokens=2,*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USRPATH=%%B"
call set "PATH=%SYSPATH%;%USRPATH%;%PATH%;%USERPROFILE%\.local\bin;%ProgramFiles%\Git\cmd;%LOCALAPPDATA%\Microsoft\WinGet\Links"
goto :eof
