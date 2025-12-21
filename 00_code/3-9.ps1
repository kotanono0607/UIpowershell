function 3_9 {
    # カスタムキー送信：SendKeys形式でキーを送信

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "カスタムキー送信"
    $フォーム.Size = New-Object System.Drawing.Size(500, 380)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # 入力フィールド
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "SendKeys形式で入力："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $キーテキスト = New-Object System.Windows.Forms.TextBox
    $キーテキスト.Location = New-Object System.Drawing.Point(20, 45)
    $キーテキスト.Size = New-Object System.Drawing.Size(440, 25)
    $キーテキスト.Text = ""

    # ヘルプ
    $ヘルプラベル = New-Object System.Windows.Forms.Label
    $ヘルプラベル.Text = "SendKeys記法一覧："
    $ヘルプラベル.Location = New-Object System.Drawing.Point(20, 85)
    $ヘルプラベル.AutoSize = $true

    $ヘルプテキスト = New-Object System.Windows.Forms.TextBox
    $ヘルプテキスト.Location = New-Object System.Drawing.Point(20, 110)
    $ヘルプテキスト.Size = New-Object System.Drawing.Size(440, 150)
    $ヘルプテキスト.Multiline = $true
    $ヘルプテキスト.ReadOnly = $true
    $ヘルプテキスト.ScrollBars = "Vertical"
    $ヘルプテキスト.Text = @"
修飾キー:
  ^ = Ctrl    例: ^c = Ctrl+C
  + = Shift   例: +{TAB} = Shift+Tab
  % = Alt     例: %{F4} = Alt+F4

特殊キー（{}で囲む）:
  {ENTER}  {TAB}  {ESC}  {BACKSPACE}  {DELETE}
  {UP} {DOWN} {LEFT} {RIGHT}
  {HOME} {END} {PGUP} {PGDN}
  {F1}～{F12}
  {CAPSLOCK}  {NUMLOCK}  {SCROLLLOCK}
  {INSERT}  {BREAK}  {HELP}

特殊文字:
  + ^ % ~ ( ) { } [ ] をそのまま送信するには{}で囲む
  例: {+} = プラス記号

繰り返し:
  {キー 回数}  例: {RIGHT 5} = 右矢印5回
"@
    $ヘルプテキスト.BackColor = [System.Drawing.Color]::WhiteSmoke

    # 例
    $例ラベル = New-Object System.Windows.Forms.Label
    $例ラベル.Text = "例: ^a^c = 全選択してコピー、%{F4} = Alt+F4"
    $例ラベル.Location = New-Object System.Drawing.Point(20, 270)
    $例ラベル.AutoSize = $true
    $例ラベル.ForeColor = [System.Drawing.Color]::Gray

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(290, 300)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(390, 300)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $キーテキスト, $ヘルプラベル, $ヘルプテキスト, $例ラベル, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $キー文字列 = $キーテキスト.Text

    if ([string]::IsNullOrWhiteSpace($キー文字列)) {
        return "# キャンセルされました"
    }

    # エスケープ処理（ダブルクォート内で使用するため）
    $エスケープ済み = $キー文字列 -replace '"', '`"'

    $entryString = @"
# カスタムキー送信: $キー文字列
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait("$エスケープ済み")
Write-Host "カスタムキーを送信しました" -ForegroundColor Green
"@

    return $entryString
}
