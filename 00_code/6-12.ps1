
function 6_12 {
    # 型変換：文字列/数値/日付の相互変換

    $変数ファイルパス = $global:JSONPath
    $変数 = @{}

    if (Test-Path -Path $変数ファイルパス) {
        $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "型変換設定"
    $フォーム.Size = New-Object System.Drawing.Size(450, 280)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # 変換元変数
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "変換元の変数："
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

    # 変換先型
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "変換先の型："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $型コンボ = New-Object System.Windows.Forms.ComboBox
    $型コンボ.Location = New-Object System.Drawing.Point(20, 110)
    $型コンボ.Size = New-Object System.Drawing.Size(200, 25)
    $型コンボ.DropDownStyle = "DropDownList"
    $型コンボ.Items.AddRange(@("文字列 [string]", "整数 [int]", "小数 [double]", "日付 [datetime]"))
    $型コンボ.SelectedIndex = 0

    # 格納先
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "格納先の変数名："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $格納先テキスト = New-Object System.Windows.Forms.TextBox
    $格納先テキスト.Location = New-Object System.Drawing.Point(20, 175)
    $格納先テキスト.Size = New-Object System.Drawing.Size(200, 25)
    $格納先テキスト.Text = "変換結果"

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

    $フォーム.Controls.AddRange(@($ラベル1, $変数コンボ, $ラベル2, $型コンボ, $ラベル3, $格納先テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $変換元 = $変数コンボ.SelectedItem
    $型 = $型コンボ.SelectedItem
    $格納先 = $格納先テキスト.Text

    $変換式 = switch ($型) {
        "文字列 [string]" { "[string]`$$変換元" }
        "整数 [int]" { "[int]`$$変換元" }
        "小数 [double]" { "[double]`$$変換元" }
        "日付 [datetime]" { "[datetime]`$$変換元" }
    }

    $entryString = @"
# 型変換: $変換元 → $型
`$$格納先 = $変換式
変数を追加する -変数 `$変数 -名前 "$格納先" -型 "単一値" -値 `$$格納先
Write-Host "$格納先 = `$$格納先 (型: `$(`$$格納先.GetType().Name))"
"@

    return $entryString
}
