function 13_5 {
    # Excel(操作) - 罫線設定
    # Excelファイルの指定範囲に罫線を設定

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # 設定ダイアログ
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "罫線設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 350)
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

    # シート名
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "シート名（空欄で最初のシート）："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $シートテキスト = New-Object System.Windows.Forms.TextBox
    $シートテキスト.Location = New-Object System.Drawing.Point(20, 110)
    $シートテキスト.Size = New-Object System.Drawing.Size(200, 25)

    # セル範囲
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "セル範囲（例: A1:D10）："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $セルテキスト = New-Object System.Windows.Forms.TextBox
    $セルテキスト.Location = New-Object System.Drawing.Point(20, 175)
    $セルテキスト.Size = New-Object System.Drawing.Size(100, 25)
    $セルテキスト.Text = "A1:D10"

    # 線種
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "線種："
    $ラベル4.Location = New-Object System.Drawing.Point(20, 215)
    $ラベル4.AutoSize = $true

    $線種コンボ = New-Object System.Windows.Forms.ComboBox
    $線種コンボ.Location = New-Object System.Drawing.Point(20, 240)
    $線種コンボ.Size = New-Object System.Drawing.Size(120, 25)
    $線種コンボ.DropDownStyle = "DropDownList"
    $線種コンボ.Items.AddRange(@("Thin", "Medium", "Thick", "None"))
    $線種コンボ.SelectedIndex = 0

    # 位置
    $ラベル5 = New-Object System.Windows.Forms.Label
    $ラベル5.Text = "適用位置："
    $ラベル5.Location = New-Object System.Drawing.Point(160, 215)
    $ラベル5.AutoSize = $true

    $位置コンボ = New-Object System.Windows.Forms.ComboBox
    $位置コンボ.Location = New-Object System.Drawing.Point(160, 240)
    $位置コンボ.Size = New-Object System.Drawing.Size(120, 25)
    $位置コンボ.DropDownStyle = "DropDownList"
    $位置コンボ.Items.AddRange(@("All", "Outline", "Top", "Bottom", "Left", "Right"))
    $位置コンボ.SelectedIndex = 0

    # ボタン
    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(290, 270)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(390, 270)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $パステキスト, $参照ボタン, $ラベル2, $シートテキスト, $ラベル3, $セルテキスト, $ラベル4, $線種コンボ, $ラベル5, $位置コンボ, $OKボタン, $キャンセルボタン))
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
    $セル範囲 = $セルテキスト.Text
    $線種 = $線種コンボ.SelectedItem
    $位置 = $位置コンボ.SelectedItem

    if ([string]::IsNullOrWhiteSpace($ファイルパス) -or [string]::IsNullOrWhiteSpace($セル範囲)) {
        [System.Windows.Forms.MessageBox]::Show("ファイルパスとセル範囲は必須です。", "エラー")
        return $null
    }

    # 生成するコード
    $シートパラメータ = if ([string]::IsNullOrEmpty($シート名)) { "" } else { " -シート名 `"$シート名`"" }

    $entryString = @"
# 罫線設定: $セル範囲
Excel操作_罫線設定 -ファイルパス "$ファイルパス" -セル範囲 "$セル範囲" -線種 "$線種" -位置 "$位置"$シートパラメータ
"@

    return $entryString
}
