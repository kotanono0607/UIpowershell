# 必要な.NETアセンブリを読み込み
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# メニュー項目を作成するヘルパー関数
function メニュー項目作成 {
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
    param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Form]$フォーム,     # フォームオブジェクト
        [Parameter(Mandatory = $true)]
        [array]$メニュー構造                        # メニュー構造の配列
    )

    # ツールバーの作成
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
