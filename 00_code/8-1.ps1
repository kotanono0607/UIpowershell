
function 8_1 {

$スクリプトPath = $PSScriptRoot # 現在のスクリプトのディレクトリを変数に格納

$変数ファイルパス =  $global:JSONPath# JSONファイルのパスを指定
# 変数をJSONファイルから読み込む
$変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス

# 関数の呼び出し
$選択結果 = Excelファイルとシート名を選択
$Excelファイルパス = $選択結果.Excelファイルパス
$シート名 = $選択結果.シート名

# 下記は一時的に実行
$myTwoDimArray = Excelシートデータ取得 -Excelファイルパス $Excelファイルパス -選択シート名 $シート名
変数を追加する -変数 $変数 -名前 "Excel2次元配列" -型 "二次元" -値 $myTwoDimArray
変数をJSONに保存する -変数 $変数　# 変数をJSONファイルに保存


# ヒアドキュメントの作成（$my2や$変数をそのまま文字列として保持）
$entryString = @"
`$my2 = Excelシートデータ取得 -Excelファイルパス `$Excelファイルパス -選択シート名 `$シート名
変数を追加する -変数 `$変数 -名前 "Excel2次元配列" -型 "二次元" -値 `$my2
変数をJSONに保存する -変数 `$変数　# 変数をJSONファイルに保存
"@

# 必要な変数を置換
$entryString = $entryString -replace '\$シート名', $シート名 -replace '\$Excelファイルパス', $Excelファイルパス

return $entryString
}
