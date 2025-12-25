﻿
function 11_7 {
    # テキスト読込：テキストファイルを読み込み

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "テキスト読込設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 280)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # ファイルパス
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "読み込むファイルパス："
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
        $dialog.Title = "テキストファイルを選択"
        $dialog.Filter = "テキストファイル (*.txt)|*.txt|すべてのファイル (*.*)|*.*"
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $ファイルパステキスト.Text = $dialog.FileName
        }
    })

    # エンコーディング
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "文字コード："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $エンコーディングコンボ = New-Object System.Windows.Forms.ComboBox
    $エンコーディングコンボ.Location = New-Object System.Drawing.Point(20, 110)
    $エンコーディングコンボ.Size = New-Object System.Drawing.Size(150, 25)
    $エンコーディングコンボ.DropDownStyle = "DropDownList"
    $エンコーディングコンボ.Items.AddRange(@("UTF8", "UTF8BOM", "Shift_JIS", "Default"))
    $エンコーディングコンボ.SelectedIndex = 0

    # 格納先変数
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "結果を格納する変数名："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $変数名テキスト = New-Object System.Windows.Forms.TextBox
    $変数名テキスト.Location = New-Object System.Drawing.Point(20, 175)
    $変数名テキスト.Size = New-Object System.Drawing.Size(200, 25)
    $変数名テキスト.Text = "ファイル内容"

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

    $フォーム.Controls.AddRange(@($ラベル1, $ファイルパステキスト, $参照ボタン, $ラベル2, $エンコーディングコンボ, $ラベル3, $変数名テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $ファイルパス = $ファイルパステキスト.Text
    $エンコーディング = $エンコーディングコンボ.SelectedItem
    $変数名 = $変数名テキスト.Text

    $encParam = switch ($エンコーディング) {
        "UTF8" { "-Encoding UTF8" }
        "UTF8BOM" { "-Encoding UTF8BOM" }
        "Shift_JIS" { "-Encoding ([System.Text.Encoding]::GetEncoding('Shift_JIS'))" }
        "Default" { "" }
    }

    $entryString = @"
# テキスト読込: $ファイルパス ($エンコーディング)
try {
    `$$変数名 = Get-Content -Path "$ファイルパス" $encParam -Raw
    変数を追加する -変数 `$変数 -名前 "$変数名" -型 "単一値" -値 `$$変数名
    Write-Host "テキストファイルを読み込みました: $ファイルパス"
} catch {
    Write-Host "エラー: テキスト読込に失敗しました - `$(`$_.Exception.Message)" -ForegroundColor Red
}
"@

    return $entryString
}
