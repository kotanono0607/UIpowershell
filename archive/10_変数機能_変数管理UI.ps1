function Show-VariableManagerForm {
    # ユーザーフォームで二次元配列を扱う変数管理システム（JSON出力・読み込み機能付き）
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # グローバル変数管理辞書
    if (-not $global:variables) {
        $global:variables = @{}
    }

    # メインフォーム作成
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "変数管理システム"
    $form.Size = New-Object System.Drawing.Size(700, 800)
    $form.StartPosition = "CenterScreen"
    $form.AutoScroll = $true  # スクロールを有効化

    # 変数一覧リストボックス
    $lstVariables = New-Object System.Windows.Forms.ListBox
    $lstVariables.Location = New-Object System.Drawing.Point(20, 20)
    $lstVariables.Size = New-Object System.Drawing.Size(300, 350)
    $form.Controls.Add($lstVariables)

    # 現在選択中の変数名を表示するテキストボックスとラベル
    $lblSelectedVariable = New-Object System.Windows.Forms.Label
    $lblSelectedVariable.Text = "選択中の変数名："
    $lblSelectedVariable.Location = New-Object System.Drawing.Point(20, 380)
    $lblSelectedVariable.AutoSize = $true
    $form.Controls.Add($lblSelectedVariable)

    $txtSelectedVariable = New-Object System.Windows.Forms.TextBox
    $txtSelectedVariable.Location = New-Object System.Drawing.Point(20, 410)
    $txtSelectedVariable.Width = 250
    $txtSelectedVariable.ReadOnly = $true
    $form.Controls.Add($txtSelectedVariable)

    # 変数取得ボタン
    $btnRetrieve = New-Object System.Windows.Forms.Button
    $btnRetrieve.Text = "変数取得"
    $btnRetrieve.Location = New-Object System.Drawing.Point(20, 450)
    $btnRetrieve.Size = New-Object System.Drawing.Size(100, 30)
    $form.Controls.Add($btnRetrieve)

    # ラベル
    $lblInfo = New-Object System.Windows.Forms.Label
    $lblInfo.Text = "変数の追加/編集"
    $lblInfo.Location = New-Object System.Drawing.Point(350, 20)
    $lblInfo.AutoSize = $true
    $form.Controls.Add($lblInfo)

    # テキストボックス (変数名)
    $lblName = New-Object System.Windows.Forms.Label
    $lblName.Text = "変数名:"
    $lblName.Location = New-Object System.Drawing.Point(350, 60)
    $lblName.AutoSize = $true
    $form.Controls.Add($lblName)

    $txtName = New-Object System.Windows.Forms.TextBox
    $txtName.Location = New-Object System.Drawing.Point(460, 60)
    $txtName.Width = 200
    $form.Controls.Add($txtName)

    # コンボボックス (データ型)
    $lblType = New-Object System.Windows.Forms.Label
    $lblType.Text = "データ型:"
    $lblType.Location = New-Object System.Drawing.Point(350, 100)
    $lblType.AutoSize = $true
    $form.Controls.Add($lblType)

    $cmbType = New-Object System.Windows.Forms.ComboBox
    $cmbType.Location = New-Object System.Drawing.Point(460, 100)
    $cmbType.Width = 200
    $cmbType.DropDownStyle = "DropDownList"
    $cmbType.Items.Add("単一値") | Out-Null
    $cmbType.Items.Add("一次元") | Out-Null
    $cmbType.Items.Add("二次元") | Out-Null
    $form.Controls.Add($cmbType)

    # データグリッドビュー (二次元配列)
    $gridView = New-Object System.Windows.Forms.DataGridView
    $gridView.Location = New-Object System.Drawing.Point(350, 150)
    $gridView.Size = New-Object System.Drawing.Size(300, 200)
    $gridView.Visible = $false
    $gridView.ReadOnly = $false
    $gridView.AllowUserToAddRows = $true
    $gridView.AllowUserToDeleteRows = $true
    $gridView.EditMode = "EditOnKeystrokeOrF2"
    $gridView.AutoSizeColumnsMode = "Fill"
    $form.Controls.Add($gridView)

    # テキストボックス (一次元変数の値)
    $txtValue = New-Object System.Windows.Forms.TextBox
    $txtValue.Location = New-Object System.Drawing.Point(350, 150)
    $txtValue.Width = 300
    $txtValue.Visible = $false
    $form.Controls.Add($txtValue)

    # ボタン (列追加)
    $btnAddColumn = New-Object System.Windows.Forms.Button
    $btnAddColumn.Text = "列追加"
    $btnAddColumn.Location = New-Object System.Drawing.Point(350, 360)
    $btnAddColumn.Visible = $false
    $form.Controls.Add($btnAddColumn)

    # ボタン (列削除)
    $btnRemoveColumn = New-Object System.Windows.Forms.Button
    $btnRemoveColumn.Text = "列削除"
    $btnRemoveColumn.Location = New-Object System.Drawing.Point(450, 360)
    $btnRemoveColumn.Visible = $false
    $form.Controls.Add($btnRemoveColumn)

    # ボタン (追加/更新)
    $btnAddUpdate = New-Object System.Windows.Forms.Button
    $btnAddUpdate.Text = "追加/更新"
    $btnAddUpdate.Location = New-Object System.Drawing.Point(350, 410)
    $form.Controls.Add($btnAddUpdate)

    # ボタン (削除)
    $btnDelete = New-Object System.Windows.Forms.Button
    $btnDelete.Text = "削除"
    $btnDelete.Location = New-Object System.Drawing.Point(450, 410)
    $form.Controls.Add($btnDelete)

    # ボタン (JSON出力)
    $btnExportJson = New-Object System.Windows.Forms.Button
    $btnExportJson.Text = "JSON出力"
    $btnExportJson.Location = New-Object System.Drawing.Point(350, 460)
    $form.Controls.Add($btnExportJson)

    # ボタン (JSON読み込み)
    $btnImportJson = New-Object System.Windows.Forms.Button
    $btnImportJson.Text = "JSON読み込み"
    $btnImportJson.Location = New-Object System.Drawing.Point(450, 460)
    $form.Controls.Add($btnImportJson)

    # 選択された変数名を保持する変数
    $script:selectedVariableName = $null

    # 更新関数
    function Refresh-VariableList {
        $lstVariables.Items.Clear()
        foreach ($key in $global:variables.Keys) {
            $value = $global:variables[$key]
            if ($value -is [object[]] -and $value.Count -gt 0 -and $value[0] -is [object[]]) {
                # 二次元配列
                $displayValue = ($value | ForEach-Object { ($_ -join ", ") }) -join "; "
            } elseif ($value -is [object[]]) {
                # 一次元配列
                $displayValue = ($value -join ", ")
            } else {
                # 単一値
                $displayValue = $value
            }
            $lstVariables.Items.Add("$key = $displayValue") | Out-Null
        }
    }

    # イベント: リスト選択時の再編集準備
    $lstVariables.add_SelectedIndexChanged({
        $selectedItem = $lstVariables.SelectedItem
        if ($null -eq $selectedItem) {
            $txtSelectedVariable.Text = ""
            $script:selectedVariableName = $null
            return
        }

        $keyToEdit = $selectedItem.Split("=")[0].Trim()
        $valueToEdit = $global:variables[$keyToEdit]

        $txtName.Text = $keyToEdit

        # テキストボックスに選択中の変数名を表示
        $txtSelectedVariable.Text = $keyToEdit
        $script:selectedVariableName = $keyToEdit

        if ($valueToEdit -is [object[]] -and $valueToEdit.Count -gt 0 -and $valueToEdit[0] -is [object[]]) {
            # 二次元配列の場合
            $cmbType.SelectedItem = "二次元"
            $txtValue.Visible = $false
            $gridView.Visible = $true
            $btnAddColumn.Visible = $true
            $btnRemoveColumn.Visible = $true
            $gridView.Columns.Clear()
            $gridView.Rows.Clear()

            # 列を再作成
            $columns = $valueToEdit[0].Length
            for ($i = 0; $i -lt $columns; $i++) {
                $gridView.Columns.Add("Column$i", "列 $($i + 1)") | Out-Null
            }

            # 行を追加
            foreach ($row in $valueToEdit) {
                $gridView.Rows.Add($row) | Out-Null
            }
        } elseif ($valueToEdit -is [object[]]) {
            # 一次元配列の場合
            $cmbType.SelectedItem = "一次元"
            $txtValue.Visible = $true
            $gridView.Visible = $false
            $btnAddColumn.Visible = $false
            $btnRemoveColumn.Visible = $false
            $txtValue.Text = ($valueToEdit -join ",")
        } else {
            # 単一値の場合
            $cmbType.SelectedItem = "単一値"
            $txtValue.Visible = $true
            $gridView.Visible = $false
            $btnAddColumn.Visible = $false
            $btnRemoveColumn.Visible = $false
            $txtValue.Text = $valueToEdit
        }
    })

    # イベント: データ型選択時の動作
    $cmbType.add_SelectedIndexChanged({
        if ($cmbType.SelectedItem -eq "単一値" -or $cmbType.SelectedItem -eq "一次元") {
            $txtValue.Visible = $true
            $gridView.Visible = $false
            $btnAddColumn.Visible = $false
            $btnRemoveColumn.Visible = $false
        } elseif ($cmbType.SelectedItem -eq "二次元") {
            $txtValue.Visible = $false
            $gridView.Visible = $true
            $btnAddColumn.Visible = $true
            $btnRemoveColumn.Visible = $true
            $gridView.Columns.Clear()
            $gridView.Rows.Clear()
            # 列と行は空のまま。ユーザーが追加する
        }
    })

    # イベント: 列追加
    $btnAddColumn.add_Click({
        $columnIndex = $gridView.Columns.Count + 1
        $gridView.Columns.Add("Column$columnIndex", "列 $columnIndex") | Out-Null
    })

    # イベント: 列削除
    $btnRemoveColumn.add_Click({
        if ($gridView.Columns.Count -gt 0) {
            $gridView.Columns.RemoveAt($gridView.Columns.Count - 1)
        } else {
            Show-WarningDialog "これ以上、列を削除できません。"
        }
    })

    # イベント: 追加/更新
    $btnAddUpdate.add_Click({
        $name = $txtName.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($name)) {
            Show-WarningDialog "変数名を入力してください"
            return
        }

        if ($cmbType.SelectedItem -eq "単一値") {
            $value = $txtValue.Text.Trim()
            if ([string]::IsNullOrWhiteSpace($value)) {
                Show-WarningDialog "値を入力してください。"
                return
            }
            $global:variables[$name] = $value
        } elseif ($cmbType.SelectedItem -eq "一次元") {
            $inputArray = $txtValue.Text -split ','
            if ($inputArray -contains { $_ -match '^\s*$' }) {
                Show-WarningDialog "一次元配列の値が不正です。カンマで区切られた有効な値を入力してください。"
                return
            }
            $global:variables[$name] = $inputArray
        } elseif ($cmbType.SelectedItem -eq "二次元") {
            $array = @()
            foreach ($row in $gridView.Rows) {
                if (-not $row.IsNewRow) {
                    $rowData = @()
                    foreach ($cell in $row.Cells) {
                        $cellValue = $cell.Value
                        if ($null -eq $cellValue) {
                            $cellValue = ""
                        }
                        $rowData += $cellValue
                    }
                    $array += ,$rowData
                }
            }
            $global:variables[$name] = $array
        } else {
            Show-WarningDialog "データ型を選択してください"
            return
        }

        Refresh-VariableList | Out-Null
        $txtName.Clear()
        $txtValue.Clear()
        $gridView.Rows.Clear()
        $gridView.Columns.Clear()
    })

    # イベント: 削除
    $btnDelete.add_Click({
        $selectedItem = $lstVariables.SelectedItem
        if ($null -eq $selectedItem) {
            Show-WarningDialog "削除する変数を選択してください"
            return
        }

        $keyToDelete = $selectedItem.Split("=")[0].Trim()
        if ($global:variables.ContainsKey($keyToDelete)) {
            $global:variables.Remove($keyToDelete)
            Refresh-VariableList | Out-Null
            Show-InfoDialog "変数 '$keyToDelete' を削除しました。"
        } else {
            Show-WarningDialog "指定された変数が見つかりません: $keyToDelete"
        }
    })

    # イベント: JSON出力
    $btnExportJson.add_Click({
    　　$スクリプトPath = $PSScriptRoot # 現在のスクリプトのディレクトリを変数に格納
        # 保存先パスを指定　＃＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝ここ決め打ち
        $outputFile = $global:JSONPath
        try {
            # JSON保存（共通関数使用 - ディレクトリ作成も自動）
            Write-JsonSafe -Path $outputFile -Data $global:variables -Depth 10 -CreateDirectory $true -Silent $true
            Show-InfoDialog "変数がJSON形式で保存されました: `n$outputFile"
        } catch {
            Show-ErrorDialog "JSONの保存に失敗しました: $_"
        }
    })

    # イベント: JSON読み込み
    $btnImportJson.add_Click({

        $スクリプトPath = $PSScriptRoot # 現在のスクリプトのディレクトリを変数に格納

        $inputFile = $global:JSONPath
        if (-not (Test-Path -Path $inputFile)) {
            Show-ErrorDialog "JSONファイルが見つかりません: `n$inputFile"
            return
        }
        try {
            # JSON読み込み（共通関数使用）
            $importedVariables = Read-JsonSafe -Path $inputFile -Required $true -Silent $false

            # デバッグ用出力を抑制
            # Write-Host "importedVariablesの型: $($importedVariables.GetType().FullName)"
            # Write-Host "importedVariablesの内容: $importedVariables"

            if ($importedVariables -is [System.Collections.IEnumerable] -and -not ($importedVariables -is [string])) {
                # 配列の場合
                foreach ($item in $importedVariables) {
                    foreach ($key in $item.PSObject.Properties.Name) {
                        $value = $item.$key
                        Add-VariableToGlobal $key $value
                    }
                }
            } else {
                # オブジェクトの場合
                foreach ($key in $importedVariables.PSObject.Properties.Name) {
                    $value = $importedVariables.$key
                    Add-VariableToGlobal $key $value
                }
            }

            Refresh-VariableList | Out-Null
            [System.Windows.Forms.MessageBox]::Show("JSONファイルを読み込みました: `n$inputFile") | Out-Null
        } catch {
            [System.Windows.Forms.MessageBox]::Show("JSONの読み込みに失敗しました: $_") | Out-Null
        }
    })

    # 変数をグローバル変数に追加する関数
    function Add-VariableToGlobal($key, $value) {
        if ($value -is [System.Array]) {
            if ($value.Length -gt 0 -and ($value[0] -is [System.Array] -or $value[0] -is [System.Object[]])) {
                # 二次元配列
                $array = @()
                foreach ($row in $value) {
                    $rowData = @()
                    foreach ($cell in $row) {
                        $rowData += $cell
                    }
                    $array += ,$rowData
                }
                $global:variables[$key] = $array
            } else {
                # 一次元配列
                $global:variables[$key] = $value
            }
        } else {
            # 単一値
            $global:variables[$key] = $value
        }
    }

    # 変数取得ボタンのクリックイベント
    $btnRetrieve.Add_Click({
        if ($script:selectedVariableName -ne $null) {
            # フォームを閉じて、選択された変数名を返す
            $form.Tag = $script:selectedVariableName
            $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $form.Close()
        } else {
            [System.Windows.Forms.MessageBox]::Show("変数を選択してください。") | Out-Null
        }
    })

    # フォーム初期化時にJSONを読み込み
    function Load-VariablesFromJson {
        $inputFile = $global:JSONPath
        if (-not (Test-Path -Path $inputFile)) {
            return
        }
        try {
            # JSON読み込み（共通関数使用）
            $importedVariables = Read-JsonSafe -Path $inputFile -Required $true -Silent $false

            if ($importedVariables -is [System.Collections.IEnumerable] -and -not ($importedVariables -is [string])) {
                foreach ($item in $importedVariables) {
                    foreach ($key in $item.PSObject.Properties.Name) {
                        $value = $item.$key
                        Add-VariableToGlobal $key $value
                    }
                }
            } else {
                foreach ($key in $importedVariables.PSObject.Properties.Name) {
                    $value = $importedVariables.$key
                    Add-VariableToGlobal $key $value
                }
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("JSONの読み込みに失敗しました: $_") | Out-Null
        }
    }

    # フォーム初期化
    $form.Add_Shown({
        Load-VariablesFromJson | Out-Null
        Refresh-VariableList | Out-Null
    }) | Out-Null

    $dialogResult = $form.ShowDialog()

    # フォームが閉じた後、選択された変数名を取得
    if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedVariable = "$"+ $form.Tag
        # Write-Host "選択された変数名: $selectedVariable"
        return $selectedVariable
    } else {
        # Write-Host "変数取得がキャンセルされました。"
        return $null
    }
}
