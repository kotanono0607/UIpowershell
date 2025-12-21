
function 8_13 {
    # 行削除：二次元配列から指定行を削除

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
    $フォーム.Text = "行削除設定"
    $フォーム.Size = New-Object System.Drawing.Size(450, 280)
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

    # 削除方法
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "削除方法："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $単一ラジオ = New-Object System.Windows.Forms.RadioButton
    $単一ラジオ.Text = "行番号を指定"
    $単一ラジオ.Location = New-Object System.Drawing.Point(20, 110)
    $単一ラジオ.Size = New-Object System.Drawing.Size(130, 25)
    $単一ラジオ.Checked = $true

    $検索ラジオ = New-Object System.Windows.Forms.RadioButton
    $検索ラジオ.Text = "検索結果の行を削除"
    $検索ラジオ.Location = New-Object System.Drawing.Point(160, 110)
    $検索ラジオ.Size = New-Object System.Drawing.Size(180, 25)

    # 行番号
    $行テキスト = New-Object System.Windows.Forms.NumericUpDown
    $行テキスト.Location = New-Object System.Drawing.Point(20, 145)
    $行テキスト.Size = New-Object System.Drawing.Size(100, 25)
    $行テキスト.Minimum = 1
    $行テキスト.Maximum = 100000
    $行テキスト.Value = 1

    # 検索結果変数
    $検索変数コンボ = New-Object System.Windows.Forms.ComboBox
    $検索変数コンボ.Location = New-Object System.Drawing.Point(160, 145)
    $検索変数コンボ.Size = New-Object System.Drawing.Size(200, 25)
    $検索変数コンボ.DropDownStyle = "DropDownList"
    $検索変数コンボ.Enabled = $false

    # 一次元配列変数を抽出
    foreach ($キー in $変数.Keys) {
        $値 = $変数[$キー]
        if ($値 -is [System.Array] -and $値.Count -gt 0 -and -not ($値[0] -is [System.Array])) {
            $検索変数コンボ.Items.Add($キー) | Out-Null
        }
    }
    if ($検索変数コンボ.Items.Count -gt 0) { $検索変数コンボ.SelectedIndex = 0 }

    $単一ラジオ.Add_CheckedChanged({
        $行テキスト.Enabled = $単一ラジオ.Checked
        $検索変数コンボ.Enabled = -not $単一ラジオ.Checked
    })

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(240, 195)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(340, 195)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $変数コンボ, $ラベル2, $単一ラジオ, $検索ラジオ, $行テキスト, $検索変数コンボ, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $選択変数 = $変数コンボ.SelectedItem
    $単一削除 = $単一ラジオ.Checked

    if ($単一削除) {
        $行番号 = [int]$行テキスト.Value
        $entryString = @"
# 行削除: $選択変数 の $行番号 行目を削除
`$データ = 変数の値を取得する -変数 `$変数 -名前 "$選択変数"
`$データ = 行削除 -データ `$データ -行番号 $行番号
変数を追加する -変数 `$変数 -名前 "$選択変数" -型 "二次元" -値 `$データ
Write-Host "$選択変数 から $行番号 行目を削除しました。現在 `$(`$データ.Count) 行"
"@
    } else {
        $検索変数名 = $検索変数コンボ.SelectedItem
        $entryString = @"
# 行削除: $選択変数 から検索結果の行を削除
`$データ = 変数の値を取得する -変数 `$変数 -名前 "$選択変数"
`$削除行リスト = 変数の値を取得する -変数 `$変数 -名前 "$検索変数名"
`$データ = 複数行削除 -データ `$データ -行番号リスト `$削除行リスト
変数を追加する -変数 `$変数 -名前 "$選択変数" -型 "二次元" -値 `$データ
Write-Host "$選択変数 から `$(`$削除行リスト.Count) 行を削除しました。現在 `$(`$データ.Count) 行"
"@
    }

    return $entryString
}
