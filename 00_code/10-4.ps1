﻿
function 10_4 {
    # 画像存在確認：画像が画面上に存在するかを確認

    $スクリプトPath = $PSScriptRoot
    $メインPath = Split-Path $スクリプトPath

    # ウィンドウ選択モジュールをインポート
    $modulePath = Join-Path -Path $メインPath -ChildPath '02_modules\ウィンドウ選択.psm1'
    $windowTitle = ""
    $windowMode = $false

    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force

        # ウィンドウ選択（全画面オプション付き）
        $selection = Show-WindowSelectorWithFullscreen -DialogTitle "画像確認対象を選択"

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

    $変数ファイルパス = $global:JSONPath
    $変数 = @{}

    if (Test-Path -Path $変数ファイルパス) {
        $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "画像存在確認設定"
    $フォーム.Size = New-Object System.Drawing.Size(400, 250)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # 選択した画像
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "確認する画像: $スクリーンショット"
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

    # 結果変数名
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "結果を格納する変数名："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 120)
    $ラベル3.AutoSize = $true

    $変数名テキスト = New-Object System.Windows.Forms.TextBox
    $変数名テキスト.Location = New-Object System.Drawing.Point(20, 145)
    $変数名テキスト.Size = New-Object System.Drawing.Size(200, 25)
    $変数名テキスト.Text = "画像存在"

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(180, 180)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(280, 180)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $ラベル2, $しきい値テキスト, $ラベル3, $変数名テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $しきい値 = $しきい値テキスト.Text
    $変数名 = $変数名テキスト.Text

    if ($windowMode) {
        $entryString = @"
# 画像存在確認: $スクリーンショット (ウィンドウ: $windowTitle)
`$$変数名 = 画像存在確認 -ファイル名 "$スクリーンショット" -しきい値 $しきい値 -フォルダパス "$($global:folderPath)" -ウィンドウ名 "$windowTitle"
変数を追加する -変数 `$変数 -名前 "$変数名" -型 "単一値" -値 `$$変数名
if (`$$変数名) {
    Write-Host "画像が見つかりました: $スクリーンショット" -ForegroundColor Green
} else {
    Write-Host "画像が見つかりませんでした: $スクリーンショット" -ForegroundColor Yellow
}
"@
    } else {
        $entryString = @"
# 画像存在確認: $スクリーンショット
`$$変数名 = 画像存在確認 -ファイル名 "$スクリーンショット" -しきい値 $しきい値 -フォルダパス "$($global:folderPath)"
変数を追加する -変数 `$変数 -名前 "$変数名" -型 "単一値" -値 `$$変数名
if (`$$変数名) {
    Write-Host "画像が見つかりました: $スクリーンショット" -ForegroundColor Green
} else {
    Write-Host "画像が見つかりませんでした: $スクリーンショット" -ForegroundColor Yellow
}
"@
    }

    return $entryString
}
