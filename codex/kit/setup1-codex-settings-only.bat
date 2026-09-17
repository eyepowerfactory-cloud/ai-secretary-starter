@echo off
chcp 932 >nul
title AI秘書セットアップ (Codex・設定のみ)
setlocal

set "KITDIR=%~dp0"
set "LOG=%KITDIR%setup_log.txt"
set "SETUP_LINE=SETUP.md を読んで、Phase B（Google連携）は設定済みなので飛ばして、残りをセットアップして"
echo ===== codex settings-only setup start %date% %time% ===== > "%LOG%"

echo =================================================
echo   AI秘書セットアップ (Windows / Codex)  設定のみ版
echo =================================================
echo.
echo すでに Codex と Google 連携 (プラグイン / MCP) が済んでいるパソコン向けです。
echo インストールはせず、「AI秘書」の設定・スキル・作業フォルダ・
echo デスクトップの入口だけを配置します。所要時間はおよそ 1分です。
echo.
echo 既存の config.toml は退避したうえで、無いキーだけを足します
echo (今ある MCP 設定やプロファイルは消しません)。
echo.
pause

rem ---------------------------------------------
rem 事前確認: codex コマンドが見つかるか (PATH を読み直してから確認)
rem ---------------------------------------------
set "SYSPATH="
set "USRPATH="
for /f "tokens=2,*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYSPATH=%%B"
for /f "tokens=2,*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USRPATH=%%B"
call set "PATH=%SYSPATH%;%USRPATH%;%PATH%;%ProgramFiles%\nodejs;%APPDATA%\npm;%ProgramFiles%\Git\cmd;%LOCALAPPDATA%\Microsoft\WindowsApps"
if not exist "%KITDIR%assets\config.toml" (
    echo assets フォルダが見つかりません。zip を「すべて展開」してから実行してください。
    goto :FAIL
)
where codex >nul 2>&1
if errorlevel 1 (
    echo [確認] codex コマンドが見つかりませんでした。Codex デスクトップアプリだけで使う場合はこのままで大丈夫です。
    echo        黒い画面でも使いたい場合は、フル版の setup1-codex.bat を実行してください。
) else (
    for /f "usebackq delims=" %%V in (`codex --version 2^>nul`) do set "CODEXVER=%%V"
    echo [確認] Codex は導入済みです (%CODEXVER%)。
)

rem ---------------------------------------------
rem [1/4] Codex の設定 (許可を求めない) と AI秘書スキルの配置
rem ---------------------------------------------
set "CODEXDIR=%USERPROFILE%\.codex"
if not exist "%CODEXDIR%" mkdir "%CODEXDIR%"
if exist "%CODEXDIR%\config.toml" (
    copy /y "%CODEXDIR%\config.toml" "%CODEXDIR%\config.toml.backup" >nul
    echo [1/4] 既存の設定を config.toml.backup に退避しました。
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%KITDIR%assets\ensure_codex_config.ps1" -ConfigPath "%CODEXDIR%\config.toml" -TemplatePath "%KITDIR%assets\config.toml" >> "%LOG%" 2>&1
if errorlevel 1 (
    if exist "%CODEXDIR%\config.toml" (
        echo        設定の追記に失敗しました。既存の config.toml はそのまま残しています (setup_log.txt 参照)。
    ) else (
        copy /y "%KITDIR%assets\config.toml" "%CODEXDIR%\config.toml" >nul
    )
)
set "SKILLDIR=%USERPROFILE%\.agents\skills"
if not exist "%SKILLDIR%" mkdir "%SKILLDIR%"
xcopy /e /i /y "%KITDIR%assets\starter\skills" "%SKILLDIR%" >> "%LOG%" 2>&1
echo [1/4] Codex の設定(許可を求めない)と AI秘書スキル(4つ)を配置しました。

rem ---------------------------------------------
rem [2/4] デスクトップに作業フォルダ「AI」を作成 (秘書の机)
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
echo [2/4] デスクトップに「AI」フォルダを用意しました (既にある場合は中身を残しています)。

rem ---------------------------------------------
rem [3/4] Codex デスクトップアプリ (入っていなければ入れるか確認)
rem ---------------------------------------------
set "CODEXAPP="
powershell -NoProfile -Command "if (Get-AppxPackage | Where-Object { $_.Name -like '*Codex*' }) { exit 0 } else { exit 1 }" >nul 2>&1
if not errorlevel 1 set "CODEXAPP=1"
if defined CODEXAPP (
    echo [3/4] Codex デスクトップアプリは導入済みです。
    goto :SHORTCUTS
)
echo [3/4] Codex デスクトップアプリが見つかりません。
echo        アプリを入れると、ブラウザ連携 ^(Phase D^) と定期実行が使えます。
choice /c YN /n /t 30 /d N /m "       いまインストールしますか? (Y=入れる / N=入れない・30秒で N)"
if errorlevel 2 (
    echo        アプリは入れずに進みます。黒い画面の入口だけ作ります。
    goto :SHORTCUTS
)
echo        Codex デスクトップアプリをインストールしています (Microsoft Store 経由)...
winget install --id 9PLM9XGG6VKS -s msstore --accept-package-agreements --accept-source-agreements >> "%LOG%" 2>&1
if errorlevel 1 (
    echo        アプリの自動インストールができませんでした。あとで Codex に頼めば案内してくれます (無くても秘書は動きます)。
) else (
    set "CODEXAPP=1"
    echo        Codex デスクトップアプリのインストールが完了しました。
)

:SHORTCUTS
rem ---------------------------------------------
rem [4/4] デスクトップの入口 + 次の1行をクリップボードとデスクトップに置く
rem ---------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "%KITDIR%assets\make_shortcuts_codex.ps1" -AiDir "%AIDIR%" -Desktop "%DESK%" >> "%LOG%" 2>&1
if errorlevel 1 (
    echo [4/4] ショートカットの作成に失敗しました。あとで Codex に頼めば作れます。
) else (
    echo [4/4] デスクトップに「AI秘書 (Codex)」「AI秘書を起動 (Codex・黒い画面)」を作りました。
)
echo %SETUP_LINE%| clip
(
echo AI秘書セットアップ ^(Codex・設定のみ版^) 次にやること
echo.
if defined CODEXAPP (
echo 1. デスクトップの「AI秘書 ^(Codex^)」をダブルクリック ^(Codex アプリが開きます^)
echo 2. 作業フォルダ ^(プロジェクト^) に、デスクトップの「AI」フォルダを選ぶ
echo 3. チャット欄に、次の1行を貼り付けて Enter:
) else (
echo 1. デスクトップの「AI秘書を起動 ^(Codex・黒い画面^)」をダブルクリック
echo 2. 黒い画面に次の1行を貼り付けて Enter:
)
echo.
echo %SETUP_LINE%
echo.
echo ^(この1行はすでにコピー済みです。Ctrl+V で貼り付けできます^)
echo.
echo Google 連携 ^(Phase B^) は済んでいる前提で、Codex が残り ^(秘書ベース確認・
echo ブラウザ連携・音声入力・動作確認^) を画面で案内しながら進めてくれます。
echo 明日からは同じ入口から「おはよう」で始まります。
) > "%DESK%\AI秘書_次にやること_Codex.txt"

echo.
echo =================================================
echo   準備完了! 次にやること
echo =================================================
if defined CODEXAPP (
    echo   1. デスクトップの「AI秘書 ^(Codex^)」をダブルクリック ^(アプリが開く^)
    echo   2. 作業フォルダに、デスクトップの「AI」を選ぶ
    echo   3. チャット欄に次の1行を貼り付けて Enter ^(すでにコピー済み・Ctrl+V^)
) else (
    echo   1. デスクトップの「AI秘書を起動 ^(Codex・黒い画面^)」をダブルクリック
    echo   2. 黒い画面に次の1行を貼り付けて Enter ^(すでにコピー済み・Ctrl+V^)
)
echo.
echo   %SETUP_LINE%
echo.
echo   この内容はデスクトップの「AI秘書_次にやること_Codex.txt」にもあります。
echo   元の設定に戻したいときは %CODEXDIR%\config.toml.backup を戻してください。
echo =================================================
echo.
echo この画面は閉じて大丈夫です。
pause
exit /b 0

:FAIL
echo.
echo 問題が発生しました。setup_log.txt を配布元にお送りください。
pause
exit /b 1
