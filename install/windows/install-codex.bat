@echo off
chcp 932 >nul
setlocal
title AI秘書 インストール - Codex
rem ------------------------------------------------------------
rem  AI秘書 インストール (Windows / Codex)
rem  やること: Git と Codex を入れて、デスクトップに AI フォルダを作り、
rem           Codex を起動してセットアップの1行を渡す。
rem  設定・スキル・ショートカットは、起動した Codex が GitHub から取ってきて行う。
rem  注意: if/for の ( ) ブロックは使わない (括弧1文字で即終了する事故の再発防止)。
rem        変更したら tools\lint_bat.py を通すこと。
rem ------------------------------------------------------------
set "LOG=%TEMP%\ai-secretary-install.log"
set "REPO=https://github.com/eyepowerfactory-cloud/ai-secretary-starter"
set "FIRST=Clone %REPO% into a folder named .kit here - run git pull if .kit already exists; if git is missing, download %REPO%/archive/refs/heads/main.zip and extract it as .kit. Then read .kit/setup-codex.md and follow it step by step. Talk to me in Japanese."
set "LINE_JA=%REPO% を今いるフォルダの .kit に git clone して (すでにあれば git pull)、.kit/setup-codex.md の通りにこのパソコンをセットアップして"
echo ===== install-codex %date% %time% ===== > "%LOG%"

echo =================================================
echo   AI秘書 インストール  Windows / Codex
echo =================================================
echo.
echo このパソコンに Git と Codex を入れます。所要時間は 5分ほどです。
echo 設定は、このあと起動する Codex が自分で行います。
echo 途中で青い確認画面が出たら「はい」を押してください。
echo.
pause

call :REFRESH

rem ---- [1/4] Git ----
where git >nul 2>&1
if not errorlevel 1 goto GIT_OK
where winget >nul 2>&1
if errorlevel 1 goto GIT_SKIP
echo [1/4] Git をインストールしています...
winget install -e --id Git.Git --silent --accept-package-agreements --accept-source-agreements >> "%LOG%" 2>&1
call :REFRESH
where git >nul 2>&1
if not errorlevel 1 goto GIT_OK
:GIT_SKIP
echo [1/4] Git は入りませんでした。Codex が別の方法で進めるので、このまま続けます。
goto GIT_END
:GIT_OK
echo [1/4] Git OK
:GIT_END

rem ---- [2/4] Codex 本体 (公式インストーラー。Node.js は不要) ----
where codex >nul 2>&1
if not errorlevel 1 goto CODEX_OK
echo [2/4] Codex をインストールしています...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:CODEX_NON_INTERACTIVE='1'; irm https://chatgpt.com/codex/install.ps1 | iex" >> "%LOG%" 2>&1
call :REFRESH
where codex >nul 2>&1
if not errorlevel 1 goto CODEX_OK
where winget >nul 2>&1
if errorlevel 1 goto CODEX_NG
echo        別の方法で試しています...
winget install -e --id OpenAI.Codex --silent --accept-package-agreements --accept-source-agreements >> "%LOG%" 2>&1
call :REFRESH
where codex >nul 2>&1
if not errorlevel 1 goto CODEX_OK
:CODEX_NG
echo [2/4] Codex が入りませんでした。パソコンを再起動して、もう一度このファイルを実行してください。
echo        それでもだめなときは、ログ %LOG% を講師に送ってください。
pause
exit /b 1
:CODEX_OK
echo [2/4] Codex OK

rem ---- [3/4] Codex デスクトップアプリ (任意・Microsoft Store) ----
powershell -NoProfile -Command "if (Get-AppxPackage | Where-Object { $_.Name -like '*Codex*' }) { exit 0 } else { exit 1 }" >nul 2>&1
if not errorlevel 1 goto APP_OK
where winget >nul 2>&1
if errorlevel 1 goto APP_END
echo [3/4] Codex デスクトップアプリも入れると、ブラウザ連携などアプリだけの機能が使えます。
choice /c YN /n /t 30 /d N /m "       アプリを入れますか? Y=入れる / N=入れない (30秒で N)"
if errorlevel 2 goto APP_END
echo        アプリをインストールしています...
winget install --id 9PLM9XGG6VKS -s msstore --accept-package-agreements --accept-source-agreements >> "%LOG%" 2>&1
goto APP_END
:APP_OK
echo [3/4] Codex デスクトップアプリ OK
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
echo  Enter を押すと、AI フォルダで Codex が起動して、セットアップが始まります。
echo  はじめてのときは ChatGPT のログイン画面が出るので、案内に従ってください。
echo.
echo  アプリで進めたい場合: この画面を閉じて、Codex アプリでデスクトップの AI フォルダを
echo  開き、Ctrl+V で貼り付けて Enter。貼り付ける1行はコピー済みです。
echo =================================================
pause
start "AI秘書セットアップ" /d "%AIDIR%" cmd /k codex "%FIRST%"
exit /b 0

:REFRESH
set "SYSPATH="
set "USRPATH="
for /f "tokens=2,*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYSPATH=%%B"
for /f "tokens=2,*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USRPATH=%%B"
call set "PATH=%SYSPATH%;%USRPATH%;%PATH%;%LOCALAPPDATA%\Programs\OpenAI\Codex\bin;%ProgramFiles%\Git\cmd;%LOCALAPPDATA%\Microsoft\WinGet\Links"
goto :eof
