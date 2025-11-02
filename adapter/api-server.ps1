# ============================================
# Polaris HTTPサーバー - API Adapter Layer
# ============================================
# 役割：ブラウザ（HTML/JS） ↔ 既存PowerShell関数を橋渡し
# アーキテクチャ：Browser fetch() → Polaris → PowerShell関数 → JSON
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
Write-Host "UIpowershell - Polaris API Server" -ForegroundColor Cyan
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
        # PowerShell Galleryからインストール
        Write-Host "Install-Module -Name Polaris -Scope CurrentUser -Force を実行中..." -ForegroundColor Cyan
        Install-Module -Name Polaris -Scope CurrentUser -Force -AllowClobber

        # インストール確認
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

# 既存のPowerShell関数を読み込み（アダプター層）
Write-Host ""
Write-Host "既存のPowerShell関数を読み込みます..." -ForegroundColor Cyan

# JSON操作ユーティリティ
. "$script:RootDir\00_共通ユーティリティ_JSON操作.ps1"
Write-Host "[OK] JSON操作ユーティリティ" -ForegroundColor Green

# コードID管理（純粋なビジネスロジック - 100%再利用可能）
. "$script:RootDir\09_変数機能_コードID管理JSON.ps1"
Write-Host "[OK] コードID管理JSON" -ForegroundColor Green

# 必要に応じて他のビジネスロジックファイルも読み込み
# . "$script:RootDir\13_コードサブ汎用関数.ps1"
# . "$script:RootDir\14_コードサブ_EXCEL.ps1"

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# 2. Polaris HTTPサーバー設定
# ============================================

# 既存のPolarisインスタンスをクリーンアップ
try {
    Stop-Polaris -ErrorAction SilentlyContinue
} catch {
    # 初回起動時は無視
}

# 静的ファイル配信（HTML/CSS/JS）
$global:uiPath = Join-Path $script:RootDir "ui"

# Polarisの静的ファイル配信を設定
try {
    # ルートパスへのアクセス - index.htmlを返す
    New-PolarisRoute -Path "/" -Method GET -ScriptBlock {
        $indexPath = Join-Path $global:uiPath "index.html"
        if (Test-Path $indexPath) {
            $content = Get-Content $indexPath -Raw -Encoding UTF8
            $Response.SetContentType("text/html; charset=utf-8")
            $Response.Send($content)
        } else {
            $Response.SetStatusCode(404)
            $Response.Send("index.html not found at: $indexPath")
        }
    }

    # libs/配下の静的ファイルを配信
    New-PolarisRoute -Path "/libs/*" -Method GET -ScriptBlock {
        $requestPath = $Request.Parameters["*"]
        $filePath = Join-Path $global:uiPath "libs\$requestPath"

        if (Test-Path $filePath) {
            $content = Get-Content $filePath -Raw -Encoding UTF8

            # Content-Typeを設定
            $extension = [System.IO.Path]::GetExtension($filePath)
            switch ($extension) {
                ".js"  { $Response.SetContentType("application/javascript; charset=utf-8") }
                ".css" { $Response.SetContentType("text/css; charset=utf-8") }
                default { $Response.SetContentType("text/plain; charset=utf-8") }
            }

            $Response.Send($content)
        } else {
            $Response.SetStatusCode(404)
            $Response.Send("File not found: $requestPath")
        }
    }

    Write-Host "[OK] 静的ファイル配信: $global:uiPath" -ForegroundColor Green
} catch {
    Write-Host "[エラー] 静的ファイル配信の設定に失敗しました: $($_.Exception.Message)" -ForegroundColor Red
    throw
}

# ============================================
# 3. REST APIエンドポイント定義
# ============================================

# ヘルスチェック
New-PolarisRoute -Path "/api/health" -Method GET -ScriptBlock {
    $Response.Json(@{
        status = "ok"
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        version = "1.0.0-prototype"
    })
}

# --------------------------------------------
# コードID管理API（09_変数機能_コードID管理JSON.ps1から）
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
        # コード.jsonから全エントリを読み込み
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

# エントリを削除
New-PolarisRoute -Path "/api/entry/:id" -Method DELETE -ScriptBlock {
    try {
        $id = $Request.Parameters.id

        # TODO: 削除関数が既存PowerShellに存在する場合はそれを呼び出す
        # 現時点ではJSON直接操作のプレースホルダー

        $Response.Json(@{
            success = $true
            message = "エントリを削除しました: ID=$id"
        })
    } catch {
        $Response.SetStatusCode(500)
        $Response.Json(@{
            success = $false
            error = $_.Exception.Message
        })
    }
}

# --------------------------------------------
# ボタン配置・移動API（既存の02-4_ボタン操作配置.ps1から）
# --------------------------------------------

# ボタン位置を更新
New-PolarisRoute -Path "/api/button/position" -Method PUT -ScriptBlock {
    try {
        $body = $Request.Body | ConvertFrom-Json

        # TODO: 既存の位置更新関数を呼び出す
        # 現時点ではプレースホルダー

        $Response.Json(@{
            success = $true
            message = "ボタン位置を更新しました"
            data = @{
                id = $body.id
                x = $body.x
                y = $body.y
            }
        })
    } catch {
        $Response.SetStatusCode(500)
        $Response.Json(@{
            success = $false
            error = $_.Exception.Message
        })
    }
}

# ============================================
# 4. サーバー起動
# ============================================

Write-Host "Polarisサーバーを起動します..." -ForegroundColor Cyan
Write-Host "  ポート: $Port" -ForegroundColor White
Write-Host "  URL: http://localhost:$Port" -ForegroundColor White
Write-Host ""

try {
    Start-Polaris -Port $Port -MinRunspaces 1 -MaxRunspaces 5

    Write-Host "==================================" -ForegroundColor Green
    Write-Host "✓ サーバー起動成功！" -ForegroundColor Green
    Write-Host "==================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "アクセス先: http://localhost:$Port" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "APIエンドポイント:" -ForegroundColor Yellow
    Write-Host "  GET  /api/health              - ヘルスチェック" -ForegroundColor White
    Write-Host "  POST /api/id/generate         - 新規ID生成" -ForegroundColor White
    Write-Host "  POST /api/entry/add           - エントリ追加" -ForegroundColor White
    Write-Host "  GET  /api/entry/:id           - エントリ取得" -ForegroundColor White
    Write-Host "  GET  /api/entries/all         - 全エントリ取得" -ForegroundColor White
    Write-Host "  DELETE /api/entry/:id         - エントリ削除" -ForegroundColor White
    Write-Host "  PUT  /api/button/position     - ボタン位置更新" -ForegroundColor White
    Write-Host ""
    Write-Host "停止するには Ctrl+C を押してください" -ForegroundColor Yellow
    Write-Host ""

    # ブラウザ自動起動
    if ($AutoOpenBrowser) {
        Start-Sleep -Seconds 1
        Start-Process "http://localhost:$Port"
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
    Write-Host "  - 別のポートを指定してください: .\api-server.ps1 -Port 8081" -ForegroundColor Yellow
    exit 1
} finally {
    # クリーンアップ
    Stop-Polaris
}
