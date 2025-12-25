function 7_2 {
    # メッセージボックス表示：ユーザーにメッセージを表示

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "メッセージボックス設定"
    $フォーム.Size = New-Object System.Drawing.Size(450, 320)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # タイトル
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "タイトル："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $タイトルテキスト = New-Object System.Windows.Forms.TextBox
    $タイトルテキスト.Location = New-Object System.Drawing.Point(20, 45)
    $タイトルテキスト.Size = New-Object System.Drawing.Size(390, 25)
    $タイトルテキスト.Text = "お知らせ"

    # メッセージ
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "メッセージ："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 80)
    $ラベル2.AutoSize = $true

    $メッセージテキスト = New-Object System.Windows.Forms.TextBox
    $メッセージテキスト.Location = New-Object System.Drawing.Point(20, 105)
    $メッセージテキスト.Size = New-Object System.Drawing.Size(390, 60)
    $メッセージテキスト.Multiline = $true
    $メッセージテキスト.Text = "処理が完了しました。"

    # アイコン
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "アイコン："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 175)
    $ラベル3.AutoSize = $true

    $アイコンコンボ = New-Object System.Windows.Forms.ComboBox
    $アイコンコンボ.Location = New-Object System.Drawing.Point(20, 200)
    $アイコンコンボ.Size = New-Object System.Drawing.Size(150, 25)
    $アイコンコンボ.DropDownStyle = "DropDownList"
    $アイコンコンボ.Items.AddRange(@("情報", "警告", "エラー", "なし"))
    $アイコンコンボ.SelectedIndex = 0

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(230, 240)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(330, 240)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $タイトルテキスト, $ラベル2, $メッセージテキスト, $ラベル3, $アイコンコンボ, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $タイトル = $タイトルテキスト.Text
    $メッセージ = $メッセージテキスト.Text -replace "`r`n", "\n"
    $アイコン = switch ($アイコンコンボ.SelectedItem) {
        "情報" { "Information" }
        "警告" { "Warning" }
        "エラー" { "Error" }
        "なし" { "None" }
        default { "Information" }
    }

    $entryString = @"
# メッセージボックス表示: $タイトル
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show("$メッセージ", "$タイトル", "OK", "$アイコン")
"@

    return $entryString
}
