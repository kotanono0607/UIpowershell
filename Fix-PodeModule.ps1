﻿# ============================================
# Podeモジュール完全修正スクリプト
# ============================================
# PowerShell 5.1環境でPodeモジュールのConsole.ps1が
# エラーを起こす問題を解決します

param(
    [switch]$Uninstall
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Podeモジュール修正ツール" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Podeモジュールのパス
$podeModulePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Pode"
$podeConsoleFile = "$podeModulePath\2.12.1\Private\Console.ps1"

if ($Uninstall) {
    Write-Host "[1/2] Podeモジュールを完全にアンインストールします..." -ForegroundColor Yellow

    # モジュールがロードされている場合は削除
    if (Get-Module Pode) {
        Remove-Module Pode -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ メモリから削除しました" -ForegroundColor Gray
    }

    # アンインストール
    Uninstall-Module -Name Pode -AllVersions -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ アンインストールしました" -ForegroundColor Gray

    # ディレクトリを削除
    if (Test-Path $podeModulePath) {
        Remove-Item $podeModulePath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ ディレクトリを削除しました" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "[2/2] Podeモジュールを再インストールします..." -ForegroundColor Yellow
    Install-Module -Name Pode -Scope CurrentUser -Force -AllowClobber
    Write-Host "  ✓ インストール完了" -ForegroundColor Green
    Write-Host ""
}

# Console.ps1の修正
Write-Host "[修正] Console.ps1を修正します..." -ForegroundColor Cyan

if (-not (Test-Path $podeConsoleFile)) {
    Write-Host "[エラー] Console.ps1が見つかりません: $podeConsoleFile" -ForegroundColor Red
    Write-Host "        まず -Uninstall オプションで実行してください" -ForegroundColor Yellow
    exit 1
}

try {
    # バックアップ作成
    $backupFile = "$podeConsoleFile.backup"
    if (-not (Test-Path $backupFile)) {
        Copy-Item $podeConsoleFile $backupFile -Force
        Write-Host "  ✓ バックアップ作成: $backupFile" -ForegroundColor Gray
    }

    # ファイルを読み込み（バイナリモードで正確に読み取る）
    $content = [System.IO.File]::ReadAllText($podeConsoleFile, [System.Text.Encoding]::UTF8)

    # 463行目付近の問題のある文字列を直接修正
    # エラーが発生している箇所を特定して修正
    $originalContent = $content

    # 方法1: 問題のある行を直接置換（最も確実）
    $content = $content -replace "# Repeat the UTF-8 '.+ \(heavy horizontal line\) character", "# Repeat the horizontal line character"

    # 方法2: すべての非ASCII文字をコメント内から削除
    $lines = $content -split "`r?`n"
    $fixedLines = @()
    $lineNumber = 0
    $replacedCount = 0

    foreach ($line in $lines) {
        $lineNumber++
        $originalLine = $line

        # 463行目付近を特に注意深く処理
        if ($lineNumber -ge 460 -and $lineNumber -le 470) {
            # この範囲のコメント内の非ASCII文字を全て削除
            if ($line -match '#') {
                $parts = $line -split '#', 2
                if ($parts.Count -eq 2) {
                    $code = $parts[0]
                    $comment = $parts[1]

                    # 非ASCII文字を削除（空白に置換）
                    $comment = $comment -replace '[^\x00-\x7F]', ''

                    $line = $code + '#' + $comment
                }
            }
        }

        # 全体的な処理：Box Drawing文字を置換
        $line = $line -replace [char]0x2500, '-'
        $line = $line -replace [char]0x2501, '-'
        $line = $line -replace [char]0x2502, '|'
        $line = $line -replace [char]0x2503, '|'
        $line = $line -replace [char]0x2013, '-'
        $line = $line -replace [char]0x2014, '-'
        $line = $line -replace [char]0x2212, '-'

        if ($originalLine -ne $line) {
            $replacedCount++
            Write-Host "  修正 (行 $lineNumber): $originalLine" -ForegroundColor DarkGray
            Write-Host "    -> $line" -ForegroundColor DarkGray
        }

        $fixedLines += $line
    }

    # UTF-8 BOMで保存
    $utf8BOM = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllLines($podeConsoleFile, $fixedLines, $utf8BOM)

    Write-Host ""
    if ($replacedCount -gt 0) {
        Write-Host "[成功] Console.ps1を修正しました ($replacedCount 行を変更)" -ForegroundColor Green
    } else {
        Write-Host "[情報] 修正の必要はありませんでした" -ForegroundColor Gray
    }

    # 修正を検証
    Write-Host ""
    Write-Host "[検証] Podeモジュールをテスト読み込みします..." -ForegroundColor Cyan

    # 既存のモジュールを削除
    if (Get-Module Pode) {
        Remove-Module Pode -Force
    }

    # 再読み込み
    Import-Module Pode -ErrorAction Stop
    $version = (Get-Module Pode).Version

    Write-Host "[成功] Podeモジュールが正常に読み込まれました (Version: $version)" -ForegroundColor Green
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "修正が完了しました！" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green

} catch {
    Write-Host ""
    Write-Host "[エラー] 修正に失敗しました" -ForegroundColor Red
    Write-Host "詳細: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "以下のコマンドで再試行してください:" -ForegroundColor Yellow
    Write-Host "  .\Fix-PodeModule.ps1 -Uninstall" -ForegroundColor Yellow
    exit 1
}
