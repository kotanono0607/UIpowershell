# ページ末尾へスクロール機能
# 更新: 2025-12-20
function 4_4 {
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

    $選択された項目 = リストから項目を選択 -フォームタイトル "ページ末尾へスクロール" -ラベルテキスト "スクロールするウインドウを選択してください:" -選択肢リスト $整形済みリスト

    if ($選択された項目) {
        return "ページ末尾へスクロール -ウインドウ名 `"$選択された項目`""
    } else {
        return "# キャンセルされました"
    }
}
