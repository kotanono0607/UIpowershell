﻿function 5_5 {
    # プロセス終了：実行中のプロセスを終了する

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "プロセス終了"
    $フォーム.Size = New-Object System.Drawing.Size(450, 280)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # プロセス名
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "終了するプロセス名（例: notepad, chrome）："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $プロセス名テキスト = New-Object System.Windows.Forms.TextBox
    $プロセス名テキスト.Location = New-Object System.Drawing.Point(20, 45)
    $プロセス名テキスト.Size = New-Object System.Drawing.Size(300, 25)
    $プロセス名テキスト.Text = ""

    # 現在のプロセス一覧ボタン
    $一覧ボタン = New-Object System.Windows.Forms.Button
    $一覧ボタン.Text = "一覧..."
    $一覧ボタン.Location = New-Object System.Drawing.Point(330, 44)
    $一覧ボタン.Size = New-Object System.Drawing.Size(80, 27)
    $一覧ボタン.Add_Click({
        $プロセス一覧 = Get-Process | Where-Object { $_.MainWindowTitle -ne "" } | Sort-Object ProcessName | Select-Object -Property ProcessName, MainWindowTitle -Unique

        $選択フォーム = New-Object System.Windows.Forms.Form
        $選択フォーム.Text = "プロセスを選択"
        $選択フォーム.Size = New-Object System.Drawing.Size(500, 400)
        $選択フォーム.StartPosition = "CenterScreen"
        $選択フォーム.Topmost = $true
    $選択フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

        $リストビュー = New-Object System.Windows.Forms.ListView
        $リストビュー.Location = New-Object System.Drawing.Point(10, 10)
        $リストビュー.Size = New-Object System.Drawing.Size(465, 300)
        $リストビュー.View = "Details"
        $リストビュー.FullRowSelect = $true
        $リストビュー.Columns.Add("プロセス名", 150)
        $リストビュー.Columns.Add("ウィンドウタイトル", 300)

        foreach ($p in $プロセス一覧) {
            $item = New-Object System.Windows.Forms.ListViewItem($p.ProcessName)
            $item.SubItems.Add($p.MainWindowTitle)
            $リストビュー.Items.Add($item)
        }

        $選択ボタン = New-Object System.Windows.Forms.Button
        $選択ボタン.Text = "選択"
        $選択ボタン.Location = New-Object System.Drawing.Point(300, 320)
        $選択ボタン.Size = New-Object System.Drawing.Size(80, 30)
        $選択ボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

        $閉じるボタン = New-Object System.Windows.Forms.Button
        $閉じるボタン.Text = "閉じる"
        $閉じるボタン.Location = New-Object System.Drawing.Point(390, 320)
        $閉じるボタン.Size = New-Object System.Drawing.Size(80, 30)
        $閉じるボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

        $選択フォーム.Controls.AddRange(@($リストビュー, $選択ボタン, $閉じるボタン))
        $選択フォーム.AcceptButton = $選択ボタン

        if ($選択フォーム.ShowDialog() -eq "OK" -and $リストビュー.SelectedItems.Count -gt 0) {
            $プロセス名テキスト.Text = $リストビュー.SelectedItems[0].Text
        }
    })

    # 終了方法
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "終了方法："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $終了方法コンボ = New-Object System.Windows.Forms.ComboBox
    $終了方法コンボ.Location = New-Object System.Drawing.Point(20, 110)
    $終了方法コンボ.Size = New-Object System.Drawing.Size(200, 25)
    $終了方法コンボ.DropDownStyle = "DropDownList"
    $終了方法コンボ.Items.AddRange(@("通常終了（推奨）", "強制終了"))
    $終了方法コンボ.SelectedIndex = 0

    # オプション
    $全終了チェック = New-Object System.Windows.Forms.CheckBox
    $全終了チェック.Text = "同名のプロセスをすべて終了"
    $全終了チェック.Location = New-Object System.Drawing.Point(20, 150)
    $全終了チェック.AutoSize = $true
    $全終了チェック.Checked = $true

    $確認チェック = New-Object System.Windows.Forms.CheckBox
    $確認チェック.Text = "終了前に確認ダイアログを表示"
    $確認チェック.Location = New-Object System.Drawing.Point(20, 175)
    $確認チェック.AutoSize = $true

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(240, 210)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(340, 210)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $プロセス名テキスト, $一覧ボタン, $ラベル2, $終了方法コンボ, $全終了チェック, $確認チェック, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $プロセス名 = $プロセス名テキスト.Text
    $強制終了 = ($終了方法コンボ.SelectedItem -eq "強制終了")

    if ([string]::IsNullOrWhiteSpace($プロセス名)) {
        return "# キャンセルされました"
    }

    $強制オプション = if ($強制終了) { " -Force" } else { "" }

    if ($確認チェック.Checked) {
        $entryString = @"
# プロセス終了: $プロセス名 (確認あり)
Add-Type -AssemblyName System.Windows.Forms
`$確認結果 = [System.Windows.Forms.MessageBox]::Show("プロセス '$プロセス名' を終了しますか？", "確認", "YesNo", "Question")
if (`$確認結果 -eq "Yes") {
    `$対象プロセス = Get-Process -Name "$プロセス名" -ErrorAction SilentlyContinue
    if (`$対象プロセス) {
        Stop-Process -Name "$プロセス名"$強制オプション -ErrorAction SilentlyContinue
        Write-Host "プロセス '$プロセス名' を終了しました" -ForegroundColor Green
    } else {
        Write-Host "プロセス '$プロセス名' は実行されていません" -ForegroundColor Yellow
    }
} else {
    Write-Host "プロセス終了がキャンセルされました" -ForegroundColor Yellow
}
"@
    } else {
        $entryString = @"
# プロセス終了: $プロセス名
`$対象プロセス = Get-Process -Name "$プロセス名" -ErrorAction SilentlyContinue
if (`$対象プロセス) {
    Stop-Process -Name "$プロセス名"$強制オプション -ErrorAction SilentlyContinue
    Write-Host "プロセス '$プロセス名' を終了しました" -ForegroundColor Green
} else {
    Write-Host "プロセス '$プロセス名' は実行されていません" -ForegroundColor Yellow
}
"@
    }

    return $entryString
}
