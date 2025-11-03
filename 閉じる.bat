@echo off
chcp 65001 > nul
echo ============================================
echo UIpowershell - 完全停止（サーバー+ブラウザ）
echo ============================================
echo.

echo [1/4] Polarisサーバーを停止しています...
REM PowerShell 7とWindows PowerShellの両方を停止
taskkill /F /IM pwsh.exe 2>nul
taskkill /F /IM powershell.exe /FI "WINDOWTITLE eq UIpowershell API Server*" 2>nul

timeout /t 1 /nobreak > nul

echo [2/4] ポート8080を使用しているプロセスを停止しています...
REM ポート8080を使用しているプロセスを停止
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8080" ^| findstr "LISTENING"') do (
    taskkill /F /PID %%a 2>nul
)

timeout /t 1 /nobreak > nul

echo [3/4] ブラウザウインドウを閉じています...
REM PowerShellスクリプトでlocalhost:8080を開いているブラウザを閉じる
powershell -ExecutionPolicy Bypass -Command "& { Get-Process | Where-Object { $_.ProcessName -match 'chrome|msedge' -and $_.MainWindowTitle -match 'localhost:8080|UIpowershell' } | ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue } }"

timeout /t 1 /nobreak > nul

echo [4/4] クリーンアップ完了
echo.
echo ✅ すべてのPowerShellプロセスを終了しました
echo ✅ ポート8080を解放しました
echo ✅ ブラウザウインドウを閉じました
echo.
echo UIpowershellが完全に停止しました
echo.
echo このウインドウは3秒後に自動的に閉じます...
timeout /t 3
