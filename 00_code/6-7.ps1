
function 6_7 {
    # 文字列置換：文字列内の特定のパターンを置換

    $変数ファイルパス = $global:JSONPath
    $変数 = @{}

    if (Test-Path -Path $変数ファイルパス) {
        $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "文字列置換設定"
    $フォーム.Size = New-Object System.Drawing.Size(450, 320)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # 対象変数
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "置換対象の変数："
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

    # 検索文字列
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "検索する文字列："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $検索テキスト = New-Object System.Windows.Forms.TextBox
    $検索テキスト.Location = New-Object System.Drawing.Point(20, 110)
    $検索テキスト.Size = New-Object System.Drawing.Size(200, 25)

    # 置換文字列
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "置換後の文字列："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $置換テキスト = New-Object System.Windows.Forms.TextBox
    $置換テキスト.Location = New-Object System.Drawing.Point(20, 175)
    $置換テキスト.Size = New-Object System.Drawing.Size(200, 25)

    # 格納先
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "結果を格納する変数名："
    $ラベル4.Location = New-Object System.Drawing.Point(20, 215)
    $ラベル4.AutoSize = $true

    $格納先テキスト = New-Object System.Windows.Forms.TextBox
    $格納先テキスト.Location = New-Object System.Drawing.Point(20, 240)
    $格納先テキスト.Size = New-Object System.Drawing.Size(200, 25)
    $格納先テキスト.Text = "置換結果"

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(240, 240)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(340, 240)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $変数コンボ, $ラベル2, $検索テキスト, $ラベル3, $置換テキスト, $ラベル4, $格納先テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $対象変数 = $変数コンボ.SelectedItem
    $検索 = $検索テキスト.Text
    $置換 = $置換テキスト.Text
    $格納先 = $格納先テキスト.Text

    $entryString = @"
# 文字列置換: "$検索" → "$置換"
`$$格納先 = `$$対象変数 -replace "$検索", "$置換"
変数を追加する -変数 `$変数 -名前 "$格納先" -型 "単一値" -値 `$$格納先
Write-Host "$格納先 = `$$格納先"
"@

    return $entryString
}
