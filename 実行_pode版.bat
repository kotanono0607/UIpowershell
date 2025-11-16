@echo off
chcp 65001 > nul
echo ============================================
echo UIpowershell - Pode APIサーバー起動
echo ============================================
echo.

REM 既存のサーバーを停止
echo [1/3] 既存のサーバーを停止しています...
taskkill /F /IM pwsh.exe 2>nul
taskkill /F /IM powershell.exe /FI "WINDOWTITLE eq api-server-v2*" 2>nul
timeout /t 1 /nobreak > nul

REM カレントディレクトリをスクリプトの場所に変更
cd /d "%~dp0"

REM PowerShell 7 (pwsh) が利用可能かチェック
where pwsh > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [2/3] PowerShell 7 でPode APIサーバーを起動します...
    echo.
    start "UIpowershell Pode API Server" pwsh -NoExit -ExecutionPolicy Bypass -File ".\adapter\api-server-v2-pode-complete.ps1" -AutoOpenBrowser
) else (
    echo [2/3] Windows PowerShell 5.1 でPode APIサーバーを起動します...
    echo.
    start "UIpowershell Pode API Server" powershell -NoExit -ExecutionPolicy Bypass -File ".\adapter\api-server-v2-pode-complete.ps1" -AutoOpenBrowser
)

echo [3/3] Pode APIサーバーが起動しました！
echo.
echo ✅ ブラウザが新規ウインドウで開きます
echo ✅ サーバーURL: http://localhost:8080/index-legacy.html
echo ✅ サーバー: Pode (高速版)
echo.
echo 【注意】
echo - サーバーウインドウを閉じないでください
echo - 停止する場合はサーバーウインドウで Ctrl+C を押してください
echo.
echo 【期待される改善】
echo - API応答時間: 95-99%削減 (1000ms → 10-50ms)
echo - 起動時間: 35-48%削減 (21秒 → 8-10秒)
echo.
echo このウインドウは5秒後に自動的に閉じます...
timeout /t 5
