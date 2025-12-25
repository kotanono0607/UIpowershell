﻿function 1_2 {
    # ================================================================
    # 変数比較（2分岐 If-Else）
    # ================================================================
    # 変数の値を比較して分岐する
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
    $form.Text = "変数比較（If-Else）"
    $form.Size = New-Object System.Drawing.Size(520, 400)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.Topmost = $true
    $form.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # 条件セクション
    $grpCondition = New-Object System.Windows.Forms.GroupBox
    $grpCondition.Text = "条件式"
    $grpCondition.Location = New-Object System.Drawing.Point(20, 20)
    $grpCondition.Size = New-Object System.Drawing.Size(465, 160)
    $form.Controls.Add($grpCondition)

    # 左辺（比較元）
    $lblLeft = New-Object System.Windows.Forms.Label
    $lblLeft.Text = "比較元："
    $lblLeft.Location = New-Object System.Drawing.Point(15, 30)
    $lblLeft.AutoSize = $true
    $grpCondition.Controls.Add($lblLeft)

    $chkLeftVar = New-Object System.Windows.Forms.CheckBox
    $chkLeftVar.Text = "変数を使用"
    $chkLeftVar.Location = New-Object System.Drawing.Point(100, 28)
    $chkLeftVar.AutoSize = $true
    $chkLeftVar.Checked = $true
    $grpCondition.Controls.Add($chkLeftVar)

    $cmbLeftVar = New-Object System.Windows.Forms.ComboBox
    $cmbLeftVar.Location = New-Object System.Drawing.Point(220, 26)
    $cmbLeftVar.Size = New-Object System.Drawing.Size(220, 25)
    $cmbLeftVar.Items.AddRange($variablesList)
    if ($variablesList.Count -gt 0) { $cmbLeftVar.SelectedIndex = 0 }
    $grpCondition.Controls.Add($cmbLeftVar)

    $txtLeft = New-Object System.Windows.Forms.TextBox
    $txtLeft.Location = New-Object System.Drawing.Point(220, 26)
    $txtLeft.Size = New-Object System.Drawing.Size(220, 25)
    $txtLeft.Visible = $false
    $grpCondition.Controls.Add($txtLeft)

    # 演算子
    $lblOperator = New-Object System.Windows.Forms.Label
    $lblOperator.Text = "比較方法："
    $lblOperator.Location = New-Object System.Drawing.Point(15, 70)
    $lblOperator.AutoSize = $true
    $grpCondition.Controls.Add($lblOperator)

    $cmbOperator = New-Object System.Windows.Forms.ComboBox
    $cmbOperator.Location = New-Object System.Drawing.Point(100, 68)
    $cmbOperator.Size = New-Object System.Drawing.Size(340, 25)
    $cmbOperator.DropDownStyle = "DropDownList"
    $cmbOperator.Items.AddRange(@(
        "-eq （等しい）",
        "-ne （等しくない）",
        "-lt （より小さい）",
        "-gt （より大きい）",
        "-le （以下）",
        "-ge （以上）"
    ))
    $cmbOperator.SelectedIndex = 0
    $grpCondition.Controls.Add($cmbOperator)

    # 右辺（比較先）
    $lblRight = New-Object System.Windows.Forms.Label
    $lblRight.Text = "比較先："
    $lblRight.Location = New-Object System.Drawing.Point(15, 110)
    $lblRight.AutoSize = $true
    $grpCondition.Controls.Add($lblRight)

    $chkRightVar = New-Object System.Windows.Forms.CheckBox
    $chkRightVar.Text = "変数を使用"
    $chkRightVar.Location = New-Object System.Drawing.Point(100, 108)
    $chkRightVar.AutoSize = $true
    $grpCondition.Controls.Add($chkRightVar)

    $txtRight = New-Object System.Windows.Forms.TextBox
    $txtRight.Location = New-Object System.Drawing.Point(220, 106)
    $txtRight.Size = New-Object System.Drawing.Size(220, 25)
    $grpCondition.Controls.Add($txtRight)

    $cmbRightVar = New-Object System.Windows.Forms.ComboBox
    $cmbRightVar.Location = New-Object System.Drawing.Point(220, 106)
    $cmbRightVar.Size = New-Object System.Drawing.Size(220, 25)
    $cmbRightVar.Items.AddRange($variablesList)
    $cmbRightVar.Visible = $false
    $grpCondition.Controls.Add($cmbRightVar)

    # プレビュー
    $lblPreview = New-Object System.Windows.Forms.Label
    $lblPreview.Text = "プレビュー："
    $lblPreview.Location = New-Object System.Drawing.Point(20, 195)
    $lblPreview.AutoSize = $true
    $form.Controls.Add($lblPreview)

    $txtPreview = New-Object System.Windows.Forms.TextBox
    $txtPreview.Location = New-Object System.Drawing.Point(20, 220)
    $txtPreview.Size = New-Object System.Drawing.Size(465, 80)
    $txtPreview.Multiline = $true
    $txtPreview.ReadOnly = $true
    $txtPreview.ScrollBars = "Vertical"
    $txtPreview.Font = New-Object System.Drawing.Font("Consolas", 9)
    $form.Controls.Add($txtPreview)

    # ボタン
    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "OK"
    $btnOK.Location = New-Object System.Drawing.Point(300, 315)
    $btnOK.Size = New-Object System.Drawing.Size(85, 30)
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($btnOK)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "キャンセル"
    $btnCancel.Location = New-Object System.Drawing.Point(395, 315)
    $btnCancel.Size = New-Object System.Drawing.Size(85, 30)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnCancel)

    $form.AcceptButton = $btnOK
    $form.CancelButton = $btnCancel

    # 演算子抽出
    $getOperator = {
        $selected = $cmbOperator.SelectedItem
        if ($selected -match "^(-\w+)") { return $matches[1] }
        return "-eq"
    }

    # プレビュー更新
    $updatePreview = {
        $left = if ($chkLeftVar.Checked) { $cmbLeftVar.SelectedItem } else { "`"$($txtLeft.Text)`"" }
        $right = if ($chkRightVar.Checked) { $cmbRightVar.SelectedItem } else { "`"$($txtRight.Text)`"" }
        $op = & $getOperator

        if (-not [string]::IsNullOrWhiteSpace($left) -and -not [string]::IsNullOrWhiteSpace($right)) {
            $txtPreview.Text = "if ($left $op $right) {`r`n    # True の処理`r`n} else {`r`n    # False の処理`r`n}"
        }
    }

    # イベントハンドラ
    $chkLeftVar.Add_CheckedChanged({
        $cmbLeftVar.Visible = $chkLeftVar.Checked
        $txtLeft.Visible = -not $chkLeftVar.Checked
        & $updatePreview
    })

    $chkRightVar.Add_CheckedChanged({
        $cmbRightVar.Visible = $chkRightVar.Checked
        $txtRight.Visible = -not $chkRightVar.Checked
        & $updatePreview
    })

    $cmbLeftVar.Add_SelectedIndexChanged($updatePreview)
    $cmbRightVar.Add_SelectedIndexChanged($updatePreview)
    $txtLeft.Add_TextChanged($updatePreview)
    $txtRight.Add_TextChanged($updatePreview)
    $cmbOperator.Add_SelectedIndexChanged($updatePreview)

    # 初期プレビュー
    & $updatePreview

    $メインメニューハンドル = メインメニューを最小化
    $result = $form.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    # コード生成
    $left = if ($chkLeftVar.Checked) { $cmbLeftVar.SelectedItem } else { "`"$($txtLeft.Text)`"" }
    $right = if ($chkRightVar.Checked) { $cmbRightVar.SelectedItem } else { "`"$($txtRight.Text)`"" }
    $op = & $getOperator

    $code = @"
if ($left $op $right) {
---
} else {
---
}
"@

    # JSON形式で返す（branchCount = 2）
    $resultJson = @{
        branchCount = 2
        code = $code
    } | ConvertTo-Json -Compress

    return $resultJson
}
