﻿
function 11_1 {
    # ファイルコピー：ファイルを別の場所にコピー

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "ファイルコピー設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 280)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # コピー元
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "コピー元ファイルパス："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $コピー元テキスト = New-Object System.Windows.Forms.TextBox
    $コピー元テキスト.Location = New-Object System.Drawing.Point(20, 45)
    $コピー元テキスト.Size = New-Object System.Drawing.Size(350, 25)

    $参照ボタン1 = New-Object System.Windows.Forms.Button
    $参照ボタン1.Text = "参照..."
    $参照ボタン1.Location = New-Object System.Drawing.Point(380, 43)
    $参照ボタン1.Size = New-Object System.Drawing.Size(80, 25)
    $参照ボタン1.Add_Click({
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
        $dialog.Title = "コピー元ファイルを選択"
        $dialog.Filter = "すべてのファイル (*.*)|*.*"
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $コピー元テキスト.Text = $dialog.FileName
        }
    })

    # コピー先
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "コピー先フォルダまたはファイルパス："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $コピー先テキスト = New-Object System.Windows.Forms.TextBox
    $コピー先テキスト.Location = New-Object System.Drawing.Point(20, 110)
    $コピー先テキスト.Size = New-Object System.Drawing.Size(350, 25)

    $参照ボタン2 = New-Object System.Windows.Forms.Button
    $参照ボタン2.Text = "参照..."
    $参照ボタン2.Location = New-Object System.Drawing.Point(380, 108)
    $参照ボタン2.Size = New-Object System.Drawing.Size(80, 25)
    $参照ボタン2.Add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "コピー先フォルダを選択"
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $コピー先テキスト.Text = $dialog.SelectedPath
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

    $フォーム.Controls.AddRange(@($ラベル1, $コピー元テキスト, $参照ボタン1, $ラベル2, $コピー先テキスト, $参照ボタン2, $上書きチェック, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $コピー元 = $コピー元テキスト.Text
    $コピー先 = $コピー先テキスト.Text
    $上書き = if ($上書きチェック.Checked) { "`$true" } else { "`$false" }

    $entryString = @"
# ファイルコピー: $コピー元 → $コピー先
try {
    if ($上書き) {
        Copy-Item -Path "$コピー元" -Destination "$コピー先" -Force
    } else {
        Copy-Item -Path "$コピー元" -Destination "$コピー先"
    }
    Write-Host "ファイルをコピーしました: $コピー元 → $コピー先"
} catch {
    Write-Host "エラー: ファイルコピーに失敗しました - `$(`$_.Exception.Message)" -ForegroundColor Red
}
"@

    return $entryString
}
