function 13_4 {
    # Excel(操作) - フォント設定
    # Excelファイルの指定セルのフォントを設定

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # 設定ダイアログ
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "フォント設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 400)
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
    $ラベル3.Text = "セル範囲（例: A1, A1:B5）："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $セルテキスト = New-Object System.Windows.Forms.TextBox
    $セルテキスト.Location = New-Object System.Drawing.Point(20, 175)
    $セルテキスト.Size = New-Object System.Drawing.Size(100, 25)
    $セルテキスト.Text = "A1"

    # フォント色
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "フォント色："
    $ラベル4.Location = New-Object System.Drawing.Point(20, 215)
    $ラベル4.AutoSize = $true

    $色コンボ = New-Object System.Windows.Forms.ComboBox
    $色コンボ.Location = New-Object System.Drawing.Point(20, 240)
    $色コンボ.Size = New-Object System.Drawing.Size(120, 25)
    $色コンボ.DropDownStyle = "DropDownList"
    $色コンボ.Items.AddRange(@("（変更なし）", "Black", "Red", "Blue", "Green", "Orange", "Purple", "Gray"))
    $色コンボ.SelectedIndex = 0

    # 太字
    $太字チェック = New-Object System.Windows.Forms.CheckBox
    $太字チェック.Text = "太字"
    $太字チェック.Location = New-Object System.Drawing.Point(160, 242)
    $太字チェック.AutoSize = $true

    # 斜体
    $斜体チェック = New-Object System.Windows.Forms.CheckBox
    $斜体チェック.Text = "斜体"
    $斜体チェック.Location = New-Object System.Drawing.Point(220, 242)
    $斜体チェック.AutoSize = $true

    # フォントサイズ
    $ラベル5 = New-Object System.Windows.Forms.Label
    $ラベル5.Text = "フォントサイズ："
    $ラベル5.Location = New-Object System.Drawing.Point(20, 280)
    $ラベル5.AutoSize = $true

    $サイズコンボ = New-Object System.Windows.Forms.ComboBox
    $サイズコンボ.Location = New-Object System.Drawing.Point(20, 305)
    $サイズコンボ.Size = New-Object System.Drawing.Size(80, 25)
    $サイズコンボ.DropDownStyle = "DropDownList"
    $サイズコンボ.Items.AddRange(@("（変更なし）", "8", "9", "10", "11", "12", "14", "16", "18", "20", "24", "28", "36"))
    $サイズコンボ.SelectedIndex = 0

    # ボタン
    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(290, 320)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(390, 320)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $パステキスト, $参照ボタン, $ラベル2, $シートテキスト, $ラベル3, $セルテキスト, $ラベル4, $色コンボ, $太字チェック, $斜体チェック, $ラベル5, $サイズコンボ, $OKボタン, $キャンセルボタン))
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
    $フォント色 = $色コンボ.SelectedItem
    $太字 = $太字チェック.Checked
    $斜体 = $斜体チェック.Checked
    $サイズ = $サイズコンボ.SelectedItem

    if ([string]::IsNullOrWhiteSpace($ファイルパス) -or [string]::IsNullOrWhiteSpace($セル範囲)) {
        [System.Windows.Forms.MessageBox]::Show("ファイルパスとセル範囲は必須です。", "エラー")
        return $null
    }

    # パラメータ構築
    $params = @()
    $params += "-ファイルパス `"$ファイルパス`""
    $params += "-セル範囲 `"$セル範囲`""
    if (-not [string]::IsNullOrEmpty($シート名)) { $params += "-シート名 `"$シート名`"" }
    if ($フォント色 -ne "（変更なし）") { $params += "-フォント色 `"$フォント色`"" }
    if ($太字) { $params += "-太字" }
    if ($斜体) { $params += "-斜体" }
    if ($サイズ -ne "（変更なし）") { $params += "-サイズ $サイズ" }

    $entryString = @"
# フォント設定: $セル範囲
Excel操作_フォント設定 $($params -join " ")
"@

    return $entryString
}
