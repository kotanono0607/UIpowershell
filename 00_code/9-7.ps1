﻿function 9_7 {
    # ウインドウ情報取得：ウインドウの位置とサイズを取得

    $変数ファイルパス = $global:JSONPath
    $変数 = @{}

    if (Test-Path -Path $変数ファイルパス) {
        $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス
    }

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
    $フォーム.Text = "ウインドウ情報取得"
    $フォーム.Size = New-Object System.Drawing.Size(450, 320)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

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

    # 取得項目
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "取得する情報："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $X座標チェック = New-Object System.Windows.Forms.CheckBox
    $X座標チェック.Text = "X座標"
    $X座標チェック.Location = New-Object System.Drawing.Point(20, 110)
    $X座標チェック.AutoSize = $true
    $X座標チェック.Checked = $true

    $Y座標チェック = New-Object System.Windows.Forms.CheckBox
    $Y座標チェック.Text = "Y座標"
    $Y座標チェック.Location = New-Object System.Drawing.Point(100, 110)
    $Y座標チェック.AutoSize = $true
    $Y座標チェック.Checked = $true

    $幅チェック = New-Object System.Windows.Forms.CheckBox
    $幅チェック.Text = "幅"
    $幅チェック.Location = New-Object System.Drawing.Point(180, 110)
    $幅チェック.AutoSize = $true
    $幅チェック.Checked = $true

    $高さチェック = New-Object System.Windows.Forms.CheckBox
    $高さチェック.Text = "高さ"
    $高さチェック.Location = New-Object System.Drawing.Point(240, 110)
    $高さチェック.AutoSize = $true
    $高さチェック.Checked = $true

    # 変数名プレフィックス
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "変数名プレフィックス："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $プレフィックステキスト = New-Object System.Windows.Forms.TextBox
    $プレフィックステキスト.Location = New-Object System.Drawing.Point(20, 175)
    $プレフィックステキスト.Size = New-Object System.Drawing.Size(150, 25)
    $プレフィックステキスト.Text = "ウインドウ"

    $説明ラベル = New-Object System.Windows.Forms.Label
    $説明ラベル.Text = "※ 例: プレフィックス「ウインドウ」→ `$ウインドウX, `$ウインドウY..."
    $説明ラベル.Location = New-Object System.Drawing.Point(20, 210)
    $説明ラベル.AutoSize = $true
    $説明ラベル.ForeColor = [System.Drawing.Color]::Gray

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(240, 245)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(340, 245)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $ウインドウコンボ, $ラベル2, $X座標チェック, $Y座標チェック, $幅チェック, $高さチェック, $ラベル3, $プレフィックステキスト, $説明ラベル, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $選択ウインドウ = $ウインドウコンボ.SelectedItem
    $プレフィックス = $プレフィックステキスト.Text

    if (-not $選択ウインドウ) { return "# キャンセルされました" }

    $コード = @()
    $コード += "# ウインドウ情報取得: $選択ウインドウ"
    $コード += "`$ウインドウハンドル = 文字列からウインドウハンドルを探す -検索文字列 `"$選択ウインドウ`""
    $コード += "`$ウインドウ矩形 = ウインドウ矩形取得 -ウインドウハンドル `$ウインドウハンドル"

    if ($X座標チェック.Checked) {
        $コード += "`$${プレフィックス}X = `$ウインドウ矩形.Left"
        $コード += "変数を追加する -変数 `$変数 -名前 `"${プレフィックス}X`" -型 `"単一値`" -値 `$${プレフィックス}X"
    }
    if ($Y座標チェック.Checked) {
        $コード += "`$${プレフィックス}Y = `$ウインドウ矩形.Top"
        $コード += "変数を追加する -変数 `$変数 -名前 `"${プレフィックス}Y`" -型 `"単一値`" -値 `$${プレフィックス}Y"
    }
    if ($幅チェック.Checked) {
        $コード += "`$${プレフィックス}幅 = `$ウインドウ矩形.Right - `$ウインドウ矩形.Left"
        $コード += "変数を追加する -変数 `$変数 -名前 `"${プレフィックス}幅`" -型 `"単一値`" -値 `$${プレフィックス}幅"
    }
    if ($高さチェック.Checked) {
        $コード += "`$${プレフィックス}高さ = `$ウインドウ矩形.Bottom - `$ウインドウ矩形.Top"
        $コード += "変数を追加する -変数 `$変数 -名前 `"${プレフィックス}高さ`" -型 `"単一値`" -値 `$${プレフィックス}高さ"
    }

    $コード += "Write-Host `"ウインドウ情報を取得しました`" -ForegroundColor Green"

    return ($コード -join "`n")
}
