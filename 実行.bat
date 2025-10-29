@echo off
REM 相対パスでメインスクリプトを実行（どの環境でも動作可能）
powershell -ExecutionPolicy Bypass -File "%~dp0\01_メインフォーム_メイン.ps1"
