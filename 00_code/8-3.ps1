
function 8_3 {
    # Excel書き込み：二次元配列変数をExcelファイルに書き込む

    $変数ファイルパス = $global:JSONPath

    # variables.jsonが存在しない場合
    if (-not (Test-Path -Path $変数ファイルパス)) {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show(
            "変数ファイルが存在しません。`n先にExcel読み込みなどで変数を作成してください。",
            "エラー",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return $null
    }

    # 変数を読み込む
    $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス

    # 二次元配列の変数のみ抽出
    $二次元変数 = @{}
    foreach ($キー in $変数.Keys) {
        $値 = $変数[$キー]
        if ($値 -is [System.Array] -and $値.Count -gt 0 -and $値[0] -is [System.Array]) {
            $二次元変数[$キー] = $値
        }
    }

    if ($二次元変数.Count -eq 0) {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show(
            "二次元配列の変数がありません。`n先にExcel読み込みで変数を作成してください。",
            "情報",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        return $null
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # 設定ダイアログ
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "Excel書き込み設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 280)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.MinimizeBox = $false
    $フォーム.Topmost = $true

    # 変数選択
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "書き込む変数："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $変数コンボ = New-Object System.Windows.Forms.ComboBox
    $変数コンボ.Location = New-Object System.Drawing.Point(20, 45)
    $変数コンボ.Size = New-Object System.Drawing.Size(440, 25)
    $変数コンボ.DropDownStyle = "DropDownList"
    foreach ($キー in $二次元変数.Keys) {
        $変数コンボ.Items.Add($キー) | Out-Null
    }
    if ($変数コンボ.Items.Count -gt 0) { $変数コンボ.SelectedIndex = 0 }

    # 出力ファイル
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "出力ファイルパス："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $パステキスト = New-Object System.Windows.Forms.TextBox
    $パステキスト.Location = New-Object System.Drawing.Point(20, 110)
    $パステキスト.Size = New-Object System.Drawing.Size(350, 25)

    $参照ボタン = New-Object System.Windows.Forms.Button
    $参照ボタン.Text = "参照..."
    $参照ボタン.Location = New-Object System.Drawing.Point(380, 108)
    $参照ボタン.Size = New-Object System.Drawing.Size(80, 28)
    $参照ボタン.Add_Click({
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "Excelファイル (*.xlsx)|*.xlsx"
        $saveDialog.Title = "保存先を選択"
        if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $パステキスト.Text = $saveDialog.FileName
        }
    })

    # シート名
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "シート名："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $シートテキスト = New-Object System.Windows.Forms.TextBox
    $シートテキスト.Location = New-Object System.Drawing.Point(20, 175)
    $シートテキスト.Size = New-Object System.Drawing.Size(200, 25)
    $シートテキスト.Text = "Sheet1"

    # ボタン
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

    $フォーム.Controls.AddRange(@($ラベル1, $変数コンボ, $ラベル2, $パステキスト, $参照ボタン, $ラベル3, $シートテキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    $選択変数名 = $変数コンボ.SelectedItem
    $出力パス = $パステキスト.Text
    $シート名 = $シートテキスト.Text

    if ([string]::IsNullOrWhiteSpace($出力パス)) {
        [System.Windows.Forms.MessageBox]::Show("出力ファイルパスを指定してください。", "エラー")
        return $null
    }

    # 生成するコード
    $entryString = @"
# Excel書き込み: $選択変数名 → $出力パス
`$書き込みデータ = 変数の値を取得する -変数 `$変数 -名前 "$選択変数名"
Excel書き込み -データ `$書き込みデータ -出力パス "$出力パス" -シート名 "$シート名"
"@

    return $entryString
}
