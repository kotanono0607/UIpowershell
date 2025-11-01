
function 4_2 {

$スクリプトPath = $PSScriptRoot # 現在のスクリプトのディレクトリを変数に格納
$メインPath = Split-Path $スクリプトPath # ひとつ上の階層のパスを取得
Import-Module "$メインPath\02_modules\20241016_psUIGET.psm1" -Force
$inputNumber = Invoke-UIlement -Caller "AddonUI2"  # Caller を明示的に指定

@"
$inputNumber
"@
}
