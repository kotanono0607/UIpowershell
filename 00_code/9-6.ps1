function 9_6 {
    # ウインドウを閉じる：指定したウインドウを閉じる

    $ウインドウリスト = 開いているウインドウタイトル取得

    # タイトルからブラウザ名等を削除して整形
    $整形済みリスト = $ウインドウリスト | ForEach-Object {
        $t = $_
        $parts = $t -split '\s*-\s+'
        $filteredParts = @()
        foreach ($part in $parts) {
            $p = $part.Trim()
            if ($p -match 'Microsoft.*Edge|Google.*Chrome|Mozilla.*Firefox|^\[InPrivate\]$|^InPrivate$|^シークレット$|^プライベート$') {
                continue
            }
            if ($p -ne '') {
                $filteredParts += $p
            }
        }
        ($filteredParts -join ' - ').Trim()
    } | Sort-Object -Unique

    $選択された項目 = リストから項目を選択 -フォームタイトル "ウインドウを閉じる" -ラベルテキスト "閉じるウインドウを選択してください:" -選択肢リスト $整形済みリスト

    if ($選択された項目) {
        return @"
# ウインドウを閉じる: $選択された項目
`$ウインドウハンドル = 文字列からウインドウハンドルを探す -検索文字列 "$選択された項目"
if (`$ウインドウハンドル) {
    ウインドウを閉じる -ウインドウハンドル `$ウインドウハンドル
    Write-Host "ウインドウ '$選択された項目' を閉じました" -ForegroundColor Green
} else {
    Write-Host "ウインドウ '$選択された項目' が見つかりません" -ForegroundColor Yellow
}
"@
    } else {
        return "# キャンセルされました"
    }
}
