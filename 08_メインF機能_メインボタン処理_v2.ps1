# ============================================
# 08_メインF機能_メインボタン処理_v2.ps1
# UI非依存版 - HTML/JS移行対応
# ============================================
# 変更内容:
#   - 実行イベント_v2: $global:レイヤー1.Controlsではなくノード配列を受け取る
#   - 変数イベント_v2、フォルダ作成イベント_v2などのUI非依存版を追加
#   - すべての関数が構造化データを返却（REST API対応）
#   - 既存の関数も維持（後方互換性）
#
# 互換性:
#   - 既存のWindows Forms版でも動作
#   - HTML/JS版でも動作（REST API経由）
# ============================================

# Windowsフォームを利用するための必要なアセンブリを読み込み
Add-Type -AssemblyName System.Windows.Forms

# ============================================
# 新しい関数（UI非依存版 - HTML/JS対応）
# ============================================

function 実行イベント_v2 {
    <#
    .SYNOPSIS
    PowerShellコードを生成（UI非依存版）

    .DESCRIPTION
    ノード配列からPowerShellコードを生成します。
    Windows FormsのPanel.Controlsではなく、配列ベースで動作します。

    .PARAMETER ノード配列
    ノード情報を含むハッシュテーブルの配列
    各ノードは以下のプロパティを持つ:
      - id (または name): ノードID
      - text: 表示テキスト
      - color (または BackColor): ノード色
      - y: Y座標（ソート用）

    .PARAMETER OutputPath
    出力ファイルパス（省略時は $global:folderPath/output.ps1 を使用）

    .PARAMETER OpenFile
    生成後にファイルを開くか（デフォルト: $false）

    .EXAMPLE
    $nodes = @(
        @{ id = "100-1"; text = "開始"; color = "White"; y = 50 },
        @{ id = "101-1"; text = "処理A"; color = "SpringGreen"; y = 100 }
    )
    $result = 実行イベント_v2 -ノード配列 $nodes
    #>
    param (
        [Parameter(Mandatory=$true)]
        [array]$ノード配列,

        [string]$OutputPath = $null,
        [bool]$OpenFile = $false
    )

    try {
        # ノード配列が空の場合
        if (-not $ノード配列 -or $ノード配列.Count -eq 0) {
            return @{
                success = $false
                error = "ノード配列が空です"
            }
        }

        # Y座標でソート
        $buttons = $ノード配列 | Sort-Object { $_.y }

        # 出力用の文字列変数を初期化
        $output = ""

        # ボタンの総数を取得
        $buttonCount = $buttons.Count
        Write-Host "ノードカウント: $buttonCount"

        # 最後に見つかったGreenボタンの親IDを格納
        $lastGreenParentId = $null

        for ($i = 0; $i -lt $buttonCount; $i++) {
            $button = $buttons[$i]

            # プロパティ名の柔軟な取得（id/name, text/Text, color/BackColorに対応）
            $buttonName = if ($button.id) { $button.id } elseif ($button.name) { $button.name } else { "unknown" }
            $buttonText = if ($button.text) { $button.text } elseif ($button.Text) { $button.Text } else { "" }
            $colorName = if ($button.color) { $button.color } elseif ($button.BackColor) { $button.BackColor } else { "White" }

            # ボタン情報をコンソールに出力
            $buttonInfo = "ノード名: $buttonName, テキスト: $buttonText, 色: $colorName"
            Write-Host $buttonInfo

            # 処理番号プロパティがあればそれを優先してそのまま使用、なければノード名から抽出
            if ($button.PSObject.Properties['処理番号'] -and $button.処理番号) {
                # 処理番号をそのまま使用 (例: "1-1", "1-6")
                # コード.jsonのキーは "1-1", "6-1" などのサブID形式で保存されている
                $id = $button.処理番号
                Write-Host "[DEBUG] 処理番号をそのまま使用: $id" -ForegroundColor Cyan
            } else {
                # ノード名から抽出 (例: "9-1" -> "9", "10-1" -> "10")
                # ハイフンが含まれている場合は最初の部分を使用、含まれていない場合はそのまま使用
                $baseId = if ($buttonName -match '-') { ($buttonName -split '-')[0] } else { $buttonName }
                $id = $baseId
                Write-Host "[DEBUG] ノードIDから抽出: $buttonName -> ID: $id" -ForegroundColor Cyan
            }

            # エントリを取得
            try {
                $取得したエントリ = IDでエントリを取得 -ID $id
                Write-Host "取得したエントリ: $取得したエントリ"
            } catch {
                Write-Host "[ERROR] IDでエントリを取得に失敗: $($_.Exception.Message)" -ForegroundColor Red
                $取得したエントリ = $null
            }

            if ($取得したエントリ -ne $null -and $取得したエントリ -ne "") {
                # エントリの内容をコンソールに出力
                Write-Host "エントリID: $id`n内容:`n$取得したエントリ`n"

                # エントリが "AAAA" で始まる場合は展開（Pinkノード）
                if ($取得したエントリ -match "^AAAA") {
                    Write-Host "Pinkノード（スクリプト化されたノード）を展開します"
                    $取得したエントリ = ノードリストを展開 -ノードリスト文字列 $取得したエントリ
                }

                # エントリの内容のみを$outputに追加（空行を追加）
                $output += "$取得したエントリ`n`n"
            } else {
                Write-Host "[WARNING] エントリが見つかりません: ノードID=$buttonName, ベースID=$id" -ForegroundColor Yellow
                Write-Host "[WARNING] このノードはスキップされます" -ForegroundColor Yellow
            }

            # 現在のノードがGreenの場合、lastGreenParentIdを更新
            if ($colorName -eq "Green" -or $colorName -eq "SpringGreen") {
                # 親IDを抽出（例: "76-1" -> "76"）
                $lastGreenParentId = ($id -split '-')[0]
            }

            # 現在のノードがRedで、次のノードがBlueの場合に特定のIDを挿入
            if ($colorName -eq "Red" -or $colorName -eq "Salmon") {
                if (($i + 1) -lt $buttonCount) {
                    $nextButton = $buttons[$i + 1]
                    $nextColorName = if ($nextButton.color) { $nextButton.color } else { $nextButton.BackColor }

                    if ($nextColorName -eq "Blue" -or $nextColorName -eq "DeepSkyBlue") {
                        if ($lastGreenParentId -ne $null) {
                            # 特定のIDをlastGreenParentIdに基づいて設定（例: "76-2"）
                            $specialId = "$lastGreenParentId-2"

                            # 特定のIDでエントリを取得
                            $specialEntry = IDでエントリを取得 -ID $specialId
                            if ($specialEntry -ne $null) {
                                # エントリの内容のみを$outputに追加（空行を追加）
                                $output += "$specialEntry`n`n"
                            }
                        }
                    }
                }
            }
        }

        # 出力パスの決定
        if ([string]::IsNullOrWhiteSpace($OutputPath)) {
            if ([string]::IsNullOrWhiteSpace($global:folderPath)) {
                return @{
                    success = $false
                    error = "出力先パスが指定されていません（$global:folderPath も未設定）"
                }
            }
            $OutputPath = Join-Path -Path $global:folderPath -ChildPath "output.ps1"
        }

        # 出力をファイルに書き込む
        try {
            $output | Set-Content -Path $OutputPath -Force -Encoding UTF8
            Write-Host "出力をファイルに書き込みました: $OutputPath"
        }
        catch {
            return @{
                success = $false
                error = "出力ファイルの書き込みに失敗しました: $($_.Exception.Message)"
            }
        }

        # ファイルを開く（オプション）
        if ($OpenFile) {
            try {
                Start-Process -FilePath "powershell_ise.exe" -ArgumentList $OutputPath -NoNewWindow
                Write-Host "PowerShell ISEでファイルを開きました"
            }
            catch {
                Write-Warning "ファイルを開く際にエラーが発生しました: $($_.Exception.Message)"
            }
        }

        return @{
            success = $true
            message = "PowerShellコードを生成しました"
            outputPath = $OutputPath
            nodeCount = $buttonCount
            codeLength = $output.Length
        }

    } catch {
        return @{
            success = $false
            error = "実行イベント処理に失敗しました: $($_.Exception.Message)"
            stackTrace = $_.ScriptStackTrace
        }
    }
}


function 変数イベント_v2 {
    <#
    .SYNOPSIS
    変数管理UIを表示（UI非依存版）

    .PARAMETER ShowUI
    UIを表示するかどうか（デフォルト: $false）
    $false の場合、変数一覧をJSON形式で返します

    .EXAMPLE
    # UI非表示の場合
    $result = 変数イベント_v2 -ShowUI $false

    # UI表示の場合
    $result = 変数イベント_v2 -ShowUI $true
    #>
    param (
        [bool]$ShowUI = $false
    )

    try {
        # UI非表示の場合は、変数一覧を返す
        if (-not $ShowUI) {
            # v2関数を使用（10_変数機能_変数管理UI_v2.ps1 から）
            if (Get-Command "Get-VariableList_v2" -ErrorAction SilentlyContinue) {
                $result = Get-VariableList_v2
                return $result
            } else {
                return @{
                    success = $false
                    error = "Get-VariableList_v2 関数が見つかりません（10_変数機能_変数管理UI_v2.ps1 を読み込んでください）"
                }
            }
        }

        # UI表示の場合
        if ($global:メインフォーム) {
            $global:メインフォーム.Hide()
        }

        # 変数管理UIを表示
        $variableName = Show-VariableManagerForm

        if ($global:メインフォーム) {
            $global:メインフォーム.Show()
        }

        return @{
            success = $true
            selectedVariable = $variableName
        }

    } catch {
        return @{
            success = $false
            error = "変数イベント処理に失敗しました: $($_.Exception.Message)"
        }
    }
}


function フォルダ作成イベント_v2 {
    <#
    .SYNOPSIS
    新規フォルダを作成（UI非依存版）

    .PARAMETER FolderName
    作成するフォルダ名

    .PARAMETER ShowUI
    UIを表示するかどうか（デフォルト: $false）

    .EXAMPLE
    # UI非表示の場合
    $result = フォルダ作成イベント_v2 -FolderName "NewProject"

    # UI表示の場合
    $result = フォルダ作成イベント_v2 -ShowUI $true
    #>
    param (
        [string]$FolderName = $null,
        [bool]$ShowUI = $false
    )

    try {
        # UI表示の場合
        if ($ShowUI) {
            if ($global:メインフォーム) {
                $global:メインフォーム.Hide()
            }

            新規フォルダ作成

            if ($global:メインフォーム) {
                $global:メインフォーム.Show()
            }

            return @{
                success = $true
                message = "フォルダを作成しました"
            }
        }

        # UI非表示の場合
        if ([string]::IsNullOrWhiteSpace($FolderName)) {
            return @{
                success = $false
                error = "フォルダ名を指定してください"
            }
        }

        # 保存先ディレクトリを設定
        $保存先ディレクトリ = Join-Path -Path $PSScriptRoot -ChildPath "03_history"

        if (-not (Test-Path -Path $保存先ディレクトリ)) {
            New-Item -Path $保存先ディレクトリ -ItemType Directory | Out-Null
        }

        # 保存先のフルパスを生成
        $フォルダパス = Join-Path -Path $保存先ディレクトリ -ChildPath $FolderName

        # 新規フォルダを作成
        if (-not (Test-Path -Path $フォルダパス)) {
            New-Item -Path $フォルダパス -ItemType Directory | Out-Null
        } else {
            return @{
                success = $false
                error = "フォルダは既に存在しています: $フォルダパス"
            }
        }

        # メイン.json ファイルに保存
        $jsonFilePath = Join-Path -Path $保存先ディレクトリ -ChildPath "メイン.json"

        $jsonData = @{}
        if (Test-Path -Path $jsonFilePath) {
            $existingData = Read-JsonSafe -Path $jsonFilePath -Required $false -Silent $true
            if ($existingData) {
                $jsonData = $existingData
            }
        }
        $jsonData.フォルダパス = $フォルダパス

        Write-JsonSafe -Path $jsonFilePath -Data $jsonData -Depth 10 -Silent $true

        # グローバル変数を更新
        $global:folderPath = $フォルダパス
        $global:JSONPath = "$global:folderPath\variables.json"

        # variables.jsonを初期化
        if (Get-Command "Write-JsonSafe" -ErrorAction SilentlyContinue) {
            Write-JsonSafe -Path $global:JSONPath -Data @{} -Depth 10 -CreateDirectory $true -Silent $true
        }

        # コードIDストアを初期化
        if (Get-Command "JSON初回" -ErrorAction SilentlyContinue) {
            JSON初回
        }
        if (Get-Command "JSONストアを初期化" -ErrorAction SilentlyContinue) {
            JSONストアを初期化
        }

        return @{
            success = $true
            message = "フォルダを作成しました"
            folderPath = $フォルダパス
        }

    } catch {
        return @{
            success = $false
            error = "フォルダ作成に失敗しました: $($_.Exception.Message)"
        }
    }
}


function フォルダ切替イベント_v2 {
    <#
    .SYNOPSIS
    フォルダを切り替え（UI非依存版）

    .PARAMETER FolderName
    切り替えるフォルダ名

    .PARAMETER ShowUI
    UIを表示するかどうか（デフォルト: $false）

    .EXAMPLE
    # UI非表示の場合
    $result = フォルダ切替イベント_v2 -FolderName "Project1"

    # UI表示の場合
    $result = フォルダ切替イベント_v2 -ShowUI $true

    # フォルダ一覧を取得
    $result = フォルダ切替イベント_v2 -FolderName "list"
    #>
    param (
        [string]$FolderName = $null,
        [bool]$ShowUI = $false
    )

    try {
        # UI表示の場合
        if ($ShowUI) {
            if ($global:メインフォーム) {
                $global:メインフォーム.Hide()
            }

            フォルダ選択と保存

            if ($global:メインフォーム) {
                $global:メインフォーム.Show()
            }

            return @{
                success = $true
                message = "フォルダを切り替えました"
            }
        }

        # 保存先ディレクトリを取得
        $保存先ディレクトリ = Join-Path -Path $PSScriptRoot -ChildPath "03_history"

        if (-not (Test-Path -Path $保存先ディレクトリ)) {
            return @{
                success = $false
                error = "03_historyディレクトリが存在しません"
            }
        }

        # フォルダ一覧を取得
        $フォルダ一覧 = Get-ChildItem -Path $保存先ディレクトリ -Directory | Select-Object -ExpandProperty Name

        # フォルダ一覧のみを返す場合
        if ($FolderName -eq "list") {
            return @{
                success = $true
                folders = $フォルダ一覧
                count = $フォルダ一覧.Count
            }
        }

        # UI非表示の場合
        if ([string]::IsNullOrWhiteSpace($FolderName)) {
            return @{
                success = $false
                error = "フォルダ名を指定してください"
            }
        }

        # フォルダの存在確認
        if ($フォルダ一覧 -notcontains $FolderName) {
            return @{
                success = $false
                error = "フォルダが見つかりません: $FolderName"
                availableFolders = $フォルダ一覧
            }
        }

        # フォルダパスを取得
        $選択フォルダパス = Join-Path -Path $保存先ディレクトリ -ChildPath $FolderName

        # JSONファイルへの保存
        $jsonFilePath = Join-Path -Path $保存先ディレクトリ -ChildPath "メイン.json"

        $jsonData = @{ フォルダパス = $選択フォルダパス }
        if (Test-Path -Path $jsonFilePath) {
            $existingData = Read-JsonSafe -Path $jsonFilePath -Required $false -Silent $true
            if ($existingData) {
                $existingData.フォルダパス = $選択フォルダパス
                $jsonData = $existingData
            }
        }

        Write-JsonSafe -Path $jsonFilePath -Data $jsonData -Depth 10 -Silent $true

        # グローバル変数を更新
        $global:folderPath = $選択フォルダパス
        $global:JSONPath = "$global:folderPath\variables.json"

        return @{
            success = $true
            message = "フォルダを切り替えました"
            folderPath = $選択フォルダパス
        }

    } catch {
        return @{
            success = $false
            error = "フォルダ切り替えに失敗しました: $($_.Exception.Message)"
        }
    }
}


# ============================================
# ヘルパー関数（再利用可能）
# ============================================

# ノードリストを展開する再帰関数
function ノードリストを展開 {
    <#
    .SYNOPSIS
    Pinkノード（スクリプト化されたノード）を展開

    .DESCRIPTION
    この関数は既存のロジックをそのまま維持しています。
    ビジネスロジックなので、Windows Forms版とv2版で共有できます。
    #>
    param (
        [string]$ノードリスト文字列
    )

    Write-Host "=== ノードリスト展開開始 ==="
    Write-Host "入力: $ノードリスト文字列"

    # "AAAA" を除去
    $ノードリスト文字列 = $ノードリスト文字列 -replace "^AAAA\s*", ""

    # 行ごとに分割
    $lines = $ノードリスト文字列 -split "`r?`n" | Where-Object { $_.Trim() -ne "" }

    Write-Host "ノード数: $($lines.Count)"

    $output = ""

    foreach ($line in $lines) {
        # 形式: <ノードID>;<背景色>;<テキスト>;
        $parts = $line -split ";"
        if ($parts.Count -ge 1) {
            $nodeId = $parts[0].Trim()
            Write-Host "処理中のノードID: $nodeId"

            # このノードのエントリを取得
            $entry = IDでエントリを取得 -ID $nodeId

            if ($entry -ne $null) {
                Write-Host "取得したエントリ: $entry"

                # エントリが "AAAA" で始まる場合は再帰的に展開
                if ($entry -match "^AAAA") {
                    Write-Host "再帰的に展開します"
                    $entry = ノードリストを展開 -ノードリスト文字列 $entry
                }

                $output += "$entry`n"
            } else {
                Write-Host "エントリが見つかりません: $nodeId"
            }
        }
    }

    Write-Host "=== ノードリスト展開完了 ==="
    return $output
}


# ============================================
# 既存の関数（Windows Forms版 - 後方互換性維持）
# ============================================

function 実行イベント {
    <#
    .SYNOPSIS
    実行ボタンのクリックイベント（既存のWindows Forms版）

    .DESCRIPTION
    この関数は既存のWindows Forms版との互換性維持のために残されています。
    内部でv2関数を呼び出すことも可能ですが、既存のロジックを維持します。
    #>

    try {
        # メインフレームパネル内のボタンを取得し、Y座標でソート
        $buttons = $global:レイヤー1.Controls |
                   Where-Object { $_ -is [System.Windows.Forms.Button] } |
                   Sort-Object { $_.Location.Y }

        # ボタン情報をノード配列に変換
        $ノード配列 = @()
        foreach ($button in $buttons) {
            $ノード配列 += @{
                id = $button.Name
                text = $button.Text
                color = $button.BackColor.Name
                y = $button.Location.Y
            }
        }

        # v2関数を呼び出し
        $result = 実行イベント_v2 -ノード配列 $ノード配列 -OpenFile $true

        if (-not $result.success) {
            Write-Error $result.error
        }

    } catch {
        Write-Error "エラーが発生しました: $_"
    }
}

function 変数イベント {
    変数イベント_v2 -ShowUI $true | Out-Null
}

function フォルダ作成イベント {
    フォルダ作成イベント_v2 -ShowUI $true | Out-Null
}

function フォルダ切替イベント {
    フォルダ切替イベント_v2 -ShowUI $true | Out-Null
}

function Update-説明ラベル {
    param (
        [string]$説明文
    )
    if ($説明文) {
        $global:説明ラベル.Text = $説明文
    } else {
        $global:説明ラベル.Text = "ここに説明文が表示されます。"
    }
}

function 切替ボタンイベント {
    param (
        [array]$SwitchButtons,
        [array]$SwitchTexts
    )

    for ($i = 0; $i -lt $SwitchButtons.Count; $i++) {
        $ボタン = $SwitchButtons[$i]
        $ボタンテキスト = $SwitchTexts[$i]
        $説明文 = $global:切替ボタン説明[$ボタン.Text]

        $ボタン.Tag = $説明文

        $ボタン.Add_GotFocus({
            param($sender, $e)
            Update-説明ラベル -説明文 $sender.Tag
        })

        $ボタン.Add_LostFocus({
            param($sender, $e)
            Update-説明ラベル -説明文 $null
        })

        $ボタン.Add_MouseEnter({
            param($sender, $e)
            Update-説明ラベル -説明文 $sender.Tag
        })

        $ボタン.Add_MouseLeave({
            param($sender, $e)
            Update-説明ラベル -説明文 $null
        })
    }
}

function 新規フォルダ作成 {
    $保存先ディレクトリ = $PSScriptRoot
    $保存先ディレクトリ = $保存先ディレクトリ + "\03_history"

    $入力フォーム = New-Object Windows.Forms.Form
    $入力フォーム.Text = "フォルダ名入力"
    $入力フォーム.Size = New-Object Drawing.Size(400,150)

    $ラベル = New-Object Windows.Forms.Label
    $ラベル.Text = "新しいフォルダ名を入力してください:"
    $ラベル.AutoSize = $true
    $ラベル.Location = New-Object Drawing.Point(10,20)

    $テキストボックス = New-Object Windows.Forms.TextBox
    $テキストボックス.Size = New-Object Drawing.Size(350,30)
    $テキストボックス.Location = New-Object Drawing.Point(10,50)

    $ボタン = New-Object Windows.Forms.Button
    $ボタン.Text = "作成"
    $ボタン.Location = New-Object Drawing.Point(10,90)
    $ボタン.Add_Click({$入力フォーム.Close()})

    $入力フォーム.Controls.Add($ラベル)
    $入力フォーム.Controls.Add($テキストボックス)
    $入力フォーム.Controls.Add($ボタン)

    $入力フォーム.ShowDialog()

    $フォルダ名 = $テキストボックス.Text

    if (-not $フォルダ名) {
        return
    }

    $フォルダパス = Join-Path -Path $保存先ディレクトリ -ChildPath $フォルダ名

    if (-not (Test-Path -Path $フォルダパス)) {
        New-Item -Path $フォルダパス -ItemType Directory | Out-Null
    }

    $jsonFilePath = Join-Path -Path $保存先ディレクトリ -ChildPath "メイン.json"

    $jsonData = @{}
    if (Test-Path -Path $jsonFilePath) {
        $existingData = Read-JsonSafe -Path $jsonFilePath -Required $false -Silent $true
        if ($existingData) {
            $jsonData = $existingData
        }
    }
    $jsonData.フォルダパス = $フォルダパス

    Write-JsonSafe -Path $jsonFilePath -Data $jsonData -Depth 10 -Silent $true

    $スクリプトPath = $PSScriptRoot

    $global:folderPath = 取得-JSON値 -jsonFilePath "$スクリプトPath\03_history\メイン.json" -keyName "フォルダパス"
    $global:JSONPath = "$global:folderPath\variables.json"

    $outputFile = $global:JSONPath
    try {
        $outputFolder = Split-Path -Parent $outputFile

        [System.Windows.Forms.MessageBox]::Show($outputFolder)

        Write-JsonSafe -Path $outputFile -Data $global:variables -Depth 10 -CreateDirectory $true -Silent $true
        [System.Windows.Forms.MessageBox]::Show("変数がJSON形式で保存されました: `n$outputFile") | Out-Null
    } catch {
        [System.Windows.Forms.MessageBox]::Show("JSONの保存に失敗しました: $_") | Out-Null
    }

    JSON初回
    JSONストアを初期化
}

function フォルダ選択と保存 {
    $保存先ディレクトリ = Join-Path -Path $PSScriptRoot -ChildPath "03_history"

    if (-not (Test-Path -Path $保存先ディレクトリ)) {
        New-Item -Path $保存先ディレクトリ -ItemType Directory | Out-Null
    }

    $フォルダ一覧 = Get-ChildItem -Path $保存先ディレクトリ -Directory | Select-Object -ExpandProperty Name

    $入力フォーム = New-Object Windows.Forms.Form
    $入力フォーム.Text = "フォルダ選択"
    $入力フォーム.Size = New-Object Drawing.Size(400,300)

    $ラベル = New-Object Windows.Forms.Label
    $ラベル.Text = "フォルダを選択してください:"
    $ラベル.AutoSize = $true
    $ラベル.Location = New-Object Drawing.Point(10,10)

    $リストボックス = New-Object Windows.Forms.ListBox
    $リストボックス.Size = New-Object Drawing.Size(350,200)
    $リストボックス.Location = New-Object Drawing.Point(10,40)
    $リストボックス.Items.AddRange($フォルダ一覧)

    $ボタン = New-Object Windows.Forms.Button
    $ボタン.Text = "保存"
    $ボタン.Location = New-Object Drawing.Point(10,250)
    $ボタン.Add_Click({
        if ($リストボックス.SelectedItem) {
            $global:選択フォルダ = $リストボックス.SelectedItem
            $入力フォーム.Close()
        } else {
            Show-WarningDialog "フォルダを選択してください。" -Title "エラー"
        }
    })

    $入力フォーム.Controls.Add($ラベル)
    $入力フォーム.Controls.Add($リストボックス)
    $入力フォーム.Controls.Add($ボタン)

    $入力フォーム.ShowDialog()

    if (-not $global:選択フォルダ) {
        return
    }

    $選択フォルダパス = Join-Path -Path $保存先ディレクトリ -ChildPath $global:選択フォルダ

    $jsonFilePath = Join-Path -Path $保存先ディレクトリ -ChildPath "メイン.json"

    $jsonData = @{ フォルダパス = $選択フォルダパス }
    if (Test-Path -Path $jsonFilePath) {
        $existingData = Read-JsonSafe -Path $jsonFilePath -Required $false -Silent $true
        if ($existingData) {
            $existingData.フォルダパス = $選択フォルダパス
            $jsonData = $existingData
        }
    }

    Write-JsonSafe -Path $jsonFilePath -Data $jsonData -Depth 10 -Silent $true

    $スクリプトPath = $PSScriptRoot
    $global:folderPath = 取得-JSON値 -jsonFilePath "$スクリプトPath\03_history\メイン.json" -keyName "フォルダパス"
    $global:JSONPath = "$global:folderPath\variables.json"
}

function 作成ボタンとイベント設定 {
    param (
        [string]$処理番号,
        [string]$テキスト,
        [string]$ボタン名,
        [System.Drawing.Color]$背景色,
        [object]$コンテナ,
        [string]$説明
    )

    $新しいボタン = 00_汎用色ボタンを作成する -コンテナ $コンテナ -テキスト $テキスト -ボタン名 $ボタン名 -幅 160 -高さ 30 -X位置 10 -Y位置 $Y位置 -背景色 $背景色

    $新しいボタン.Tag = @{
        処理番号 = $処理番号
        説明 = $説明
    }

    00_汎用色ボタンのクリックイベントを設定する -ボタン $新しいボタン -処理番号 $処理番号

    $global:作成ボタン説明[$処理番号] = $説明

    $新しいボタン.Add_MouseEnter({
        param($sender, $eventArgs)
        $global:説明ラベル.Text = $説明
        $tag = $sender.Tag
        $処理番号 = $tag.処理番号
        $説明 = $tag.説明

        if ($global:作成ボタン説明.ContainsKey($処理番号)) {
            $global:説明ラベル.Text = $global:作成ボタン説明[$処理番号]
        } else {
            $global:説明ラベル.Text = "このボタンには説明が設定されていません。"
        }
    })

    $新しいボタン.Add_MouseLeave({
        $global:説明ラベル.Text = ""
    })

    $新しいボタン.Add_GotFocus({
        param($sender, $eventArgs)
        $global:説明ラベル.Text = $説明
        $tag = $sender.Tag
        $処理番号 = $tag.処理番号
        $説明 = $tag.説明

        if ($global:作成ボタン説明.ContainsKey($処理番号)) {
            $global:説明ラベル.Text = $説明
        } else {
            $global:説明ラベル.Text = $説明
        }
    })

    $新しいボタン.Add_LostFocus({
        $global:説明ラベル.Text = ""
    })
}
