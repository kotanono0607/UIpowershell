
function 10_1 {

$スクリプトPath = $PSScriptRoot # 現在のスクリプトのディレクトリを変数に格納
$メインPath = Split-Path $スクリプトPath # ひとつ上の階層のパスを取得
Import-Module "$メインPath\02_modules\20250531_screenShot.psm1" -Force
# ウィンドウ選択 → 矩形選択 → スクリーンショット保存
$スクリーンショット = ウィンドウ選択してスクリーンショット


# $global:folderPathの値を生成時に埋め込む（CONVERTED_ROUTESの$PSScriptRoot置換問題を回避）
'画像マッチ移動 -ファイル名 "' + $スクリーンショット + '" -しきい値 0.7 -フォルダパス "' + $global:folderPath + '"'

}
