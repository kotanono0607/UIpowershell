function 7_8 {
    # 進捗表示：処理の進捗状況を表示

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "進捗表示設定"
    $フォーム.Size = New-Object System.Drawing.Size(450, 280)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # 操作タイプ
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "操作タイプ："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $操作コンボ = New-Object System.Windows.Forms.ComboBox
    $操作コンボ.Location = New-Object System.Drawing.Point(20, 45)
    $操作コンボ.Size = New-Object System.Drawing.Size(200, 25)
    $操作コンボ.DropDownStyle = "DropDownList"
    $操作コンボ.Items.AddRange(@("進捗開始", "進捗更新", "進捗終了"))
    $操作コンボ.SelectedIndex = 0

    # タイトル
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "ウィンドウタイトル："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $タイトルテキスト = New-Object System.Windows.Forms.TextBox
    $タイトルテキスト.Location = New-Object System.Drawing.Point(20, 110)
    $タイトルテキスト.Size = New-Object System.Drawing.Size(390, 25)
    $タイトルテキスト.Text = "処理中..."

    # メッセージ
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "表示メッセージ："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 145)
    $ラベル3.AutoSize = $true

    $メッセージテキスト = New-Object System.Windows.Forms.TextBox
    $メッセージテキスト.Location = New-Object System.Drawing.Point(20, 170)
    $メッセージテキスト.Size = New-Object System.Drawing.Size(390, 25)
    $メッセージテキスト.Text = "処理を実行しています。しばらくお待ちください..."

    # 操作タイプ変更時の処理
    $操作コンボ.Add_SelectedIndexChanged({
        $選択 = $操作コンボ.SelectedItem
        switch ($選択) {
            "進捗開始" {
                $タイトルテキスト.Enabled = $true
                $メッセージテキスト.Enabled = $true
            }
            "進捗更新" {
                $タイトルテキスト.Enabled = $false
                $メッセージテキスト.Enabled = $true
                $メッセージテキスト.Text = "処理中... (50%完了)"
            }
            "進捗終了" {
                $タイトルテキスト.Enabled = $false
                $メッセージテキスト.Enabled = $false
            }
        }
    })

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(230, 210)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(330, 210)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $操作コンボ, $ラベル2, $タイトルテキスト, $ラベル3, $メッセージテキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $操作タイプ = $操作コンボ.SelectedItem
    $タイトル = $タイトルテキスト.Text
    $メッセージ = $メッセージテキスト.Text

    switch ($操作タイプ) {
        "進捗開始" {
            $entryString = @"
# 進捗表示開始: $タイトル
`$global:進捗フォーム = New-Object System.Windows.Forms.Form
`$global:進捗フォーム.Text = "$タイトル"
`$global:進捗フォーム.Size = New-Object System.Drawing.Size(400, 120)
`$global:進捗フォーム.StartPosition = "CenterScreen"
`$global:進捗フォーム.FormBorderStyle = "FixedToolWindow"
`$global:進捗フォーム.TopMost = `$true
`$global:進捗ラベル = New-Object System.Windows.Forms.Label
`$global:進捗ラベル.Text = "$メッセージ"
`$global:進捗ラベル.Location = New-Object System.Drawing.Point(20, 20)
`$global:進捗ラベル.Size = New-Object System.Drawing.Size(350, 40)
`$global:進捗フォーム.Controls.Add(`$global:進捗ラベル)
`$global:進捗フォーム.Show()
[System.Windows.Forms.Application]::DoEvents()
Write-Host "進捗表示を開始しました" -ForegroundColor Cyan
"@
        }
        "進捗更新" {
            $entryString = @"
# 進捗表示更新
if (`$global:進捗ラベル) {
    `$global:進捗ラベル.Text = "$メッセージ"
    [System.Windows.Forms.Application]::DoEvents()
}
"@
        }
        "進捗終了" {
            $entryString = @"
# 進捗表示終了
if (`$global:進捗フォーム) {
    `$global:進捗フォーム.Close()
    `$global:進捗フォーム = `$null
    `$global:進捗ラベル = `$null
    Write-Host "進捗表示を終了しました" -ForegroundColor Cyan
}
"@
        }
    }

    return $entryString
}
