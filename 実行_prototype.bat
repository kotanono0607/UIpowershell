@echo off
REM ============================================
REM UIpowershell - HTML版プロトタイプ起動スクリプト
REM ============================================
REM アーキテクチャ: Polaris HTTPサーバー + React Flow (CDN)
REM ゼロインストール: PowerShellとブラウザのみで動作
REM ============================================

echo ============================================
echo UIpowershell - HTML版プロトタイプ起動
echo ============================================
echo.

REM PowerShellの実行ポリシーをバイパスして起動
REM -AutoOpenBrowser オプションでブラウザを自動起動
powershell -ExecutionPolicy Bypass -File "%~dp0adapter\api-server.ps1" -AutoOpenBrowser

echo.
echo サーバーが停止しました
pause
