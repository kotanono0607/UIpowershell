@echo off
chcp 65001 > nul
echo ============================================
echo UIpowershell - ブラウザを開く（Edge専用）
echo ============================================
echo.

set URL=http://localhost:8080/index-legacy.html

echo サーバーURL: %URL%
echo.
echo ℹ️  UIpowershell専用にMicrosoft Edgeを使用します
echo    （Chromeとの分離により、他のブラウザに影響しません）
echo.

REM Microsoft Edge を検索（UIpowershell専用）
set EDGE_PATH=
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
    set EDGE_PATH=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe
) else if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" (
    set EDGE_PATH=%ProgramFiles%\Microsoft\Edge\Application\msedge.exe
)

if defined EDGE_PATH (
    echo [✓] Microsoft Edge をアプリモードで起動します...
    start "" "%EDGE_PATH%" --app=%URL%
    goto :END
)

REM Edgeが見つからない場合
echo [!] Microsoft Edge が見つかりませんでした
echo.
echo 【対処方法】
echo 1. Microsoft Edgeをインストールしてください
echo 2. または、手動でブラウザを開いてください: %URL%
echo.
pause

:END
echo.
echo ブラウザを起動しました！
echo.
echo このウインドウは3秒後に自動的に閉じます...
timeout /t 3
