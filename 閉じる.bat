@echo off
chcp 65001 > nul
echo ============================================
echo UIpowershell - 完全停止（サーバー+Edge）
echo ============================================
echo.
echo ℹ️  Microsoft Edge（UIpowershell専用）のみ終了します
echo    Chrome等の他のブラウザは影響を受けません
echo.

echo [1/6] ポート8080-8090を使用しているプロセスを停止しています...
REM ポート8080-8090の範囲でリスニングしているプロセスを停止
for /L %%p in (8080,1,8090) do (
    for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr ":%%p" ^| findstr "LISTENING"') do (
        echo   - ポート%%p: PID %%a を終了中...
        taskkill /F /PID %%a 2>nul
    )
)

timeout /t 1 /nobreak > nul

echo [2/6] Microsoft Edge（UIpowershell専用）を閉じています...
REM Edge専用終了（Chrome対象外で完全分離）
REM 方法1: WMI経由でCommandLineをチェック（より互換性が高い）
powershell -ExecutionPolicy Bypass -Command "& { $found = $false; try { Get-WmiObject Win32_Process | Where-Object { $_.Name -eq 'msedge.exe' -and $_.CommandLine -like '*--app=*localhost:*' } | ForEach-Object { $found = $true; Write-Host \"  - Edge (PID: $($_.ProcessId), CommandLine確認) を終了中...\"; Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } } catch { Write-Host \"  - WMIによる検索をスキップ\" }; if (-not $found) { try { $procs = Get-Process msedge -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -like '*localhost*' }; if ($procs) { $procs | ForEach-Object { $found = $true; Write-Host \"  - Edge (PID: $($_.Id), WindowTitle確認) を終了中...\"; Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue } } } catch {} }; if (-not $found) { Write-Host \"  - UIpowershell用Edgeは見つかりませんでした\" } }"

timeout /t 1 /nobreak > nul

echo [3/6] UIpowershell関連のPowerShellプロセスを停止しています...
REM api-server-v2.ps1を実行しているPowerShellを停止（WMI経由で確実に）
powershell -ExecutionPolicy Bypass -Command "& { $found = $false; try { Get-WmiObject Win32_Process | Where-Object { ($_.Name -eq 'powershell.exe' -or $_.Name -eq 'pwsh.exe') -and $_.CommandLine -like '*api-server-v2.ps1*' } | ForEach-Object { $found = $true; Write-Host \"  - APIサーバー (PID: $($_.ProcessId)) を終了中...\"; Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } } catch {}; if (-not $found) { try { Get-Process | Where-Object { ($_.Name -eq 'powershell' -or $_.Name -eq 'pwsh') -and $_.MainWindowTitle -like '*api-server*' } | ForEach-Object { Write-Host \"  - APIサーバー (PID: $($_.Id)) を終了中...\"; Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue } } catch {} } }"

REM quick-start.ps1を実行しているPowerShellを停止
powershell -ExecutionPolicy Bypass -Command "& { $found = $false; try { Get-WmiObject Win32_Process | Where-Object { ($_.Name -eq 'powershell.exe' -or $_.Name -eq 'pwsh.exe') -and $_.CommandLine -like '*quick-start.ps1*' } | ForEach-Object { $found = $true; Write-Host \"  - QuickStartプロセス (PID: $($_.ProcessId)) を終了中...\"; Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } } catch {}; if (-not $found) { try { Get-Process | Where-Object { ($_.Name -eq 'powershell' -or $_.Name -eq 'pwsh') -and $_.MainWindowTitle -like '*quick-start*' } | ForEach-Object { Write-Host \"  - QuickStartプロセス (PID: $($_.Id)) を終了中...\"; Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue } } catch {} } }"

timeout /t 1 /nobreak > nul

echo [4/6] 残りのPowerShellプロセスを確認しています...
REM タイトルに"UIpowershell"を含むPowerShellウインドウを停止
taskkill /F /FI "WINDOWTITLE eq UIpowershell*" 2>nul

REM pwsh.exeプロセスを停止（念のため）
taskkill /F /IM pwsh.exe 2>nul

timeout /t 1 /nobreak > nul

echo [5/6] クリーンアップ完了
echo.
echo ✅ ポート8080-8090の範囲でリスニングしていたプロセスを終了しました
echo ✅ Microsoft Edge（UIpowershell専用）を閉じました
echo ✅ UIpowershell関連のPowerShellプロセスを終了しました
echo ✅ PowerShellコンソールウインドウを閉じました
echo.
echo ✨ Chrome等の他のブラウザは影響を受けていません
echo.

timeout /t 1 /nobreak > nul

echo [6/6] ログをGitにプッシュしています...
REM ログファイルが存在するか確認
if exist "logs\*.log" (
    echo   - ログファイルが見つかりました。Gitにプッシュします...
    powershell -ExecutionPolicy Bypass -Command "& { try { Set-Location '%~dp0'; $env:AUTO_PUSH=1; & '.\git-push-local.ps1' 'Update: サーバー実行ログを自動保存' 2>&1 | Out-String | Write-Host; Write-Host '  ✅ ログのGitプッシュが完了しました' -ForegroundColor Green } catch { Write-Host '  ⚠️ ログのGitプッシュに失敗しました（無視して続行）' -ForegroundColor Yellow } }"
) else (
    echo   - ログファイルが見つかりませんでした（プッシュをスキップ）
)
echo.

echo UIpowershellが完全に停止しました
echo.
echo このウインドウは5秒後に自動的に閉じます...
timeout /t 5
