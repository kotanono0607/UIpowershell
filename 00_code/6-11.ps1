
function 6_11 {
    # 数値演算：四則演算を実行

    $変数ファイルパス = $global:JSONPath
    $変数 = @{}

    if (Test-Path -Path $変数ファイルパス) {
        $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "数値演算設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 320)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # 値1
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "値1："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $値1テキスト = New-Object System.Windows.Forms.TextBox
    $値1テキスト.Location = New-Object System.Drawing.Point(20, 45)
    $値1テキスト.Size = New-Object System.Drawing.Size(100, 25)
    $値1テキスト.Text = "0"

    $変数1コンボ = New-Object System.Windows.Forms.ComboBox
    $変数1コンボ.Location = New-Object System.Drawing.Point(130, 45)
    $変数1コンボ.Size = New-Object System.Drawing.Size(150, 25)
    $変数1コンボ.DropDownStyle = "DropDownList"
    $変数1コンボ.Items.Add("（直接入力）") | Out-Null
    foreach ($キー in $変数.Keys) { $変数1コンボ.Items.Add($キー) | Out-Null }
    $変数1コンボ.SelectedIndex = 0

    # 演算子
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "演算子："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $演算子コンボ = New-Object System.Windows.Forms.ComboBox
    $演算子コンボ.Location = New-Object System.Drawing.Point(20, 110)
    $演算子コンボ.Size = New-Object System.Drawing.Size(150, 25)
    $演算子コンボ.DropDownStyle = "DropDownList"
    $演算子コンボ.Items.AddRange(@("+ （加算）", "- （減算）", "* （乗算）", "/ （除算）", "% （剰余）"))
    $演算子コンボ.SelectedIndex = 0

    # 値2
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "値2："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $値2テキスト = New-Object System.Windows.Forms.TextBox
    $値2テキスト.Location = New-Object System.Drawing.Point(20, 175)
    $値2テキスト.Size = New-Object System.Drawing.Size(100, 25)
    $値2テキスト.Text = "0"

    $変数2コンボ = New-Object System.Windows.Forms.ComboBox
    $変数2コンボ.Location = New-Object System.Drawing.Point(130, 175)
    $変数2コンボ.Size = New-Object System.Drawing.Size(150, 25)
    $変数2コンボ.DropDownStyle = "DropDownList"
    $変数2コンボ.Items.Add("（直接入力）") | Out-Null
    foreach ($キー in $変数.Keys) { $変数2コンボ.Items.Add($キー) | Out-Null }
    $変数2コンボ.SelectedIndex = 0

    # 格納先
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "結果を格納する変数名："
    $ラベル4.Location = New-Object System.Drawing.Point(20, 215)
    $ラベル4.AutoSize = $true

    $格納先テキスト = New-Object System.Windows.Forms.TextBox
    $格納先テキスト.Location = New-Object System.Drawing.Point(20, 240)
    $格納先テキスト.Size = New-Object System.Drawing.Size(200, 25)
    $格納先テキスト.Text = "計算結果"

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(290, 240)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(390, 240)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $値1テキスト, $変数1コンボ, $ラベル2, $演算子コンボ, $ラベル3, $値2テキスト, $変数2コンボ, $ラベル4, $格納先テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $格納先 = $格納先テキスト.Text
    $演算子 = $演算子コンボ.SelectedItem.Substring(0, 1)

    # 値1の取得方法
    if ($変数1コンボ.SelectedIndex -eq 0) {
        $値1式 = $値1テキスト.Text
    } else {
        $値1式 = "[double]`$$($変数1コンボ.SelectedItem)"
    }

    # 値2の取得方法
    if ($変数2コンボ.SelectedIndex -eq 0) {
        $値2式 = $値2テキスト.Text
    } else {
        $値2式 = "[double]`$$($変数2コンボ.SelectedItem)"
    }

    $entryString = @"
# 数値演算: $値1式 $演算子 $値2式
`$$格納先 = $値1式 $演算子 $値2式
変数を追加する -変数 `$変数 -名前 "$格納先" -型 "単一値" -値 `$$格納先
Write-Host "$格納先 = `$$格納先"
"@

    return $entryString
}
