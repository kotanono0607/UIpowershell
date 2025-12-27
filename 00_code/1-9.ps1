function 1_9 {
    # ================================================================
    # 多分岐（3つ以上の条件分岐）
    # ================================================================
    # 複数の条件をElseIfで分岐する
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
            $folderName = $jsonContent."フォルダパス"
            # 相対フォルダ名を03_history配下のフルパスに変換
            $folderPath = Join-Path $メインPath "03_history\$folderName"
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
    $form.Text = "多分岐（ElseIf）"
    $form.Size = New-Object System.Drawing.Size(600, 550)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.Topmost = $true
    $form.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # 比較対象変数
    $lblTarget = New-Object System.Windows.Forms.Label
    $lblTarget.Text = "比較する変数："
    $lblTarget.Location = New-Object System.Drawing.Point(20, 20)
    $lblTarget.AutoSize = $true
    $form.Controls.Add($lblTarget)

    $cmbTarget = New-Object System.Windows.Forms.ComboBox
    $cmbTarget.Location = New-Object System.Drawing.Point(140, 18)
    $cmbTarget.Size = New-Object System.Drawing.Size(200, 25)
    $cmbTarget.Items.AddRange($variablesList)
    if ($variablesList.Count -gt 0) { $cmbTarget.SelectedIndex = 0 }
    $form.Controls.Add($cmbTarget)

    # 分岐数
    $lblBranches = New-Object System.Windows.Forms.Label
    $lblBranches.Text = "分岐数："
    $lblBranches.Location = New-Object System.Drawing.Point(360, 20)
    $lblBranches.AutoSize = $true
    $form.Controls.Add($lblBranches)

    $numBranches = New-Object System.Windows.Forms.NumericUpDown
    $numBranches.Location = New-Object System.Drawing.Point(420, 18)
    $numBranches.Size = New-Object System.Drawing.Size(60, 25)
    $numBranches.Minimum = 3
    $numBranches.Maximum = 10
    $numBranches.Value = 3
    $form.Controls.Add($numBranches)

    # 条件リストパネル
    $pnlConditions = New-Object System.Windows.Forms.Panel
    $pnlConditions.Location = New-Object System.Drawing.Point(20, 55)
    $pnlConditions.Size = New-Object System.Drawing.Size(545, 280)
    $pnlConditions.AutoScroll = $true
    $pnlConditions.BorderStyle = "FixedSingle"
    $form.Controls.Add($pnlConditions)

    # 条件入力コントロールを格納する配列
    $script:conditionControls = @()

    # 条件行を作成する関数
    $createConditionRow = {
        param($index, $yPos)

        $row = @{}

        # ラベル
        $lbl = New-Object System.Windows.Forms.Label
        if ($index -eq 0) {
            $lbl.Text = "If"
        } elseif ($index -lt ($numBranches.Value - 1)) {
            $lbl.Text = "ElseIf"
        } else {
            $lbl.Text = "Else"
        }
        $lbl.Location = New-Object System.Drawing.Point(5, ($yPos + 5))
        $lbl.Size = New-Object System.Drawing.Size(45, 20)
        $pnlConditions.Controls.Add($lbl)
        $row.label = $lbl

        if ($index -lt ($numBranches.Value - 1)) {
            # 値入力（変数使用チェックボックス）
            $chkVar = New-Object System.Windows.Forms.CheckBox
            $chkVar.Text = "変数"
            $chkVar.Location = New-Object System.Drawing.Point(55, ($yPos + 3))
            $chkVar.Size = New-Object System.Drawing.Size(55, 20)
            $pnlConditions.Controls.Add($chkVar)
            $row.chkVar = $chkVar

            # 値テキストボックス
            $txtValue = New-Object System.Windows.Forms.TextBox
            $txtValue.Location = New-Object System.Drawing.Point(115, $yPos)
            $txtValue.Size = New-Object System.Drawing.Size(150, 25)
            $txtValue.Text = "値$($index + 1)"
            $pnlConditions.Controls.Add($txtValue)
            $row.txtValue = $txtValue

            # 値コンボボックス（変数用）
            $cmbValue = New-Object System.Windows.Forms.ComboBox
            $cmbValue.Location = New-Object System.Drawing.Point(115, $yPos)
            $cmbValue.Size = New-Object System.Drawing.Size(150, 25)
            $cmbValue.Items.AddRange($variablesList)
            $cmbValue.Visible = $false
            $pnlConditions.Controls.Add($cmbValue)
            $row.cmbValue = $cmbValue

            # 説明ラベル
            $lblDesc = New-Object System.Windows.Forms.Label
            $lblDesc.Text = "の場合"
            $lblDesc.Location = New-Object System.Drawing.Point(270, ($yPos + 5))
            $lblDesc.AutoSize = $true
            $pnlConditions.Controls.Add($lblDesc)
            $row.lblDesc = $lblDesc

            # チェックボックスイベント
            $chkVar.Add_CheckedChanged({
                param($sender)
                $idx = $script:conditionControls.IndexOf(($script:conditionControls | Where-Object { $_.chkVar -eq $sender }))
                if ($idx -ge 0) {
                    $script:conditionControls[$idx].txtValue.Visible = -not $sender.Checked
                    $script:conditionControls[$idx].cmbValue.Visible = $sender.Checked
                }
                & $updatePreview
            }.GetNewClosure())

            $txtValue.Add_TextChanged($updatePreview)
            $cmbValue.Add_SelectedIndexChanged($updatePreview)
        } else {
            # Elseの場合は説明のみ
            $lblDesc = New-Object System.Windows.Forms.Label
            $lblDesc.Text = "（上記以外の場合）"
            $lblDesc.Location = New-Object System.Drawing.Point(55, ($yPos + 5))
            $lblDesc.AutoSize = $true
            $lblDesc.ForeColor = [System.Drawing.Color]::Gray
            $pnlConditions.Controls.Add($lblDesc)
            $row.lblDesc = $lblDesc
        }

        return $row
    }

    # 条件リストを再構築
    $rebuildConditions = {
        $pnlConditions.Controls.Clear()
        $script:conditionControls = @()

        $branchCount = [int]$numBranches.Value
        $yPos = 5

        for ($i = 0; $i -lt $branchCount; $i++) {
            $row = & $createConditionRow $i $yPos
            $script:conditionControls += $row
            $yPos += 35
        }

        & $updatePreview
    }

    # プレビュー
    $lblPreview = New-Object System.Windows.Forms.Label
    $lblPreview.Text = "プレビュー："
    $lblPreview.Location = New-Object System.Drawing.Point(20, 345)
    $lblPreview.AutoSize = $true
    $form.Controls.Add($lblPreview)

    $txtPreview = New-Object System.Windows.Forms.TextBox
    $txtPreview.Location = New-Object System.Drawing.Point(20, 370)
    $txtPreview.Size = New-Object System.Drawing.Size(545, 80)
    $txtPreview.Multiline = $true
    $txtPreview.ReadOnly = $true
    $txtPreview.ScrollBars = "Both"
    $txtPreview.WordWrap = $false
    $txtPreview.Font = New-Object System.Drawing.Font("Consolas", 9)
    $form.Controls.Add($txtPreview)

    # ボタン
    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "OK"
    $btnOK.Location = New-Object System.Drawing.Point(380, 465)
    $btnOK.Size = New-Object System.Drawing.Size(85, 30)
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($btnOK)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "キャンセル"
    $btnCancel.Location = New-Object System.Drawing.Point(475, 465)
    $btnCancel.Size = New-Object System.Drawing.Size(85, 30)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnCancel)

    $form.AcceptButton = $btnOK
    $form.CancelButton = $btnCancel

    # プレビュー更新
    $updatePreview = {
        $target = $cmbTarget.SelectedItem
        if ([string]::IsNullOrWhiteSpace($target)) {
            $txtPreview.Text = ""
            return
        }

        $branchCount = [int]$numBranches.Value
        $preview = ""

        for ($i = 0; $i -lt $branchCount; $i++) {
            $row = $script:conditionControls[$i]

            if ($i -eq 0) {
                # If
                $value = if ($row.chkVar -and $row.chkVar.Checked) { $row.cmbValue.SelectedItem } else { "`"$($row.txtValue.Text)`"" }
                $preview += "if ($target -eq $value) {`r`n    # 条件1の処理`r`n}"
            } elseif ($i -lt ($branchCount - 1)) {
                # ElseIf
                $value = if ($row.chkVar -and $row.chkVar.Checked) { $row.cmbValue.SelectedItem } else { "`"$($row.txtValue.Text)`"" }
                $preview += " elseif ($target -eq $value) {`r`n    # 条件$($i + 1)の処理`r`n}"
            } else {
                # Else
                $preview += " else {`r`n    # 上記以外の処理`r`n}"
            }
        }

        $txtPreview.Text = $preview
    }

    # イベントハンドラ
    $numBranches.Add_ValueChanged($rebuildConditions)
    $cmbTarget.Add_SelectedIndexChanged($updatePreview)

    # 初期化
    & $rebuildConditions

    $メインメニューハンドル = メインメニューを最小化
    $result = $form.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    # コード生成
    $target = $cmbTarget.SelectedItem
    if ([string]::IsNullOrWhiteSpace($target)) {
        return $null
    }

    $branchCount = [int]$numBranches.Value
    $code = ""

    for ($i = 0; $i -lt $branchCount; $i++) {
        $row = $script:conditionControls[$i]

        if ($i -eq 0) {
            # If
            $value = if ($row.chkVar -and $row.chkVar.Checked) { $row.cmbValue.SelectedItem } else { "`"$($row.txtValue.Text)`"" }
            $code += "if ($target -eq $value) {`r`n---`r`n}"
        } elseif ($i -lt ($branchCount - 1)) {
            # ElseIf
            $value = if ($row.chkVar -and $row.chkVar.Checked) { $row.cmbValue.SelectedItem } else { "`"$($row.txtValue.Text)`"" }
            $code += " elseif ($target -eq $value) {`r`n---`r`n}"
        } else {
            # Else
            $code += " else {`r`n---`r`n}"
        }
    }

    # JSON形式で返す
    $resultJson = @{
        branchCount = $branchCount
        code = $code
    } | ConvertTo-Json -Compress

    return $resultJson
}
