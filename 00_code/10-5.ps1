﻿
function 10_5 {
    # 画像クリック：画像を見つけてクリック

    $スクリプトPath = $PSScriptRoot
    $メインPath = Split-Path $スクリプトPath

    # ウィンドウ選択モジュールをインポート
    $modulePath = Join-Path -Path $メインPath -ChildPath '02_modules\ウィンドウ選択.psm1'
    $windowTitle = ""
    $windowMode = $false

    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force

        # ウィンドウ選択（全画面オプション付き）
        $selection = Show-WindowSelectorWithFullscreen -DialogTitle "画像クリック対象を選択"

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
    $フォーム.Text = "画像クリック設定"
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
    $ラベル1.Text = "クリックする画像: $スクリーンショット"
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true
    $ラベル1.ForeColor = [System.Drawing.Color]::Blue

    # しきい値
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "しきい値（0.1〜1.0）："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 55)
    $ラベル2.AutoSize = $true

    $しきい値テキスト = New-Object System.Windows.Forms.TextBox
    $しきい値テキスト.Location = New-Object System.Drawing.Point(20, 80)
    $しきい値テキスト.Size = New-Object System.Drawing.Size(80, 25)
    $しきい値テキスト.Text = "0.7"

    # クリック種類
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "クリック種類："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 120)
    $ラベル3.AutoSize = $true

    $クリック種類コンボ = New-Object System.Windows.Forms.ComboBox
    $クリック種類コンボ.Location = New-Object System.Drawing.Point(20, 145)
    $クリック種類コンボ.Size = New-Object System.Drawing.Size(150, 25)
    $クリック種類コンボ.DropDownStyle = "DropDownList"
    $クリック種類コンボ.Items.AddRange(@("左クリック", "ダブルクリック", "右クリック"))
    $クリック種類コンボ.SelectedIndex = 0

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

    $フォーム.Controls.AddRange(@($ラベル1, $ラベル2, $しきい値テキスト, $ラベル3, $クリック種類コンボ, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $しきい値 = $しきい値テキスト.Text
    $クリック種類 = $クリック種類コンボ.SelectedItem

    $クリックオプション = switch ($クリック種類) {
        "ダブルクリック" { " -ダブルクリック" }
        "右クリック" { " -右クリック" }
        default { "" }
    }

    if ($windowMode) {
        $entryString = @"
# 画像クリック: $スクリーンショット ($クリック種類, ウィンドウ: $windowTitle)
`$クリック結果 = 画像クリック -ファイル名 "$スクリーンショット" -しきい値 $しきい値 -フォルダパス "$($global:folderPath)" -ウィンドウ名 "$windowTitle"$クリックオプション
if (-not `$クリック結果) {
    Write-Host "画像が見つからなかったためクリックできませんでした: $スクリーンショット" -ForegroundColor Yellow
}
"@
    } else {
        $entryString = @"
# 画像クリック: $スクリーンショット ($クリック種類)
`$クリック結果 = 画像クリック -ファイル名 "$スクリーンショット" -しきい値 $しきい値 -フォルダパス "$($global:folderPath)"$クリックオプション
if (-not `$クリック結果) {
    Write-Host "画像が見つからなかったためクリックできませんでした: $スクリーンショット" -ForegroundColor Yellow
}
"@
    }

    return $entryString
}
