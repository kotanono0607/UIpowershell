
function 8_2 {
    # 変数ビューア：変数の中身を確認するためのノード

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

    $ラベル = New-Object System.Windows.Forms.Label
    $ラベル.Text = "変数を選択してください："
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
    $OKボタン.Text = "表示"
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
    $選択された値 = $変数[$選択された変数名]

    # 値の型に応じて表示方法を変える
    if ($選択された値 -is [System.Array] -and $選択された値.Count -gt 0 -and $選択された値[0] -is [System.Array]) {
        # 二次元配列の場合はDataGridViewで表示
        変数をグリッド表示 -変数名 $選択された変数名 -データ $選択された値
    } elseif ($選択された値 -is [System.Array]) {
        # 一次元配列の場合
        $表示テキスト = "【変数名】$選択された変数名`n【型】一次元配列`n【要素数】$($選択された値.Count)`n`n【内容】`n"
        for ($i = 0; $i -lt [Math]::Min($選択された値.Count, 50); $i++) {
            $表示テキスト += "[$i] $($選択された値[$i])`n"
        }
        if ($選択された値.Count -gt 50) {
            $表示テキスト += "... (以降省略、全$($選択された値.Count)件)"
        }
        [System.Windows.Forms.MessageBox]::Show($表示テキスト, "変数の内容", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        # 単一値の場合
        $表示テキスト = "【変数名】$選択された変数名`n【型】単一値`n`n【内容】`n$選択された値"
        [System.Windows.Forms.MessageBox]::Show($表示テキスト, "変数の内容", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }

    # このノードはコードを生成しない（表示のみ）
    return ""
}

# 二次元配列をDataGridViewで表示する関数
function 変数をグリッド表示 {
    param(
        [string]$変数名,
        [array]$データ
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "変数ビューア: $変数名"
    $フォーム.Size = New-Object System.Drawing.Size(900, 600)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.Topmost = $true

    # 情報ラベル
    $情報ラベル = New-Object System.Windows.Forms.Label
    $情報ラベル.Text = "変数名: $変数名  |  行数: $($データ.Count)  |  列数: $($データ[0].Count)"
    $情報ラベル.Location = New-Object System.Drawing.Point(10, 10)
    $情報ラベル.Size = New-Object System.Drawing.Size(860, 20)
    $情報ラベル.Font = New-Object System.Drawing.Font("メイリオ", 10)

    # DataGridView
    $グリッド = New-Object System.Windows.Forms.DataGridView
    $グリッド.Location = New-Object System.Drawing.Point(10, 40)
    $グリッド.Size = New-Object System.Drawing.Size(860, 470)
    $グリッド.AllowUserToAddRows = $false
    $グリッド.AllowUserToDeleteRows = $false
    $グリッド.ReadOnly = $true
    $グリッド.AutoSizeColumnsMode = "AllCells"
    $グリッド.ColumnHeadersHeightSizeMode = "AutoSize"
    $グリッド.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

    # ヘッダー行（最初の行）を列名として使用
    $ヘッダー = $データ[0]
    for ($col = 0; $col -lt $ヘッダー.Count; $col++) {
        $列名 = if ($ヘッダー[$col]) { $ヘッダー[$col].ToString() } else { "列$col" }
        $グリッド.Columns.Add("col$col", $列名) | Out-Null
    }

    # データ行を追加（2行目以降）
    for ($row = 1; $row -lt $データ.Count; $row++) {
        $行データ = @()
        for ($col = 0; $col -lt $データ[$row].Count; $col++) {
            $値 = if ($null -eq $データ[$row][$col]) { "" } else { $データ[$row][$col].ToString() }
            $行データ += $値
        }
        $グリッド.Rows.Add($行データ) | Out-Null
    }

    # 閉じるボタン
    $閉じるボタン = New-Object System.Windows.Forms.Button
    $閉じるボタン.Text = "閉じる"
    $閉じるボタン.Location = New-Object System.Drawing.Point(780, 520)
    $閉じるボタン.Size = New-Object System.Drawing.Size(90, 30)
    $閉じるボタン.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $閉じるボタン.Add_Click({ $フォーム.Close() })

    $フォーム.Controls.Add($情報ラベル)
    $フォーム.Controls.Add($グリッド)
    $フォーム.Controls.Add($閉じるボタン)

    $メインメニューハンドル = メインメニューを最小化
    $フォーム.ShowDialog() | Out-Null
    メインメニューを復元 -ハンドル $メインメニューハンドル
}
