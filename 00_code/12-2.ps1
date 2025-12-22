function 12_2 {
    # ランダム待機：指定範囲内のランダムな秒数だけ待機

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "ランダム待機設定"
    $フォーム.Size = New-Object System.Drawing.Size(350, 200)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # 最小秒数
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "最小秒数："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 25)
    $ラベル1.AutoSize = $true

    $最小値 = New-Object System.Windows.Forms.NumericUpDown
    $最小値.Location = New-Object System.Drawing.Point(100, 22)
    $最小値.Size = New-Object System.Drawing.Size(80, 25)
    $最小値.Minimum = 1
    $最小値.Maximum = 300
    $最小値.Value = 1
    $最小値.DecimalPlaces = 1
    $最小値.Increment = 0.5

    # 最大秒数
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "最大秒数："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 65)
    $ラベル2.AutoSize = $true

    $最大値 = New-Object System.Windows.Forms.NumericUpDown
    $最大値.Location = New-Object System.Drawing.Point(100, 62)
    $最大値.Size = New-Object System.Drawing.Size(80, 25)
    $最大値.Minimum = 1
    $最大値.Maximum = 300
    $最大値.Value = 5
    $最大値.DecimalPlaces = 1
    $最大値.Increment = 0.5

    $説明ラベル = New-Object System.Windows.Forms.Label
    $説明ラベル.Text = "※ 指定範囲内でランダムな秒数だけ待機します"
    $説明ラベル.Location = New-Object System.Drawing.Point(20, 100)
    $説明ラベル.AutoSize = $true
    $説明ラベル.ForeColor = [System.Drawing.Color]::Gray

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(130, 125)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(230, 125)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $最小値, $ラベル2, $最大値, $説明ラベル, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $最小秒 = $最小値.Value
    $最大秒 = $最大値.Value

    # 最小が最大より大きい場合は入れ替え
    if ($最小秒 -gt $最大秒) {
        $tmp = $最小秒
        $最小秒 = $最大秒
        $最大秒 = $tmp
    }

    $entryString = @"
# ランダム待機: ${最小秒}秒〜${最大秒}秒
`$ランダム秒 = Get-Random -Minimum $最小秒 -Maximum $最大秒
Write-Host "ランダム待機: `$ランダム秒 秒" -ForegroundColor Cyan
Start-Sleep -Seconds `$ランダム秒
"@

    return $entryString
}
