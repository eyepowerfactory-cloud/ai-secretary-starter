@echo off
chcp 932 >nul
setlocal
title AI秘書 診断
rem ------------------------------------------------------------
rem  AI秘書 診断 (Windows / Claude Code・Codex 共通)
rem  やること: いま何が入っていて何が入っていないかを調べ、結果を
rem           デスクトップの「AI秘書_診断結果.txt」に保存＋クリップボードにコピーする。
rem           AI (Claude Code / Codex) が入っていれば、その場で AI を起動して
rem           .kit/troubleshoot.md の手順で切り分け・修復までやらせる。
rem  注意: if/for の ( ) ブロックは使わない。変更したら tools\lint_bat.py を通すこと。
rem        読み取りだけ。設定は何も変えない。
rem ------------------------------------------------------------
set "REPO=https://github.com/eyepowerfactory-cloud/ai-secretary-starter"
set "OUT=%TEMP%\ai-secretary-diagnose.txt"
set "LOG=%TEMP%\ai-secretary-install.log"

echo =================================================
echo   AI秘書 診断
echo =================================================
echo.
echo  いまパソコンに何が入っているかを調べます。30秒ほどです。
echo  設定は何も変えません。調べるだけです。
echo.
pause

call :REFRESH

echo ===== AI秘書 診断 %date% %time% ===== > "%OUT%"
echo --- Windows --- >> "%OUT%"
ver >> "%OUT%" 2>&1
echo --- 場所 --- >> "%OUT%"
set "DESK="
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "DESK=%%D"
if not defined DESK set "DESK=%USERPROFILE%\Desktop"
echo Desktop=%DESK% >> "%OUT%"
echo AI folder=%DESK%\AI >> "%OUT%"
if exist "%DESK%\AI" echo AI folder: あり >> "%OUT%"
if not exist "%DESK%\AI" echo AI folder: なし >> "%OUT%"
if exist "%DESK%\AI\.kit" echo .kit: あり >> "%OUT%"
if not exist "%DESK%\AI\.kit" echo .kit: なし >> "%OUT%"

echo --- 入っている道具 --- >> "%OUT%"
call :CHECK winget
call :CHECK git
call :CHECK node
call :CHECK npm
call :CHECK claude
call :CHECK codex

echo --- Claude / Codex アプリ --- >> "%OUT%"
if exist "%LOCALAPPDATA%\AnthropicClaude\claude.exe" echo Claude app: あり >> "%OUT%"
if exist "%LOCALAPPDATA%\Programs\Claude\Claude.exe" echo Claude app: あり(Programs) >> "%OUT%"
powershell -NoProfile -Command "if (Get-AppxPackage ^| Where-Object { $_.Name -like '*Codex*' }) { 'Codex app: あり' } else { 'Codex app: なし' }" >> "%OUT%" 2>&1

echo --- ウイルス対策が止めたもの (直近5件) --- >> "%OUT%"
powershell -NoProfile -Command "try { Get-MpThreatDetection -ErrorAction Stop ^| Sort-Object InitialDetectionTime -Descending ^| Select-Object -First 5 InitialDetectionTime,Resources ^| Format-List } catch { '取得できませんでした（ウイルス対策が別製品か、権限がありません）' }" >> "%OUT%" 2>&1

echo --- インストールのログ (最後の20行) --- >> "%OUT%"
if not exist "%LOG%" echo ログはありません (インストールがほとんど進んでいない) >> "%OUT%"
if exist "%LOG%" powershell -NoProfile -Command "Get-Content -Tail 20 -LiteralPath '%LOG%'" >> "%OUT%" 2>&1

copy /y "%OUT%" "%DESK%\AI秘書_診断結果.txt" >nul 2>&1
clip < "%OUT%"

cls
type "%OUT%"
echo.
echo =================================================
echo  この内容を「%DESK%\AI秘書_診断結果.txt」に保存しました。
echo  コピー済みなので、LINE に Ctrl+V で貼って講師に送れます。
echo =================================================
echo.

rem ---- AI が入っていれば、その場で切り分けまでやらせる ----
where claude >nul 2>&1
if not errorlevel 1 goto AI_CLAUDE
where codex >nul 2>&1
if not errorlevel 1 goto AI_CODEX
echo  このパソコンにはまだ AI 本体が入っていません。
echo  「うまくいかないとき.txt」の C の手順（1行ずつ貼る）を試すか、
echo  上の内容を講師に送ってください。
echo.
pause
exit /b 0

:AI_CLAUDE
set "FIRST=Read the diagnosis at %OUT%. Then clone %REPO% into a folder named .kit here (git pull if it exists; if git is missing, download %REPO%/archive/refs/heads/main.zip and extract it as .kit), read .kit/troubleshoot.md and follow it to diagnose and repair this PC step by step. Talk to me in Japanese."
echo  Claude Code が入っています。このまま AI に原因を調べさせて直せます。
choice /c YN /n /t 60 /d Y /m "  AI に見てもらいますか? Y=見てもらう / N=やめる (60秒で Y)"
if errorlevel 2 goto BYE
if not exist "%DESK%\AI" mkdir "%DESK%\AI"
start "AI秘書 診断" /d "%DESK%\AI" cmd /k claude "%FIRST%"
exit /b 0

:AI_CODEX
set "FIRST=Read the diagnosis at %OUT%. Then clone %REPO% into a folder named .kit here (git pull if it exists; if git is missing, download %REPO%/archive/refs/heads/main.zip and extract it as .kit), read .kit/troubleshoot.md and follow it to diagnose and repair this PC step by step. Talk to me in Japanese."
echo  Codex が入っています。このまま AI に原因を調べさせて直せます。
choice /c YN /n /t 60 /d Y /m "  AI に見てもらいますか? Y=見てもらう / N=やめる (60秒で Y)"
if errorlevel 2 goto BYE
if not exist "%DESK%\AI" mkdir "%DESK%\AI"
start "AI秘書 診断" /d "%DESK%\AI" cmd /k codex "%FIRST%"
exit /b 0

:BYE
echo  わかりました。上の内容を講師に送ってください。
pause
exit /b 0

:CHECK
set "P="
for /f "usebackq delims=" %%A in (`where %1 2^>nul`) do if not defined P set "P=%%A"
if not defined P echo %1: なし >> "%OUT%"
if defined P echo %1: %P% >> "%OUT%"
if defined P call %1 --version >> "%OUT%" 2>&1
goto :eof

:REFRESH
set "SYSPATH="
set "USRPATH="
for /f "tokens=2,*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYSPATH=%%B"
for /f "tokens=2,*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USRPATH=%%B"
call set "PATH=%SYSPATH%;%USRPATH%;%PATH%;%USERPROFILE%\.local\bin;%LOCALAPPDATA%\Programs\OpenAI\Codex\bin;%ProgramFiles%\Git\cmd;%LOCALAPPDATA%\Microsoft\WinGet\Links"
goto :eof
