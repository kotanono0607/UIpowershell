function 1_8 {
    # ================================================================
    # 文字列含む（2分岐 If-Else）
    # ================================================================
    # 文字列に特定のパターンが含まれるかで分岐する
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
    $form.Text = "文字列パターン（If-Else）"
    $form.Size = New-Object System.Drawing.Size(520, 420)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.Topmost = $true

    # 対象文字列
    $lblTarget = New-Object System.Windows.Forms.Label
    $lblTarget.Text = "対象文字列："
    $lblTarget.Location = New-Object System.Drawing.Point(20, 25)
    $lblTarget.AutoSize = $true
    $form.Controls.Add($lblTarget)

    $chkTargetVar = New-Object System.Windows.Forms.CheckBox
    $chkTargetVar.Text = "変数を使用"
    $chkTargetVar.Location = New-Object System.Drawing.Point(120, 23)
    $chkTargetVar.AutoSize = $true
    $chkTargetVar.Checked = $true
    $form.Controls.Add($chkTargetVar)

    $cmbTargetVar = New-Object System.Windows.Forms.ComboBox
    $cmbTargetVar.Location = New-Object System.Drawing.Point(240, 21)
    $cmbTargetVar.Size = New-Object System.Drawing.Size(240, 25)
    $cmbTargetVar.Items.AddRange($variablesList)
    if ($variablesList.Count -gt 0) { $cmbTargetVar.SelectedIndex = 0 }
    $form.Controls.Add($cmbTargetVar)

    $txtTarget = New-Object System.Windows.Forms.TextBox
    $txtTarget.Location = New-Object System.Drawing.Point(240, 21)
    $txtTarget.Size = New-Object System.Drawing.Size(240, 25)
    $txtTarget.Visible = $false
    $form.Controls.Add($txtTarget)

    # マッチ方法
    $lblMethod = New-Object System.Windows.Forms.Label
    $lblMethod.Text = "マッチ方法："
    $lblMethod.Location = New-Object System.Drawing.Point(20, 65)
    $lblMethod.AutoSize = $true
    $form.Controls.Add($lblMethod)

    $cmbMethod = New-Object System.Windows.Forms.ComboBox
    $cmbMethod.Location = New-Object System.Drawing.Point(120, 63)
    $cmbMethod.Size = New-Object System.Drawing.Size(360, 25)
    $cmbMethod.DropDownStyle = "DropDownList"
    $cmbMethod.Items.AddRange(@(
        "-like （ワイルドカード: *文字*）",
        "-notlike （含まない）",
        "-match （正規表現）",
        "-notmatch （正規表現で一致しない）"
    ))
    $cmbMethod.SelectedIndex = 0
    $form.Controls.Add($cmbMethod)

    # パターン
    $lblPattern = New-Object System.Windows.Forms.Label
    $lblPattern.Text = "パターン："
    $lblPattern.Location = New-Object System.Drawing.Point(20, 105)
    $lblPattern.AutoSize = $true
    $form.Controls.Add($lblPattern)

    $chkPatternVar = New-Object System.Windows.Forms.CheckBox
    $chkPatternVar.Text = "変数を使用"
    $chkPatternVar.Location = New-Object System.Drawing.Point(120, 103)
    $chkPatternVar.AutoSize = $true
    $form.Controls.Add($chkPatternVar)

    $txtPattern = New-Object System.Windows.Forms.TextBox
    $txtPattern.Location = New-Object System.Drawing.Point(240, 101)
    $txtPattern.Size = New-Object System.Drawing.Size(240, 25)
    $txtPattern.Text = "*検索文字*"
    $form.Controls.Add($txtPattern)

    $cmbPatternVar = New-Object System.Windows.Forms.ComboBox
    $cmbPatternVar.Location = New-Object System.Drawing.Point(240, 101)
    $cmbPatternVar.Size = New-Object System.Drawing.Size(240, 25)
    $cmbPatternVar.Items.AddRange($variablesList)
    $cmbPatternVar.Visible = $false
    $form.Controls.Add($cmbPatternVar)

    # ヒント
    $lblHint = New-Object System.Windows.Forms.Label
    $lblHint.Text = "※ -like: * は任意の文字列、? は任意の1文字`r`n※ -match: 正規表現を使用（例: ^開始, 終了$, [0-9]+）"
    $lblHint.Location = New-Object System.Drawing.Point(20, 140)
    $lblHint.Size = New-Object System.Drawing.Size(460, 35)
    $lblHint.ForeColor = [System.Drawing.Color]::Gray
    $form.Controls.Add($lblHint)

    # プレビュー
    $lblPreview = New-Object System.Windows.Forms.Label
    $lblPreview.Text = "プレビュー："
    $lblPreview.Location = New-Object System.Drawing.Point(20, 185)
    $lblPreview.AutoSize = $true
    $form.Controls.Add($lblPreview)

    $txtPreview = New-Object System.Windows.Forms.TextBox
    $txtPreview.Location = New-Object System.Drawing.Point(20, 210)
    $txtPreview.Size = New-Object System.Drawing.Size(465, 110)
    $txtPreview.Multiline = $true
    $txtPreview.ReadOnly = $true
    $txtPreview.ScrollBars = "Vertical"
    $txtPreview.Font = New-Object System.Drawing.Font("Consolas", 9)
    $form.Controls.Add($txtPreview)

    # ボタン
    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "OK"
    $btnOK.Location = New-Object System.Drawing.Point(310, 335)
    $btnOK.Size = New-Object System.Drawing.Size(85, 30)
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($btnOK)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "キャンセル"
    $btnCancel.Location = New-Object System.Drawing.Point(405, 335)
    $btnCancel.Size = New-Object System.Drawing.Size(85, 30)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnCancel)

    $form.AcceptButton = $btnOK
    $form.CancelButton = $btnCancel

    # 演算子抽出
    $getOperator = {
        $selected = $cmbMethod.SelectedItem
        if ($selected -match "^(-\w+)") { return $matches[1] }
        return "-like"
    }

    # プレビュー更新
    $updatePreview = {
        $target = if ($chkTargetVar.Checked) { $cmbTargetVar.SelectedItem } else { "`"$($txtTarget.Text)`"" }
        $pattern = if ($chkPatternVar.Checked) { $cmbPatternVar.SelectedItem } else { "`"$($txtPattern.Text)`"" }
        $op = & $getOperator

        if (-not [string]::IsNullOrWhiteSpace($target) -and -not [string]::IsNullOrWhiteSpace($pattern)) {
            $trueLabel = if ($op -like "*not*") { "一致しない" } else { "一致する" }
            $falseLabel = if ($op -like "*not*") { "一致する" } else { "一致しない" }
            $txtPreview.Text = "if ($target $op $pattern) {`r`n    # ${trueLabel}場合の処理`r`n} else {`r`n    # ${falseLabel}場合の処理`r`n}"
        }
    }

    # イベントハンドラ
    $chkTargetVar.Add_CheckedChanged({
        $cmbTargetVar.Visible = $chkTargetVar.Checked
        $txtTarget.Visible = -not $chkTargetVar.Checked
        & $updatePreview
    })

    $chkPatternVar.Add_CheckedChanged({
        $cmbPatternVar.Visible = $chkPatternVar.Checked
        $txtPattern.Visible = -not $chkPatternVar.Checked
        & $updatePreview
    })

    $cmbTargetVar.Add_SelectedIndexChanged($updatePreview)
    $cmbPatternVar.Add_SelectedIndexChanged($updatePreview)
    $txtTarget.Add_TextChanged($updatePreview)
    $txtPattern.Add_TextChanged($updatePreview)
    $cmbMethod.Add_SelectedIndexChanged($updatePreview)

    # 初期プレビュー
    & $updatePreview

    $メインメニューハンドル = メインメニューを最小化
    $result = $form.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    # コード生成
    $target = if ($chkTargetVar.Checked) { $cmbTargetVar.SelectedItem } else { "`"$($txtTarget.Text)`"" }
    $pattern = if ($chkPatternVar.Checked) { $cmbPatternVar.SelectedItem } else { "`"$($txtPattern.Text)`"" }
    $op = & $getOperator

    $code = @"
if ($target $op $pattern) {
---
} else {
---
}
"@

    # JSON形式で返す
    $resultJson = @{
        branchCount = 2
        code = $code
    } | ConvertTo-Json -Compress

    return $resultJson
}
