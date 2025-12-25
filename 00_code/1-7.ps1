﻿function 1_7 {
    # ================================================================
    # ファイル存在確認（2分岐 If-Else）
    # ================================================================
    # ファイルまたはフォルダが存在するかで分岐する
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
    $form.Text = "ファイル存在確認（If-Else）"
    $form.Size = New-Object System.Drawing.Size(520, 380)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.Topmost = $true

    # パス入力
    $lblPath = New-Object System.Windows.Forms.Label
    $lblPath.Text = "チェックするパス："
    $lblPath.Location = New-Object System.Drawing.Point(20, 25)
    $lblPath.AutoSize = $true
    $form.Controls.Add($lblPath)

    $chkPathVar = New-Object System.Windows.Forms.CheckBox
    $chkPathVar.Text = "変数を使用"
    $chkPathVar.Location = New-Object System.Drawing.Point(140, 23)
    $chkPathVar.AutoSize = $true
    $form.Controls.Add($chkPathVar)

    $txtPath = New-Object System.Windows.Forms.TextBox
    $txtPath.Location = New-Object System.Drawing.Point(20, 50)
    $txtPath.Size = New-Object System.Drawing.Size(380, 25)
    $form.Controls.Add($txtPath)

    $cmbPathVar = New-Object System.Windows.Forms.ComboBox
    $cmbPathVar.Location = New-Object System.Drawing.Point(20, 50)
    $cmbPathVar.Size = New-Object System.Drawing.Size(380, 25)
    $cmbPathVar.Items.AddRange($variablesList)
    $cmbPathVar.Visible = $false
    $form.Controls.Add($cmbPathVar)

    $btnBrowse = New-Object System.Windows.Forms.Button
    $btnBrowse.Text = "参照..."
    $btnBrowse.Location = New-Object System.Drawing.Point(410, 48)
    $btnBrowse.Size = New-Object System.Drawing.Size(70, 28)
    $form.Controls.Add($btnBrowse)

    # チェックタイプ
    $lblType = New-Object System.Windows.Forms.Label
    $lblType.Text = "チェック方法："
    $lblType.Location = New-Object System.Drawing.Point(20, 95)
    $lblType.AutoSize = $true
    $form.Controls.Add($lblType)

    $cmbType = New-Object System.Windows.Forms.ComboBox
    $cmbType.Location = New-Object System.Drawing.Point(140, 93)
    $cmbType.Size = New-Object System.Drawing.Size(260, 25)
    $cmbType.DropDownStyle = "DropDownList"
    $cmbType.Items.AddRange(@(
        "存在する場合",
        "存在しない場合"
    ))
    $cmbType.SelectedIndex = 0
    $form.Controls.Add($cmbType)

    # プレビュー
    $lblPreview = New-Object System.Windows.Forms.Label
    $lblPreview.Text = "プレビュー："
    $lblPreview.Location = New-Object System.Drawing.Point(20, 140)
    $lblPreview.AutoSize = $true
    $form.Controls.Add($lblPreview)

    $txtPreview = New-Object System.Windows.Forms.TextBox
    $txtPreview.Location = New-Object System.Drawing.Point(20, 165)
    $txtPreview.Size = New-Object System.Drawing.Size(465, 110)
    $txtPreview.Multiline = $true
    $txtPreview.ReadOnly = $true
    $txtPreview.ScrollBars = "Vertical"
    $txtPreview.Font = New-Object System.Drawing.Font("Consolas", 9)
    $form.Controls.Add($txtPreview)

    # ボタン
    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "OK"
    $btnOK.Location = New-Object System.Drawing.Point(310, 295)
    $btnOK.Size = New-Object System.Drawing.Size(85, 30)
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($btnOK)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "キャンセル"
    $btnCancel.Location = New-Object System.Drawing.Point(405, 295)
    $btnCancel.Size = New-Object System.Drawing.Size(85, 30)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnCancel)

    $form.AcceptButton = $btnOK
    $form.CancelButton = $btnCancel

    # 参照ボタン
    $btnBrowse.Add_Click({
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
        $dialog.Title = "ファイルを選択"
        $dialog.Filter = "すべてのファイル (*.*)|*.*"
        $dialog.CheckFileExists = $false
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtPath.Text = $dialog.FileName
        }
    })

    # プレビュー更新
    $updatePreview = {
        $path = if ($chkPathVar.Checked) { $cmbPathVar.SelectedItem } else { "`"$($txtPath.Text)`"" }
        $type = $cmbType.SelectedIndex

        if (-not [string]::IsNullOrWhiteSpace($path)) {
            if ($type -eq 0) {
                $txtPreview.Text = "if (Test-Path $path) {`r`n    # 存在する場合の処理`r`n} else {`r`n    # 存在しない場合の処理`r`n}"
            } else {
                $txtPreview.Text = "if (-not (Test-Path $path)) {`r`n    # 存在しない場合の処理`r`n} else {`r`n    # 存在する場合の処理`r`n}"
            }
        }
    }

    # イベントハンドラ
    $chkPathVar.Add_CheckedChanged({
        $txtPath.Visible = -not $chkPathVar.Checked
        $cmbPathVar.Visible = $chkPathVar.Checked
        $btnBrowse.Enabled = -not $chkPathVar.Checked
        & $updatePreview
    })

    $txtPath.Add_TextChanged($updatePreview)
    $cmbPathVar.Add_SelectedIndexChanged($updatePreview)
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
    $path = if ($chkPathVar.Checked) { $cmbPathVar.SelectedItem } else { "`"$($txtPath.Text)`"" }
    $type = $cmbType.SelectedIndex

    if ($type -eq 0) {
        $code = @"
if (Test-Path $path) {
---
} else {
---
}
"@
    } else {
        $code = @"
if (-not (Test-Path $path)) {
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
