
function 11_8 {
    # テキスト書込：テキストファイルに書き込み

    $変数ファイルパス = $global:JSONPath
    $変数 = @{}

    if (Test-Path -Path $変数ファイルパス) {
        $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "テキスト書込設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 380)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # ファイルパス
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "書き込み先ファイルパス："
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
        $dialog = New-Object System.Windows.Forms.SaveFileDialog
        $dialog.Title = "保存先を選択"
        $dialog.Filter = "テキストファイル (*.txt)|*.txt|すべてのファイル (*.*)|*.*"
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $ファイルパステキスト.Text = $dialog.FileName
        }
    })

    # 書き込み内容
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "書き込む内容："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $内容テキスト = New-Object System.Windows.Forms.TextBox
    $内容テキスト.Location = New-Object System.Drawing.Point(20, 110)
    $内容テキスト.Size = New-Object System.Drawing.Size(350, 60)
    $内容テキスト.Multiline = $true

    # 変数から選択
    $変数コンボ = New-Object System.Windows.Forms.ComboBox
    $変数コンボ.Location = New-Object System.Drawing.Point(380, 110)
    $変数コンボ.Size = New-Object System.Drawing.Size(80, 25)
    $変数コンボ.DropDownStyle = "DropDownList"
    $変数コンボ.Items.Add("変数選択") | Out-Null
    foreach ($キー in $変数.Keys) {
        $変数コンボ.Items.Add($キー) | Out-Null
    }
    $変数コンボ.SelectedIndex = 0
    $変数コンボ.Add_SelectedIndexChanged({
        if ($変数コンボ.SelectedIndex -gt 0) {
            $内容テキスト.Text = "`$$($変数コンボ.SelectedItem)"
        }
    })

    # エンコーディング
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "文字コード："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 185)
    $ラベル3.AutoSize = $true

    $エンコーディングコンボ = New-Object System.Windows.Forms.ComboBox
    $エンコーディングコンボ.Location = New-Object System.Drawing.Point(20, 210)
    $エンコーディングコンボ.Size = New-Object System.Drawing.Size(150, 25)
    $エンコーディングコンボ.DropDownStyle = "DropDownList"
    $エンコーディングコンボ.Items.AddRange(@("UTF8", "UTF8BOM", "Shift_JIS", "Default"))
    $エンコーディングコンボ.SelectedIndex = 0

    # 追記モード
    $追記チェック = New-Object System.Windows.Forms.CheckBox
    $追記チェック.Text = "既存ファイルに追記する"
    $追記チェック.Location = New-Object System.Drawing.Point(200, 212)
    $追記チェック.Size = New-Object System.Drawing.Size(200, 25)

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(290, 300)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(390, 300)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $ファイルパステキスト, $参照ボタン, $ラベル2, $内容テキスト, $変数コンボ, $ラベル3, $エンコーディングコンボ, $追記チェック, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $ファイルパス = $ファイルパステキスト.Text
    $内容 = $内容テキスト.Text
    $エンコーディング = $エンコーディングコンボ.SelectedItem
    $追記 = $追記チェック.Checked

    $encParam = switch ($エンコーディング) {
        "UTF8" { "-Encoding UTF8" }
        "UTF8BOM" { "-Encoding UTF8BOM" }
        "Shift_JIS" { "-Encoding ([System.Text.Encoding]::GetEncoding('Shift_JIS'))" }
        "Default" { "" }
    }

    $appendParam = if ($追記) { "-Append" } else { "" }
    $modeText = if ($追記) { "追記" } else { "書き込み" }

    $entryString = @"
# テキスト$modeText : $ファイルパス ($エンコーディング)
try {
    $内容 | Out-File -FilePath "$ファイルパス" $encParam $appendParam -NoNewline
    Write-Host "テキストファイルに${modeText}しました: $ファイルパス"
} catch {
    Write-Host "エラー: テキスト${modeText}に失敗しました - `$(`$_.Exception.Message)" -ForegroundColor Red
}
"@

    return $entryString
}
