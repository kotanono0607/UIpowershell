﻿function 5_7 {
    # プロセス待機：プロセスの開始または終了を待機

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "プロセス待機"
    $フォーム.Size = New-Object System.Drawing.Size(450, 280)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # プロセス名
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "待機するプロセス名（例: notepad, chrome）："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $プロセス名テキスト = New-Object System.Windows.Forms.TextBox
    $プロセス名テキスト.Location = New-Object System.Drawing.Point(20, 45)
    $プロセス名テキスト.Size = New-Object System.Drawing.Size(300, 25)
    $プロセス名テキスト.Text = ""

    # 待機タイプ
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "待機タイプ："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $待機タイプコンボ = New-Object System.Windows.Forms.ComboBox
    $待機タイプコンボ.Location = New-Object System.Drawing.Point(20, 110)
    $待機タイプコンボ.Size = New-Object System.Drawing.Size(200, 25)
    $待機タイプコンボ.DropDownStyle = "DropDownList"
    $待機タイプコンボ.Items.AddRange(@("プロセス開始を待機", "プロセス終了を待機"))
    $待機タイプコンボ.SelectedIndex = 0

    # タイムアウト
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "タイムアウト（秒、0=無制限）："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $タイムアウト = New-Object System.Windows.Forms.NumericUpDown
    $タイムアウト.Location = New-Object System.Drawing.Point(20, 175)
    $タイムアウト.Size = New-Object System.Drawing.Size(80, 25)
    $タイムアウト.Minimum = 0
    $タイムアウト.Maximum = 3600
    $タイムアウト.Value = 60

    # チェック間隔
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "チェック間隔（ミリ秒）："
    $ラベル4.Location = New-Object System.Drawing.Point(150, 150)
    $ラベル4.AutoSize = $true

    $間隔 = New-Object System.Windows.Forms.NumericUpDown
    $間隔.Location = New-Object System.Drawing.Point(150, 175)
    $間隔.Size = New-Object System.Drawing.Size(80, 25)
    $間隔.Minimum = 100
    $間隔.Maximum = 10000
    $間隔.Value = 500

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

    $フォーム.Controls.AddRange(@($ラベル1, $プロセス名テキスト, $ラベル2, $待機タイプコンボ, $ラベル3, $タイムアウト, $ラベル4, $間隔, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $プロセス名 = $プロセス名テキスト.Text
    $待機タイプ = $待機タイプコンボ.SelectedItem
    $タイムアウト秒 = $タイムアウト.Value
    $間隔ミリ秒 = $間隔.Value

    if ([string]::IsNullOrWhiteSpace($プロセス名)) {
        return "# キャンセルされました"
    }

    if ($待機タイプ -eq "プロセス開始を待機") {
        if ($タイムアウト秒 -eq 0) {
            $entryString = @"
# プロセス開始待機: $プロセス名 (無制限)
Write-Host "プロセス '$プロセス名' の開始を待機中..." -ForegroundColor Cyan
while (-not (Get-Process -Name "$プロセス名" -ErrorAction SilentlyContinue)) {
    Start-Sleep -Milliseconds $間隔ミリ秒
}
Write-Host "プロセス '$プロセス名' が開始されました" -ForegroundColor Green
"@
        } else {
            $entryString = @"
# プロセス開始待機: $プロセス名 (タイムアウト: ${タイムアウト秒}秒)
Write-Host "プロセス '$プロセス名' の開始を待機中..." -ForegroundColor Cyan
`$開始時刻 = Get-Date
`$タイムアウト = $タイムアウト秒
`$プロセス検出 = `$false
while ((Get-Date) -lt `$開始時刻.AddSeconds(`$タイムアウト)) {
    if (Get-Process -Name "$プロセス名" -ErrorAction SilentlyContinue) {
        `$プロセス検出 = `$true
        break
    }
    Start-Sleep -Milliseconds $間隔ミリ秒
}
if (`$プロセス検出) {
    Write-Host "プロセス '$プロセス名' が開始されました" -ForegroundColor Green
} else {
    Write-Host "タイムアウト: プロセス '$プロセス名' は開始されませんでした" -ForegroundColor Yellow
}
"@
        }
    } else {
        # プロセス終了待機
        if ($タイムアウト秒 -eq 0) {
            $entryString = @"
# プロセス終了待機: $プロセス名 (無制限)
`$対象プロセス = Get-Process -Name "$プロセス名" -ErrorAction SilentlyContinue
if (`$対象プロセス) {
    Write-Host "プロセス '$プロセス名' の終了を待機中..." -ForegroundColor Cyan
    `$対象プロセス | Wait-Process
    Write-Host "プロセス '$プロセス名' が終了しました" -ForegroundColor Green
} else {
    Write-Host "プロセス '$プロセス名' は実行されていません" -ForegroundColor Yellow
}
"@
        } else {
            $entryString = @"
# プロセス終了待機: $プロセス名 (タイムアウト: ${タイムアウト秒}秒)
`$対象プロセス = Get-Process -Name "$プロセス名" -ErrorAction SilentlyContinue
if (`$対象プロセス) {
    Write-Host "プロセス '$プロセス名' の終了を待機中..." -ForegroundColor Cyan
    `$待機結果 = `$対象プロセス | Wait-Process -Timeout $タイムアウト秒 -ErrorAction SilentlyContinue
    if (-not (Get-Process -Name "$プロセス名" -ErrorAction SilentlyContinue)) {
        Write-Host "プロセス '$プロセス名' が終了しました" -ForegroundColor Green
    } else {
        Write-Host "タイムアウト: プロセス '$プロセス名' はまだ実行中です" -ForegroundColor Yellow
    }
} else {
    Write-Host "プロセス '$プロセス名' は実行されていません" -ForegroundColor Yellow
}
"@
        }
    }

    return $entryString
}
