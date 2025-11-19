# ================================================================
# 17_操作履歴管理.ps1
# ================================================================
# 責任: Undo/Redo機能の操作履歴管理
#
# 含まれる関数:
#   - Initialize-HistoryStack  : 操作履歴スタックの初期化
#   - Record-Operation        : 操作を記録
#   - Undo-Operation          : Undo実行
#   - Redo-Operation          : Redo実行
#   - Get-HistoryStatus       : 履歴状態取得
#   - Clear-HistoryStack      : 履歴クリア
#
# 作成日: 2025-11-19
# 目的: スナップショット機能を拡張してUndo/Redo機能を実装
# ================================================================

# グローバル変数
$global:操作履歴スタック = $null
$global:現在の履歴位置 = 0
$global:最大履歴数 = 50

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
                $global:操作履歴スタック = $historyData.履歴スタック
                $global:現在の履歴位置 = $historyData.現在の履歴位置
                $global:最大履歴数 = if ($historyData.最大履歴数) { $historyData.最大履歴数 } else { 50 }

                Write-Host "[操作履歴] 履歴を読み込みました: $($global:操作履歴スタック.Count)件" -ForegroundColor Cyan
            } else {
                # ファイルは存在するがデータが空
                $global:操作履歴スタック = @()
                $global:現在の履歴位置 = 0
                Write-Host "[操作履歴] 新規履歴スタックを作成しました" -ForegroundColor Green
            }
        } else {
            # 新規作成
            $global:操作履歴スタック = @()
            $global:現在の履歴位置 = 0

            $initialData = @{
                履歴スタック = @()
                現在の履歴位置 = 0
                最大履歴数 = $global:最大履歴数
            }

            Write-JsonSafe -Path $historyPath -Data $initialData -Depth 10 -Silent $false
            Write-Host "[操作履歴] 新規履歴ファイルを作成しました: $historyPath" -ForegroundColor Green
        }

        return @{
            success = $true
            count = $global:操作履歴スタック.Count
            position = $global:現在の履歴位置
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
操作を記録

.DESCRIPTION
ノード追加/削除/移動/更新などの操作を履歴スタックに記録。
Redo分岐を削除し、新しい操作を追加する。

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
        if ($null -eq $global:操作履歴スタック) {
            Initialize-HistoryStack -FolderPath $FolderPath | Out-Null
        }

        # 現在の位置より後ろの履歴を削除（Redo分岐を破棄）
        if ($global:現在の履歴位置 -lt $global:操作履歴スタック.Count) {
            $global:操作履歴スタック = $global:操作履歴スタック[0..($global:現在の履歴位置 - 1)]
            Write-Host "[操作履歴] Redo分岐を削除しました" -ForegroundColor Yellow
        }

        # 新しい操作を追加
        $operation = @{
            操作ID = [guid]::NewGuid().ToString()
            操作タイプ = $OperationType
            説明 = $Description
            タイムスタンプ = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            memory_before = $MemoryBefore
            memory_after = $MemoryAfter
            code_before = $CodeBefore
            code_after = $CodeAfter
        }

        $global:操作履歴スタック += $operation
        $global:現在の履歴位置 = $global:操作履歴スタック.Count

        # 最大履歴数を超えた場合は古い履歴を削除
        if ($global:操作履歴スタック.Count -gt $global:最大履歴数) {
            $削除数 = $global:操作履歴スタック.Count - $global:最大履歴数
            $global:操作履歴スタック = $global:操作履歴スタック[$削除数..($global:操作履歴スタック.Count - 1)]
            $global:現在の履歴位置 = $global:操作履歴スタック.Count
            Write-Host "[操作履歴] 古い履歴 $削除数 件を削除しました" -ForegroundColor Yellow
        }

        # history.jsonに保存
        $historyPath = Join-Path $FolderPath 'history.json'
        $historyData = @{
            履歴スタック = $global:操作履歴スタック
            現在の履歴位置 = $global:現在の履歴位置
            最大履歴数 = $global:最大履歴数
        }

        Write-JsonSafe -Path $historyPath -Data $historyData -Depth 10 -Silent $true

        Write-Host "[操作履歴] 操作を記録: $Description (位置: $global:現在の履歴位置)" -ForegroundColor Green

        return @{
            success = $true
            operationId = $operation.操作ID
            position = $global:現在の履歴位置
            count = $global:操作履歴スタック.Count
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
Undo実行（操作を戻す）

.DESCRIPTION
操作履歴スタックから1つ前の状態に戻す。
memory.jsonとコード.jsonを復元する。

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
        # 履歴スタックが未初期化の場合は初期化
        if ($null -eq $global:操作履歴スタック) {
            Initialize-HistoryStack -FolderPath $FolderPath | Out-Null
        }

        # Undo可能かチェック
        if ($global:現在の履歴位置 -le 0) {
            Write-Host "[操作履歴] これ以上Undoできません" -ForegroundColor Yellow
            return @{
                success = $false
                error = "Undo不可: 履歴の最初です"
                canUndo = $false
                canRedo = $global:現在の履歴位置 -lt $global:操作履歴スタック.Count
            }
        }

        # 1つ前の操作を取得
        $現在の操作 = $global:操作履歴スタック[$global:現在の履歴位置 - 1]

        # 操作前の状態に復元
        $memoryPath = Join-Path $FolderPath 'memory.json'
        $codePath = Join-Path $FolderPath 'コード.json'

        # memory.jsonを復元
        if ($現在の操作.memory_before) {
            Write-JsonSafe -Path $memoryPath -Data $現在の操作.memory_before -Depth 10 -Silent $true
            Write-Host "[操作履歴] memory.jsonを復元しました" -ForegroundColor Cyan
        }

        # コード.jsonを復元（存在する場合）
        if ($現在の操作.code_before) {
            Write-JsonSafe -Path $codePath -Data $現在の操作.code_before -Depth 10 -Silent $true
            Write-Host "[操作履歴] コード.jsonを復元しました" -ForegroundColor Cyan
        }

        # 履歴位置を1つ戻す
        $global:現在の履歴位置--

        # history.jsonを更新
        $historyPath = Join-Path $FolderPath 'history.json'
        $historyData = @{
            履歴スタック = $global:操作履歴スタック
            現在の履歴位置 = $global:現在の履歴位置
            最大履歴数 = $global:最大履歴数
        }
        Write-JsonSafe -Path $historyPath -Data $historyData -Depth 10 -Silent $true

        Write-Host "[操作履歴] Undo実行: $($現在の操作.説明) (位置: $global:現在の履歴位置)" -ForegroundColor Green

        return @{
            success = $true
            operation = @{
                type = $現在の操作.操作タイプ
                description = $現在の操作.説明
                timestamp = $現在の操作.タイムスタンプ
            }
            position = $global:現在の履歴位置
            canUndo = $global:現在の履歴位置 -gt 0
            canRedo = $global:現在の履歴位置 -lt $global:操作履歴スタック.Count
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
        # 履歴スタックが未初期化の場合は初期化
        if ($null -eq $global:操作履歴スタック) {
            Initialize-HistoryStack -FolderPath $FolderPath | Out-Null
        }

        # Redo可能かチェック
        if ($global:現在の履歴位置 -ge $global:操作履歴スタック.Count) {
            Write-Host "[操作履歴] これ以上Redoできません" -ForegroundColor Yellow
            return @{
                success = $false
                error = "Redo不可: 履歴の最後です"
                canUndo = $global:現在の履歴位置 -gt 0
                canRedo = $false
            }
        }

        # 次の操作を取得
        $次の操作 = $global:操作履歴スタック[$global:現在の履歴位置]

        # 操作後の状態に復元
        $memoryPath = Join-Path $FolderPath 'memory.json'
        $codePath = Join-Path $FolderPath 'コード.json'

        # memory.jsonを復元
        if ($次の操作.memory_after) {
            Write-JsonSafe -Path $memoryPath -Data $次の操作.memory_after -Depth 10 -Silent $true
            Write-Host "[操作履歴] memory.jsonを復元しました" -ForegroundColor Cyan
        }

        # コード.jsonを復元（存在する場合）
        if ($次の操作.code_after) {
            Write-JsonSafe -Path $codePath -Data $次の操作.code_after -Depth 10 -Silent $true
            Write-Host "[操作履歴] コード.jsonを復元しました" -ForegroundColor Cyan
        }

        # 履歴位置を1つ進める
        $global:現在の履歴位置++

        # history.jsonを更新
        $historyPath = Join-Path $FolderPath 'history.json'
        $historyData = @{
            履歴スタック = $global:操作履歴スタック
            現在の履歴位置 = $global:現在の履歴位置
            最大履歴数 = $global:最大履歴数
        }
        Write-JsonSafe -Path $historyPath -Data $historyData -Depth 10 -Silent $true

        Write-Host "[操作履歴] Redo実行: $($次の操作.説明) (位置: $global:現在の履歴位置)" -ForegroundColor Green

        return @{
            success = $true
            operation = @{
                type = $次の操作.操作タイプ
                description = $次の操作.説明
                timestamp = $次の操作.タイムスタンプ
            }
            position = $global:現在の履歴位置
            canUndo = $global:現在の履歴位置 -gt 0
            canRedo = $global:現在の履歴位置 -lt $global:操作履歴スタック.Count
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
        # 履歴スタックが未初期化の場合は初期化
        if ($null -eq $global:操作履歴スタック) {
            Initialize-HistoryStack -FolderPath $FolderPath | Out-Null
        }

        $canUndo = $global:現在の履歴位置 -gt 0
        $canRedo = $global:現在の履歴位置 -lt $global:操作履歴スタック.Count

        # 直近の操作履歴（最大5件）
        $recentOperations = @()
        $startIndex = [Math]::Max(0, $global:現在の履歴位置 - 5)
        $endIndex = [Math]::Min($global:操作履歴スタック.Count - 1, $global:現在の履歴位置 - 1)

        if ($startIndex -le $endIndex) {
            for ($i = $startIndex; $i -le $endIndex; $i++) {
                $op = $global:操作履歴スタック[$i]
                $recentOperations += @{
                    type = $op.操作タイプ
                    description = $op.説明
                    timestamp = $op.タイムスタンプ
                }
            }
        }

        return @{
            success = $true
            canUndo = $canUndo
            canRedo = $canRedo
            position = $global:現在の履歴位置
            totalCount = $global:操作履歴スタック.Count
            maxCount = $global:最大履歴数
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
        $global:操作履歴スタック = @()
        $global:現在の履歴位置 = 0

        # history.jsonをクリア
        $historyPath = Join-Path $FolderPath 'history.json'
        $historyData = @{
            履歴スタック = @()
            現在の履歴位置 = 0
            最大履歴数 = $global:最大履歴数
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
