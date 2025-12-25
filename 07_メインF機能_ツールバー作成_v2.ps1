# ============================================
# 07_メインF機能_ツールバー作成_v2.ps1
# UI非依存版 - HTML/JS移行対応
# ============================================
# 変更内容:
#   - メニュー構造をデータとして管理する関数を追加
#   - メニューアクションを登録・実行できる仕組みを追加
#   - REST API経由でメニュー構造をJSON形式で返却可能
#   - 既存のWindows Forms版も維持（後方互換性）
#
# 互換性:
#   - 既存のWindows Forms版でも動作
#   - HTML/JS版でも動作（REST API経由）
# ============================================

# グローバルメニューアクション辞書の初期化
if (-not $global:menuActions) {
    $global:menuActions = @{}
}

# ============================================
# 新しい関数（UI非依存版 - HTML/JS対応）
# ============================================

function Get-MenuStructure_v2 {
    <#
    .SYNOPSIS
    メニュー構造をデータとして取得（UI非依存版）

    .DESCRIPTION
    ツールバーのメニュー構造を、Windows Formsオブジェクトではなく
    ハッシュテーブル/配列として返します。
    HTML/JS版のREST API経由で呼び出すことを想定しています。

    .PARAMETER MenuStructure
    メニュー構造の配列（元のメニュー構造と同じ形式）

    .PARAMETER IncludeActionIds
    アクションIDを含めるかどうか（デフォルト: $true）

    .EXAMPLE
    $menus = @(
        @{
            名前 = "ファイル"
            ツールチップ = "ファイル操作"
            項目 = @(
                @{ テキスト = "開く"; アクション = { Write-Host "開く" } },
                @{ テキスト = "保存"; アクション = { Write-Host "保存" } }
            )
        }
    )
    $result = Get-MenuStructure_v2 -MenuStructure $menus
    #>
    param (
        [Parameter(Mandatory=$true)]
        [array]$MenuStructure,

        [bool]$IncludeActionIds = $true
    )

    try {
        $menuData = @()

        foreach ($メニュー in $MenuStructure) {
            $menuInfo = @{
                name = $メニュー.名前
                tooltip = if ($メニュー.ツールチップ) { $メニュー.ツールチップ } else { "" }
                items = @()
            }

            if ($メニュー.項目) {
                foreach ($項目 in $メニュー.項目) {
                    $itemInfo = @{
                        text = $項目.テキスト
                    }

                    # アクションIDを生成（メニュー名_項目名）
                    if ($IncludeActionIds) {
                        $actionId = "$($メニュー.名前)_$($項目.テキスト)"
                        $itemInfo.actionId = $actionId

                        # アクションを登録
                        if ($項目.アクション) {
                            Register-MenuAction_v2 -ActionId $actionId -Action $項目.アクション
                        }
                    }

                    $menuInfo.items += $itemInfo
                }
            }

            $menuData += $menuInfo
        }

        return @{
            success = $true
            menus = $menuData
            count = $menuData.Count
        }

    } catch {
        return @{
            success = $false
            error = "メニュー構造の取得に失敗しました: $($_.Exception.Message)"
        }
    }
}


function Register-MenuAction_v2 {
    <#
    .SYNOPSIS
    メニューアクションを登録（UI非依存版）

    .DESCRIPTION
    メニュー項目のアクション（ScriptBlock）を、アクションIDで登録します。
    HTML/JS版からアクションIDを指定してアクションを実行できるようにします。

    .PARAMETER ActionId
    アクションID（一意な識別子）

    .PARAMETER Action
    実行するアクション（ScriptBlock）

    .EXAMPLE
    Register-MenuAction_v2 -ActionId "file_open" -Action { Write-Host "開く" }
    #>
    param (
        [Parameter(Mandatory=$true)]
        [string]$ActionId,

        [Parameter(Mandatory=$true)]
        [scriptblock]$Action
    )

    try {
        # グローバルアクション辞書に登録
        $global:menuActions[$ActionId] = $Action

        return @{
            success = $true
            message = "アクション '$ActionId' を登録しました"
            actionId = $ActionId
        }

    } catch {
        return @{
            success = $false
            error = "アクションの登録に失敗しました: $($_.Exception.Message)"
        }
    }
}


function Execute-MenuAction_v2 {
    <#
    .SYNOPSIS
    メニューアクションを実行（UI非依存版）

    .DESCRIPTION
    登録されたアクションIDを指定して、アクションを実行します。
    HTML/JS版からREST API経由で呼び出すことを想定しています。

    .PARAMETER ActionId
    実行するアクションID

    .PARAMETER Parameters
    アクションに渡すパラメータ（オプション）

    .EXAMPLE
    Execute-MenuAction_v2 -ActionId "file_open"
    Execute-MenuAction_v2 -ActionId "file_save" -Parameters @{ path = "C:\test.txt" }
    #>
    param (
        [Parameter(Mandatory=$true)]
        [string]$ActionId,

        [hashtable]$Parameters = @{}
    )

    try {
        # アクションの存在確認
        if (-not $global:menuActions.ContainsKey($ActionId)) {
            return @{
                success = $false
                error = "アクション '$ActionId' が見つかりません"
            }
        }

        # アクションを実行
        $action = $global:menuActions[$ActionId]

        # パラメータがある場合は渡す
        if ($Parameters.Count -gt 0) {
            $result = & $action @Parameters
        } else {
            $result = & $action
        }

        return @{
            success = $true
            message = "アクション '$ActionId' を実行しました"
            actionId = $ActionId
            result = $result
        }

    } catch {
        return @{
            success = $false
            error = "アクションの実行に失敗しました: $($_.Exception.Message)"
            stackTrace = $_.ScriptStackTrace
        }
    }
}


function Get-RegisteredActions_v2 {
    <#
    .SYNOPSIS
    登録されているアクション一覧を取得（UI非依存版）

    .DESCRIPTION
    グローバルアクション辞書に登録されているすべてのアクションIDを取得します。

    .EXAMPLE
    $result = Get-RegisteredActions_v2
    #>
    param ()

    try {
        $actionIds = @($global:menuActions.Keys)

        return @{
            success = $true
            actionIds = $actionIds
            count = $actionIds.Count
        }

    } catch {
        return @{
            success = $false
            error = "アクション一覧の取得に失敗しました: $($_.Exception.Message)"
        }
    }
}


function Clear-MenuActions_v2 {
    <#
    .SYNOPSIS
    登録されているアクションをすべてクリア（UI非依存版）

    .DESCRIPTION
    グローバルアクション辞書をクリアします。

    .EXAMPLE
    Clear-MenuActions_v2
    #>
    param ()

    try {
        $count = $global:menuActions.Count
        $global:menuActions = @{}

        return @{
            success = $true
            message = "$count 個のアクションをクリアしました"
            count = $count
        }

    } catch {
        return @{
            success = $false
            error = "アクションのクリアに失敗しました: $($_.Exception.Message)"
        }
    }
}


# ============================================
# 既存の関数（Windows Forms版 - 後方互換性維持）
# ============================================

# 必要な.NETアセンブリを読み込み
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# メニュー項目を作成するヘルパー関数
function メニュー項目作成 {
    <#
    .SYNOPSIS
    Windows Formsメニュー項目を作成（既存のWindows Forms版）

    .DESCRIPTION
    この関数は既存のWindows Forms版との互換性維持のために残されています。
    HTML/JS版では使用しません。
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$テキスト,         # メニュー項目のテキスト
        [Parameter(Mandatory = $true)]
        [scriptblock]$アクション    # クリック時のアクション
    )

    $項目 = New-Object System.Windows.Forms.ToolStripMenuItem
    $項目.Text = $テキスト
    $項目.Add_Click($アクション)
    return $項目
}

# 任意のメニューを作成してツールバーに追加する関数
function メニューを追加 {
    <#
    .SYNOPSIS
    Windows Formsツールバーにメニューを追加（既存のWindows Forms版）

    .DESCRIPTION
    この関数は既存のWindows Forms版との互換性維持のために残されています。
    HTML/JS版では使用しません。
    #>
    param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.ToolStrip]$ツールバー,  # ツールバーオブジェクト
        [Parameter(Mandatory = $true)]
        [string]$メニュー名,                         # メニューの名前（表示テキスト）
        [Parameter(Mandatory = $true)]
        [array]$項目リスト,                            # メニュー項目の配列
        [string]$ツールチップ = ""                     # ツールチップのオプション
    )

    $ドロップダウンボタン = New-Object System.Windows.Forms.ToolStripDropDownButton
    $ドロップダウンボタン.Text = $メニュー名
    $ドロップダウンボタン.ToolTipText = $ツールチップ  # 親メニューにツールチップを設定

    foreach ($項目 in $項目リスト) {
        if ($項目.テキスト -and $項目.アクション) {
            $ドロップダウンボタン.DropDownItems.Add( (メニュー項目作成 -テキスト $項目.テキスト -アクション $項目.アクション) ) | Out-Null
        }
    }

    $ツールバー.Items.Add($ドロップダウンボタン) | Out-Null
}

# ツールバーを作成する関数
function ツールバーを追加 {
    <#
    .SYNOPSIS
    Windows Formsフォームにツールバーを追加（既存のWindows Forms版）

    .DESCRIPTION
    この関数は既存のWindows Forms版との互換性維持のために残されています。
    HTML/JS版では使用しません。

    .PARAMETER フォーム
    フォームオブジェクト

    .PARAMETER メニュー構造
    メニュー構造の配列

    .PARAMETER RegisterActions
    v2関数にアクションを登録するかどうか（デフォルト: $true）
    $true の場合、メニューアクションをグローバル辞書に登録します。

    .EXAMPLE
    # Windows Forms版
    ツールバーを追加 -フォーム $form -メニュー構造 $menus

    # v2関数にも登録する場合（推奨）
    ツールバーを追加 -フォーム $form -メニュー構造 $menus -RegisterActions $true
    #>
    param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Form]$フォーム,     # フォームオブジェクト
        [Parameter(Mandatory = $true)]
        [array]$メニュー構造,                        # メニュー構造の配列
        [bool]$RegisterActions = $true             # 🆕 v2関数にアクションを登録
    )

    # 🆕 v2関数にアクションを登録（オプション）
    if ($RegisterActions) {
        Get-MenuStructure_v2 -MenuStructure $メニュー構造 | Out-Null
    }

    # ツールバーの作成（既存のコード）
    $ツールバー = New-Object System.Windows.Forms.ToolStrip
    $ツールバー.Dock = [System.Windows.Forms.DockStyle]::Top  # フォームの一番上に配置
    $ツールバー.ShowItemToolTips = $true                     # ツールチップを有効化

    # 各メニューを追加
    foreach ($メニュー in $メニュー構造) {
        メニューを追加 -ツールバー $ツールバー `
                    -メニュー名 $メニュー.名前 `
                    -項目リスト $メニュー.項目 `
                    -ツールチップ $メニュー.ツールチップ
    }

    # ツールバーをフォームに追加
    $フォーム.Controls.Add($ツールバー)
}
