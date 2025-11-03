@echo off
chcp 65001 > nul
echo ============================================
echo UIpowershell - 完全停止（サーバー+ブラウザ）
echo ============================================
echo.

echo [1/5] ポート8080を使用しているプロセスを停止しています...
REM ポート8080を使用しているプロセスを停止
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8080" ^| findstr "LISTENING"') do (
    echo   - PID %%a を終了中...
    taskkill /F /PID %%a 2>nul
)

timeout /t 1 /nobreak > nul

echo [2/5] アプリモードで起動したブラウザを閉じています...
echo   （--app=http://localhost:8080 で起動されたプロセスのみ）
REM --appモードで起動されたブラウザのみを閉じる（手動ブラウザは保護）
powershell -ExecutionPolicy Bypass -Command "& { $found = $false; Get-CimInstance Win32_Process | Where-Object { ($_.Name -eq 'chrome.exe' -or $_.Name -eq 'msedge.exe') -and $_.CommandLine -like '*--app=*localhost:8080*' } | ForEach-Object { $found = $true; Write-Host \"  - ブラウザプロセス (PID: $($_.ProcessId), $($_.Name)) を終了中...\"; Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }; if (-not $found) { Write-Host \"  - アプリモードのブラウザは見つかりませんでした\" } }"

timeout /t 1 /nobreak > nul

echo [3/5] UIpowershell関連のPowerShellプロセスを停止しています...
REM api-server-v2.ps1を実行しているPowerShellを停止
powershell -ExecutionPolicy Bypass -Command "& { Get-CimInstance Win32_Process | Where-Object { ($_.Name -eq 'powershell.exe' -or $_.Name -eq 'pwsh.exe') -and $_.CommandLine -like '*api-server-v2.ps1*' } | ForEach-Object { Write-Host \"  - APIサーバー (PID: $($_.ProcessId)) を終了中...\"; Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } }"

REM quick-start.ps1を実行しているPowerShellを停止
powershell -ExecutionPolicy Bypass -Command "& { Get-CimInstance Win32_Process | Where-Object { ($_.Name -eq 'powershell.exe' -or $_.Name -eq 'pwsh.exe') -and $_.CommandLine -like '*quick-start.ps1*' } | ForEach-Object { Write-Host \"  - QuickStartプロセス (PID: $($_.ProcessId)) を終了中...\"; Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } }"

timeout /t 1 /nobreak > nul

echo [4/5] 残りのPowerShellプロセスを確認しています...
REM タイトルに"UIpowershell"を含むPowerShellウインドウを停止
taskkill /F /FI "WINDOWTITLE eq UIpowershell*" 2>nul

REM pwsh.exeプロセスを停止（念のため）
taskkill /F /IM pwsh.exe 2>nul

timeout /t 1 /nobreak > nul

echo [5/5] クリーンアップ完了
echo.
echo ✅ ポート8080を解放しました
echo ✅ アプリモードで起動したブラウザを閉じました
echo ✅ UIpowershell関連のPowerShellプロセスを終了しました
echo ✅ PowerShellコンソールウインドウを閉じました
echo.
echo ℹ️  注意: 手動で開いたブラウザは影響を受けません
echo.
echo UIpowershellが完全に停止しました
echo.
echo このウインドウは3秒後に自動的に閉じます...
timeout /t 3
