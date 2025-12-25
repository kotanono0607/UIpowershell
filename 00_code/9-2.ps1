﻿function 9_2 {
    $ウインドウリスト = 開いているウインドウタイトル取得

    # タイトルからブラウザ名等を削除して整形
    $整形済みリスト = $ウインドウリスト | ForEach-Object {
        $t = $_
        # " - " で分割してブラウザ関連パーツを除去
        $parts = $t -split '\s*-\s+'
        $filteredParts = @()
        foreach ($part in $parts) {
            $p = $part.Trim()
            # ブラウザ関連キーワードを含むパーツをスキップ
            if ($p -match 'Microsoft.*Edge|Google.*Chrome|Mozilla.*Firefox|^\[InPrivate\]$|^InPrivate$|^シークレット$|^プライベート$') {
                continue
            }
            if ($p -ne '') {
                $filteredParts += $p
            }
        }
        ($filteredParts -join ' - ').Trim()
    } | Sort-Object -Unique

    $選択された項目 = リストから項目を選択 -フォームタイトル "ウインドウ待機" -ラベルテキスト "待機するウインドウを選択してください:" -選択肢リスト $整形済みリスト

    if ($選択された項目) {
        return "ウインドウ待機 -ウインドウ名の一部 `"$選択された項目`""
    } else {
        return "# キャンセルされました"
    }
}
