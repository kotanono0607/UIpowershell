@echo off
chcp 65001 > nul
echo ============================================
echo win32API.psm1 Update Tool
echo ============================================
echo.

REM Source and destination paths
set "SOURCE=%~dp0win32API.psm1"
set "DEST=%USERPROFILE%\Documents\WindowsPowerShell\add-on\win32API.psm1"

REM Check if source exists
if not exist "%SOURCE%" (
    echo [ERROR] Source file not found:
    echo    %SOURCE%
    pause
    exit /b 1
)

REM Check/create destination folder
set "DEST_DIR=%USERPROFILE%\Documents\WindowsPowerShell\add-on"
if not exist "%DEST_DIR%" (
    echo [INFO] Creating destination folder...
    mkdir "%DEST_DIR%"
)

REM Backup existing file if exists
if exist "%DEST%" (
    echo [1/3] Backing up existing file...
    copy /Y "%DEST%" "%DEST%.bak" > nul
    echo    Backup: %DEST%.bak
) else (
    echo [1/3] No existing file (new install)
)

REM Copy file
echo [2/3] Copying win32API.psm1...
copy /Y "%SOURCE%" "%DEST%" > nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Copy failed
    pause
    exit /b 1
)

echo    Copy complete: %DEST%

REM Completion message
echo [3/3] Update complete!
echo.
echo ============================================
echo [OK] win32API.psm1 has been updated
echo.
echo Source: %SOURCE%
echo Destination: %DEST%
echo.
echo [NOTE] Changes take effect in new PowerShell sessions
echo ============================================
