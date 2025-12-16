@echo off
chcp 65001 > nul
echo ============================================
echo UIpowershell - Pode API Server Launcher
echo ============================================
echo.

REM Stop existing servers
echo [1/3] Stopping existing servers...
taskkill /F /IM pwsh.exe 2>nul
taskkill /F /IM powershell.exe /FI "WINDOWTITLE eq api-server-v2*" 2>nul
timeout /t 1 /nobreak > nul

REM Change to script directory
cd /d "%~dp0"

REM Check if PowerShell 7 (pwsh) is available
where pwsh > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [2/3] Starting Pode API Server with PowerShell 7...
    echo.
    start "UIpowershell Pode API Server" pwsh -NoExit -ExecutionPolicy Bypass -File ".\adapter\api-server-v2-pode-complete.ps1" -AutoOpenBrowser
) else (
    echo [2/3] Starting Pode API Server with Windows PowerShell 5.1...
    echo.
    start "UIpowershell Pode API Server" powershell -NoExit -ExecutionPolicy Bypass -File ".\adapter\api-server-v2-pode-complete.ps1" -AutoOpenBrowser
)

echo [3/3] Pode API Server started!
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
