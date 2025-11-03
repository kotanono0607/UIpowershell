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

echo [3/4] アプリモードで起動したブラウザウインドウを閉じています...
REM PowerShellスクリプトで--appモードで起動されたブラウザのみを閉じる
REM コマンドライン引数に "--app=http://localhost:8080" を含むプロセスのみ
powershell -ExecutionPolicy Bypass -Command "& { Get-WmiObject Win32_Process | Where-Object { ($_.Name -eq 'chrome.exe' -or $_.Name -eq 'msedge.exe') -and $_.CommandLine -like '*--app=http://localhost:8080*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } }"

timeout /t 1 /nobreak > nul

echo [4/4] クリーンアップ完了
echo.
echo ✅ すべてのPowerShellプロセスを終了しました
echo ✅ ポート8080を解放しました
echo ✅ アプリモードで起動したブラウザウインドウを閉じました
echo    （手動で開いたブラウザウインドウは影響を受けません）
echo.
echo UIpowershellが完全に停止しました
echo.
echo このウインドウは3秒後に自動的に閉じます...
timeout /t 3
