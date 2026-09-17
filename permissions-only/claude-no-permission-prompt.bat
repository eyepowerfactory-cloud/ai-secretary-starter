@echo off
chcp 932 >nul
title Claude Code 「許可を求めない」設定
setlocal

set "KITDIR=%~dp0"
set "LOG=%KITDIR%setup_log.txt"
set "CLAUDEDIR=%USERPROFILE%\.claude"
echo ===== permissions setup %date% %time% ===== > "%LOG%"

echo =================================================
echo   Claude Code 「許可を求めない」設定 (Windows)
echo =================================================
echo.
echo Claude Code が作業のたびに「許可しますか?」と聞いてくるのを止めます。
echo 危険な操作 (ファイルの一括削除・ディスク初期化・.env や鍵の読み取りなど) は
echo 引き続き自動でブロックされます。
echo.
echo 対象ファイル: %CLAUDEDIR%\settings.json
echo 今ある設定 (MCP・フック・許可リストなど) は消さず、必要な項目だけ足します。
echo 実行前の内容は settings.json.backup に退避します。所要時間は数秒です。
echo.
pause

if not exist "%KITDIR%assets\settings.json" (
    echo assets フォルダが見つかりません。zip を「すべて展開」してから実行してください。
    goto :FAIL
)
if not exist "%CLAUDEDIR%" mkdir "%CLAUDEDIR%"
if exist "%CLAUDEDIR%\settings.json" (
    copy /y "%CLAUDEDIR%\settings.json" "%CLAUDEDIR%\settings.json.backup" >nul
    echo [1/2] 既存の設定を settings.json.backup に退避しました。
) else (
    echo [1/2] settings.json はまだ無いので、新しく作ります。
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%KITDIR%assets\merge_settings.ps1" -ConfigPath "%CLAUDEDIR%\settings.json" -TemplatePath "%KITDIR%assets\settings.json" >> "%LOG%" 2>&1
if errorlevel 1 (
    echo        設定のマージに失敗しました。setup_log.txt を配布元にお送りください。
    echo        既存の settings.json はそのまま残しています。
    goto :FAIL
)
echo [2/2] 設定を書き込みました。
echo.
echo =================================================
echo   完了! 反映のしかた
echo =================================================
echo   ・黒い画面 (claude コマンド) で使っている場合
echo       → いったん終了して、もう一度 claude を起動すると反映されます。
echo   ・Claude デスクトップアプリで使っている場合
echo       → アプリを一度終了して開き直す。入力欄のそばのモード選択が
echo         「Bypass permissions」になっていれば OK です。
echo         出てこないときは 設定 → Claude Code → 「Allow bypass permissions mode」
echo         をオンにしてから、モード選択で「Bypass permissions」を選んでください。
echo.
echo   元に戻したいときは、同じフォルダの「元に戻す.bat」を実行してください。
echo =================================================
echo.
echo この画面は閉じて大丈夫です。
pause
exit /b 0

:FAIL
echo.
pause
exit /b 1
