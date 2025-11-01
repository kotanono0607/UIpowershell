function ShowLoopBuilder {
    param(
        [string]$JSONPath = $global:JSONPath  # 変数リストを格納したJSONファイルのパス
    )

    # 単一値の変数名リストを取得
    $variablesList = Get-SingleValueVariableNames -JSONPath $JSONPath
    # 配列変数のリストを取得
    $arrayVariablesList = Get-ArrayVariableNames -JSONPath $JSONPath

    # 変数リストが空の場合は空の配列を使用（情報表示のみ）
    if ($variablesList.Count -eq 0) {
        Write-Host "情報: 単一値変数が未登録です。固定値のみ使用可能です。変数を使いたい場合は、先に変数を登録してください。" -ForegroundColor Cyan
        $variablesList = @()  # 空の配列を設定
    }

    # 配列変数リストが空の場合も空配列を設定
    if ($null -eq $arrayVariablesList -or $arrayVariablesList.Count -eq 0) {
        $arrayVariablesList = @()
    }

    Add-Type -AssemblyName System.Windows.Forms

    # 保存時にループ構文プレビューの値を返すための変数
    $script:loopResult = $null

    # フォーム作成
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "ループ構文の設定"
    $form.Size = New-Object System.Drawing.Size(700, 600)
    $form.StartPosition = "CenterScreen"

    # ループタイプの選択
    $lblLoopType = New-Object System.Windows.Forms.Label
    $lblLoopType.Text = "ループの種類を選択してください:"
    $lblLoopType.Location = New-Object System.Drawing.Point(20, 20)
    $lblLoopType.AutoSize = $true
    $form.Controls.Add($lblLoopType)

    $cmbLoopType = New-Object System.Windows.Forms.ComboBox
    $cmbLoopType.Location = New-Object System.Drawing.Point(20, 50)
    $cmbLoopType.Size = New-Object System.Drawing.Size(200, 20)
    $cmbLoopType.DropDownStyle = "DropDownList"
    $cmbLoopType.Items.Add("固定回数ループ") | Out-Null
    $cmbLoopType.Items.Add("コレクションのループ") | Out-Null
    $cmbLoopType.Items.Add("条件付きループ") | Out-Null
    $form.Controls.Add($cmbLoopType)

    # 設定パネル
    $panelSettings = New-Object System.Windows.Forms.Panel
    $panelSettings.Location = New-Object System.Drawing.Point(20, 90)
    $panelSettings.Size = New-Object System.Drawing.Size(550, 250)
    $form.Controls.Add($panelSettings)

    # ループ構文プレビューセクション
    $lblPreview = New-Object System.Windows.Forms.Label
    $lblPreview.Text = "ループ構文プレビュー:"
    $lblPreview.Location = New-Object System.Drawing.Point(20, 360)
    $lblPreview.AutoSize = $true
    $form.Controls.Add($lblPreview)

    $txtPreview = New-Object System.Windows.Forms.TextBox
    $txtPreview.Location = New-Object System.Drawing.Point(20, 390)
    $txtPreview.Size = New-Object System.Drawing.Size(550, 60)
    $txtPreview.Multiline = $true
    $txtPreview.ScrollBars = "Vertical"
    $form.Controls.Add($txtPreview)

    # 保存/キャンセルボタン
    $btnSave = New-Object System.Windows.Forms.Button
    $btnSave.Text = "保存"
    $btnSave.Size = New-Object System.Drawing.Size(80, 30)
    $btnSave.Location = New-Object System.Drawing.Point(390, 460)
    $form.Controls.Add($btnSave)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "キャンセル"
    $btnCancel.Size = New-Object System.Drawing.Size(80, 30)
    $btnCancel.Location = New-Object System.Drawing.Point(490, 460)
    $form.Controls.Add($btnCancel)

    # 各種コントロール（後で動的に追加）
    $controls = @{}

    # イベントハンドラのコードを関数化
    function UpdateLoopTypeControls {
        $panelSettings.Controls.Clear()
        $controls.Clear()
        #UpdateLoopPreview

        switch ($cmbLoopType.SelectedItem) {
            "固定回数ループ" {
                # カウンタ変数名の入力
                $lblCounterVar = New-Object System.Windows.Forms.Label
                $lblCounterVar.Text = "カウンタ変数名:"
                $lblCounterVar.Location = New-Object System.Drawing.Point(0, 0)
                $lblCounterVar.AutoSize = $true
                $panelSettings.Controls.Add($lblCounterVar)

                $txtCounterVar = New-Object System.Windows.Forms.TextBox
                $txtCounterVar.Location = New-Object System.Drawing.Point(120, 0)
                $txtCounterVar.Size = New-Object System.Drawing.Size(200, 20)
                $txtCounterVar.Text = '$i'
                $panelSettings.Controls.Add($txtCounterVar)
                $controls.CounterVar = $txtCounterVar

                # 開始値ラベル
                $lblStartValue = New-Object System.Windows.Forms.Label
                $lblStartValue.Text = "開始値:"
                $lblStartValue.Location = New-Object System.Drawing.Point(0, 30)
                $lblStartValue.AutoSize = $true
                $panelSettings.Controls.Add($lblStartValue)

                # 開始値の入力（テキストボックス）
                $txtStartValue = New-Object System.Windows.Forms.TextBox
                $txtStartValue.Location = New-Object System.Drawing.Point(120, 30)
                $txtStartValue.Size = New-Object System.Drawing.Size(200, 20)
                $txtStartValue.Text = '0'
                $panelSettings.Controls.Add($txtStartValue)
                $controls.StartValue = $txtStartValue

                # 開始値の「変数を使用」チェックボックス
                $chkStartVar = New-Object System.Windows.Forms.CheckBox
                $chkStartVar.Text = "変数を使用"
                $chkStartVar.Location = New-Object System.Drawing.Point(330, 30)
                $chkStartVar.AutoSize = $true
                $panelSettings.Controls.Add($chkStartVar)
                $controls.UseStartVar = $chkStartVar

                # 開始値の選択（コンボボックス）
                $cmbStartVar = New-Object System.Windows.Forms.ComboBox
                $cmbStartVar.Location = New-Object System.Drawing.Point(120, 30)
                $cmbStartVar.Size = New-Object System.Drawing.Size(200, 20)
                $cmbStartVar.Items.AddRange($variablesList)
                $cmbStartVar.Visible = $false
                $panelSettings.Controls.Add($cmbStartVar)
                $controls.StartVar = $cmbStartVar

                # 終了値ラベル
                $lblEndValue = New-Object System.Windows.Forms.Label
                $lblEndValue.Text = "終了値:"
                $lblEndValue.Location = New-Object System.Drawing.Point(0, 60)
                $lblEndValue.AutoSize = $true
                $panelSettings.Controls.Add($lblEndValue)

                # 終了値の入力（テキストボックス）
                $txtEndValue = New-Object System.Windows.Forms.TextBox
                $txtEndValue.Location = New-Object System.Drawing.Point(120, 60)
                $txtEndValue.Size = New-Object System.Drawing.Size(200, 20)
                $panelSettings.Controls.Add($txtEndValue)
                $controls.EndValue = $txtEndValue

                # 終了値の「変数を使用」チェックボックス
                $chkEndVar = New-Object System.Windows.Forms.CheckBox
                $chkEndVar.Text = "変数を使用"
                $chkEndVar.Location = New-Object System.Drawing.Point(330, 60)
                $chkEndVar.AutoSize = $true
                $panelSettings.Controls.Add($chkEndVar)
                $controls.UseEndVar = $chkEndVar

                # 終了値の選択（コンボボックス）
                $cmbEndVar = New-Object System.Windows.Forms.ComboBox
                $cmbEndVar.Location = New-Object System.Drawing.Point(120, 60)
                $cmbEndVar.Size = New-Object System.Drawing.Size(200, 20)
                $cmbEndVar.Items.AddRange($variablesList)
                $cmbEndVar.Visible = $false
                $panelSettings.Controls.Add($cmbEndVar)
                $controls.EndVar = $cmbEndVar

                # 増分値の入力
                $lblIncrement = New-Object System.Windows.Forms.Label
                $lblIncrement.Text = "増分値:"
                $lblIncrement.Location = New-Object System.Drawing.Point(0, 90)
                $lblIncrement.AutoSize = $true
                $panelSettings.Controls.Add($lblIncrement)

                $txtIncrement = New-Object System.Windows.Forms.TextBox
                $txtIncrement.Location = New-Object System.Drawing.Point(120, 90)
                $txtIncrement.Size = New-Object System.Drawing.Size(200, 20)
                $txtIncrement.Text = '1'
                $panelSettings.Controls.Add($txtIncrement)
                $controls.Increment = $txtIncrement

                # イベントハンドラ
                $txtCounterVar.Add_TextChanged({ UpdateLoopPreview })
                $txtStartValue.Add_TextChanged({ UpdateLoopPreview })
                $txtEndValue.Add_TextChanged({ UpdateLoopPreview })
                $txtIncrement.Add_TextChanged({ UpdateLoopPreview })
                $chkStartVar.Add_CheckedChanged({
                    if ($controls.UseStartVar.Checked) {
                        $controls.StartValue.Visible = $false
                        $controls.StartVar.Visible = $true
                    } else {
                        $controls.StartValue.Visible = $true
                        $controls.StartVar.Visible = $false
                    }
                    UpdateLoopPreview
                })
                $chkEndVar.Add_CheckedChanged({
                    if ($controls.UseEndVar.Checked) {
                        $controls.EndValue.Visible = $false
                        $controls.EndVar.Visible = $true
                    } else {
                        $controls.EndValue.Visible = $true
                        $controls.EndVar.Visible = $false
                    }
                    UpdateLoopPreview
                })
                $cmbStartVar.Add_SelectedIndexChanged({ UpdateLoopPreview })
                $cmbEndVar.Add_SelectedIndexChanged({ UpdateLoopPreview })
                $txtIncrement.Add_TextChanged({ UpdateLoopPreview })
            }

            "コレクションのループ" {
                # 要素変数名の入力
                $lblElementVar = New-Object System.Windows.Forms.Label
                $lblElementVar.Text = "要素変数名:"
                $lblElementVar.Location = New-Object System.Drawing.Point(0, 0)
                $lblElementVar.AutoSize = $true
                $panelSettings.Controls.Add($lblElementVar)

                $txtElementVar = New-Object System.Windows.Forms.TextBox
                $txtElementVar.Location = New-Object System.Drawing.Point(120, 0)
                $txtElementVar.Size = New-Object System.Drawing.Size(200, 20)
                $txtElementVar.Text = '$item'
                $panelSettings.Controls.Add($txtElementVar)
                $controls.ElementVar = $txtElementVar

                # コレクション変数の選択
                $lblCollectionVar = New-Object System.Windows.Forms.Label
                $lblCollectionVar.Text = "コレクション変数:"
                $lblCollectionVar.Location = New-Object System.Drawing.Point(0, 30)
                $lblCollectionVar.AutoSize = $true
                $panelSettings.Controls.Add($lblCollectionVar)

                $cmbCollectionVar = New-Object System.Windows.Forms.ComboBox
                $cmbCollectionVar.Location = New-Object System.Drawing.Point(120, 30)
                $cmbCollectionVar.Size = New-Object System.Drawing.Size(200, 20)
                $cmbCollectionVar.Items.AddRange($arrayVariablesList)
                $panelSettings.Controls.Add($cmbCollectionVar)
                $controls.CollectionVar = $cmbCollectionVar

                # イベントハンドラ
                $txtElementVar.Add_TextChanged({ UpdateLoopPreview })
                $cmbCollectionVar.Add_SelectedIndexChanged({ UpdateLoopPreview })
            }

            "条件付きループ" {
                # ループの種類の選択
                $lblConditionType = New-Object System.Windows.Forms.Label
                $lblConditionType.Text = "ループの種類:"
                $lblConditionType.Location = New-Object System.Drawing.Point(0, 0)
                $lblConditionType.AutoSize = $true
                $panelSettings.Controls.Add($lblConditionType)

                $cmbConditionType = New-Object System.Windows.Forms.ComboBox
                $cmbConditionType.Location = New-Object System.Drawing.Point(120, 0)
                $cmbConditionType.Size = New-Object System.Drawing.Size(200, 20)
                $cmbConditionType.DropDownStyle = "DropDownList"
                $cmbConditionType.Items.Add("while") | Out-Null
                $cmbConditionType.Items.Add("do-while") | Out-Null
                $panelSettings.Controls.Add($cmbConditionType)
                $controls.ConditionType = $cmbConditionType

                # 条件式設定ボタン
                $btnSetCondition = New-Object System.Windows.Forms.Button
                $btnSetCondition.Text = "条件式を設定"
                $btnSetCondition.Location = New-Object System.Drawing.Point(0, 40)
                $btnSetCondition.Size = New-Object System.Drawing.Size(100, 30)
                $panelSettings.Controls.Add($btnSetCondition)

                $lblConditionPreview = New-Object System.Windows.Forms.Label
                $lblConditionPreview.Text = "条件式: （未設定）"
                $lblConditionPreview.Location = New-Object System.Drawing.Point(120, 40)
                $lblConditionPreview.AutoSize = $true
                $panelSettings.Controls.Add($lblConditionPreview)
                $controls.ConditionPreview = $lblConditionPreview

                $script:loopCondition = ""

                # 条件式設定ボタンのイベント
                $btnSetCondition.Add_Click({
                    $condition = ShowConditionBuilder -JSONPath $JSONPath -IsFromLoopBuilder
                    if ($condition -ne $null) {
                        $script:loopCondition = $condition
                        $controls.ConditionPreview.Text = "条件式: $condition"
                        UpdateLoopPreview
                    }
                })

                # イベントハンドラ
                $cmbConditionType.Add_SelectedIndexChanged({ UpdateLoopPreview })
            }
        }
    }

    # ループタイプ選択時のイベント
    $cmbLoopType.add_SelectedIndexChanged({
        UpdateLoopTypeControls
    })

    # 初期選択を設定
    $cmbLoopType.SelectedIndex = 0  # 0は最初のアイテム（固定回数ループ）

    # 初期表示のために、コントロールを更新
    UpdateLoopTypeControls

    # プレビューを更新する関数
    function UpdateLoopPreview {
        $loopCode = ""

        switch ($cmbLoopType.SelectedItem) {
            "固定回数ループ" {
                $counterVar = $controls.CounterVar.Text

                # 開始値
                if ($controls.UseStartVar.Checked) {
                    $startValue = $controls.StartVar.SelectedItem
                } else {
                    $startValue = $controls.StartValue.Text
                }

                # 終了値
                if ($controls.UseEndVar.Checked) {
                    $endValue = $controls.EndVar.SelectedItem
                } else {
                    $endValue = $controls.EndValue.Text
                }

                $increment = $controls.Increment.Text

                if ([string]::IsNullOrWhiteSpace($counterVar) -or [string]::IsNullOrWhiteSpace($startValue) -or [string]::IsNullOrWhiteSpace($endValue) -or [string]::IsNullOrWhiteSpace($increment)) {
                    $txtPreview.Text = ""
                    return
                }

                $loopCode = "for ($counterVar = $startValue; $counterVar -lt $endValue; $counterVar += $increment) {
    # 処理内容
}"
            }

            "コレクションのループ" {
                $elementVar = $controls.ElementVar.Text
                $collectionVar = $controls.CollectionVar.SelectedItem

                if ([string]::IsNullOrWhiteSpace($elementVar) -or [string]::IsNullOrWhiteSpace($collectionVar)) {
                    $txtPreview.Text = ""
                    return
                }

                $loopCode = "foreach ($elementVar in $collectionVar) {
    # 処理内容
}"
            }

            "条件付きループ" {
                $conditionType = $controls.ConditionType.SelectedItem
                $condition = $script:loopCondition

                if ([string]::IsNullOrWhiteSpace($conditionType) -or [string]::IsNullOrWhiteSpace($condition)) {
                    $txtPreview.Text = ""
                    return
                }

                if ($conditionType -eq "while") {
                    $loopCode = "while ($condition) {
    # 処理内容
}"
                } elseif ($conditionType -eq "do-while") {
                    $loopCode = "do {
    # 処理内容
} while ($condition)"
                }
            }
        }

        $txtPreview.Text = $loopCode
    }

    # 閉じるイベント
    $btnCancel.Add_Click({
        $script:loopResult = $null  # キャンセル時は $null を設定
        $form.Close()
    })

    # 「保存」ボタンのクリックイベント
    $btnSave.Add_Click({
        # 各行を処理し、#で始まる行を---に置換
        $script:loopResult  = $txtPreview.Text -split "`n" | ForEach-Object {
            if ($_ -match '^\s*#') {
                # 置換
                '---'
            } else {
                # そのまま保持
                $_
            }
        } | Out-String

        $form.Close()
    })

    # フォームを表示（戻り値を無視）
    $null = $form.ShowDialog()

    # 関数の返り値としてループ構文プレビューの値を返す
    return $script:loopResult
}

# 配列変数のリストを取得する関数
function Get-ArrayVariableNames {
    param(
        [string]$JSONPath = $global:JSONPath # JSONファイルのパスを指定
    )
    if (-not (Test-Path -Path $JSONPath)) {
        #Write-Host "JSONファイルが見つかりません: $JSONPath"
        return @()  # 空の配列を返す
    }

    try {
        # JSON読み込み（共通関数使用）
        $importedVariables = Read-JsonSafe -Path $JSONPath -Required $true -Silent $false

        $arrayVariableNames = @()

        # JSONデータがハッシュテーブル（オブジェクト）である場合
        if ($importedVariables -is [hashtable] -or $importedVariables -is [PSCustomObject]) {
            foreach ($key in $importedVariables.PSObject.Properties.Name) {
                $value = $importedVariables.$key
                if ($value -is [System.Array]) {
                    # 配列の場合
                    $variableName = '$' + $key
                    $arrayVariableNames += $variableName
                }
            }
        } else {
            # JSONデータが配列である場合
            foreach ($item in $importedVariables) {
                if ($item -is [hashtable] -or $item -is [PSCustomObject]) {
                    foreach ($key in $item.PSObject.Properties.Name) {
                        $value = $item.$key
                        if ($value -is [System.Array]) {
                            # 配列の場合
                            $variableName = '$' + $key
                            $arrayVariableNames += $variableName
                        }
                    }
                }
            }
        }

        return $arrayVariableNames
    } catch {
        #Write-Host "JSONの読み込みに失敗しました: $_"
        return @()  # エラー時は空の配列を返す
    }
}




function ShowConditionBuilder {
    param(
        [string]$JSONPath = $global:JSONPath,  # 変数リストを格納したJSONファイルのパス
        [switch]$IsFromLoopBuilder  # ループビルダーからの呼び出しかどうか
    )

    # 単一値の変数名リストを取得
    $variablesList = Get-SingleValueVariableNames -JSONPath $JSONPath

    # 変数リストが空の場合は空の配列を使用（情報表示のみ）
    if ($variablesList.Count -eq 0) {
        Write-Host "情報: 変数が未登録です。固定値の比較のみ可能です。変数を使いたい場合は、先に変数を登録してください。" -ForegroundColor Cyan
        $variablesList = @()  # 空の配列を設定
    }

    Add-Type -AssemblyName System.Windows.Forms

    # 変数リストをスクリプトスコープに設定
    $script:variablesList = $variablesList

    # 保存時に条件式プレビューの値を返すための変数
    $script:conditionResult = $null

    # フォーム作成
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "条件式の設定"
    $form.Size = New-Object System.Drawing.Size(1000, 800)
    $form.StartPosition = "CenterScreen"

    # 条件項目セクション
    $groupBoxConditionItem = New-Object System.Windows.Forms.GroupBox
    $groupBoxConditionItem.Text = "条件項目"
    $groupBoxConditionItem.Size = New-Object System.Drawing.Size(800, 450)
    $groupBoxConditionItem.Location = New-Object System.Drawing.Point(10, 10)
    $form.Controls.Add($groupBoxConditionItem)

    # 条件入力フィールドを追加するパネル
    $script:panelConditions = New-Object System.Windows.Forms.Panel
    $script:panelConditions.AutoScroll = $true
    $script:panelConditions.Size = New-Object System.Drawing.Size(730, 400)
    $script:panelConditions.Location = New-Object System.Drawing.Point(10, 20)
    $groupBoxConditionItem.Controls.Add($script:panelConditions)

    # 条件追加ボタン
    $btnAddCondition = New-Object System.Windows.Forms.Button
    $btnAddCondition.Text = "条件追加"
    $btnAddCondition.Size = New-Object System.Drawing.Size(120, 30)
    $btnAddCondition.Location = New-Object System.Drawing.Point(10, 470)
    $form.Controls.Add($btnAddCondition)

    # 条件式プレビューセクション
    $labelPreview = New-Object System.Windows.Forms.Label
    $labelPreview.Text = "条件式プレビュー:"
    $labelPreview.AutoSize = $true
    $labelPreview.Location = New-Object System.Drawing.Point(10, 510)
    $form.Controls.Add($labelPreview)

    $script:textBoxPreview = New-Object System.Windows.Forms.TextBox
    $script:textBoxPreview.Size = New-Object System.Drawing.Size(950, 70)
    $script:textBoxPreview.Location = New-Object System.Drawing.Point(10, 540)
    $script:textBoxPreview.Multiline = $true
    $script:textBoxPreview.ScrollBars = "Vertical"
    $form.Controls.Add($script:textBoxPreview)

    # 保存/キャンセルボタン
    $btnSave = New-Object System.Windows.Forms.Button
    $btnSave.Text = "保存"
    $btnSave.Size = New-Object System.Drawing.Size(100, 30)
    $btnSave.Location = New-Object System.Drawing.Point(770, 620)
    $form.Controls.Add($btnSave)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "キャンセル"
    $btnCancel.Size = New-Object System.Drawing.Size(100, 30)
    $btnCancel.Location = New-Object System.Drawing.Point(880, 620)
    $form.Controls.Add($btnCancel)

    # 閉じるイベント
    $btnCancel.Add_Click({ 
        $script:conditionResult = $null  # キャンセル時は $null を設定
        $form.Close() 
    })

    # 「保存」ボタンのクリックイベント
    $btnSave.Add_Click({
        #$script:conditionResult = $script:textBoxPreview.Text

                # 各行を処理し、#で始まる行を---に置換
            $script:conditionResult  = $script:textBoxPreview.Text -split "`n" | ForEach-Object {
                if ($_ -match '^\s*#') {
                    # 置換
                    '---'
                } else {
                    # そのまま保持
                    $_
                }
            } | Out-String


        $form.Close()
    })

    # 条件コントロールを保持するリスト
    $script:conditionControls = @()

    # 条件追加の処理を関数化
    function AddCondition {
        # スクリプトスコープの変数を参照
        $index = $script:conditionControls.Count
        $yPosition = $index * 90  # 行の高さを増やす

        # デバッグ用
        # #Write-Host "Index: $index"
        # #Write-Host "Y Position: $yPosition"

        # 条件連結（2行目以降）
        if ($index -ge 1) {
            $comboBoxLogicalOperator = New-Object System.Windows.Forms.ComboBox
            $comboBoxLogicalOperator.Size = New-Object System.Drawing.Size(60, 20)
            $comboBoxLogicalOperator.Location = [System.Drawing.Point]::new(0, $yPosition + 30)
            $comboBoxLogicalOperator.Items.AddRange(@("-and", "-or"))
            $script:panelConditions.Controls.Add($comboBoxLogicalOperator)
        } else {
            $comboBoxLogicalOperator = $null
        }

        # 左辺グループ
        $groupLeftOption = New-Object System.Windows.Forms.GroupBox
        $groupLeftOption.Text = "左辺"
        $groupLeftOption.Size = New-Object System.Drawing.Size(280, 80)
        $groupLeftOption.Location = [System.Drawing.Point]::new(70, $yPosition)
        $script:panelConditions.Controls.Add($groupLeftOption)

        # 左辺の「変数を使用」チェックボックス
        $checkBoxLeftVariable = New-Object System.Windows.Forms.CheckBox
        $checkBoxLeftVariable.Text = "変数を使用"
        $checkBoxLeftVariable.Location = [System.Drawing.Point]::new(10, 15)
        $groupLeftOption.Controls.Add($checkBoxLeftVariable)
        $checkBoxLeftVariable.Checked = $false  # 初期状態はチェックなし

        # 左辺変数選択コンボボックス
        $comboBoxLeftVariable = New-Object System.Windows.Forms.ComboBox
        $comboBoxLeftVariable.Size = New-Object System.Drawing.Size(250, 20)
        $comboBoxLeftVariable.Location = [System.Drawing.Point]::new(10, 40)
        $comboBoxLeftVariable.Items.AddRange($script:variablesList)
        $groupLeftOption.Controls.Add($comboBoxLeftVariable)
        $comboBoxLeftVariable.Visible = $false  # 初期状態は非表示

        # 左辺直接入力テキストボックス
        $textBoxLeftValue = New-Object System.Windows.Forms.TextBox
        $textBoxLeftValue.Size = New-Object System.Drawing.Size(250, 20)
        $textBoxLeftValue.Location = [System.Drawing.Point]::new(10, 40)
        $groupLeftOption.Controls.Add($textBoxLeftValue)
        $textBoxLeftValue.Visible = $true  # 初期状態は表示

        # 演算子
        $comboBoxOperator = New-Object System.Windows.Forms.ComboBox
        $comboBoxOperator.Size = New-Object System.Drawing.Size(80, 20)
        $comboBoxOperator.Location = [System.Drawing.Point]::new(360, $yPosition + 30)
        $comboBoxOperator.Items.AddRange(@("-eq", "-ne", "-lt", "-gt", "-like", "-notlike"))
        $script:panelConditions.Controls.Add($comboBoxOperator)

        # 右辺グループ
        $groupRightOption = New-Object System.Windows.Forms.GroupBox
        $groupRightOption.Text = "右辺"
        $groupRightOption.Size = New-Object System.Drawing.Size(280, 80)
        $groupRightOption.Location = [System.Drawing.Point]::new(450, $yPosition)
        $script:panelConditions.Controls.Add($groupRightOption)

        # 右辺の「変数を使用」チェックボックス
        $checkBoxRightVariable = New-Object System.Windows.Forms.CheckBox
        $checkBoxRightVariable.Text = "変数を使用"
        $checkBoxRightVariable.Location = [System.Drawing.Point]::new(10, 15)
        $groupRightOption.Controls.Add($checkBoxRightVariable)
        $checkBoxRightVariable.Checked = $false  # 初期状態はチェックなし

        # 右辺変数選択コンボボックス
        $comboBoxRightVariable = New-Object System.Windows.Forms.ComboBox
        $comboBoxRightVariable.Size = New-Object System.Drawing.Size(250, 20)
        $comboBoxRightVariable.Location = [System.Drawing.Point]::new(10, 40)
        $comboBoxRightVariable.Items.AddRange($script:variablesList)
        $groupRightOption.Controls.Add($comboBoxRightVariable)
        $comboBoxRightVariable.Visible = $false  # 初期状態は非表示

        # 右辺直接入力テキストボックス
        $textBoxRightValue = New-Object System.Windows.Forms.TextBox
        $textBoxRightValue.Size = New-Object System.Drawing.Size(250, 20)
        $textBoxRightValue.Location = [System.Drawing.Point]::new(10, 40)
        $groupRightOption.Controls.Add($textBoxRightValue)
        $textBoxRightValue.Visible = $true  # 初期状態は表示

        # 条件削除ボタン
        $btnDeleteCondition = New-Object System.Windows.Forms.Button
        $btnDeleteCondition.Text = "削除"
        $btnDeleteCondition.Size = New-Object System.Drawing.Size(50, 20)
        $btnDeleteCondition.Location = [System.Drawing.Point]::new(10, $yPosition + 60)
        $script:panelConditions.Controls.Add($btnDeleteCondition)

        # コントロール情報をリストに追加
        $controlSet = [pscustomobject]@{
            LogicalOperatorControl = $comboBoxLogicalOperator
            LeftVariableCheckBox = $checkBoxLeftVariable
            LeftVariableControl = $comboBoxLeftVariable
            LeftValueControl = $textBoxLeftValue
            OperatorControl = $comboBoxOperator
            RightVariableCheckBox = $checkBoxRightVariable
            RightVariableControl = $comboBoxRightVariable
            RightValueControl = $textBoxRightValue
            DeleteButton = $btnDeleteCondition
        }

        # 各コントロールのTagプロパティにコントロールセットを格納
        $checkBoxLeftVariable.Tag = $controlSet
        $checkBoxRightVariable.Tag = $controlSet
        $btnDeleteCondition.Tag = $controlSet

        # 入力コントロールのTagプロパティにも格納（必要に応じて）
        $comboBoxLeftVariable.Tag = $controlSet
        $textBoxLeftValue.Tag = $controlSet
        $comboBoxOperator.Tag = $controlSet
        $comboBoxRightVariable.Tag = $controlSet
        $textBoxRightValue.Tag = $controlSet
        if ($comboBoxLogicalOperator -ne $null) {
            $comboBoxLogicalOperator.Tag = $controlSet
        }

        # コントロールリストに追加
        $script:conditionControls += $controlSet

        # 左辺のチェックボックスのイベント
        $checkBoxLeftVariable.Add_CheckedChanged({
            param($sender, $e)
            $controlSet = $sender.Tag
            if ($controlSet -ne $null) {
                if ($sender.Checked) {
                    $controlSet.LeftVariableControl.Visible = $true
                    $controlSet.LeftValueControl.Visible = $false
                } else {
                    $controlSet.LeftVariableControl.Visible = $false
                    $controlSet.LeftValueControl.Visible = $true
                }
                UpdateConditionPreview
            }
        })

        # 右辺のチェックボックスのイベント
        $checkBoxRightVariable.Add_CheckedChanged({
            param($sender, $e)
            $controlSet = $sender.Tag
            if ($controlSet -ne $null) {
                if ($sender.Checked) {
                    $controlSet.RightVariableControl.Visible = $true
                    $controlSet.RightValueControl.Visible = $false
                } else {
                    $controlSet.RightVariableControl.Visible = $false
                    $controlSet.RightValueControl.Visible = $true
                }
                UpdateConditionPreview
            }
        })

        # 入力フィールドが変更されたときにプレビューを更新
        $comboBoxLeftVariable.Add_SelectedIndexChanged({
            UpdateConditionPreview
        })
        $textBoxLeftValue.Add_TextChanged({
            UpdateConditionPreview
        })
        $comboBoxOperator.Add_SelectedIndexChanged({
            UpdateConditionPreview
        })
        $comboBoxRightVariable.Add_SelectedIndexChanged({
            UpdateConditionPreview
        })
        $textBoxRightValue.Add_TextChanged({
            UpdateConditionPreview
        })
        if ($comboBoxLogicalOperator -ne $null) {
            $comboBoxLogicalOperator.Add_SelectedIndexChanged({
                UpdateConditionPreview
            })
        }

        # 削除ボタンのクリックイベント
        $btnDeleteCondition.Add_Click({
            param($sender, $e)
            $controlSet = $sender.Tag
            if ($controlSet -ne $null) {
                # 条件行が一つだけの場合は削除しない
                if ($script:conditionControls.Count -le 1) {
                    [System.Windows.Forms.MessageBox]::Show("これ以上削除できません。最低一つの条件が必要です。", "警告", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                    return
                }

                # コントロールを削除
                $script:panelConditions.Controls.Remove($controlSet.LogicalOperatorControl)
                $script:panelConditions.Controls.Remove($controlSet.LeftVariableCheckBox.Parent)
                $script:panelConditions.Controls.Remove($controlSet.OperatorControl)
                $script:panelConditions.Controls.Remove($controlSet.RightVariableCheckBox.Parent)
                $script:panelConditions.Controls.Remove($controlSet.DeleteButton)

                # リストから削除
                $script:conditionControls = $script:conditionControls | Where-Object { $_.DeleteButton -ne $controlSet.DeleteButton }

                # 再配置
                $index = 0
                foreach ($controlSet in $script:conditionControls) {
                    $yPos = $index * 90  # 行の高さを増やす
                    if ($index -ge 1) {
                        $controlSet.LogicalOperatorControl.Location = [System.Drawing.Point]::new(0, $yPos + 30)
                    }
                    $controlSet.LeftVariableCheckBox.Parent.Location = [System.Drawing.Point]::new(70, $yPos)
                    $controlSet.OperatorControl.Location = [System.Drawing.Point]::new(360, $yPos + 30)
                    $controlSet.RightVariableCheckBox.Parent.Location = [System.Drawing.Point]::new(450, $yPos)
                    $controlSet.DeleteButton.Location = [System.Drawing.Point]::new(10, $yPos + 60)
                    $index++
                }

                # プレビューを更新
                UpdateConditionPreview
            }
        })

        # プレビューを更新
        UpdateConditionPreview
    }

    # プレビューを更新する関数
    function UpdateConditionPreview {
    $fullCondition = ""
    $i = 0
    foreach ($controlSet in $script:conditionControls) {
        # 左辺の値を取得
        if ($controlSet.LeftVariableCheckBox.Checked) {
            $leftOperand = $controlSet.LeftVariableControl.SelectedItem
        } else {
            $leftOperandValue = $controlSet.LeftValueControl.Text.Trim()
            # 値をダブルクォーテーションで囲む
            $leftOperand = '"' + $leftOperandValue + '"'
        }

        # 右辺の値を取得
        if ($controlSet.RightVariableCheckBox.Checked) {
            $rightOperand = $controlSet.RightVariableControl.SelectedItem
        } else {
            $rightOperandValue = $controlSet.RightValueControl.Text.Trim()
            # 値をダブルクォーテーションで囲む
            $rightOperand = '"' + $rightOperandValue + '"'
        }

        $operator = $controlSet.OperatorControl.SelectedItem

        # 入力チェック
        if ([string]::IsNullOrWhiteSpace($leftOperand) -or [string]::IsNullOrWhiteSpace($operator) -or [string]::IsNullOrWhiteSpace($rightOperand)) {
            continue
        }

        # 条件式の作成
        $condition = "$leftOperand $operator $rightOperand"

        if ($i -eq 0) {
            $fullCondition = $condition
        } else {
            $logicalOperator = $controlSet.LogicalOperatorControl.SelectedItem
            if (![string]::IsNullOrWhiteSpace($logicalOperator)) {
                $fullCondition = "($fullCondition) $logicalOperator ($condition)"
            }
        }
        $i++
    }

        # プレビューの表示を切り替え
        if ($IsFromLoopBuilder) {
            # ループビルダーからの呼び出しの場合は条件式のみを表示
            $script:textBoxPreview.Text = $fullCondition
        } else {
            # それ以外の場合は if-else 構文を表示
            $script:textBoxPreview.Text = "if ($fullCondition) {
    # Trueの処理内容
} else {
    # Falseの処理内容
}"
        }
    }

    # 条件追加ボタンのクリックイベント
    $btnAddCondition.Add_Click({
        AddCondition
    })

    # フォームを表示する前に、最初の条件行を追加
    AddCondition

    # フォームを表示（戻り値を無視）
    $null = $form.ShowDialog()

    # 関数の返り値として条件式プレビューの値を返す
    return $script:conditionResult
}


$スクリプトPath = $PSScriptRoot # 現在のスクリプトのディレクトリを変数に格納
$global:folderPath = 取得-JSON値 -jsonFilePath "$スクリプトPath\個々の履歴\メイン.json" -keyName "フォルダパス"
$global:JSONPath = "$global:folderPath\variables.json"
function Get-SingleValueVariableNames {
    param(
        [string]$JSONPath = $global:JSONPath # JSONファイルのパスを指定
    )
    #Write-Host "JSONPath: $JSONPath"

    if (-not (Test-Path -Path $JSONPath)) {
        #Write-Host "JSONファイルが見つかりません: $JSONPath"
        return @()  # 空の配列を返す
    }

    try {
        # JSON読み込み（共通関数使用）
        $importedVariables = Read-JsonSafe -Path $JSONPath -Required $true -Silent $false
        #Write-Host "importedVariables の型: $($importedVariables.GetType().FullName)"
        #Write-Host "importedVariables の内容:"
        #Write-Host ($importedVariables | ConvertTo-Json -Depth 10)

        $singleValueVariableNames = @()

        # JSONデータがハッシュテーブル（オブジェクト）である場合
        if ($importedVariables -is [hashtable] -or $importedVariables -is [PSCustomObject]) {
            #Write-Host "importedVariables はハッシュテーブルまたは PSCustomObject です。"

            foreach ($key in $importedVariables.PSObject.Properties.Name) {
                #Write-Host "キー: $key"
                $value = $importedVariables.$key
                #Write-Host "値の型: $($value.GetType().FullName)"
                #Write-Host "値: $value"

                if (-not ($value -is [System.Array])) {
                    # 単一値の場合
                    $variableName = '$' + $key  # 修正箇所
                    $singleValueVariableNames += $variableName
                    #Write-Host "単一値として追加: $variableName"
                } else {
                    #Write-Host "配列なので除外: $key"
                }
            }
        } else {
            #Write-Host "importedVariables は配列です。"
            # JSONデータが配列である場合
            foreach ($item in $importedVariables) {
                if ($item -is [hashtable] -or $item -is [PSCustomObject]) {
                    foreach ($key in $item.PSObject.Properties.Name) {
                        #Write-Host "キー: $key"
                        $value = $item.$key
                        #Write-Host "値の型: $($value.GetType().FullName)"
                        #Write-Host "値: $value"

                        if (-not ($value -is [System.Array])) {
                            # 単一値の場合
                            $variableName = '$' + $key  # 修正箇所
                            $singleValueVariableNames += $variableName
                            #Write-Host "単一値として追加: $variableName"
                        } else {
                            #Write-Host "配列なので除外: $key"
                        }
                    }
                }
            }
        }

        #Write-Host "取得された単一値の変数名リスト: $($singleValueVariableNames -join ', ')"

        return $singleValueVariableNames
    } catch {
        #Write-Host "JSONの読み込みに失敗しました: $_"
        return @()  # エラー時は空の配列を返す
    }
}


# 必要な関数を定義（Get-SingleValueVariableNames, Get-ArrayVariableNames, ShowConditionBuilder）

# ループ構文生成パネルを表示
#$loopCode = ShowLoopBuilder


# 関数の使用例
#$conditionExpression = ShowConditionBuilder

##Write-Host "生成された条件式: $conditionExpression"
