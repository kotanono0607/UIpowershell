function 7_5 {
    # ファイル選択ダイアログ：ファイルを選択するダイアログを表示

    $変数ファイルパス = $global:JSONPath
    $変数 = @{}

    if (Test-Path -Path $変数ファイルパス) {
        $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "ファイル選択ダイアログ設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 380)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # タイトル
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "ダイアログタイトル："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $タイトルテキスト = New-Object System.Windows.Forms.TextBox
    $タイトルテキスト.Location = New-Object System.Drawing.Point(20, 45)
    $タイトルテキスト.Size = New-Object System.Drawing.Size(440, 25)
    $タイトルテキスト.Text = "ファイルを選択してください"

    # フィルター
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "ファイルフィルター："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 80)
    $ラベル2.AutoSize = $true

    $フィルターコンボ = New-Object System.Windows.Forms.ComboBox
    $フィルターコンボ.Location = New-Object System.Drawing.Point(20, 105)
    $フィルターコンボ.Size = New-Object System.Drawing.Size(300, 25)
    $フィルターコンボ.DropDownStyle = "DropDown"
    $フィルターコンボ.Items.AddRange(@(
        "すべてのファイル (*.*)|*.*",
        "テキストファイル (*.txt)|*.txt",
        "Excelファイル (*.xlsx;*.xls)|*.xlsx;*.xls",
        "CSVファイル (*.csv)|*.csv",
        "画像ファイル (*.png;*.jpg;*.gif;*.bmp)|*.png;*.jpg;*.gif;*.bmp",
        "PDFファイル (*.pdf)|*.pdf",
        "PowerShellスクリプト (*.ps1)|*.ps1"
    ))
    $フィルターコンボ.SelectedIndex = 0

    # 初期フォルダ
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "初期フォルダ（省略可）："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 145)
    $ラベル3.AutoSize = $true

    $初期フォルダテキスト = New-Object System.Windows.Forms.TextBox
    $初期フォルダテキスト.Location = New-Object System.Drawing.Point(20, 170)
    $初期フォルダテキスト.Size = New-Object System.Drawing.Size(350, 25)
    $初期フォルダテキスト.Text = ""

    $参照ボタン = New-Object System.Windows.Forms.Button
    $参照ボタン.Text = "参照..."
    $参照ボタン.Location = New-Object System.Drawing.Point(380, 169)
    $参照ボタン.Size = New-Object System.Drawing.Size(80, 27)
    $参照ボタン.Add_Click({
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($folderDialog.ShowDialog() -eq "OK") {
            $初期フォルダテキスト.Text = $folderDialog.SelectedPath
        }
    })

    # 複数選択
    $複数選択チェック = New-Object System.Windows.Forms.CheckBox
    $複数選択チェック.Text = "複数ファイルの選択を許可"
    $複数選択チェック.Location = New-Object System.Drawing.Point(20, 210)
    $複数選択チェック.AutoSize = $true

    # 結果変数名
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "結果を格納する変数名："
    $ラベル4.Location = New-Object System.Drawing.Point(20, 250)
    $ラベル4.AutoSize = $true

    $変数名テキスト = New-Object System.Windows.Forms.TextBox
    $変数名テキスト.Location = New-Object System.Drawing.Point(20, 275)
    $変数名テキスト.Size = New-Object System.Drawing.Size(200, 25)
    $変数名テキスト.Text = "選択ファイル"

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(290, 305)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(390, 305)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $タイトルテキスト, $ラベル2, $フィルターコンボ, $ラベル3, $初期フォルダテキスト, $参照ボタン, $複数選択チェック, $ラベル4, $変数名テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $タイトル = $タイトルテキスト.Text
    $フィルター = $フィルターコンボ.Text
    $初期フォルダ = $初期フォルダテキスト.Text
    $複数選択 = $複数選択チェック.Checked
    $変数名 = $変数名テキスト.Text

    $初期フォルダ引数 = if ($初期フォルダ) { "`n`$ダイアログ.InitialDirectory = `"$初期フォルダ`"" } else { "" }
    $複数選択引数 = if ($複数選択) { "`n`$ダイアログ.Multiselect = `$true" } else { "" }

    if ($複数選択) {
        $entryString = @"
# ファイル選択ダイアログ（複数選択）: $タイトル
Add-Type -AssemblyName System.Windows.Forms
`$ダイアログ = New-Object System.Windows.Forms.OpenFileDialog
`$ダイアログ.Title = "$タイトル"
`$ダイアログ.Filter = "$フィルター"$初期フォルダ引数$複数選択引数
if (`$ダイアログ.ShowDialog() -eq "OK") {
    `$$変数名 = `$ダイアログ.FileNames
    変数を追加する -変数 `$変数 -名前 "$変数名" -型 "リスト" -値 `$$変数名
    Write-Host "選択されたファイル: `$(`$$変数名 -join ', ')" -ForegroundColor Green
} else {
    `$$変数名 = `$null
    Write-Host "ファイル選択がキャンセルされました" -ForegroundColor Yellow
}
"@
    } else {
        $entryString = @"
# ファイル選択ダイアログ: $タイトル
Add-Type -AssemblyName System.Windows.Forms
`$ダイアログ = New-Object System.Windows.Forms.OpenFileDialog
`$ダイアログ.Title = "$タイトル"
`$ダイアログ.Filter = "$フィルター"$初期フォルダ引数
if (`$ダイアログ.ShowDialog() -eq "OK") {
    `$$変数名 = `$ダイアログ.FileName
    変数を追加する -変数 `$変数 -名前 "$変数名" -型 "単一値" -値 `$$変数名
    Write-Host "選択されたファイル: `$$変数名" -ForegroundColor Green
} else {
    `$$変数名 = `$null
    Write-Host "ファイル選択がキャンセルされました" -ForegroundColor Yellow
}
"@
    }

    return $entryString
}
