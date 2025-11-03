@echo off
chcp 65001 > nul
echo ============================================
echo UIpowershell - ブラウザを開く（新規ウインドウ）
echo ============================================
echo.

set URL=http://localhost:8080/index-legacy.html

echo サーバーURL: %URL%
echo.

REM Chrome を検索（優先順位1）
set CHROME_PATH=
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" (
    set CHROME_PATH=%ProgramFiles%\Google\Chrome\Application\chrome.exe
) else if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" (
    set CHROME_PATH=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe
) else if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" (
    set CHROME_PATH=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe
)

if defined CHROME_PATH (
    echo [✓] Google Chrome を新規ウインドウで起動します...
    start "" "%CHROME_PATH%" --new-window "%URL%"
    goto :END
)

REM Microsoft Edge を検索（優先順位2）
set EDGE_PATH=
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
    set EDGE_PATH=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe
) else if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" (
    set EDGE_PATH=%ProgramFiles%\Microsoft\Edge\Application\msedge.exe
)

if defined EDGE_PATH (
    echo [✓] Microsoft Edge を新規ウインドウで起動します...
    start "" "%EDGE_PATH%" --new-window "%URL%"
    goto :END
)

REM デフォルトブラウザで開く（優先順位3）
echo [i] Chrome/Edge が見つかりません。デフォルトブラウザで開きます...
start "" "%URL%"

:END
echo.
echo ブラウザを起動しました！
echo.
echo このウインドウは3秒後に自動的に閉じます...
timeout /t 3
