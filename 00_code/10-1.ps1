﻿# 10-1.ps1 Ver 2.0 - ウィンドウ限定検索対応版

function 10_1 {

$スクリプトPath = $PSScriptRoot
$メインPath = Split-Path $スクリプトPath

# ウィンドウ選択モジュールをインポート
$modulePath = Join-Path -Path $メインPath -ChildPath '02_modules\ウィンドウ選択.psm1'
$windowTitle = ""
$windowMode = $false

if (Test-Path $modulePath) {
    Import-Module $modulePath -Force

    # ウィンドウ選択（全画面オプション付き）
    $selection = Show-WindowSelectorWithFullscreen -DialogTitle "画像マッチング対象を選択"

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

# $global:folderPathの値を生成時に埋め込む（CONVERTED_ROUTESの$PSScriptRoot置換問題を回避）
if ($windowMode) {
    # ウィンドウ限定版: ウィンドウ内のみで検索
    '画像マッチ移動 -ファイル名 "' + $スクリーンショット + '" -しきい値 0.7 -フォルダパス "' + $global:folderPath + '" -ウィンドウ名 "' + $windowTitle + '"'
} else {
    # 全画面版: 既存動作
    '画像マッチ移動 -ファイル名 "' + $スクリーンショット + '" -しきい値 0.7 -フォルダパス "' + $global:folderPath + '"'
}

}
