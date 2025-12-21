function 7_9 {
    # 通知トースト：Windowsの通知を表示

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "通知トースト設定"
    $フォーム.Size = New-Object System.Drawing.Size(450, 320)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # タイトル
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "通知タイトル："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $タイトルテキスト = New-Object System.Windows.Forms.TextBox
    $タイトルテキスト.Location = New-Object System.Drawing.Point(20, 45)
    $タイトルテキスト.Size = New-Object System.Drawing.Size(390, 25)
    $タイトルテキスト.Text = "処理完了"

    # メッセージ
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "通知メッセージ："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 80)
    $ラベル2.AutoSize = $true

    $メッセージテキスト = New-Object System.Windows.Forms.TextBox
    $メッセージテキスト.Location = New-Object System.Drawing.Point(20, 105)
    $メッセージテキスト.Size = New-Object System.Drawing.Size(390, 60)
    $メッセージテキスト.Multiline = $true
    $メッセージテキスト.Text = "処理が正常に完了しました。"

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

    # 表示時間
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "表示時間（ミリ秒）："
    $ラベル4.Location = New-Object System.Drawing.Point(200, 175)
    $ラベル4.AutoSize = $true

    $表示時間 = New-Object System.Windows.Forms.NumericUpDown
    $表示時間.Location = New-Object System.Drawing.Point(200, 200)
    $表示時間.Size = New-Object System.Drawing.Size(100, 25)
    $表示時間.Minimum = 1000
    $表示時間.Maximum = 30000
    $表示時間.Value = 5000
    $表示時間.Increment = 1000

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

    $フォーム.Controls.AddRange(@($ラベル1, $タイトルテキスト, $ラベル2, $メッセージテキスト, $ラベル3, $アイコンコンボ, $ラベル4, $表示時間, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $タイトル = $タイトルテキスト.Text
    $メッセージ = $メッセージテキスト.Text -replace "`r`n", "\n"
    $アイコン = switch ($アイコンコンボ.SelectedItem) {
        "情報" { "Info" }
        "警告" { "Warning" }
        "エラー" { "Error" }
        "なし" { "None" }
        default { "Info" }
    }
    $表示時間ミリ秒 = $表示時間.Value

    $entryString = @"
# 通知トースト: $タイトル
Add-Type -AssemblyName System.Windows.Forms
`$通知アイコン = New-Object System.Windows.Forms.NotifyIcon
`$通知アイコン.Icon = [System.Drawing.SystemIcons]::Information
`$通知アイコン.Visible = `$true
`$通知アイコン.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::$アイコン
`$通知アイコン.BalloonTipTitle = "$タイトル"
`$通知アイコン.BalloonTipText = "$メッセージ"
`$通知アイコン.ShowBalloonTip($表示時間ミリ秒)
Start-Sleep -Milliseconds $表示時間ミリ秒
`$通知アイコン.Dispose()
Write-Host "通知を表示しました: $タイトル" -ForegroundColor Green
"@

    return $entryString
}
