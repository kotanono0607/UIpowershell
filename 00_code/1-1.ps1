function 1_1 {
    # 順次処理：番号を入力してコード生成

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "順次ノード設定"
    $フォーム.Size = New-Object System.Drawing.Size(350, 180)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # 番号ラベル
    $ラベル = New-Object System.Windows.Forms.Label
    $ラベル.Text = "番号を入力してください："
    $ラベル.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル.AutoSize = $true

    # 番号入力
    $番号テキスト = New-Object System.Windows.Forms.NumericUpDown
    $番号テキスト.Location = New-Object System.Drawing.Point(20, 50)
    $番号テキスト.Size = New-Object System.Drawing.Size(100, 25)
    $番号テキスト.Minimum = 1
    $番号テキスト.Maximum = 9999
    $番号テキスト.Value = 1

    # OKボタン
    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(140, 95)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    # キャンセルボタン
    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(240, 95)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル, $番号テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $番号 = [int]$番号テキスト.Value

    # コード生成
    $code = @"
Write-Host "${番号}OK"
"@

    # JSON形式で返す（ノード名更新用）
    $response = @{
        code = $code
        nodeName = "順次$番号"
    }

    return ($response | ConvertTo-Json -Compress)
}
