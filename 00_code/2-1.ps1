
function 2_1 {
$スクリプトPath = $PSScriptRoot # 現在のスクリプトのディレクトリを変数に格納
$メインPath = Split-Path $スクリプトPath # ひとつ上の階層のパスを取得
Import-Module "$メインPath\02_modules\20241019_point.psm1" -Force
$inputNumber = Invoke-MouseGet -Caller "Addon1"  # Caller を明示的に指定
@"
$inputNumber
"@
}
