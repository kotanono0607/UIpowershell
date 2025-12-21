
function 6_10 {
    # 日付計算：日付に対して日数を加算/減算

    $変数ファイルパス = $global:JSONPath
    $変数 = @{}

    if (Test-Path -Path $変数ファイルパス) {
        $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "日付計算設定"
    $フォーム.Size = New-Object System.Drawing.Size(450, 350)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # 基準日
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "基準日："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $今日ラジオ = New-Object System.Windows.Forms.RadioButton
    $今日ラジオ.Text = "今日"
    $今日ラジオ.Location = New-Object System.Drawing.Point(20, 45)
    $今日ラジオ.Size = New-Object System.Drawing.Size(80, 25)
    $今日ラジオ.Checked = $true

    $変数ラジオ = New-Object System.Windows.Forms.RadioButton
    $変数ラジオ.Text = "変数から"
    $変数ラジオ.Location = New-Object System.Drawing.Point(110, 45)
    $変数ラジオ.Size = New-Object System.Drawing.Size(100, 25)

    $変数コンボ = New-Object System.Windows.Forms.ComboBox
    $変数コンボ.Location = New-Object System.Drawing.Point(220, 45)
    $変数コンボ.Size = New-Object System.Drawing.Size(150, 25)
    $変数コンボ.DropDownStyle = "DropDownList"
    $変数コンボ.Enabled = $false
    foreach ($キー in $変数.Keys) {
        $val = $変数[$キー]
        if (-not ($val -is [System.Array])) {
            $変数コンボ.Items.Add($キー) | Out-Null
        }
    }
    if ($変数コンボ.Items.Count -gt 0) { $変数コンボ.SelectedIndex = 0 }

    $変数ラジオ.Add_CheckedChanged({
        $変数コンボ.Enabled = $変数ラジオ.Checked
    })

    # 計算方法
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "計算："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $演算コンボ = New-Object System.Windows.Forms.ComboBox
    $演算コンボ.Location = New-Object System.Drawing.Point(20, 110)
    $演算コンボ.Size = New-Object System.Drawing.Size(80, 25)
    $演算コンボ.DropDownStyle = "DropDownList"
    $演算コンボ.Items.AddRange(@("加算", "減算"))
    $演算コンボ.SelectedIndex = 0

    $日数テキスト = New-Object System.Windows.Forms.NumericUpDown
    $日数テキスト.Location = New-Object System.Drawing.Point(110, 110)
    $日数テキスト.Size = New-Object System.Drawing.Size(80, 25)
    $日数テキスト.Minimum = 0
    $日数テキスト.Maximum = 3650
    $日数テキスト.Value = 1

    $単位コンボ = New-Object System.Windows.Forms.ComboBox
    $単位コンボ.Location = New-Object System.Drawing.Point(200, 110)
    $単位コンボ.Size = New-Object System.Drawing.Size(80, 25)
    $単位コンボ.DropDownStyle = "DropDownList"
    $単位コンボ.Items.AddRange(@("日", "月", "年"))
    $単位コンボ.SelectedIndex = 0

    # 出力形式
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "出力形式："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $形式コンボ = New-Object System.Windows.Forms.ComboBox
    $形式コンボ.Location = New-Object System.Drawing.Point(20, 175)
    $形式コンボ.Size = New-Object System.Drawing.Size(200, 25)
    $形式コンボ.DropDownStyle = "DropDownList"
    $形式コンボ.Items.AddRange(@("yyyy/MM/dd", "yyyy-MM-dd", "yyyyMMdd", "yyyy年MM月dd日"))
    $形式コンボ.SelectedIndex = 0

    # 格納先
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "格納先の変数名："
    $ラベル4.Location = New-Object System.Drawing.Point(20, 215)
    $ラベル4.AutoSize = $true

    $格納先テキスト = New-Object System.Windows.Forms.TextBox
    $格納先テキスト.Location = New-Object System.Drawing.Point(20, 240)
    $格納先テキスト.Size = New-Object System.Drawing.Size(200, 25)
    $格納先テキスト.Text = "計算結果日"

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(240, 270)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(340, 270)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $今日ラジオ, $変数ラジオ, $変数コンボ, $ラベル2, $演算コンボ, $日数テキスト, $単位コンボ, $ラベル3, $形式コンボ, $ラベル4, $格納先テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $今日から = $今日ラジオ.Checked
    $対象変数 = $変数コンボ.SelectedItem
    $演算 = $演算コンボ.SelectedItem
    $日数 = [int]$日数テキスト.Value
    $単位 = $単位コンボ.SelectedItem
    $形式 = $形式コンボ.SelectedItem
    $格納先 = $格納先テキスト.Text

    # 符号
    $符号 = if ($演算 -eq "減算") { "-" } else { "" }

    # メソッド
    $メソッド = switch ($単位) {
        "日" { "AddDays" }
        "月" { "AddMonths" }
        "年" { "AddYears" }
    }

    if ($今日から) {
        $entryString = @"
# 日付計算: 今日 $演算 $日数$単位
`$$格納先 = (Get-Date).$メソッド($符号$日数).ToString("$形式")
変数を追加する -変数 `$変数 -名前 "$格納先" -型 "単一値" -値 `$$格納先
Write-Host "$格納先 = `$$格納先"
"@
    } else {
        $entryString = @"
# 日付計算: $対象変数 $演算 $日数$単位
`$基準日 = [datetime]::Parse(`$$対象変数)
`$$格納先 = `$基準日.$メソッド($符号$日数).ToString("$形式")
変数を追加する -変数 `$変数 -名前 "$格納先" -型 "単一値" -値 `$$格納先
Write-Host "$格納先 = `$$格納先"
"@
    }

    return $entryString
}
