# ============================================
# UIpowershell - 組織PC互換性チェック
# ============================================
# 目的：組織内PCでUIpowershellが実行可能かチェック
# 所要時間：約10秒
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "UIpowershell - 組織PC互換性チェック" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "このスクリプトは、UIpowershellがこのPCで実行可能かチェックします。" -ForegroundColor Gray
Write-Host "所要時間：約10秒" -ForegroundColor Gray
Write-Host ""

$issues = @()
$warnings = @()

# ============================================
# 1. PowerShell実行ポリシー
# ============================================

Write-Host "[1/6] PowerShell実行ポリシーをチェック..." -ForegroundColor Yellow

$policies = Get-ExecutionPolicy -List
$machinePolicy = ($policies | Where-Object {$_.Scope -eq "MachinePolicy"}).ExecutionPolicy
$userPolicy = ($policies | Where-Object {$_.Scope -eq "UserPolicy"}).ExecutionPolicy
$currentUser = ($policies | Where-Object {$_.Scope -eq "CurrentUser"}).ExecutionPolicy

Write-Host "      MachinePolicy: $machinePolicy" -ForegroundColor Gray
Write-Host "      UserPolicy: $userPolicy" -ForegroundColor Gray
Write-Host "      CurrentUser: $currentUser" -ForegroundColor Gray

if ($machinePolicy -eq "Restricted") {
    Write-Host "      [エラー] グループポリシーで実行が完全に制限されています" -ForegroundColor Red
    $issues += "PowerShell実行ポリシー（Restricted）"
} elseif ($machinePolicy -eq "AllSigned") {
    Write-Host "      [警告] 署名付きスクリプトのみ実行可能です（UIpowershellは未署名）" -ForegroundColor Red
    $issues += "PowerShell実行ポリシー（AllSigned）"
} else {
    Write-Host "      [OK] PowerShellスクリプトは実行可能です" -ForegroundColor Green
}

# ============================================
# 2. ポート8080の使用可否
# ============================================

Write-Host ""
Write-Host "[2/6] ポート8080の使用可否をチェック..." -ForegroundColor Yellow

try {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 8080)
    $listener.Start()
    Start-Sleep -Milliseconds 100
    $listener.Stop()
    Write-Host "      [OK] ポート8080は使用可能です" -ForegroundColor Green
} catch {
    if ($_.Exception.Message -like "*既に使用されています*" -or $_.Exception.Message -like "*already in use*") {
        Write-Host "      [警告] ポート8080は現在使用中です（別のアプリケーションが使用中）" -ForegroundColor Yellow
        Write-Host "      対処法：別のポートを使用してください（例：-Port 8081）" -ForegroundColor Gray
        $warnings += "ポート8080使用中（代替ポートで回避可能）"
    } else {
        Write-Host "      [エラー] ポート8080が使用できません: $($_.Exception.Message)" -ForegroundColor Red
        $issues += "ポート8080の使用制限"
    }
}

# ============================================
# 3. ファイアウォール（localhost通信）
# ============================================

Write-Host ""
Write-Host "[3/6] ファイアウォール（localhost通信）をチェック..." -ForegroundColor Yellow

try {
    # localhost への接続テスト（ポート445: SMB）
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $asyncResult = $tcpClient.BeginConnect("127.0.0.1", 445, $null, $null)
    $wait = $asyncResult.AsyncWaitHandle.WaitOne(1000)

    if ($wait) {
        $tcpClient.EndConnect($asyncResult)
        $tcpClient.Close()
        Write-Host "      [OK] localhost通信は許可されています" -ForegroundColor Green
    } else {
        $tcpClient.Close()
        Write-Host "      [情報] localhostポート445に接続できませんでした（正常な場合もあります）" -ForegroundColor Gray
    }
} catch {
    Write-Host "      [情報] ファイアウォールチェックをスキップ（エラー: $($_.Exception.Message)）" -ForegroundColor Gray
}

# ============================================
# 4. PowerShell.exeの実行可否
# ============================================

Write-Host ""
Write-Host "[4/6] PowerShell.exeの実行可否をチェック..." -ForegroundColor Yellow

try {
    $testScript = "Write-Output 'OK'"
    $testResult = powershell -ExecutionPolicy Bypass -Command $testScript 2>&1

    if ($testResult -eq "OK") {
        Write-Host "      [OK] PowerShell.exeは実行可能です" -ForegroundColor Green
    } else {
        Write-Host "      [警告] PowerShell.exeの実行結果が不正です: $testResult" -ForegroundColor Yellow
        $warnings += "PowerShell実行結果異常"
    }
} catch {
    Write-Host "      [エラー] PowerShell.exeが実行できません: $($_.Exception.Message)" -ForegroundColor Red
    $issues += "PowerShell実行不可"
}

# ============================================
# 5. Podeモジュールの読み込み確認
# ============================================

Write-Host ""
Write-Host "[5/6] Podeモジュールの読み込みをテスト..." -ForegroundColor Yellow

# ローカルのPodeモジュールをチェック（バージョン付きフォルダ構造に対応）
$localPodePath = Join-Path $PSScriptRoot "Modules\Pode"
$localPodeVersionPath = Get-ChildItem -Path "$localPodePath\*\Pode.psm1" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($localPodeVersionPath) {
    Write-Host "      [OK] ローカルPodeモジュールが見つかりました: $($localPodeVersionPath.Directory.FullName)" -ForegroundColor Green

    # モジュール読み込みテスト
    try {
        $env:PSModulePath = "$($localPodeVersionPath.Directory.Parent.FullName);$env:PSModulePath"
        Import-Module Pode -ErrorAction Stop
        $podeVersion = (Get-Module Pode).Version
        Write-Host "      [OK] Podeモジュールを読み込めました (Version: $podeVersion)" -ForegroundColor Green
        Remove-Module Pode -Force
    } catch {
        Write-Host "      [警告] Podeモジュールの読み込みに失敗しました: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "      初回起動時に自動インストールを試みます" -ForegroundColor Gray
        $warnings += "Podeモジュール読み込み失敗（自動インストールで対応）"
    }
} else {
    # システムにインストールされているかチェック
    $podeModule = Get-Module -ListAvailable -Name Pode -ErrorAction SilentlyContinue
    if ($podeModule) {
        Write-Host "      [OK] Podeモジュールがインストールされています (Version: $($podeModule.Version))" -ForegroundColor Green
    } else {
        Write-Host "      [情報] Podeモジュールが見つかりません（初回起動時に自動インストールされます）" -ForegroundColor Gray
    }
}

# ============================================
# 6. 管理者権限の確認
# ============================================

Write-Host ""
Write-Host "[6/6] 管理者権限をチェック..." -ForegroundColor Yellow

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host "      [情報] 管理者権限で実行されています" -ForegroundColor Cyan
    Write-Host "      UIpowershellは通常ユーザー権限で動作します（管理者権限不要）" -ForegroundColor Gray
} else {
    Write-Host "      [OK] 通常ユーザー権限で実行されています（推奨）" -ForegroundColor Green
}

# ============================================
# 結果サマリー
# ============================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "チェック結果サマリー" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 致命的な問題
if ($issues.Count -gt 0) {
    Write-Host "❌ 致命的な問題が検出されました：" -ForegroundColor Red
    Write-Host ""
    foreach ($issue in $issues) {
        Write-Host "  • $issue" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "対処法：" -ForegroundColor Yellow
    Write-Host "  1. IT部門に相談して制限を緩和してもらう" -ForegroundColor White
    Write-Host "  2. '組織PC制限事項.md' を参照して詳細を確認" -ForegroundColor White
    Write-Host "  3. IT部門への申請テンプレートを使用" -ForegroundColor White
    Write-Host ""
}

# 警告
if ($warnings.Count -gt 0) {
    Write-Host "⚠️  警告が検出されました：" -ForegroundColor Yellow
    Write-Host ""
    foreach ($warning in $warnings) {
        Write-Host "  • $warning" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "これらの警告は動作に影響しない場合があります。" -ForegroundColor Gray
    Write-Host "実際に実行して動作を確認してください。" -ForegroundColor Gray
    Write-Host ""
}

# 成功
if ($issues.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "✓ すべてのチェックに合格しました！" -ForegroundColor Green
    Write-Host ""
    Write-Host "このPCでUIpowershellは正常に動作する可能性が高いです。" -ForegroundColor Green
    Write-Host ""
    Write-Host "次のステップ：" -ForegroundColor Cyan
    Write-Host "  1. 実行_prototype.bat をダブルクリック" -ForegroundColor White
    Write-Host "  2. ブラウザで http://localhost:8080 にアクセス" -ForegroundColor White
    Write-Host "  3. 「API接続テスト」ボタンをクリック" -ForegroundColor White
    Write-Host ""
}

# 推奨アクション
if ($issues.Count -gt 0) {
    Write-Host "推奨アクション：" -ForegroundColor Cyan
    Write-Host ""

    if ($issues -contains "PowerShell実行ポリシー（Restricted）" -or
        $issues -contains "PowerShell実行ポリシー（AllSigned）") {
        Write-Host "【PowerShell実行ポリシー問題】" -ForegroundColor Yellow
        Write-Host "  IT部門に以下を申請してください：" -ForegroundColor White
        Write-Host "  - PowerShell実行ポリシーを 'RemoteSigned' に変更" -ForegroundColor White
        Write-Host "  - または UIpowershell ディレクトリを例外として許可" -ForegroundColor White
        Write-Host ""
    }

    if ($issues -contains "ポート8080の使用制限") {
        Write-Host "【ポート制限問題】" -ForegroundColor Yellow
        Write-Host "  以下のいずれかを実施：" -ForegroundColor White
        Write-Host "  1. IT部門にポート8080の使用許可を申請" -ForegroundColor White
        Write-Host "  2. 別のポートを使用（例：.\adapter\api-server.ps1 -Port 9000）" -ForegroundColor White
        Write-Host ""
    }

    if ($issues -contains "PowerShell実行不可") {
        Write-Host "【PowerShell実行不可】" -ForegroundColor Yellow
        Write-Host "  このPCではPowerShell実行が完全にブロックされています。" -ForegroundColor White
        Write-Host "  IT部門にアプリケーションホワイトリストへの追加を申請してください。" -ForegroundColor White
        Write-Host ""
    }
}

Write-Host "詳細情報：" -ForegroundColor Cyan
Write-Host "  • 組織PC制限事項.md - 詳細な説明と対処法" -ForegroundColor White
Write-Host "  • PROTOTYPE_README.md - 使い方ガイド" -ForegroundColor White
Write-Host "  • 配布手順.md - 配布方法" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "チェック完了" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
