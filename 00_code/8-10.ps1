
function 8_10 {
    # 行追加：二次元配列に新しい行を追加

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
    $フォーム.Text = "行追加設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 280)
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
    $変数コンボ.Size = New-Object System.Drawing.Size(440, 25)
    $変数コンボ.DropDownStyle = "DropDownList"
    foreach ($キー in $二次元変数.Keys) { $変数コンボ.Items.Add($キー) | Out-Null }
    if ($変数コンボ.Items.Count -gt 0) { $変数コンボ.SelectedIndex = 0 }

    # 追加方法
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "追加する行のデータ："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $空行ラジオ = New-Object System.Windows.Forms.RadioButton
    $空行ラジオ.Text = "空行を追加"
    $空行ラジオ.Location = New-Object System.Drawing.Point(20, 110)
    $空行ラジオ.Size = New-Object System.Drawing.Size(150, 25)
    $空行ラジオ.Checked = $true

    $変数ラジオ = New-Object System.Windows.Forms.RadioButton
    $変数ラジオ.Text = "一次元配列変数から"
    $変数ラジオ.Location = New-Object System.Drawing.Point(180, 110)
    $変数ラジオ.Size = New-Object System.Drawing.Size(150, 25)

    # 一次元配列変数のみ抽出
    $一次元変数 = @{}
    foreach ($キー in $変数.Keys) {
        $値 = $変数[$キー]
        if ($値 -is [System.Array] -and $値.Count -gt 0 -and -not ($値[0] -is [System.Array])) {
            $一次元変数[$キー] = $値
        }
    }

    $行変数コンボ = New-Object System.Windows.Forms.ComboBox
    $行変数コンボ.Location = New-Object System.Drawing.Point(20, 145)
    $行変数コンボ.Size = New-Object System.Drawing.Size(300, 25)
    $行変数コンボ.DropDownStyle = "DropDownList"
    $行変数コンボ.Enabled = $false
    foreach ($キー in $一次元変数.Keys) { $行変数コンボ.Items.Add($キー) | Out-Null }
    if ($行変数コンボ.Items.Count -gt 0) { $行変数コンボ.SelectedIndex = 0 }

    $変数ラジオ.Add_CheckedChanged({
        $行変数コンボ.Enabled = $変数ラジオ.Checked
    })

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(290, 195)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(390, 195)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $変数コンボ, $ラベル2, $空行ラジオ, $変数ラジオ, $行変数コンボ, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $選択変数 = $変数コンボ.SelectedItem
    $変数から = $変数ラジオ.Checked

    if ($変数から -and $行変数コンボ.SelectedItem) {
        $行変数名 = $行変数コンボ.SelectedItem
        $entryString = @"
# 行追加: $選択変数 に $行変数名 を追加
`$データ = 変数の値を取得する -変数 `$変数 -名前 "$選択変数"
`$新行 = 変数の値を取得する -変数 `$変数 -名前 "$行変数名"
`$データ = 行追加 -データ `$データ -新しい行 `$新行
変数を追加する -変数 `$変数 -名前 "$選択変数" -型 "二次元" -値 `$データ
Write-Host "$選択変数 に行を追加しました。現在 `$(`$データ.Count) 行"
"@
    } else {
        $entryString = @"
# 行追加: $選択変数 に空行を追加
`$データ = 変数の値を取得する -変数 `$変数 -名前 "$選択変数"
`$データ = 行追加 -データ `$データ
変数を追加する -変数 `$変数 -名前 "$選択変数" -型 "二次元" -値 `$データ
Write-Host "$選択変数 に空行を追加しました。現在 `$(`$データ.Count) 行"
"@
    }

    return $entryString
}
