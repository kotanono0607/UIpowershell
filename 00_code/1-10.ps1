function 1_10 {
    # ================================================================
    # switch文（多分岐）
    # ================================================================
    # 変数の値に応じて複数の処理を分岐するswitch文を生成する
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
    $form.Text = "switch文（多分岐）"
    $form.Size = New-Object System.Drawing.Size(620, 580)
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
    $lblTarget.Text = "switch対象変数："
    $lblTarget.Location = New-Object System.Drawing.Point(20, 20)
    $lblTarget.AutoSize = $true
    $form.Controls.Add($lblTarget)

    $cmbTarget = New-Object System.Windows.Forms.ComboBox
    $cmbTarget.Location = New-Object System.Drawing.Point(150, 18)
    $cmbTarget.Size = New-Object System.Drawing.Size(200, 25)
    $cmbTarget.Items.AddRange($variablesList)
    if ($variablesList.Count -gt 0) { $cmbTarget.SelectedIndex = 0 }
    $form.Controls.Add($cmbTarget)

    # オプション
    $chkWildcard = New-Object System.Windows.Forms.CheckBox
    $chkWildcard.Text = "-Wildcard"
    $chkWildcard.Location = New-Object System.Drawing.Point(370, 20)
    $chkWildcard.AutoSize = $true
    $form.Controls.Add($chkWildcard)

    $chkRegex = New-Object System.Windows.Forms.CheckBox
    $chkRegex.Text = "-Regex"
    $chkRegex.Location = New-Object System.Drawing.Point(470, 20)
    $chkRegex.AutoSize = $true
    $form.Controls.Add($chkRegex)

    # 分岐数
    $lblBranches = New-Object System.Windows.Forms.Label
    $lblBranches.Text = "ケース数："
    $lblBranches.Location = New-Object System.Drawing.Point(20, 55)
    $lblBranches.AutoSize = $true
    $form.Controls.Add($lblBranches)

    $numBranches = New-Object System.Windows.Forms.NumericUpDown
    $numBranches.Location = New-Object System.Drawing.Point(100, 53)
    $numBranches.Size = New-Object System.Drawing.Size(60, 25)
    $numBranches.Minimum = 2
    $numBranches.Maximum = 15
    $numBranches.Value = 3
    $form.Controls.Add($numBranches)

    $chkDefault = New-Object System.Windows.Forms.CheckBox
    $chkDefault.Text = "default句を含む"
    $chkDefault.Location = New-Object System.Drawing.Point(180, 55)
    $chkDefault.AutoSize = $true
    $chkDefault.Checked = $true
    $form.Controls.Add($chkDefault)

    # ケースリストパネル
    $pnlCases = New-Object System.Windows.Forms.Panel
    $pnlCases.Location = New-Object System.Drawing.Point(20, 90)
    $pnlCases.Size = New-Object System.Drawing.Size(565, 280)
    $pnlCases.AutoScroll = $true
    $pnlCases.BorderStyle = "FixedSingle"
    $form.Controls.Add($pnlCases)

    # ケース入力コントロールを格納する配列
    $script:caseControls = @()

    # ケース行を作成する関数
    $createCaseRow = {
        param($index, $yPos)

        $row = @{}

        # ラベル
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = "case $($index + 1):"
        $lbl.Location = New-Object System.Drawing.Point(5, ($yPos + 5))
        $lbl.Size = New-Object System.Drawing.Size(60, 20)
        $pnlCases.Controls.Add($lbl)
        $row.label = $lbl

        # 値入力（変数使用チェックボックス）
        $chkVar = New-Object System.Windows.Forms.CheckBox
        $chkVar.Text = "変数"
        $chkVar.Location = New-Object System.Drawing.Point(70, ($yPos + 3))
        $chkVar.Size = New-Object System.Drawing.Size(55, 20)
        $pnlCases.Controls.Add($chkVar)
        $row.chkVar = $chkVar

        # 値テキストボックス
        $txtValue = New-Object System.Windows.Forms.TextBox
        $txtValue.Location = New-Object System.Drawing.Point(130, $yPos)
        $txtValue.Size = New-Object System.Drawing.Size(200, 25)
        $txtValue.Text = "値$($index + 1)"
        $pnlCases.Controls.Add($txtValue)
        $row.txtValue = $txtValue

        # 値コンボボックス（変数用）
        $cmbValue = New-Object System.Windows.Forms.ComboBox
        $cmbValue.Location = New-Object System.Drawing.Point(130, $yPos)
        $cmbValue.Size = New-Object System.Drawing.Size(200, 25)
        $cmbValue.Items.AddRange($variablesList)
        $cmbValue.Visible = $false
        $pnlCases.Controls.Add($cmbValue)
        $row.cmbValue = $cmbValue

        # 説明ラベル
        $lblDesc = New-Object System.Windows.Forms.Label
        $lblDesc.Text = "の場合の処理"
        $lblDesc.Location = New-Object System.Drawing.Point(340, ($yPos + 5))
        $lblDesc.AutoSize = $true
        $pnlCases.Controls.Add($lblDesc)
        $row.lblDesc = $lblDesc

        # チェックボックスイベント
        $chkVar.Add_CheckedChanged({
            param($sender)
            $idx = $script:caseControls.IndexOf(($script:caseControls | Where-Object { $_.chkVar -eq $sender }))
            if ($idx -ge 0) {
                $script:caseControls[$idx].txtValue.Visible = -not $sender.Checked
                $script:caseControls[$idx].cmbValue.Visible = $sender.Checked
            }
            & $updatePreview
        }.GetNewClosure())

        $txtValue.Add_TextChanged($updatePreview)
        $cmbValue.Add_SelectedIndexChanged($updatePreview)

        return $row
    }

    # ケースリストを再構築
    $rebuildCases = {
        $pnlCases.Controls.Clear()
        $script:caseControls = @()

        $caseCount = [int]$numBranches.Value
        $yPos = 5

        for ($i = 0; $i -lt $caseCount; $i++) {
            $row = & $createCaseRow $i $yPos
            $script:caseControls += $row
            $yPos += 35
        }

        & $updatePreview
    }

    # プレビュー
    $lblPreview = New-Object System.Windows.Forms.Label
    $lblPreview.Text = "プレビュー："
    $lblPreview.Location = New-Object System.Drawing.Point(20, 380)
    $lblPreview.AutoSize = $true
    $form.Controls.Add($lblPreview)

    $txtPreview = New-Object System.Windows.Forms.TextBox
    $txtPreview.Location = New-Object System.Drawing.Point(20, 405)
    $txtPreview.Size = New-Object System.Drawing.Size(565, 80)
    $txtPreview.Multiline = $true
    $txtPreview.ReadOnly = $true
    $txtPreview.ScrollBars = "Both"
    $txtPreview.WordWrap = $false
    $txtPreview.Font = New-Object System.Drawing.Font("Consolas", 9)
    $form.Controls.Add($txtPreview)

    # ボタン
    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "OK"
    $btnOK.Location = New-Object System.Drawing.Point(400, 500)
    $btnOK.Size = New-Object System.Drawing.Size(85, 30)
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($btnOK)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "キャンセル"
    $btnCancel.Location = New-Object System.Drawing.Point(495, 500)
    $btnCancel.Size = New-Object System.Drawing.Size(85, 30)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnCancel)

    $form.AcceptButton = $btnOK
    $form.CancelButton = $btnCancel

    # オプション排他制御
    $chkWildcard.Add_CheckedChanged({
        if ($chkWildcard.Checked) { $chkRegex.Checked = $false }
        & $updatePreview
    })
    $chkRegex.Add_CheckedChanged({
        if ($chkRegex.Checked) { $chkWildcard.Checked = $false }
        & $updatePreview
    })

    # プレビュー更新
    $updatePreview = {
        $target = $cmbTarget.SelectedItem
        if ([string]::IsNullOrWhiteSpace($target)) {
            $txtPreview.Text = ""
            return
        }

        $options = ""
        if ($chkWildcard.Checked) { $options = " -Wildcard" }
        if ($chkRegex.Checked) { $options = " -Regex" }

        $caseCount = [int]$numBranches.Value
        $preview = "switch$options ($target) {`r`n"

        for ($i = 0; $i -lt $caseCount; $i++) {
            $row = $script:caseControls[$i]
            $value = if ($row.chkVar -and $row.chkVar.Checked) { $row.cmbValue.SelectedItem } else { "`"$($row.txtValue.Text)`"" }
            $preview += "    $value { # 処理$($i + 1) }`r`n"
        }

        if ($chkDefault.Checked) {
            $preview += "    default { # 上記以外 }`r`n"
        }

        $preview += "}"

        $txtPreview.Text = $preview
    }

    # イベントハンドラ
    $numBranches.Add_ValueChanged($rebuildCases)
    $cmbTarget.Add_SelectedIndexChanged($updatePreview)
    $chkDefault.Add_CheckedChanged($updatePreview)

    # 初期化
    & $rebuildCases

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

    $options = ""
    if ($chkWildcard.Checked) { $options = " -Wildcard" }
    if ($chkRegex.Checked) { $options = " -Regex" }

    $caseCount = [int]$numBranches.Value
    $totalBranches = $caseCount + $(if ($chkDefault.Checked) { 1 } else { 0 })

    $code = "switch$options ($target) {`r`n"

    for ($i = 0; $i -lt $caseCount; $i++) {
        $row = $script:caseControls[$i]
        $value = if ($row.chkVar -and $row.chkVar.Checked) { $row.cmbValue.SelectedItem } else { "`"$($row.txtValue.Text)`"" }
        $code += "    $value {`r`n---`r`n    }`r`n"
    }

    if ($chkDefault.Checked) {
        $code += "    default {`r`n---`r`n    }`r`n"
    }

    $code += "}"

    # JSON形式で返す
    $resultJson = @{
        branchCount = $totalBranches
        code = $code
    } | ConvertTo-Json -Compress

    return $resultJson
}
