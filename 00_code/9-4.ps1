﻿function 9_4 {
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

    $選択された項目 = リストから項目を選択 -フォームタイトル "ウインドウ最大化" -ラベルテキスト "最大化するウインドウを選択してください:" -選択肢リスト $整形済みリスト

    if ($選択された項目) {
        return "特定タイトルウインドウを最大化する -タイトル `"$選択された項目`""
    } else {
        return "# キャンセルされました"
    }
}
