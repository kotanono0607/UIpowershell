
function 8_7 {
    # 列値一覧：二次元配列から特定列の全値を取得

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
    $フォーム.Text = "列値一覧取得設定"
    $フォーム.Size = New-Object System.Drawing.Size(450, 300)
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

    # 取得列
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "取得する列："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    # オプション
    $重複除外チェック = New-Object System.Windows.Forms.CheckBox
    $重複除外チェック.Text = "重複を除外する"
    $重複除外チェック.Location = New-Object System.Drawing.Point(20, 150)
    $重複除外チェック.Size = New-Object System.Drawing.Size(200, 25)
    $重複除外チェック.Checked = $false

    # 結果格納変数
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "結果を格納する変数名："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 185)
    $ラベル3.AutoSize = $true

    $結果変数テキスト = New-Object System.Windows.Forms.TextBox
    $結果変数テキスト.Location = New-Object System.Drawing.Point(20, 210)
    $結果変数テキスト.Size = New-Object System.Drawing.Size(200, 25)
    $結果変数テキスト.Text = "列値リスト"

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(240, 250)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(340, 250)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $変数コンボ, $ラベル2, $列コンボ, $重複除外チェック, $ラベル3, $結果変数テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $選択変数 = $変数コンボ.SelectedItem
    $列名 = $列コンボ.SelectedItem
    $重複除外 = $重複除外チェック.Checked
    $結果変数 = $結果変数テキスト.Text

    $重複オプション = if ($重複除外) { " -重複除外" } else { "" }

    $entryString = @"
# 列値一覧: $選択変数 の $列名 列を取得
`$データ = 変数の値を取得する -変数 `$変数 -名前 "$選択変数"
`$$結果変数 = 列値一覧 -データ `$データ -列名 "$列名"$重複オプション
変数を追加する -変数 `$変数 -名前 "$結果変数" -型 "一次元" -値 `$$結果変数
Write-Host "$結果変数: `$(`$$結果変数.Count) 件"
"@

    return $entryString
}
