function 1_4 {
    # ================================================================
    # コレクションループ (foreach)
    # ================================================================
    # 配列やコレクションの各要素を順に処理するループを生成する
    # ================================================================

    # スクリプトのルートパスを取得
    if ($script:RootDir) {
        $メインPath = $script:RootDir
    } else {
        $スクリプトPath = $PSScriptRoot
        $メインPath = Split-Path $スクリプトPath
    }

    # 共通ユーティリティを読み込み
    $utilityPath = Join-Path $メインPath "00_共通ユーティリティ_JSON操作.ps1"
    if (Test-Path $utilityPath) {
        . $utilityPath
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

    # 配列変数リスト取得
    $arrayVariablesList = @()
    if ($JSONPath -and (Test-Path $JSONPath)) {
        try {
            $importedVariables = Get-Content -Path $JSONPath -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($key in $importedVariables.PSObject.Properties.Name) {
                $value = $importedVariables.$key
                if ($value -is [System.Array]) {
                    $arrayVariablesList += ('$' + $key)
                }
            }
        } catch {}
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "コレクションループ (foreach)"
    $form.Size = New-Object System.Drawing.Size(500, 320)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.Topmost = $true

    # 要素変数名
    $lblElement = New-Object System.Windows.Forms.Label
    $lblElement.Text = "要素変数名："
    $lblElement.Location = New-Object System.Drawing.Point(20, 20)
    $lblElement.AutoSize = $true
    $form.Controls.Add($lblElement)

    $txtElement = New-Object System.Windows.Forms.TextBox
    $txtElement.Location = New-Object System.Drawing.Point(150, 18)
    $txtElement.Size = New-Object System.Drawing.Size(200, 25)
    $txtElement.Text = '$item'
    $form.Controls.Add($txtElement)

    # コレクション変数
    $lblCollection = New-Object System.Windows.Forms.Label
    $lblCollection.Text = "コレクション変数："
    $lblCollection.Location = New-Object System.Drawing.Point(20, 60)
    $lblCollection.AutoSize = $true
    $form.Controls.Add($lblCollection)

    $cmbCollection = New-Object System.Windows.Forms.ComboBox
    $cmbCollection.Location = New-Object System.Drawing.Point(150, 58)
    $cmbCollection.Size = New-Object System.Drawing.Size(200, 25)
    $cmbCollection.DropDownStyle = "DropDownList"
    if ($arrayVariablesList.Count -gt 0) {
        $cmbCollection.Items.AddRange($arrayVariablesList)
        $cmbCollection.SelectedIndex = 0
    }
    $form.Controls.Add($cmbCollection)

    # 手動入力オプション
    $chkManual = New-Object System.Windows.Forms.CheckBox
    $chkManual.Text = "手動入力"
    $chkManual.Location = New-Object System.Drawing.Point(360, 60)
    $chkManual.AutoSize = $true
    $form.Controls.Add($chkManual)

    $txtCollection = New-Object System.Windows.Forms.TextBox
    $txtCollection.Location = New-Object System.Drawing.Point(150, 58)
    $txtCollection.Size = New-Object System.Drawing.Size(200, 25)
    $txtCollection.Visible = $false
    $form.Controls.Add($txtCollection)

    # ヒント
    $lblHint = New-Object System.Windows.Forms.Label
    $lblHint.Text = "※ 配列変数が未登録の場合は、先に変数を登録してください"
    $lblHint.Location = New-Object System.Drawing.Point(20, 95)
    $lblHint.AutoSize = $true
    $lblHint.ForeColor = [System.Drawing.Color]::Gray
    $form.Controls.Add($lblHint)

    # プレビュー
    $lblPreview = New-Object System.Windows.Forms.Label
    $lblPreview.Text = "プレビュー："
    $lblPreview.Location = New-Object System.Drawing.Point(20, 130)
    $lblPreview.AutoSize = $true
    $form.Controls.Add($lblPreview)

    $txtPreview = New-Object System.Windows.Forms.TextBox
    $txtPreview.Location = New-Object System.Drawing.Point(20, 155)
    $txtPreview.Size = New-Object System.Drawing.Size(440, 70)
    $txtPreview.Multiline = $true
    $txtPreview.ReadOnly = $true
    $txtPreview.ScrollBars = "Vertical"
    $txtPreview.Font = New-Object System.Drawing.Font("Consolas", 9)
    $form.Controls.Add($txtPreview)

    # ボタン
    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "OK"
    $btnOK.Location = New-Object System.Drawing.Point(280, 240)
    $btnOK.Size = New-Object System.Drawing.Size(85, 30)
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($btnOK)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "キャンセル"
    $btnCancel.Location = New-Object System.Drawing.Point(375, 240)
    $btnCancel.Size = New-Object System.Drawing.Size(85, 30)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnCancel)

    $form.AcceptButton = $btnOK
    $form.CancelButton = $btnCancel

    # プレビュー更新関数
    $updatePreview = {
        $element = $txtElement.Text
        $collection = if ($chkManual.Checked) { $txtCollection.Text } else { $cmbCollection.SelectedItem }

        if (-not [string]::IsNullOrWhiteSpace($element) -and -not [string]::IsNullOrWhiteSpace($collection)) {
            $txtPreview.Text = "foreach ($element in $collection) {`r`n    # 処理内容`r`n}"
        } else {
            $txtPreview.Text = ""
        }
    }

    # イベントハンドラ
    $chkManual.Add_CheckedChanged({
        $cmbCollection.Visible = -not $chkManual.Checked
        $txtCollection.Visible = $chkManual.Checked
        & $updatePreview
    })

    $txtElement.Add_TextChanged($updatePreview)
    $cmbCollection.Add_SelectedIndexChanged($updatePreview)
    $txtCollection.Add_TextChanged($updatePreview)

    # 初期プレビュー
    & $updatePreview

    $メインメニューハンドル = メインメニューを最小化
    $result = $form.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    # コード生成
    $element = $txtElement.Text
    $collection = if ($chkManual.Checked) { $txtCollection.Text } else { $cmbCollection.SelectedItem }

    if ([string]::IsNullOrWhiteSpace($element) -or [string]::IsNullOrWhiteSpace($collection)) {
        return $null
    }

    $loopCode = @"
foreach ($element in $collection) {
---
}
"@

    return $loopCode
}
