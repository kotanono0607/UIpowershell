﻿
function 4_1 {

$スクリプトPath = $PSScriptRoot # 現在のスクリプトのディレクトリを変数に格納

$メインPath = Split-Path $スクリプトPath # ひとつ上の階層のパスを取得


Import-Module "$メインPath\コード\20241016_psUIGET.psm1" -Force
$inputNumber = Invoke-UIlement -Caller "AddonUI1"  # Caller を明示的に指定

@"
$inputNumber
"@
}
