@echo off
chcp 65001 > nul
echo ============================================
echo UIpowershell - Pode API Server Launcher
echo ============================================
echo.

REM ============================================
REM [1/4] Clean shutdown: Send shutdown request via API
REM ============================================
echo [1/4] Sending shutdown request to existing server...
powershell -Command "try { Invoke-WebRequest -Uri 'http://localhost:8080/api/shutdown' -Method POST -TimeoutSec 3 -ErrorAction SilentlyContinue | Out-Null; Write-Host '    API shutdown request sent successfully' } catch { Write-Host '    No existing server found (OK)' }" 2>nul
timeout /t 2 /nobreak > nul

REM ============================================
REM [2/4] Fallback: Kill by window title
REM ============================================
echo [2/4] Stopping remaining UIpowershell processes...
taskkill /F /FI "WINDOWTITLE eq UIpowershell Pode API Server" 2>nul
taskkill /F /FI "WINDOWTITLE eq UIpowershell*" 2>nul
timeout /t 1 /nobreak > nul

REM ============================================
REM [3/4] Close browser: Close Edge tabs with localhost:8080
REM ============================================
echo [3/4] Closing UIpowershell browser window...
powershell -Command "Get-Process msedge -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -like '*localhost:8080*' -or $_.MainWindowTitle -like '*UIpowershell*' } | ForEach-Object { $_.CloseMainWindow() | Out-Null }" 2>nul
timeout /t 1 /nobreak > nul

REM Change to script directory
cd /d "%~dp0"

REM ============================================
REM [4/4] Start server
REM ============================================
REM Check if PowerShell 7 (pwsh) is available
where pwsh > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [4/4] Starting Pode API Server with PowerShell 7...
    echo.
    start "UIpowershell Pode API Server" pwsh -NoExit -ExecutionPolicy Bypass -File ".\adapter\api-server-v2-pode-complete.ps1" -AutoOpenBrowser
) else (
    echo [4/4] Starting Pode API Server with Windows PowerShell 5.1...
    echo.
    start "UIpowershell Pode API Server" powershell -NoExit -ExecutionPolicy Bypass -File ".\adapter\api-server-v2-pode-complete.ps1" -AutoOpenBrowser
)

echo.
echo Pode API Server started!
echo.
echo [OK] Browser will open in a new window
echo [OK] Server URL: http://localhost:8080/index-legacy.html
echo [OK] Server: Pode (high-speed version)
echo.
echo [NOTE]
echo - Do not close the server window
echo - To stop, press Ctrl+C in the server window
echo.
echo [Expected Improvements]
echo - API response time: 95-99%% reduction (1000ms to 10-50ms)
echo - Startup time: 35-48%% reduction (21s to 8-10s)
echo.
echo This window will close automatically in 5 seconds...
timeout /t 5
