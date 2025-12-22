function 3_5 {
    # キー連打：指定したキーを複数回連続で送信

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "キー連打"
    $フォーム.Size = New-Object System.Drawing.Size(400, 280)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # キー選択
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "連打するキー："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $キーコンボ = New-Object System.Windows.Forms.ComboBox
    $キーコンボ.Location = New-Object System.Drawing.Point(20, 45)
    $キーコンボ.Size = New-Object System.Drawing.Size(200, 25)
    $キーコンボ.DropDownStyle = "DropDownList"
    $キーリスト = @(
        "Enter", "Tab", "Space", "Esc", "Del", "Backspace",
        "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight",
        "Home", "End", "PageUp", "PageDown",
        "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"
    )
    $キーコンボ.Items.AddRange($キーリスト)
    $キーコンボ.SelectedIndex = 0

    # 回数
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "連打回数："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $回数 = New-Object System.Windows.Forms.NumericUpDown
    $回数.Location = New-Object System.Drawing.Point(20, 110)
    $回数.Size = New-Object System.Drawing.Size(80, 25)
    $回数.Minimum = 1
    $回数.Maximum = 100
    $回数.Value = 5

    # 間隔
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "間隔（ミリ秒）："
    $ラベル3.Location = New-Object System.Drawing.Point(150, 85)
    $ラベル3.AutoSize = $true

    $間隔 = New-Object System.Windows.Forms.NumericUpDown
    $間隔.Location = New-Object System.Drawing.Point(150, 110)
    $間隔.Size = New-Object System.Drawing.Size(80, 25)
    $間隔.Minimum = 50
    $間隔.Maximum = 5000
    $間隔.Value = 200

    # 説明
    $説明ラベル = New-Object System.Windows.Forms.Label
    $説明ラベル.Text = "※ 指定したキーを一定間隔で連続送信します"
    $説明ラベル.Location = New-Object System.Drawing.Point(20, 150)
    $説明ラベル.AutoSize = $true
    $説明ラベル.ForeColor = [System.Drawing.Color]::Gray

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(190, 200)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(290, 200)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $キーコンボ, $ラベル2, $回数, $ラベル3, $間隔, $説明ラベル, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $選択キー = $キーコンボ.SelectedItem
    $連打回数 = $回数.Value
    $間隔ミリ秒 = $間隔.Value

    $entryString = @"
# キー連打: $選択キー を $連打回数 回（間隔: ${間隔ミリ秒}ms）
Write-Host "キー連打開始: $選択キー × $連打回数 回" -ForegroundColor Cyan
for (`$i = 0; `$i -lt $連打回数; `$i++) {
    キー操作 -キーコマンド "$選択キー"
    Start-Sleep -Milliseconds $間隔ミリ秒
}
Write-Host "キー連打完了" -ForegroundColor Green
"@

    return $entryString
}
