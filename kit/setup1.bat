@echo off
chcp 932 >nul
title AI秘書セットアップ (Claude Code)
setlocal

set "KITDIR=%~dp0"
set "LOG=%KITDIR%setup_log.txt"
set "SETUP_URL=https://raw.githubusercontent.com/eyepowerfactory-cloud/ai-secretary-starter/main/setup.md"
set "SETUP_LINE=%SETUP_URL% を読んで、書いてある通りにセットアップして"
echo ===== setup start %date% %time% ===== > "%LOG%"

echo =================================================
echo   AI秘書セットアップ (Windows)  step 1 / 2
echo =================================================
echo.
echo このパソコンに「AI秘書」の土台を準備します。
echo 所要時間はおよそ 5分から10分です。
echo 黒い画面はそのままにしてお待ちください。
echo 途中で「変更を許可しますか」と青い画面が出たら「はい」を押してください。
echo.
pause

rem ---------------------------------------------
rem [1/7] Git の導入 (Claude Code の動作に必要)
rem ---------------------------------------------
where git >nul 2>&1
if not errorlevel 1 (
    echo [1/7] Git は導入済みです。
    goto :NODE
)
where winget >nul 2>&1
if errorlevel 1 (
    echo [1/7] 自動インストールの仕組み winget が見つかりません。
    echo        「はじめにお読みください.txt」の「wingetがない場合」をご覧ください。
    goto :NODE
)
echo [1/7] Git をインストールしています。数分かかります...
winget install -e --id Git.Git --silent --accept-package-agreements --accept-source-agreements >> "%LOG%" 2>&1
if errorlevel 1 (
    echo        Git の自動インストールに失敗しました。txt の手動インストールをご覧ください。
) else (
    echo        Git のインストールが完了しました。
)

:NODE
rem ---------------------------------------------
rem [2/7] Node.js の導入
rem ---------------------------------------------
where node >nul 2>&1
if not errorlevel 1 (
    echo [2/7] Node.js は導入済みです。
    goto :REFRESHPATH
)
where winget >nul 2>&1
if errorlevel 1 (
    echo [2/7] Node.js は後から txt の方法で導入できます。先へ進みます。
    goto :REFRESHPATH
)
echo [2/7] Node.js をインストールしています。数分かかります...
winget install -e --id OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements >> "%LOG%" 2>&1
if errorlevel 1 (
    echo        Node.js の自動インストールに失敗しました。txt の手動インストールをご覧ください。
) else (
    echo        Node.js のインストールが完了しました。
)

:REFRESHPATH
rem ---------------------------------------------
rem 今インストールしたものを、この画面のまま使えるように PATH を読み直す
rem (再起動しないと git / node が見つからない問題の対策)
rem ---------------------------------------------
set "SYSPATH="
set "USRPATH="
for /f "tokens=2,*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYSPATH=%%B"
for /f "tokens=2,*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USRPATH=%%B"
call set "PATH=%SYSPATH%;%USRPATH%;%PATH%;%ProgramFiles%\nodejs;%APPDATA%\npm;%ProgramFiles%\Git\cmd;%USERPROFILE%\.local\bin"

rem ---------------------------------------------
rem [3/7] Claude Code 本体の導入
rem ---------------------------------------------
where claude >nul 2>&1
if not errorlevel 1 (
    echo [3/7] Claude Code は導入済みです。最新版に更新します...
    call npm install -g @anthropic-ai/claude-code >> "%LOG%" 2>&1
    goto :SETTINGS
)
where npm >nul 2>&1
if errorlevel 1 (
    echo [3/7] npm が見つからないため、公式インストーラーで Claude Code を入れます...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://claude.ai/install.ps1 | iex" >> "%LOG%" 2>&1
    goto :CHECKCLAUDE
)
echo [3/7] Claude Code をインストールしています。数分かかります...
call npm install -g @anthropic-ai/claude-code >> "%LOG%" 2>&1
if errorlevel 1 (
    echo        npm での導入に失敗したため、公式インストーラーを試します...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://claude.ai/install.ps1 | iex" >> "%LOG%" 2>&1
)
:CHECKCLAUDE
call set "PATH=%PATH%;%APPDATA%\npm;%USERPROFILE%\.local\bin"
where claude >nul 2>&1
if errorlevel 1 (
    echo        Claude Code がまだ見つかりません。パソコンを再起動してからもう一度この setup1.bat を実行してください。
    echo        それでも直らない場合は setup_log.txt を配布元にお送りください。
) else (
    echo        Claude Code のインストールが完了しました。
)

:SETTINGS
rem ---------------------------------------------
rem [4/7] おすすめ設定と AI秘書スターターの配置
rem ---------------------------------------------
set "CLAUDEDIR=%USERPROFILE%\.claude"
if not exist "%CLAUDEDIR%" mkdir "%CLAUDEDIR%"
if exist "%CLAUDEDIR%\settings.json" (
    copy /y "%CLAUDEDIR%\settings.json" "%CLAUDEDIR%\settings.json.backup" >nul
    echo [4/7] 既存の設定を settings.json.backup に退避しました。
)
copy /y "%KITDIR%assets\settings.json" "%CLAUDEDIR%\settings.json" >nul
if errorlevel 1 (
    echo [4/7] 設定ファイルの配置に失敗しました。zip を全部展開してから実行してください。
    goto :FAIL
)
if not exist "%CLAUDEDIR%\skills" mkdir "%CLAUDEDIR%\skills"
xcopy /e /i /y "%KITDIR%assets\starter\skills" "%CLAUDEDIR%\skills" >> "%LOG%" 2>&1
echo [4/7] おすすめ設定と AI秘書スキル(4つ)を配置しました。危険な操作は自動でブロックされます。

rem ---------------------------------------------
rem [5/7] デスクトップに作業フォルダ「AI」を作成 (秘書の机)
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
echo [5/7] デスクトップに「AI」フォルダを作りました。ここが秘書の机になります。

rem ---------------------------------------------
rem [6/7] アプリのインストール許可設定 + デスクトップのショートカット
rem ---------------------------------------------
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowAllTrustedApps /t REG_DWORD /d 1 /f >nul 2>&1
if errorlevel 1 (
    echo [6/7] アプリのインストール許可設定を行います。青い確認画面が出たら「はい」を押してください。
    powershell -NoProfile -Command "Start-Process -FilePath 'reg.exe' -ArgumentList 'add','HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock','/v','AllowAllTrustedApps','/t','REG_DWORD','/d','1','/f' -Verb RunAs -Wait" >> "%LOG%" 2>&1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%KITDIR%assets\make_shortcuts.ps1" -AiDir "%AIDIR%" -Desktop "%DESK%" >> "%LOG%" 2>&1
if errorlevel 1 (
    echo [6/7] ショートカットの作成に失敗しました。あとで Claude に頼めば作れます。
) else (
    echo [6/7] デスクトップに「AI秘書を起動」のショートカットを作りました。
)

rem ---------------------------------------------
rem [7/7] 仕上げ: 次の1行をクリップボードとデスクトップに置く
rem ---------------------------------------------
echo %SETUP_LINE%| clip
(
echo AI秘書セットアップ step 2 / 2
echo.
echo 1. デスクトップの「AI秘書を起動」をダブルクリック
echo 2. 初回はブラウザが開くので Claude にログインする ^(Pro 以上の有料プラン^)
echo 3. 「このフォルダを信頼しますか」と聞かれたら Yes
echo 4. 黒い画面に、次の1行を貼り付けて Enter:
echo.
echo %SETUP_LINE%
echo.
echo ^(この1行はすでにコピー済みです。右クリックまたは Ctrl+V で貼り付けできます^)
echo.
echo あとは Claude が画面で案内しながら、Google連携・音声入力まで進めてくれます。
) > "%DESK%\AI秘書_次にやること.txt"

echo [7/7] パソコン側の準備が完了しました。
echo.
echo =================================================
echo   準備完了! 次にやること (step 2 / 2)
echo =================================================
echo   1. デスクトップの「AI秘書を起動」をダブルクリック
echo   2. ブラウザで Claude にログイン (Pro以上の有料プラン)
echo   3. 黒い画面に次の1行を貼り付けて Enter
echo      (すでにコピー済み。右クリック or Ctrl+V で貼れます)
echo.
echo   %SETUP_LINE%
echo.
echo   この内容はデスクトップの「AI秘書_次にやること.txt」にもあります。
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
