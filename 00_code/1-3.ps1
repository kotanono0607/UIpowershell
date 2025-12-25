function 1_3 {
    # ================================================================
    # 固定回数ループ (for)
    # ================================================================
    # 指定した回数だけ繰り返すループを生成する
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

    # 変数リスト取得
    $variablesList = @()
    if ($JSONPath -and (Test-Path $JSONPath)) {
        try {
            $importedVariables = Get-Content -Path $JSONPath -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($key in $importedVariables.PSObject.Properties.Name) {
                $value = $importedVariables.$key
                if (-not ($value -is [System.Array])) {
                    $variablesList += ('$' + $key)
                }
            }
        } catch {}
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "固定回数ループ (for)"
    $form.Size = New-Object System.Drawing.Size(500, 380)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.Topmost = $true
    $form.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # カウンタ変数名
    $lblCounter = New-Object System.Windows.Forms.Label
    $lblCounter.Text = "カウンタ変数名："
    $lblCounter.Location = New-Object System.Drawing.Point(20, 20)
    $lblCounter.AutoSize = $true
    $form.Controls.Add($lblCounter)

    $txtCounter = New-Object System.Windows.Forms.TextBox
    $txtCounter.Location = New-Object System.Drawing.Point(150, 18)
    $txtCounter.Size = New-Object System.Drawing.Size(150, 25)
    $txtCounter.Text = '$i'
    $form.Controls.Add($txtCounter)

    # 開始値
    $lblStart = New-Object System.Windows.Forms.Label
    $lblStart.Text = "開始値："
    $lblStart.Location = New-Object System.Drawing.Point(20, 60)
    $lblStart.AutoSize = $true
    $form.Controls.Add($lblStart)

    $txtStart = New-Object System.Windows.Forms.TextBox
    $txtStart.Location = New-Object System.Drawing.Point(150, 58)
    $txtStart.Size = New-Object System.Drawing.Size(150, 25)
    $txtStart.Text = "1"
    $form.Controls.Add($txtStart)

    $chkStartVar = New-Object System.Windows.Forms.CheckBox
    $chkStartVar.Text = "変数を使用"
    $chkStartVar.Location = New-Object System.Drawing.Point(310, 60)
    $chkStartVar.AutoSize = $true
    $form.Controls.Add($chkStartVar)

    $cmbStartVar = New-Object System.Windows.Forms.ComboBox
    $cmbStartVar.Location = New-Object System.Drawing.Point(150, 58)
    $cmbStartVar.Size = New-Object System.Drawing.Size(150, 25)
    $cmbStartVar.Items.AddRange($variablesList)
    $cmbStartVar.Visible = $false
    $form.Controls.Add($cmbStartVar)

    # 終了値
    $lblEnd = New-Object System.Windows.Forms.Label
    $lblEnd.Text = "終了値："
    $lblEnd.Location = New-Object System.Drawing.Point(20, 100)
    $lblEnd.AutoSize = $true
    $form.Controls.Add($lblEnd)

    $txtEnd = New-Object System.Windows.Forms.TextBox
    $txtEnd.Location = New-Object System.Drawing.Point(150, 98)
    $txtEnd.Size = New-Object System.Drawing.Size(150, 25)
    $txtEnd.Text = "10"
    $form.Controls.Add($txtEnd)

    $chkEndVar = New-Object System.Windows.Forms.CheckBox
    $chkEndVar.Text = "変数を使用"
    $chkEndVar.Location = New-Object System.Drawing.Point(310, 100)
    $chkEndVar.AutoSize = $true
    $form.Controls.Add($chkEndVar)

    $cmbEndVar = New-Object System.Windows.Forms.ComboBox
    $cmbEndVar.Location = New-Object System.Drawing.Point(150, 98)
    $cmbEndVar.Size = New-Object System.Drawing.Size(150, 25)
    $cmbEndVar.Items.AddRange($variablesList)
    $cmbEndVar.Visible = $false
    $form.Controls.Add($cmbEndVar)

    # 増分値
    $lblIncrement = New-Object System.Windows.Forms.Label
    $lblIncrement.Text = "増分値："
    $lblIncrement.Location = New-Object System.Drawing.Point(20, 140)
    $lblIncrement.AutoSize = $true
    $form.Controls.Add($lblIncrement)

    $txtIncrement = New-Object System.Windows.Forms.TextBox
    $txtIncrement.Location = New-Object System.Drawing.Point(150, 138)
    $txtIncrement.Size = New-Object System.Drawing.Size(150, 25)
    $txtIncrement.Text = "1"
    $form.Controls.Add($txtIncrement)

    # プレビュー
    $lblPreview = New-Object System.Windows.Forms.Label
    $lblPreview.Text = "プレビュー："
    $lblPreview.Location = New-Object System.Drawing.Point(20, 190)
    $lblPreview.AutoSize = $true
    $form.Controls.Add($lblPreview)

    $txtPreview = New-Object System.Windows.Forms.TextBox
    $txtPreview.Location = New-Object System.Drawing.Point(20, 215)
    $txtPreview.Size = New-Object System.Drawing.Size(440, 70)
    $txtPreview.Multiline = $true
    $txtPreview.ReadOnly = $true
    $txtPreview.ScrollBars = "Vertical"
    $txtPreview.Font = New-Object System.Drawing.Font("Consolas", 9)
    $form.Controls.Add($txtPreview)

    # ボタン
    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "OK"
    $btnOK.Location = New-Object System.Drawing.Point(280, 300)
    $btnOK.Size = New-Object System.Drawing.Size(85, 30)
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($btnOK)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "キャンセル"
    $btnCancel.Location = New-Object System.Drawing.Point(375, 300)
    $btnCancel.Size = New-Object System.Drawing.Size(85, 30)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnCancel)

    $form.AcceptButton = $btnOK
    $form.CancelButton = $btnCancel

    # プレビュー更新関数
    $updatePreview = {
        $counter = $txtCounter.Text
        $start = if ($chkStartVar.Checked) { $cmbStartVar.SelectedItem } else { $txtStart.Text }
        $end = if ($chkEndVar.Checked) { $cmbEndVar.SelectedItem } else { $txtEnd.Text }
        $increment = $txtIncrement.Text

        if (-not [string]::IsNullOrWhiteSpace($counter) -and -not [string]::IsNullOrWhiteSpace($start) -and -not [string]::IsNullOrWhiteSpace($end)) {
            $txtPreview.Text = "for ($counter = $start; $counter -le $end; $counter += $increment) {`r`n    # 処理内容`r`n}"
        }
    }

    # イベントハンドラ
    $chkStartVar.Add_CheckedChanged({
        $txtStart.Visible = -not $chkStartVar.Checked
        $cmbStartVar.Visible = $chkStartVar.Checked
        & $updatePreview
    })

    $chkEndVar.Add_CheckedChanged({
        $txtEnd.Visible = -not $chkEndVar.Checked
        $cmbEndVar.Visible = $chkEndVar.Checked
        & $updatePreview
    })

    $txtCounter.Add_TextChanged($updatePreview)
    $txtStart.Add_TextChanged($updatePreview)
    $txtEnd.Add_TextChanged($updatePreview)
    $txtIncrement.Add_TextChanged($updatePreview)
    $cmbStartVar.Add_SelectedIndexChanged($updatePreview)
    $cmbEndVar.Add_SelectedIndexChanged($updatePreview)

    # 初期プレビュー
    & $updatePreview

    $メインメニューハンドル = メインメニューを最小化
    $result = $form.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    # コード生成
    $counter = $txtCounter.Text
    $start = if ($chkStartVar.Checked) { $cmbStartVar.SelectedItem } else { $txtStart.Text }
    $end = if ($chkEndVar.Checked) { $cmbEndVar.SelectedItem } else { $txtEnd.Text }
    $increment = $txtIncrement.Text

    $loopCode = @"
for ($counter = $start; $counter -le $end; $counter += $increment) {
---
}
"@

    return $loopCode
}
