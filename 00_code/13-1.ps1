# JSテキストクリック機能
# 更新: 2025-12-20
# ブラウザ上の指定テキストを持つ要素をJavaScriptでクリック
function 13_1 {
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
    $選択された項目 = リストから項目を選択 -フォームタイトル "JSテキストクリック" -ラベルテキスト "対象ブラウザウインドウを選択してください:" -選択肢リスト $整形済みリスト

    if (-not $選択された項目) {
        return "# キャンセルされました"
    }

    # テキスト入力
    Add-Type -AssemblyName Microsoft.VisualBasic
    $検索テキスト = [Microsoft.VisualBasic.Interaction]::InputBox("クリックしたいテキストを入力してください:", "検索テキスト", "")

    if (-not $検索テキスト) {
        return "# キャンセルされました"
    }

    # 一致方法選択
    $一致リスト = @("部分一致", "完全一致")
    $選択された一致 = リストから項目を選択 -フォームタイトル "一致方法" -ラベルテキスト "テキストの一致方法を選択してください:" -選択肢リスト $一致リスト

    if (-not $選択された一致) {
        return "# キャンセルされました"
    }

    return "JSテキストクリック -ウインドウ名 `"$選択された項目`" -検索テキスト `"$検索テキスト`" -一致方法 `"$選択された一致`""
}
