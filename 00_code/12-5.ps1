﻿function 12_5 {
    # 処理中断：スクリプトの実行を中断する

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "処理中断設定"
    $フォーム.Size = New-Object System.Drawing.Size(450, 280)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # 中断タイプ
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "中断タイプ："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $中断タイプコンボ = New-Object System.Windows.Forms.ComboBox
    $中断タイプコンボ.Location = New-Object System.Drawing.Point(20, 45)
    $中断タイプコンボ.Size = New-Object System.Drawing.Size(200, 25)
    $中断タイプコンボ.DropDownStyle = "DropDownList"
    $中断タイプコンボ.Items.AddRange(@("スクリプト終了", "エラーで終了", "ループ中断（Break）", "次の繰り返しへ（Continue）"))
    $中断タイプコンボ.SelectedIndex = 0

    # メッセージ
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "終了メッセージ（省略可）："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $メッセージテキスト = New-Object System.Windows.Forms.TextBox
    $メッセージテキスト.Location = New-Object System.Drawing.Point(20, 110)
    $メッセージテキスト.Size = New-Object System.Drawing.Size(390, 60)
    $メッセージテキスト.Multiline = $true
    $メッセージテキスト.Text = ""

    $説明ラベル = New-Object System.Windows.Forms.Label
    $説明ラベル.Text = "※ スクリプト終了: 正常終了`n※ エラーで終了: エラーとして終了`n※ ループ中断: 現在のループを抜ける`n※ 次の繰り返しへ: ループの次の回へスキップ"
    $説明ラベル.Location = New-Object System.Drawing.Point(20, 180)
    $説明ラベル.Size = New-Object System.Drawing.Size(400, 60)
    $説明ラベル.ForeColor = [System.Drawing.Color]::Gray

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(230, 245)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(330, 245)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $中断タイプコンボ, $ラベル2, $メッセージテキスト, $説明ラベル, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $中断タイプ = $中断タイプコンボ.SelectedItem
    $メッセージ = $メッセージテキスト.Text -replace "`r`n", " "

    $entryString = switch ($中断タイプ) {
        "スクリプト終了" {
            if ($メッセージ) {
                @"
# 処理中断: スクリプト終了
Write-Host "$メッセージ" -ForegroundColor Cyan
exit 0
"@
            } else {
                @"
# 処理中断: スクリプト終了
exit 0
"@
            }
        }
        "エラーで終了" {
            if ($メッセージ) {
                @"
# 処理中断: エラーで終了
Write-Host "$メッセージ" -ForegroundColor Red
exit 1
"@
            } else {
                @"
# 処理中断: エラーで終了
exit 1
"@
            }
        }
        "ループ中断（Break）" {
            if ($メッセージ) {
                @"
# 処理中断: ループ中断
Write-Host "$メッセージ" -ForegroundColor Yellow
break
"@
            } else {
                @"
# 処理中断: ループ中断
break
"@
            }
        }
        "次の繰り返しへ（Continue）" {
            if ($メッセージ) {
                @"
# 処理中断: 次の繰り返しへスキップ
Write-Host "$メッセージ" -ForegroundColor Yellow
continue
"@
            } else {
                @"
# 処理中断: 次の繰り返しへスキップ
continue
"@
            }
        }
    }

    return $entryString
}
