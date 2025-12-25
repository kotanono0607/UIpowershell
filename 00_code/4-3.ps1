# ページスクロール機能
# 更新: 2025-12-20
function 4_3 {
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

    # ウインドウ選択
    $選択された項目 = リストから項目を選択 -フォームタイトル "ページスクロール" -ラベルテキスト "スクロールするウインドウを選択してください:" -選択肢リスト $整形済みリスト

    if (-not $選択された項目) {
        return "# キャンセルされました"
    }

    # 方向選択
    $方向リスト = @("下", "上")
    $選択された方向 = リストから項目を選択 -フォームタイトル "スクロール方向" -ラベルテキスト "スクロール方向を選択してください:" -選択肢リスト $方向リスト

    if (-not $選択された方向) {
        return "# キャンセルされました"
    }

    # スクロール量（デフォルト10）
    return "ページスクロール -ウインドウ名 `"$選択された項目`" -方向 `"$選択された方向`" -スクロール量 10"
}
