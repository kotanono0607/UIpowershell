﻿
function 6_4 {
    # 変数設定：単一の値を変数に設定

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "変数設定"
    $フォーム.Size = New-Object System.Drawing.Size(450, 250)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # 変数名
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "変数名："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $変数名テキスト = New-Object System.Windows.Forms.TextBox
    $変数名テキスト.Location = New-Object System.Drawing.Point(20, 45)
    $変数名テキスト.Size = New-Object System.Drawing.Size(200, 25)
    $変数名テキスト.Text = "新規変数"

    # 値
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "設定する値："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $値テキスト = New-Object System.Windows.Forms.TextBox
    $値テキスト.Location = New-Object System.Drawing.Point(20, 110)
    $値テキスト.Size = New-Object System.Drawing.Size(390, 25)

    # 保存オプション
    $保存チェック = New-Object System.Windows.Forms.CheckBox
    $保存チェック.Text = "変数ファイル(JSON)にも保存する"
    $保存チェック.Location = New-Object System.Drawing.Point(20, 145)
    $保存チェック.Size = New-Object System.Drawing.Size(300, 25)
    $保存チェック.Checked = $true

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(240, 175)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(340, 175)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $変数名テキスト, $ラベル2, $値テキスト, $保存チェック, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $変数名 = $変数名テキスト.Text
    $値 = $値テキスト.Text
    $保存する = $保存チェック.Checked

    if ($保存する) {
        $entryString = @"
# 変数設定: $変数名 = "$値"
`$$変数名 = "$値"
変数を追加する -変数 `$変数 -名前 "$変数名" -型 "単一値" -値 `$$変数名
Write-Host "$変数名 = `$$変数名"
"@
    } else {
        $entryString = @"
# 変数設定: $変数名 = "$値"
`$$変数名 = "$値"
Write-Host "$変数名 = `$$変数名"
"@
    }

    return $entryString
}
