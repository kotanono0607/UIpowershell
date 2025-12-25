﻿function 7_7 {
    # リスト選択ダイアログ：リストから項目を選択するダイアログを表示

    $変数ファイルパス = $global:JSONPath
    $変数 = @{}

    if (Test-Path -Path $変数ファイルパス) {
        $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "リスト選択ダイアログ設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 420)
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
    $タイトルテキスト.Size = New-Object System.Drawing.Size(440, 25)
    $タイトルテキスト.Text = "項目を選択してください"

    # ラベルテキスト
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "説明文："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 80)
    $ラベル2.AutoSize = $true

    $説明テキスト = New-Object System.Windows.Forms.TextBox
    $説明テキスト.Location = New-Object System.Drawing.Point(20, 105)
    $説明テキスト.Size = New-Object System.Drawing.Size(440, 25)
    $説明テキスト.Text = "以下のリストから選択してください:"

    # 選択肢リスト
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "選択肢（1行に1項目）："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 140)
    $ラベル3.AutoSize = $true

    $選択肢テキスト = New-Object System.Windows.Forms.TextBox
    $選択肢テキスト.Location = New-Object System.Drawing.Point(20, 165)
    $選択肢テキスト.Size = New-Object System.Drawing.Size(440, 100)
    $選択肢テキスト.Multiline = $true
    $選択肢テキスト.ScrollBars = "Vertical"
    $選択肢テキスト.Text = "項目1`r`n項目2`r`n項目3"

    # 結果変数名
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "結果を格納する変数名："
    $ラベル4.Location = New-Object System.Drawing.Point(20, 280)
    $ラベル4.AutoSize = $true

    $変数名テキスト = New-Object System.Windows.Forms.TextBox
    $変数名テキスト.Location = New-Object System.Drawing.Point(20, 305)
    $変数名テキスト.Size = New-Object System.Drawing.Size(200, 25)
    $変数名テキスト.Text = "選択項目"

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(290, 345)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(390, 345)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $タイトルテキスト, $ラベル2, $説明テキスト, $ラベル3, $選択肢テキスト, $ラベル4, $変数名テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $タイトル = $タイトルテキスト.Text
    $説明 = $説明テキスト.Text
    $選択肢配列 = ($選択肢テキスト.Text -split "`r`n" | Where-Object { $_ -ne "" })
    $変数名 = $変数名テキスト.Text

    if ($選択肢配列.Count -eq 0) {
        return "# キャンセルされました（選択肢が空です）"
    }

    # 選択肢を文字列として整形
    $選択肢文字列 = ($選択肢配列 | ForEach-Object { "`"$_`"" }) -join ", "

    $entryString = @"
# リスト選択ダイアログ: $タイトル
`$選択肢リスト = @($選択肢文字列)
`$$変数名 = リストから項目を選択 -フォームタイトル "$タイトル" -ラベルテキスト "$説明" -選択肢リスト `$選択肢リスト
if (`$$変数名) {
    変数を追加する -変数 `$変数 -名前 "$変数名" -型 "単一値" -値 `$$変数名
    Write-Host "選択された項目: `$$変数名" -ForegroundColor Green
} else {
    Write-Host "選択がキャンセルされました" -ForegroundColor Yellow
}
"@

    return $entryString
}
