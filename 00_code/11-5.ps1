
function 11_5 {
    # フォルダ作成：新しいフォルダを作成

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "フォルダ作成設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 200)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # 作成先
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "作成するフォルダパス："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $フォルダパステキスト = New-Object System.Windows.Forms.TextBox
    $フォルダパステキスト.Location = New-Object System.Drawing.Point(20, 45)
    $フォルダパステキスト.Size = New-Object System.Drawing.Size(350, 25)

    $参照ボタン = New-Object System.Windows.Forms.Button
    $参照ボタン.Text = "参照..."
    $参照ボタン.Location = New-Object System.Drawing.Point(380, 43)
    $参照ボタン.Size = New-Object System.Drawing.Size(80, 25)
    $参照ボタン.Add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "親フォルダを選択"
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $フォルダパステキスト.Text = $dialog.SelectedPath + "\新しいフォルダ"
        }
    })

    # 説明
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "※親フォルダが存在しない場合も自動的に作成されます"
    $ラベル2.Location = New-Object System.Drawing.Point(20, 80)
    $ラベル2.AutoSize = $true
    $ラベル2.ForeColor = [System.Drawing.Color]::Gray

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(290, 120)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(390, 120)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $フォルダパステキスト, $参照ボタン, $ラベル2, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $フォルダパス = $フォルダパステキスト.Text

    $entryString = @"
# フォルダ作成: $フォルダパス
try {
    if (-not (Test-Path -Path "$フォルダパス")) {
        New-Item -Path "$フォルダパス" -ItemType Directory -Force | Out-Null
        Write-Host "フォルダを作成しました: $フォルダパス"
    } else {
        Write-Host "フォルダは既に存在します: $フォルダパス"
    }
} catch {
    Write-Host "エラー: フォルダ作成に失敗しました - `$(`$_.Exception.Message)" -ForegroundColor Red
}
"@

    return $entryString
}
