
function 5_2 {
    # ダイアログを表示してURLを取得
    $URL = 文字列を入力 -フォームタイトル "URLを開く" -ラベルテキスト "開くURLを入力してください:"

    # 入力された値を使ってコードを生成
    if ($URL) {
        return "URLを開く -URL `"$URL`""
    } else {
        return "# キャンセルされました"
    }
}
