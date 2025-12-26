function 1_12 {
    # ================================================================
    # continue（次の繰り返しへ）
    # ================================================================
    # ループの残りの処理をスキップして次の繰り返しへ進む
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

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "continue（次の繰り返しへ）"
    $form.Size = New-Object System.Drawing.Size(450, 280)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.Topmost = $true
    $form.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # 説明
    $lblDesc = New-Object System.Windows.Forms.Label
    $lblDesc.Text = "continue は現在の繰り返し処理の残りをスキップし、`r`n次の繰り返しに進みます。`r`n`r`nループ（for/foreach/while）内でのみ使用できます。"
    $lblDesc.Location = New-Object System.Drawing.Point(20, 20)
    $lblDesc.Size = New-Object System.Drawing.Size(400, 80)
    $form.Controls.Add($lblDesc)

    # ラベル付きcontinue（オプション）
    $chkLabeled = New-Object System.Windows.Forms.CheckBox
    $chkLabeled.Text = "ラベル付きcontinue（外側のループに対して使う場合）"
    $chkLabeled.Location = New-Object System.Drawing.Point(20, 110)
    $chkLabeled.AutoSize = $true
    $form.Controls.Add($chkLabeled)

    $lblLabel = New-Object System.Windows.Forms.Label
    $lblLabel.Text = "ラベル名："
    $lblLabel.Location = New-Object System.Drawing.Point(40, 145)
    $lblLabel.AutoSize = $true
    $lblLabel.Enabled = $false
    $form.Controls.Add($lblLabel)

    $txtLabel = New-Object System.Windows.Forms.TextBox
    $txtLabel.Location = New-Object System.Drawing.Point(120, 143)
    $txtLabel.Size = New-Object System.Drawing.Size(150, 25)
    $txtLabel.Text = "OuterLoop"
    $txtLabel.Enabled = $false
    $form.Controls.Add($txtLabel)

    # ヒント
    $lblHint = New-Object System.Windows.Forms.Label
    $lblHint.Text = "※ ラベル付きcontinueを使う場合、ループに :ラベル名 を付ける必要があります"
    $lblHint.Location = New-Object System.Drawing.Point(40, 175)
    $lblHint.Size = New-Object System.Drawing.Size(380, 20)
    $lblHint.ForeColor = [System.Drawing.Color]::Gray
    $lblHint.Font = New-Object System.Drawing.Font($lblHint.Font.FontFamily, 8)
    $form.Controls.Add($lblHint)

    # ボタン
    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "OK"
    $btnOK.Location = New-Object System.Drawing.Point(250, 200)
    $btnOK.Size = New-Object System.Drawing.Size(85, 30)
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($btnOK)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "キャンセル"
    $btnCancel.Location = New-Object System.Drawing.Point(345, 200)
    $btnCancel.Size = New-Object System.Drawing.Size(85, 30)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($btnCancel)

    $form.AcceptButton = $btnOK
    $form.CancelButton = $btnCancel

    # チェックボックスイベント
    $chkLabeled.Add_CheckedChanged({
        $lblLabel.Enabled = $chkLabeled.Checked
        $txtLabel.Enabled = $chkLabeled.Checked
    })

    $メインメニューハンドル = メインメニューを最小化
    $result = $form.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    # コード生成
    if ($chkLabeled.Checked -and -not [string]::IsNullOrWhiteSpace($txtLabel.Text)) {
        $code = "continue $($txtLabel.Text)"
    } else {
        $code = "continue"
    }

    return $code
}
