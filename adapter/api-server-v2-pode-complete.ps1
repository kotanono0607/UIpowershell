# ============================================
# Pode HTTPサーバー - API Adapter Layer V2
# ============================================
# 役割：ブラウザ（HTML/JS） ↔ 既存PowerShell関数（v2版）を橋渡し
# アーキテクチャ：Browser fetch() → Pode → v2関数 → JSON
# Phase 3対応：すべてのv2関数のエンドポイントを追加
# Pode移行: Polarisからの完全移行（2025-11-16）
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

# コントロールログファイル（control-log_*.log）を全て削除
$controlLogs = Get-ChildItem -Path $logDir -Filter "control-log_*.log" -ErrorAction SilentlyContinue
foreach ($file in $controlLogs) {
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

# コントロールログファイル（起動時からノード生成可能までのタイムスタンプ記録）
$controlLogFile = Join-Path $logDir "control-log_$timestamp.log"

# トランスクリプト開始
Start-Transcript -Path $logFile -Append -Force
Write-Host "[ログ] ログファイル: $logFile" -ForegroundColor Green
Write-Host "[ログ] コントロールログ: $controlLogFile" -ForegroundColor Green
Write-Host ""

# ============================================
# コントロールログ関数
# ============================================

function Write-ControlLog {
    param(
        [string]$Message,
        [string]$LogFile = $controlLogFile
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] $Message"

    # ファイルに追記
    Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8

    # コンソールにも表示
    Write-Host $logEntry -ForegroundColor Cyan
}

# 起動開始タイムスタンプ
Write-ControlLog "[START] UIpowershell 起動開始（Pode版）"

# ============================================
# 1. モジュール読み込み
# ============================================

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "UIpowershell - Pode API Server V2" -ForegroundColor Cyan
Write-Host "Version: 2.0.0 (Pode移行版)" -ForegroundColor Yellow
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Podeモジュールの読み込み
$podeModulePath = Join-Path $script:RootDir "Modules\Pode"
if (Test-Path $podeModulePath) {
    Write-Host "[OK] Podeモジュールを読み込みます: $podeModulePath" -ForegroundColor Green
    $env:PSModulePath = "$podeModulePath;$env:PSModulePath"
} else {
    Write-Host "[警告] Podeモジュールが見つかりません: $podeModulePath" -ForegroundColor Yellow
    Write-Host "       PowerShell Galleryからのインストールを試みます..." -ForegroundColor Yellow
}

# ============================================
# PowerShell 5.1対応: PodeモジュールのUTF-8 BOM修正
# ============================================
# PowerShell 5.1はUTF-8 BOMが必要なため、Podeモジュールの問題ファイルを修正
Write-Host "PowerShell 5.1環境用にPodeモジュールを最適化しています..." -ForegroundColor Cyan

# Pode 2.11.0または2.12.1のConsole.ps1を検出
$podeConsoleFile = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Pode\2.11.0\Private\Console.ps1"
if (-not (Test-Path $podeConsoleFile)) {
    $podeConsoleFile = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Pode\2.12.1\Private\Console.ps1"
}
if (Test-Path $podeConsoleFile) {
    try {
        # バイナリモードで正確に読み取る
        $bytes = [System.IO.File]::ReadAllBytes($podeConsoleFile)
        $content = [System.Text.Encoding]::UTF8.GetString($bytes)

        # 行ごとに処理
        $lines = $content -split "`r?`n"
        $fixedLines = @()
        $lineNumber = 0
        $replacedCount = 0

        foreach ($line in $lines) {
            $lineNumber++
            $originalLine = $line

            # すべての問題あるUnicode文字をASCII相当文字に置換
            # Box Drawing文字
            $line = $line -replace ([char]0x2500), '-'
            $line = $line -replace ([char]0x2501), '-'
            $line = $line -replace ([char]0x2502), '|'
            $line = $line -replace ([char]0x2503), '|'

            # ダッシュ類
            $line = $line -replace ([char]0x2013), '-'
            $line = $line -replace ([char]0x2014), '-'
            $line = $line -replace ([char]0x2212), '-'

            # アポストロフィとクォート（482行目対策）
            $line = $line -replace ([char]0x2018), "'"
            $line = $line -replace ([char]0x2019), "'"
            $line = $line -replace ([char]0x201C), '"'
            $line = $line -replace ([char]0x201D), '"'

            # 460-470行目：クォート内の非ASCII文字を削除
            if ($lineNumber -ge 460 -and $lineNumber -le 470) {
                $line = $line -replace "'[^\x00-\x7F]+'", "''"
                $line = $line -replace '"[^\x00-\x7F]+"', '""'
            }

            if ($originalLine -ne $line) {
                $replacedCount++
            }

            $fixedLines += $line
        }

        # UTF-8 BOM無しで保存（モジュールファイルはBOM無しが推奨）
        $utf8NoBOM = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllLines($podeConsoleFile, $fixedLines, $utf8NoBOM)

        if ($replacedCount -gt 0) {
            Write-Host "[OK] Podeモジュールのエンコーディングを修正しました ($replacedCount 文字)" -ForegroundColor Green
        } else {
            Write-Host "[情報] Podeモジュールは既に修正済みです" -ForegroundColor Gray
        }
    } catch {
        Write-Host "[警告] Podeモジュールの修正をスキップ: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "[情報] Podeモジュールが未インストールです（自動インストールされます）" -ForegroundColor Gray
}

try {
    Import-Module Pode -ErrorAction Stop
    Write-Host "[OK] Podeモジュールを読み込みました (Version: $((Get-Module Pode).Version))" -ForegroundColor Green
    Write-ControlLog "[MODULE] Podeモジュール読み込み完了"
} catch {
    Write-Host "[エラー] Podeモジュールの読み込みに失敗しました" -ForegroundColor Red
    Write-Host "       詳細: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "自動インストールを開始します..." -ForegroundColor Yellow
    Write-Host ""

    try {
        Write-Host "Install-Module -Name Pode -RequiredVersion 2.11.0 -Scope CurrentUser -Force を実行中..." -ForegroundColor Cyan
        Write-Host "    （PowerShell 5.1互換バージョンをインストールします）" -ForegroundColor Gray
        Install-Module -Name Pode -RequiredVersion 2.11.0 -Scope CurrentUser -Force -AllowClobber

        # PowerShell 5.1対応: インストール後にPodeモジュールを修正
        Write-Host "Podeモジュールのエンコーディングを修正しています..." -ForegroundColor Cyan
        $podeConsoleFile = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Pode\2.11.0\Private\Console.ps1"
        if (Test-Path $podeConsoleFile) {
            try {
                # バイナリモードで正確に読み取る
                $bytes = [System.IO.File]::ReadAllBytes($podeConsoleFile)
                $content = [System.Text.Encoding]::UTF8.GetString($bytes)

                # 行ごとに処理
                $lines = $content -split "`r?`n"
                $fixedLines = @()
                $lineNumber = 0
                $replacedCount = 0

                foreach ($line in $lines) {
                    $lineNumber++
                    $originalLine = $line

                    # すべての問題あるUnicode文字をASCII相当文字に置換
                    # Box Drawing文字
                    $line = $line -replace ([char]0x2500), '-'
                    $line = $line -replace ([char]0x2501), '-'
                    $line = $line -replace ([char]0x2502), '|'
                    $line = $line -replace ([char]0x2503), '|'

                    # ダッシュ類
                    $line = $line -replace ([char]0x2013), '-'
                    $line = $line -replace ([char]0x2014), '-'
                    $line = $line -replace ([char]0x2212), '-'

                    # アポストロフィとクォート（482行目対策）
                    $line = $line -replace ([char]0x2018), "'"
                    $line = $line -replace ([char]0x2019), "'"
                    $line = $line -replace ([char]0x201C), '"'
                    $line = $line -replace ([char]0x201D), '"'

                    # 460-470行目：クォート内の非ASCII文字を削除
                    if ($lineNumber -ge 460 -and $lineNumber -le 470) {
                        $line = $line -replace "'[^\x00-\x7F]+'", "''"
                        $line = $line -replace '"[^\x00-\x7F]+"', '""'
                    }

                    if ($originalLine -ne $line) {
                        $replacedCount++
                    }

                    $fixedLines += $line
                }

                # UTF-8 BOM無しで保存（モジュールファイルはBOM無しが推奨）
                $utf8NoBOM = New-Object System.Text.UTF8Encoding $false
                [System.IO.File]::WriteAllLines($podeConsoleFile, $fixedLines, $utf8NoBOM)

                if ($replacedCount -gt 0) {
                    Write-Host "[OK] Podeモジュールのエンコーディング修正完了 ($replacedCount 文字)" -ForegroundColor Green
                } else {
                    Write-Host "[情報] Podeモジュールは既に修正済みです" -ForegroundColor Gray
                }
            } catch {
                Write-Host "[警告] エンコーディング修正をスキップ: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }

        Import-Module Pode -ErrorAction Stop
        Write-Host "[OK] Podeのインストールと読み込みに成功しました！" -ForegroundColor Green

        # プロジェクトにコピー（次回起動時用）
        Write-Host ""
        Write-Host "次回起動を高速化するため、プロジェクトにコピーします..." -ForegroundColor Cyan
        $installedPodePath = (Get-Module Pode -ListAvailable | Select-Object -First 1).ModuleBase

        if (Test-Path $installedPodePath) {
            $targetPath = Join-Path $script:RootDir "Modules"
            if (-not (Test-Path $targetPath)) {
                New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
            }

            Copy-Item -Path $installedPodePath -Destination (Join-Path $targetPath "Pode") -Recurse -Force
            Write-Host "[OK] Podeをプロジェクトにコピーしました: $targetPath\Pode" -ForegroundColor Green
            Write-Host "     次回起動時は自動的にこのコピーが使用されます" -ForegroundColor Gray
        }

    } catch {
        Write-Host "[エラー] Podeのインストールに失敗しました" -ForegroundColor Red
        Write-Host "詳細: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "手動でインストールしてください:" -ForegroundColor Yellow
        Write-Host "  Install-Module -Name Pode -Scope CurrentUser -Force" -ForegroundColor Yellow
        Write-Host ""
        Stop-Transcript
        exit 1
    }
}

Write-ControlLog "[MODULE] モジュール読み込み完了"
Write-Host ""

# ============================================
# 2. 既存のPowerShell関数を読み込み
# ============================================

Write-Host "既存のPowerShell関数を読み込みます..." -ForegroundColor Cyan

# 00_共通ユーティリティ_JSON操作.ps1
$jsonUtilPath = Join-Path $script:RootDir "00_共通ユーティリティ_JSON操作.ps1"
if (Test-Path $jsonUtilPath) {
    . $jsonUtilPath
    Write-Host "[OK] 00_共通ユーティリティ_JSON操作.ps1" -ForegroundColor Green
} else {
    Write-Host "[警告] 00_共通ユーティリティ_JSON操作.ps1 が見つかりません" -ForegroundColor Yellow
}

# 09_変数機能_コードID管理JSON.ps1
$varManagePath = Join-Path $script:RootDir "09_変数機能_コードID管理JSON.ps1"
if (Test-Path $varManagePath) {
    . $varManagePath
    Write-Host "[OK] 09_変数機能_コードID管理JSON.ps1" -ForegroundColor Green
} else {
    Write-Host "[警告] 09_変数機能_コードID管理JSON.ps1 が見つかりません" -ForegroundColor Yellow
}

# Phase 3 Adapterファイルを読み込み
Write-Host ""
Write-Host "Phase 3 Adapterファイルを読み込みます..." -ForegroundColor Cyan

$stateManagerPath = Join-Path $PSScriptRoot "state-manager.ps1"
if (Test-Path $stateManagerPath) {
    . $stateManagerPath
    Write-Host "[OK] state-manager.ps1" -ForegroundColor Green
} else {
    Write-Host "[警告] state-manager.ps1 が見つかりません" -ForegroundColor Yellow
}

$nodeOpsPath = Join-Path $PSScriptRoot "node-operations.ps1"
if (Test-Path $nodeOpsPath) {
    . $nodeOpsPath
    Write-Host "[OK] node-operations.ps1" -ForegroundColor Green
} else {
    Write-Host "[警告] node-operations.ps1 が見つかりません" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

Write-ControlLog "[MODULE] 全モジュール読み込み完了"

# 静的ファイル配信用パス
$script:uiPath = Join-Path $script:RootDir "ui"

# ==============================================================================
# 3. Podeサーバーの起動と設定
# ==============================================================================

Write-Host "Podeサーバーを起動します..." -ForegroundColor Cyan
Write-Host "  ポート: $Port" -ForegroundColor White
Write-Host "  URL: http://localhost:$Port" -ForegroundColor White
Write-Host "  フロントエンド: http://localhost:$Port/index-legacy.html" -ForegroundColor Cyan
Write-Host ""

# Start-PodeServer でサーバー設定とルート定義を行う
Start-PodeServer {

    # エンドポイント設定
    Add-PodeEndpoint -Address localhost -Port $using:Port -Protocol Http

    # ロギング設定
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    Write-ControlLog "[SERVER] Podeサーバーエンドポイント設定完了 (ポート: $using:Port)"

    # CORS設定（すべてのオリジンを許可）
    Add-PodeCors -Name 'AllowAll' -Origin '*' -Methods 'GET, POST, PUT, DELETE, OPTIONS' -Headers 'Content-Type, Authorization'

    Write-ControlLog "[CORS] CORS設定完了"

    # ============================================
    # 4. 変換されたルート定義を読み込み
    # ============================================

    Write-Host "APIエンドポイントを設定します..." -ForegroundColor Cyan

    # 変換されたルート定義ファイルを読み込み
    $convertedRoutesPath = Join-Path $PSScriptRoot "CONVERTED_ROUTES.ps1"
    if (Test-Path $convertedRoutesPath) {
        . $convertedRoutesPath
        Write-Host "[OK] CONVERTED_ROUTES.ps1 から50個のルートを読み込みました" -ForegroundColor Green
        Write-ControlLog "[ROUTES] 全APIルート設定完了（50個）"
    } else {
        Write-Host "[エラー] CONVERTED_ROUTES.ps1 が見つかりません: $convertedRoutesPath" -ForegroundColor Red
        Write-Host "        ルート定義ファイルが必要です" -ForegroundColor Red
    }

    # ============================================
    # 5. サーバー起動完了メッセージ
    # ============================================

    Write-Host ""
    Write-Host "==================================" -ForegroundColor Green
    Write-Host "✓ Podeサーバー起動成功！" -ForegroundColor Green
    Write-Host "==================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "アクセス先: http://localhost:$using:Port" -ForegroundColor Cyan
    Write-Host ""

    Write-ControlLog "[SERVER] Podeサーバー起動成功 (ポート: $using:Port)"

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
    Write-Host "  POST /api/control-log               - コントロールログ受信" -ForegroundColor Gray
    Write-Host ""
    Write-Host "【静的ファイル】" -ForegroundColor White
    Write-Host "  GET  /                              - index-legacy.html" -ForegroundColor Gray
    Write-Host "  GET  /index-legacy.html             - HTMLファイル" -ForegroundColor Gray
    Write-Host "  GET  /style-legacy.css              - CSSファイル" -ForegroundColor Gray
    Write-Host "  GET  /app-legacy.js                 - JavaScriptファイル" -ForegroundColor Gray
    Write-Host ""
    Write-Host "停止するには Ctrl+C を押してください" -ForegroundColor Yellow
    Write-Host ""

    # ブラウザ自動起動（Edge専用 - Chrome分離）
    if ($using:AutoOpenBrowser) {
        Start-Sleep -Seconds 1
        $url = "http://localhost:$using:Port/index-legacy.html"

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

} # Start-PodeServer ブロックの終了

# サーバーが停止した後のクリーンアップ
Write-Host ""
Write-Host "[ログ] ログファイルに保存しました: $logFile" -ForegroundColor Green
Stop-Transcript
