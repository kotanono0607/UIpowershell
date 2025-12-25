﻿# ============================================
# UIpowershell 配布パッケージ作成スクリプト
# ============================================
# 目的：完全スタンドアロン配布用ZIPを作成
# 要件：管理者権限不要、インターネット不要、インストール不要
# ============================================

param(
    [string]$OutputPath = ".\配布"
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "UIpowershell 配布パッケージ作成" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"

# ============================================
# 1. Podeモジュールの確認とインストール
# ============================================

Write-Host "[1/5] Podeモジュールを確認..." -ForegroundColor Yellow

$podeModule = Get-Module -ListAvailable -Name Pode | Select-Object -First 1

if (-not $podeModule) {
    Write-Host "      Podeがインストールされていません。インストールします..." -ForegroundColor Yellow
    try {
        Install-Module -Name Pode -Scope CurrentUser -Force -AllowClobber
        $podeModule = Get-Module -ListAvailable -Name Pode | Select-Object -First 1
        Write-Host "      [OK] Podeをインストールしました" -ForegroundColor Green
    } catch {
        Write-Host ""
        Write-Host "[エラー] Podeのインストールに失敗しました" -ForegroundColor Red
        Write-Host "詳細: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "手動でインストールしてください:" -ForegroundColor Yellow
        Write-Host "  Install-Module -Name Pode -Scope CurrentUser -Force" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "      [OK] Pode Version $($podeModule.Version) を検出" -ForegroundColor Green
}

# ============================================
# 2. 配布ディレクトリの作成
# ============================================

Write-Host "[2/5] 配布ディレクトリを作成..." -ForegroundColor Yellow

$distDir = Join-Path $PSScriptRoot $OutputPath
$distUIpowershell = Join-Path $distDir "UIpowershell"

if (Test-Path $distDir) {
    Write-Host "      既存の配布ディレクトリを削除します..." -ForegroundColor Gray
    Remove-Item -Path $distDir -Recurse -Force
}

New-Item -ItemType Directory -Path $distUIpowershell -Force | Out-Null
Write-Host "      [OK] $distUIpowershell" -ForegroundColor Green

# ============================================
# 3. 必要なファイルをコピー
# ============================================

Write-Host "[3/5] プロジェクトファイルをコピー..." -ForegroundColor Yellow

# コピー対象のファイル・ディレクトリ
$itemsToCopy = @(
    "adapter",
    "ui",
    "00_code",
    "00_共通ユーティリティ_JSON操作.ps1",
    "09_変数機能_コードID管理JSON.ps1",
    "実行_prototype.bat",
    "PROTOTYPE_README.md"
)

foreach ($item in $itemsToCopy) {
    $sourcePath = Join-Path $PSScriptRoot $item
    $destPath = Join-Path $distUIpowershell $item

    if (Test-Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
        Write-Host "      [OK] $item" -ForegroundColor Green
    } else {
        Write-Host "      [警告] $item が見つかりません（スキップ）" -ForegroundColor Yellow
    }
}

# ============================================
# 4. Podeモジュールをコピー（重要！）
# ============================================

Write-Host "[4/5] Podeモジュールをコピー（完全スタンドアロン化）..." -ForegroundColor Yellow

$podeSourcePath = $podeModule.ModuleBase
$podeDestPath = Join-Path $distUIpowershell "Modules\Pode"

# Modulesディレクトリを作成
$modulesDir = Join-Path $distUIpowershell "Modules"
if (-not (Test-Path $modulesDir)) {
    New-Item -ItemType Directory -Path $modulesDir -Force | Out-Null
}

# Podeモジュール全体をコピー
Copy-Item -Path $podeSourcePath -Destination $podeDestPath -Recurse -Force

Write-Host "      [OK] Podeモジュールをコピー完了" -ForegroundColor Green
Write-Host "      場所: $podeDestPath" -ForegroundColor Gray
Write-Host "      サイズ: $([math]::Round((Get-ChildItem $podeDestPath -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)) MB" -ForegroundColor Gray

# ============================================
# 5. 配布用README作成
# ============================================

Write-Host "[5/5] 配布用READMEを作成..." -ForegroundColor Yellow

$readmeContent = @"
# UIpowershell HTML版プロトタイプ - 配布パッケージ

## 🎯 特徴

- ✅ **完全スタンドアロン**：インターネット不要・完全オフライン動作
- ✅ **インストール不要**：ZIPを展開してすぐ使える
- ✅ **管理者権限不要**：通常ユーザーで動作
- ✅ **依存関係ゼロ**：PowerShellとブラウザのみ
- ✅ **完全オフライン**：すべてのライブラリをローカルに同梱

## 📦 含まれるもの

- Podeモジュール (Version $($podeModule.Version)) - 同梱済み
- React 18 + ReactDOM 18 - ローカル同梱 (約11KB + 129KB)
- React Flow 11 - ローカル同梱 (約151KB + 7.5KB CSS)
- 既存PowerShell関数 (70%再利用)

**重要**: すべてのJavaScriptライブラリがローカルに含まれているため、インターネット接続なしで動作します。

## 🚀 使い方

### 1. ZIPを展開

任意の場所に展開してください（例：デスクトップ、USBメモリ、ネットワークドライブ）

### 2. 起動

``````
実行_prototype.bat をダブルクリック
``````

### 3. ブラウザでアクセス

自動的にブラウザが開きます。開かない場合は手動でアクセス：

``````
http://localhost:8080
``````

## ⚠️ 注意事項

### 完全オフライン動作

このパッケージは**完全オフライン対応**です：

- **Podeサーバー起動**：インターネット不要 ✅
- **React/ReactDOM/React Flow読み込み**：ローカルから読み込み ✅
- **すべてのライブラリ**：ui/libs/ に同梱済み ✅

**インターネット接続は一切不要です**。閉域網・オフライン環境でも動作します。

### ポート8080

ポート8080が既に使用中の場合は、以下で別ポートを指定：

``````powershell
.\adapter\api-server.ps1 -Port 8081 -AutoOpenBrowser
``````

## 📋 動作確認済み環境

- Windows 10/11
- PowerShell 5.1以降
- Chrome / Edge / Firefox

## 🔒 セキュリティ

- Podeは localhost (127.0.0.1) のみリスニング
- 外部ネットワークからのアクセスは不可
- データはすべてローカルに保存

## 📞 サポート

詳細は PROTOTYPE_README.md を参照してください。

---

**配布日**: $(Get-Date -Format "yyyy年MM月dd日 HH:mm")
**Podeバージョン**: $($podeModule.Version)
**ライセンス**: MIT License (Pode), プロジェクトライセンスに準拠 (UIpowershell)
"@

$readmePath = Join-Path $distUIpowershell "配布用README.txt"
$readmeContent | Out-File -FilePath $readmePath -Encoding UTF8

Write-Host "      [OK] 配布用README.txt" -ForegroundColor Green

# ============================================
# 完了
# ============================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "✓ 配布パッケージ作成完了！" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "配布先: $distUIpowershell" -ForegroundColor Cyan
Write-Host ""

# サイズ計算
$totalSize = (Get-ChildItem $distUIpowershell -Recurse | Measure-Object -Property Length -Sum).Sum
$totalSizeMB = [math]::Round($totalSize / 1MB, 2)

Write-Host "パッケージサイズ: $totalSizeMB MB" -ForegroundColor Yellow
Write-Host ""

# ファイル数
$fileCount = (Get-ChildItem $distUIpowershell -Recurse -File | Measure-Object).Count
Write-Host "ファイル数: $fileCount" -ForegroundColor Yellow
Write-Host ""

Write-Host "含まれるもの:" -ForegroundColor Cyan
Write-Host "  ✅ Podeモジュール（完全版）" -ForegroundColor White
Write-Host "  ✅ adapter/api-server-v2-pode-complete.ps1" -ForegroundColor White
Write-Host "  ✅ ui/index-legacy.html" -ForegroundColor White
Write-Host "  ✅ 既存PowerShell関数" -ForegroundColor White
Write-Host "  ✅ 実行_prototype.bat" -ForegroundColor White
Write-Host "  ✅ ドキュメント" -ForegroundColor White
Write-Host ""

Write-Host "次のステップ:" -ForegroundColor Yellow
Write-Host "  1. $distUIpowershell をZIP圧縮" -ForegroundColor White
Write-Host "  2. 配布先に展開" -ForegroundColor White
Write-Host "  3. 実行_prototype.bat をダブルクリック" -ForegroundColor White
Write-Host ""

# ZIP作成オプション
$createZip = Read-Host "今すぐZIPファイルを作成しますか？ (Y/N)"

if ($createZip -eq "Y" -or $createZip -eq "y") {
    Write-Host ""
    Write-Host "ZIPファイルを作成中..." -ForegroundColor Yellow

    $zipPath = Join-Path $distDir "UIpowershell_配布版_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"

    try {
        Compress-Archive -Path $distUIpowershell -DestinationPath $zipPath -Force
        Write-Host "[OK] ZIPファイル作成完了！" -ForegroundColor Green
        Write-Host "     $zipPath" -ForegroundColor Cyan
        Write-Host ""

        # エクスプローラーで開く
        $openExplorer = Read-Host "エクスプローラーで開きますか？ (Y/N)"
        if ($openExplorer -eq "Y" -or $openExplorer -eq "y") {
            Start-Process explorer.exe "/select,`"$zipPath`""
        }
    } catch {
        Write-Host "[エラー] ZIP作成に失敗しました" -ForegroundColor Red
        Write-Host "詳細: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "完了！" -ForegroundColor Green
