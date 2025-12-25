﻿
function 98_1 {
  param (
    [string]$直接エントリ
      )

# 関数ノードのコード生成処理
# ピンクノード（99-1）と同様に、含まれるノードのIDリストを展開する

$直接エントリ = "AAAA_" + $直接エントリ

# 直接エントリのアンダースコアを改行に置き換える（CRLF）
$processedEntry = $直接エントリ -replace '_', "`r`n"

# 置換後のエントリを含む複数行の文字列を作成

$entryString = @"
$processedEntry
"@

return $entryString
}
