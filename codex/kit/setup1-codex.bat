@echo off
chcp 932 >nul
title AI秘書セットアップ (Codex)
setlocal

set "KITDIR=%~dp0"
set "LOG=%KITDIR%setup_log.txt"
set "SETUP_LINE=SETUP.md を読んで、書いてある通りにセットアップして"
echo ===== codex setup start %date% %time% ===== > "%LOG%"

echo =================================================
echo   AI秘書セットアップ (Windows / Codex)  step 1 / 2
echo =================================================
echo.
echo このパソコンに「AI秘書」の土台を準備します。
echo 所要時間はおよそ 5分から10分です。
echo 黒い画面はそのままにしてお待ちください。
echo 途中で「変更を許可しますか」と青い画面が出たら「はい」を押してください。
echo.
pause

rem ---------------------------------------------
rem [1/8] Git の導入 (任意だが、あると Codex の機能が全部使える)
rem ---------------------------------------------
where git >nul 2>&1
if not errorlevel 1 (
    echo [1/8] Git は導入済みです。
    goto :NODE
)
where winget >nul 2>&1
if errorlevel 1 (
    echo [1/8] 自動インストールの仕組み winget が見つかりません。
    echo        「はじめにお読みください.txt」の「wingetがない場合」をご覧ください。
    goto :NODE
)
echo [1/8] Git をインストールしています。数分かかります...
winget install -e --id Git.Git --silent --accept-package-agreements --accept-source-agreements >> "%LOG%" 2>&1
if errorlevel 1 (
    echo        Git の自動インストールに失敗しました。あとで入れられるので先へ進みます。
) else (
    echo        Git のインストールが完了しました。
)

:NODE
rem ---------------------------------------------
rem [2/8] Node.js の導入
rem ---------------------------------------------
where node >nul 2>&1
if not errorlevel 1 (
    echo [2/8] Node.js は導入済みです。
    goto :REFRESHPATH
)
where winget >nul 2>&1
if errorlevel 1 (
    echo [2/8] Node.js は後から txt の方法で導入できます。先へ進みます。
    goto :REFRESHPATH
)
echo [2/8] Node.js をインストールしています。数分かかります...
winget install -e --id OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements >> "%LOG%" 2>&1
if errorlevel 1 (
    echo        Node.js の自動インストールに失敗しました。txt の手動インストールをご覧ください。
) else (
    echo        Node.js のインストールが完了しました。
)

:REFRESHPATH
rem 今インストールしたものを、この画面のまま使えるように PATH を読み直す
set "SYSPATH="
set "USRPATH="
for /f "tokens=2,*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYSPATH=%%B"
for /f "tokens=2,*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USRPATH=%%B"
call set "PATH=%SYSPATH%;%USRPATH%;%PATH%;%ProgramFiles%\nodejs;%APPDATA%\npm;%ProgramFiles%\Git\cmd;%LOCALAPPDATA%\Microsoft\WindowsApps"

rem ---------------------------------------------
rem [3/8] Codex 本体 (コマンド版) の導入
rem ---------------------------------------------
where codex >nul 2>&1
if not errorlevel 1 (
    echo [3/8] Codex は導入済みです。最新版に更新します...
    call npm install -g @openai/codex >> "%LOG%" 2>&1
    goto :APP
)
where npm >nul 2>&1
if errorlevel 1 (
    echo [3/8] npm が見つからないため、winget で Codex を入れます...
    winget install -e --id OpenAI.Codex --silent --accept-package-agreements --accept-source-agreements >> "%LOG%" 2>&1
    goto :CHECKCODEX
)
echo [3/8] Codex をインストールしています。数分かかります...
call npm install -g @openai/codex >> "%LOG%" 2>&1
if errorlevel 1 (
    echo        npm での導入に失敗したため、winget を試します...
    winget install -e --id OpenAI.Codex --silent --accept-package-agreements --accept-source-agreements >> "%LOG%" 2>&1
)
:CHECKCODEX
call set "PATH=%PATH%;%APPDATA%\npm"
where codex >nul 2>&1
if errorlevel 1 (
    echo        Codex がまだ見つかりません。パソコンを再起動してからもう一度この bat を実行してください。
) else (
    echo        Codex のインストールが完了しました。
)

:APP
rem ---------------------------------------------
rem [4/8] Codex デスクトップアプリ (ブラウザ連携・定期実行はアプリ側の機能)
rem ---------------------------------------------
echo [4/8] Codex デスクトップアプリをインストールしています (Microsoft Store 経由)...
winget install --id 9PLM9XGG6VKS -s msstore --accept-package-agreements --accept-source-agreements >> "%LOG%" 2>&1
if errorlevel 1 (
    echo        アプリの自動インストールができませんでした。あとで Codex に頼めば案内してくれます (無くても秘書は動きます)。
) else (
    echo        Codex デスクトップアプリのインストールが完了しました。
)

rem ---------------------------------------------
rem [5/8] Codex の設定と AI秘書スキルの配置
rem ---------------------------------------------
set "CODEXDIR=%USERPROFILE%\.codex"
if not exist "%CODEXDIR%" mkdir "%CODEXDIR%"
if exist "%CODEXDIR%\config.toml" copy /y "%CODEXDIR%\config.toml" "%CODEXDIR%\config.toml.backup" >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%KITDIR%assets\ensure_codex_config.ps1" -ConfigPath "%CODEXDIR%\config.toml" -TemplatePath "%KITDIR%assets\config.toml" >> "%LOG%" 2>&1
if errorlevel 1 copy /y "%KITDIR%assets\config.toml" "%CODEXDIR%\config.toml" >nul
set "SKILLDIR=%USERPROFILE%\.agents\skills"
if not exist "%SKILLDIR%" mkdir "%SKILLDIR%"
xcopy /e /i /y "%KITDIR%assets\starter\skills" "%SKILLDIR%" >> "%LOG%" 2>&1
echo [5/8] Codex の設定(許可を求めない)と AI秘書スキル(4つ)を配置しました。

rem ---------------------------------------------
rem [6/8] デスクトップに作業フォルダ「AI」を作成 (秘書の机)
rem ---------------------------------------------
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "DESK=%%D"
if not defined DESK set "DESK=%USERPROFILE%\Desktop"
set "AIDIR=%DESK%\AI"
if not exist "%AIDIR%" mkdir "%AIDIR%"
if not exist "%AIDIR%\memory" mkdir "%AIDIR%\memory"
if not exist "%AIDIR%\AGENTS.md" copy "%KITDIR%assets\starter\AGENTS.md" "%AIDIR%\AGENTS.md" >nul
if not exist "%AIDIR%\tasks.md" copy "%KITDIR%assets\starter\tasks.md" "%AIDIR%\tasks.md" >nul
if not exist "%AIDIR%\SKILL_CATALOG.md" copy "%KITDIR%assets\starter\SKILL_CATALOG.md" "%AIDIR%\SKILL_CATALOG.md" >nul
if not exist "%AIDIR%\memory\README.md" copy "%KITDIR%assets\starter\memory\README.md" "%AIDIR%\memory\README.md" >nul
if not exist "%AIDIR%\memory\condition.md" copy "%KITDIR%assets\starter\memory\condition.md" "%AIDIR%\memory\condition.md" >nul
copy /y "%KITDIR%assets\SETUP.md" "%AIDIR%\SETUP.md" >nul
echo [6/8] デスクトップに「AI」フォルダを作りました。ここが秘書の机になります。

rem ---------------------------------------------
rem [7/8] デスクトップのショートカット
rem ---------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "%KITDIR%assets\make_shortcuts_codex.ps1" -AiDir "%AIDIR%" -Desktop "%DESK%" >> "%LOG%" 2>&1
if errorlevel 1 (
    echo [7/8] ショートカットの作成に失敗しました。あとで Codex に頼めば作れます。
) else (
    echo [7/8] デスクトップに「AI秘書 (Codex)」のショートカットを作りました。
)

rem ---------------------------------------------
rem [8/8] 仕上げ: 次の1行をクリップボードとデスクトップに置く
rem ---------------------------------------------
echo %SETUP_LINE%| clip
(
echo AI秘書セットアップ ^(Codex^) step 2 / 2
echo.
echo 1. デスクトップの「AI秘書 ^(Codex^)」をダブルクリック ^(Codex アプリが開きます^)
echo 2. 初回は ChatGPT にログインする ^(Plus 以上の有料プラン^)
echo 3. 作業フォルダ ^(プロジェクト^) に、デスクトップの「AI」フォルダを選ぶ
echo 4. チャット欄に、次の1行を貼り付けて Enter:
echo.
echo %SETUP_LINE%
echo.
echo ^(この1行はすでにコピー済みです。Ctrl+V で貼り付けできます^)
echo.
echo あとは Codex が画面で案内しながら、Google連携・音声入力まで進めてくれます。
echo アプリが開かないときは「AI秘書を起動 ^(Codex・黒い画面^)」でも同じことができます。
) > "%DESK%\AI秘書_次にやること_Codex.txt"

echo [8/8] パソコン側の準備が完了しました。
echo.
echo =================================================
echo   準備完了! 次にやること (step 2 / 2)
echo =================================================
echo   1. デスクトップの「AI秘書 (Codex)」をダブルクリック (アプリが開く)
echo   2. ChatGPT にログイン (Plus以上の有料プラン)
echo   3. 作業フォルダに、デスクトップの「AI」を選ぶ
echo   4. チャット欄に次の1行を貼り付けて Enter
echo      (すでにコピー済み。Ctrl+V で貼れます)
echo.
echo   %SETUP_LINE%
echo.
echo   この内容はデスクトップの「AI秘書_次にやること_Codex.txt」にもあります。
echo =================================================
echo.
echo この画面は閉じて大丈夫です。
pause
exit /b 0
