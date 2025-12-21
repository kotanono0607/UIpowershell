
function 11_2 {
    # ファイル移動：ファイルを別の場所に移動

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "ファイル移動設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 280)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # 移動元
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "移動元ファイルパス："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $移動元テキスト = New-Object System.Windows.Forms.TextBox
    $移動元テキスト.Location = New-Object System.Drawing.Point(20, 45)
    $移動元テキスト.Size = New-Object System.Drawing.Size(350, 25)

    $参照ボタン1 = New-Object System.Windows.Forms.Button
    $参照ボタン1.Text = "参照..."
    $参照ボタン1.Location = New-Object System.Drawing.Point(380, 43)
    $参照ボタン1.Size = New-Object System.Drawing.Size(80, 25)
    $参照ボタン1.Add_Click({
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
        $dialog.Title = "移動元ファイルを選択"
        $dialog.Filter = "すべてのファイル (*.*)|*.*"
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $移動元テキスト.Text = $dialog.FileName
        }
    })

    # 移動先
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "移動先フォルダまたはファイルパス："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $移動先テキスト = New-Object System.Windows.Forms.TextBox
    $移動先テキスト.Location = New-Object System.Drawing.Point(20, 110)
    $移動先テキスト.Size = New-Object System.Drawing.Size(350, 25)

    $参照ボタン2 = New-Object System.Windows.Forms.Button
    $参照ボタン2.Text = "参照..."
    $参照ボタン2.Location = New-Object System.Drawing.Point(380, 108)
    $参照ボタン2.Size = New-Object System.Drawing.Size(80, 25)
    $参照ボタン2.Add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "移動先フォルダを選択"
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $移動先テキスト.Text = $dialog.SelectedPath
        }
    })

    # 上書きオプション
    $上書きチェック = New-Object System.Windows.Forms.CheckBox
    $上書きチェック.Text = "既存ファイルを上書きする"
    $上書きチェック.Location = New-Object System.Drawing.Point(20, 150)
    $上書きチェック.Size = New-Object System.Drawing.Size(200, 25)
    $上書きチェック.Checked = $true

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(290, 200)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(390, 200)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $移動元テキスト, $参照ボタン1, $ラベル2, $移動先テキスト, $参照ボタン2, $上書きチェック, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $移動元 = $移動元テキスト.Text
    $移動先 = $移動先テキスト.Text
    $上書き = if ($上書きチェック.Checked) { "`$true" } else { "`$false" }

    $entryString = @"
# ファイル移動: $移動元 → $移動先
try {
    if ($上書き) {
        Move-Item -Path "$移動元" -Destination "$移動先" -Force
    } else {
        Move-Item -Path "$移動元" -Destination "$移動先"
    }
    Write-Host "ファイルを移動しました: $移動元 → $移動先"
} catch {
    Write-Host "エラー: ファイル移動に失敗しました - `$(`$_.Exception.Message)" -ForegroundColor Red
}
"@

    return $entryString
}
