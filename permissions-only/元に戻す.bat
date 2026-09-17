@echo off
chcp 932 >nul
title Claude Code 設定を元に戻す
setlocal
set "CLAUDEDIR=%USERPROFILE%\.claude"
echo =================================================
echo   Claude Code の設定を、変更前の状態に戻します
echo =================================================
echo.
if not exist "%CLAUDEDIR%\settings.json.backup" (
    echo 退避ファイル settings.json.backup が見つかりません。
    echo 変更前に settings.json が無かった場合は、次のファイルを削除すれば元どおりです:
    echo   %CLAUDEDIR%\settings.json
    echo.
    pause
    exit /b 1
)
echo %CLAUDEDIR%\settings.json.backup を settings.json に戻します。
pause
copy /y "%CLAUDEDIR%\settings.json.backup" "%CLAUDEDIR%\settings.json" >nul
if errorlevel 1 (
    echo 戻せませんでした。Claude Code を終了してからもう一度お試しください。
    pause
    exit /b 1
)
echo 戻しました。Claude Code を起動し直すと反映されます。
echo.
pause
exit /b 0
