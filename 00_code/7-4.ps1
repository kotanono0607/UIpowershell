function 7_4 {
    # 確認ダイアログ：Yes/Noでユーザーに確認を求める

    $変数ファイルパス = $global:JSONPath
    $変数 = @{}

    if (Test-Path -Path $変数ファイルパス) {
        $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "確認ダイアログ設定"
    $フォーム.Size = New-Object System.Drawing.Size(450, 320)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # タイトル
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "ダイアログタイトル："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $タイトルテキスト = New-Object System.Windows.Forms.TextBox
    $タイトルテキスト.Location = New-Object System.Drawing.Point(20, 45)
    $タイトルテキスト.Size = New-Object System.Drawing.Size(390, 25)
    $タイトルテキスト.Text = "確認"

    # メッセージ
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "確認メッセージ："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 80)
    $ラベル2.AutoSize = $true

    $メッセージテキスト = New-Object System.Windows.Forms.TextBox
    $メッセージテキスト.Location = New-Object System.Drawing.Point(20, 105)
    $メッセージテキスト.Size = New-Object System.Drawing.Size(390, 60)
    $メッセージテキスト.Multiline = $true
    $メッセージテキスト.Text = "この処理を続行しますか？"

    # アイコン
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "アイコン："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 175)
    $ラベル3.AutoSize = $true

    $アイコンコンボ = New-Object System.Windows.Forms.ComboBox
    $アイコンコンボ.Location = New-Object System.Drawing.Point(20, 200)
    $アイコンコンボ.Size = New-Object System.Drawing.Size(150, 25)
    $アイコンコンボ.DropDownStyle = "DropDownList"
    $アイコンコンボ.Items.AddRange(@("質問", "警告", "情報"))
    $アイコンコンボ.SelectedIndex = 0

    # 結果変数名
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "結果を格納する変数名："
    $ラベル4.Location = New-Object System.Drawing.Point(200, 175)
    $ラベル4.AutoSize = $true

    $変数名テキスト = New-Object System.Windows.Forms.TextBox
    $変数名テキスト.Location = New-Object System.Drawing.Point(200, 200)
    $変数名テキスト.Size = New-Object System.Drawing.Size(150, 25)
    $変数名テキスト.Text = "確認結果"

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(230, 250)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(330, 250)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $タイトルテキスト, $ラベル2, $メッセージテキスト, $ラベル3, $アイコンコンボ, $ラベル4, $変数名テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $タイトル = $タイトルテキスト.Text
    $メッセージ = $メッセージテキスト.Text -replace "`r`n", "\n"
    $アイコン = switch ($アイコンコンボ.SelectedItem) {
        "質問" { "Question" }
        "警告" { "Warning" }
        "情報" { "Information" }
        default { "Question" }
    }
    $変数名 = $変数名テキスト.Text

    $entryString = @"
# 確認ダイアログ: $タイトル
Add-Type -AssemblyName System.Windows.Forms
`$ダイアログ結果 = [System.Windows.Forms.MessageBox]::Show("$メッセージ", "$タイトル", "YesNo", "$アイコン")
`$$変数名 = (`$ダイアログ結果 -eq "Yes")
変数を追加する -変数 `$変数 -名前 "$変数名" -型 "単一値" -値 `$$変数名
if (`$$変数名) {
    Write-Host "ユーザーが「はい」を選択しました" -ForegroundColor Green
} else {
    Write-Host "ユーザーが「いいえ」を選択しました" -ForegroundColor Yellow
}
"@

    return $entryString
}
