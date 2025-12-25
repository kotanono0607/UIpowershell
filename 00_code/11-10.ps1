﻿
function 11_10 {
    # パス結合：複数のパス要素を結合してフルパスを生成

    $変数ファイルパス = $global:JSONPath
    $変数 = @{}

    if (Test-Path -Path $変数ファイルパス) {
        $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "パス結合設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 320)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # ベースパス
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "ベースパス（フォルダ）："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $ベースパステキスト = New-Object System.Windows.Forms.TextBox
    $ベースパステキスト.Location = New-Object System.Drawing.Point(20, 45)
    $ベースパステキスト.Size = New-Object System.Drawing.Size(280, 25)

    $参照ボタン = New-Object System.Windows.Forms.Button
    $参照ボタン.Text = "参照..."
    $参照ボタン.Location = New-Object System.Drawing.Point(310, 43)
    $参照ボタン.Size = New-Object System.Drawing.Size(70, 25)
    $参照ボタン.Add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "フォルダを選択"
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $ベースパステキスト.Text = $dialog.SelectedPath
        }
    })

    $変数1コンボ = New-Object System.Windows.Forms.ComboBox
    $変数1コンボ.Location = New-Object System.Drawing.Point(390, 45)
    $変数1コンボ.Size = New-Object System.Drawing.Size(80, 25)
    $変数1コンボ.DropDownStyle = "DropDownList"
    $変数1コンボ.Items.Add("変数") | Out-Null
    foreach ($キー in $変数.Keys) { $変数1コンボ.Items.Add($キー) | Out-Null }
    $変数1コンボ.SelectedIndex = 0
    $変数1コンボ.Add_SelectedIndexChanged({
        if ($変数1コンボ.SelectedIndex -gt 0) {
            $ベースパステキスト.Text = "`$$($変数1コンボ.SelectedItem)"
        }
    })

    # サブパス
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "追加パス（ファイル名やサブフォルダ）："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $サブパステキスト = New-Object System.Windows.Forms.TextBox
    $サブパステキスト.Location = New-Object System.Drawing.Point(20, 110)
    $サブパステキスト.Size = New-Object System.Drawing.Size(280, 25)

    $変数2コンボ = New-Object System.Windows.Forms.ComboBox
    $変数2コンボ.Location = New-Object System.Drawing.Point(310, 110)
    $変数2コンボ.Size = New-Object System.Drawing.Size(80, 25)
    $変数2コンボ.DropDownStyle = "DropDownList"
    $変数2コンボ.Items.Add("変数") | Out-Null
    foreach ($キー in $変数.Keys) { $変数2コンボ.Items.Add($キー) | Out-Null }
    $変数2コンボ.SelectedIndex = 0
    $変数2コンボ.Add_SelectedIndexChanged({
        if ($変数2コンボ.SelectedIndex -gt 0) {
            $サブパステキスト.Text = "`$$($変数2コンボ.SelectedItem)"
        }
    })

    # 格納先変数
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "結果を格納する変数名："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $変数名テキスト = New-Object System.Windows.Forms.TextBox
    $変数名テキスト.Location = New-Object System.Drawing.Point(20, 175)
    $変数名テキスト.Size = New-Object System.Drawing.Size(200, 25)
    $変数名テキスト.Text = "結合パス"

    # プレビュー
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "※例: C:\Folder + file.txt → C:\Folder\file.txt"
    $ラベル4.Location = New-Object System.Drawing.Point(20, 215)
    $ラベル4.AutoSize = $true
    $ラベル4.ForeColor = [System.Drawing.Color]::Gray

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

    $フォーム.Controls.AddRange(@($ラベル1, $ベースパステキスト, $参照ボタン, $変数1コンボ, $ラベル2, $サブパステキスト, $変数2コンボ, $ラベル3, $変数名テキスト, $ラベル4, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $ベースパス = $ベースパステキスト.Text
    $サブパス = $サブパステキスト.Text
    $変数名 = $変数名テキスト.Text

    $entryString = @"
# パス結合: $ベースパス + $サブパス
`$$変数名 = Join-Path -Path $ベースパス -ChildPath $サブパス
変数を追加する -変数 `$変数 -名前 "$変数名" -型 "単一値" -値 `$$変数名
Write-Host "$変数名 = `$$変数名"
"@

    return $entryString
}
