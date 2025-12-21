
function 10_1 {

$スクリプトPath = $PSScriptRoot # 現在のスクリプトのディレクトリを変数に格納
$メインPath = Split-Path $スクリプトPath # ひとつ上の階層のパスを取得
Import-Module "$メインPath\02_modules\20250531_screenShot.psm1" -Force
$スクリーンショット 　= 　全画面ドラッグ矩形オーバーレイ


@"

画像マッチ移動 -ファイル名 "$スクリーンショット" -しきい値 0.7 -フォルダパス `$PSScriptRoot

"@

}
