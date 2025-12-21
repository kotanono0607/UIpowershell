function 3_6 {
    # キーシーケンス：複数のキーを順番に送信

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "キーシーケンス"
    $フォーム.Size = New-Object System.Drawing.Size(500, 400)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # プリセット選択
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "プリセットから選択："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $プリセットコンボ = New-Object System.Windows.Forms.ComboBox
    $プリセットコンボ.Location = New-Object System.Drawing.Point(20, 45)
    $プリセットコンボ.Size = New-Object System.Drawing.Size(300, 25)
    $プリセットコンボ.DropDownStyle = "DropDownList"
    $プリセットリスト = @(
        "カスタム",
        "全選択してコピー (Ctrl+A → Ctrl+C)",
        "全選択して切り取り (Ctrl+A → Ctrl+X)",
        "全選択して貼り付け (Ctrl+A → Ctrl+V)",
        "保存して閉じる (Ctrl+S → Alt+F4)",
        "検索して次へ (Ctrl+F → Enter)",
        "コピーして貼り付け (Ctrl+C → Ctrl+V)",
        "アドレスバーコピー (Alt+D → Ctrl+C)",
        "新規タブでURL開く (Ctrl+T → Ctrl+V → Enter)"
    )
    $プリセットコンボ.Items.AddRange($プリセットリスト)
    $プリセットコンボ.SelectedIndex = 0

    # シーケンス入力
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "キーシーケンス（カンマ区切り）："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $シーケンステキスト = New-Object System.Windows.Forms.TextBox
    $シーケンステキスト.Location = New-Object System.Drawing.Point(20, 110)
    $シーケンステキスト.Size = New-Object System.Drawing.Size(440, 25)
    $シーケンステキスト.Text = ""

    # 使用可能なキー一覧
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "使用可能なキー："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 145)
    $ラベル3.AutoSize = $true

    $キー一覧 = New-Object System.Windows.Forms.TextBox
    $キー一覧.Location = New-Object System.Drawing.Point(20, 170)
    $キー一覧.Size = New-Object System.Drawing.Size(440, 60)
    $キー一覧.Multiline = $true
    $キー一覧.ReadOnly = $true
    $キー一覧.Text = "Ctrl+A, Ctrl+C, Ctrl+V, Ctrl+X, Ctrl+Z, Ctrl+Y, Ctrl+S, Ctrl+F, Ctrl+N, Ctrl+O, Ctrl+P, Ctrl+W, Alt+F4, Alt+Tab, Alt+D, Ctrl+T, Enter, Tab, Shift+Tab, Esc, Del, Backspace, Space, Home, End, PageUp, PageDown, ArrowUp, ArrowDown, ArrowLeft, ArrowRight, F1-F12"
    $キー一覧.BackColor = [System.Drawing.Color]::WhiteSmoke

    # 間隔
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "キー間の待機時間（ミリ秒）："
    $ラベル4.Location = New-Object System.Drawing.Point(20, 245)
    $ラベル4.AutoSize = $true

    $間隔 = New-Object System.Windows.Forms.NumericUpDown
    $間隔.Location = New-Object System.Drawing.Point(200, 242)
    $間隔.Size = New-Object System.Drawing.Size(80, 25)
    $間隔.Minimum = 100
    $間隔.Maximum = 5000
    $間隔.Value = 500

    # プリセット変更時の処理
    $プリセットコンボ.Add_SelectedIndexChanged({
        $プリセットマップ = @{
            "全選択してコピー (Ctrl+A → Ctrl+C)" = "Ctrl+A, Ctrl+C"
            "全選択して切り取り (Ctrl+A → Ctrl+X)" = "Ctrl+A, Ctrl+X"
            "全選択して貼り付け (Ctrl+A → Ctrl+V)" = "Ctrl+A, Ctrl+V"
            "保存して閉じる (Ctrl+S → Alt+F4)" = "Ctrl+S, Alt+F4"
            "検索して次へ (Ctrl+F → Enter)" = "Ctrl+F, Enter"
            "コピーして貼り付け (Ctrl+C → Ctrl+V)" = "Ctrl+C, Ctrl+V"
            "アドレスバーコピー (Alt+D → Ctrl+C)" = "Alt+D, Ctrl+C"
            "新規タブでURL開く (Ctrl+T → Ctrl+V → Enter)" = "Ctrl+T, Ctrl+V, Enter"
        }
        $選択 = $プリセットコンボ.SelectedItem
        if ($プリセットマップ.ContainsKey($選択)) {
            $シーケンステキスト.Text = $プリセットマップ[$選択]
        }
    })

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(290, 320)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(390, 320)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $プリセットコンボ, $ラベル2, $シーケンステキスト, $ラベル3, $キー一覧, $ラベル4, $間隔, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $シーケンス = $シーケンステキスト.Text.Trim()
    $間隔ミリ秒 = $間隔.Value

    if ([string]::IsNullOrWhiteSpace($シーケンス)) {
        return "# キャンセルされました"
    }

    # キーシーケンスを解析してコード生成
    $キー配列 = $シーケンス -split '\s*,\s*'
    $コード行 = @()
    $コード行 += "# キーシーケンス: $シーケンス"
    $コード行 += "Write-Host `"キーシーケンス実行開始`" -ForegroundColor Cyan"

    foreach ($キー in $キー配列) {
        $コード行 += "キー操作 -キーコマンド `"$キー`""
        $コード行 += "Start-Sleep -Milliseconds $間隔ミリ秒"
    }
    $コード行 += "Write-Host `"キーシーケンス完了`" -ForegroundColor Green"

    return ($コード行 -join "`n")
}
