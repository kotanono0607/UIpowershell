﻿function 13_2 {
    # Excel(操作) - セル値設定
    # Excelファイルの指定セルに値を設定（列・行分離指定、変数対応）

    # スクリプトのルートパスを取得
    if ($script:RootDir) {
        $メインPath = $script:RootDir
    } else {
        $スクリプトPath = $PSScriptRoot
        $メインPath = Split-Path $スクリプトPath
    }

    # 変数リスト取得用
    $JSONPath = $null
    try {
        $メインJsonPath = Join-Path $メインPath "03_history\メイン.json"
        if (Test-Path $メインJsonPath) {
            $jsonContent = Get-Content -Path $メインJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $folderPath = $jsonContent."フォルダパス"
            $JSONPath = Join-Path $folderPath "variables.json"
        }
    } catch {}

    # 変数リスト取得
    $variablesList = @()
    if ($JSONPath -and (Test-Path $JSONPath)) {
        try {
            $importedVariables = Get-Content -Path $JSONPath -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($key in $importedVariables.PSObject.Properties.Name) {
                $variablesList += ('$' + $key)
            }
        } catch {}
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # 設定ダイアログ
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "セル値設定"
    $フォーム.Size = New-Object System.Drawing.Size(520, 420)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.MinimizeBox = $false
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # ファイルパス
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "Excelファイルパス："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $chkPathVar = New-Object System.Windows.Forms.CheckBox
    $chkPathVar.Text = "変数を使用"
    $chkPathVar.Location = New-Object System.Drawing.Point(150, 18)
    $chkPathVar.AutoSize = $true

    $パステキスト = New-Object System.Windows.Forms.TextBox
    $パステキスト.Location = New-Object System.Drawing.Point(20, 45)
    $パステキスト.Size = New-Object System.Drawing.Size(350, 25)

    $cmbPathVar = New-Object System.Windows.Forms.ComboBox
    $cmbPathVar.Location = New-Object System.Drawing.Point(20, 45)
    $cmbPathVar.Size = New-Object System.Drawing.Size(350, 25)
    $cmbPathVar.DropDownStyle = "DropDownList"
    $cmbPathVar.Items.AddRange($variablesList)
    $cmbPathVar.Visible = $false

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

    $chkPathVar.Add_CheckedChanged({
        $パステキスト.Visible = -not $chkPathVar.Checked
        $cmbPathVar.Visible = $chkPathVar.Checked
        $参照ボタン.Enabled = -not $chkPathVar.Checked
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
    $ラベル3.Text = "列番号："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $chkColVar = New-Object System.Windows.Forms.CheckBox
    $chkColVar.Text = "変数を使用"
    $chkColVar.Location = New-Object System.Drawing.Point(80, 148)
    $chkColVar.AutoSize = $true

    $列テキスト = New-Object System.Windows.Forms.TextBox
    $列テキスト.Location = New-Object System.Drawing.Point(20, 175)
    $列テキスト.Size = New-Object System.Drawing.Size(150, 25)
    $列テキスト.Text = "1"

    $cmbColVar = New-Object System.Windows.Forms.ComboBox
    $cmbColVar.Location = New-Object System.Drawing.Point(20, 175)
    $cmbColVar.Size = New-Object System.Drawing.Size(150, 25)
    $cmbColVar.DropDownStyle = "DropDownList"
    $cmbColVar.Items.AddRange($variablesList)
    $cmbColVar.Visible = $false

    $chkColVar.Add_CheckedChanged({
        $列テキスト.Visible = -not $chkColVar.Checked
        $cmbColVar.Visible = $chkColVar.Checked
    })

    # 行番号
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "行番号："
    $ラベル4.Location = New-Object System.Drawing.Point(230, 150)
    $ラベル4.AutoSize = $true

    $chkRowVar = New-Object System.Windows.Forms.CheckBox
    $chkRowVar.Text = "変数を使用"
    $chkRowVar.Location = New-Object System.Drawing.Point(290, 148)
    $chkRowVar.AutoSize = $true

    $行テキスト = New-Object System.Windows.Forms.TextBox
    $行テキスト.Location = New-Object System.Drawing.Point(230, 175)
    $行テキスト.Size = New-Object System.Drawing.Size(150, 25)
    $行テキスト.Text = "1"

    $cmbRowVar = New-Object System.Windows.Forms.ComboBox
    $cmbRowVar.Location = New-Object System.Drawing.Point(230, 175)
    $cmbRowVar.Size = New-Object System.Drawing.Size(150, 25)
    $cmbRowVar.DropDownStyle = "DropDownList"
    $cmbRowVar.Items.AddRange($variablesList)
    $cmbRowVar.Visible = $false

    $chkRowVar.Add_CheckedChanged({
        $行テキスト.Visible = -not $chkRowVar.Checked
        $cmbRowVar.Visible = $chkRowVar.Checked
    })

    # 設定値
    $ラベル5 = New-Object System.Windows.Forms.Label
    $ラベル5.Text = "設定する値："
    $ラベル5.Location = New-Object System.Drawing.Point(20, 215)
    $ラベル5.AutoSize = $true

    $chkValueVar = New-Object System.Windows.Forms.CheckBox
    $chkValueVar.Text = "変数を使用"
    $chkValueVar.Location = New-Object System.Drawing.Point(110, 213)
    $chkValueVar.AutoSize = $true

    $値テキスト = New-Object System.Windows.Forms.TextBox
    $値テキスト.Location = New-Object System.Drawing.Point(20, 240)
    $値テキスト.Size = New-Object System.Drawing.Size(250, 25)

    $cmbValueVar = New-Object System.Windows.Forms.ComboBox
    $cmbValueVar.Location = New-Object System.Drawing.Point(20, 240)
    $cmbValueVar.Size = New-Object System.Drawing.Size(250, 25)
    $cmbValueVar.DropDownStyle = "DropDownList"
    $cmbValueVar.Items.AddRange($variablesList)
    $cmbValueVar.Visible = $false

    $chkValueVar.Add_CheckedChanged({
        $値テキスト.Visible = -not $chkValueVar.Checked
        $cmbValueVar.Visible = $chkValueVar.Checked
    })

    # ヒント
    $ヒントラベル = New-Object System.Windows.Forms.Label
    $ヒントラベル.Text = "※ 変数を使用すると、事前に設定した変数から値を取得できます"
    $ヒントラベル.Location = New-Object System.Drawing.Point(20, 280)
    $ヒントラベル.AutoSize = $true
    $ヒントラベル.ForeColor = [System.Drawing.Color]::Gray

    # ボタン
    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(300, 330)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(400, 330)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $chkPathVar, $パステキスト, $cmbPathVar, $参照ボタン, $ラベル2, $シートテキスト, $ラベル3, $chkColVar, $列テキスト, $cmbColVar, $ラベル4, $chkRowVar, $行テキスト, $cmbRowVar, $ラベル5, $chkValueVar, $値テキスト, $cmbValueVar, $ヒントラベル, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    # 値を取得
    $ファイルパス = if ($chkPathVar.Checked) { $cmbPathVar.SelectedItem } else { $パステキスト.Text }
    $シート名 = $シートテキスト.Text
    $列入力 = if ($chkColVar.Checked) { $cmbColVar.SelectedItem } else { $列テキスト.Text }
    $行入力 = if ($chkRowVar.Checked) { $cmbRowVar.SelectedItem } else { $行テキスト.Text }
    $設定値 = if ($chkValueVar.Checked) { $cmbValueVar.SelectedItem } else { $値テキスト.Text }

    if ([string]::IsNullOrWhiteSpace($ファイルパス) -or [string]::IsNullOrWhiteSpace($列入力) -or [string]::IsNullOrWhiteSpace($行入力)) {
        [System.Windows.Forms.MessageBox]::Show("ファイルパス、列番号、行番号は必須です。", "エラー")
        return $null
    }

    # 変数かどうかを判定
    $パスは変数 = $chkPathVar.Checked
    $列は変数 = $chkColVar.Checked
    $行は変数 = $chkRowVar.Checked
    $値は変数 = $chkValueVar.Checked

    # パラメータ生成
    $パスパラメータ = if ($パスは変数) { $ファイルパス } else { "`"$ファイルパス`"" }
    $列パラメータ = if ($列は変数) { $列入力 } else { $列入力 }
    $行パラメータ = if ($行は変数) { $行入力 } else { $行入力 }
    $値パラメータ = if ($値は変数) { $設定値 } else { "`"$設定値`"" }
    $シートパラメータ = if ([string]::IsNullOrEmpty($シート名)) { "" } else { " -シート名 `"$シート名`"" }

    # コメント用の表示
    $列表示 = if ($列は変数) { "列=$列入力" } else { "列$列入力" }
    $行表示 = if ($行は変数) { "行=$行入力" } else { "行$行入力" }

    $entryString = @"
# セル値設定: $列表示, $行表示 = $設定値
Excel操作_セル値設定_行列 -ファイルパス $パスパラメータ -列番号 $列パラメータ -行番号 $行パラメータ -値 $値パラメータ$シートパラメータ
"@

    return $entryString
}
