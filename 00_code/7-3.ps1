function 7_3 {
    # 入力ダイアログ：ユーザーからテキスト入力を受け付ける

    $変数ファイルパス = $global:JSONPath
    $変数 = @{}

    if (Test-Path -Path $変数ファイルパス) {
        $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "入力ダイアログ設定"
    $フォーム.Size = New-Object System.Drawing.Size(450, 320)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # タイトル
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "ダイアログタイトル："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $タイトルテキスト = New-Object System.Windows.Forms.TextBox
    $タイトルテキスト.Location = New-Object System.Drawing.Point(20, 45)
    $タイトルテキスト.Size = New-Object System.Drawing.Size(390, 25)
    $タイトルテキスト.Text = "入力してください"

    # プロンプト
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "入力を促すメッセージ："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 80)
    $ラベル2.AutoSize = $true

    $プロンプトテキスト = New-Object System.Windows.Forms.TextBox
    $プロンプトテキスト.Location = New-Object System.Drawing.Point(20, 105)
    $プロンプトテキスト.Size = New-Object System.Drawing.Size(390, 25)
    $プロンプトテキスト.Text = "値を入力してください:"

    # デフォルト値
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "デフォルト値（省略可）："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 140)
    $ラベル3.AutoSize = $true

    $デフォルトテキスト = New-Object System.Windows.Forms.TextBox
    $デフォルトテキスト.Location = New-Object System.Drawing.Point(20, 165)
    $デフォルトテキスト.Size = New-Object System.Drawing.Size(390, 25)
    $デフォルトテキスト.Text = ""

    # 結果変数名
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "結果を格納する変数名："
    $ラベル4.Location = New-Object System.Drawing.Point(20, 200)
    $ラベル4.AutoSize = $true

    $変数名テキスト = New-Object System.Windows.Forms.TextBox
    $変数名テキスト.Location = New-Object System.Drawing.Point(20, 225)
    $変数名テキスト.Size = New-Object System.Drawing.Size(200, 25)
    $変数名テキスト.Text = "入力値"

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(230, 250)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(330, 250)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $タイトルテキスト, $ラベル2, $プロンプトテキスト, $ラベル3, $デフォルトテキスト, $ラベル4, $変数名テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $タイトル = $タイトルテキスト.Text
    $プロンプト = $プロンプトテキスト.Text
    $デフォルト = $デフォルトテキスト.Text
    $変数名 = $変数名テキスト.Text

    $デフォルト引数 = if ($デフォルト) { " -デフォルト値 `"$デフォルト`"" } else { "" }

    $entryString = @"
# 入力ダイアログ: $タイトル
`$$変数名 = 入力ダイアログ表示 -タイトル "$タイトル" -プロンプト "$プロンプト"$デフォルト引数
変数を追加する -変数 `$変数 -名前 "$変数名" -型 "単一値" -値 `$$変数名
if (`$null -eq `$$変数名) {
    Write-Host "入力がキャンセルされました" -ForegroundColor Yellow
} else {
    Write-Host "入力値: `$$変数名" -ForegroundColor Green
}
"@

    return $entryString
}
