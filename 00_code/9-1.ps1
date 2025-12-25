﻿
function 9_1 {
    # ダイアログを表示して値を取得
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

    $選択された項目 = リストから項目を選択 -フォームタイトル "ウインドウの選択" -ラベルテキスト "対象のウインドウを選択してください:" -選択肢リスト $整形済みリスト

    # 選択された値を使って固定値のコードを生成
    if ($選択された項目) {
        return "`$存在 = ウインドウ存在確認 -タイトル `"$選択された項目`" -完全一致"
    } else {
        return "# キャンセルされました"
    }
}