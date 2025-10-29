
function 4_2 {

$スクリプトPath = $PSScriptRoot # 現在のスクリプトのディレクトリを変数に格納
Import-Module "$スクリプトPath\コード\20241016_psUIGET.psm1" -Force
$inputNumber = Invoke-UIlement -Caller "AddonUI2"  # Caller を明示的に指定

@"
$inputNumber
"@
}
