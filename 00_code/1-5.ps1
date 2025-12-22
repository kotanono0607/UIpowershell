function 1_5 {
    # ================================================================
    # 条件付きループ (while / do-while)
    # ================================================================
    # 条件が真の間、繰り返すループを生成する
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
    $form.Text = "条件付きループ (while)"
    $form.Size = New-Object System.Drawing.Size(550, 420)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.Topmost = $true

    # ループタイプ選択
    $lblLoopType = New-Object System.Windows.Forms.Label
    $lblLoopType.Text = "ループタイプ："
    $lblLoopType.Location = New-Object System.Drawing.Point(20, 20)
    $lblLoopType.AutoSize = $true
    $form.Controls.Add($lblLoopType)

    $cmbLoopType = New-Object System.Windows.Forms.ComboBox
    $cmbLoopType.Location = New-Object System.Drawing.Point(150, 18)
    $cmbLoopType.Size = New-Object System.Drawing.Size(200, 25)
    $cmbLoopType.DropDownStyle = "DropDownList"
    $cmbLoopType.Items.Add("while（先に条件判定）") | Out-Null
    $cmbLoopType.Items.Add("do-while（後で条件判定）") | Out-Null
    $cmbLoopType.SelectedIndex = 0
    $form.Controls.Add($cmbLoopType)

    # 条件式セクション
    $grpCondition = New-Object System.Windows.Forms.GroupBox
    $grpCondition.Text = "条件式"
    $grpCondition.Location = New-Object System.Drawing.Point(20, 60)
    $grpCondition.Size = New-Object System.Drawing.Size(495, 130)
    $form.Controls.Add($grpCondition)

    # 左辺
    $lblLeft = New-Object System.Windows.Forms.Label
    $lblLeft.Text = "左辺："
    $lblLeft.Location = New-Object System.Drawing.Point(10, 25)
    $lblLeft.AutoSize = $true
    $grpCondition.Controls.Add($lblLeft)

    $chkLeftVar = New-Object System.Windows.Forms.CheckBox
    $chkLeftVar.Text = "変数"
    $chkLeftVar.Location = New-Object System.Drawing.Point(60, 25)
    $chkLeftVar.AutoSize = $true
    $grpCondition.Controls.Add($chkLeftVar)

    $txtLeft = New-Object System.Windows.Forms.TextBox
    $txtLeft.Location = New-Object System.Drawing.Point(130, 23)
    $txtLeft.Size = New-Object System.Drawing.Size(150, 25)
    $txtLeft.Text = "1"
    $grpCondition.Controls.Add($txtLeft)

    $cmbLeftVar = New-Object System.Windows.Forms.ComboBox
    $cmbLeftVar.Location = New-Object System.Drawing.Point(130, 23)
    $cmbLeftVar.Size = New-Object System.Drawing.Size(150, 25)
    $cmbLeftVar.Items.AddRange($variablesList)
    $cmbLeftVar.Visible = $false
    $grpCondition.Controls.Add($cmbLeftVar)

    # 演算子
    $lblOperator = New-Object System.Windows.Forms.Label
    $lblOperator.Text = "演算子："
    $lblOperator.Location = New-Object System.Drawing.Point(10, 60)
    $lblOperator.AutoSize = $true
    $grpCondition.Controls.Add($lblOperator)

    $cmbOperator = New-Object System.Windows.Forms.ComboBox
    $cmbOperator.Location = New-Object System.Drawing.Point(130, 58)
    $cmbOperator.Size = New-Object System.Drawing.Size(150, 25)
    $cmbOperator.DropDownStyle = "DropDownList"
    $cmbOperator.Items.AddRange(@("-eq (等しい)", "-ne (等しくない)", "-lt (より小さい)", "-gt (より大きい)", "-le (以下)", "-ge (以上)"))
    $cmbOperator.SelectedIndex = 2  # -lt
    $grpCondition.Controls.Add($cmbOperator)

    # 右辺
    $lblRight = New-Object System.Windows.Forms.Label
    $lblRight.Text = "右辺："
    $lblRight.Location = New-Object System.Drawing.Point(10, 95)
    $lblRight.AutoSize = $true
    $grpCondition.Controls.Add($lblRight)

    $chkRightVar = New-Object System.Windows.Forms.CheckBox
    $chkRightVar.Text = "変数"
    $chkRightVar.Location = New-Object System.Drawing.Point(60, 95)
    $chkRightVar.AutoSize = $true
    $grpCondition.Controls.Add($chkRightVar)

    $txtRight = New-Object System.Windows.Forms.TextBox
    $txtRight.Location = New-Object System.Drawing.Point(130, 93)
    $txtRight.Size = New-Object System.Drawing.Size(150, 25)
    $txtRight.Text = "10"
    $grpCondition.Controls.Add($txtRight)

    $cmbRightVar = New-Object System.Windows.Forms.ComboBox
    $cmbRightVar.Location = New-Object System.Drawing.Point(130, 93)
    $cmbRightVar.Size = New-Object System.Drawing.Size(150, 25)
    $cmbRightVar.Items.AddRange($variablesList)
    $cmbRightVar.Visible = $false
    $grpCondition.Controls.Add($cmbRightVar)

    # 直接入力オプション
    $chkDirect = New-Object System.Windows.Forms.CheckBox
    $chkDirect.Text = "条件式を直接入力"
    $chkDirect.Location = New-Object System.Drawing.Point(300, 25)
    $chkDirect.AutoSize = $true
    $grpCondition.Controls.Add($chkDirect)

    $txtDirectCondition = New-Object System.Windows.Forms.TextBox
    $txtDirectCondition.Location = New-Object System.Drawing.Point(300, 55)
    $txtDirectCondition.Size = New-Object System.Drawing.Size(180, 60)
    $txtDirectCondition.Multiline = $true
    $txtDirectCondition.Visible = $false
    $txtDirectCondition.Text = '$i -lt 10'
    $grpCondition.Controls.Add($txtDirectCondition)

    # プレビュー
    $lblPreview = New-Object System.Windows.Forms.Label
    $lblPreview.Text = "プレビュー："
    $lblPreview.Location = New-Object System.Drawing.Point(20, 200)
    $lblPreview.AutoSize = $true
    $form.Controls.Add($lblPreview)

    $txtPreview = New-Object System.Windows.Forms.TextBox
    $txtPreview.Location = New-Object System.Drawing.Point(20, 225)
    $txtPreview.Size = New-Object System.Drawing.Size(495, 100)
    $txtPreview.Multiline = $true
    $txtPreview.ReadOnly = $true
    $txtPreview.ScrollBars = "Vertical"
    $txtPreview.Font = New-Object System.Drawing.Font("Consolas", 9)
    $form.Controls.Add($txtPreview)

    # ボタン
    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "OK"
    $btnOK.Location = New-Object System.Drawing.Point(330, 340)
    $btnOK.Size = New-Object System.Drawing.Size(85, 30)
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($btnOK)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "キャンセル"
    $btnCancel.Location = New-Object System.Drawing.Point(425, 340)
    $btnCancel.Size = New-Object System.Drawing.Size(85, 30)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnCancel)

    $form.AcceptButton = $btnOK
    $form.CancelButton = $btnCancel

    # 演算子変換
    $getOperator = {
        $selected = $cmbOperator.SelectedItem
        if ($selected -match "^(-\w+)") {
            return $matches[1]
        }
        return "-eq"
    }

    # 条件式取得
    $getCondition = {
        if ($chkDirect.Checked) {
            return $txtDirectCondition.Text.Trim()
        }

        $left = if ($chkLeftVar.Checked) { $cmbLeftVar.SelectedItem } else { $txtLeft.Text }
        $right = if ($chkRightVar.Checked) { $cmbRightVar.SelectedItem } else { $txtRight.Text }
        $op = & $getOperator

        if ([string]::IsNullOrWhiteSpace($left) -or [string]::IsNullOrWhiteSpace($right)) {
            return ""
        }

        # 固定値の場合は引用符を付ける
        if (-not $chkLeftVar.Checked -and $left -notmatch '^\$') {
            $left = "`"$left`""
        }
        if (-not $chkRightVar.Checked -and $right -notmatch '^\$') {
            $right = "`"$right`""
        }

        return "$left $op $right"
    }

    # プレビュー更新関数
    $updatePreview = {
        $condition = & $getCondition
        $loopType = $cmbLoopType.SelectedItem

        if ([string]::IsNullOrWhiteSpace($condition)) {
            $txtPreview.Text = ""
            return
        }

        if ($loopType -like "*do-while*") {
            $txtPreview.Text = "do {`r`n    # 処理内容`r`n} while ($condition)"
        } else {
            $txtPreview.Text = "while ($condition) {`r`n    # 処理内容`r`n}"
        }
    }

    # イベントハンドラ
    $chkLeftVar.Add_CheckedChanged({
        $txtLeft.Visible = -not $chkLeftVar.Checked
        $cmbLeftVar.Visible = $chkLeftVar.Checked
        & $updatePreview
    })

    $chkRightVar.Add_CheckedChanged({
        $txtRight.Visible = -not $chkRightVar.Checked
        $cmbRightVar.Visible = $chkRightVar.Checked
        & $updatePreview
    })

    $chkDirect.Add_CheckedChanged({
        $txtDirectCondition.Visible = $chkDirect.Checked
        $txtLeft.Enabled = -not $chkDirect.Checked
        $txtRight.Enabled = -not $chkDirect.Checked
        $cmbLeftVar.Enabled = -not $chkDirect.Checked
        $cmbRightVar.Enabled = -not $chkDirect.Checked
        $cmbOperator.Enabled = -not $chkDirect.Checked
        $chkLeftVar.Enabled = -not $chkDirect.Checked
        $chkRightVar.Enabled = -not $chkDirect.Checked
        & $updatePreview
    })

    $cmbLoopType.Add_SelectedIndexChanged($updatePreview)
    $txtLeft.Add_TextChanged($updatePreview)
    $txtRight.Add_TextChanged($updatePreview)
    $cmbLeftVar.Add_SelectedIndexChanged($updatePreview)
    $cmbRightVar.Add_SelectedIndexChanged($updatePreview)
    $cmbOperator.Add_SelectedIndexChanged($updatePreview)
    $txtDirectCondition.Add_TextChanged($updatePreview)

    # 初期プレビュー
    & $updatePreview

    $メインメニューハンドル = メインメニューを最小化
    $result = $form.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    # コード生成
    $condition = & $getCondition
    $loopType = $cmbLoopType.SelectedItem

    if ([string]::IsNullOrWhiteSpace($condition)) {
        return $null
    }

    if ($loopType -like "*do-while*") {
        $loopCode = @"
do {
---
} while ($condition)
"@
    } else {
        $loopCode = @"
while ($condition) {
---
}
"@
    }

    return $loopCode
}
