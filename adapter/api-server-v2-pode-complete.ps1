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

# スクリプトのルートディレクトリ（exe化対応）
# exe化された場合: $MyInvocation.MyCommand.Path が実行ファイルのパス
# 通常実行の場合: $PSScriptRoot がスクリプトのディレクトリ
if ($MyInvocation.MyCommand.Path) {
    # exe化または直接実行の場合
    $scriptPath = $MyInvocation.MyCommand.Path
    $script:RootDir = Split-Path -Parent (Split-Path -Parent $scriptPath)
} elseif ($PSScriptRoot) {
    # モジュールから呼び出された場合
    $script:RootDir = Split-Path -Parent $PSScriptRoot
} else {
    # フォールバック: カレントディレクトリ
    $script:RootDir = Get-Location
}


# ============================================
# ログファイル設定
# ============================================

# ログディレクトリの作成
$logDir = Join-Path $script:RootDir "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# 古いログファイルを削除（起動のたびにクリーンアップ）
$deletedCount = 0

# サーバーログファイル（api-server-v2_*.log）を全て削除
$serverLogs = Get-ChildItem -Path $logDir -Filter "api-server-v2_*.log" -ErrorAction SilentlyContinue
foreach ($file in $serverLogs) {
    try {
        Remove-Item -Path $file.FullName -Force
        $deletedCount++
    } catch {
        # エラーを無視（意図的）
    }
}

# ブラウザコンソールログファイル（browser-console_*.log）を全て削除
$browserLogs = Get-ChildItem -Path $logDir -Filter "browser-console_*.log" -ErrorAction SilentlyContinue
foreach ($file in $browserLogs) {
    try {
        Remove-Item -Path $file.FullName -Force
        $deletedCount++
    } catch {
        # エラーを無視（意図的）
    }
}

# コントロールログファイル（control-log_*.log）を全て削除
$controlLogs = Get-ChildItem -Path $logDir -Filter "control-log_*.log" -ErrorAction SilentlyContinue
foreach ($file in $controlLogs) {
    try {
        Remove-Item -Path $file.FullName -Force
        $deletedCount++
    } catch {
        # エラーを無視（意図的）
    }
}

if ($deletedCount -gt 0) {
} else {
}

# ログファイル名（日付時刻付き）
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $logDir "api-server-v2_$timestamp.log"

# コントロールログファイル（起動時からノード生成可能までのタイムスタンプ記録）
$global:controlLogFile = Join-Path $logDir "control-log_$timestamp.log"

# トランスクリプト開始
Start-Transcript -Path $logFile -Append -Force

# ============================================
# コントロールログ関数
# ============================================

function global:Write-ControlLog {
    param(
        [string]$Message,
        [string]$LogFile = $global:controlLogFile
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] $Message"

    # ファイルに追記
    if ($LogFile -and $LogFile -ne "") {
        Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8
    }

    # コンソールにも表示
}

# 起動開始タイムスタンプ
Write-ControlLog "[START] UIpowershell 起動開始（Pode版）"

# ============================================
# 1. モジュール読み込み
# ============================================


# Podeモジュールの読み込み
# Modules フォルダを PSModulePath に追加（Modules\Pode\<version> 構造に対応）
$modulesPath = Join-Path $script:RootDir "Modules"
if (Test-Path $modulesPath) {
    $env:PSModulePath = "$modulesPath;$env:PSModulePath"
}

# ローカルの Pode モジュールを検索（バージョン付きフォルダ対応）
$localPodePath = Join-Path $script:RootDir "Modules\Pode"
$localPodeFound = $false
if (Test-Path $localPodePath) {
    # Modules\Pode\<version> または Modules\Pode 直下を確認
    $podeVersionDirs = Get-ChildItem -Path $localPodePath -Directory -ErrorAction SilentlyContinue
    if ($podeVersionDirs) {
        $latestVersion = $podeVersionDirs | Sort-Object Name -Descending | Select-Object -First 1
        $localPodeFound = $true
    } elseif (Test-Path (Join-Path $localPodePath "Pode.psd1")) {
        $localPodeFound = $true
    }
}


# ============================================
# PowerShell 5.1対応: PodeモジュールのUTF-8 BOM修正
# ============================================
# PowerShell 5.1はUTF-8 BOMが必要なため、Podeモジュールの問題ファイルを修正

# Pode 2.11.0または2.12.1のConsole.ps1を検出（ローカル優先）
$podeConsoleFile = $null
$possiblePaths = @(
    # ローカル（プロジェクト内）
    (Join-Path $script:RootDir "Modules\Pode\2.11.0\Private\Console.ps1"),
    (Join-Path $script:RootDir "Modules\Pode\2.12.1\Private\Console.ps1"),
    # システム（ユーザープロファイル）
    "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Pode\2.11.0\Private\Console.ps1",
    "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Pode\2.12.1\Private\Console.ps1"
)
foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $podeConsoleFile = $path
        break
    }
}
if ($podeConsoleFile -and (Test-Path $podeConsoleFile)) {
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
        } else {
        }
    } catch {
        # エラーを無視（意図的）
    }
} else {
}

try {
    Import-Module Pode -ErrorAction Stop
    Write-ControlLog "[MODULE] Podeモジュール読み込み完了"
} catch {

    try {
        Install-Module -Name Pode -RequiredVersion 2.11.0 -Scope CurrentUser -Force -AllowClobber

        # PowerShell 5.1対応: インストール後にPodeモジュールを修正
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
                } else {
                }
            } catch {
                # エラーを無視（意図的）
            }
        }

        Import-Module Pode -ErrorAction Stop

        # プロジェクトにコピー（次回起動時用）
        $installedPodePath = (Get-Module Pode -ListAvailable | Select-Object -First 1).ModuleBase

        if (Test-Path $installedPodePath) {
            $targetPath = Join-Path $script:RootDir "Modules"
            if (-not (Test-Path $targetPath)) {
                New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
            }

            Copy-Item -Path $installedPodePath -Destination (Join-Path $targetPath "Pode") -Recurse -Force
        }

    } catch {
        Stop-Transcript
        exit 1
    }
}

Write-ControlLog "[MODULE] モジュール読み込み完了"

# ============================================
# 2. 既存のPowerShell関数を読み込み
# ============================================


# 00_共通ユーティリティ_JSON操作.ps1
$jsonUtilPath = Join-Path $script:RootDir "00_共通ユーティリティ_JSON操作.ps1"
if (Test-Path $jsonUtilPath) {
    . $jsonUtilPath
} else {
}

# 09_変数機能_コードID管理JSON.ps1
$varManagePath = Join-Path $script:RootDir "09_変数機能_コードID管理JSON.ps1"
if (Test-Path $varManagePath) {
    . $varManagePath
} else {
}


Write-ControlLog "[MODULE] 基本モジュール読み込み完了"

# 静的ファイル配信用パス
$script:uiPath = Join-Path $script:RootDir "ui"

# ==============================================================================
# 3. Podeサーバーの起動と設定
# ==============================================================================


# PowerShell 5.1互換: グローバルスコープ変数を定義（$using:は使用不可）
# Start-PodeServerブロック内のスクリプトブロックからアクセスするため
$global:ServerPort = $Port
$global:ShouldOpenBrowser = $AutoOpenBrowser
$global:RootDir = $script:RootDir
$global:uiPath = $script:uiPath

# server.psd1の設定を読み込み（タイムアウト延長等）
# Podeは -RootPath で指定したディレクトリから server.psd1 を自動読み込み
$adapterPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$serverConfigPath = Join-Path $adapterPath "server.psd1"
if (Test-Path $serverConfigPath) {
} else {
}

# Start-PodeServer でサーバー設定とルート定義を行う
# -RootPath で adapter ディレクトリを指定し、server.psd1 を自動読み込み
Start-PodeServer -RootPath $adapterPath {

    # ============================================
    # 注: v2ファイルとAdapterファイルの読み込みは
    # CONVERTED_ROUTES.ps1内で行います（スコープ問題の回避のため）
    # ============================================

    # adapterディレクトリのパスを取得
    $adapterDir = Split-Path -Parent $PSCommandPath

    # エンドポイント設定
    Add-PodeEndpoint -Address localhost -Port $global:ServerPort -Protocol Http

    # ロギング設定
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # 設定が読み込まれたか確認
    $config = Get-PodeConfig
    if ($config -and $config.Server -and $config.Server.Request) {
        $timeout = $config.Server.Request.Timeout
    } else {
    }

    Write-ControlLog "[SERVER] Podeサーバーエンドポイント設定完了 (ポート: $global:ServerPort)"

    # CORS設定（PowerShell 5.1 / Pode 2.11.0互換：ミドルウェアを使用）
    Add-PodeMiddleware -Name 'CORS' -ScriptBlock {
        Add-PodeHeader -Name 'Access-Control-Allow-Origin' -Value '*'
        Add-PodeHeader -Name 'Access-Control-Allow-Methods' -Value 'GET, POST, PUT, DELETE, OPTIONS'
        Add-PodeHeader -Name 'Access-Control-Allow-Headers' -Value 'Content-Type, Authorization'
        return $true
    }

    Write-ControlLog "[CORS] CORS設定完了（ミドルウェア方式）"

    # CORSプリフライトリクエスト（OPTIONS）を処理
    Add-PodeRoute -Method Options -Path * -ScriptBlock {
        # ヘッダーは既にミドルウェアで設定済み
        Write-PodeTextResponse -Value 'OK' -StatusCode 200
    }

    Write-ControlLog "[CORS] OPTIONSプリフライトハンドラー設定完了"

    # ============================================
    # 4. 変換されたルート定義を読み込み
    # ============================================


    # PowerShell 5.1 / Pode 2.11.0互換: Podeの状態管理を使用して変数を共有
    # ルート定義内のスクリプトブロックからGet-PodeStateでアクセス可能
    Set-PodeState -Name 'RootDir' -Value $global:RootDir
    Set-PodeState -Name 'uiPath' -Value $global:uiPath
    Set-PodeState -Name 'ServerPort' -Value $global:ServerPort
    Set-PodeState -Name 'ShouldOpenBrowser' -Value $global:ShouldOpenBrowser

    # 変換されたルート定義ファイルを読み込み
    $convertedRoutesPath = Join-Path $adapterDir "CONVERTED_ROUTES.ps1"
    if (Test-Path $convertedRoutesPath) {
        . $convertedRoutesPath
        Write-ControlLog "[ROUTES] 全APIルート設定完了（50個）"
    } else {
    }

    # 静的ファイル配信（Pode 2.11.0の組み込み機能を使用）
    Add-PodeStaticRoute -Path '/' -Source $global:uiPath -Defaults @('index-legacy.html')
    Write-ControlLog "[STATIC] 静的ファイル配信設定完了"

    # ============================================
    # 5. サーバー起動完了メッセージ
    # ============================================


    Write-ControlLog "[SERVER] Podeサーバー起動成功 (ポート: $global:ServerPort)"


    # ブラウザ自動起動（Edge専用 - Chrome分離）
    if ($global:ShouldOpenBrowser) {
        Start-Sleep -Seconds 1
        $url = "http://localhost:$global:ServerPort/index-legacy.html"

        # Microsoft Edge専用で起動（Chromeと分離）
        $edgePaths = @(
            "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
            "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe"
        )

        # UIpowershell専用のプロファイルディレクトリ（ウィンドウサイズの記憶をリセット）
        $userDataDir = "$env:TEMP\UIpowershell-Edge-Profile"

        $edgeFound = $false
        foreach ($edgePath in $edgePaths) {
            if (Test-Path $edgePath) {
                # --app モードで起動（タブなし、独立ウインドウ、最大化、専用プロファイル）
                Start-Process $edgePath -ArgumentList "--app=$url --start-maximized --user-data-dir=`"$userDataDir`""
                $edgeFound = $true
                break
            }
        }

    }

} # Start-PodeServer ブロックの終了

# サーバーが停止した後のクリーンアップ
Stop-Transcript
