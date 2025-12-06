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
# コメント生成用ヘルパー関数
# ============================================

function Get-NodeTypeFromColor {
    <#
    .SYNOPSIS
    ノードの色からノードタイプを判定
    #>
    param([string]$Color)

    switch ($Color) {
        "White"        { return "順次処理" }
        "LemonChiffon" { return "ループ" }
        "SpringGreen"  { return "条件分岐" }
        "Green"        { return "条件分岐" }
        "Salmon"       { return "処理" }
        "Red"          { return "処理" }
        "Pink"         { return "スクリプト" }
        "Gray"         { return "条件分岐" }
        default        { return "処理" }
    }
}

function New-NodeComment {
    <#
    .SYNOPSIS
    ノード情報からコメントブロックを生成
    #>
    param(
        [string]$NodeType,
        [string]$NodeText,
        [string]$NodeId,
        [string]$GroupId = $null
    )

    $separator = "# " + ("─" * 40)
    $comment = "$separator`r`n"
    $comment += "# [$NodeType] $NodeText`r`n"

    if ($GroupId -and $GroupId -ne "") {
        $comment += "# ノードID: $NodeId, GroupID: $GroupId`r`n"
    } else {
        $comment += "# ノードID: $NodeId`r`n"
    }

    $comment += "$separator`r`n"

    return $comment
}

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

        # デバッグモード（環境変数で制御）
        $DebugMode = $env:UIPOWERSHELL_DEBUG -eq "1"

        # Y座標でソート（配列として強制）
        $buttons = @($ノード配列 | Sort-Object { $_.y })

        # 出力用の文字列変数を初期化
        $output = ""

        # ボタンの総数を取得
        $buttonCount = $buttons.Count
        if ($DebugMode) {
            Write-Host "ノードカウント: $buttonCount"
        }

        # 最後に見つかったGreenボタンの親IDを格納
        $lastGreenParentId = $null

        for ($i = 0; $i -lt $buttonCount; $i++) {
            $button = $buttons[$i]

            # プロパティ名の柔軟な取得（id/name, text/Text, color/BackColorに対応）
            $buttonName = if ($button.id) { $button.id } elseif ($button.name) { $button.name } else { "unknown" }
            $buttonText = if ($button.text) { $button.text } elseif ($button.Text) { $button.Text } else { "" }
            $colorName = if ($button.color) { $button.color } elseif ($button.BackColor) { $button.BackColor } else { "White" }

            # ボタン情報をコンソールに出力（デバッグモードのみ）
            if ($DebugMode) {
                $buttonInfo = "ノード名: $buttonName, テキスト: $buttonText, 色: $colorName"
                Write-Host $buttonInfo
            }

            # ノードIDをそのまま使用（例: "5-1", "6-1"）
            # コード.jsonのキーは "1-1", "6-1" などのノードID形式で保存されている
            $id = $buttonName
            if ($DebugMode) {
                Write-Host "[DEBUG] ノードIDをそのまま使用: $id" -ForegroundColor Cyan
            }

            # エントリを取得（まずノードIDそのままで検索）
            try {
                $取得したエントリ = IDでエントリを取得 -ID $id
                if ($DebugMode) {
                    Write-Host "[DEBUG] ノードID '$id' で検索結果: $(if ($取得したエントリ) { '見つかりました' } else { '見つかりません' })" -ForegroundColor Cyan
                }

                # 見つからない場合は "-1" を追加して再検索
                if ([string]::IsNullOrWhiteSpace($取得したエントリ)) {
                    $idWithSuffix = "$id-1"
                    if ($DebugMode) {
                        Write-Host "[DEBUG] ノードID '$id' で見つからないため、'$idWithSuffix' で再検索..." -ForegroundColor Yellow
                    }
                    $取得したエントリ = IDでエントリを取得 -ID $idWithSuffix
                    if ($DebugMode) {
                        Write-Host "[DEBUG] ノードID '$idWithSuffix' で検索結果: $(if ($取得したエントリ) { '見つかりました' } else { '見つかりません' })" -ForegroundColor Cyan
                    }
                    if ($取得したエントリ) {
                        $id = $idWithSuffix
                        if ($DebugMode) {
                            Write-Host "[DEBUG] 使用するID: $id" -ForegroundColor Green
                        }
                    }
                }

                if ($取得したエントリ -and $DebugMode) {
                    Write-Host "取得したエントリ: $取得したエントリ"
                }
            } catch {
                Write-Host "[ERROR] IDでエントリを取得に失敗: $($_.Exception.Message)" -ForegroundColor Red
                $取得したエントリ = $null
            }

            # Pinkノードの場合はscriptプロパティを優先的に使用（ID不整合問題を回避）
            if ($colorName -eq "Pink" -and $button.script) {
                Write-Host "[Pinkノード] scriptプロパティを優先使用" -ForegroundColor Magenta
                Write-Host "[Pinkノード] script内容: $($button.script)" -ForegroundColor Magenta

                # scriptがノードリスト形式か直接コード形式かを判定
                # ノードリスト形式:
                #   1. "AAAA" で始まる場合
                #   2. "ID;色;テキスト;" パターン（例: "26-1;White;順次;_27-1;White;順次;"）
                # 直接コード形式: それ以外（例: "Write-Host 'OK'"）
                $isNodeListFormat = ($button.script -match "^AAAA") -or ($button.script -match "^[\w\-]+;[\w]+;[^;]*;")

                if ($isNodeListFormat) {
                    Write-Host "[Pinkノード] ノードリスト形式を検出 → 展開処理" -ForegroundColor Magenta

                    # 既にAAAAで始まっている場合はそのまま、そうでなければAAAAを付加
                    if ($button.script -match "^AAAA") {
                        # "_" を改行に置換（フロントエンドでの区切り文字対応）
                        $ノードリスト文字列 = $button.script -replace "_", "`n"
                        Write-Host "[Pinkノード] AAAA形式をそのまま使用" -ForegroundColor Magenta
                    } else {
                        # scriptプロパティからノードリスト文字列を生成（AAAA形式に変換）
                        $scriptContent = $button.script -replace "_", "`n"
                        $ノードリスト文字列 = "AAAA`n$scriptContent"
                        Write-Host "[Pinkノード] AAAA形式に変換" -ForegroundColor Magenta
                    }
                    Write-Host "[Pinkノード] 生成したノードリスト: $ノードリスト文字列" -ForegroundColor Magenta

                    # ノードリストを展開
                    $取得したエントリ = ノードリストを展開 -ノードリスト文字列 $ノードリスト文字列
                    Write-Host "[Pinkノード] 展開後の内容: $取得したエントリ" -ForegroundColor Magenta
                    Write-Host "[Pinkノード] 展開後の長さ: $($取得したエントリ.Length) 文字" -ForegroundColor Magenta
                } else {
                    Write-Host "[Pinkノード] 直接コード形式を検出 → そのまま出力" -ForegroundColor Magenta
                    # 直接コード形式の場合はそのまま使用
                    $取得したエントリ = $button.script
                }

                # 改行コードの正規化
                $取得したエントリ = $取得したエントリ -replace "`r`n", "<<CRLF>>" -replace "`n", "`r`n" -replace "<<CRLF>>", "`r`n"

                # コメント生成（Pinkノード用）
                $nodeType = Get-NodeTypeFromColor -Color $colorName
                $groupIdValue = if ($button.groupId) { $button.groupId } else { "" }
                $nodeComment = New-NodeComment -NodeType $nodeType -NodeText $buttonText -NodeId $buttonName -GroupId $groupIdValue
                $output += "$nodeComment$取得したエントリ`r`n`r`n"
            } elseif ($取得したエントリ -ne $null -and $取得したエントリ -ne "") {
                # エントリの内容をコンソールに出力（デバッグモードのみ）
                if ($DebugMode) {
                    Write-Host "エントリID: $id`n内容:`n$取得したエントリ`n"
                }

                # エントリが "AAAA" で始まる場合は展開（Pinkノード）
                if ($取得したエントリ -match "^AAAA") {
                    Write-Host "[Pinkノード展開] ★展開開始: $取得したエントリ" -ForegroundColor Magenta
                    $取得したエントリ = ノードリストを展開 -ノードリスト文字列 $取得したエントリ
                    Write-Host "[Pinkノード展開] ★展開後: $($取得したエントリ.Length) 文字" -ForegroundColor Magenta
                    Write-Host "[Pinkノード展開] ★内容: $取得したエントリ" -ForegroundColor Magenta
                }

                # エントリの内容のみを$outputに追加（空行を追加）
                if ($DebugMode) {
                    Write-Host "[出力追加] outputに追加中: 長さ=$($取得したエントリ.Length) 文字" -ForegroundColor Cyan
                }
                # 改行コードの正規化: LF → CRLF（既にCRLFの場合は保持）
                $取得したエントリ = $取得したエントリ -replace "`r`n", "<<CRLF>>" -replace "`n", "`r`n" -replace "<<CRLF>>", "`r`n"

                # コメント生成（通常ノード用）
                $nodeType = Get-NodeTypeFromColor -Color $colorName
                $groupIdValue = if ($button.groupId) { $button.groupId } else { "" }
                $nodeComment = New-NodeComment -NodeType $nodeType -NodeText $buttonText -NodeId $buttonName -GroupId $groupIdValue
                $output += "$nodeComment$取得したエントリ`r`n`r`n"
                if ($DebugMode) {
                    Write-Host "[出力追加] 追加後のoutput長: $($output.Length) 文字" -ForegroundColor Cyan
                }
            } else {
                if ($DebugMode) {
                    Write-Host "[WARNING] エントリが見つかりません: ノードID=$buttonName, ベースID=$id" -ForegroundColor Yellow
                    Write-Host "[WARNING] このノードはスキップされます" -ForegroundColor Yellow
                }
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
                                # 改行コードの正規化: LF → CRLF（既にCRLFの場合は保持）
                                $specialEntry = $specialEntry -replace "`r`n", "<<CRLF>>" -replace "`n", "`r`n" -replace "<<CRLF>>", "`r`n"
                                # エントリの内容のみを$outputに追加（空行を追加）
                                $output += "$specialEntry`r`n`r`n"
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
            # -Value パラメータを使用して明示的に書き込む（改行を保持）
            Set-Content -Path $OutputPath -Value $output -Force -Encoding UTF8
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

        # 最終的なレスポンスデータのログ出力
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
        Write-Host "[実行イベント完了] レスポンス情報:" -ForegroundColor Green
        Write-Host "  success: $true" -ForegroundColor Green
        Write-Host "  nodeCount: $buttonCount" -ForegroundColor Green
        Write-Host "  outputPath: $OutputPath" -ForegroundColor Green
        Write-Host "  output長: $($output.Length) 文字" -ForegroundColor Green
        Write-Host "  outputが空: $([string]::IsNullOrWhiteSpace($output))" -ForegroundColor Green
        if ($output.Length -gt 0) {
            Write-Host "  output先頭200文字: $($output.Substring(0, [Math]::Min(200, $output.Length)))" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ output が空です！" -ForegroundColor Yellow
        }
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green

        return @{
            success = $true
            message = "PowerShellコードを生成しました"
            code = $output
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
    循環参照を検出して無限ループを防止します。
    #>
    param (
        [string]$ノードリスト文字列,
        [System.Collections.Generic.HashSet[string]]$処理済みID = $null,
        [int]$再帰深度 = 0
    )

    # 最大再帰深度（無限ループ防止）
    $最大再帰深度 = 10
    if ($再帰深度 -ge $最大再帰深度) {
        Write-Host "[ノードリスト展開] ⚠️ 最大再帰深度 ($最大再帰深度) に達しました。循環参照の可能性があります。" -ForegroundColor Red
        return ""
    }

    # 処理済みIDセットを初期化（初回呼び出し時）
    if ($null -eq $処理済みID) {
        $処理済みID = New-Object 'System.Collections.Generic.HashSet[string]'
    }

    # デバッグモード（環境変数で制御）
    $DebugMode = $env:UIPOWERSHELL_DEBUG -eq "1"

    if ($DebugMode) {
        Write-Host "=== ノードリスト展開開始 (深度: $再帰深度) ===" -ForegroundColor Magenta
        Write-Host "入力: $ノードリスト文字列" -ForegroundColor Gray
    }

    # "AAAA" を除去
    $ノードリスト文字列 = $ノードリスト文字列 -replace "^AAAA\s*", ""

    # 行ごとに分割
    $lines = $ノードリスト文字列 -split "`r?`n" | Where-Object { $_.Trim() -ne "" }

    if ($DebugMode) {
        Write-Host "ノード数: $($lines.Count)" -ForegroundColor Gray
    }

    $output = ""

    foreach ($line in $lines) {
        # 形式: <ノードID>;<背景色>;<テキスト>;<GroupID>
        $parts = $line -split ";"
        if ($parts.Count -ge 1) {
            $nodeId = $parts[0].Trim()
            $nodeColor = if ($parts.Count -ge 2) { $parts[1].Trim() } else { "" }
            $nodeText = if ($parts.Count -ge 3) { $parts[2].Trim() } else { "" }

            Write-Host "[ノードリスト展開] 処理中: ID=$nodeId, 色=$nodeColor, テキスト=$nodeText (深度: $再帰深度)" -ForegroundColor Gray

            # 循環参照チェック
            if ($処理済みID.Contains($nodeId)) {
                Write-Host "[ノードリスト展開] ⚠️ 循環参照検出: ID=$nodeId は既に処理済み（スキップ）" -ForegroundColor Red
                continue
            }

            # 処理済みとしてマーク
            [void]$処理済みID.Add($nodeId)

            # このノードのエントリを取得（まずノードIDそのままで検索）
            $entry = IDでエントリを取得 -ID $nodeId

            # 見つからない場合は "-1" を追加して再検索
            if ([string]::IsNullOrWhiteSpace($entry)) {
                $nodeIdWithSuffix = "$nodeId-1"
                Write-Host "[ノードリスト展開] ID '$nodeId' で見つからない → '$nodeIdWithSuffix' で再検索" -ForegroundColor Yellow

                # 循環参照チェック（-1付きバージョン）
                if ($処理済みID.Contains($nodeIdWithSuffix)) {
                    Write-Host "[ノードリスト展開] ⚠️ 循環参照検出: ID=$nodeIdWithSuffix は既に処理済み（スキップ）" -ForegroundColor Red
                    continue
                }

                $entry = IDでエントリを取得 -ID $nodeIdWithSuffix
                if ($entry) {
                    $nodeId = $nodeIdWithSuffix
                    [void]$処理済みID.Add($nodeIdWithSuffix)
                    Write-Host "[ノードリスト展開] '$nodeIdWithSuffix' で見つかりました" -ForegroundColor Green
                }
            }

            if ($entry -ne $null -and $entry -ne "") {
                Write-Host "[ノードリスト展開] エントリ取得成功: $($entry.Substring(0, [Math]::Min(50, $entry.Length)))..." -ForegroundColor Gray

                # エントリが "AAAA" で始まる場合は再帰的に展開
                if ($entry -match "^AAAA") {
                    Write-Host "[ノードリスト展開] AAAA検出 → 再帰的に展開 (深度: $($再帰深度 + 1))" -ForegroundColor Magenta
                    $entry = ノードリストを展開 -ノードリスト文字列 $entry -処理済みID $処理済みID -再帰深度 ($再帰深度 + 1)
                }

                # 改行コードの正規化: LF → CRLF（既にCRLFの場合は保持）
                $entry = $entry -replace "`r`n", "<<CRLF>>" -replace "`n", "`r`n" -replace "<<CRLF>>", "`r`n"
                $output += "$entry`r`n"
            } else {
                # エントリが見つからない場合、Pinkノードなら警告を出すがスキップ
                if ($nodeColor -eq "Pink") {
                    Write-Host "[ノードリスト展開] ⚠️ Pinkノード '$nodeId' のエントリが見つかりません（スキップ）" -ForegroundColor Yellow
                } else {
                    Write-Host "[ノードリスト展開] ⚠️ エントリが見つかりません: $nodeId（スキップ）" -ForegroundColor Yellow
                }
            }
        }
    }

    if ($DebugMode) {
        Write-Host "=== ノードリスト展開完了 (深度: $再帰深度) ===" -ForegroundColor Magenta
    }
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

    $入力フォーム.Topmost = $true
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

    $入力フォーム.Topmost = $true
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
