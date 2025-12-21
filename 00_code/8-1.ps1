
function 8_1 {

$スクリプトPath = $PSScriptRoot # 現在のスクリプトのディレクトリを変数に格納

$変数ファイルパス =  $global:JSONPath# JSONファイルのパスを指定

# variables.jsonが存在しない場合は初期化
if (-not (Test-Path -Path $変数ファイルパス)) {
    Write-Host "variables.jsonが存在しないため、新規作成します: $変数ファイルパス"
    # 親ディレクトリが存在しない場合は作成
    $親ディレクトリ = Split-Path -Path $変数ファイルパス -Parent
    if (-not (Test-Path -Path $親ディレクトリ)) {
        New-Item -Path $親ディレクトリ -ItemType Directory -Force | Out-Null
    }
    # 空のJSONオブジェクトを書き込み
    @{} | ConvertTo-Json -Depth 10 | Out-File -FilePath $変数ファイルパス -Encoding UTF8
}

# 変数をJSONファイルから読み込む
$変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス

# 関数の呼び出し
$選択結果 = Excelファイルとシート名を選択
$Excelファイルパス = $選択結果.Excelファイルパス
$シート名 = $選択結果.シート名

# Excelからデータを取得
$myTwoDimArray = @(Excelシートデータ取得 -Excelファイルパス $Excelファイルパス -選択シート名 $シート名)

変数を追加する -変数 $変数 -名前 "Excel2次元配列" -型 "二次元" -値 $myTwoDimArray
変数をJSONに保存する -変数 $変数　# 変数をJSONファイルに保存


# 生成するコード（パスと値は直接埋め込み）
$entryString = @"
`$my2 = Excelシートデータ取得 -Excelファイルパス "$Excelファイルパス" -選択シート名 "$シート名"
変数を追加する -変数 `$変数 -名前 "Excel2次元配列" -型 "二次元" -値 `$my2
変数をJSONに保存する -変数 `$変数
"@

return $entryString
}
