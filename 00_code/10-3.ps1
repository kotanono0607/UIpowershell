﻿
function 10_3 {
    # 画像待機：画像が表示されるまで待機

    $スクリプトPath = $PSScriptRoot
    $メインPath = Split-Path $スクリプトPath

    # ウィンドウ選択モジュールをインポート
    $modulePath = Join-Path -Path $メインPath -ChildPath '02_modules\ウィンドウ選択.psm1'
    $windowTitle = ""
    $windowMode = $false

    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force

        # ウィンドウ選択（全画面オプション付き）
        $selection = Show-WindowSelectorWithFullscreen -DialogTitle "画像待機対象を選択"

        if ($null -eq $selection) {
            return "# キャンセルされました"
        }

        if ($selection.Mode -eq "Window") {
            $windowMode = $true
            $windowTitle = $selection.Title

            # 選択したウィンドウをフォアグラウンドに
            Start-Sleep -Milliseconds 200
            if ([WindowHelper]::IsIconic($selection.Handle)) {
                [WindowHelper]::ShowWindow($selection.Handle, 9) | Out-Null
            }
            [WindowHelper]::SetForegroundWindow($selection.Handle) | Out-Null
            Start-Sleep -Milliseconds 500
        }
    }

    # スクリーンショットモジュールをインポート
    Import-Module "$メインPath\02_modules\20250531_screenShot.psm1" -Force

    # 矩形選択 → スクリーンショット保存
    $スクリーンショット = 全画面ドラッグ矩形オーバーレイ

    if ([string]::IsNullOrEmpty($スクリーンショット)) {
        return "# キャンセルされました"
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "画像待機設定"
    $フォーム.Size = New-Object System.Drawing.Size(400, 280)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # 選択した画像
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "待機する画像: $スクリーンショット"
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true
    $ラベル1.ForeColor = [System.Drawing.Color]::Blue

    # タイムアウト
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "タイムアウト（秒）："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 55)
    $ラベル2.AutoSize = $true

    $タイムアウト = New-Object System.Windows.Forms.NumericUpDown
    $タイムアウト.Location = New-Object System.Drawing.Point(20, 80)
    $タイムアウト.Size = New-Object System.Drawing.Size(80, 25)
    $タイムアウト.Minimum = 1
    $タイムアウト.Maximum = 300
    $タイムアウト.Value = 30

    # しきい値
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "しきい値（0.1〜1.0）："
    $ラベル3.Location = New-Object System.Drawing.Point(150, 55)
    $ラベル3.AutoSize = $true

    $しきい値テキスト = New-Object System.Windows.Forms.TextBox
    $しきい値テキスト.Location = New-Object System.Drawing.Point(150, 80)
    $しきい値テキスト.Size = New-Object System.Drawing.Size(80, 25)
    $しきい値テキスト.Text = "0.7"

    # チェック間隔
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "チェック間隔（ミリ秒）："
    $ラベル4.Location = New-Object System.Drawing.Point(20, 120)
    $ラベル4.AutoSize = $true

    $間隔 = New-Object System.Windows.Forms.NumericUpDown
    $間隔.Location = New-Object System.Drawing.Point(20, 145)
    $間隔.Size = New-Object System.Drawing.Size(80, 25)
    $間隔.Minimum = 100
    $間隔.Maximum = 5000
    $間隔.Value = 500

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(180, 200)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(280, 200)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $ラベル2, $タイムアウト, $ラベル3, $しきい値テキスト, $ラベル4, $間隔, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $タイムアウト秒 = $タイムアウト.Value
    $しきい値 = $しきい値テキスト.Text
    $間隔ミリ秒 = $間隔.Value

    if ($windowMode) {
        $entryString = @"
# 画像待機: $スクリーンショット (タイムアウト: ${タイムアウト秒}秒, ウィンドウ: $windowTitle)
`$画像待機結果 = 画像待機 -ファイル名 "$スクリーンショット" -しきい値 $しきい値 -タイムアウト秒 $タイムアウト秒 -間隔ミリ秒 $間隔ミリ秒 -フォルダパス "$($global:folderPath)" -ウィンドウ名 "$windowTitle"
if (-not `$画像待機結果) {
    Write-Host "画像が見つかりませんでした: $スクリーンショット" -ForegroundColor Yellow
}
"@
    } else {
        $entryString = @"
# 画像待機: $スクリーンショット (タイムアウト: ${タイムアウト秒}秒)
`$画像待機結果 = 画像待機 -ファイル名 "$スクリーンショット" -しきい値 $しきい値 -タイムアウト秒 $タイムアウト秒 -間隔ミリ秒 $間隔ミリ秒 -フォルダパス "$($global:folderPath)"
if (-not `$画像待機結果) {
    Write-Host "画像が見つかりませんでした: $スクリーンショット" -ForegroundColor Yellow
}
"@
    }

    return $entryString
}
