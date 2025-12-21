
function 6_8 {
    # 部分文字列：文字列から一部を切り出し

    $変数ファイルパス = $global:JSONPath
    $変数 = @{}

    if (Test-Path -Path $変数ファイルパス) {
        $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "部分文字列設定"
    $フォーム.Size = New-Object System.Drawing.Size(450, 320)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # 対象変数
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "対象の変数："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $変数コンボ = New-Object System.Windows.Forms.ComboBox
    $変数コンボ.Location = New-Object System.Drawing.Point(20, 45)
    $変数コンボ.Size = New-Object System.Drawing.Size(390, 25)
    $変数コンボ.DropDownStyle = "DropDownList"
    foreach ($キー in $変数.Keys) {
        $val = $変数[$キー]
        if (-not ($val -is [System.Array])) {
            $変数コンボ.Items.Add($キー) | Out-Null
        }
    }
    if ($変数コンボ.Items.Count -gt 0) { $変数コンボ.SelectedIndex = 0 }

    # 開始位置
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "開始位置（0から）："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $開始テキスト = New-Object System.Windows.Forms.NumericUpDown
    $開始テキスト.Location = New-Object System.Drawing.Point(20, 110)
    $開始テキスト.Size = New-Object System.Drawing.Size(100, 25)
    $開始テキスト.Minimum = 0
    $開始テキスト.Maximum = 10000
    $開始テキスト.Value = 0

    # 文字数
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "文字数（0=末尾まで）："
    $ラベル3.Location = New-Object System.Drawing.Point(200, 85)
    $ラベル3.AutoSize = $true

    $文字数テキスト = New-Object System.Windows.Forms.NumericUpDown
    $文字数テキスト.Location = New-Object System.Drawing.Point(200, 110)
    $文字数テキスト.Size = New-Object System.Drawing.Size(100, 25)
    $文字数テキスト.Minimum = 0
    $文字数テキスト.Maximum = 10000
    $文字数テキスト.Value = 0

    # 方法
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "切り出し方法："
    $ラベル4.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル4.AutoSize = $true

    $方法コンボ = New-Object System.Windows.Forms.ComboBox
    $方法コンボ.Location = New-Object System.Drawing.Point(20, 175)
    $方法コンボ.Size = New-Object System.Drawing.Size(200, 25)
    $方法コンボ.DropDownStyle = "DropDownList"
    $方法コンボ.Items.AddRange(@("先頭から", "末尾から", "位置指定"))
    $方法コンボ.SelectedIndex = 0

    # 格納先
    $ラベル5 = New-Object System.Windows.Forms.Label
    $ラベル5.Text = "結果を格納する変数名："
    $ラベル5.Location = New-Object System.Drawing.Point(20, 215)
    $ラベル5.AutoSize = $true

    $格納先テキスト = New-Object System.Windows.Forms.TextBox
    $格納先テキスト.Location = New-Object System.Drawing.Point(20, 240)
    $格納先テキスト.Size = New-Object System.Drawing.Size(200, 25)
    $格納先テキスト.Text = "部分文字列"

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(240, 240)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(340, 240)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $変数コンボ, $ラベル2, $開始テキスト, $ラベル3, $文字数テキスト, $ラベル4, $方法コンボ, $ラベル5, $格納先テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $対象変数 = $変数コンボ.SelectedItem
    $開始 = [int]$開始テキスト.Value
    $文字数 = [int]$文字数テキスト.Value
    $方法 = $方法コンボ.SelectedItem
    $格納先 = $格納先テキスト.Text

    switch ($方法) {
        "先頭から" {
            if ($文字数 -eq 0) {
                $式 = "`$$対象変数"
            } else {
                $式 = "`$$対象変数.Substring(0, [Math]::Min($文字数, `$$対象変数.Length))"
            }
        }
        "末尾から" {
            if ($文字数 -eq 0) {
                $式 = "`$$対象変数"
            } else {
                $式 = "`$$対象変数.Substring([Math]::Max(0, `$$対象変数.Length - $文字数))"
            }
        }
        "位置指定" {
            if ($文字数 -eq 0) {
                $式 = "`$$対象変数.Substring($開始)"
            } else {
                $式 = "`$$対象変数.Substring($開始, [Math]::Min($文字数, `$$対象変数.Length - $開始))"
            }
        }
    }

    $entryString = @"
# 部分文字列: $方法
`$$格納先 = $式
変数を追加する -変数 `$変数 -名前 "$格納先" -型 "単一値" -値 `$$格納先
Write-Host "$格納先 = `$$格納先"
"@

    return $entryString
}
