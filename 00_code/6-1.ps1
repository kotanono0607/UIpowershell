﻿function 6_1 {
    $変数名 = 文字列を入力 -フォームタイトル "クリップボード取得" -ラベルテキスト "格納先の変数名:"

    if ($変数名 -ne $null) {
        return "`$$変数名 = Get-Clipboard"
    } else {
        return "# キャンセルされました"
    }
}
