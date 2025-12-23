function 13_8 {
    # Excel(操作) - シート名変更
    # Excelファイルのシート名を変更

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
    $フォーム.Text = "シート名変更"
    $フォーム.Size = New-Object System.Drawing.Size(520, 300)
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

    # 現シート名
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "現在のシート名："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $現シートテキスト = New-Object System.Windows.Forms.TextBox
    $現シートテキスト.Location = New-Object System.Drawing.Point(20, 110)
    $現シートテキスト.Size = New-Object System.Drawing.Size(200, 25)
    $現シートテキスト.Text = "Sheet1"

    # 新シート名
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "新しいシート名："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 150)
    $ラベル3.AutoSize = $true

    $新シートテキスト = New-Object System.Windows.Forms.TextBox
    $新シートテキスト.Location = New-Object System.Drawing.Point(20, 175)
    $新シートテキスト.Size = New-Object System.Drawing.Size(200, 25)

    # ボタン
    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(300, 215)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(400, 215)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $chkPathVar, $パステキスト, $cmbPathVar, $参照ボタン, $ラベル2, $現シートテキスト, $ラベル3, $新シートテキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    $ファイルパス = if ($chkPathVar.Checked) { $cmbPathVar.SelectedItem } else { $パステキスト.Text }
    $現シート名 = $現シートテキスト.Text
    $新シート名 = $新シートテキスト.Text

    if ([string]::IsNullOrWhiteSpace($ファイルパス) -or [string]::IsNullOrWhiteSpace($現シート名) -or [string]::IsNullOrWhiteSpace($新シート名)) {
        [System.Windows.Forms.MessageBox]::Show("すべての項目を入力してください。", "エラー")
        return $null
    }

    # パラメータ生成
    $パスは変数 = $chkPathVar.Checked
    $パスパラメータ = if ($パスは変数) { $ファイルパス } else { "`"$ファイルパス`"" }

    $entryString = @"
# シート名変更: $現シート名 → $新シート名
Excel操作_シート名変更 -ファイルパス $パスパラメータ -現シート名 "$現シート名" -新シート名 "$新シート名"
"@

    return $entryString
}
