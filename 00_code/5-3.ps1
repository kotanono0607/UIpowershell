﻿function 5_3 {
    # ファイルを開く：関連付けられたアプリケーションでファイルを開く

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "ファイルを開く"
    $フォーム.Size = New-Object System.Drawing.Size(500, 200)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # ファイルパス
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "開くファイル："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $ファイルパステキスト = New-Object System.Windows.Forms.TextBox
    $ファイルパステキスト.Location = New-Object System.Drawing.Point(20, 45)
    $ファイルパステキスト.Size = New-Object System.Drawing.Size(350, 25)
    $ファイルパステキスト.Text = ""

    $参照ボタン = New-Object System.Windows.Forms.Button
    $参照ボタン.Text = "参照..."
    $参照ボタン.Location = New-Object System.Drawing.Point(380, 44)
    $参照ボタン.Size = New-Object System.Drawing.Size(80, 27)
    $参照ボタン.Add_Click({
        $openDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openDialog.Filter = "すべてのファイル (*.*)|*.*"
        $openDialog.Title = "開くファイルを選択"
        if ($openDialog.ShowDialog() -eq "OK") {
            $ファイルパステキスト.Text = $openDialog.FileName
        }
    })

    # 待機オプション
    $待機チェック = New-Object System.Windows.Forms.CheckBox
    $待機チェック.Text = "アプリケーションが終了するまで待機"
    $待機チェック.Location = New-Object System.Drawing.Point(20, 85)
    $待機チェック.AutoSize = $true

    $説明ラベル = New-Object System.Windows.Forms.Label
    $説明ラベル.Text = "※ ファイルの種類に応じた既定のアプリケーションで開きます"
    $説明ラベル.Location = New-Object System.Drawing.Point(20, 115)
    $説明ラベル.AutoSize = $true
    $説明ラベル.ForeColor = [System.Drawing.Color]::Gray

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(290, 130)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(390, 130)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $ファイルパステキスト, $参照ボタン, $待機チェック, $説明ラベル, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $ファイルパス = $ファイルパステキスト.Text

    if ([string]::IsNullOrWhiteSpace($ファイルパス)) {
        return "# キャンセルされました"
    }

    if ($待機チェック.Checked) {
        $entryString = @"
# ファイルを開く: $ファイルパス (終了待機)
`$プロセス = Start-Process -FilePath "$ファイルパス" -PassThru
`$プロセス.WaitForExit()
Write-Host "ファイルを開いたアプリケーションが終了しました" -ForegroundColor Green
"@
    } else {
        $entryString = @"
# ファイルを開く: $ファイルパス
Start-Process -FilePath "$ファイルパス"
Write-Host "ファイルを開きました: $ファイルパス" -ForegroundColor Green
"@
    }

    return $entryString
}
