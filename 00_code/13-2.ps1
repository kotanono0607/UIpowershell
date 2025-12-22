function 13_2 {
    # Excel(操作) - セル値設定
    # Excelファイルの指定セルに値を設定（列・行分離指定、変数対応）

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # 設定ダイアログ
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "セル値設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 380)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.MinimizeBox = $false
    $フォーム.Topmost = $true

    # ファイルパス
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "Excelファイルパス："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $パステキスト = New-Object System.Windows.Forms.TextBox
    $パステキスト.Location = New-Object System.Drawing.Point(20, 45)
    $パステキスト.Size = New-Object System.Drawing.Size(350, 25)

    $参照ボタン = New-Object System.Windows.Forms.Button
    $参照ボタン.Text = "参照..."
    $参照ボタン.Location = New-Object System.Drawing.Point(380, 43)
    $参照ボタン.Size = New-Object System.Drawing.Size(80, 28)
    $参照ボタン.Add_Click({
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "Excelファイル (*.xlsx)|*.xlsx"
        $saveDialog.Title = "Excelファイルを選択"
        if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $パステキスト.Text = $saveDialog.FileName
        }
    })

    # シート名
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "シート名（空欄で最初のシート）："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $シートテキスト = New-Object System.Windows.Forms.TextBox
    $シートテキスト.Location = New-Object System.Drawing.Point(20, 110)
    $シートテキスト.Size = New-Object System.Drawing.Size(200, 25)

    # 列番号
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "列番号（数値または変数名 例: 1, $列）："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $列テキスト = New-Object System.Windows.Forms.TextBox
    $列テキスト.Location = New-Object System.Drawing.Point(20, 175)
    $列テキスト.Size = New-Object System.Drawing.Size(150, 25)
    $列テキスト.Text = "1"

    # 行番号
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "行番号（数値または変数名 例: 1, $行）："
    $ラベル4.Location = New-Object System.Drawing.Point(230, 150)
    $ラベル4.AutoSize = $true

    $行テキスト = New-Object System.Windows.Forms.TextBox
    $行テキスト.Location = New-Object System.Drawing.Point(230, 175)
    $行テキスト.Size = New-Object System.Drawing.Size(150, 25)
    $行テキスト.Text = "1"

    # 設定値
    $ラベル5 = New-Object System.Windows.Forms.Label
    $ラベル5.Text = "設定する値（変数も使用可 例: $値）："
    $ラベル5.Location = New-Object System.Drawing.Point(20, 215)
    $ラベル5.AutoSize = $true

    $値テキスト = New-Object System.Windows.Forms.TextBox
    $値テキスト.Location = New-Object System.Drawing.Point(20, 240)
    $値テキスト.Size = New-Object System.Drawing.Size(250, 25)

    # ヒント
    $ヒントラベル = New-Object System.Windows.Forms.Label
    $ヒントラベル.Text = "※ 変数を使用する場合は `$変数名 の形式で入力してください"
    $ヒントラベル.Location = New-Object System.Drawing.Point(20, 280)
    $ヒントラベル.AutoSize = $true
    $ヒントラベル.ForeColor = [System.Drawing.Color]::Gray

    # ボタン
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

    $フォーム.Controls.AddRange(@($ラベル1, $パステキスト, $参照ボタン, $ラベル2, $シートテキスト, $ラベル3, $列テキスト, $ラベル4, $行テキスト, $ラベル5, $値テキスト, $ヒントラベル, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    $ファイルパス = $パステキスト.Text
    $シート名 = $シートテキスト.Text
    $列入力 = $列テキスト.Text
    $行入力 = $行テキスト.Text
    $設定値 = $値テキスト.Text

    if ([string]::IsNullOrWhiteSpace($ファイルパス) -or [string]::IsNullOrWhiteSpace($列入力) -or [string]::IsNullOrWhiteSpace($行入力)) {
        [System.Windows.Forms.MessageBox]::Show("ファイルパス、列番号、行番号は必須です。", "エラー")
        return $null
    }

    # 変数かどうかを判定
    $列は変数 = $列入力.StartsWith('$')
    $行は変数 = $行入力.StartsWith('$')
    $値は変数 = $設定値.StartsWith('$')

    # パラメータ生成
    $列パラメータ = if ($列は変数) { $列入力 } else { $列入力 }
    $行パラメータ = if ($行は変数) { $行入力 } else { $行入力 }
    $値パラメータ = if ($値は変数) { $設定値 } else { "`"$設定値`"" }
    $シートパラメータ = if ([string]::IsNullOrEmpty($シート名)) { "" } else { " -シート名 `"$シート名`"" }

    # コメント用の表示
    $列表示 = if ($列は変数) { "列=$列入力" } else { "列$列入力" }
    $行表示 = if ($行は変数) { "行=$行入力" } else { "行$行入力" }

    $entryString = @"
# セル値設定: $列表示, $行表示 = $設定値
Excel操作_セル値設定_行列 -ファイルパス "$ファイルパス" -列番号 $列パラメータ -行番号 $行パラメータ -値 $値パラメータ$シートパラメータ
"@

    return $entryString
}
