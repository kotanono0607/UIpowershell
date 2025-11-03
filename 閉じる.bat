@echo off
chcp 65001 > nul
echo ============================================
echo UIpowershell - APIサーバー停止
echo ============================================
echo.

echo [1/2] Polarisサーバーを停止しています...
REM PowerShell 7とWindows PowerShellの両方を停止
taskkill /F /IM pwsh.exe 2>nul
taskkill /F /IM powershell.exe /FI "WINDOWTITLE eq UIpowershell API Server*" 2>nul

REM ポート8080を使用しているプロセスを停止
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8080" ^| findstr "LISTENING"') do (
    taskkill /F /PID %%a 2>nul
)

timeout /t 1 /nobreak > nul

echo [2/2] サーバーを停止しました
echo.
echo ✅ すべてのPowerShellプロセスを終了しました
echo ✅ ポート8080を解放しました
echo.
echo このウインドウは3秒後に自動的に閉じます...
timeout /t 3
