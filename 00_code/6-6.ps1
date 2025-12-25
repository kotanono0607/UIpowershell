﻿
function 6_6 {
    # 文字列分割：文字列を区切り文字で分割して配列に

    $変数ファイルパス = $global:JSONPath
    $変数 = @{}

    if (Test-Path -Path $変数ファイルパス) {
        $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "文字列分割設定"
    $フォーム.Size = New-Object System.Drawing.Size(450, 280)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # 分割対象
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "分割する文字列（変数を選択または直接入力）："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $変数コンボ = New-Object System.Windows.Forms.ComboBox
    $変数コンボ.Location = New-Object System.Drawing.Point(20, 45)
    $変数コンボ.Size = New-Object System.Drawing.Size(200, 25)
    $変数コンボ.DropDownStyle = "DropDownList"
    $変数コンボ.Items.Add("（直接入力）") | Out-Null
    foreach ($キー in $変数.Keys) {
        $val = $変数[$キー]
        if (-not ($val -is [System.Array])) {
            $変数コンボ.Items.Add($キー) | Out-Null
        }
    }
    $変数コンボ.SelectedIndex = 0

    $文字列テキスト = New-Object System.Windows.Forms.TextBox
    $文字列テキスト.Location = New-Object System.Drawing.Point(230, 45)
    $文字列テキスト.Size = New-Object System.Drawing.Size(190, 25)

    # 区切り文字
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "区切り文字："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $区切りコンボ = New-Object System.Windows.Forms.ComboBox
    $区切りコンボ.Location = New-Object System.Drawing.Point(20, 110)
    $区切りコンボ.Size = New-Object System.Drawing.Size(150, 25)
    $区切りコンボ.Items.AddRange(@(",", "、", " ", "　", "`t", "/", "-", "_", "|", "その他"))
    $区切りコンボ.SelectedIndex = 0

    $区切りテキスト = New-Object System.Windows.Forms.TextBox
    $区切りテキスト.Location = New-Object System.Drawing.Point(180, 110)
    $区切りテキスト.Size = New-Object System.Drawing.Size(100, 25)
    $区切りテキスト.Enabled = $false

    $区切りコンボ.Add_SelectedIndexChanged({
        $区切りテキスト.Enabled = ($区切りコンボ.SelectedItem -eq "その他")
    })

    # 格納先
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "結果（配列）を格納する変数名："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $格納先テキスト = New-Object System.Windows.Forms.TextBox
    $格納先テキスト.Location = New-Object System.Drawing.Point(20, 175)
    $格納先テキスト.Size = New-Object System.Drawing.Size(200, 25)
    $格納先テキスト.Text = "分割結果"

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(240, 210)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(340, 210)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $変数コンボ, $文字列テキスト, $ラベル2, $区切りコンボ, $区切りテキスト, $ラベル3, $格納先テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $格納先 = $格納先テキスト.Text
    $区切り = if ($区切りコンボ.SelectedItem -eq "その他") { $区切りテキスト.Text } else { $区切りコンボ.SelectedItem }

    # 対象文字列
    if ($変数コンボ.SelectedIndex -eq 0) {
        $対象式 = "`"$($文字列テキスト.Text)`""
    } else {
        $対象式 = "`$$($変数コンボ.SelectedItem)"
    }

    $entryString = @"
# 文字列分割: 区切り文字 "$区切り"
`$$格納先 = $対象式 -split "$区切り"
変数を追加する -変数 `$変数 -名前 "$格納先" -型 "一次元" -値 `$$格納先
Write-Host "$格納先 の要素数: `$(`$$格納先.Count)"
"@

    return $entryString
}
