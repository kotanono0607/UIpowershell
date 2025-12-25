﻿# UI操作機能 (AddonUI1)
# 更新: 2025-12-20 - メインメニュー最小化対応
function 4_1 {

# 最初にメインメニューを最小化
$menuHandle = メインメニューを最小化

try {
    $スクリプトPath = $PSScriptRoot # 現在のスクリプトのディレクトリを変数に格納

    $メインPath = Split-Path $スクリプトPath # ひとつ上の階層のパスを取得


    Import-Module "$メインPath\02_modules\20241016_psUIGET.psm1" -Force
    $inputNumber = Invoke-UIlement -Caller "AddonUI1"  # Caller を明示的に指定

    @"
$inputNumber
"@
} finally {
    # 最後にメインメニューを復元
    メインメニューを復元 -ハンドル $menuHandle
}
}
