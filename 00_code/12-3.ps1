﻿function 12_3 {
    # ログ出力：ログファイルにメッセージを出力

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "ログ出力設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 300)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # ログメッセージ
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "ログメッセージ："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $メッセージテキスト = New-Object System.Windows.Forms.TextBox
    $メッセージテキスト.Location = New-Object System.Drawing.Point(20, 45)
    $メッセージテキスト.Size = New-Object System.Drawing.Size(440, 60)
    $メッセージテキスト.Multiline = $true
    $メッセージテキスト.Text = "処理を実行しました"

    # ログレベル
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "ログレベル："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 115)
    $ラベル2.AutoSize = $true

    $ログレベルコンボ = New-Object System.Windows.Forms.ComboBox
    $ログレベルコンボ.Location = New-Object System.Drawing.Point(20, 140)
    $ログレベルコンボ.Size = New-Object System.Drawing.Size(120, 25)
    $ログレベルコンボ.DropDownStyle = "DropDownList"
    $ログレベルコンボ.Items.AddRange(@("INFO", "WARNING", "ERROR", "DEBUG"))
    $ログレベルコンボ.SelectedIndex = 0

    # ログファイルパス
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "ログファイル（省略時: フォルダ内のlog.txt）："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 180)
    $ラベル3.AutoSize = $true

    $ログパステキスト = New-Object System.Windows.Forms.TextBox
    $ログパステキスト.Location = New-Object System.Drawing.Point(20, 205)
    $ログパステキスト.Size = New-Object System.Drawing.Size(350, 25)
    $ログパステキスト.Text = ""

    $参照ボタン = New-Object System.Windows.Forms.Button
    $参照ボタン.Text = "参照..."
    $参照ボタン.Location = New-Object System.Drawing.Point(380, 204)
    $参照ボタン.Size = New-Object System.Drawing.Size(80, 27)
    $参照ボタン.Add_Click({
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "テキストファイル (*.txt)|*.txt|すべてのファイル (*.*)|*.*"
        $saveDialog.DefaultExt = "txt"
        $saveDialog.FileName = "log.txt"
        if ($saveDialog.ShowDialog() -eq "OK") {
            $ログパステキスト.Text = $saveDialog.FileName
        }
    })

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(280, 240)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(380, 240)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $メッセージテキスト, $ラベル2, $ログレベルコンボ, $ラベル3, $ログパステキスト, $参照ボタン, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $メッセージ = $メッセージテキスト.Text -replace "`r`n", " "
    $ログレベル = $ログレベルコンボ.SelectedItem
    $ログパス = $ログパステキスト.Text

    $ログファイル指定 = if ($ログパス) {
        "`"$ログパス`""
    } else {
        "(Join-Path `"`$(`$global:folderPath)`" `"log.txt`")"
    }

    $色 = switch ($ログレベル) {
        "INFO" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "DEBUG" { "Cyan" }
        default { "White" }
    }

    $entryString = @"
# ログ出力: [$ログレベル] $メッセージ
`$ログファイルパス = $ログファイル指定
`$ログ時刻 = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
`$ログ内容 = "[`$ログ時刻] [$ログレベル] $メッセージ"
Add-Content -Path `$ログファイルパス -Value `$ログ内容 -Encoding UTF8
Write-Host `$ログ内容 -ForegroundColor $色
"@

    return $entryString
}
