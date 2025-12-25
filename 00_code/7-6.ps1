﻿function 7_6 {
    # フォルダ選択ダイアログ：フォルダを選択するダイアログを表示

    $変数ファイルパス = $global:JSONPath
    $変数 = @{}

    if (Test-Path -Path $変数ファイルパス) {
        $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "フォルダ選択ダイアログ設定"
    $フォーム.Size = New-Object System.Drawing.Size(450, 280)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # 説明
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "ダイアログの説明文："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $説明テキスト = New-Object System.Windows.Forms.TextBox
    $説明テキスト.Location = New-Object System.Drawing.Point(20, 45)
    $説明テキスト.Size = New-Object System.Drawing.Size(390, 25)
    $説明テキスト.Text = "フォルダを選択してください"

    # 初期フォルダ
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "初期フォルダ（省略可）："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $初期フォルダテキスト = New-Object System.Windows.Forms.TextBox
    $初期フォルダテキスト.Location = New-Object System.Drawing.Point(20, 110)
    $初期フォルダテキスト.Size = New-Object System.Drawing.Size(300, 25)
    $初期フォルダテキスト.Text = ""

    $参照ボタン = New-Object System.Windows.Forms.Button
    $参照ボタン.Text = "参照..."
    $参照ボタン.Location = New-Object System.Drawing.Point(330, 109)
    $参照ボタン.Size = New-Object System.Drawing.Size(80, 27)
    $参照ボタン.Add_Click({
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($folderDialog.ShowDialog() -eq "OK") {
            $初期フォルダテキスト.Text = $folderDialog.SelectedPath
        }
    })

    # 結果変数名
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "結果を格納する変数名："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $変数名テキスト = New-Object System.Windows.Forms.TextBox
    $変数名テキスト.Location = New-Object System.Drawing.Point(20, 175)
    $変数名テキスト.Size = New-Object System.Drawing.Size(200, 25)
    $変数名テキスト.Text = "選択フォルダ"

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(230, 210)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(330, 210)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $説明テキスト, $ラベル2, $初期フォルダテキスト, $参照ボタン, $ラベル3, $変数名テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $説明 = $説明テキスト.Text
    $初期フォルダ = $初期フォルダテキスト.Text
    $変数名 = $変数名テキスト.Text

    $初期フォルダ引数 = if ($初期フォルダ) { "`n`$ダイアログ.SelectedPath = `"$初期フォルダ`"" } else { "" }

    $entryString = @"
# フォルダ選択ダイアログ: $説明
Add-Type -AssemblyName System.Windows.Forms
`$ダイアログ = New-Object System.Windows.Forms.FolderBrowserDialog
`$ダイアログ.Description = "$説明"$初期フォルダ引数
if (`$ダイアログ.ShowDialog() -eq "OK") {
    `$$変数名 = `$ダイアログ.SelectedPath
    変数を追加する -変数 `$変数 -名前 "$変数名" -型 "単一値" -値 `$$変数名
    Write-Host "選択されたフォルダ: `$$変数名" -ForegroundColor Green
} else {
    `$$変数名 = `$null
    Write-Host "フォルダ選択がキャンセルされました" -ForegroundColor Yellow
}
"@

    return $entryString
}
