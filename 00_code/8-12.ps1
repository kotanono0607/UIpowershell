﻿
function 8_12 {
    # 列名セル取得：列名を指定してセル値を取得

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
    $フォーム.Text = "列名セル取得設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 300)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # 変数選択
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "対象の二次元配列："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $変数コンボ = New-Object System.Windows.Forms.ComboBox
    $変数コンボ.Location = New-Object System.Drawing.Point(20, 45)
    $変数コンボ.Size = New-Object System.Drawing.Size(440, 25)
    $変数コンボ.DropDownStyle = "DropDownList"

    $列コンボ = New-Object System.Windows.Forms.ComboBox
    $列コンボ.Location = New-Object System.Drawing.Point(200, 110)
    $列コンボ.Size = New-Object System.Drawing.Size(200, 25)
    $列コンボ.DropDownStyle = "DropDownList"

    # 変数選択時に列リストを更新
    $変数コンボ.Add_SelectedIndexChanged({
        $列コンボ.Items.Clear()
        $選択変数名 = $変数コンボ.SelectedItem
        if ($選択変数名 -and $二次元変数.ContainsKey($選択変数名)) {
            $データ = $二次元変数[$選択変数名]
            if ($データ.Count -gt 0) {
                foreach ($列名 in $データ[0]) {
                    $列コンボ.Items.Add($列名) | Out-Null
                }
                if ($列コンボ.Items.Count -gt 0) { $列コンボ.SelectedIndex = 0 }
            }
        }
    })

    foreach ($キー in $二次元変数.Keys) { $変数コンボ.Items.Add($キー) | Out-Null }
    if ($変数コンボ.Items.Count -gt 0) { $変数コンボ.SelectedIndex = 0 }

    # 行番号
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "行番号（1=最初のデータ行）："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $行テキスト = New-Object System.Windows.Forms.NumericUpDown
    $行テキスト.Location = New-Object System.Drawing.Point(20, 110)
    $行テキスト.Size = New-Object System.Drawing.Size(100, 25)
    $行テキスト.Minimum = 1
    $行テキスト.Maximum = 100000
    $行テキスト.Value = 1

    # 列選択
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "列名："
    $ラベル3.Location = New-Object System.Drawing.Point(200, 85)
    $ラベル3.AutoSize = $true

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
    $OKボタン.Location = New-Object System.Drawing.Point(290, 220)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(390, 220)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $変数コンボ, $ラベル2, $行テキスト, $ラベル3, $列コンボ, $ラベル4, $格納先テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $選択変数 = $変数コンボ.SelectedItem
    $行番号 = [int]$行テキスト.Value
    $列名 = $列コンボ.SelectedItem
    $格納先 = $格納先テキスト.Text

    $entryString = @"
# 列名セル取得: $選択変数 の $行番号 行目 $列名 列
`$データ = 変数の値を取得する -変数 `$変数 -名前 "$選択変数"
`$$格納先 = 列名セル取得 -データ `$データ -行番号 $行番号 -列名 "$列名"
変数を追加する -変数 `$変数 -名前 "$格納先" -型 "単一値" -値 `$$格納先
Write-Host "$格納先 = `$$格納先"
"@

    return $entryString
}
