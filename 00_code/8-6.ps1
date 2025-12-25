﻿
function 8_6 {
    # 条件検索：二次元配列から条件に一致する行を検索

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
    $フォーム.Text = "条件検索設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 350)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # 変数選択
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "検索対象の二次元配列："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $変数コンボ = New-Object System.Windows.Forms.ComboBox
    $変数コンボ.Location = New-Object System.Drawing.Point(20, 45)
    $変数コンボ.Size = New-Object System.Drawing.Size(440, 25)
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

    # 検索列
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "検索する列："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    # 検索値
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "検索値："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $検索値テキスト = New-Object System.Windows.Forms.TextBox
    $検索値テキスト.Location = New-Object System.Drawing.Point(20, 175)
    $検索値テキスト.Size = New-Object System.Drawing.Size(200, 25)

    # 一致方法
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "一致方法："
    $ラベル4.Location = New-Object System.Drawing.Point(250, 150)
    $ラベル4.AutoSize = $true

    $一致コンボ = New-Object System.Windows.Forms.ComboBox
    $一致コンボ.Location = New-Object System.Drawing.Point(250, 175)
    $一致コンボ.Size = New-Object System.Drawing.Size(120, 25)
    $一致コンボ.DropDownStyle = "DropDownList"
    $一致コンボ.Items.AddRange(@("完全一致", "部分一致", "前方一致", "後方一致"))
    $一致コンボ.SelectedIndex = 0

    # 結果格納変数
    $ラベル5 = New-Object System.Windows.Forms.Label
    $ラベル5.Text = "結果（行番号リスト）を格納する変数名："
    $ラベル5.Location = New-Object System.Drawing.Point(20, 215)
    $ラベル5.AutoSize = $true

    $結果変数テキスト = New-Object System.Windows.Forms.TextBox
    $結果変数テキスト.Location = New-Object System.Drawing.Point(20, 240)
    $結果変数テキスト.Size = New-Object System.Drawing.Size(200, 25)
    $結果変数テキスト.Text = "検索結果"

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(290, 280)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(390, 280)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $変数コンボ, $ラベル2, $列コンボ, $ラベル3, $検索値テキスト, $ラベル4, $一致コンボ, $ラベル5, $結果変数テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $選択変数 = $変数コンボ.SelectedItem
    $検索列 = $列コンボ.SelectedItem
    $検索値 = $検索値テキスト.Text
    $一致方法 = $一致コンボ.SelectedItem
    $結果変数 = $結果変数テキスト.Text

    $entryString = @"
# 条件検索: $選択変数 の $検索列 = "$検索値" ($一致方法)
`$データ = 変数の値を取得する -変数 `$変数 -名前 "$選択変数"
`$$結果変数 = 条件検索 -データ `$データ -検索列名 "$検索列" -検索値 "$検索値" -一致方法 "$一致方法"
変数を追加する -変数 `$変数 -名前 "$結果変数" -型 "一次元" -値 `$$結果変数
Write-Host "検索結果: `$(`$$結果変数.Count) 件ヒット"
"@

    return $entryString
}
