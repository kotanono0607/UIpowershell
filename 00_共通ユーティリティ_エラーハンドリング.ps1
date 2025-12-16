# ================================================================
# 00_共通ユーティリティ_エラーハンドリング.ps1
# ================================================================
# 責任: 統一されたエラーハンドリング機能を提供
#
# 含まれる関数:
#   - Show-ErrorDialog: エラーダイアログを表示
#   - Show-WarningDialog: 警告ダイアログを表示
#   - Show-InfoDialog: 情報ダイアログを表示
#   - Show-ConfirmDialog: 確認ダイアログを表示
#   - Write-ErrorLog: エラーをコンソールとログに記録
#
# 作成日: 2025-11-01
# ================================================================

<#
.SYNOPSIS
    エラーダイアログを表示する統一関数

.DESCRIPTION
    エラーメッセージをユーザーに表示し、オプションでコンソールにも出力します。

.PARAMETER Message
    表示するエラーメッセージ

.PARAMETER Title
    ダイアログのタイトル（既定値: "エラー"）

.PARAMETER ShowInConsole
    コンソールにもエラーを出力するか（既定値: $true）

.EXAMPLE
    Show-ErrorDialog "ファイルが見つかりません"
    Show-ErrorDialog "処理に失敗しました" -Title "処理エラー" -ShowInConsole $false
#>
function Show-ErrorDialog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$Title = "エラー",

        [Parameter(Mandatory=$false)]
        [bool]$ShowInConsole = $true
    )

    # コンソール出力
    if ($ShowInConsole) {
        Write-Host "[ERROR] $Message" -ForegroundColor Red
    }

    # Topmostなダミーフォームを作成してオーナーとして使用（ブラウザの前面に表示）
    $topmostForm = New-Object System.Windows.Forms.Form
    $topmostForm.TopMost = $true
    $topmostForm.StartPosition = "CenterScreen"
    $topmostForm.Size = New-Object System.Drawing.Size(0,0)
    $topmostForm.ShowInTaskbar = $false
    $topmostForm.Opacity = 0
    $topmostForm.Show()

    # ダイアログ表示
    [System.Windows.Forms.MessageBox]::Show(
        $topmostForm,
        $Message,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null

    $topmostForm.Close()
    $topmostForm.Dispose()
}

<#
.SYNOPSIS
    警告ダイアログを表示する統一関数

.DESCRIPTION
    警告メッセージをユーザーに表示し、オプションでコンソールにも出力します。

.PARAMETER Message
    表示する警告メッセージ

.PARAMETER Title
    ダイアログのタイトル（既定値: "警告"）

.PARAMETER ShowInConsole
    コンソールにも警告を出力するか（既定値: $true）

.EXAMPLE
    Show-WarningDialog "この操作は元に戻せません"
#>
function Show-WarningDialog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$Title = "警告",

        [Parameter(Mandatory=$false)]
        [bool]$ShowInConsole = $true
    )

    # コンソール出力
    if ($ShowInConsole) {
        Write-Host "[WARNING] $Message" -ForegroundColor Yellow
    }

    # Topmostなダミーフォームを作成してオーナーとして使用（ブラウザの前面に表示）
    $topmostForm = New-Object System.Windows.Forms.Form
    $topmostForm.TopMost = $true
    $topmostForm.StartPosition = "CenterScreen"
    $topmostForm.Size = New-Object System.Drawing.Size(0,0)
    $topmostForm.ShowInTaskbar = $false
    $topmostForm.Opacity = 0
    $topmostForm.Show()

    # ダイアログ表示
    [System.Windows.Forms.MessageBox]::Show(
        $topmostForm,
        $Message,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    ) | Out-Null

    $topmostForm.Close()
    $topmostForm.Dispose()
}

<#
.SYNOPSIS
    情報ダイアログを表示する統一関数

.DESCRIPTION
    情報メッセージをユーザーに表示します。

.PARAMETER Message
    表示する情報メッセージ

.PARAMETER Title
    ダイアログのタイトル（既定値: "情報"）

.PARAMETER ShowInConsole
    コンソールにも情報を出力するか（既定値: $false）

.EXAMPLE
    Show-InfoDialog "処理が完了しました"
#>
function Show-InfoDialog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$Title = "情報",

        [Parameter(Mandatory=$false)]
        [bool]$ShowInConsole = $false
    )

    # コンソール出力
    if ($ShowInConsole) {
        Write-Host "[INFO] $Message" -ForegroundColor Cyan
    }

    # Topmostなダミーフォームを作成してオーナーとして使用（ブラウザの前面に表示）
    $topmostForm = New-Object System.Windows.Forms.Form
    $topmostForm.TopMost = $true
    $topmostForm.StartPosition = "CenterScreen"
    $topmostForm.Size = New-Object System.Drawing.Size(0,0)
    $topmostForm.ShowInTaskbar = $false
    $topmostForm.Opacity = 0
    $topmostForm.Show()

    # ダイアログ表示
    [System.Windows.Forms.MessageBox]::Show(
        $topmostForm,
        $Message,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null

    $topmostForm.Close()
    $topmostForm.Dispose()
}

<#
.SYNOPSIS
    確認ダイアログを表示する統一関数

.DESCRIPTION
    確認メッセージを表示し、ユーザーの選択を返します。

.PARAMETER Message
    表示する確認メッセージ

.PARAMETER Title
    ダイアログのタイトル（既定値: "確認"）

.OUTPUTS
    System.Boolean
    ユーザーが「はい」を選択した場合は$true、「いいえ」を選択した場合は$false

.EXAMPLE
    $result = Show-ConfirmDialog "削除してもよろしいですか？"
    if ($result) { # 削除処理 }
#>
function Show-ConfirmDialog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$Title = "確認"
    )

    # Topmostなダミーフォームを作成してオーナーとして使用（ブラウザの前面に表示）
    $topmostForm = New-Object System.Windows.Forms.Form
    $topmostForm.TopMost = $true
    $topmostForm.StartPosition = "CenterScreen"
    $topmostForm.Size = New-Object System.Drawing.Size(0,0)
    $topmostForm.ShowInTaskbar = $false
    $topmostForm.Opacity = 0
    $topmostForm.Show()

    # ダイアログ表示
    $result = [System.Windows.Forms.MessageBox]::Show(
        $topmostForm,
        $Message,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    $topmostForm.Close()
    $topmostForm.Dispose()

    return ($result -eq [System.Windows.Forms.DialogResult]::Yes)
}

<#
.SYNOPSIS
    エラーをコンソールに記録する関数

.DESCRIPTION
    エラーメッセージをコンソールに出力します。ダイアログは表示しません。
    将来的にログファイルへの記録機能を追加できます。

.PARAMETER Message
    記録するエラーメッセージ

.PARAMETER Exception
    例外オブジェクト（オプション）

.EXAMPLE
    Write-ErrorLog "データベース接続エラー"
    Write-ErrorLog "ファイル読み込みエラー" -Exception $_
#>
function Write-ErrorLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        $Exception = $null
    )

    # コンソール出力
    Write-Host "[ERROR] $Message" -ForegroundColor Red

    if ($Exception) {
        Write-Host "  詳細: $($Exception.Exception.Message)" -ForegroundColor Red
        Write-Host "  場所: $($Exception.InvocationInfo.ScriptName):$($Exception.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    }

    # 将来的な拡張: ログファイルへの記録
    # $logPath = Join-Path $PSScriptRoot "error.log"
    # $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    # "$timestamp - $Message" | Out-File -FilePath $logPath -Append
}

<#
.SYNOPSIS
    警告をコンソールに記録する関数

.DESCRIPTION
    警告メッセージをコンソールに出力します。ダイアログは表示しません。

.PARAMETER Message
    記録する警告メッセージ

.EXAMPLE
    Write-WarningLog "設定ファイルが見つかりません。デフォルト設定を使用します。"
#>
function Write-WarningLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message
    )

    # コンソール出力
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}
