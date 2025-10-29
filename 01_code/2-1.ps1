
function 2_1 {
$スクリプトPath = $PSScriptRoot # 現在のスクリプトのディレクトリを変数に格納
Import-Module "$スクリプトPath\コード\20241019_point.psm1" -Force
$inputNumber = Invoke-MouseGet -Caller "Addon1"  # Caller を明示的に指定
@"
$inputNumber
"@
}
