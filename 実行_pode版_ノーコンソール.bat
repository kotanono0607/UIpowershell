@echo off
chcp 65001 > nul

REM ============================================
REM UIpowershell - No Console Launcher
REM サーバーをバックグラウンドで起動（コンソール非表示）
REM ============================================

REM [1] Clean shutdown: Send shutdown request via API
powershell -Command "try { Invoke-WebRequest -Uri 'http://localhost:8080/api/shutdown' -Method POST -TimeoutSec 3 -ErrorAction SilentlyContinue | Out-Null } catch {}" 2>nul
timeout /t 2 /nobreak > nul

REM [2] Fallback: Kill by window title
taskkill /F /FI "WINDOWTITLE eq UIpowershell Pode API Server" 2>nul
taskkill /F /FI "WINDOWTITLE eq UIpowershell*" 2>nul
timeout /t 1 /nobreak > nul

REM [3] Close browser
powershell -Command "Get-Process msedge -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -like '*localhost:8080*' -or $_.MainWindowTitle -like '*UIpowershell*' } | ForEach-Object { $_.CloseMainWindow() | Out-Null }" 2>nul
timeout /t 1 /nobreak > nul

REM Change to script directory
cd /d "%~dp0"

REM [4] Start server in background (no console window)
where pwsh > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell -WindowStyle Hidden -Command "Start-Process pwsh -ArgumentList '-WindowStyle Hidden -ExecutionPolicy Bypass -File \".\adapter\api-server-v2-pode-complete.ps1\" -AutoOpenBrowser' -WindowStyle Hidden"
) else (
    powershell -WindowStyle Hidden -Command "Start-Process powershell -ArgumentList '-WindowStyle Hidden -ExecutionPolicy Bypass -File \".\adapter\api-server-v2-pode-complete.ps1\" -AutoOpenBrowser' -WindowStyle Hidden"
)

exit
