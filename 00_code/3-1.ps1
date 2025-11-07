
function 3_1 {
    # ダイアログを表示して値を取得
    $キーコマンドリスト = @("Ctrl+A", "Ctrl+C", "Ctrl+V", "Ctrl+F", "Alt+F4", "Del", "Enter", "Tab", "Shift+Tab", "PageUp", "PageDown", "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "Esc")
    $選択された項目 = リストから項目を選択 -フォームタイトル "キーコマンドの選択" -ラベルテキスト "キーコマンドを選択してください:" -選択肢リスト $キーコマンドリスト

    # 選択された値を使って固定値のコードを生成
    if ($選択された項目) {
        return "キー操作 -キーコマンド `"$選択された項目`""
    } else {
        return "# キャンセルされました"
    }
}
