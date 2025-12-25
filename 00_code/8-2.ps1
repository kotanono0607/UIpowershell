
function 8_2 {
    # 変数ビューア：実行時に変数の中身を確認するためのノード
    # ノード追加時に変数名を選択し、実行時にその変数の中身を表示する

    $変数ファイルパス = $global:JSONPath

    # variables.jsonが存在しない場合
    if (-not (Test-Path -Path $変数ファイルパス)) {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show(
            "変数ファイルが存在しません。`n先にExcel読み込みなどで変数を作成してください。",
            "エラー",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return $null
    }

    # 変数を読み込む
    $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス

    # 変数が空の場合
    if ($変数.Count -eq 0) {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show(
            "変数が登録されていません。`n先にExcel読み込みなどで変数を作成してください。",
            "情報",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        return $null
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # 変数選択ダイアログ
    $選択フォーム = New-Object System.Windows.Forms.Form
    $選択フォーム.Text = "表示する変数を選択"
    $選択フォーム.Size = New-Object System.Drawing.Size(400, 150)
    $選択フォーム.StartPosition = "CenterScreen"
    $選択フォーム.FormBorderStyle = "FixedDialog"
    $選択フォーム.MaximizeBox = $false
    $選択フォーム.MinimizeBox = $false
    $選択フォーム.Topmost = $true
    $選択フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    $ラベル = New-Object System.Windows.Forms.Label
    $ラベル.Text = "実行時に表示する変数を選択："
    $ラベル.Location = New-Object System.Drawing.Point(20, 15)
    $ラベル.AutoSize = $true

    $コンボボックス = New-Object System.Windows.Forms.ComboBox
    $コンボボックス.Location = New-Object System.Drawing.Point(20, 40)
    $コンボボックス.Size = New-Object System.Drawing.Size(340, 30)
    $コンボボックス.DropDownStyle = "DropDownList"

    # 変数名をコンボボックスに追加
    foreach ($キー in $変数.Keys) {
        $コンボボックス.Items.Add($キー) | Out-Null
    }
    if ($コンボボックス.Items.Count -gt 0) {
        $コンボボックス.SelectedIndex = 0
    }

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(200, 75)
    $OKボタン.Size = New-Object System.Drawing.Size(75, 28)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(285, 75)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(75, 28)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $選択フォーム.Controls.Add($ラベル)
    $選択フォーム.Controls.Add($コンボボックス)
    $選択フォーム.Controls.Add($OKボタン)
    $選択フォーム.Controls.Add($キャンセルボタン)
    $選択フォーム.AcceptButton = $OKボタン
    $選択フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $選択フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    $選択された変数名 = $コンボボックス.SelectedItem

    # 実行時に変数を表示するコードを生成
    $entryString = @"
# 変数ビューア: $選択された変数名
`$表示対象 = 変数の値を取得する -変数 `$変数 -名前 "$選択された変数名"
変数をグリッド表示 -変数名 "$選択された変数名" -データ `$表示対象
"@

    return $entryString
}
# 注: 変数をグリッド表示関数は 11_変数機能_変数管理を外から読み込む関数.ps1 で定義
