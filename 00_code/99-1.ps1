
function 99_1 {
  param (
    [string]$直接エントリ
      )


$直接エントリ = "AAAA_" + $直接エントリ

# 直接エントリのアンダースコアを改行に置き換える（CRLF）
$processedEntry = $直接エントリ -replace '_', "`r`n"

# 置換後のエントリを含む複数行の文字列を作成（AAAAとprocessedEntryの間に改行を追加）

$entryString = @"
$processedEntry
"@



return $entryString
}
