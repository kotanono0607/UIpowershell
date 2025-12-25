# 3-1.ps1 Ver 2.0 - ウィンドウ選択対応版

function 3_1 {
    # ウィンドウ選択モジュールをインポート
    $スクリプトPath = $PSScriptRoot
    $メインPath = Split-Path $スクリプトPath
    $modulePath = Join-Path -Path $メインPath -ChildPath '02_modules\ウィンドウ選択.psm1'

    $windowMode = $false
    $windowTitle = ""

    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force

        # ウィンドウ選択（全画面オプション付き）
        $selection = Show-WindowSelectorWithFullscreen -DialogTitle "キー送信先を選択"

        if ($null -eq $selection) {
            return "# キャンセルされました"
        }

        if ($selection.Mode -eq "Window") {
            $windowMode = $true
            $windowTitle = $selection.Title
        }
    }

    # ダイアログを表示して値を取得
    $キーコマンドリスト = @(
        # 基本操作
        "Ctrl+A", "Ctrl+C", "Ctrl+V", "Ctrl+X",
        # ファイル操作
        "Ctrl+S", "Ctrl+Z", "Ctrl+Y", "Ctrl+N", "Ctrl+O", "Ctrl+P", "Ctrl+W",
        # 検索・その他
        "Ctrl+F", "Alt+F4", "Alt+Tab",
        # 特殊キー
        "Enter", "Tab", "Shift+Tab", "Esc", "Del", "Backspace", "Space",
        # ナビゲーション
        "Home", "End", "PageUp", "PageDown",
        "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight",
        # ファンクションキー
        "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"
    )
    $選択された項目 = リストから項目を選択 -フォームタイトル "キーコマンドの選択" -ラベルテキスト "キーコマンドを選択してください:" -選択肢リスト $キーコマンドリスト

    # 選択された値を使って固定値のコードを生成
    if ($選択された項目) {
        if ($windowMode) {
            # ウィンドウ指定版: ウィンドウをアクティブ化してからキー送信
            return "ウィンドウ指定キー操作 -ウィンドウ名 `"$windowTitle`" -キーコマンド `"$選択された項目`""
        } else {
            # 従来版: グローバルにキー送信
            return "キー操作 -キーコマンド `"$選択された項目`""
        }
    } else {
        return "# キャンセルされました"
    }
}
