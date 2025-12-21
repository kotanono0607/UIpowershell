@echo off
chcp 65001 > nul
echo ============================================
echo win32API.psm1 更新ツール
echo ============================================
echo.

REM コピー元とコピー先のパス
set "SOURCE=%~dp0win32API.psm1"
set "DEST=%USERPROFILE%\Documents\WindowsPowerShell\add-on\win32API.psm1"

REM コピー元の存在確認
if not exist "%SOURCE%" (
    echo [エラー] コピー元が見つかりません:
    echo    %SOURCE%
    pause
    exit /b 1
)

REM コピー先フォルダの存在確認・作成
set "DEST_DIR=%USERPROFILE%\Documents\WindowsPowerShell\add-on"
if not exist "%DEST_DIR%" (
    echo [INFO] コピー先フォルダを作成します...
    mkdir "%DEST_DIR%"
)

REM バックアップ作成（既存ファイルがある場合）
if exist "%DEST%" (
    echo [1/3] 既存ファイルをバックアップ中...
    copy /Y "%DEST%" "%DEST%.bak" > nul
    echo    バックアップ: %DEST%.bak
) else (
    echo [1/3] 既存ファイルなし（新規作成）
)

REM ファイルをコピー
echo [2/3] win32API.psm1 をコピー中...
copy /Y "%SOURCE%" "%DEST%" > nul
if %ERRORLEVEL% NEQ 0 (
    echo [エラー] コピーに失敗しました
    pause
    exit /b 1
)

echo    コピー完了: %DEST%

REM 完了メッセージ
echo [3/3] 更新完了!
echo.
echo ============================================
echo [OK] win32API.psm1 を更新しました
echo.
echo コピー元: %SOURCE%
echo コピー先: %DEST%
echo.
echo [NOTE] 新しいPowerShellセッションで反映されます
echo ============================================
