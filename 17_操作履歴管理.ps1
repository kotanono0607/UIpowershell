# ================================================================
# 17_操作履歴管理.ps1
# ================================================================
# 責任: Undo/Redo機能の操作履歴管理
#
# 含まれる関数:
#   - Initialize-HistoryStack  : 操作履歴スタックの初期化
#   - Record-Operation        : 操作を記録（差分保存方式）
#   - Undo-Operation          : Undo実行（差分復元方式）
#   - Redo-Operation          : Redo実行（差分復元方式）
#   - Get-HistoryStatus       : 履歴状態取得
#   - Clear-HistoryStack      : 履歴クリア
#
# 作成日: 2025-11-19
# 更新日: 2025-11-29
# 目的: スナップショット機能を拡張してUndo/Redo機能を実装
# 変更: 差分保存方式に変更（ファイルサイズ大幅削減）
# ================================================================

# グローバル変数
$global:HistoryStack = $null
$global:CurrentHistoryPosition = 0
$global:MaxHistoryCount = 50

<#
.SYNOPSIS
操作履歴スタックを初期化

.DESCRIPTION
history.jsonが存在する場合は読み込み、存在しない場合は新規作成。
セッション開始時に1回だけ呼び出す。

.PARAMETER FolderPath
プロジェクトフォルダのパス（03_history/{プロジェクト名}/）

.EXAMPLE
Initialize-HistoryStack -FolderPath "C:\UIpowershell\03_history\AAAAAA111"
#>
function Initialize-HistoryStack {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FolderPath
    )

    try {
        $historyPath = Join-Path $FolderPath 'history.json'

        if (Test-Path $historyPath) {
            # 既存の履歴を読み込み
            $historyData = Read-JsonSafe -Path $historyPath -Required $false -Silent $true

            if ($historyData) {
                $global:HistoryStack = $historyData.HistoryStack
                $global:CurrentHistoryPosition = $historyData.CurrentHistoryPosition
                $global:MaxHistoryCount = if ($historyData.MaxHistoryCount) { $historyData.MaxHistoryCount } else { 50 }

                Write-Host "[操作履歴] 履歴を読み込みました: $($global:HistoryStack.Count)件" -ForegroundColor Cyan
            } else {
                # ファイルは存在するがデータが空
                $global:HistoryStack = @()
                $global:CurrentHistoryPosition = 0
                Write-Host "[操作履歴] 新規履歴スタックを作成しました" -ForegroundColor Green
            }
        } else {
            # 新規作成
            $global:HistoryStack = @()
            $global:CurrentHistoryPosition = 0

            $initialData = @{
                HistoryStack = @()
                CurrentHistoryPosition = 0
                MaxHistoryCount = $global:MaxHistoryCount
            }

            Write-JsonSafe -Path $historyPath -Data $initialData -Depth 10 -Silent $false
            Write-Host "[操作履歴] 新規履歴ファイルを作成しました: $historyPath" -ForegroundColor Green
        }

        return @{
            success = $true
            count = $global:HistoryStack.Count
            position = $global:CurrentHistoryPosition
        }

    } catch {
        Write-Error "[操作履歴] 初期化エラー: $_"
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}


<#
.SYNOPSIS
操作を記録（差分保存方式）

.DESCRIPTION
ノード追加/削除/移動/更新などの操作を履歴スタックに記録。
Redo分岐を削除し、新しい操作を追加する。
【改善】全体スナップショットではなく、変更されたレイヤーのみを保存してファイルサイズを削減。

.PARAMETER FolderPath
プロジェクトフォルダのパス

.PARAMETER OperationType
操作タイプ（NodeAdd, NodeDelete, NodeMove, NodeUpdate, CodeUpdate）

.PARAMETER Description
操作の説明（例: "ノード215-1を追加"）

.PARAMETER MemoryBefore
操作前のmemory.jsonのスナップショット

.PARAMETER MemoryAfter
操作後のmemory.jsonのスナップショット

.PARAMETER CodeBefore
操作前のコード.jsonのスナップショット（オプション）

.PARAMETER CodeAfter
操作後のコード.jsonのスナップショット（オプション）

.EXAMPLE
Record-Operation -FolderPath $global:folderPath -OperationType "NodeAdd" -Description "ノード215-1を追加" -MemoryBefore $memBefore -MemoryAfter $memAfter
#>
function Record-Operation {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FolderPath,

        [Parameter(Mandatory=$true)]
        [ValidateSet("NodeAdd", "NodeDelete", "NodeMove", "NodeUpdate", "CodeUpdate", "Other")]
        [string]$OperationType,

        [Parameter(Mandatory=$true)]
        [string]$Description,

        [Parameter(Mandatory=$false)]
        [object]$MemoryBefore = $null,

        [Parameter(Mandatory=$false)]
        [object]$MemoryAfter = $null,

        [Parameter(Mandatory=$false)]
        [object]$CodeBefore = $null,

        [Parameter(Mandatory=$false)]
        [object]$CodeAfter = $null
    )

    try {
        # 履歴スタックが未初期化の場合は初期化
        if ($null -eq $global:HistoryStack) {
            Initialize-HistoryStack -FolderPath $FolderPath | Out-Null
        }

        # 現在の位置より後ろの履歴を削除（Redo分岐を破棄）
        if ($global:CurrentHistoryPosition -lt $global:HistoryStack.Count) {
            $global:HistoryStack = $global:HistoryStack[0..($global:CurrentHistoryPosition - 1)]
            Write-Host "[操作履歴] Redo分岐を削除しました" -ForegroundColor Yellow
        }

        # ===== 差分抽出処理 =====
        $affectedLayers = @()
        $layerDiffs = @{}

        Write-Host "[Record Debug] MemoryBefore is null: $($null -eq $MemoryBefore)" -ForegroundColor Magenta
        Write-Host "[Record Debug] MemoryAfter is null: $($null -eq $MemoryAfter)" -ForegroundColor Magenta
        if ($MemoryBefore) {
            Write-Host "[Record Debug] MemoryBefore type: $($MemoryBefore.GetType().FullName)" -ForegroundColor Magenta
        }
        if ($MemoryAfter) {
            Write-Host "[Record Debug] MemoryAfter type: $($MemoryAfter.GetType().FullName)" -ForegroundColor Magenta
        }

        if ($MemoryBefore -and $MemoryAfter) {
            Write-Host "[Record Debug] 差分抽出処理を開始" -ForegroundColor Magenta
            # MemoryBeforeとMemoryAfterを比較して、変更されたレイヤーを特定
            # レイヤーキーは "1", "2", "3", "4", "5", "6" のみを対象とする
            $validLayerKeys = @("1", "2", "3", "4", "5", "6")
            $allLayerKeys = @()

            foreach ($key in $validLayerKeys) {
                # PSObjectの場合
                if ($MemoryBefore.PSObject.Properties[$key] -or $MemoryAfter.PSObject.Properties[$key]) {
                    $allLayerKeys += $key
                }
                # Hashtable/OrderedDictionaryの場合（IDictionaryインターフェースで両方をカバー）
                elseif (($MemoryBefore -is [System.Collections.IDictionary] -and $MemoryBefore.ContainsKey($key)) -or
                        ($MemoryAfter -is [System.Collections.IDictionary] -and $MemoryAfter.ContainsKey($key))) {
                    $allLayerKeys += $key
                }
            }
            $allLayerKeys = $allLayerKeys | Select-Object -Unique

            foreach ($layerKey in $allLayerKeys) {
                $beforeLayer = $null
                $afterLayer = $null

                # PSObject、Hashtable、OrderedDictionaryの全てに対応
                if ($MemoryBefore -is [System.Collections.IDictionary]) {
                    if ($MemoryBefore.ContainsKey($layerKey)) {
                        $beforeLayer = $MemoryBefore[$layerKey]
                    }
                } elseif ($MemoryBefore.PSObject.Properties[$layerKey]) {
                    $beforeLayer = $MemoryBefore.$layerKey
                }

                if ($MemoryAfter -is [System.Collections.IDictionary]) {
                    if ($MemoryAfter.ContainsKey($layerKey)) {
                        $afterLayer = $MemoryAfter[$layerKey]
                    }
                } elseif ($MemoryAfter.PSObject.Properties[$layerKey]) {
                    $afterLayer = $MemoryAfter.$layerKey
                }

                # レイヤーが変更されたかチェック（簡易比較：JSON文字列化して比較）
                $beforeJson = if ($beforeLayer) { $beforeLayer | ConvertTo-Json -Depth 5 -Compress } else { "" }
                $afterJson = if ($afterLayer) { $afterLayer | ConvertTo-Json -Depth 5 -Compress } else { "" }

                if ($beforeJson -ne $afterJson) {
                    $affectedLayers += $layerKey
                    $layerDiffs[$layerKey] = @{
                        before = $beforeLayer
                        after = $afterLayer
                    }
                }
            }

            Write-Host "[操作履歴] 変更されたレイヤー: $($affectedLayers -join ', ')" -ForegroundColor Cyan
        }

        # コード差分も同様に処理
        $codeDiff = $null
        if ($CodeBefore -or $CodeAfter) {
            $codeDiff = @{
                before = $CodeBefore
                after = $CodeAfter
            }
        }

        # 新しい操作を追加（差分のみ保存）
        $operation = @{
            operationId = [guid]::NewGuid().ToString()
            operationType = $OperationType
            description = $Description
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            # 差分保存方式のフィールド
            affectedLayers = $affectedLayers
            layerDiffs = $layerDiffs
            codeDiff = $codeDiff
            # 旧フィールドは削除（互換性のためnullを設定）
            memory_before = $null
            memory_after = $null
            code_before = $null
            code_after = $null
        }

        $global:HistoryStack += $operation
        $global:CurrentHistoryPosition = $global:HistoryStack.Count

        # 最大履歴数を超えた場合は古い履歴を削除
        if ($global:HistoryStack.Count -gt $global:MaxHistoryCount) {
            $deleteCount = $global:HistoryStack.Count - $global:MaxHistoryCount
            $global:HistoryStack = $global:HistoryStack[$deleteCount..($global:HistoryStack.Count - 1)]
            $global:CurrentHistoryPosition = $global:HistoryStack.Count
            Write-Host "[操作履歴] 古い履歴 $deleteCount 件を削除しました" -ForegroundColor Yellow
        }

        # history.jsonに保存
        $historyPath = Join-Path $FolderPath 'history.json'
        $historyData = @{
            HistoryStack = $global:HistoryStack
            CurrentHistoryPosition = $global:CurrentHistoryPosition
            MaxHistoryCount = $global:MaxHistoryCount
            version = 2  # 差分保存方式のバージョン
        }

        Write-JsonSafe -Path $historyPath -Data $historyData -Depth 10 -Silent $true

        Write-Host "[操作履歴] 操作を記録: $Description (位置: $global:CurrentHistoryPosition, 影響レイヤー: $($affectedLayers.Count))" -ForegroundColor Green

        return @{
            success = $true
            operationId = $operation.operationId
            position = $global:CurrentHistoryPosition
            count = $global:HistoryStack.Count
            affectedLayers = $affectedLayers
        }

    } catch {
        Write-Error "[操作履歴] 記録エラー: $_"
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}


<#
.SYNOPSIS
Undo実行（操作を戻す）- 差分復元方式

.DESCRIPTION
操作履歴スタックから1つ前の状態に戻す。
【改善】差分データを使用して、変更されたレイヤーのみを復元する。
旧形式（全体スナップショット）との互換性も維持。

.PARAMETER FolderPath
プロジェクトフォルダのパス

.EXAMPLE
$result = Undo-Operation -FolderPath $global:folderPath
#>
function Undo-Operation {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FolderPath
    )

    try {
        # Pode Runspace分離対策: 毎回history.jsonを直接読み込む
        $historyPath = Join-Path $FolderPath 'history.json'

        if (-not (Test-Path $historyPath)) {
            Write-Host "[操作履歴] history.jsonが見つかりません" -ForegroundColor Yellow
            return @{
                success = $false
                error = "履歴ファイルが見つかりません"
                canUndo = $false
                canRedo = $false
            }
        }

        # history.jsonを直接読み込み
        $historyData = Read-JsonSafe -Path $historyPath -Required $false -Silent $true

        if ($null -eq $historyData) {
            return @{
                success = $false
                error = "履歴データが読み込めません"
                canUndo = $false
                canRedo = $false
            }
        }

        $historyStack = $historyData.HistoryStack
        $currentPosition = $historyData.CurrentHistoryPosition
        $maxCount = if ($historyData.MaxHistoryCount) { $historyData.MaxHistoryCount } else { 50 }
        $historyVersion = if ($historyData.version) { $historyData.version } else { 1 }

        # Undo可能かチェック
        if ($currentPosition -le 0) {
            Write-Host "[操作履歴] これ以上Undoできません" -ForegroundColor Yellow
            return @{
                success = $false
                error = "Undo不可: 履歴の最初です"
                canUndo = $false
                canRedo = $currentPosition -lt $historyStack.Count
            }
        }

        # 1つ前の操作を取得
        $currentOp = $historyStack[$currentPosition - 1]

        # 操作前の状態に復元
        $memoryPath = Join-Path $FolderPath 'memory.json'
        $codePath = Join-Path $FolderPath 'コード.json'

        # ===== 差分復元処理（v2形式） =====
        if ($currentOp.layerDiffs -and $currentOp.affectedLayers) {
            # 現在のmemory.jsonを読み込み
            $currentMemory = Read-JsonSafe -Path $memoryPath -Required $false -Silent $true

            if ($currentMemory) {
                # 影響を受けたレイヤーのみを復元
                foreach ($layerKey in $currentOp.affectedLayers) {
                    # レイヤーキーを文字列に変換（数値の場合Add-Memberでエラーになるため）
                    $layerKeyStr = [string]$layerKey
                    if ($currentOp.layerDiffs.$layerKeyStr) {
                        $beforeData = $currentOp.layerDiffs.$layerKeyStr.before
                        if ($null -ne $beforeData) {
                            # デバッグ: beforeデータの内容を確認
                            $nodeCount = if ($beforeData.構成) { $beforeData.構成.Count } else { 0 }
                            Write-Host "[Undo Debug] Layer $layerKeyStr : beforeデータに $nodeCount 個のノード" -ForegroundColor Cyan

                            # beforeデータの最初のノードのIDを確認
                            if ($nodeCount -gt 0) {
                                $firstNode = $beforeData.構成[0]
                                $hasId = $firstNode.PSObject.Properties['ID'] -ne $null
                                $idValue = if ($hasId) { $firstNode.ID } else { "(IDフィールドなし)" }
                                Write-Host "[Undo Debug]   -> 最初のノードID: $idValue" -ForegroundColor Cyan
                            }

                            # 直接プロパティを設定（Add-Memberを使わない）
                            $currentMemory.$layerKeyStr = $beforeData
                        } else {
                            Write-Host "[Undo Debug] Layer $layerKeyStr : beforeデータがnullのため、レイヤーを削除" -ForegroundColor Yellow
                            # beforeがnullの場合、そのレイヤーを削除（新規追加されたレイヤーのUndo）
                            $currentMemory.PSObject.Properties.Remove($layerKeyStr)
                        }
                    }
                }

                Write-JsonSafe -Path $memoryPath -Data $currentMemory -Depth 10 -Silent $true | Out-Null
                Write-Host "[操作履歴] memory.jsonを差分復元しました (レイヤー: $($currentOp.affectedLayers -join ', '))" -ForegroundColor Cyan
            }

            # コード差分の復元
            if ($currentOp.codeDiff -and $currentOp.codeDiff.before) {
                Write-JsonSafe -Path $codePath -Data $currentOp.codeDiff.before -Depth 10 -Silent $true | Out-Null
                Write-Host "[操作履歴] コード.jsonを差分復元しました" -ForegroundColor Cyan
            }
        }
        # ===== 旧形式（v1形式）との互換性 =====
        elseif ($currentOp.memory_before) {
            Write-JsonSafe -Path $memoryPath -Data $currentOp.memory_before -Depth 10 -Silent $true | Out-Null
            Write-Host "[操作履歴] memory.jsonを復元しました (旧形式)" -ForegroundColor Cyan

            if ($currentOp.code_before) {
                Write-JsonSafe -Path $codePath -Data $currentOp.code_before -Depth 10 -Silent $true | Out-Null
                Write-Host "[操作履歴] コード.jsonを復元しました (旧形式)" -ForegroundColor Cyan
            }
        }

        # 履歴位置を1つ戻す
        $currentPosition--

        # history.jsonを更新
        $updatedHistoryData = @{
            HistoryStack = $historyStack
            CurrentHistoryPosition = $currentPosition
            MaxHistoryCount = $maxCount
            version = $historyVersion
        }
        Write-JsonSafe -Path $historyPath -Data $updatedHistoryData -Depth 10 -Silent $true | Out-Null

        Write-Host "[操作履歴] Undo実行: $($currentOp.description) (位置: $currentPosition)" -ForegroundColor Green

        return @{
            success = $true
            operation = @{
                type = $currentOp.operationType
                description = $currentOp.description
                timestamp = $currentOp.timestamp
            }
            position = $currentPosition
            canUndo = $currentPosition -gt 0
            canRedo = $currentPosition -lt $historyStack.Count
        }

    } catch {
        Write-Error "[操作履歴] Undoエラー: $_"
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}


<#
.SYNOPSIS
Redo実行（操作をやり直す）

.DESCRIPTION
操作履歴スタックから1つ先の状態に進める。
memory.jsonとコード.jsonを復元する。

.PARAMETER FolderPath
プロジェクトフォルダのパス

.EXAMPLE
$result = Redo-Operation -FolderPath $global:folderPath
#>
function Redo-Operation {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FolderPath
    )

    try {
        # Pode Runspace分離対策: 毎回history.jsonを直接読み込む
        $historyPath = Join-Path $FolderPath 'history.json'

        if (-not (Test-Path $historyPath)) {
            Write-Host "[操作履歴] history.jsonが見つかりません" -ForegroundColor Yellow
            return @{
                success = $false
                error = "履歴ファイルが見つかりません"
                canUndo = $false
                canRedo = $false
            }
        }

        # history.jsonを直接読み込み
        $historyData = Read-JsonSafe -Path $historyPath -Required $false -Silent $true

        if ($null -eq $historyData) {
            return @{
                success = $false
                error = "履歴データが読み込めません"
                canUndo = $false
                canRedo = $false
            }
        }

        $historyStack = $historyData.HistoryStack
        $currentPosition = $historyData.CurrentHistoryPosition
        $maxCount = if ($historyData.MaxHistoryCount) { $historyData.MaxHistoryCount } else { 50 }

        # Redo可能かチェック
        if ($currentPosition -ge $historyStack.Count) {
            Write-Host "[操作履歴] これ以上Redoできません" -ForegroundColor Yellow
            return @{
                success = $false
                error = "Redo不可: 履歴の最後です"
                canUndo = $currentPosition -gt 0
                canRedo = $false
            }
        }

        # 次の操作を取得
        $nextOp = $historyStack[$currentPosition]

        # 操作後の状態に復元
        $memoryPath = Join-Path $FolderPath 'memory.json'
        $codePath = Join-Path $FolderPath 'コード.json'

        # ===== 差分復元処理（v2形式） =====
        if ($nextOp.layerDiffs -and $nextOp.affectedLayers) {
            # 現在のmemory.jsonを読み込み
            $currentMemory = Read-JsonSafe -Path $memoryPath -Required $false -Silent $true

            if ($currentMemory) {
                # 影響を受けたレイヤーのみを復元
                foreach ($layerKey in $nextOp.affectedLayers) {
                    # レイヤーキーを文字列に変換（数値の場合Add-Memberでエラーになるため）
                    $layerKeyStr = [string]$layerKey
                    if ($nextOp.layerDiffs.$layerKeyStr) {
                        $afterData = $nextOp.layerDiffs.$layerKeyStr.after
                        if ($null -ne $afterData) {
                            # デバッグ: afterデータの内容を確認
                            $nodeCount = if ($afterData.構成) { $afterData.構成.Count } else { 0 }
                            Write-Host "[Redo Debug] Layer $layerKeyStr : afterデータに $nodeCount 個のノード" -ForegroundColor Magenta

                            # afterデータの最初のノードのIDを確認
                            if ($nodeCount -gt 0) {
                                $firstNode = $afterData.構成[0]
                                $hasId = $firstNode.PSObject.Properties['ID'] -ne $null
                                $idValue = if ($hasId) { $firstNode.ID } else { "(IDフィールドなし)" }
                                Write-Host "[Redo Debug]   -> 最初のノードID: $idValue" -ForegroundColor Magenta
                            }

                            # 直接プロパティを設定（Add-Memberを使わない）
                            $currentMemory.$layerKeyStr = $afterData
                        } else {
                            Write-Host "[Redo Debug] Layer $layerKeyStr : afterデータがnullのため、レイヤーを削除" -ForegroundColor Yellow
                            # afterがnullの場合、そのレイヤーを削除（削除されたレイヤーのRedo）
                            $currentMemory.PSObject.Properties.Remove($layerKeyStr)
                        }
                    }
                }

                Write-JsonSafe -Path $memoryPath -Data $currentMemory -Depth 10 -Silent $true | Out-Null
                Write-Host "[操作履歴] memory.jsonを差分復元しました (レイヤー: $($nextOp.affectedLayers -join ', '))" -ForegroundColor Cyan
            }

            # コード差分の復元
            if ($nextOp.codeDiff -and $nextOp.codeDiff.after) {
                Write-JsonSafe -Path $codePath -Data $nextOp.codeDiff.after -Depth 10 -Silent $true | Out-Null
                Write-Host "[操作履歴] コード.jsonを差分復元しました" -ForegroundColor Cyan
            }
        }
        # ===== 旧形式（v1形式）との互換性 =====
        elseif ($nextOp.memory_after) {
            Write-JsonSafe -Path $memoryPath -Data $nextOp.memory_after -Depth 10 -Silent $true | Out-Null
            Write-Host "[操作履歴] memory.jsonを復元しました (旧形式)" -ForegroundColor Cyan

            if ($nextOp.code_after) {
                Write-JsonSafe -Path $codePath -Data $nextOp.code_after -Depth 10 -Silent $true | Out-Null
                Write-Host "[操作履歴] コード.jsonを復元しました (旧形式)" -ForegroundColor Cyan
            }
        }

        # 履歴位置を1つ進める
        $currentPosition++

        # history.jsonを更新
        $updatedHistoryData = @{
            HistoryStack = $historyStack
            CurrentHistoryPosition = $currentPosition
            MaxHistoryCount = $maxCount
        }
        Write-JsonSafe -Path $historyPath -Data $updatedHistoryData -Depth 10 -Silent $true | Out-Null

        Write-Host "[操作履歴] Redo実行: $($nextOp.description) (位置: $currentPosition)" -ForegroundColor Green

        return @{
            success = $true
            operation = @{
                type = $nextOp.operationType
                description = $nextOp.description
                timestamp = $nextOp.timestamp
            }
            position = $currentPosition
            canUndo = $currentPosition -gt 0
            canRedo = $currentPosition -lt $historyStack.Count
        }

    } catch {
        Write-Error "[操作履歴] Redoエラー: $_"
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}


<#
.SYNOPSIS
履歴状態を取得

.DESCRIPTION
現在の履歴状態（Undo/Redo可能かどうか、履歴数など）を取得。
UIのボタン有効/無効制御に使用。

.PARAMETER FolderPath
プロジェクトフォルダのパス

.EXAMPLE
$status = Get-HistoryStatus -FolderPath $global:folderPath
#>
function Get-HistoryStatus {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FolderPath
    )

    try {
        # Pode Runspace分離対策: 毎回history.jsonを直接読み込む
        $historyPath = Join-Path $FolderPath 'history.json'

        if (-not (Test-Path $historyPath)) {
            # history.jsonが存在しない場合は新規作成
            Initialize-HistoryStack -FolderPath $FolderPath | Out-Null
        }

        # history.jsonを直接読み込み（$global変数に依存しない）
        $historyData = Read-JsonSafe -Path $historyPath -Required $false -Silent $true

        if ($null -eq $historyData) {
            # データが空の場合
            return @{
                success = $true
                canUndo = $false
                canRedo = $false
                position = 0
                totalCount = 0
                maxCount = 50
                recentOperations = @()
            }
        }

        $historyStack = $historyData.HistoryStack
        $currentPosition = $historyData.CurrentHistoryPosition
        $maxCount = if ($historyData.MaxHistoryCount) { $historyData.MaxHistoryCount } else { 50 }

        $canUndo = $currentPosition -gt 0
        $canRedo = $currentPosition -lt $historyStack.Count

        # 直近の操作履歴（最大5件）
        $recentOperations = @()
        $startIndex = [Math]::Max(0, $currentPosition - 5)
        $endIndex = [Math]::Min($historyStack.Count - 1, $currentPosition - 1)

        if ($startIndex -le $endIndex) {
            for ($i = $startIndex; $i -le $endIndex; $i++) {
                $op = $historyStack[$i]
                $recentOperations += @{
                    type = $op.operationType
                    description = $op.description
                    timestamp = $op.timestamp
                }
            }
        }

        return @{
            success = $true
            canUndo = $canUndo
            canRedo = $canRedo
            position = $currentPosition
            totalCount = $historyStack.Count
            maxCount = $maxCount
            recentOperations = $recentOperations
        }

    } catch {
        Write-Error "[操作履歴] 状態取得エラー: $_"
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}


<#
.SYNOPSIS
履歴スタックをクリア

.DESCRIPTION
すべての操作履歴を削除し、履歴位置を0にリセット。

.PARAMETER FolderPath
プロジェクトフォルダのパス

.EXAMPLE
Clear-HistoryStack -FolderPath $global:folderPath
#>
function Clear-HistoryStack {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FolderPath
    )

    try {
        $global:HistoryStack = @()
        $global:CurrentHistoryPosition = 0

        # history.jsonをクリア
        $historyPath = Join-Path $FolderPath 'history.json'
        $historyData = @{
            HistoryStack = @()
            CurrentHistoryPosition = 0
            MaxHistoryCount = $global:MaxHistoryCount
        }

        Write-JsonSafe -Path $historyPath -Data $historyData -Depth 10 -Silent $false

        Write-Host "[操作履歴] 履歴をクリアしました" -ForegroundColor Green

        return @{
            success = $true
            message = "履歴をクリアしました"
        }

    } catch {
        Write-Error "[操作履歴] クリアエラー: $_"
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}


# ================================================================
# エクスポート（モジュールとして使用する場合）
# ================================================================

# Export-ModuleMember -Function Initialize-HistoryStack, Record-Operation, Undo-Operation, Redo-Operation, Get-HistoryStatus, Clear-HistoryStack
