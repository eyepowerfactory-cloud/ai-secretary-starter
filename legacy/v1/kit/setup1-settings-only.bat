@echo off
chcp 932 >nul
title AI秘書セットアップ (Claude Code・設定のみ)
setlocal

set "KITDIR=%~dp0"
set "LOG=%KITDIR%setup_log.txt"
set "SETUP_URL=https://raw.githubusercontent.com/eyepowerfactory-cloud/ai-secretary-starter/main/setup.md"
set "SETUP_LINE=%SETUP_URL% を読んで、Phase B（Google連携）は設定済みなので飛ばして、残りをセットアップして"
echo ===== settings-only setup start %date% %time% ===== > "%LOG%"

echo =================================================
echo   AI秘書セットアップ (Windows)  設定のみ版
echo =================================================
echo.
echo すでに Claude Code と Google 連携 (MCP) が済んでいるパソコン向けです。
echo インストールはせず、「AI秘書」の設定・スキル・作業フォルダ・
echo デスクトップの入口だけを配置します。所要時間はおよそ 1分です。
echo.
echo 既存の settings.json は退避したうえで、必要な設定だけを足します
echo (今ある許可設定や MCP 設定は消しません)。
echo.
pause

rem ---------------------------------------------
rem 事前確認: claude コマンドが見つかるか (PATH を読み直してから確認)
rem ---------------------------------------------
set "SYSPATH="
set "USRPATH="
for /f "tokens=2,*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYSPATH=%%B"
for /f "tokens=2,*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USRPATH=%%B"
call set "PATH=%SYSPATH%;%USRPATH%;%PATH%;%ProgramFiles%\nodejs;%APPDATA%\npm;%ProgramFiles%\Git\cmd;%USERPROFILE%\.local\bin"
if not exist "%KITDIR%assets\settings.json" (
    echo assets フォルダが見つかりません。zip を「すべて展開」してから実行してください。
    goto :FAIL
)
where claude >nul 2>&1
if errorlevel 1 (
    echo [確認] claude コマンドが見つかりませんでした。Claude デスクトップアプリだけで使う場合はこのままで大丈夫です。
    echo        黒い画面でも使いたい場合は、フル版の setup1.bat を実行してください。
) else (
    for /f "usebackq delims=" %%V in (`claude --version 2^>nul`) do set "CLAUDEVER=%%V"
    echo [確認] Claude Code は導入済みです ^(%CLAUDEVER%^)。
)

rem ---------------------------------------------
rem [1/5] 設定 (許可を求めない) のマージと AI秘書スキルの配置
rem ---------------------------------------------
set "CLAUDEDIR=%USERPROFILE%\.claude"
if not exist "%CLAUDEDIR%" mkdir "%CLAUDEDIR%"
if exist "%CLAUDEDIR%\settings.json" (
    copy /y "%CLAUDEDIR%\settings.json" "%CLAUDEDIR%\settings.json.backup" >nul
    echo [1/5] 既存の設定を settings.json.backup に退避しました。
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%KITDIR%assets\merge_settings.ps1" -ConfigPath "%CLAUDEDIR%\settings.json" -TemplatePath "%KITDIR%assets\settings.json" >> "%LOG%" 2>&1
if errorlevel 1 (
    echo        設定のマージに失敗したため、設定ファイルをそのまま置きます ^(退避済み^)。
    copy /y "%KITDIR%assets\settings.json" "%CLAUDEDIR%\settings.json" >nul
    if errorlevel 1 (
        echo [1/5] 設定ファイルの配置に失敗しました。zip を全部展開してから実行してください。
        goto :FAIL
    )
)
if not exist "%CLAUDEDIR%\skills" mkdir "%CLAUDEDIR%\skills"
xcopy /e /i /y "%KITDIR%assets\starter\skills" "%CLAUDEDIR%\skills" >> "%LOG%" 2>&1
echo [1/5] 設定(許可を求めない)と AI秘書スキル(4つ)を配置しました。危険な操作だけは自動でブロックされます。

rem ---------------------------------------------
rem [2/5] デスクトップに作業フォルダ「AI」を作成 (秘書の机)
rem ---------------------------------------------
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "DESK=%%D"
if not defined DESK set "DESK=%USERPROFILE%\Desktop"
set "AIDIR=%DESK%\AI"
if not exist "%AIDIR%" mkdir "%AIDIR%"
if not exist "%AIDIR%\memory" mkdir "%AIDIR%\memory"
if not exist "%AIDIR%\CLAUDE.md" copy "%KITDIR%assets\starter\CLAUDE.md" "%AIDIR%\CLAUDE.md" >nul
if not exist "%AIDIR%\tasks.md" copy "%KITDIR%assets\starter\tasks.md" "%AIDIR%\tasks.md" >nul
if not exist "%AIDIR%\SKILL_CATALOG.md" copy "%KITDIR%assets\starter\SKILL_CATALOG.md" "%AIDIR%\SKILL_CATALOG.md" >nul
if not exist "%AIDIR%\memory\README.md" copy "%KITDIR%assets\starter\memory\README.md" "%AIDIR%\memory\README.md" >nul
if not exist "%AIDIR%\memory\condition.md" copy "%KITDIR%assets\starter\memory\condition.md" "%AIDIR%\memory\condition.md" >nul
echo [2/5] デスクトップに「AI」フォルダを用意しました (既にある場合は中身を残しています)。

rem ---------------------------------------------
rem [3/5] Claude デスクトップアプリ (入っていなければ入れるか確認)
rem ---------------------------------------------
set "CLAUDEAPP="
if exist "%LOCALAPPDATA%\AnthropicClaude\claude.exe" set "CLAUDEAPP=1"
if exist "%LOCALAPPDATA%\Programs\Claude\Claude.exe" set "CLAUDEAPP=1"
if not defined CLAUDEAPP (
    winget list -e --id Anthropic.Claude --accept-source-agreements 2>nul | findstr /i "Anthropic.Claude" >nul 2>&1
    if not errorlevel 1 set "CLAUDEAPP=1"
)
if defined CLAUDEAPP (
    echo [3/5] Claude デスクトップアプリは導入済みです。
    goto :SHORTCUTS
)
echo [3/5] Claude デスクトップアプリが見つかりません。
echo        アプリを入れると、デスクトップの入口からワンクリックで秘書を開けます。
choice /c YN /n /t 30 /d N /m "       いまインストールしますか? (Y=入れる / N=入れない・30秒で N)"
if errorlevel 2 (
    echo        アプリは入れずに進みます。黒い画面の入口だけ作ります。
    goto :SHORTCUTS
)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowAllTrustedApps /t REG_DWORD /d 1 /f >nul 2>&1
if errorlevel 1 (
    echo        アプリのインストール許可設定を行います。青い確認画面が出たら「はい」を押してください。
    powershell -NoProfile -Command "Start-Process -FilePath 'reg.exe' -ArgumentList 'add','HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock','/v','AllowAllTrustedApps','/t','REG_DWORD','/d','1','/f' -Verb RunAs -Wait" >> "%LOG%" 2>&1
)
echo        Claude デスクトップアプリをインストールしています (Claude Code 内蔵)...
winget install -e --id Anthropic.Claude --silent --accept-package-agreements --accept-source-agreements >> "%LOG%" 2>&1
if errorlevel 1 (
    echo        自動インストールができなかったので、公式インストーラーをダウンロードして開きます。
    echo        画面の案内に従ってインストールしてください ^(終わったらこの黒い画面に戻ります^)。
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://claude.ai/api/desktop/win32/x64/setup/latest/redirect' -OutFile \"$env:TEMP\ClaudeSetup.exe\"; Start-Process \"$env:TEMP\ClaudeSetup.exe\" -Wait" >> "%LOG%" 2>&1
)
set "CLAUDEAPP=1"
echo        Claude デスクトップアプリの導入手順が完了しました。

:SHORTCUTS
rem ---------------------------------------------
rem [4/5] デスクトップの入口 (アプリを AI フォルダで開くリンク + 予備の黒い画面)
rem ---------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "%KITDIR%assets\make_shortcuts.ps1" -AiDir "%AIDIR%" -Desktop "%DESK%" -SetupLine "%SETUP_LINE%" >> "%LOG%" 2>&1
if errorlevel 1 (
    echo [4/5] ショートカットの作成に失敗しました。あとで Claude に頼めば作れます。
) else (
    echo [4/5] デスクトップに「AI秘書 ^(Claude^)」「AI秘書セットアップ開始」「AI秘書を起動 ^(黒い画面^)」を作りました。
)

rem ---------------------------------------------
rem [5/5] 仕上げ: 次の1行をクリップボードとデスクトップに置く
rem ---------------------------------------------
echo %SETUP_LINE%| clip
(
echo AI秘書セットアップ ^(設定のみ版^) 次にやること
echo.
if defined CLAUDEAPP (
echo 1. デスクトップの「AI秘書セットアップ開始」をダブルクリック ^(Claude アプリが開きます^)
echo 2. 「このフォルダを作業場所にしますか」と聞かれたら「はい」
echo 3. 入力欄に次の1行が入っているので、そのまま Enter ^(入っていなければ貼り付け^):
) else (
echo 1. デスクトップの「AI秘書を起動 ^(黒い画面^)」をダブルクリック
echo 2. 黒い画面に次の1行を貼り付けて Enter:
)
echo.
echo %SETUP_LINE%
echo.
echo ^(この1行はすでにコピー済みです。Ctrl+V で貼り付けできます^)
echo.
echo Google 連携 ^(Phase B^) は済んでいる前提で、Claude が残り ^(秘書ベース確認・
echo ブラウザ連携・音声入力・動作確認^) を画面で案内しながら進めてくれます。
echo 明日からは「AI秘書 ^(Claude^)」をダブルクリック →「おはよう」で始まります。
) > "%DESK%\AI秘書_次にやること.txt"

echo [5/5] 設定が完了しました。
echo.
echo =================================================
echo   準備完了! 次にやること
echo =================================================
if defined CLAUDEAPP (
    echo   1. デスクトップの「AI秘書セットアップ開始」をダブルクリック ^(アプリが開く^)
    echo   2. フォルダの確認に「はい」
    echo   3. 入力欄に次の1行が入っているので Enter ^(無ければ Ctrl+V で貼る^)
) else (
    echo   1. デスクトップの「AI秘書を起動 ^(黒い画面^)」をダブルクリック
    echo   2. 黒い画面に次の1行を貼り付けて Enter ^(Ctrl+V でも貼れます^)
)
echo.
echo   %SETUP_LINE%
echo.
echo   この内容はデスクトップの「AI秘書_次にやること.txt」にもあります。
echo   元の設定に戻したいときは %CLAUDEDIR%\settings.json.backup を戻してください。
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
