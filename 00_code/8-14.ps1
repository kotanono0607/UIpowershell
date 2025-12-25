﻿
function 8_14 {
    # 配列ソート：二次元配列を指定列でソート

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
    $フォーム.Text = "配列ソート設定"
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

    $列コンボ = New-Object System.Windows.Forms.ComboBox
    $列コンボ.Location = New-Object System.Drawing.Point(20, 110)
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

    # ソート列
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "ソートする列："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    # ソート順
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "ソート順："
    $ラベル3.Location = New-Object System.Drawing.Point(250, 85)
    $ラベル3.AutoSize = $true

    $順序コンボ = New-Object System.Windows.Forms.ComboBox
    $順序コンボ.Location = New-Object System.Drawing.Point(250, 110)
    $順序コンボ.Size = New-Object System.Drawing.Size(120, 25)
    $順序コンボ.DropDownStyle = "DropDownList"
    $順序コンボ.Items.AddRange(@("昇順", "降順"))
    $順序コンボ.SelectedIndex = 0

    # データ型
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "データ型："
    $ラベル4.Location = New-Object System.Drawing.Point(20, 145)
    $ラベル4.AutoSize = $true

    $型コンボ = New-Object System.Windows.Forms.ComboBox
    $型コンボ.Location = New-Object System.Drawing.Point(20, 170)
    $型コンボ.Size = New-Object System.Drawing.Size(120, 25)
    $型コンボ.DropDownStyle = "DropDownList"
    $型コンボ.Items.AddRange(@("文字列", "数値", "日付"))
    $型コンボ.SelectedIndex = 0

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(240, 200)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(340, 200)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $変数コンボ, $ラベル2, $列コンボ, $ラベル3, $順序コンボ, $ラベル4, $型コンボ, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $選択変数 = $変数コンボ.SelectedItem
    $ソート列 = $列コンボ.SelectedItem
    $ソート順 = $順序コンボ.SelectedItem
    $データ型 = $型コンボ.SelectedItem
    $降順フラグ = if ($ソート順 -eq "降順") { "-降順" } else { "" }

    $entryString = @"
# 配列ソート: $選択変数 を $ソート列 で $ソート順
`$データ = 変数の値を取得する -変数 `$変数 -名前 "$選択変数"
`$データ = 配列ソート -データ `$データ -列名 "$ソート列" -データ型 "$データ型" $降順フラグ
変数を追加する -変数 `$変数 -名前 "$選択変数" -型 "二次元" -値 `$データ
Write-Host "$選択変数 を $ソート列 で $ソート順 にソートしました"
"@

    return $entryString
}
