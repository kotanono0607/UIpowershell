﻿
function 6_5 {
    # 文字列結合：複数の文字列を結合

    $変数ファイルパス = $global:JSONPath
    $変数 = @{}

    if (Test-Path -Path $変数ファイルパス) {
        $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "文字列結合設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 320)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # 結合元1
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "文字列1："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $文字列1テキスト = New-Object System.Windows.Forms.TextBox
    $文字列1テキスト.Location = New-Object System.Drawing.Point(20, 45)
    $文字列1テキスト.Size = New-Object System.Drawing.Size(200, 25)

    $変数1コンボ = New-Object System.Windows.Forms.ComboBox
    $変数1コンボ.Location = New-Object System.Drawing.Point(230, 45)
    $変数1コンボ.Size = New-Object System.Drawing.Size(150, 25)
    $変数1コンボ.DropDownStyle = "DropDownList"
    $変数1コンボ.Items.Add("（直接入力）") | Out-Null
    foreach ($キー in $変数.Keys) { $変数1コンボ.Items.Add($キー) | Out-Null }
    $変数1コンボ.SelectedIndex = 0

    # 結合元2
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "文字列2："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $文字列2テキスト = New-Object System.Windows.Forms.TextBox
    $文字列2テキスト.Location = New-Object System.Drawing.Point(20, 110)
    $文字列2テキスト.Size = New-Object System.Drawing.Size(200, 25)

    $変数2コンボ = New-Object System.Windows.Forms.ComboBox
    $変数2コンボ.Location = New-Object System.Drawing.Point(230, 110)
    $変数2コンボ.Size = New-Object System.Drawing.Size(150, 25)
    $変数2コンボ.DropDownStyle = "DropDownList"
    $変数2コンボ.Items.Add("（直接入力）") | Out-Null
    foreach ($キー in $変数.Keys) { $変数2コンボ.Items.Add($キー) | Out-Null }
    $変数2コンボ.SelectedIndex = 0

    # 区切り文字
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "間に挿入する文字（任意）："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $区切りテキスト = New-Object System.Windows.Forms.TextBox
    $区切りテキスト.Location = New-Object System.Drawing.Point(20, 175)
    $区切りテキスト.Size = New-Object System.Drawing.Size(100, 25)

    # 格納先
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "結果を格納する変数名："
    $ラベル4.Location = New-Object System.Drawing.Point(20, 215)
    $ラベル4.AutoSize = $true

    $格納先テキスト = New-Object System.Windows.Forms.TextBox
    $格納先テキスト.Location = New-Object System.Drawing.Point(20, 240)
    $格納先テキスト.Size = New-Object System.Drawing.Size(200, 25)
    $格納先テキスト.Text = "結合結果"

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(290, 240)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(390, 240)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $文字列1テキスト, $変数1コンボ, $ラベル2, $文字列2テキスト, $変数2コンボ, $ラベル3, $区切りテキスト, $ラベル4, $格納先テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $格納先 = $格納先テキスト.Text
    $区切り = $区切りテキスト.Text

    # 文字列1の取得方法
    if ($変数1コンボ.SelectedIndex -eq 0) {
        $文字列1式 = "`"$($文字列1テキスト.Text)`""
    } else {
        $文字列1式 = "`$($($変数1コンボ.SelectedItem))"
    }

    # 文字列2の取得方法
    if ($変数2コンボ.SelectedIndex -eq 0) {
        $文字列2式 = "`"$($文字列2テキスト.Text)`""
    } else {
        $文字列2式 = "`$($($変数2コンボ.SelectedItem))"
    }

    if ([string]::IsNullOrEmpty($区切り)) {
        $entryString = @"
# 文字列結合
`$$格納先 = $文字列1式 + $文字列2式
変数を追加する -変数 `$変数 -名前 "$格納先" -型 "単一値" -値 `$$格納先
Write-Host "$格納先 = `$$格納先"
"@
    } else {
        $entryString = @"
# 文字列結合（区切り文字あり）
`$$格納先 = $文字列1式 + "$区切り" + $文字列2式
変数を追加する -変数 `$変数 -名前 "$格納先" -型 "単一値" -値 `$$格納先
Write-Host "$格納先 = `$$格納先"
"@
    }

    return $entryString
}
