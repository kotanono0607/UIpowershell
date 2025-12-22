function 13_3 {
    # Excel(操作) - 背景色設定
    # Excelファイルの指定セルの背景色を設定

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # 設定ダイアログ
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "背景色設定"
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
        $openDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openDialog.Filter = "Excelファイル (*.xlsx;*.xls)|*.xlsx;*.xls"
        $openDialog.Title = "Excelファイルを選択"
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
    $ラベル3.Text = "セル範囲（例: A1, A1:B5）："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $セルテキスト = New-Object System.Windows.Forms.TextBox
    $セルテキスト.Location = New-Object System.Drawing.Point(20, 175)
    $セルテキスト.Size = New-Object System.Drawing.Size(100, 25)
    $セルテキスト.Text = "A1"

    # 色選択
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "背景色："
    $ラベル4.Location = New-Object System.Drawing.Point(20, 215)
    $ラベル4.AutoSize = $true

    $色コンボ = New-Object System.Windows.Forms.ComboBox
    $色コンボ.Location = New-Object System.Drawing.Point(20, 240)
    $色コンボ.Size = New-Object System.Drawing.Size(150, 25)
    $色コンボ.DropDownStyle = "DropDownList"
    $色コンボ.Items.AddRange(@("Yellow", "LightGreen", "LightBlue", "LightPink", "Orange", "LightGray", "White", "Red", "Green", "Blue"))
    $色コンボ.SelectedIndex = 0

    $色選択ボタン = New-Object System.Windows.Forms.Button
    $色選択ボタン.Text = "色を選択..."
    $色選択ボタン.Location = New-Object System.Drawing.Point(180, 238)
    $色選択ボタン.Size = New-Object System.Drawing.Size(90, 28)
    $色選択ボタン.Add_Click({
        $colorDialog = New-Object System.Windows.Forms.ColorDialog
        if ($colorDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $script:選択色 = "#" + $colorDialog.Color.R.ToString("X2") + $colorDialog.Color.G.ToString("X2") + $colorDialog.Color.B.ToString("X2")
            $色コンボ.Items.Add($script:選択色)
            $色コンボ.SelectedItem = $script:選択色
        }
    })

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

    $フォーム.Controls.AddRange(@($ラベル1, $パステキスト, $参照ボタン, $ラベル2, $シートテキスト, $ラベル3, $セルテキスト, $ラベル4, $色コンボ, $色選択ボタン, $OKボタン, $キャンセルボタン))
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
    $色 = $色コンボ.SelectedItem

    if ([string]::IsNullOrWhiteSpace($ファイルパス) -or [string]::IsNullOrWhiteSpace($セル範囲)) {
        [System.Windows.Forms.MessageBox]::Show("ファイルパスとセル範囲は必須です。", "エラー")
        return $null
    }

    # 生成するコード
    $シートパラメータ = if ([string]::IsNullOrEmpty($シート名)) { "" } else { " -シート名 `"$シート名`"" }

    $entryString = @"
# 背景色設定: $セル範囲 を $色 に
Excel操作_背景色設定 -ファイルパス "$ファイルパス" -セル範囲 "$セル範囲" -色 "$色"$シートパラメータ
"@

    return $entryString
}
