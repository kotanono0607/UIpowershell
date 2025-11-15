# ============================================
# Polaris HTTPサーバー - API Adapter Layer V2
# ============================================
# 役割：ブラウザ（HTML/JS） ↔ 既存PowerShell関数（v2版）を橋渡し
# アーキテクチャ：Browser fetch() → Polaris → v2関数 → JSON
# Phase 3対応：すべてのv2関数のエンドポイントを追加
# ============================================

param(
    [int]$Port = 8080,
    [switch]$AutoOpenBrowser
)

# スクリプトのルートディレクトリ
$script:RootDir = Split-Path -Parent $PSScriptRoot

# ============================================
# ログファイル設定
# ============================================

# ログディレクトリの作成
$logDir = Join-Path $script:RootDir "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# 古いログファイルを削除（起動のたびにクリーンアップ）
Write-Host "[ログ] 古いログファイルをクリーンアップします..." -ForegroundColor Cyan
$deletedCount = 0

# サーバーログファイル（api-server-v2_*.log）を全て削除
$serverLogs = Get-ChildItem -Path $logDir -Filter "api-server-v2_*.log" -ErrorAction SilentlyContinue
foreach ($file in $serverLogs) {
    try {
        Remove-Item -Path $file.FullName -Force
        Write-Host "  [削除] $($file.Name)" -ForegroundColor Gray
        $deletedCount++
    } catch {
        Write-Host "  [警告] 削除失敗: $($file.Name)" -ForegroundColor Yellow
    }
}

# ブラウザコンソールログファイル（browser-console_*.log）を全て削除
$browserLogs = Get-ChildItem -Path $logDir -Filter "browser-console_*.log" -ErrorAction SilentlyContinue
foreach ($file in $browserLogs) {
    try {
        Remove-Item -Path $file.FullName -Force
        Write-Host "  [削除] $($file.Name)" -ForegroundColor Gray
        $deletedCount++
    } catch {
        Write-Host "  [警告] 削除失敗: $($file.Name)" -ForegroundColor Yellow
    }
}

if ($deletedCount -gt 0) {
    Write-Host "[ログ] $deletedCount 個のログファイルを削除しました" -ForegroundColor Green
} else {
    Write-Host "[ログ] 削除するログファイルはありませんでした" -ForegroundColor Gray
}
Write-Host ""

# ログファイル名（日付時刻付き）
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $logDir "api-server-v2_$timestamp.log"

# トランスクリプト開始
Start-Transcript -Path $logFile -Append -Force
Write-Host "[ログ] ログファイル: $logFile" -ForegroundColor Green
Write-Host ""

# ============================================
# 1. モジュール読み込み
# ============================================

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "UIpowershell - Polaris API Server V2" -ForegroundColor Cyan
Write-Host "Version: 1.0.179 (UTF-8エンコーディング修正版)" -ForegroundColor Yellow
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Polarisモジュールの読み込み
$polarisModulePath = Join-Path $script:RootDir "Modules\Polaris"
if (Test-Path $polarisModulePath) {
    Write-Host "[OK] Polarisモジュールを読み込みます: $polarisModulePath" -ForegroundColor Green
    $env:PSModulePath = "$polarisModulePath;$env:PSModulePath"
} else {
    Write-Host "[警告] Polarisモジュールが見つかりません: $polarisModulePath" -ForegroundColor Yellow
    Write-Host "       PowerShell Galleryからのインストールを試みます..." -ForegroundColor Yellow
}

try {
    Import-Module Polaris -ErrorAction Stop
    Write-Host "[OK] Polarisモジュールを読み込みました (Version: $(Get-Module Polaris).Version)" -ForegroundColor Green
} catch {
    Write-Host "[エラー] Polarisモジュールの読み込みに失敗しました" -ForegroundColor Red
    Write-Host "       詳細: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "自動インストールを開始します..." -ForegroundColor Yellow
    Write-Host ""

    try {
        Write-Host "Install-Module -Name Polaris -Scope CurrentUser -Force を実行中..." -ForegroundColor Cyan
        Install-Module -Name Polaris -Scope CurrentUser -Force -AllowClobber

        Import-Module Polaris -ErrorAction Stop
        Write-Host "[OK] Polarisのインストールと読み込みに成功しました！" -ForegroundColor Green

        # プロジェクトにコピー（次回起動時用）
        Write-Host ""
        Write-Host "次回起動を高速化するため、プロジェクトにコピーします..." -ForegroundColor Cyan
        $installedPolarisPath = (Get-Module Polaris -ListAvailable | Select-Object -First 1).ModuleBase

        if (Test-Path $installedPolarisPath) {
            $targetPath = Join-Path $script:RootDir "Modules"
            if (-not (Test-Path $targetPath)) {
                New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
            }

            Copy-Item -Path $installedPolarisPath -Destination (Join-Path $targetPath "Polaris") -Recurse -Force
            Write-Host "[OK] Polarisをプロジェクトにコピーしました: $targetPath\Polaris" -ForegroundColor Green
            Write-Host "     次回起動時は自動的にこのコピーが使用されます" -ForegroundColor Gray
        }

    } catch {
        Write-Host ""
        Write-Host "[致命的エラー] Polarisの自動インストールに失敗しました" -ForegroundColor Red
        Write-Host "詳細: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "手動でインストールしてください:" -ForegroundColor Yellow
        Write-Host "  1. PowerShellを管理者権限で開く" -ForegroundColor Yellow
        Write-Host "  2. Install-Module -Name Polaris -Scope CurrentUser -Force" -ForegroundColor Yellow
        Write-Host "  3. このスクリプトを再実行" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "詳細は Modules/Polaris/README_INSTALL.md を参照" -ForegroundColor Yellow
        pause
        exit 1
    }
}

# 既存のPowerShell関数を読み込み
Write-Host ""
Write-Host "既存のPowerShell関数を読み込みます..." -ForegroundColor Cyan

# JSON操作ユーティリティ
. "$script:RootDir\00_共通ユーティリティ_JSON操作.ps1"
Write-Host "[OK] JSON操作ユーティリティ" -ForegroundColor Green

# コードID管理
. "$script:RootDir\09_変数機能_コードID管理JSON.ps1"
Write-Host "[OK] コードID管理JSON" -ForegroundColor Green

# Phase 2 v2ファイルを読み込み
Write-Host ""
Write-Host "Phase 2 v2ファイルを読み込みます..." -ForegroundColor Cyan

. "$script:RootDir\12_コードメイン_コード本文_v2.ps1"
Write-Host "[OK] コードメイン_コード本文_v2" -ForegroundColor Green

. "$script:RootDir\10_変数機能_変数管理UI_v2.ps1"
Write-Host "[OK] 変数機能_変数管理UI_v2" -ForegroundColor Green

. "$script:RootDir\07_メインF機能_ツールバー作成_v2.ps1"
Write-Host "[OK] メインF機能_ツールバー作成_v2" -ForegroundColor Green

. "$script:RootDir\08_メインF機能_メインボタン処理_v2.ps1"
Write-Host "[OK] メインF機能_メインボタン処理_v2" -ForegroundColor Green

. "$script:RootDir\02-6_削除処理_v2.ps1"
Write-Host "[OK] 削除処理_v2" -ForegroundColor Green

. "$script:RootDir\02-2_ネスト規制バリデーション_v2.ps1"
Write-Host "[OK] ネスト規制バリデーション_v2" -ForegroundColor Green

# Phase 3 Adapterファイルを読み込み
Write-Host ""
Write-Host "Phase 3 Adapterファイルを読み込みます..." -ForegroundColor Cyan

. "$PSScriptRoot\state-manager.ps1"
Write-Host "[OK] state-manager" -ForegroundColor Green

. "$PSScriptRoot\node-operations.ps1"
Write-Host "[OK] node-operations" -ForegroundColor Green

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# 2. Polaris HTTPサーバー設定
# ============================================

# 既存のPolarisインスタンスをクリーンアップ
try {
    Stop-Polaris -ErrorAction SilentlyContinue
} catch {}

# 静的ファイル配信（HTML/CSS/JS）
$global:uiPath = Join-Path $script:RootDir "ui"

# ============================================
# CORS対応（クロスオリジンリクエスト許可）
# ============================================

# すべてのOPTIONSリクエストに対応（プリフライトリクエスト）
New-PolarisRoute -Path "*" -Method OPTIONS -ScriptBlock {
    Set-CorsHeaders -Response $Response
    $Response.SetHeader('Access-Control-Allow-Origin', '*')
    $Response.SetHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
    $Response.SetHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization')
    $Response.SetHeader('Access-Control-Max-Age', '86400')
    $Response.SetStatusCode(204)
    $Response.Send('')
}

# ヘルパー関数：CORSヘッダーを設定
function Set-CorsHeaders {
    param($Response)
    $Response.SetHeader('Access-Control-Allow-Origin', '*')
    $Response.SetHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
    $Response.SetHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization')
}

# ============================================
# 3. REST APIエンドポイント定義
# ============================================

# --------------------------------------------
# 基本エンドポイント
# --------------------------------------------

# ヘルスチェック
New-PolarisRoute -Path "/api/health" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    $result = @{
        status = "ok"
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        version = "2.0.0-phase3"
        phase = "Phase 3 - Adapter Layer Complete"
    }
    $json = $result | ConvertTo-Json -Compress
    $Response.SetContentType('application/json; charset=utf-8')
    $Response.Send($json)
}

# セッション情報取得
New-PolarisRoute -Path "/api/session" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    $result = Get-SessionInfo
    $json = $result | ConvertTo-Json -Compress
    $Response.SetContentType('application/json; charset=utf-8')
    $Response.Send($json)
}

# デバッグ情報取得
New-PolarisRoute -Path "/api/debug" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    $result = Get-StateDebugInfo
    $json = $result | ConvertTo-Json -Compress
    $Response.SetContentType('application/json; charset=utf-8')
    $Response.Send($json)
}

# --------------------------------------------
# ノード管理API（state-manager）
# --------------------------------------------

# 全ノード取得
New-PolarisRoute -Path "/api/nodes" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    $result = Get-AllNodes
    $json = $result | ConvertTo-Json -Compress
    $Response.SetContentType('application/json; charset=utf-8')
    $Response.Send($json)
}

# ノード配列を一括設定（React Flowから同期）
New-PolarisRoute -Path "/api/nodes" -Method PUT -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $body = $Request.Body | ConvertFrom-Json
        $result = Set-AllNodes -Nodes $body.nodes
        $json = $result | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# ノード追加
New-PolarisRoute -Path "/api/nodes" -Method POST -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $body = $Request.Body | ConvertFrom-Json
        $result = Add-Node -Node $body
        $json = $result | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# すべてのノードを削除（具体的なルートを先に定義）
New-PolarisRoute -Path "/api/nodes/all" -Method DELETE -ScriptBlock {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host "[API] 🔥 DELETE /api/nodes/all エンドポイントが呼ばれました！" -ForegroundColor Magenta
    Write-Host "[API] 🔍 Request.Method: $($Request.Method)" -ForegroundColor Cyan
    Write-Host "[API] 🔍 Request.Path: $($Request.Path)" -ForegroundColor Cyan

    Set-CorsHeaders -Response $Response
    try {
        Write-Host "[API] 全ノード削除リクエスト受信" -ForegroundColor Cyan

        # Request.Body は null の可能性があるため、Request.BodyString を使用
        $bodyRaw = $null
        if ($null -eq $Request.Body) {
            Write-Host "[API] Request.Body が null です。Request.BodyString を確認..." -ForegroundColor Yellow
            if ($Request.PSObject.Properties['BodyString']) {
                $bodyRaw = $Request.BodyString
                Write-Host "[API] ✅ Request.BodyString を取得しました" -ForegroundColor Green
            } else {
                throw "Request.Body と Request.BodyString の両方が null です"
            }
        } else {
            $bodyRaw = $Request.Body
            Write-Host "[API] ✅ Request.Body を取得しました" -ForegroundColor Green
        }

        Write-Host "[API] リクエストボディ長: $($bodyRaw.Length) 文字" -ForegroundColor Gray

        $body = $bodyRaw | ConvertFrom-Json
        Write-Host "[API] JSON解析成功" -ForegroundColor Green
        Write-Host "[API] body のプロパティ: $($body.PSObject.Properties.Name -join ', ')" -ForegroundColor Gray

        # $body.nodesのnullチェック
        $nodes = $body.nodes
        if ($null -eq $nodes) {
            Write-Host "[API] ⚠️ body.nodesがnullです。空配列として処理します" -ForegroundColor Yellow
            $nodes = @()
        } else {
            Write-Host "[API] body.nodesの型: $($nodes.GetType().FullName)" -ForegroundColor Gray
        }

        Write-Host "[API] 削除対象ノード数: $($nodes.Count)" -ForegroundColor Yellow

        # 最初の数個のノードIDを表示
        if ($nodes.Count -gt 0) {
            $sampleIds = $nodes | Select-Object -First 3 | ForEach-Object { $_.id }
            Write-Host "[API] サンプルノードID: $($sampleIds -join ', ')" -ForegroundColor Gray
        }

        # ノード配列が空でも関数を呼び出す（関数内で空チェックあり）
        $result = すべてのノードを削除_v2 -ノード配列 $nodes

        Write-Host "[API] ✅ 全ノード削除完了: $($result.deleteCount)個" -ForegroundColor Green

        $json = $result | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    } catch {
        Write-Host "[API] ❌ エラー発生: $($_.Exception.Message)" -ForegroundColor Red
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# ノード削除（単一・セット両対応）
New-PolarisRoute -Path "/api/nodes/:id" -Method DELETE -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $nodeId = $Request.Parameters.id
        $body = $Request.Body | ConvertFrom-Json

        # ノード配列を受け取る
        $nodes = $body.nodes

        # v2関数で削除対象を特定
        $result = ノード削除_v2 -ノード配列 $nodes -TargetNodeId $nodeId

        $json = $result | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# --------------------------------------------
# 変数管理API（10_変数機能_変数管理UI_v2.ps1）
# --------------------------------------------

# 変数一覧取得
New-PolarisRoute -Path "/api/variables" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    $result = Get-VariableList_v2
    $json = $result | ConvertTo-Json -Compress
    $Response.SetContentType('application/json; charset=utf-8')
    $Response.Send($json)
}

# 変数取得（名前指定）
New-PolarisRoute -Path "/api/variables/:name" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $varName = $Request.Parameters.name
        $result = Get-Variable_v2 -Name $varName
        $json = $result | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# 変数追加
New-PolarisRoute -Path "/api/variables" -Method POST -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $body = $Request.Body | ConvertFrom-Json
        $result = Add-Variable_v2 -Name $body.name -Value $body.value -Type $body.type
        $json = $result | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# 変数更新
New-PolarisRoute -Path "/api/variables/:name" -Method PUT -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $varName = $Request.Parameters.name
        $body = $Request.Body | ConvertFrom-Json
        $result = Update-Variable_v2 -Name $varName -Value $body.value
        $json = $result | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# 変数削除
New-PolarisRoute -Path "/api/variables/:name" -Method DELETE -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $varName = $Request.Parameters.name
        $result = Remove-Variable_v2 -Name $varName
        $json = $result | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# 変数管理ダイアログ（PowerShell Windows Forms版）
New-PolarisRoute -Path "/api/variables/manage" -Method POST -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        Write-Host "[API] /api/variables/manage - 変数管理ダイアログを表示" -ForegroundColor Cyan

        # 現在の変数一覧を取得
        $変数一覧結果 = Get-VariableList_v2
        if (-not $変数一覧結果.success) {
            $errorResult = @{
                success = $false
                error = "変数一覧の取得に失敗しました: $($変数一覧結果.error)"
            }
            $json = $errorResult | ConvertTo-Json -Compress -Depth 5
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
            return
        }

        Write-Host "[API] 現在の変数数: $($変数一覧結果.variables.Count)" -ForegroundColor Gray

        # 元の変数リストを保存（比較用）
        $元の変数リスト = $変数一覧結果.variables

        # 共通関数ファイルを読み込み
        . (Join-Path $script:RootDir "13_コードサブ汎用関数.ps1")

        # PowerShell Windows Forms ダイアログを表示
        $ダイアログ結果 = 変数管理を表示 -変数リスト $変数一覧結果.variables

        if ($null -eq $ダイアログ結果) {
            Write-Host "[API] 変数管理ダイアログがキャンセルされました" -ForegroundColor Yellow
            $result = @{
                success = $false
                cancelled = $true
                message = "変数管理がキャンセルされました"
            }
            $json = $result | ConvertTo-Json -Compress -Depth 5
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
            return
        }

        Write-Host "[API] ダイアログ完了 - 変数リストを比較して変更を適用します" -ForegroundColor Green

        # 変更を検出して適用
        $新しい変数リスト = $ダイアログ結果.variables
        $変更カウント = @{
            追加 = 0
            更新 = 0
            削除 = 0
        }

        # 元のリストから変数名のマップを作成
        $元の変数マップ = @{}
        foreach ($var in $元の変数リスト) {
            $元の変数マップ[$var.name] = $var
        }

        # 新しいリストから変数名のマップを作成
        $新しい変数マップ = @{}
        foreach ($var in $新しい変数リスト) {
            $新しい変数マップ[$var.name] = $var
        }

        # 追加・更新を検出
        foreach ($var in $新しい変数リスト) {
            if ($元の変数マップ.ContainsKey($var.name)) {
                # 既存の変数 - 値が変更されているか確認
                $元の値 = $元の変数マップ[$var.name].value
                $新しい値 = $var.value

                # 値を文字列化して比較
                $元の値文字列 = if ($元の値 -is [array]) { $元の値 -join "," } else { $元の値 }
                $新しい値文字列 = if ($新しい値 -is [array]) { $新しい値 -join "," } else { $新しい値 }

                if ($元の値文字列 -ne $新しい値文字列) {
                    Write-Host "[API] 変数を更新: $($var.name)" -ForegroundColor Cyan
                    $updateResult = Update-Variable_v2 -Name $var.name -Value $var.value
                    if ($updateResult.success) {
                        $変更カウント.更新++
                    }
                }
            } else {
                # 新しい変数
                Write-Host "[API] 変数を追加: $($var.name)" -ForegroundColor Green
                $addResult = Add-Variable_v2 -Name $var.name -Value $var.value -Type $var.type
                if ($addResult.success) {
                    $変更カウント.追加++
                }
            }
        }

        # 削除を検出
        foreach ($var in $元の変数リスト) {
            if (-not $新しい変数マップ.ContainsKey($var.name)) {
                Write-Host "[API] 変数を削除: $($var.name)" -ForegroundColor Yellow
                $removeResult = Remove-Variable_v2 -Name $var.name
                if ($removeResult.success) {
                    $変更カウント.削除++
                }
            }
        }

        Write-Host "[API] 変更完了 - 追加:$($変更カウント.追加), 更新:$($変更カウント.更新), 削除:$($変更カウント.削除)" -ForegroundColor Green

        # 変更を永続化
        $exportResult = Export-VariablesToJson_v2
        if (-not $exportResult.success) {
            Write-Host "[API] ⚠️ 変数のJSON保存に失敗: $($exportResult.error)" -ForegroundColor Yellow
        }

        # 成功レスポンス
        $result = @{
            success = $true
            cancelled = $false
            message = "変数管理が完了しました"
            changes = $変更カウント
        }

        $json = $result | ConvertTo-Json -Compress -Depth 5
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)

    } catch {
        Write-Host "[API] ❌ エラー: $_" -ForegroundColor Red
        Write-Host "[API] スタックトレース: $($_.ScriptStackTrace)" -ForegroundColor Red
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# --------------------------------------------
# メニュー操作API（07_メインF機能_ツールバー作成_v2.ps1）
# --------------------------------------------

# メニュー構造取得
New-PolarisRoute -Path "/api/menu/structure" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    $result = Get-MenuStructure_v2
    $json = $result | ConvertTo-Json -Compress
    $Response.SetContentType('application/json; charset=utf-8')
    $Response.Send($json)
}

# メニューアクション実行
New-PolarisRoute -Path "/api/menu/action/:actionId" -Method POST -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $actionId = $Request.Parameters.actionId
        $body = $Request.Body | ConvertFrom-Json

        $params = if ($body.parameters) { $body.parameters } else { @{} }
        $result = Execute-MenuAction_v2 -ActionId $actionId -Parameters $params

        $json = $result | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# --------------------------------------------
# 実行イベントAPI（08_メインF機能_メインボタン処理_v2.ps1）
# --------------------------------------------

# PowerShellコード生成
New-PolarisRoute -Path "/api/execute/generate" -Method POST -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        # デバッグモード（環境変数で制御）
        $DebugMode = $env:UIPOWERSHELL_DEBUG -eq "1"

        if ($DebugMode) {
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
            Write-Host "[/api/execute/generate] リクエスト受信" -ForegroundColor Cyan
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        }

        # Request.Body は null の可能性があるため、Request.BodyString を使用
        $bodyRaw = $null
        if ($null -eq $Request.Body) {
            if ($Request.PSObject.Properties['BodyString']) {
                $bodyRaw = $Request.BodyString
            } else {
                throw "Request.Body と Request.BodyString の両方が null です"
            }
        } else {
            $bodyRaw = $Request.Body
        }

        $body = $bodyRaw | ConvertFrom-Json

        # ノード配列の検証
        if ($null -eq $body.nodes -or $body.nodes.Count -eq 0) {
            $Response.SetStatusCode(400)
            $errorResult = @{
                success = $false
                error = "ノード配列が空またはNULLです"
            }
            $json = $errorResult | ConvertTo-Json -Compress
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
            return
        }

        # 配列として確実に変換
        $nodeArray = @($body.nodes)

        # OutputPathとOpenFileのデフォルト値設定
        $outputPath = if ($body.outputPath) { $body.outputPath } else { $null }
        $openFile = if ($body.PSObject.Properties.Name -contains 'openFile') { [bool]$body.openFile } else { $false }

        if ($DebugMode) {
            Write-Host "[DEBUG] ノード数: $($nodeArray.Count)" -ForegroundColor Green
        }

        $result = 実行イベント_v2 `
            -ノード配列 $nodeArray `
            -OutputPath $outputPath `
            -OpenFile $openFile

        if ($DebugMode) {
            Write-Host "[DEBUG] 実行イベント_v2 completed - success: $($result.success)" -ForegroundColor Green
            if ($result.code) {
                Write-Host "[DEBUG] コード長: $($result.code.Length) 文字" -ForegroundColor Green
            }
        } else {
            # 通常モード: 簡潔なログのみ
            Write-Host "[実行] ノード数: $($nodeArray.Count), 成功: $($result.success)" -ForegroundColor $(if ($result.success) { "Green" } else { "Red" })
        }

        $json = $result | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)

        if ($DebugMode) {
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
            Write-Host "[/api/execute/generate] ✅ 成功" -ForegroundColor Green
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
        }
    } catch {
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        Write-Host "[/api/execute/generate] ❌ エラー発生" -ForegroundColor Red
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        Write-Host "[ERROR] Exception: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[ERROR] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red

        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
            stackTrace = $_.ScriptStackTrace
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# PowerShellスクリプト実行（単一ノード）
New-PolarisRoute -Path "/api/execute/script" -Method POST -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $body = $Request.Body | ConvertFrom-Json
        $scriptContent = $body.script
        $nodeName = $body.nodeName

        if ([string]::IsNullOrWhiteSpace($scriptContent)) {
            $Response.SetStatusCode(400)
            $errorResult = @{
                success = $false
                error = "スクリプトが空です"
            }
            $json = $errorResult | ConvertTo-Json -Compress
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
            return
        }

        # 汎用関数を読み込み（13_コードサブ汎用関数.ps1）
        $汎用関数パス = Join-Path $global:RootDirForPolaris "13_コードサブ汎用関数.ps1"
        if (Test-Path $汎用関数パス) {
            . $汎用関数パス
        }

        # スクリプトを実行して出力を取得
        $output = Invoke-Expression $scriptContent 2>&1 | Out-String

        $result = @{
            success = $true
            output = $output
            nodeName = $nodeName
        }
        $json = $result | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# --------------------------------------------
# フォルダ管理API（08_メインF機能_メインボタン処理_v2.ps1）
# --------------------------------------------

# フォルダ一覧取得
New-PolarisRoute -Path "/api/folders" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    $result = フォルダ切替イベント_v2 -FolderName "list"
    $json = $result | ConvertTo-Json -Compress
    $Response.SetContentType('application/json; charset=utf-8')
    $Response.Send($json)
}

# フォルダ作成
New-PolarisRoute -Path "/api/folders" -Method POST -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $body = $Request.Body | ConvertFrom-Json
        $result = フォルダ作成イベント_v2 -FolderName $body.name
        $json = $result | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# フォルダ切り替え
New-PolarisRoute -Path "/api/folders/:name" -Method PUT -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $folderName = $Request.Parameters.name
        $result = フォルダ切替イベント_v2 -FolderName $folderName
        $json = $result | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# フォルダ切替ダイアログ（PowerShell Windows Forms版）
New-PolarisRoute -Path "/api/folders/switch-dialog" -Method POST -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        Write-Host "[API] /api/folders/switch-dialog - フォルダ切替ダイアログを表示" -ForegroundColor Cyan

        # 現在のフォルダ一覧を取得
        $フォルダ一覧結果 = フォルダ切替イベント_v2 -FolderName "list"
        if (-not $フォルダ一覧結果.success) {
            $errorResult = @{
                success = $false
                error = "フォルダ一覧の取得に失敗しました: $($フォルダ一覧結果.error)"
            }
            $json = $errorResult | ConvertTo-Json -Compress -Depth 5
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
            return
        }

        $フォルダリスト = $フォルダ一覧結果.folders

        # 現在のフォルダを取得
        $rootDir = $global:RootDirForPolaris
        $mainJsonPath = Join-Path $rootDir "03_history\メイン.json"
        $現在のフォルダ = ""

        if (Test-Path $mainJsonPath) {
            try {
                $content = Get-Content $mainJsonPath -Raw -Encoding UTF8
                $mainData = $content | ConvertFrom-Json
                $folderPath = $mainData.フォルダパス
                $現在のフォルダ = Split-Path -Leaf $folderPath
                Write-Host "[API] 現在のフォルダ: $現在のフォルダ" -ForegroundColor Gray
            } catch {
                Write-Host "[API] ⚠️ メイン.jsonの読み込みに失敗しました: $_" -ForegroundColor Yellow
            }
        }

        Write-Host "[API] フォルダ数: $($フォルダリスト.Count)" -ForegroundColor Gray

        # 共通関数ファイルを読み込み
        . (Join-Path $script:RootDir "13_コードサブ汎用関数.ps1")

        # PowerShell Windows Forms ダイアログを表示
        $ダイアログ結果 = フォルダ切替を表示 -フォルダリスト $フォルダリスト -現在のフォルダ $現在のフォルダ

        if ($null -eq $ダイアログ結果) {
            Write-Host "[API] フォルダ切替ダイアログがキャンセルされました" -ForegroundColor Yellow
            $result = @{
                success = $false
                cancelled = $true
                message = "フォルダ切替がキャンセルされました"
            }
            $json = $result | ConvertTo-Json -Compress -Depth 5
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
            return
        }

        Write-Host "[API] ダイアログ完了 - 選択されたフォルダ: $($ダイアログ結果.folderName)" -ForegroundColor Green

        # 新しいフォルダが作成された場合はAPI経由で作成
        if ($ダイアログ結果.newFolder) {
            Write-Host "[API] 新しいフォルダを作成: $($ダイアログ結果.newFolder)" -ForegroundColor Cyan
            $作成結果 = フォルダ作成イベント_v2 -FolderName $ダイアログ結果.newFolder
            if (-not $作成結果.success) {
                Write-Host "[API] ⚠️ フォルダ作成に失敗: $($作成結果.error)" -ForegroundColor Yellow
            }
        }

        # 選択されたフォルダが現在のフォルダと異なる場合は切り替え
        if ($ダイアログ結果.folderName -ne $現在のフォルダ) {
            Write-Host "[API] フォルダを切り替え: $($ダイアログ結果.folderName)" -ForegroundColor Cyan
            $切替結果 = フォルダ切替イベント_v2 -FolderName $ダイアログ結果.folderName

            if ($切替結果.success) {
                Write-Host "[API] ✅ フォルダ切り替え成功" -ForegroundColor Green
            } else {
                Write-Host "[API] ❌ フォルダ切り替え失敗: $($切替結果.error)" -ForegroundColor Red
            }

            # 成功レスポンス
            $result = @{
                success = $切替結果.success
                cancelled = $false
                message = "フォルダ「$($ダイアログ結果.folderName)」に切り替えました"
                folderName = $ダイアログ結果.folderName
                switched = $true
                error = $切替結果.error
            }
        } else {
            # 同じフォルダが選択された場合
            Write-Host "[API] 同じフォルダが選択されました（切り替えなし）" -ForegroundColor Gray
            $result = @{
                success = $true
                cancelled = $false
                message = "フォルダ選択完了（変更なし）"
                folderName = $ダイアログ結果.folderName
                switched = $false
            }
        }

        $json = $result | ConvertTo-Json -Compress -Depth 5
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)

    } catch {
        Write-Host "[API] ❌ エラー: $_" -ForegroundColor Red
        Write-Host "[API] スタックトレース: $($_.ScriptStackTrace)" -ForegroundColor Red
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# メイン.json読み込み（現在のフォルダパス取得）
New-PolarisRoute -Path "/api/main-json" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $rootDir = $global:RootDirForPolaris
        $mainJsonPath = Join-Path $rootDir "03_history\メイン.json"

        if (Test-Path $mainJsonPath) {
            $content = Get-Content $mainJsonPath -Raw -Encoding UTF8
            $mainData = $content | ConvertFrom-Json

            # フォルダパスからフォルダ名を抽出
            $folderPath = $mainData.フォルダパス
            $folderName = Split-Path -Leaf $folderPath

            $result = @{
                success = $true
                folderPath = $folderPath
                folderName = $folderName
            }
            $json = $result | ConvertTo-Json -Compress
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
        } else {
            $result = @{
                success = $false
                error = "メイン.jsonが存在しません"
            }
            $json = $result | ConvertTo-Json -Compress
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
        }
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# memory.json読み込み（フォルダごと）
New-PolarisRoute -Path "/api/folders/:name/memory" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $folderName = $Request.Parameters.name
        $rootDir = $global:RootDirForPolaris
        $memoryPath = Join-Path $rootDir "03_history\$folderName\memory.json"

        if (Test-Path $memoryPath) {
            $content = Get-Content $memoryPath -Raw -Encoding UTF8
            $memoryData = $content | ConvertFrom-Json

            $result = @{
                success = $true
                data = $memoryData
                folderName = $folderName
            }
            $json = $result | ConvertTo-Json -Depth 10
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
        } else {
            # memory.jsonが存在しない場合は空のレイヤー構造を返す
            $emptyMemory = @{
                "1" = @{ "構成" = @() }
                "2" = @{ "構成" = @() }
                "3" = @{ "構成" = @() }
                "4" = @{ "構成" = @() }
                "5" = @{ "構成" = @() }
                "6" = @{ "構成" = @() }
            }
            $result = @{
                success = $true
                data = $emptyMemory
                folderName = $folderName
                message = "memory.jsonが存在しないため、空のデータを返しました"
            }
            $json = $result | ConvertTo-Json -Depth 10
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
        }
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# memory.json保存（フォルダごと）
New-PolarisRoute -Path "/api/folders/:name/memory" -Method POST -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $folderName = $Request.Parameters.name
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host "[API] memory.json保存リクエスト受信" -ForegroundColor Cyan
        Write-Host "[API] フォルダ名: $folderName" -ForegroundColor Yellow

        # Request.Body は null の可能性があるため、Request.BodyString を使用
        $bodyRaw = $null
        if ($null -eq $Request.Body) {
            Write-Host "[API] Request.Body が null です。Request.BodyString を確認..." -ForegroundColor Yellow
            if ($Request.PSObject.Properties['BodyString']) {
                $bodyRaw = $Request.BodyString
                Write-Host "[API] ✅ Request.BodyString を取得しました" -ForegroundColor Green
            } else {
                throw "Request.Body と Request.BodyString の両方が null です"
            }
        } else {
            $bodyRaw = $Request.Body
            Write-Host "[API] ✅ Request.Body を取得しました" -ForegroundColor Green
        }

        Write-Host "[API] リクエストボディ長: $($bodyRaw.Length) 文字" -ForegroundColor Gray

        $body = $bodyRaw | ConvertFrom-Json
        Write-Host "[API] JSON解析成功" -ForegroundColor Green

        $layerStructure = $body.layerStructure
        Write-Host "[API] layerStructure取得: $($layerStructure.PSObject.Properties.Name.Count) レイヤー" -ForegroundColor Gray

        $rootDir = $global:RootDirForPolaris
        $folderPath = Join-Path $rootDir "03_history\$folderName"
        $memoryPath = Join-Path $folderPath "memory.json"

        Write-Host "[API] 保存先パス: $memoryPath" -ForegroundColor Gray

        # フォルダが存在しない場合は作成
        if (-not (Test-Path $folderPath)) {
            Write-Host "[API] フォルダを作成します: $folderPath" -ForegroundColor Yellow
            New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
        } else {
            Write-Host "[API] フォルダは既に存在します" -ForegroundColor Gray
        }

        # memory.json形式に変換
        # [ordered]を使用してレイヤーの順序を保持（1, 2, 3, 4, 5, 6の順）
        $memoryData = [ordered]@{}
        $totalNodes = 0

        for ($i = 1; $i -le 6; $i++) {
            $layerNodes = $layerStructure."$i".nodes
            $構成 = @()

            foreach ($node in $layerNodes) {
                # [ordered] を使用してフィールドの順序を既存のPS1形式に合わせる
                # 既存PS1版: 05_メインフォームUI_矢印処理.ps1 1069-1081行
                $構成 += [ordered]@{
                    ボタン名 = $node.name
                    X座標 = if ($node.x) { $node.x } else { 10 }
                    Y座標 = $node.y
                    順番 = if ($node.順番) { $node.順番 } else { 1 }
                    ボタン色 = $node.color
                    テキスト = $node.text
                    処理番号 = if ($node.処理番号) { $node.処理番号 } else { "未設定" }
                    高さ = if ($node.height) { $node.height } else { 40 }
                    幅 = if ($node.width) { $node.width } else { 280 }
                    script = if ($null -ne $node.script) { $node.script } else { "未設定" }
                    GroupID = if ($node.groupId -ne $null -and $node.groupId -ne "") { $node.groupId } else { "" }
                }
                $totalNodes++
            }

            $memoryData["$i"] = @{ "構成" = $構成 }

            if ($構成.Count -gt 0) {
                Write-Host "[API] レイヤー$i : $($構成.Count)個のノード" -ForegroundColor Gray
            }
        }

        Write-Host "[API] 合計ノード数: $totalNodes" -ForegroundColor Yellow

        # JSON形式で保存
        $json = $memoryData | ConvertTo-Json -Depth 10
        Write-Host "[API] JSON生成完了 (長さ: $($json.Length) 文字)" -ForegroundColor Gray

        # UTF-8 without BOMで保存（文字化け防止）
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($memoryPath, $json, $utf8NoBom)
        Write-Host "[API] UTF-8 (BOMなし) でファイルを保存しました" -ForegroundColor Green

        # ファイル保存確認
        if (Test-Path $memoryPath) {
            $fileInfo = Get-Item $memoryPath
            Write-Host "[API] ✅ ファイル保存成功" -ForegroundColor Green
            Write-Host "[API]    ファイルサイズ: $($fileInfo.Length) バイト" -ForegroundColor Gray
            Write-Host "[API]    最終更新時刻: $($fileInfo.LastWriteTime)" -ForegroundColor Gray
        } else {
            Write-Host "[API] ❌ ファイル保存失敗" -ForegroundColor Red
        }

        $result = @{
            success = $true
            folderName = $folderName
            message = "memory.jsonを保存しました"
            nodeCount = $totalNodes
        }
        $resultJson = $result | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($resultJson)

        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    } catch {
        Write-Host "[API] ❌ エラー発生: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[API] スタックトレース: $($_.ScriptStackTrace)" -ForegroundColor Red

        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# コード.json読み込み（フォルダごと）
New-PolarisRoute -Path "/api/folders/:name/code" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $folderName = $Request.Parameters.name
        $rootDir = $global:RootDirForPolaris
        $codePath = Join-Path $rootDir "03_history\$folderName\コード.json"

        if (Test-Path $codePath) {
            $content = Get-Content $codePath -Raw -Encoding UTF8
            $codeData = $content | ConvertFrom-Json

            $result = @{
                success = $true
                data = $codeData
                folderName = $folderName
            }
            $json = $result | ConvertTo-Json -Depth 10
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
        } else {
            # コード.jsonが存在しない場合は空の構造を返す
            $emptyCode = @{
                "エントリ" = @{}
                "最後のID" = 0
            }
            $result = @{
                success = $true
                data = $emptyCode
                folderName = $folderName
                message = "コード.jsonが存在しないため、空のデータを返しました"
            }
            $json = $result | ConvertTo-Json -Depth 10
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
        }
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# コード.json保存（フォルダごと）
New-PolarisRoute -Path "/api/folders/:name/code" -Method POST -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host "[API] コード.json保存リクエスト受信" -ForegroundColor Cyan

        $folderName = $Request.Parameters.name
        Write-Host "[API] フォルダ名: $folderName" -ForegroundColor Yellow

        # $Request オブジェクトの詳細を確認
        Write-Host "[API] ========== Request オブジェクトのデバッグ ==========" -ForegroundColor Cyan
        Write-Host "[API] Request 型: $($Request.GetType().FullName)" -ForegroundColor Cyan
        Write-Host "[API] Request プロパティ一覧:" -ForegroundColor Cyan
        $Request.PSObject.Properties | ForEach-Object {
            $propName = $_.Name
            $propValue = try { $_.Value } catch { "Error: $($_.Exception.Message)" }
            Write-Host "[API]   - $propName : $propValue" -ForegroundColor Gray
        }
        Write-Host "[API] ====================================================" -ForegroundColor Cyan

        # リクエストボディを取得（ストリームは一度しか読めない可能性があるため、一度だけ読み込む）
        Write-Host "[API] Request.Body のデバッグ開始..." -ForegroundColor Cyan
        $bodyRaw = $Request.Body

        if ($null -eq $bodyRaw) {
            Write-Host "[API] ❌ Request.Body が null です" -ForegroundColor Red

            # Body が null の場合、他のプロパティを確認
            Write-Host "[API] Request.BodyString を確認..." -ForegroundColor Yellow
            if ($Request.PSObject.Properties['BodyString']) {
                $bodyRaw = $Request.BodyString
                Write-Host "[API] ✅ Request.BodyString を取得: $bodyRaw" -ForegroundColor Green
            } else {
                Write-Host "[API] ❌ Request.BodyString も存在しません" -ForegroundColor Red
                throw "Request.Body が null です"
            }
        }

        Write-Host "[API] Request.Body の型: $($bodyRaw.GetType().FullName)" -ForegroundColor Cyan
        $bodyStr = "$bodyRaw"
        Write-Host "[API] Request.Body の文字列表現長さ: $($bodyStr.Length)" -ForegroundColor Cyan

        if ($bodyStr.Length -gt 0) {
            $preview = $bodyStr.Substring(0, [Math]::Min(200, $bodyStr.Length))
            Write-Host "[API] Request.Body の最初の200文字: [$preview]" -ForegroundColor Cyan
        } else {
            Write-Host "[API] ❌ Request.Body の文字列表現が空です" -ForegroundColor Red
            throw "Request.Body が空です"
        }

        # リクエストボディを解析（$bodyRaw を使用、$Request.Body を再度読まない）
        Write-Host "[API] bodyRaw を ConvertFrom-Json します..." -ForegroundColor Yellow
        $body = $bodyRaw | ConvertFrom-Json
        Write-Host "[API] ✅ ConvertFrom-Json完了" -ForegroundColor Green

        if ($null -eq $body) {
            Write-Host "[API] ❌ エラー: bodyがnullです" -ForegroundColor Red
            throw "リクエストボディが空です"
        }

        Write-Host "[API] bodyの内容: $($body | ConvertTo-Json -Compress -Depth 2)" -ForegroundColor Yellow

        $codeData = $body.codeData
        if ($null -eq $codeData) {
            Write-Host "[API] ❌ エラー: codeDataがnullです" -ForegroundColor Red
            throw "codeDataが見つかりません"
        }

        Write-Host "[API] ✅ codeDataを取得しました" -ForegroundColor Green
        Write-Host "[API] codeDataの内容: $($codeData | ConvertTo-Json -Compress -Depth 2)" -ForegroundColor Yellow

        $rootDir = $global:RootDirForPolaris
        $folderPath = Join-Path $rootDir "03_history\$folderName"
        $codePath = Join-Path $folderPath "コード.json"

        Write-Host "[API] 保存先パス: $codePath" -ForegroundColor Yellow
        Write-Host "[API] フォルダパス: $folderPath" -ForegroundColor Yellow

        # フォルダが存在しない場合は作成
        if (-not (Test-Path $folderPath)) {
            Write-Host "[API] フォルダが存在しないため作成します" -ForegroundColor Magenta
            New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
        } else {
            Write-Host "[API] フォルダは既に存在します" -ForegroundColor Green
        }

        # JSON形式で保存
        $json = $codeData | ConvertTo-Json -Depth 10
        Write-Host "[API] JSON生成完了 (長さ: $($json.Length) 文字)" -ForegroundColor Yellow
        Write-Host "[API] JSON内容の最初の200文字: $($json.Substring(0, [Math]::Min(200, $json.Length)))" -ForegroundColor Gray

        # UTF-8 without BOMで保存（文字化け防止）
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($codePath, $json, $utf8NoBom)
        Write-Host "[API] UTF-8 (BOMなし) でファイルを保存しました" -ForegroundColor Green

        # 保存確認
        if (Test-Path $codePath) {
            $fileInfo = Get-Item $codePath
            Write-Host "[API] ✅ ファイル保存成功" -ForegroundColor Green
            Write-Host "[API]    ファイルサイズ: $($fileInfo.Length) バイト" -ForegroundColor Green
            Write-Host "[API]    最終更新時刻: $($fileInfo.LastWriteTime)" -ForegroundColor Green
        } else {
            Write-Host "[API] ❌ ファイル保存後に存在確認失敗" -ForegroundColor Red
        }

        $result = @{
            success = $true
            folderName = $folderName
            message = "コード.jsonを保存しました"
            filePath = $codePath
        }
        $resultJson = $result | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($resultJson)

        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    } catch {
        Write-Host "[API] ❌ エラー発生: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[API] スタックトレース: $($_.Exception.StackTrace)" -ForegroundColor Red

        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# variables.json読み込み（フォルダごと）
New-PolarisRoute -Path "/api/folders/:name/variables" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $folderName = $Request.Parameters.name
        $rootDir = $global:RootDirForPolaris
        $variablesPath = Join-Path $rootDir "03_history\$folderName\variables.json"

        if (Test-Path $variablesPath) {
            $content = Get-Content $variablesPath -Raw -Encoding UTF8
            $variablesData = $content | ConvertFrom-Json

            $result = @{
                success = $true
                data = $variablesData
                folderName = $folderName
            }
            $json = $result | ConvertTo-Json -Depth 10
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
        } else {
            # variables.jsonが存在しない場合は空のオブジェクトを返す
            $emptyVariables = @{}
            $result = @{
                success = $true
                data = $emptyVariables
                folderName = $folderName
                message = "variables.jsonが存在しないため、空のデータを返しました"
            }
            $json = $result | ConvertTo-Json -Depth 10
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
        }
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# --------------------------------------------
# バリデーションAPI（02-2_ネスト規制バリデーション_v2.ps1）
# --------------------------------------------

# ドロップ可否チェック
New-PolarisRoute -Path "/api/validate/drop" -Method POST -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $body = $Request.Body | ConvertFrom-Json

        $result = ドロップ禁止チェック_ネスト規制_v2 `
            -ノード配列 $body.nodes `
            -MovingNodeId $body.movingNodeId `
            -設置希望Y $body.targetY

        $json = $result | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# --------------------------------------------
# コードID管理API（既存）
# --------------------------------------------

# 新しいIDを自動生成
New-PolarisRoute -Path "/api/id/generate" -Method POST -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $newId = IDを自動生成する
        $result = @{
            success = $true
            id = $newId
        }
        $json = $result | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# エントリを追加（指定ID）
New-PolarisRoute -Path "/api/entry/add" -Method POST -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $body = $Request.Body | ConvertFrom-Json

        $result = エントリを追加_指定ID `
            -targetID $body.targetID `
            -TypeName $body.TypeName `
            -displayText $body.displayText `
            -code $body.code `
            -toID $body.toID `
            -order $body.order

        $responseObj = @{
            success = $true
            data = $result
        }
        $json = $responseObj | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# IDでエントリを取得
New-PolarisRoute -Path "/api/entry/:id" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $id = $Request.Parameters.id
        $entry = IDでエントリを取得 -targetID $id

        if ($entry) {
            $result = @{
                success = $true
                data = $entry
            }
            $json = $result | ConvertTo-Json -Compress
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
        } else {
            $Response.SetStatusCode(404)
            $errorResult = @{
                success = $false
                error = "エントリが見つかりません: ID=$id"
            }
            $json = $errorResult | ConvertTo-Json -Compress
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
        }
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# 全エントリを取得（フロー描画用）
New-PolarisRoute -Path "/api/entries/all" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $jsonPath = Join-Path $script:RootDir "00_code\コード.json"

        if (Test-Path $jsonPath) {
            $jsonContent = Get-Content $jsonPath -Encoding UTF8 -Raw | ConvertFrom-Json

            $result = @{
                success = $true
                data = $jsonContent
            }
            $json = $result | ConvertTo-Json -Compress
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
        } else {
            $result = @{
                success = $true
                data = @()
                message = "コード.jsonが存在しません"
            }
            $json = $result | ConvertTo-Json -Compress
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
        }
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# ============================================
# ノード関数実行 - 動的ノード設定機能
# ============================================

# 利用可能なノード関数一覧を取得
New-PolarisRoute -Path "/api/node/functions" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $codeDir = Join-Path $script:RootDir "00_code"

        if (Test-Path $codeDir) {
            # 00_code/*.ps1 ファイルを取得
            $scriptFiles = Get-ChildItem -Path $codeDir -Filter "*.ps1"

            $functions = @()
            foreach ($file in $scriptFiles) {
                $functionName = $file.BaseName -replace '-', '_'
                $functions += @{
                    fileName = $file.Name
                    functionName = $functionName
                    scriptPath = $file.FullName
                }
            }

            $result = @{
                success = $true
                data = $functions
            }
            $json = $result | ConvertTo-Json -Compress -Depth 5
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
        } else {
            $result = @{
                success = $false
                error = "00_code directory not found"
            }
            $json = $result | ConvertTo-Json -Compress
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
        }
    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# ノード関数を実行
New-PolarisRoute -Path "/api/node/execute/:functionName" -Method POST -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        $functionName = $Request.Parameters.functionName
        Write-Host "[ノード関数実行] 関数名: $functionName" -ForegroundColor Cyan

        # 関数名をファイル名に変換（例: "8_1" -> "8-1.ps1"）
        $fileName = $functionName -replace '_', '-'
        $scriptPath = Join-Path $script:RootDir "00_code\$fileName.ps1"

        Write-Host "[ノード関数実行] スクリプトパス: $scriptPath" -ForegroundColor Gray

        if (-not (Test-Path $scriptPath)) {
            $Response.SetStatusCode(404)
            $errorResult = @{
                success = $false
                error = "Script file not found: $fileName.ps1"
            }
            $json = $errorResult | ConvertTo-Json -Compress
            $Response.SetContentType('application/json; charset=utf-8')
            $Response.Send($json)
            return
        }

        # スクリプトを読み込み
        Write-Host "[ノード関数実行] 📂 ファイルを読み込み中..." -ForegroundColor Yellow
        Write-Host "[ノード関数実行] 📄 ファイルパス: $scriptPath" -ForegroundColor Gray
        Write-Host "[ノード関数実行] ⏰ ファイル更新日時: $((Get-Item $scriptPath).LastWriteTime)" -ForegroundColor Gray

        # ファイル内容をプレビュー表示（デバッグ用）
        $fileContent = Get-Content $scriptPath -Raw
        $preview = $fileContent.Substring(0, [Math]::Min(200, $fileContent.Length))
        Write-Host "[ノード関数実行] 📝 ファイルプレビュー (先頭200文字):" -ForegroundColor Gray
        Write-Host $preview -ForegroundColor DarkGray

        # 汎用関数を読み込み（13_コードサブ汎用関数.ps1）
        $汎用関数パス = Join-Path $script:RootDir "13_コードサブ汎用関数.ps1"
        if (Test-Path $汎用関数パス) {
            . $汎用関数パス
            Write-Host "[ノード関数実行] ✅ 汎用関数を読み込みました" -ForegroundColor Green
        }

        . $scriptPath
        Write-Host "[ノード関数実行] ✅ スクリプト読み込み完了" -ForegroundColor Green

        # リクエストボディを取得
        $params = @{}
        if ($Request.Body) {
            $bodyJson = $Request.Body | ConvertFrom-Json
            # プロパティをハッシュテーブルに変換
            $bodyJson.PSObject.Properties | ForEach-Object {
                $params[$_.Name] = $_.Value
            }
            Write-Host "[ノード関数実行] パラメータ: $($params | ConvertTo-Json -Compress)" -ForegroundColor Gray
        }

        # 関数を実行
        Write-Host "[ノード関数実行] 🚀 関数 '$functionName' を実行中..." -ForegroundColor Yellow
        if ($params.Count -gt 0) {
            $code = & $functionName @params
        } else {
            $code = & $functionName
        }

        Write-Host "[ノード関数実行] ✅ 関数実行完了" -ForegroundColor Green

        # $codeが$nullの場合はキャンセルまたはエラー
        if ($null -eq $code) {
            Write-Host "[ノード関数実行] ⚠️ 関数が$nullを返しました（キャンセルまたはエラー）" -ForegroundColor Yellow
            $result = @{
                success = $false
                code = $null
                functionName = $functionName
                error = "関数が$nullを返しました（ユーザーキャンセルまたはエラー）"
            }
        } else {
            Write-Host "[ノード関数実行] 📤 生成されたコード (先頭200文字):" -ForegroundColor Gray
            $codePreview = $code.Substring(0, [Math]::Min(200, $code.Length))
            Write-Host $codePreview -ForegroundColor DarkGray

            $result = @{
                success = $true
                code = $code
                functionName = $functionName
            }
        }

        $json = $result | ConvertTo-Json -Compress -Depth 5
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)

    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
            stackTrace = $_.ScriptStackTrace
        }
        Write-Host "[ノード関数実行エラー] $($_.Exception.Message)" -ForegroundColor Red
        $json = $errorResult | ConvertTo-Json -Compress -Depth 5
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# ============================================
# ノードスクリプト編集API（PowerShell Windows Forms）
# ============================================

# スクリプト編集ダイアログを表示
New-PolarisRoute -Path "/api/node/edit-script" -Method POST -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        Write-Host "[スクリプト編集] リクエスト受信" -ForegroundColor Cyan

        # リクエストボディを取得（Request.Bodyがnullの場合はRequest.BodyStringを使用）
        if ($null -eq $Request.Body) {
            Write-Host "[スクリプト編集] Request.Body が null です。Request.BodyString を確認..." -ForegroundColor Yellow
            $bodyRaw = $Request.BodyString
        } else {
            $bodyRaw = $Request.Body
        }

        Write-Host "[スクリプト編集] bodyRaw の長さ: $($bodyRaw.Length)文字" -ForegroundColor Gray
        $body = $bodyRaw | ConvertFrom-Json
        $nodeId = $body.nodeId
        $nodeName = $body.nodeName
        $currentScript = $body.currentScript

        Write-Host "[スクリプト編集] ノードID: $nodeId, ノード名: $nodeName" -ForegroundColor Gray
        Write-Host "[スクリプト編集] 現在のスクリプト長: $($currentScript.Length)文字" -ForegroundColor Gray
        Write-Host "[スクリプト編集] 現在のスクリプト内容: [$currentScript]" -ForegroundColor Gray

        # 汎用関数を読み込み（複数行テキストを編集）
        $汎用関数パス = Join-Path $script:RootDir "13_コードサブ汎用関数.ps1"
        if (Test-Path $汎用関数パス) {
            . $汎用関数パス
            Write-Host "[スクリプト編集] ✅ 汎用関数を読み込みました" -ForegroundColor Green
        } else {
            throw "汎用関数ファイルが見つかりません: $汎用関数パス"
        }

        # PowerShell Windows Formsダイアログを表示
        Write-Host "[スクリプト編集] 📝 編集ダイアログを表示します..." -ForegroundColor Cyan
        $editedScript = 複数行テキストを編集 -フォームタイトル "スクリプト編集 - $nodeName" -ラベルテキスト "スクリプトを編集してください:" -初期テキスト $currentScript

        if ($null -eq $editedScript) {
            # キャンセルされた
            Write-Host "[スクリプト編集] ⚠️ ユーザーがキャンセルしました" -ForegroundColor Yellow
            $result = @{
                success = $false
                cancelled = $true
                message = "編集がキャンセルされました"
            }
        } else {
            # 編集成功
            Write-Host "[スクリプト編集] ✅ 編集完了（長さ: $($editedScript.Length)文字）" -ForegroundColor Green
            $result = @{
                success = $true
                cancelled = $false
                newScript = $editedScript
            }
        }

        $json = $result | ConvertTo-Json -Compress -Depth 5
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)

    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
            stackTrace = $_.ScriptStackTrace
        }
        Write-Host "[スクリプト編集エラー] $($_.Exception.Message)" -ForegroundColor Red
        $json = $errorResult | ConvertTo-Json -Compress -Depth 5
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# ノード設定ダイアログを表示
New-PolarisRoute -Path "/api/node/settings" -Method POST -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        Write-Host "[ノード設定] リクエスト受信" -ForegroundColor Cyan

        # リクエストボディを取得（Request.Bodyがnullの場合はRequest.BodyStringを使用）
        if ($null -eq $Request.Body) {
            Write-Host "[ノード設定] Request.Body が null です。Request.BodyString を確認..." -ForegroundColor Yellow
            $bodyRaw = $Request.BodyString
        } else {
            $bodyRaw = $Request.Body
        }

        Write-Host "[ノード設定] bodyRaw の長さ: $($bodyRaw.Length)文字" -ForegroundColor Gray
        $body = $bodyRaw | ConvertFrom-Json

        # ノード情報をハッシュテーブルに変換
        $ノード情報 = @{
            id = $body.nodeId
            text = $body.nodeName
            color = $body.color
            width = $body.width
            height = $body.height
            x = $body.x
            y = $body.y
            script = $body.script
            処理番号 = $body.処理番号
        }

        # カスタムフィールド
        if ($body.conditionExpression) {
            $ノード情報.conditionExpression = $body.conditionExpression
        }
        if ($body.loopCount) {
            $ノード情報.loopCount = $body.loopCount
        }
        if ($body.loopVariable) {
            $ノード情報.loopVariable = $body.loopVariable
        }

        Write-Host "[ノード設定] ノードID: $($ノード情報.id), 処理番号: $($ノード情報.処理番号)" -ForegroundColor Gray

        # 汎用関数を読み込み（ノード設定を編集）
        $汎用関数パス = Join-Path $script:RootDir "13_コードサブ汎用関数.ps1"
        if (Test-Path $汎用関数パス) {
            . $汎用関数パス
            Write-Host "[ノード設定] ✅ 汎用関数を読み込みました" -ForegroundColor Green
        } else {
            throw "汎用関数ファイルが見つかりません: $汎用関数パス"
        }

        # PowerShell Windows Formsダイアログを表示
        Write-Host "[ノード設定] 📝 設定ダイアログを表示します..." -ForegroundColor Cyan
        $編集結果 = ノード設定を編集 -ノード情報 $ノード情報

        if ($null -eq $編集結果) {
            # キャンセルされた
            Write-Host "[ノード設定] ⚠️ ユーザーがキャンセルしました" -ForegroundColor Yellow
            $result = @{
                success = $false
                cancelled = $true
                message = "設定がキャンセルされました"
            }
        } else {
            # 編集成功
            Write-Host "[ノード設定] ✅ 編集完了" -ForegroundColor Green
            $result = @{
                success = $true
                cancelled = $false
                settings = $編集結果
            }
        }

        $json = $result | ConvertTo-Json -Compress -Depth 5
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)

    } catch {
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
            stackTrace = $_.ScriptStackTrace
        }
        Write-Host "[ノード設定エラー] $($_.Exception.Message)" -ForegroundColor Red
        $json = $errorResult | ConvertTo-Json -Compress -Depth 5
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# ============================================
# ブラウザコンソールログ受信API
# ============================================

# ブラウザコンソールログを受信してファイルに保存
New-PolarisRoute -Path "/api/browser-logs" -Method POST -ScriptBlock {
    Set-CorsHeaders -Response $Response
    try {
        # リクエストボディを取得
        $bodyRaw = $null
        if ($null -eq $Request.Body) {
            if ($Request.PSObject.Properties['BodyString']) {
                $bodyRaw = $Request.BodyString
            } else {
                throw "Request.Body が null です"
            }
        } else {
            $bodyRaw = $Request.Body
        }

        $body = $bodyRaw | ConvertFrom-Json

        # ログディレクトリの確認
        $logDir = Join-Path $script:RootDir "logs"
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }

        # ブラウザコンソールログファイル名（日付ごと）
        $dateStr = Get-Date -Format "yyyyMMdd"
        $browserLogFile = Join-Path $logDir "browser-console_$dateStr.log"

        # ログエントリを整形
        $logEntries = $body.logs | ForEach-Object {
            $timestamp = $_.timestamp
            $level = $_.level.ToUpper()
            $message = $_.message
            "[$timestamp] [$level] $message"
        }

        # ファイルに追記（UTF-8 BOMなし）
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        $existingContent = ""
        if (Test-Path $browserLogFile) {
            $existingContent = [System.IO.File]::ReadAllText($browserLogFile, $utf8NoBom)
        }

        $newContent = $existingContent + ($logEntries -join "`r`n") + "`r`n"
        [System.IO.File]::WriteAllText($browserLogFile, $newContent, $utf8NoBom)

        # 成功レスポンス
        $result = @{
            success = $true
            logCount = $body.logs.Count
            logFile = $browserLogFile
        }
        $json = $result | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)

    } catch {
        Write-Host "[ブラウザログAPI] エラー: $($_.Exception.Message)" -ForegroundColor Red
        $Response.SetStatusCode(500)
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# ============================================
# 4. 静的ファイル（HTML/JS）の提供設定
# ============================================

Write-Host "静的ファイル提供を設定します..." -ForegroundColor Cyan

# グローバル変数として設定（PowerShell 5.1対応）
$global:UiPathForPolaris = Join-Path $script:RootDir "ui"
$global:RootDirForPolaris = $script:RootDir

# ルートパス "/" - index-legacy.htmlを提供
New-PolarisRoute -Path "/" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    $uiPath = $global:UiPathForPolaris
    $indexPath = Join-Path $uiPath "index-legacy.html"
    if (Test-Path $indexPath) {
        $content = Get-Content $indexPath -Raw -Encoding UTF8
        $Response.SetContentType('text/html; charset=utf-8')
        $Response.Send($content)
    } else {
        $Response.SetStatusCode(404)
        $Response.Send("index-legacy.html not found")
    }
}

# index-legacy.html
New-PolarisRoute -Path "/index-legacy.html" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    $uiPath = $global:UiPathForPolaris
    $indexPath = Join-Path $uiPath "index-legacy.html"
    if (Test-Path $indexPath) {
        $content = Get-Content $indexPath -Raw -Encoding UTF8
        $Response.SetContentType('text/html; charset=utf-8')
        $Response.Send($content)
    } else {
        $Response.SetStatusCode(404)
        $Response.Send("index-legacy.html not found")
    }
}

# style-legacy.css
New-PolarisRoute -Path "/style-legacy.css" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    $uiPath = $global:UiPathForPolaris
    $cssPath = Join-Path $uiPath "style-legacy.css"
    if (Test-Path $cssPath) {
        $content = Get-Content $cssPath -Raw -Encoding UTF8
        $Response.SetContentType('text/css; charset=utf-8')
        $Response.Send($content)
    } else {
        $Response.SetStatusCode(404)
        $Response.Send("style-legacy.css not found")
    }
}

# app-legacy.js
New-PolarisRoute -Path "/app-legacy.js" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    $uiPath = $global:UiPathForPolaris
    $jsPath = Join-Path $uiPath "app-legacy.js"
    if (Test-Path $jsPath) {
        $content = Get-Content $jsPath -Raw -Encoding UTF8
        $Response.SetContentType('application/javascript; charset=utf-8')
        $Response.Send($content)
    } else {
        $Response.SetStatusCode(404)
        $Response.Send("app-legacy.js not found")
    }
}

# layer-detail.html（ポップアップウィンドウ用）
New-PolarisRoute -Path "/layer-detail.html" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    $uiPath = $global:UiPathForPolaris
    $htmlPath = Join-Path $uiPath "layer-detail.html"
    if (Test-Path $htmlPath) {
        $content = Get-Content $htmlPath -Raw -Encoding UTF8
        $Response.SetContentType('text/html; charset=utf-8')
        $Response.Send($content)
    } else {
        $Response.SetStatusCode(404)
        $Response.Send("layer-detail.html not found")
    }
}

# layer-detail.js（ポップアップウィンドウ用 - 非推奨、モーダル方式に移行）
New-PolarisRoute -Path "/layer-detail.js" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    $uiPath = $global:UiPathForPolaris
    $jsPath = Join-Path $uiPath "layer-detail.js"
    if (Test-Path $jsPath) {
        $content = Get-Content $jsPath -Raw -Encoding UTF8
        $Response.SetContentType('application/javascript; charset=utf-8')
        $Response.Send($content)
    } else {
        $Response.SetStatusCode(404)
        $Response.Send("layer-detail.js not found")
    }
}

# modal-functions.js（モーダルウィンドウ用）
New-PolarisRoute -Path "/modal-functions.js" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    $uiPath = $global:UiPathForPolaris
    $jsPath = Join-Path $uiPath "modal-functions.js"
    if (Test-Path $jsPath) {
        $content = Get-Content $jsPath -Raw -Encoding UTF8
        $Response.SetContentType('application/javascript; charset=utf-8')
        $Response.Send($content)
    } else {
        $Response.SetStatusCode(404)
        $Response.Send("modal-functions.js not found")
    }
}

# ボタン設定.json (英語エイリアス: /button-settings.json)
# 注: ブラウザが日本語URLを自動エンコードするため、英語パスを使用
New-PolarisRoute -Path "/button-settings.json" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    $rootDir = $global:RootDirForPolaris
    $jsonPath = Join-Path $rootDir "ボタン設定.json"
    if (Test-Path $jsonPath) {
        $content = Get-Content $jsonPath -Raw -Encoding UTF8
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($content)
    } else {
        $Response.SetStatusCode(404)
        $errorResult = @{ error = "ボタン設定.json not found" }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

# ボタン設定.json (日本語パス - 後方互換性用)
New-PolarisRoute -Path "/ボタン設定.json" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    $rootDir = $global:RootDirForPolaris
    $jsonPath = Join-Path $rootDir "ボタン設定.json"
    if (Test-Path $jsonPath) {
        $content = Get-Content $jsonPath -Raw -Encoding UTF8
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($content)
    } else {
        $Response.SetStatusCode(404)
        $errorResult = @{ error = "ボタン設定.json not found" }
        $json = $errorResult | ConvertTo-Json -Compress
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($json)
    }
}

Write-Host "[OK] 静的ファイル提供を設定しました" -ForegroundColor Green
Write-Host ""

# ============================================
# 5. サーバー起動
# ============================================

Write-Host "Polarisサーバーを起動します..." -ForegroundColor Cyan
Write-Host "  ポート: $Port" -ForegroundColor White
Write-Host "  URL: http://localhost:$Port" -ForegroundColor White
Write-Host "  フロントエンド: http://localhost:$Port/index-legacy.html" -ForegroundColor Cyan
Write-Host ""

try {
    Start-Polaris -Port $Port -MinRunspaces 1 -MaxRunspaces 5

    Write-Host "==================================" -ForegroundColor Green
    Write-Host "✓ サーバー起動成功！" -ForegroundColor Green
    Write-Host "==================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "アクセス先: http://localhost:$Port" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "APIエンドポイント（Phase 3対応）:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "【基本】" -ForegroundColor White
    Write-Host "  GET  /api/health                    - ヘルスチェック" -ForegroundColor Gray
    Write-Host "  GET  /api/session                   - セッション情報" -ForegroundColor Gray
    Write-Host "  GET  /api/debug                     - デバッグ情報" -ForegroundColor Gray
    Write-Host ""
    Write-Host "【ノード管理】" -ForegroundColor White
    Write-Host "  GET  /api/nodes                     - 全ノード取得" -ForegroundColor Gray
    Write-Host "  PUT  /api/nodes                     - ノード配列を一括設定" -ForegroundColor Gray
    Write-Host "  POST /api/nodes                     - ノード追加" -ForegroundColor Gray
    Write-Host "  DELETE /api/nodes/:id               - ノード削除" -ForegroundColor Gray
    Write-Host "  DELETE /api/nodes/all               - 全ノード削除" -ForegroundColor Gray
    Write-Host ""
    Write-Host "【変数管理】" -ForegroundColor White
    Write-Host "  GET  /api/variables                 - 変数一覧取得" -ForegroundColor Gray
    Write-Host "  GET  /api/variables/:name           - 変数取得" -ForegroundColor Gray
    Write-Host "  POST /api/variables                 - 変数追加" -ForegroundColor Gray
    Write-Host "  PUT  /api/variables/:name           - 変数更新" -ForegroundColor Gray
    Write-Host "  DELETE /api/variables/:name         - 変数削除" -ForegroundColor Gray
    Write-Host ""
    Write-Host "【メニュー操作】" -ForegroundColor White
    Write-Host "  GET  /api/menu/structure            - メニュー構造取得" -ForegroundColor Gray
    Write-Host "  POST /api/menu/action/:actionId     - メニューアクション実行" -ForegroundColor Gray
    Write-Host ""
    Write-Host "【実行・フォルダ】" -ForegroundColor White
    Write-Host "  POST /api/execute/generate          - PowerShellコード生成" -ForegroundColor Gray
    Write-Host "  GET  /api/folders                   - フォルダ一覧取得" -ForegroundColor Gray
    Write-Host "  POST /api/folders                   - フォルダ作成" -ForegroundColor Gray
    Write-Host "  PUT  /api/folders/:name             - フォルダ切り替え" -ForegroundColor Gray
    Write-Host ""
    Write-Host "【バリデーション】" -ForegroundColor White
    Write-Host "  POST /api/validate/drop             - ドロップ可否チェック" -ForegroundColor Gray
    Write-Host ""
    Write-Host "【コードID管理】" -ForegroundColor White
    Write-Host "  POST /api/id/generate               - 新規ID生成" -ForegroundColor Gray
    Write-Host "  POST /api/entry/add                 - エントリ追加" -ForegroundColor Gray
    Write-Host "  GET  /api/entry/:id                 - エントリ取得" -ForegroundColor Gray
    Write-Host "  GET  /api/entries/all               - 全エントリ取得" -ForegroundColor Gray
    Write-Host ""
    Write-Host "【ブラウザログ】" -ForegroundColor White
    Write-Host "  POST /api/browser-logs              - ブラウザコンソールログ受信" -ForegroundColor Gray
    Write-Host ""
    Write-Host "停止するには Ctrl+C を押してください" -ForegroundColor Yellow
    Write-Host ""

    # ブラウザ自動起動（Edge専用 - Chrome分離）
    if ($AutoOpenBrowser) {
        Start-Sleep -Seconds 1
        $url = "http://localhost:$Port/index-legacy.html"

        # Microsoft Edge専用で起動（Chromeと分離）
        $edgePaths = @(
            "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
            "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe"
        )

        $edgeFound = $false
        foreach ($edgePath in $edgePaths) {
            if (Test-Path $edgePath) {
                Write-Host "[ブラウザ] Microsoft Edge（UIpowershell専用）を最大化アプリモードで起動します" -ForegroundColor Green
                Write-Host "           URL: $url" -ForegroundColor Cyan
                # --app モードで起動（タブなし、独立ウインドウ、最大化）
                Start-Process $edgePath -ArgumentList "--app=$url --start-maximized"
                $edgeFound = $true
                break
            }
        }

        if (-not $edgeFound) {
            Write-Host "[警告] Microsoft Edgeが見つかりません" -ForegroundColor Yellow
            Write-Host "        手動でブラウザを開いてください: $url" -ForegroundColor Yellow
        }
    }

    # サーバーを実行し続ける
    while ($true) {
        Start-Sleep -Seconds 1
    }

} catch {
    Write-Host "[エラー] サーバー起動に失敗しました" -ForegroundColor Red
    Write-Host "詳細: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "トラブルシューティング:" -ForegroundColor Yellow
    Write-Host "  - ポート $Port が既に使用中の可能性があります" -ForegroundColor Yellow
    Write-Host "  - 別のポートを指定してください: .\api-server-v2.ps1 -Port 8081" -ForegroundColor Yellow
    exit 1
} finally {
    # クリーンアップ
    Stop-Polaris

    # トランスクリプト停止
    Write-Host ""
    Write-Host "[ログ] ログファイルに保存しました: $logFile" -ForegroundColor Green
    Stop-Transcript
}
