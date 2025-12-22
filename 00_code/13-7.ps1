function 13_7 {
    # Excel(操作) - シート追加
    # Excelファイルに新しいシートを追加

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # 設定ダイアログ
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "シート追加"
    $フォーム.Size = New-Object System.Drawing.Size(500, 220)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.MinimizeBox = $false
    $フォーム.Topmost = $true

    # ファイルパス
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "Excelファイルパス："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $パステキスト = New-Object System.Windows.Forms.TextBox
    $パステキスト.Location = New-Object System.Drawing.Point(20, 45)
    $パステキスト.Size = New-Object System.Drawing.Size(350, 25)

    $参照ボタン = New-Object System.Windows.Forms.Button
    $参照ボタン.Text = "参照..."
    $参照ボタン.Location = New-Object System.Drawing.Point(380, 43)
    $参照ボタン.Size = New-Object System.Drawing.Size(80, 28)
    $参照ボタン.Add_Click({
        $openDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openDialog.Filter = "Excelファイル (*.xlsx;*.xls)|*.xlsx;*.xls"
        if ($openDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $パステキスト.Text = $openDialog.FileName
        }
    })

    # 新シート名
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "新しいシート名："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $シートテキスト = New-Object System.Windows.Forms.TextBox
    $シートテキスト.Location = New-Object System.Drawing.Point(20, 110)
    $シートテキスト.Size = New-Object System.Drawing.Size(200, 25)
    $シートテキスト.Text = "Sheet2"

    # ボタン
    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(290, 140)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(390, 140)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $パステキスト, $参照ボタン, $ラベル2, $シートテキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    $ファイルパス = $パステキスト.Text
    $新シート名 = $シートテキスト.Text

    if ([string]::IsNullOrWhiteSpace($ファイルパス) -or [string]::IsNullOrWhiteSpace($新シート名)) {
        [System.Windows.Forms.MessageBox]::Show("ファイルパスとシート名は必須です。", "エラー")
        return $null
    }

    $entryString = @"
# シート追加: $新シート名
Excel操作_シート追加 -ファイルパス "$ファイルパス" -新シート名 "$新シート名"
"@

    return $entryString
}
