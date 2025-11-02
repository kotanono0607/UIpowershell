# ============================================
# 10_変数機能_変数管理UI_v2.ps1
# UI非依存版 - HTML/JS移行対応
# ============================================
# 変更内容:
#   - Windows Formsダイアログを使わずにデータ操作のみを提供
#   - REST API経由で呼び出せる関数群を作成
#   - 変数の取得/追加/更新/削除/JSON操作をそれぞれ独立した関数に
#   - 既存のShow-VariableManagerForm も維持（後方互換性）
#
# 互換性:
#   - 既存のWindows Forms版でも動作（$showUI = $true の場合）
#   - HTML/JS版でも動作（REST API経由）
# ============================================

# グローバル変数管理辞書の初期化
if (-not $global:variables) {
    $global:variables = @{}
}

# ============================================
# 新しい関数（UI非依存版 - HTML/JS対応）
# ============================================

function Get-VariableList_v2 {
    <#
    .SYNOPSIS
    変数一覧を取得（UI非依存版）

    .DESCRIPTION
    グローバル変数管理辞書から全変数を取得し、構造化データとして返します。
    HTML/JS版のREST API経由で呼び出すことを想定しています。

    .PARAMETER IncludeDisplayValue
    表示用の文字列も含めるかどうか（デフォルト: $true）

    .EXAMPLE
    $result = Get-VariableList_v2
    # 結果: @{ success = $true; variables = @{ ... }; count = 3 }
    #>
    param (
        [bool]$IncludeDisplayValue = $true
    )

    try {
        $variableList = @()

        foreach ($key in $global:variables.Keys) {
            $value = $global:variables[$key]

            # 型の判定
            $type = "単一値"
            $displayValue = $value

            if ($value -is [object[]] -and $value.Count -gt 0 -and $value[0] -is [object[]]) {
                # 二次元配列
                $type = "二次元"
                if ($IncludeDisplayValue) {
                    $displayValue = ($value | ForEach-Object { ($_ -join ", ") }) -join "; "
                }
            } elseif ($value -is [object[]]) {
                # 一次元配列
                $type = "一次元"
                if ($IncludeDisplayValue) {
                    $displayValue = ($value -join ", ")
                }
            }

            $variableInfo = @{
                name = $key
                value = $value
                type = $type
            }

            if ($IncludeDisplayValue) {
                $variableInfo.displayValue = $displayValue
            }

            $variableList += $variableInfo
        }

        return @{
            success = $true
            variables = $variableList
            count = $variableList.Count
        }

    } catch {
        return @{
            success = $false
            error = "変数一覧の取得に失敗しました: $($_.Exception.Message)"
        }
    }
}


function Get-Variable_v2 {
    <#
    .SYNOPSIS
    特定の変数を取得（UI非依存版）

    .PARAMETER Name
    取得する変数名

    .EXAMPLE
    $result = Get-Variable_v2 -Name "Excel2次元配列"
    #>
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    try {
        if (-not $global:variables.ContainsKey($Name)) {
            return @{
                success = $false
                error = "変数 '$Name' が見つかりません"
            }
        }

        $value = $global:variables[$Name]

        # 型の判定
        $type = "単一値"
        if ($value -is [object[]] -and $value.Count -gt 0 -and $value[0] -is [object[]]) {
            $type = "二次元"
        } elseif ($value -is [object[]]) {
            $type = "一次元"
        }

        return @{
            success = $true
            name = $Name
            value = $value
            type = $type
        }

    } catch {
        return @{
            success = $false
            error = "変数の取得に失敗しました: $($_.Exception.Message)"
        }
    }
}


function Add-Variable_v2 {
    <#
    .SYNOPSIS
    変数を追加または更新（UI非依存版）

    .PARAMETER Name
    変数名

    .PARAMETER Value
    変数の値

    .PARAMETER Type
    データ型（"単一値", "一次元", "二次元"）

    .EXAMPLE
    # 単一値
    $result = Add-Variable_v2 -Name "test" -Value "hello" -Type "単一値"

    # 一次元配列
    $result = Add-Variable_v2 -Name "arr" -Value @("A", "B", "C") -Type "一次元"

    # 二次元配列
    $result = Add-Variable_v2 -Name "matrix" -Value @(@("A", "B"), @("C", "D")) -Type "二次元"
    #>
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        $Value,

        [ValidateSet("単一値", "一次元", "二次元")]
        [string]$Type = "単一値"
    )

    try {
        if ([string]::IsNullOrWhiteSpace($Name)) {
            return @{
                success = $false
                error = "変数名を入力してください"
            }
        }

        # 型に応じて処理
        switch ($Type) {
            "単一値" {
                if ($null -eq $Value -or [string]::IsNullOrWhiteSpace($Value.ToString())) {
                    return @{
                        success = $false
                        error = "値を入力してください"
                    }
                }
                $global:variables[$Name] = $Value
            }
            "一次元" {
                if ($Value -isnot [array]) {
                    # 文字列の場合はカンマで分割
                    if ($Value -is [string]) {
                        $Value = $Value -split ','
                    } else {
                        return @{
                            success = $false
                            error = "一次元配列の値が不正です"
                        }
                    }
                }
                $global:variables[$Name] = $Value
            }
            "二次元" {
                if ($Value -isnot [array]) {
                    return @{
                        success = $false
                        error = "二次元配列の値が不正です"
                    }
                }
                # 二次元配列の検証
                $isValid = $true
                foreach ($row in $Value) {
                    if ($row -isnot [array]) {
                        $isValid = $false
                        break
                    }
                }
                if (-not $isValid) {
                    return @{
                        success = $false
                        error = "二次元配列の形式が不正です"
                    }
                }
                $global:variables[$Name] = $Value
            }
        }

        return @{
            success = $true
            message = "変数 '$Name' を追加/更新しました"
            name = $Name
            type = $Type
        }

    } catch {
        return @{
            success = $false
            error = "変数の追加/更新に失敗しました: $($_.Exception.Message)"
        }
    }
}


function Remove-Variable_v2 {
    <#
    .SYNOPSIS
    変数を削除（UI非依存版）

    .PARAMETER Name
    削除する変数名

    .EXAMPLE
    $result = Remove-Variable_v2 -Name "test"
    #>
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    try {
        if (-not $global:variables.ContainsKey($Name)) {
            return @{
                success = $false
                error = "変数 '$Name' が見つかりません"
            }
        }

        $global:variables.Remove($Name)

        return @{
            success = $true
            message = "変数 '$Name' を削除しました"
        }

    } catch {
        return @{
            success = $false
            error = "変数の削除に失敗しました: $($_.Exception.Message)"
        }
    }
}


function Export-VariablesToJson_v2 {
    <#
    .SYNOPSIS
    変数をJSONファイルに出力（UI非依存版）

    .PARAMETER Path
    出力先ファイルパス（省略時は $global:JSONPath を使用）

    .PARAMETER CreateDirectory
    ディレクトリが存在しない場合に作成するか（デフォルト: $true）

    .EXAMPLE
    $result = Export-VariablesToJson_v2
    $result = Export-VariablesToJson_v2 -Path "C:\temp\vars.json"
    #>
    param (
        [string]$Path = $null,
        [bool]$CreateDirectory = $true
    )

    try {
        # パスの決定
        if ([string]::IsNullOrWhiteSpace($Path)) {
            if ([string]::IsNullOrWhiteSpace($global:JSONPath)) {
                return @{
                    success = $false
                    error = "出力先パスが指定されていません（$global:JSONPath も未設定）"
                }
            }
            $Path = $global:JSONPath
        }

        # JSON保存（共通関数使用 - ディレクトリ作成も自動）
        Write-JsonSafe -Path $Path -Data $global:variables -Depth 10 -CreateDirectory $CreateDirectory -Silent $true

        return @{
            success = $true
            message = "変数がJSON形式で保存されました"
            path = $Path
            count = $global:variables.Count
        }

    } catch {
        return @{
            success = $false
            error = "JSONの保存に失敗しました: $($_.Exception.Message)"
        }
    }
}


function Import-VariablesFromJson_v2 {
    <#
    .SYNOPSIS
    JSONファイルから変数を読み込み（UI非依存版）

    .PARAMETER Path
    読み込み元ファイルパス（省略時は $global:JSONPath を使用）

    .PARAMETER Merge
    既存の変数とマージするか（デフォルト: $true）
    $false の場合、既存の変数をすべてクリアしてから読み込みます

    .EXAMPLE
    $result = Import-VariablesFromJson_v2
    $result = Import-VariablesFromJson_v2 -Path "C:\temp\vars.json" -Merge $false
    #>
    param (
        [string]$Path = $null,
        [bool]$Merge = $true
    )

    try {
        # パスの決定
        if ([string]::IsNullOrWhiteSpace($Path)) {
            if ([string]::IsNullOrWhiteSpace($global:JSONPath)) {
                return @{
                    success = $false
                    error = "読み込み元パスが指定されていません（$global:JSONPath も未設定）"
                }
            }
            $Path = $global:JSONPath
        }

        # ファイルの存在確認
        if (-not (Test-Path -Path $Path)) {
            return @{
                success = $false
                error = "JSONファイルが見つかりません: $Path"
            }
        }

        # マージしない場合は既存の変数をクリア
        if (-not $Merge) {
            $global:variables = @{}
        }

        # JSON読み込み（共通関数使用）
        $importedVariables = Read-JsonSafe -Path $Path -Required $true -Silent $false

        # 変数を追加
        $count = 0
        if ($importedVariables -is [System.Collections.IEnumerable] -and -not ($importedVariables -is [string])) {
            # 配列の場合
            foreach ($item in $importedVariables) {
                foreach ($key in $item.PSObject.Properties.Name) {
                    $value = $item.$key
                    Add-VariableToGlobal_v2 $key $value
                    $count++
                }
            }
        } else {
            # オブジェクトの場合
            foreach ($key in $importedVariables.PSObject.Properties.Name) {
                $value = $importedVariables.$key
                Add-VariableToGlobal_v2 $key $value
                $count++
            }
        }

        return @{
            success = $true
            message = "JSONファイルを読み込みました"
            path = $Path
            count = $count
        }

    } catch {
        return @{
            success = $false
            error = "JSONの読み込みに失敗しました: $($_.Exception.Message)"
        }
    }
}


# ============================================
# 内部ヘルパー関数
# ============================================

function Add-VariableToGlobal_v2 {
    <#
    .SYNOPSIS
    変数をグローバル変数辞書に追加する内部関数

    .PARAMETER key
    変数名

    .PARAMETER value
    変数の値
    #>
    param($key, $value)

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


# ============================================
# 既存の関数（Windows Forms版 - 後方互換性維持）
# ============================================

function Show-VariableManagerForm {
    <#
    .SYNOPSIS
    変数管理UIダイアログを表示（Windows Forms版）

    .DESCRIPTION
    この関数は既存のWindows Forms版との互換性維持のために残されています。
    HTML/JS版では使用しません。

    .PARAMETER showUI
    UIを表示するかどうか（デフォルト: $true）
    $false の場合、v2関数群を使用することを推奨します。

    .EXAMPLE
    # Windows Forms版
    $selectedVar = Show-VariableManagerForm

    # HTML/JS版（REST API経由）
    # Show-VariableManagerForm は使用せず、v2関数群を使用
    #>
    param (
        [bool]$showUI = $true
    )

    # UI非表示の場合は、変数一覧をJSON形式で返す
    if (-not $showUI) {
        return Get-VariableList_v2
    }

    # ===== 以下、既存のWindows Formsコード（元のファイルと同じ） =====

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

    # イベント: 追加/更新（v2関数を使用）
    $btnAddUpdate.add_Click({
        $name = $txtName.Text.Trim()
        $type = $cmbType.SelectedItem

        if ($type -eq "単一値") {
            $value = $txtValue.Text.Trim()
        } elseif ($type -eq "一次元") {
            $value = $txtValue.Text -split ','
        } elseif ($type -eq "二次元") {
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
            $value = $array
        } else {
            Show-WarningDialog "データ型を選択してください"
            return
        }

        # v2関数を使用
        $result = Add-Variable_v2 -Name $name -Value $value -Type $type

        if ($result.success) {
            Refresh-VariableList | Out-Null
            $txtName.Clear()
            $txtValue.Clear()
            $gridView.Rows.Clear()
            $gridView.Columns.Clear()
        } else {
            Show-ErrorDialog $result.error
        }
    })

    # イベント: 削除（v2関数を使用）
    $btnDelete.add_Click({
        $selectedItem = $lstVariables.SelectedItem
        if ($null -eq $selectedItem) {
            Show-WarningDialog "削除する変数を選択してください"
            return
        }

        $keyToDelete = $selectedItem.Split("=")[0].Trim()

        # v2関数を使用
        $result = Remove-Variable_v2 -Name $keyToDelete

        if ($result.success) {
            Refresh-VariableList | Out-Null
            Show-InfoDialog $result.message
        } else {
            Show-ErrorDialog $result.error
        }
    })

    # イベント: JSON出力（v2関数を使用）
    $btnExportJson.add_Click({
        $result = Export-VariablesToJson_v2

        if ($result.success) {
            Show-InfoDialog "$($result.message)`n$($result.path)"
        } else {
            Show-ErrorDialog $result.error
        }
    })

    # イベント: JSON読み込み（v2関数を使用）
    $btnImportJson.add_Click({
        $result = Import-VariablesFromJson_v2

        if ($result.success) {
            Refresh-VariableList | Out-Null
            [System.Windows.Forms.MessageBox]::Show("$($result.message)`n$($result.path)") | Out-Null
        } else {
            [System.Windows.Forms.MessageBox]::Show($result.error) | Out-Null
        }
    })

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
        $result = Import-VariablesFromJson_v2

        if (-not $result.success -and $result.error -notlike "*見つかりません*") {
            [System.Windows.Forms.MessageBox]::Show($result.error) | Out-Null
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
        return $selectedVariable
    } else {
        return $null
    }
}
