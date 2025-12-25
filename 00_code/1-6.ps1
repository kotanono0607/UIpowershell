﻿function 1_6 {
    # ================================================================
    # 空チェック（2分岐 If-Else）
    # ================================================================
    # 変数が空か空でないかで分岐する
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
                $variablesList += ('$' + $key)
            }
        } catch {}
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "空チェック（If-Else）"
    $form.Size = New-Object System.Drawing.Size(450, 340)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.Topmost = $true
    $form.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # 変数選択
    $lblVar = New-Object System.Windows.Forms.Label
    $lblVar.Text = "チェックする変数："
    $lblVar.Location = New-Object System.Drawing.Point(20, 25)
    $lblVar.AutoSize = $true
    $form.Controls.Add($lblVar)

    $cmbVar = New-Object System.Windows.Forms.ComboBox
    $cmbVar.Location = New-Object System.Drawing.Point(150, 23)
    $cmbVar.Size = New-Object System.Drawing.Size(250, 25)
    $cmbVar.Items.AddRange($variablesList)
    if ($variablesList.Count -gt 0) { $cmbVar.SelectedIndex = 0 }
    $form.Controls.Add($cmbVar)

    # チェックタイプ
    $lblType = New-Object System.Windows.Forms.Label
    $lblType.Text = "チェック方法："
    $lblType.Location = New-Object System.Drawing.Point(20, 70)
    $lblType.AutoSize = $true
    $form.Controls.Add($lblType)

    $cmbType = New-Object System.Windows.Forms.ComboBox
    $cmbType.Location = New-Object System.Drawing.Point(150, 68)
    $cmbType.Size = New-Object System.Drawing.Size(250, 25)
    $cmbType.DropDownStyle = "DropDownList"
    $cmbType.Items.AddRange(@(
        "空の場合（null/空文字/空白のみ）",
        "空でない場合"
    ))
    $cmbType.SelectedIndex = 0
    $form.Controls.Add($cmbType)

    # プレビュー
    $lblPreview = New-Object System.Windows.Forms.Label
    $lblPreview.Text = "プレビュー："
    $lblPreview.Location = New-Object System.Drawing.Point(20, 120)
    $lblPreview.AutoSize = $true
    $form.Controls.Add($lblPreview)

    $txtPreview = New-Object System.Windows.Forms.TextBox
    $txtPreview.Location = New-Object System.Drawing.Point(20, 145)
    $txtPreview.Size = New-Object System.Drawing.Size(395, 100)
    $txtPreview.Multiline = $true
    $txtPreview.ReadOnly = $true
    $txtPreview.ScrollBars = "Vertical"
    $txtPreview.Font = New-Object System.Drawing.Font("Consolas", 9)
    $form.Controls.Add($txtPreview)

    # ボタン
    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "OK"
    $btnOK.Location = New-Object System.Drawing.Point(230, 260)
    $btnOK.Size = New-Object System.Drawing.Size(85, 30)
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($btnOK)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "キャンセル"
    $btnCancel.Location = New-Object System.Drawing.Point(325, 260)
    $btnCancel.Size = New-Object System.Drawing.Size(85, 30)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnCancel)

    $form.AcceptButton = $btnOK
    $form.CancelButton = $btnCancel

    # プレビュー更新
    $updatePreview = {
        $var = $cmbVar.SelectedItem
        $type = $cmbType.SelectedIndex

        if (-not [string]::IsNullOrWhiteSpace($var)) {
            if ($type -eq 0) {
                # 空の場合
                $txtPreview.Text = "if ([string]::IsNullOrWhiteSpace($var)) {`r`n    # 空の場合の処理`r`n} else {`r`n    # 空でない場合の処理`r`n}"
            } else {
                # 空でない場合
                $txtPreview.Text = "if (-not [string]::IsNullOrWhiteSpace($var)) {`r`n    # 空でない場合の処理`r`n} else {`r`n    # 空の場合の処理`r`n}"
            }
        }
    }

    # イベントハンドラ
    $cmbVar.Add_SelectedIndexChanged($updatePreview)
    $cmbType.Add_SelectedIndexChanged($updatePreview)

    # 初期プレビュー
    & $updatePreview

    $メインメニューハンドル = メインメニューを最小化
    $result = $form.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    # コード生成
    $var = $cmbVar.SelectedItem
    $type = $cmbType.SelectedIndex

    if ($type -eq 0) {
        $code = @"
if ([string]::IsNullOrWhiteSpace($var)) {
---
} else {
---
}
"@
    } else {
        $code = @"
if (-not [string]::IsNullOrWhiteSpace($var)) {
---
} else {
---
}
"@
    }

    # JSON形式で返す
    $resultJson = @{
        branchCount = 2
        code = $code
    } | ConvertTo-Json -Compress

    return $resultJson
}
