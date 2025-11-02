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
# 1. モジュール読み込み
# ============================================

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "UIpowershell - Polaris API Server V2" -ForegroundColor Cyan
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
# 3. REST APIエンドポイント定義
# ============================================

# --------------------------------------------
# 基本エンドポイント
# --------------------------------------------

# ヘルスチェック
New-PolarisRoute -Path "/api/health" -Method GET -ScriptBlock {
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
    $result = Get-SessionInfo
    $Response.Json($result)
}

# デバッグ情報取得
New-PolarisRoute -Path "/api/debug" -Method GET -ScriptBlock {
    $result = Get-StateDebugInfo
    $Response.Json($result)
}

# --------------------------------------------
# ノード管理API（state-manager）
# --------------------------------------------

# 全ノード取得
New-PolarisRoute -Path "/api/nodes" -Method GET -ScriptBlock {
    $result = Get-AllNodes
    $Response.Json($result)
}

# ノード配列を一括設定（React Flowから同期）
New-PolarisRoute -Path "/api/nodes" -Method PUT -ScriptBlock {
    try {
        $body = $Request.Body | ConvertFrom-Json
        $result = Set-AllNodes -Nodes $body.nodes
        $Response.Json($result)
    } catch {
        $Response.SetStatusCode(500)
        $Response.Json(@{
            success = $false
            error = $_.Exception.Message
        })
    }
}

# ノード追加
New-PolarisRoute -Path "/api/nodes" -Method POST -ScriptBlock {
    try {
        $body = $Request.Body | ConvertFrom-Json
        $result = Add-Node -Node $body
        $Response.Json($result)
    } catch {
        $Response.SetStatusCode(500)
        $Response.Json(@{
            success = $false
            error = $_.Exception.Message
        })
    }
}

# ノード削除（単一・セット両対応）
New-PolarisRoute -Path "/api/nodes/:id" -Method DELETE -ScriptBlock {
    try {
        $nodeId = $Request.Parameters.id
        $body = $Request.Body | ConvertFrom-Json

        # ノード配列を受け取る
        $nodes = $body.nodes

        # v2関数で削除対象を特定
        $result = ノード削除_v2 -ノード配列 $nodes -TargetNodeId $nodeId

        $Response.Json($result)
    } catch {
        $Response.SetStatusCode(500)
        $Response.Json(@{
            success = $false
            error = $_.Exception.Message
        })
    }
}

# すべてのノードを削除
New-PolarisRoute -Path "/api/nodes/all" -Method DELETE -ScriptBlock {
    try {
        $body = $Request.Body | ConvertFrom-Json
        $result = すべてのノードを削除_v2 -ノード配列 $body.nodes
        $Response.Json($result)
    } catch {
        $Response.SetStatusCode(500)
        $Response.Json(@{
            success = $false
            error = $_.Exception.Message
        })
    }
}

# --------------------------------------------
# 変数管理API（10_変数機能_変数管理UI_v2.ps1）
# --------------------------------------------

# 変数一覧取得
New-PolarisRoute -Path "/api/variables" -Method GET -ScriptBlock {
    $result = Get-VariableList_v2
    $Response.Json($result)
}

# 変数取得（名前指定）
New-PolarisRoute -Path "/api/variables/:name" -Method GET -ScriptBlock {
    try {
        $varName = $Request.Parameters.name
        $result = Get-Variable_v2 -Name $varName
        $Response.Json($result)
    } catch {
        $Response.SetStatusCode(500)
        $Response.Json(@{
            success = $false
            error = $_.Exception.Message
        })
    }
}

# 変数追加
New-PolarisRoute -Path "/api/variables" -Method POST -ScriptBlock {
    try {
        $body = $Request.Body | ConvertFrom-Json
        $result = Add-Variable_v2 -Name $body.name -Value $body.value -Type $body.type
        $Response.Json($result)
    } catch {
        $Response.SetStatusCode(500)
        $Response.Json(@{
            success = $false
            error = $_.Exception.Message
        })
    }
}

# 変数更新
New-PolarisRoute -Path "/api/variables/:name" -Method PUT -ScriptBlock {
    try {
        $varName = $Request.Parameters.name
        $body = $Request.Body | ConvertFrom-Json
        $result = Update-Variable_v2 -Name $varName -Value $body.value
        $Response.Json($result)
    } catch {
        $Response.SetStatusCode(500)
        $Response.Json(@{
            success = $false
            error = $_.Exception.Message
        })
    }
}

# 変数削除
New-PolarisRoute -Path "/api/variables/:name" -Method DELETE -ScriptBlock {
    try {
        $varName = $Request.Parameters.name
        $result = Remove-Variable_v2 -Name $varName
        $Response.Json($result)
    } catch {
        $Response.SetStatusCode(500)
        $Response.Json(@{
            success = $false
            error = $_.Exception.Message
        })
    }
}

# --------------------------------------------
# メニュー操作API（07_メインF機能_ツールバー作成_v2.ps1）
# --------------------------------------------

# メニュー構造取得
New-PolarisRoute -Path "/api/menu/structure" -Method GET -ScriptBlock {
    $result = Get-MenuStructure_v2
    $Response.Json($result)
}

# メニューアクション実行
New-PolarisRoute -Path "/api/menu/action/:actionId" -Method POST -ScriptBlock {
    try {
        $actionId = $Request.Parameters.actionId
        $body = $Request.Body | ConvertFrom-Json

        $params = if ($body.parameters) { $body.parameters } else { @{} }
        $result = Execute-MenuAction_v2 -ActionId $actionId -Parameters $params

        $Response.Json($result)
    } catch {
        $Response.SetStatusCode(500)
        $Response.Json(@{
            success = $false
            error = $_.Exception.Message
        })
    }
}

# --------------------------------------------
# 実行イベントAPI（08_メインF機能_メインボタン処理_v2.ps1）
# --------------------------------------------

# PowerShellコード生成
New-PolarisRoute -Path "/api/execute/generate" -Method POST -ScriptBlock {
    try {
        $body = $Request.Body | ConvertFrom-Json

        $result = 実行イベント_v2 `
            -ノード配列 $body.nodes `
            -OutputPath $body.outputPath `
            -OpenFile $body.openFile

        $Response.Json($result)
    } catch {
        $Response.SetStatusCode(500)
        $Response.Json(@{
            success = $false
            error = $_.Exception.Message
        })
    }
}

# --------------------------------------------
# フォルダ管理API（08_メインF機能_メインボタン処理_v2.ps1）
# --------------------------------------------

# フォルダ一覧取得
New-PolarisRoute -Path "/api/folders" -Method GET -ScriptBlock {
    $result = フォルダ切替イベント_v2 -FolderName "list"
    $Response.Json($result)
}

# フォルダ作成
New-PolarisRoute -Path "/api/folders" -Method POST -ScriptBlock {
    try {
        $body = $Request.Body | ConvertFrom-Json
        $result = フォルダ作成イベント_v2 -FolderName $body.folderName
        $Response.Json($result)
    } catch {
        $Response.SetStatusCode(500)
        $Response.Json(@{
            success = $false
            error = $_.Exception.Message
        })
    }
}

# フォルダ切り替え
New-PolarisRoute -Path "/api/folders/:name" -Method PUT -ScriptBlock {
    try {
        $folderName = $Request.Parameters.name
        $result = フォルダ切替イベント_v2 -FolderName $folderName
        $Response.Json($result)
    } catch {
        $Response.SetStatusCode(500)
        $Response.Json(@{
            success = $false
            error = $_.Exception.Message
        })
    }
}

# --------------------------------------------
# バリデーションAPI（02-2_ネスト規制バリデーション_v2.ps1）
# --------------------------------------------

# ドロップ可否チェック
New-PolarisRoute -Path "/api/validate/drop" -Method POST -ScriptBlock {
    try {
        $body = $Request.Body | ConvertFrom-Json

        $result = ドロップ禁止チェック_ネスト規制_v2 `
            -ノード配列 $body.nodes `
            -MovingNodeId $body.movingNodeId `
            -設置希望Y $body.targetY

        $Response.Json($result)
    } catch {
        $Response.SetStatusCode(500)
        $Response.Json(@{
            success = $false
            error = $_.Exception.Message
        })
    }
}

# --------------------------------------------
# コードID管理API（既存）
# --------------------------------------------

# 新しいIDを自動生成
New-PolarisRoute -Path "/api/id/generate" -Method POST -ScriptBlock {
    try {
        $newId = IDを自動生成する
        $Response.Json(@{
            success = $true
            id = $newId
        })
    } catch {
        $Response.SetStatusCode(500)
        $Response.Json(@{
            success = $false
            error = $_.Exception.Message
        })
    }
}

# エントリを追加（指定ID）
New-PolarisRoute -Path "/api/entry/add" -Method POST -ScriptBlock {
    try {
        $body = $Request.Body | ConvertFrom-Json

        $result = エントリを追加_指定ID `
            -targetID $body.targetID `
            -TypeName $body.TypeName `
            -displayText $body.displayText `
            -code $body.code `
            -toID $body.toID `
            -order $body.order

        $Response.Json(@{
            success = $true
            data = $result
        })
    } catch {
        $Response.SetStatusCode(500)
        $Response.Json(@{
            success = $false
            error = $_.Exception.Message
        })
    }
}

# IDでエントリを取得
New-PolarisRoute -Path "/api/entry/:id" -Method GET -ScriptBlock {
    try {
        $id = $Request.Parameters.id
        $entry = IDでエントリを取得 -targetID $id

        if ($entry) {
            $Response.Json(@{
                success = $true
                data = $entry
            })
        } else {
            $Response.SetStatusCode(404)
            $Response.Json(@{
                success = $false
                error = "エントリが見つかりません: ID=$id"
            })
        }
    } catch {
        $Response.SetStatusCode(500)
        $Response.Json(@{
            success = $false
            error = $_.Exception.Message
        })
    }
}

# 全エントリを取得（フロー描画用）
New-PolarisRoute -Path "/api/entries/all" -Method GET -ScriptBlock {
    try {
        $jsonPath = Join-Path $script:RootDir "00_code\コード.json"

        if (Test-Path $jsonPath) {
            $jsonContent = Get-Content $jsonPath -Encoding UTF8 -Raw | ConvertFrom-Json

            $Response.Json(@{
                success = $true
                data = $jsonContent
            })
        } else {
            $Response.Json(@{
                success = $true
                data = @()
                message = "コード.jsonが存在しません"
            })
        }
    } catch {
        $Response.SetStatusCode(500)
        $Response.Json(@{
            success = $false
            error = $_.Exception.Message
        })
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

# ボタン設定.json
New-PolarisRoute -Path "/ボタン設定.json" -Method GET -ScriptBlock {
    $rootDir = $global:RootDirForPolaris
    $jsonPath = Join-Path $rootDir "ボタン設定.json"
    if (Test-Path $jsonPath) {
        $content = Get-Content $jsonPath -Raw -Encoding UTF8
        $Response.SetContentType('application/json; charset=utf-8')
        $Response.Send($content)
    } else {
        $Response.SetStatusCode(404)
        $Response.Json(@{ error = "ボタン設定.json not found" })
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
Write-Host "  フロントエンド: http://localhost:$Port/index-v2.html" -ForegroundColor White
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
    Write-Host "停止するには Ctrl+C を押してください" -ForegroundColor Yellow
    Write-Host ""

    # ブラウザ自動起動
    if ($AutoOpenBrowser) {
        Start-Sleep -Seconds 1
        Start-Process "http://localhost:$Port/index-legacy.html"
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
}
