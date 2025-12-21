
function 6_9 {
    # 現在日時：今日の日付や現在時刻を取得

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "現在日時取得設定"
    $フォーム.Size = New-Object System.Drawing.Size(450, 280)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # 取得形式
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "取得する形式："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $形式コンボ = New-Object System.Windows.Forms.ComboBox
    $形式コンボ.Location = New-Object System.Drawing.Point(20, 45)
    $形式コンボ.Size = New-Object System.Drawing.Size(300, 25)
    $形式コンボ.DropDownStyle = "DropDownList"
    $形式コンボ.Items.AddRange(@(
        "yyyy/MM/dd（2025/01/15）",
        "yyyy-MM-dd（2025-01-15）",
        "yyyyMMdd（20250115）",
        "yyyy年MM月dd日",
        "HH:mm:ss（15:30:45）",
        "HHmmss（153045）",
        "yyyy/MM/dd HH:mm:ss",
        "yyyy-MM-dd HH:mm:ss",
        "yyyyMMddHHmmss",
        "カスタム"
    ))
    $形式コンボ.SelectedIndex = 0

    # カスタムフォーマット
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "カスタムフォーマット："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $カスタムテキスト = New-Object System.Windows.Forms.TextBox
    $カスタムテキスト.Location = New-Object System.Drawing.Point(20, 110)
    $カスタムテキスト.Size = New-Object System.Drawing.Size(200, 25)
    $カスタムテキスト.Text = "yyyy/MM/dd"
    $カスタムテキスト.Enabled = $false

    $形式コンボ.Add_SelectedIndexChanged({
        $カスタムテキスト.Enabled = ($形式コンボ.SelectedItem -eq "カスタム")
    })

    # 格納先
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "格納先の変数名："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $格納先テキスト = New-Object System.Windows.Forms.TextBox
    $格納先テキスト.Location = New-Object System.Drawing.Point(20, 175)
    $格納先テキスト.Size = New-Object System.Drawing.Size(200, 25)
    $格納先テキスト.Text = "現在日時"

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

    $フォーム.Controls.AddRange(@($ラベル1, $形式コンボ, $ラベル2, $カスタムテキスト, $ラベル3, $格納先テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $形式 = $形式コンボ.SelectedItem
    $格納先 = $格納先テキスト.Text

    # フォーマット文字列を取得
    $フォーマット = switch ($形式) {
        "yyyy/MM/dd（2025/01/15）" { "yyyy/MM/dd" }
        "yyyy-MM-dd（2025-01-15）" { "yyyy-MM-dd" }
        "yyyyMMdd（20250115）" { "yyyyMMdd" }
        "yyyy年MM月dd日" { "yyyy年MM月dd日" }
        "HH:mm:ss（15:30:45）" { "HH:mm:ss" }
        "HHmmss（153045）" { "HHmmss" }
        "yyyy/MM/dd HH:mm:ss" { "yyyy/MM/dd HH:mm:ss" }
        "yyyy-MM-dd HH:mm:ss" { "yyyy-MM-dd HH:mm:ss" }
        "yyyyMMddHHmmss" { "yyyyMMddHHmmss" }
        "カスタム" { $カスタムテキスト.Text }
    }

    $entryString = @"
# 現在日時取得: フォーマット "$フォーマット"
`$$格納先 = (Get-Date).ToString("$フォーマット")
変数を追加する -変数 `$変数 -名前 "$格納先" -型 "単一値" -値 `$$格納先
Write-Host "$格納先 = `$$格納先"
"@

    return $entryString
}
