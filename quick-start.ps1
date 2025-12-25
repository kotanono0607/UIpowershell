# ============================================
# UIpowershell クイックスタートスクリプト
# ============================================
# 役割：ワンクリックで動作確認を開始
#
# 使い方：
#   .\quick-start.ps1                    # デフォルト（ポート8080、ブラウザ自動起動）
#   .\quick-start.ps1 -Port 8081         # ポート指定
#   .\quick-start.ps1 -NoBrowser         # ブラウザを開かない
#   .\quick-start.ps1 -NoAutoInstall     # Pode自動インストールを無効
#
# 特徴：
#   - 対話プロンプトなし（完全自動）
#   - PowerShell 5.x/7.x 両対応
#   - ポート使用中の場合は自動的に次のポートを使用
#   - Podeがない場合は自動インストール
# ============================================

param(
    [int]$Port = 8080,
    [switch]$NoBrowser,
    [switch]$NoAutoInstall
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  UIpowershell クイックスタート" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# 1. 必須ファイルの存在チェック
# ============================================

Write-Host "【Step 1】必須ファイルの確認..." -ForegroundColor Yellow
Write-Host ""

$requiredFiles = @(
    "adapter\api-server-v2-pode-complete.ps1",
    "adapter\state-manager.ps1",
    "adapter\node-operations.ps1",
    "ui\index-legacy.html",
    "ui\app-legacy.js",
    "12_コードメイン_コード本文_v2.ps1",
    "10_変数機能_変数管理UI_v2.ps1",
    "07_メインF機能_ツールバー作成_v2.ps1",
    "08_メインF機能_メインボタン処理_v2.ps1",
    "02-6_削除処理_v2.ps1",
    "02-2_ネスト規制バリデーション_v2.ps1"
)

$allFilesExist = $true

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file （見つかりません）" -ForegroundColor Red
        $allFilesExist = $false
    }
}

Write-Host ""

if (-not $allFilesExist) {
    Write-Host "【エラー】必須ファイルが不足しています" -ForegroundColor Red
    Write-Host "プロジェクトディレクトリで実行しているか確認してください" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "【OK】すべての必須ファイルが揃っています" -ForegroundColor Green
Write-Host ""

# ============================================
# 2. PowerShellバージョンチェック
# ============================================

Write-Host "【Step 2】PowerShellバージョンの確認..." -ForegroundColor Yellow
Write-Host ""

$psVersion = $PSVersionTable.PSVersion
Write-Host "  PowerShellバージョン: $psVersion" -ForegroundColor White

if ($psVersion.Major -lt 7) {
    Write-Host "  ⚠ 警告: PowerShell 7.x 以上を推奨します" -ForegroundColor Yellow
    Write-Host "  現在のバージョン（$psVersion）でも動作しますが、問題が発生する場合は" -ForegroundColor Yellow
    Write-Host "  PowerShell 7.x をインストールしてください" -ForegroundColor Yellow
    Write-Host "  → 自動的に続行します..." -ForegroundColor Gray
} else {
    Write-Host "  ✓ PowerShell 7.x 以上です" -ForegroundColor Green
}

Write-Host ""

# ============================================
# 3. Podeモジュールのチェック
# ============================================

Write-Host "【Step 3】Podeモジュールの確認..." -ForegroundColor Yellow
Write-Host ""

$podeReady = $false

# ローカルのPodeモジュールをチェック（バージョン付きフォルダ構造に対応）
$localPodePath = ".\Modules\Pode"
$localPodeVersionPath = Get-ChildItem -Path ".\Modules\Pode\*\Pode.psm1" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($localPodeVersionPath) {
    Write-Host "  ✓ ローカルPodeモジュールが存在します: $($localPodeVersionPath.Directory.FullName)" -ForegroundColor Green
    $podeReady = $true
} elseif (Test-Path "$localPodePath\Pode.psm1") {
    Write-Host "  ✓ ローカルPodeモジュールが存在します: $localPodePath" -ForegroundColor Green
    $podeReady = $true
} else {
    # システムにインストールされているかチェック
    $podeModule = Get-Module -ListAvailable -Name Pode -ErrorAction SilentlyContinue

    if ($podeModule) {
        Write-Host "  ✓ Podeモジュールがインストールされています (Version: $($podeModule.Version))" -ForegroundColor Green
        $podeReady = $true
    } else {
        Write-Host "  ✗ Podeモジュールが見つかりません" -ForegroundColor Red

        if ($NoAutoInstall) {
            Write-Host "  → 自動インストールがスキップされました（-NoAutoInstall）" -ForegroundColor Yellow
            $podeReady = $false
        } else {
            Write-Host "  → 自動的にインストールします..." -ForegroundColor Cyan
            Write-Host ""
            try {
                Install-Module -Name Pode -Scope CurrentUser -Force -AllowClobber
                Write-Host "  ✓ Podeのインストールに成功しました" -ForegroundColor Green
                $podeReady = $true
            } catch {
                Write-Host "  ✗ インストールに失敗しました: $($_.Exception.Message)" -ForegroundColor Red
                $podeReady = $false
            }
        }
    }
}

Write-Host ""

if (-not $podeReady) {
    Write-Host "【エラー】Podeモジュールが利用できません" -ForegroundColor Red
    Write-Host "手動でインストールしてください:" -ForegroundColor Yellow
    Write-Host "  Install-Module -Name Pode -Scope CurrentUser -Force" -ForegroundColor Yellow
    pause
    exit 1
}

# ============================================
# 4. ポート使用状況のチェック
# ============================================

Write-Host "【Step 4】ポート $Port の使用状況を確認..." -ForegroundColor Yellow
Write-Host ""

$portInUse = $false
try {
    $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $Port)
    $listener.Start()
    $listener.Stop()
    Write-Host "  ✓ ポート $Port は利用可能です" -ForegroundColor Green
} catch {
    Write-Host "  ⚠ ポート $Port は既に使用中です" -ForegroundColor Yellow
    # 自動的に次のポートを試す
    $originalPort = $Port
    $maxAttempts = 10
    $foundPort = $false

    for ($i = 1; $i -le $maxAttempts; $i++) {
        $Port = $originalPort + $i
        try {
            $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $Port)
            $listener.Start()
            $listener.Stop()
            Write-Host "  → 自動的にポート $Port を使用します" -ForegroundColor Cyan
            $foundPort = $true
            break
        } catch {
            # 次のポートを試す
        }
    }

    if (-not $foundPort) {
        Write-Host "  ✗ 利用可能なポートが見つかりませんでした（$originalPort-$Port）" -ForegroundColor Red
        Write-Host "  既存のサーバーを停止してから再実行してください" -ForegroundColor Yellow
        pause
        exit 1
    }
}

Write-Host ""

# ============================================
# 5. APIサーバーを起動
# ============================================

Write-Host "【Step 5】APIサーバーを起動します..." -ForegroundColor Yellow
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  起動設定" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ポート: $Port" -ForegroundColor White
Write-Host "  URL: http://localhost:$Port" -ForegroundColor White
Write-Host "  フロントエンド: http://localhost:$Port/index-legacy.html" -ForegroundColor White
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ブラウザ自動起動の設定
if ($NoBrowser) {
    $openBrowser = $false
    Write-Host "ブラウザは自動起動しません（-NoBrowserオプション）" -ForegroundColor Gray
} else {
    $openBrowser = $true
    Write-Host "サーバー起動後にブラウザを自動的に開きます" -ForegroundColor Gray
    Write-Host "（ブラウザを開きたくない場合: .\quick-start.ps1 -NoBrowser）" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "サーバーを起動中..." -ForegroundColor Cyan
Write-Host ""

# サーバー起動（Pode版）
try {
    if ($openBrowser) {
        & ".\adapter\api-server-v2-pode-complete.ps1" -Port $Port -AutoOpenBrowser
    } else {
        & ".\adapter\api-server-v2-pode-complete.ps1" -Port $Port
    }
} catch {
    Write-Host ""
    Write-Host "【エラー】サーバー起動に失敗しました" -ForegroundColor Red
    Write-Host "詳細: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "トラブルシューティング:" -ForegroundColor Yellow
    Write-Host "  1. TEST_INSTRUCTIONS.md のトラブルシューティングセクションを参照" -ForegroundColor Yellow
    Write-Host "  2. 管理者権限で実行してみてください" -ForegroundColor Yellow
    Write-Host "  3. ファイアウォール設定を確認してください" -ForegroundColor Yellow
    pause
    exit 1
}
