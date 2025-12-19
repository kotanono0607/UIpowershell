@echo off
chcp 65001 > nul
echo ============================================
echo UIpowershell - APIサーバー起動
echo ============================================
echo.

REM 既存のPolarisサーバーを停止
echo [1/3] 既存のサーバーを停止しています...
taskkill /F /IM pwsh.exe 2>nul
taskkill /F /IM powershell.exe /FI "WINDOWTITLE eq api-server-v2.ps1*" 2>nul
timeout /t 1 /nobreak > nul

REM カレントディレクトリをスクリプトの場所に変更
cd /d "%~dp0"

REM PowerShell 7 (pwsh) が利用可能かチェック
where pwsh > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [2/3] PowerShell 7 でAPIサーバーを起動します...
    echo.
    start "UIpowershell API Server" pwsh -NoExit -ExecutionPolicy Bypass -File ".\adapter\api-server-v2.ps1" -AutoOpenBrowser
) else (
    echo [2/3] Windows PowerShell 5.1 でAPIサーバーを起動します...
    echo.
    start "UIpowershell API Server" powershell -NoExit -ExecutionPolicy Bypass -File ".\adapter\api-server-v2.ps1" -AutoOpenBrowser
)

echo [3/3] APIサーバーが起動しました！
echo.
echo ✅ ブラウザが新規ウインドウで開きます
echo ✅ サーバーURL: http://localhost:8080/index-legacy.html
echo.
echo 【注意】
echo - サーバーウインドウを閉じないでください
echo - 停止する場合は「閉じる.bat」を実行してください
echo.
echo このウインドウは5秒後に自動的に閉じます...
timeout /t 5
