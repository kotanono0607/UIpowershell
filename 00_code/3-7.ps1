function 3_7 {
    # 変数から入力：変数の値を文字列として入力

    $変数ファイルパス = $global:JSONPath
    $変数 = @{}

    if (Test-Path -Path $変数ファイルパス) {
        $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "変数から入力"
    $フォーム.Size = New-Object System.Drawing.Size(450, 280)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # 変数選択
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "入力に使用する変数："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $変数コンボ = New-Object System.Windows.Forms.ComboBox
    $変数コンボ.Location = New-Object System.Drawing.Point(20, 45)
    $変数コンボ.Size = New-Object System.Drawing.Size(250, 25)
    $変数コンボ.DropDownStyle = "DropDown"

    # 既存の変数をリストに追加
    if ($変数.Count -gt 0) {
        foreach ($key in $変数.Keys) {
            $変数コンボ.Items.Add($key)
        }
        if ($変数コンボ.Items.Count -gt 0) {
            $変数コンボ.SelectedIndex = 0
        }
    }

    # 入力方法
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "入力方法："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $入力方法コンボ = New-Object System.Windows.Forms.ComboBox
    $入力方法コンボ.Location = New-Object System.Drawing.Point(20, 110)
    $入力方法コンボ.Size = New-Object System.Drawing.Size(200, 25)
    $入力方法コンボ.DropDownStyle = "DropDownList"
    $入力方法コンボ.Items.AddRange(@("クリップボード貼付（高速）", "1文字ずつ入力（確実）"))
    $入力方法コンボ.SelectedIndex = 0

    # Enterキー送信オプション
    $Enter送信チェック = New-Object System.Windows.Forms.CheckBox
    $Enter送信チェック.Text = "入力後にEnterキーを送信"
    $Enter送信チェック.Location = New-Object System.Drawing.Point(20, 150)
    $Enter送信チェック.AutoSize = $true

    # 説明
    $説明ラベル = New-Object System.Windows.Forms.Label
    $説明ラベル.Text = "※ 変数に格納された値をテキストとして入力します"
    $説明ラベル.Location = New-Object System.Drawing.Point(20, 185)
    $説明ラベル.AutoSize = $true
    $説明ラベル.ForeColor = [System.Drawing.Color]::Gray

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(240, 200)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(340, 200)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $変数コンボ, $ラベル2, $入力方法コンボ, $Enter送信チェック, $説明ラベル, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $変数名 = $変数コンボ.Text.Trim()
    $入力方法 = $入力方法コンボ.SelectedItem
    $Enter送信 = $Enter送信チェック.Checked

    if ([string]::IsNullOrWhiteSpace($変数名)) {
        return "# キャンセルされました"
    }

    $コード行 = @()
    $コード行 += "# 変数から入力: `$$変数名"

    if ($入力方法 -eq "クリップボード貼付（高速）") {
        $コード行 += "文字列貼付 -入力文字列 `$$変数名"
    } else {
        $コード行 += "文字列入力 -入力文字列 `$$変数名"
    }

    if ($Enter送信) {
        $コード行 += "キー操作 -キーコマンド `"Enter`""
    }

    $コード行 += "Write-Host `"変数 '$変数名' の値を入力しました`" -ForegroundColor Green"

    return ($コード行 -join "`n")
}
