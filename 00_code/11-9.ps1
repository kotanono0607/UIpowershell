
function 11_9 {
    # ファイル名変更：ファイルの名前を変更

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "ファイル名変更設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 250)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # 対象ファイル
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "変更対象のファイルパス："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $ファイルパステキスト = New-Object System.Windows.Forms.TextBox
    $ファイルパステキスト.Location = New-Object System.Drawing.Point(20, 45)
    $ファイルパステキスト.Size = New-Object System.Drawing.Size(350, 25)

    $参照ボタン = New-Object System.Windows.Forms.Button
    $参照ボタン.Text = "参照..."
    $参照ボタン.Location = New-Object System.Drawing.Point(380, 43)
    $参照ボタン.Size = New-Object System.Drawing.Size(80, 25)
    $参照ボタン.Add_Click({
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
        $dialog.Title = "ファイルを選択"
        $dialog.Filter = "すべてのファイル (*.*)|*.*"
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $ファイルパステキスト.Text = $dialog.FileName
        }
    })

    # 新しいファイル名
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "新しいファイル名（拡張子含む）："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $新ファイル名テキスト = New-Object System.Windows.Forms.TextBox
    $新ファイル名テキスト.Location = New-Object System.Drawing.Point(20, 110)
    $新ファイル名テキスト.Size = New-Object System.Drawing.Size(300, 25)

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(290, 165)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(390, 165)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $ファイルパステキスト, $参照ボタン, $ラベル2, $新ファイル名テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $ファイルパス = $ファイルパステキスト.Text
    $新ファイル名 = $新ファイル名テキスト.Text

    $entryString = @"
# ファイル名変更: $ファイルパス → $新ファイル名
try {
    if (Test-Path -Path "$ファイルパス") {
        Rename-Item -Path "$ファイルパス" -NewName "$新ファイル名"
        Write-Host "ファイル名を変更しました: $新ファイル名"
    } else {
        Write-Host "ファイルが見つかりません: $ファイルパス" -ForegroundColor Yellow
    }
} catch {
    Write-Host "エラー: ファイル名変更に失敗しました - `$(`$_.Exception.Message)" -ForegroundColor Red
}
"@

    return $entryString
}
