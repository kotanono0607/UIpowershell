
function 3_1 {
# 使用例: キーコマンドのリストを定義
# ★ 変数をバッククォートでエスケープして、生成されたコードに含める
@"
`$キーコマンドリスト = @("Ctrl+A", "Ctrl+C", "Ctrl+V", "Ctrl+F", "Alt+F4", "Del", "Enter", "Tab", "Shift+Tab", "PageUp", "PageDown", "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "Esc")
`$選択された項目 = リストから項目を選択 -フォームタイトル "キーコマンドの選択" -ラベルテキスト "キーコマンドを選択してください:" -選択肢リスト `$キーコマンドリスト
キー操作 -キーコマンド `$選択された項目
"@

}
