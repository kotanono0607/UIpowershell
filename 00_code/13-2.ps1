function 13_2 {
    # Excel(操作) - セル値設定
    # Excelファイルの指定セルに値を設定

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # 設定ダイアログ
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "セル値設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 320)
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
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "Excelファイル (*.xlsx)|*.xlsx"
        $saveDialog.Title = "Excelファイルを選択"
        if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $パステキスト.Text = $saveDialog.FileName
        }
    })

    # シート名
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "シート名（空欄で最初のシート）："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $シートテキスト = New-Object System.Windows.Forms.TextBox
    $シートテキスト.Location = New-Object System.Drawing.Point(20, 110)
    $シートテキスト.Size = New-Object System.Drawing.Size(200, 25)

    # セルアドレス
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "セルアドレス（例: A1, B2）："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $セルテキスト = New-Object System.Windows.Forms.TextBox
    $セルテキスト.Location = New-Object System.Drawing.Point(20, 175)
    $セルテキスト.Size = New-Object System.Drawing.Size(100, 25)
    $セルテキスト.Text = "A1"

    # 設定値
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "設定する値："
    $ラベル4.Location = New-Object System.Drawing.Point(20, 215)
    $ラベル4.AutoSize = $true

    $値テキスト = New-Object System.Windows.Forms.TextBox
    $値テキスト.Location = New-Object System.Drawing.Point(20, 240)
    $値テキスト.Size = New-Object System.Drawing.Size(250, 25)

    # ボタン
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

    $フォーム.Controls.AddRange(@($ラベル1, $パステキスト, $参照ボタン, $ラベル2, $シートテキスト, $ラベル3, $セルテキスト, $ラベル4, $値テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    $ファイルパス = $パステキスト.Text
    $シート名 = $シートテキスト.Text
    $セルアドレス = $セルテキスト.Text
    $設定値 = $値テキスト.Text

    if ([string]::IsNullOrWhiteSpace($ファイルパス) -or [string]::IsNullOrWhiteSpace($セルアドレス)) {
        [System.Windows.Forms.MessageBox]::Show("ファイルパスとセルアドレスは必須です。", "エラー")
        return $null
    }

    # 生成するコード
    $シートパラメータ = if ([string]::IsNullOrEmpty($シート名)) { "" } else { " -シート名 `"$シート名`"" }

    $entryString = @"
# セル値設定: $セルアドレス = $設定値
Excel操作_セル値設定 -ファイルパス "$ファイルパス" -セルアドレス "$セルアドレス" -値 "$設定値"$シートパラメータ
"@

    return $entryString
}
