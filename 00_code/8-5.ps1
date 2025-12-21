
function 8_5 {
    # 行ループ：二次元配列の各行に対して処理を繰り返す（Greenノード用）

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
    $フォーム.Text = "行ループ設定"
    $フォーム.Size = New-Object System.Drawing.Size(450, 250)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # 変数選択
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "ループ対象の二次元配列："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $変数コンボ = New-Object System.Windows.Forms.ComboBox
    $変数コンボ.Location = New-Object System.Drawing.Point(20, 45)
    $変数コンボ.Size = New-Object System.Drawing.Size(390, 25)
    $変数コンボ.DropDownStyle = "DropDownList"
    foreach ($キー in $二次元変数.Keys) { $変数コンボ.Items.Add($キー) | Out-Null }
    if ($変数コンボ.Items.Count -gt 0) { $変数コンボ.SelectedIndex = 0 }

    # ヘッダースキップ
    $ヘッダーチェック = New-Object System.Windows.Forms.CheckBox
    $ヘッダーチェック.Text = "ヘッダー行（1行目）をスキップする"
    $ヘッダーチェック.Location = New-Object System.Drawing.Point(20, 85)
    $ヘッダーチェック.Size = New-Object System.Drawing.Size(300, 25)
    $ヘッダーチェック.Checked = $true

    # 行変数名
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "現在行を格納する変数名："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 120)
    $ラベル2.AutoSize = $true

    $行変数テキスト = New-Object System.Windows.Forms.TextBox
    $行変数テキスト.Location = New-Object System.Drawing.Point(20, 145)
    $行変数テキスト.Size = New-Object System.Drawing.Size(150, 25)
    $行変数テキスト.Text = "現在行"

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(240, 175)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(340, 175)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $変数コンボ, $ヘッダーチェック, $ラベル2, $行変数テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $選択変数 = $変数コンボ.SelectedItem
    $ヘッダースキップ = $ヘッダーチェック.Checked
    $行変数名 = $行変数テキスト.Text
    $開始行 = if ($ヘッダースキップ) { 1 } else { 0 }

    $entryString = @"
# 行ループ: $選択変数
`$ループデータ = 変数の値を取得する -変数 `$変数 -名前 "$選択変数"
for (`$行インデックス = $開始行; `$行インデックス -lt `$ループデータ.Count; `$行インデックス++) {
    `$$行変数名 = `$ループデータ[`$行インデックス]
    Write-Host "処理中: 行 `$行インデックス"
    # ここに各行の処理を追加
}
"@

    return $entryString
}
