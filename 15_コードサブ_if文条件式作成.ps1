function ShowLoopBuilder {
    param(
        [string]$JSONPath  # 変数リストを格納したJSONファイルのパス
    )

    # JSONPathが未指定の場合は、プロジェクトルートから取得
    if (-not $JSONPath) {
        try {
            # API実行時のパス（adapter/api-server-v2.ps1の$script:RootDirを使用）
            if ($script:RootDir) {
                $rootPath = $script:RootDir
            } else {
                # 通常実行時のパス（現在のスクリプトから2階層上がプロジェクトルート）
                $rootPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
            }

            $メインJsonPath = Join-Path $rootPath "03_history\メイン.json"

            if (Test-Path $メインJsonPath) {
                # JSON読み込み（外部関数に依存しない）
                $jsonContent = Get-Content -Path $メインJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
                $folderPath = $jsonContent."フォルダパス"
                $JSONPath = Join-Path $folderPath "variables.json"
            } else {
                Write-Host "[WARNING] メイン.jsonが見つかりません: $メインJsonPath" -ForegroundColor Yellow
                $JSONPath = $null
            }
        } catch {
            Write-Host "[WARNING] JSONPath取得エラー: $_" -ForegroundColor Yellow
            $JSONPath = $null
        }
    }

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
        # プレビューが空の場合はエラーメッセージを表示して保存しない
        if ([string]::IsNullOrWhiteSpace($txtPreview.Text)) {
            [System.Windows.Forms.MessageBox]::Show(
                "ループ構文が生成されていません。`n`n終了値などの必須項目を入力してください。",
                "入力エラー",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }

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
        [string]$JSONPath,  # 変数リストを格納したJSONファイルのパス
        [switch]$IsFromLoopBuilder  # ループビルダーからの呼び出しかどうか
    )

    # JSONPathが未指定の場合は、プロジェクトルートから取得
    if (-not $JSONPath) {
        try {
            # API実行時のパス（adapter/api-server-v2.ps1の$script:RootDirを使用）
            if ($script:RootDir) {
                $rootPath = $script:RootDir
            } else {
                # 通常実行時のパス（現在のスクリプトから2階層上がプロジェクトルート）
                $rootPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
            }

            $メインJsonPath = Join-Path $rootPath "03_history\メイン.json"

            if (Test-Path $メインJsonPath) {
                # JSON読み込み（外部関数に依存しない）
                $jsonContent = Get-Content -Path $メインJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
                $folderPath = $jsonContent."フォルダパス"
                $JSONPath = Join-Path $folderPath "variables.json"
            } else {
                Write-Host "[WARNING] メイン.jsonが見つかりません: $メインJsonPath" -ForegroundColor Yellow
                $JSONPath = $null
            }
        } catch {
            Write-Host "[WARNING] JSONPath取得エラー: $_" -ForegroundColor Yellow
            $JSONPath = $null
        }
    }

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
    # 分岐数を保存する変数
    $script:branchCount = 2

    # フォーム作成
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "条件分岐の設定"
    $form.Size = New-Object System.Drawing.Size(1000, 850)
    $form.StartPosition = "CenterScreen"

    # ============================================
    # 分岐数選択セクション（多重分岐対応）
    # ============================================
    $groupBoxBranchCount = New-Object System.Windows.Forms.GroupBox
    $groupBoxBranchCount.Text = "分岐数の設定"
    $groupBoxBranchCount.Size = New-Object System.Drawing.Size(960, 60)
    $groupBoxBranchCount.Location = New-Object System.Drawing.Point(10, 10)
    $form.Controls.Add($groupBoxBranchCount)

    $lblBranchCount = New-Object System.Windows.Forms.Label
    $lblBranchCount.Text = "分岐数:"
    $lblBranchCount.Location = New-Object System.Drawing.Point(20, 25)
    $lblBranchCount.AutoSize = $true
    $groupBoxBranchCount.Controls.Add($lblBranchCount)

    $cmbBranchCount = New-Object System.Windows.Forms.ComboBox
    $cmbBranchCount.Location = New-Object System.Drawing.Point(80, 22)
    $cmbBranchCount.Size = New-Object System.Drawing.Size(200, 25)
    $cmbBranchCount.DropDownStyle = "DropDownList"
    $cmbBranchCount.Items.Add("2分岐 (If-Else)") | Out-Null
    $cmbBranchCount.Items.Add("3分岐 (If-ElseIf-Else)") | Out-Null
    $cmbBranchCount.Items.Add("4分岐 (If-ElseIf×2-Else)") | Out-Null
    $cmbBranchCount.Items.Add("5分岐 (If-ElseIf×3-Else)") | Out-Null
    $cmbBranchCount.SelectedIndex = 0
    $groupBoxBranchCount.Controls.Add($cmbBranchCount)

    $lblBranchHelp = New-Object System.Windows.Forms.Label
    $lblBranchHelp.Text = "※ 各分岐の条件を下で設定してください"
    $lblBranchHelp.Location = New-Object System.Drawing.Point(300, 25)
    $lblBranchHelp.AutoSize = $true
    $lblBranchHelp.ForeColor = [System.Drawing.Color]::Gray
    $groupBoxBranchCount.Controls.Add($lblBranchHelp)

    # ループビルダーからの呼び出しの場合は分岐数選択を非表示
    if ($IsFromLoopBuilder) {
        $groupBoxBranchCount.Visible = $false
    }

    # ============================================
    # 条件項目セクション（タブコントロール）
    # ============================================
    $tabControl = New-Object System.Windows.Forms.TabControl
    $tabControl.Size = New-Object System.Drawing.Size(960, 500)
    $tabControl.Location = New-Object System.Drawing.Point(10, 80)
    $form.Controls.Add($tabControl)

    # 各分岐の条件コントロールを保持
    $script:branchConditionControls = @{}

    # タブページを作成する関数
    function CreateBranchTab {
        param([int]$branchIndex, [string]$tabTitle)

        $tabPage = New-Object System.Windows.Forms.TabPage
        $tabPage.Text = $tabTitle

        # 条件入力パネル
        $panelConditions = New-Object System.Windows.Forms.Panel
        $panelConditions.AutoScroll = $true
        $panelConditions.Size = New-Object System.Drawing.Size(930, 420)
        $panelConditions.Location = New-Object System.Drawing.Point(5, 5)
        $tabPage.Controls.Add($panelConditions)

        # 条件追加ボタン
        $btnAddCondition = New-Object System.Windows.Forms.Button
        $btnAddCondition.Text = "条件追加"
        $btnAddCondition.Size = New-Object System.Drawing.Size(100, 25)
        $btnAddCondition.Location = New-Object System.Drawing.Point(5, 430)
        $btnAddCondition.Tag = $branchIndex
        $tabPage.Controls.Add($btnAddCondition)

        # コントロール情報を保存
        $script:branchConditionControls[$branchIndex] = @{
            Panel = $panelConditions
            AddButton = $btnAddCondition
            Conditions = @()
        }

        # 条件追加ボタンのイベント
        $btnAddCondition.Add_Click({
            param($sender, $e)
            $idx = $sender.Tag
            AddConditionToBranch -branchIndex $idx
        })

        # 初期条件を追加
        $tabControl.TabPages.Add($tabPage)
        AddConditionToBranch -branchIndex $branchIndex
    }

    # 分岐に条件を追加する関数
    function AddConditionToBranch {
        param([int]$branchIndex)

        $branchData = $script:branchConditionControls[$branchIndex]
        $panel = $branchData.Panel
        $conditions = $branchData.Conditions
        $index = $conditions.Count
        $yPosition = $index * 90

        # 条件連結（2行目以降）
        $comboBoxLogicalOperator = $null
        if ($index -ge 1) {
            $comboBoxLogicalOperator = New-Object System.Windows.Forms.ComboBox
            $comboBoxLogicalOperator.Size = New-Object System.Drawing.Size(60, 20)
            $comboBoxLogicalOperator.Location = [System.Drawing.Point]::new(0, $yPosition + 30)
            $comboBoxLogicalOperator.Items.AddRange(@("-and", "-or"))
            $panel.Controls.Add($comboBoxLogicalOperator)
        }

        # 左辺グループ
        $groupLeftOption = New-Object System.Windows.Forms.GroupBox
        $groupLeftOption.Text = "左辺"
        $groupLeftOption.Size = New-Object System.Drawing.Size(280, 80)
        $groupLeftOption.Location = [System.Drawing.Point]::new(70, $yPosition)
        $panel.Controls.Add($groupLeftOption)

        $checkBoxLeftVariable = New-Object System.Windows.Forms.CheckBox
        $checkBoxLeftVariable.Text = "変数を使用"
        $checkBoxLeftVariable.Location = [System.Drawing.Point]::new(10, 15)
        $groupLeftOption.Controls.Add($checkBoxLeftVariable)

        $comboBoxLeftVariable = New-Object System.Windows.Forms.ComboBox
        $comboBoxLeftVariable.Size = New-Object System.Drawing.Size(250, 20)
        $comboBoxLeftVariable.Location = [System.Drawing.Point]::new(10, 40)
        $comboBoxLeftVariable.Items.AddRange($script:variablesList)
        $comboBoxLeftVariable.Visible = $false
        $groupLeftOption.Controls.Add($comboBoxLeftVariable)

        $textBoxLeftValue = New-Object System.Windows.Forms.TextBox
        $textBoxLeftValue.Size = New-Object System.Drawing.Size(250, 20)
        $textBoxLeftValue.Location = [System.Drawing.Point]::new(10, 40)
        $groupLeftOption.Controls.Add($textBoxLeftValue)

        # 演算子
        $comboBoxOperator = New-Object System.Windows.Forms.ComboBox
        $comboBoxOperator.Size = New-Object System.Drawing.Size(80, 20)
        $comboBoxOperator.Location = [System.Drawing.Point]::new(360, $yPosition + 30)
        $comboBoxOperator.Items.AddRange(@("-eq", "-ne", "-lt", "-gt", "-like", "-notlike"))
        $panel.Controls.Add($comboBoxOperator)

        # 右辺グループ
        $groupRightOption = New-Object System.Windows.Forms.GroupBox
        $groupRightOption.Text = "右辺"
        $groupRightOption.Size = New-Object System.Drawing.Size(280, 80)
        $groupRightOption.Location = [System.Drawing.Point]::new(450, $yPosition)
        $panel.Controls.Add($groupRightOption)

        $checkBoxRightVariable = New-Object System.Windows.Forms.CheckBox
        $checkBoxRightVariable.Text = "変数を使用"
        $checkBoxRightVariable.Location = [System.Drawing.Point]::new(10, 15)
        $groupRightOption.Controls.Add($checkBoxRightVariable)

        $comboBoxRightVariable = New-Object System.Windows.Forms.ComboBox
        $comboBoxRightVariable.Size = New-Object System.Drawing.Size(250, 20)
        $comboBoxRightVariable.Location = [System.Drawing.Point]::new(10, 40)
        $comboBoxRightVariable.Items.AddRange($script:variablesList)
        $comboBoxRightVariable.Visible = $false
        $groupRightOption.Controls.Add($comboBoxRightVariable)

        $textBoxRightValue = New-Object System.Windows.Forms.TextBox
        $textBoxRightValue.Size = New-Object System.Drawing.Size(250, 20)
        $textBoxRightValue.Location = [System.Drawing.Point]::new(10, 40)
        $groupRightOption.Controls.Add($textBoxRightValue)

        # 削除ボタン
        $btnDelete = New-Object System.Windows.Forms.Button
        $btnDelete.Text = "削除"
        $btnDelete.Size = New-Object System.Drawing.Size(50, 20)
        $btnDelete.Location = [System.Drawing.Point]::new(10, $yPosition + 60)
        $btnDelete.Tag = @{ BranchIndex = $branchIndex; ConditionIndex = $index }
        $panel.Controls.Add($btnDelete)

        # コントロールセット
        $controlSet = @{
            LogicalOperator = $comboBoxLogicalOperator
            LeftCheckBox = $checkBoxLeftVariable
            LeftComboBox = $comboBoxLeftVariable
            LeftTextBox = $textBoxLeftValue
            LeftGroup = $groupLeftOption
            Operator = $comboBoxOperator
            RightCheckBox = $checkBoxRightVariable
            RightComboBox = $comboBoxRightVariable
            RightTextBox = $textBoxRightValue
            RightGroup = $groupRightOption
            DeleteButton = $btnDelete
        }

        $branchData.Conditions += $controlSet

        # イベントハンドラ
        $checkBoxLeftVariable.Add_CheckedChanged({
            param($sender, $e)
            $parent = $sender.Parent
            $combo = $parent.Controls | Where-Object { $_ -is [System.Windows.Forms.ComboBox] }
            $text = $parent.Controls | Where-Object { $_ -is [System.Windows.Forms.TextBox] }
            if ($sender.Checked) {
                $combo.Visible = $true
                $text.Visible = $false
            } else {
                $combo.Visible = $false
                $text.Visible = $true
            }
            UpdateMultiBranchPreview
        })

        $checkBoxRightVariable.Add_CheckedChanged({
            param($sender, $e)
            $parent = $sender.Parent
            $combo = $parent.Controls | Where-Object { $_ -is [System.Windows.Forms.ComboBox] }
            $text = $parent.Controls | Where-Object { $_ -is [System.Windows.Forms.TextBox] }
            if ($sender.Checked) {
                $combo.Visible = $true
                $text.Visible = $false
            } else {
                $combo.Visible = $false
                $text.Visible = $true
            }
            UpdateMultiBranchPreview
        })

        # 入力変更時にプレビュー更新
        $comboBoxLeftVariable.Add_SelectedIndexChanged({ UpdateMultiBranchPreview })
        $textBoxLeftValue.Add_TextChanged({ UpdateMultiBranchPreview })
        $comboBoxOperator.Add_SelectedIndexChanged({ UpdateMultiBranchPreview })
        $comboBoxRightVariable.Add_SelectedIndexChanged({ UpdateMultiBranchPreview })
        $textBoxRightValue.Add_TextChanged({ UpdateMultiBranchPreview })
        if ($comboBoxLogicalOperator) {
            $comboBoxLogicalOperator.Add_SelectedIndexChanged({ UpdateMultiBranchPreview })
        }

        UpdateMultiBranchPreview
    }

    # タブを再構築する関数
    function RebuildTabs {
        $selectedBranchCount = $cmbBranchCount.SelectedIndex + 2
        $script:branchCount = $selectedBranchCount

        # 既存タブをクリア
        $tabControl.TabPages.Clear()
        $script:branchConditionControls = @{}

        # ループビルダーからの場合は1タブのみ
        if ($IsFromLoopBuilder) {
            CreateBranchTab -branchIndex 0 -tabTitle "条件式"
            return
        }

        # 分岐数に応じてタブを作成
        for ($i = 0; $i -lt $selectedBranchCount; $i++) {
            if ($i -eq 0) {
                $tabTitle = "If条件 (True時)"
            } elseif ($i -eq $selectedBranchCount - 1) {
                $tabTitle = "Else (その他)"
            } else {
                $tabTitle = "ElseIf条件 $i"
            }
            CreateBranchTab -branchIndex $i -tabTitle $tabTitle
        }

        # Elseタブの条件入力を無効化（条件不要）
        $lastIndex = $selectedBranchCount - 1
        if ($script:branchConditionControls.ContainsKey($lastIndex)) {
            $lastBranch = $script:branchConditionControls[$lastIndex]
            $lastBranch.Panel.Enabled = $false
            $lastBranch.AddButton.Enabled = $false
            # Elseタブに説明ラベルを追加
            $lblElseInfo = New-Object System.Windows.Forms.Label
            $lblElseInfo.Text = "Else分岐は条件式不要です。`n上記のいずれの条件にも該当しない場合に実行されます。"
            $lblElseInfo.Location = New-Object System.Drawing.Point(20, 50)
            $lblElseInfo.Size = New-Object System.Drawing.Size(400, 50)
            $lblElseInfo.ForeColor = [System.Drawing.Color]::Gray
            $lastBranch.Panel.Controls.Clear()
            $lastBranch.Panel.Controls.Add($lblElseInfo)
        }

        UpdateMultiBranchPreview
    }

    # 条件式プレビューセクション
    $labelPreview = New-Object System.Windows.Forms.Label
    $labelPreview.Text = "生成コード プレビュー:"
    $labelPreview.AutoSize = $true
    $labelPreview.Location = New-Object System.Drawing.Point(10, 590)
    $form.Controls.Add($labelPreview)

    $script:textBoxPreview = New-Object System.Windows.Forms.TextBox
    $script:textBoxPreview.Size = New-Object System.Drawing.Size(960, 120)
    $script:textBoxPreview.Location = New-Object System.Drawing.Point(10, 615)
    $script:textBoxPreview.Multiline = $true
    $script:textBoxPreview.ScrollBars = "Both"
    $script:textBoxPreview.Font = New-Object System.Drawing.Font("Consolas", 9)
    $form.Controls.Add($script:textBoxPreview)

    # 保存/キャンセルボタン
    $btnSave = New-Object System.Windows.Forms.Button
    $btnSave.Text = "保存"
    $btnSave.Size = New-Object System.Drawing.Size(100, 30)
    $btnSave.Location = New-Object System.Drawing.Point(770, 745)
    $form.Controls.Add($btnSave)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "キャンセル"
    $btnCancel.Size = New-Object System.Drawing.Size(100, 30)
    $btnCancel.Location = New-Object System.Drawing.Point(880, 745)
    $form.Controls.Add($btnCancel)

    # プレビュー更新関数（多重分岐対応）
    function UpdateMultiBranchPreview {
        if ($IsFromLoopBuilder) {
            # ループビルダーからの場合は条件式のみ
            $condition = GetBranchCondition -branchIndex 0
            $script:textBoxPreview.Text = $condition
            return
        }

        $branchCount = $script:branchCount
        $code = ""

        for ($i = 0; $i -lt $branchCount; $i++) {
            $condition = GetBranchCondition -branchIndex $i

            if ($i -eq 0) {
                # If
                if ([string]::IsNullOrWhiteSpace($condition)) {
                    $condition = '$true'
                }
                $code = "if ($condition) {`r`n    # True の処理`r`n}"
            } elseif ($i -eq $branchCount - 1) {
                # Else
                $code += " else {`r`n    # その他 の処理`r`n}"
            } else {
                # ElseIf
                if ([string]::IsNullOrWhiteSpace($condition)) {
                    $condition = '$true'
                }
                $code += " elseif ($condition) {`r`n    # ElseIf$i の処理`r`n}"
            }
        }

        $script:textBoxPreview.Text = $code
    }

    # 分岐の条件式を取得
    function GetBranchCondition {
        param([int]$branchIndex)

        if (-not $script:branchConditionControls.ContainsKey($branchIndex)) {
            return ""
        }

        $branchData = $script:branchConditionControls[$branchIndex]
        $conditions = $branchData.Conditions
        $fullCondition = ""
        $i = 0

        foreach ($controlSet in $conditions) {
            # 左辺
            if ($controlSet.LeftCheckBox.Checked) {
                $leftOperand = $controlSet.LeftComboBox.SelectedItem
            } else {
                $leftValue = $controlSet.LeftTextBox.Text.Trim()
                $leftOperand = '"' + $leftValue + '"'
            }

            # 右辺
            if ($controlSet.RightCheckBox.Checked) {
                $rightOperand = $controlSet.RightComboBox.SelectedItem
            } else {
                $rightValue = $controlSet.RightTextBox.Text.Trim()
                $rightOperand = '"' + $rightValue + '"'
            }

            $operator = $controlSet.Operator.SelectedItem

            if ([string]::IsNullOrWhiteSpace($leftOperand) -or [string]::IsNullOrWhiteSpace($operator) -or [string]::IsNullOrWhiteSpace($rightOperand)) {
                $i++
                continue
            }

            $condition = "$leftOperand $operator $rightOperand"

            if ($i -eq 0) {
                $fullCondition = $condition
            } else {
                $logicalOp = $controlSet.LogicalOperator.SelectedItem
                if (![string]::IsNullOrWhiteSpace($logicalOp)) {
                    $fullCondition = "($fullCondition) $logicalOp ($condition)"
                }
            }
            $i++
        }

        return $fullCondition
    }

    # 分岐数変更イベント
    $cmbBranchCount.Add_SelectedIndexChanged({
        RebuildTabs
    })

    # 初期タブ構築
    RebuildTabs

    # キャンセルボタン
    $btnCancel.Add_Click({
        $script:conditionResult = $null
        $form.Close()
    })

    # 保存ボタン
    $btnSave.Add_Click({
        # コメント行を "---" に置換
        $script:conditionResult = $script:textBoxPreview.Text -split "`n" | ForEach-Object {
            if ($_ -match '^\s*#') {
                '---'
            } else {
                $_
            }
        } | Out-String

        $form.Close()
    })

    # フォーム表示
    $null = $form.ShowDialog()

    # ループビルダーからの場合は条件式のみ返す
    if ($IsFromLoopBuilder) {
        return $script:conditionResult
    }

    # 通常の場合はJSON形式で分岐数とコードを返す
    if ($null -eq $script:conditionResult) {
        return $null
    }

    # 分岐数を含めてJSON形式で返す
    $result = @{
        branchCount = $script:branchCount
        code = $script:conditionResult
    } | ConvertTo-Json -Compress

    return $result
}


# ================================================================
# 補助関数: 単一値変数名リスト取得
# ================================================================
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
