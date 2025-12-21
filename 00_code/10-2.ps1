
function 10_2 {
    # スクリーンショット保存：画面全体をファイルに保存

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "スクリーンショット保存設定"
    $フォーム.Size = New-Object System.Drawing.Size(480, 300)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # 保存先ファイルパス
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "保存先ファイルパス："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $保存先テキスト = New-Object System.Windows.Forms.TextBox
    $保存先テキスト.Location = New-Object System.Drawing.Point(20, 45)
    $保存先テキスト.Size = New-Object System.Drawing.Size(320, 25)
    $保存先テキスト.Text = "C:\temp\screenshot.png"

    $参照ボタン = New-Object System.Windows.Forms.Button
    $参照ボタン.Text = "参照..."
    $参照ボタン.Location = New-Object System.Drawing.Point(350, 43)
    $参照ボタン.Size = New-Object System.Drawing.Size(80, 25)
    $参照ボタン.Add_Click({
        $dialog = New-Object System.Windows.Forms.SaveFileDialog
        $dialog.Title = "保存先を選択"
        $dialog.Filter = "PNG画像 (*.png)|*.png|JPEG画像 (*.jpg)|*.jpg|BMP画像 (*.bmp)|*.bmp|すべてのファイル (*.*)|*.*"
        $dialog.DefaultExt = "png"
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $保存先テキスト.Text = $dialog.FileName
        }
    })

    # キャプチャ対象
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "キャプチャ対象："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $対象コンボ = New-Object System.Windows.Forms.ComboBox
    $対象コンボ.Location = New-Object System.Drawing.Point(20, 110)
    $対象コンボ.Size = New-Object System.Drawing.Size(200, 25)
    $対象コンボ.DropDownStyle = "DropDownList"
    $対象コンボ.Items.AddRange(@("プライマリモニター", "全モニター"))
    $対象コンボ.SelectedIndex = 0

    # 画面番号
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "画面番号（0から開始）："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $画面番号 = New-Object System.Windows.Forms.NumericUpDown
    $画面番号.Location = New-Object System.Drawing.Point(20, 175)
    $画面番号.Size = New-Object System.Drawing.Size(80, 25)
    $画面番号.Minimum = 0
    $画面番号.Maximum = 10
    $画面番号.Value = 0

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(260, 220)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(360, 220)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $保存先テキスト, $参照ボタン, $ラベル2, $対象コンボ, $ラベル3, $画面番号, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $保存パス = $保存先テキスト.Text
    $対象 = $対象コンボ.SelectedItem
    $画面No = $画面番号.Value

    if ($対象 -eq "全モニター") {
        $entryString = @"
# スクリーンショット保存: 全モニター → $保存パス
スクリーンショット保存 -保存パス "$保存パス" -全画面
"@
    } else {
        $entryString = @"
# スクリーンショット保存: 画面$画面No → $保存パス
スクリーンショット保存 -保存パス "$保存パス" -画面番号 $画面No
"@
    }

    return $entryString
}
