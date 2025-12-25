﻿function 9_8 {
    # ウインドウ移動・サイズ変更：ウインドウの位置とサイズを変更

    $ウインドウリスト = 開いているウインドウタイトル取得

    # タイトルからブラウザ名等を削除して整形
    $整形済みリスト = $ウインドウリスト | ForEach-Object {
        $t = $_
        $parts = $t -split '\s*-\s+'
        $filteredParts = @()
        foreach ($part in $parts) {
            $p = $part.Trim()
            if ($p -match 'Microsoft.*Edge|Google.*Chrome|Mozilla.*Firefox|^\[InPrivate\]$|^InPrivate$|^シークレット$|^プライベート$') {
                continue
            }
            if ($p -ne '') {
                $filteredParts += $p
            }
        }
        ($filteredParts -join ' - ').Trim()
    } | Sort-Object -Unique

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "ウインドウ移動・サイズ変更"
    $フォーム.Size = New-Object System.Drawing.Size(450, 350)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # ウインドウ選択
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "対象ウインドウ："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $ウインドウコンボ = New-Object System.Windows.Forms.ComboBox
    $ウインドウコンボ.Location = New-Object System.Drawing.Point(20, 45)
    $ウインドウコンボ.Size = New-Object System.Drawing.Size(390, 25)
    $ウインドウコンボ.DropDownStyle = "DropDownList"
    foreach ($w in $整形済みリスト) {
        $ウインドウコンボ.Items.Add($w) | Out-Null
    }
    if ($ウインドウコンボ.Items.Count -gt 0) {
        $ウインドウコンボ.SelectedIndex = 0
    }

    # 位置設定
    $位置グループ = New-Object System.Windows.Forms.GroupBox
    $位置グループ.Text = "位置"
    $位置グループ.Location = New-Object System.Drawing.Point(20, 80)
    $位置グループ.Size = New-Object System.Drawing.Size(190, 100)

    $位置変更チェック = New-Object System.Windows.Forms.CheckBox
    $位置変更チェック.Text = "位置を変更"
    $位置変更チェック.Location = New-Object System.Drawing.Point(10, 20)
    $位置変更チェック.AutoSize = $true

    $Xラベル = New-Object System.Windows.Forms.Label
    $Xラベル.Text = "X:"
    $Xラベル.Location = New-Object System.Drawing.Point(10, 50)
    $Xラベル.AutoSize = $true

    $X入力 = New-Object System.Windows.Forms.NumericUpDown
    $X入力.Location = New-Object System.Drawing.Point(30, 48)
    $X入力.Size = New-Object System.Drawing.Size(60, 25)
    $X入力.Minimum = -10000
    $X入力.Maximum = 10000
    $X入力.Value = 0

    $Yラベル = New-Object System.Windows.Forms.Label
    $Yラベル.Text = "Y:"
    $Yラベル.Location = New-Object System.Drawing.Point(100, 50)
    $Yラベル.AutoSize = $true

    $Y入力 = New-Object System.Windows.Forms.NumericUpDown
    $Y入力.Location = New-Object System.Drawing.Point(120, 48)
    $Y入力.Size = New-Object System.Drawing.Size(60, 25)
    $Y入力.Minimum = -10000
    $Y入力.Maximum = 10000
    $Y入力.Value = 0

    $位置グループ.Controls.AddRange(@($位置変更チェック, $Xラベル, $X入力, $Yラベル, $Y入力))

    # サイズ設定
    $サイズグループ = New-Object System.Windows.Forms.GroupBox
    $サイズグループ.Text = "サイズ"
    $サイズグループ.Location = New-Object System.Drawing.Point(220, 80)
    $サイズグループ.Size = New-Object System.Drawing.Size(190, 100)

    $サイズ変更チェック = New-Object System.Windows.Forms.CheckBox
    $サイズ変更チェック.Text = "サイズを変更"
    $サイズ変更チェック.Location = New-Object System.Drawing.Point(10, 20)
    $サイズ変更チェック.AutoSize = $true

    $幅ラベル = New-Object System.Windows.Forms.Label
    $幅ラベル.Text = "幅:"
    $幅ラベル.Location = New-Object System.Drawing.Point(10, 50)
    $幅ラベル.AutoSize = $true

    $幅入力 = New-Object System.Windows.Forms.NumericUpDown
    $幅入力.Location = New-Object System.Drawing.Point(35, 48)
    $幅入力.Size = New-Object System.Drawing.Size(60, 25)
    $幅入力.Minimum = 100
    $幅入力.Maximum = 10000
    $幅入力.Value = 800

    $高さラベル = New-Object System.Windows.Forms.Label
    $高さラベル.Text = "高:"
    $高さラベル.Location = New-Object System.Drawing.Point(100, 50)
    $高さラベル.AutoSize = $true

    $高さ入力 = New-Object System.Windows.Forms.NumericUpDown
    $高さ入力.Location = New-Object System.Drawing.Point(125, 48)
    $高さ入力.Size = New-Object System.Drawing.Size(60, 25)
    $高さ入力.Minimum = 100
    $高さ入力.Maximum = 10000
    $高さ入力.Value = 600

    $サイズグループ.Controls.AddRange(@($サイズ変更チェック, $幅ラベル, $幅入力, $高さラベル, $高さ入力))

    # プリセット
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "プリセット："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 195)
    $ラベル2.AutoSize = $true

    $プリセットコンボ = New-Object System.Windows.Forms.ComboBox
    $プリセットコンボ.Location = New-Object System.Drawing.Point(20, 220)
    $プリセットコンボ.Size = New-Object System.Drawing.Size(200, 25)
    $プリセットコンボ.DropDownStyle = "DropDownList"
    $プリセットコンボ.Items.AddRange(@("カスタム", "左上", "右上", "左下", "右下", "中央", "左半分", "右半分"))
    $プリセットコンボ.SelectedIndex = 0

    $プリセットコンボ.Add_SelectedIndexChanged({
        $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
        switch ($プリセットコンボ.SelectedItem) {
            "左上" { $位置変更チェック.Checked = $true; $X入力.Value = 0; $Y入力.Value = 0 }
            "右上" { $位置変更チェック.Checked = $true; $X入力.Value = $screen.Width - $幅入力.Value; $Y入力.Value = 0 }
            "左下" { $位置変更チェック.Checked = $true; $X入力.Value = 0; $Y入力.Value = $screen.Height - $高さ入力.Value }
            "右下" { $位置変更チェック.Checked = $true; $X入力.Value = $screen.Width - $幅入力.Value; $Y入力.Value = $screen.Height - $高さ入力.Value }
            "中央" { $位置変更チェック.Checked = $true; $X入力.Value = ($screen.Width - $幅入力.Value) / 2; $Y入力.Value = ($screen.Height - $高さ入力.Value) / 2 }
            "左半分" { $位置変更チェック.Checked = $true; $サイズ変更チェック.Checked = $true; $X入力.Value = 0; $Y入力.Value = 0; $幅入力.Value = $screen.Width / 2; $高さ入力.Value = $screen.Height }
            "右半分" { $位置変更チェック.Checked = $true; $サイズ変更チェック.Checked = $true; $X入力.Value = $screen.Width / 2; $Y入力.Value = 0; $幅入力.Value = $screen.Width / 2; $高さ入力.Value = $screen.Height }
        }
    })

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(240, 275)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(340, 275)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $ウインドウコンボ, $位置グループ, $サイズグループ, $ラベル2, $プリセットコンボ, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $選択ウインドウ = $ウインドウコンボ.SelectedItem
    if (-not $選択ウインドウ) { return "# キャンセルされました" }

    if (-not $位置変更チェック.Checked -and -not $サイズ変更チェック.Checked) {
        return "# キャンセルされました（変更項目なし）"
    }

    $X = [int]$X入力.Value
    $Y = [int]$Y入力.Value
    $幅 = [int]$幅入力.Value
    $高さ = [int]$高さ入力.Value

    $コード = @()
    $コード += "# ウインドウ移動・サイズ変更: $選択ウインドウ"
    $コード += "`$ウインドウハンドル = 文字列からウインドウハンドルを探す -検索文字列 `"$選択ウインドウ`""

    if ($位置変更チェック.Checked -and $サイズ変更チェック.Checked) {
        $コード += "ウインドウ移動サイズ変更 -ウインドウハンドル `$ウインドウハンドル -X $X -Y $Y -幅 $幅 -高さ $高さ"
        $コード += "Write-Host `"ウインドウを位置($X, $Y)、サイズ(${幅}x${高さ})に変更しました`" -ForegroundColor Green"
    } elseif ($位置変更チェック.Checked) {
        $コード += "ウインドウ移動 -ウインドウハンドル `$ウインドウハンドル -X $X -Y $Y"
        $コード += "Write-Host `"ウインドウを位置($X, $Y)に移動しました`" -ForegroundColor Green"
    } else {
        $コード += "ウインドウサイズ変更 -ウインドウハンドル `$ウインドウハンドル -幅 $幅 -高さ $高さ"
        $コード += "Write-Host `"ウインドウをサイズ(${幅}x${高さ})に変更しました`" -ForegroundColor Green"
    }

    return ($コード -join "`n")
}
