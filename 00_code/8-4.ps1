
function 8_4 {
    # セル値取得：二次元配列から特定のセル値を取得して変数に格納

    $変数ファイルパス = $global:JSONPath

    if (-not (Test-Path -Path $変数ファイルパス)) {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("変数ファイルが存在しません。", "エラー", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return $null
    }

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
        [System.Windows.Forms.MessageBox]::Show("二次元配列の変数がありません。", "情報", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return $null
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "セル値取得設定"
    $フォーム.Size = New-Object System.Drawing.Size(450, 300)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # 変数選択
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "対象の二次元配列："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $変数コンボ = New-Object System.Windows.Forms.ComboBox
    $変数コンボ.Location = New-Object System.Drawing.Point(20, 45)
    $変数コンボ.Size = New-Object System.Drawing.Size(390, 25)
    $変数コンボ.DropDownStyle = "DropDownList"
    foreach ($キー in $二次元変数.Keys) { $変数コンボ.Items.Add($キー) | Out-Null }
    if ($変数コンボ.Items.Count -gt 0) { $変数コンボ.SelectedIndex = 0 }

    # 行番号
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "行番号（0から開始、0=ヘッダー）："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $行テキスト = New-Object System.Windows.Forms.NumericUpDown
    $行テキスト.Location = New-Object System.Drawing.Point(20, 110)
    $行テキスト.Size = New-Object System.Drawing.Size(100, 25)
    $行テキスト.Minimum = 0
    $行テキスト.Maximum = 10000
    $行テキスト.Value = 1

    # 列番号
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "列番号（0から開始）："
    $ラベル3.Location = New-Object System.Drawing.Point(200, 85)
    $ラベル3.AutoSize = $true

    $列テキスト = New-Object System.Windows.Forms.NumericUpDown
    $列テキスト.Location = New-Object System.Drawing.Point(200, 110)
    $列テキスト.Size = New-Object System.Drawing.Size(100, 25)
    $列テキスト.Minimum = 0
    $列テキスト.Maximum = 1000
    $列テキスト.Value = 0

    # 格納先変数名
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "格納先の変数名："
    $ラベル4.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル4.AutoSize = $true

    $格納先テキスト = New-Object System.Windows.Forms.TextBox
    $格納先テキスト.Location = New-Object System.Drawing.Point(20, 175)
    $格納先テキスト.Size = New-Object System.Drawing.Size(200, 25)
    $格納先テキスト.Text = "セル値"

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(240, 220)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(340, 220)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $変数コンボ, $ラベル2, $行テキスト, $ラベル3, $列テキスト, $ラベル4, $格納先テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $選択変数 = $変数コンボ.SelectedItem
    $行番号 = [int]$行テキスト.Value
    $列番号 = [int]$列テキスト.Value
    $格納先 = $格納先テキスト.Text

    $entryString = @"
# セル値取得: $選択変数[$行番号][$列番号] → $格納先
`$データ = 変数の値を取得する -変数 `$変数 -名前 "$選択変数"
`$$格納先 = セル値取得 -データ `$データ -行番号 $行番号 -列番号 $列番号
変数を追加する -変数 `$変数 -名前 "$格納先" -型 "単一値" -値 `$$格納先
Write-Host "$格納先 = `$$格納先"
"@

    return $entryString
}
