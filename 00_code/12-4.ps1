function 12_4 {
    # コメント：スクリプト内にコメント（メモ）を追加

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "コメント追加"
    $フォーム.Size = New-Object System.Drawing.Size(450, 220)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # コメント
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "コメント（メモ）："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $コメントテキスト = New-Object System.Windows.Forms.TextBox
    $コメントテキスト.Location = New-Object System.Drawing.Point(20, 45)
    $コメントテキスト.Size = New-Object System.Drawing.Size(390, 80)
    $コメントテキスト.Multiline = $true
    $コメントテキスト.ScrollBars = "Vertical"
    $コメントテキスト.Text = ""

    $説明ラベル = New-Object System.Windows.Forms.Label
    $説明ラベル.Text = "※ 処理には影響しないメモとしてスクリプトに追加されます"
    $説明ラベル.Location = New-Object System.Drawing.Point(20, 135)
    $説明ラベル.AutoSize = $true
    $説明ラベル.ForeColor = [System.Drawing.Color]::Gray

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(230, 155)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(330, 155)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $コメントテキスト, $説明ラベル, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $コメント = $コメントテキスト.Text

    if ([string]::IsNullOrWhiteSpace($コメント)) {
        return "# キャンセルされました"
    }

    # 複数行の場合は各行にコメント記号を付ける
    $コメント行 = $コメント -split "`r?`n" | ForEach-Object { "# $_" }
    $entryString = $コメント行 -join "`n"

    return $entryString
}
