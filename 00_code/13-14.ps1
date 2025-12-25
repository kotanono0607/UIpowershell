﻿function 13_14 {
    # Excel(操作) - 行削除
    # 指定行を削除

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
    $フォーム.Text = "行削除"
    $フォーム.Size = New-Object System.Drawing.Size(520, 320)
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
        $openDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openDialog.Filter = "Excelファイル (*.xlsx;*.xls)|*.xlsx;*.xls"
        if ($openDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $パステキスト.Text = $openDialog.FileName
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

    # 行番号
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "削除開始行番号："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $行番号テキスト = New-Object System.Windows.Forms.NumericUpDown
    $行番号テキスト.Location = New-Object System.Drawing.Point(20, 175)
    $行番号テキスト.Size = New-Object System.Drawing.Size(100, 25)
    $行番号テキスト.Minimum = 1
    $行番号テキスト.Maximum = 1000000
    $行番号テキスト.Value = 1

    # 削除行数
    $ラベル4 = New-Object System.Windows.Forms.Label
    $ラベル4.Text = "削除行数："
    $ラベル4.Location = New-Object System.Drawing.Point(150, 150)
    $ラベル4.AutoSize = $true

    $行数テキスト = New-Object System.Windows.Forms.NumericUpDown
    $行数テキスト.Location = New-Object System.Drawing.Point(150, 175)
    $行数テキスト.Size = New-Object System.Drawing.Size(80, 25)
    $行数テキスト.Minimum = 1
    $行数テキスト.Maximum = 1000
    $行数テキスト.Value = 1

    # ボタン
    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(300, 240)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(400, 240)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $chkPathVar, $パステキスト, $cmbPathVar, $参照ボタン, $ラベル2, $シートテキスト, $ラベル3, $行番号テキスト, $ラベル4, $行数テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    $ファイルパス = if ($chkPathVar.Checked) { $cmbPathVar.SelectedItem } else { $パステキスト.Text }
    $シート名 = $シートテキスト.Text
    $行番号 = [int]$行番号テキスト.Value
    $削除行数 = [int]$行数テキスト.Value

    if ([string]::IsNullOrWhiteSpace($ファイルパス)) {
        [System.Windows.Forms.MessageBox]::Show("ファイルパスは必須です。", "エラー")
        return $null
    }

    # パラメータ生成
    $パスは変数 = $chkPathVar.Checked
    $パスパラメータ = if ($パスは変数) { $ファイルパス } else { "`"$ファイルパス`"" }
    $シートパラメータ = if ([string]::IsNullOrEmpty($シート名)) { "" } else { " -シート名 `"$シート名`"" }

    $entryString = @"
# 行削除: 行$行番号 から $削除行数 行
Excel操作_行削除 -ファイルパス $パスパラメータ -行番号 $行番号 -削除行数 $削除行数$シートパラメータ
"@

    return $entryString
}
