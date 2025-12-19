@echo off
chcp 65001 > nul
echo ============================================
echo UIpowershell - APIサーバー起動
echo ============================================
echo.

REM 既存のPolarisサーバーを停止
echo [1/4] 既存のサーバーを停止しています...
taskkill /F /IM pwsh.exe 2>nul
taskkill /F /IM powershell.exe /FI "WINDOWTITLE eq api-server-v2.ps1*" 2>nul
timeout /t 1 /nobreak > nul

REM カレントディレクトリをスクリプトの場所に変更
cd /d "%~dp0"

REM PowerShell 7 (pwsh) が利用可能かチェック
where pwsh > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [2/4] PowerShell 7 でAPIサーバーを起動します...
    echo.
    start "UIpowershell API Server" pwsh -NoExit -ExecutionPolicy Bypass -File ".\adapter\api-server-v2.ps1"
) else (
    echo [2/4] Windows PowerShell 5.1 でAPIサーバーを起動します...
    echo.
    start "UIpowershell API Server" powershell -NoExit -ExecutionPolicy Bypass -File ".\adapter\api-server-v2.ps1"
)

echo [3/4] サーバーの起動を待機しています...
REM サーバーが応答するまで待機（最大30秒）
powershell -NoProfile -Command "$maxRetries = 30; $retry = 0; while ($retry -lt $maxRetries) { try { $r = Invoke-WebRequest -Uri 'http://localhost:8080/api/health' -TimeoutSec 1 -ErrorAction Stop; if ($r.StatusCode -eq 200) { Write-Host '[OK] サーバー起動確認'; exit 0 } } catch { $retry++; Start-Sleep -Seconds 1 } }; Write-Host '[警告] タイムアウト'; exit 1"

echo [4/4] ブラウザを起動します...
REM Microsoft Edgeで起動
set "EDGE_PATH=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
if not exist "%EDGE_PATH%" set "EDGE_PATH=%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"

if exist "%EDGE_PATH%" (
    start "" "%EDGE_PATH%" --app=http://localhost:8080/index-legacy.html --start-maximized --user-data-dir="%TEMP%\UIpowershell-Edge-Profile"
    echo ✅ ブラウザを起動しました
) else (
    echo ⚠ Microsoft Edgeが見つかりません
    echo 手動でブラウザを開いてください: http://localhost:8080/index-legacy.html
)

echo.
echo ✅ サーバーURL: http://localhost:8080/index-legacy.html
echo.
echo 【注意】
echo - サーバーウインドウを閉じないでください
echo - 停止する場合は「閉じる.bat」を実行してください
echo.
echo このウインドウは5秒後に自動的に閉じます...
timeout /t 5
