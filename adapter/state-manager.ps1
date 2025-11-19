# ============================================
# adapter/state-manager.ps1
# グローバル状態管理
# ============================================
# 役割：セッション状態、ノード配列、プロジェクト情報の一元管理
# アーキテクチャ：Singleton パターン
# ============================================

# ============================================
# グローバル状態の初期化
# ============================================

if (-not $global:UIpowershellState) {
    $global:UIpowershellState = @{
        # セッション情報
        SessionId = [Guid]::NewGuid().ToString()
        StartTime = Get-Date

        # プロジェクト情報
        CurrentProject = @{
            FolderPath = $null
            FolderName = $null
            JSONPath = $null
            HistoryPath = $null
        }

        # ノード配列（React Flowの状態を同期）
        Nodes = @()

        # エッジ配列（React Flowの状態を同期）
        Edges = @()

        # 変数管理
        Variables = @{}

        # コードIDストア
        CodeStore = @{}

        # 設定
        Settings = @{
            AutoSave = $true
            Debug = $false
        }
    }

    Write-Host "[OK] UIpowershell状態を初期化しました (SessionId: $($global:UIpowershellState.SessionId))" -ForegroundColor Green
}


# ============================================
# セッション管理関数
# ============================================

function Get-SessionInfo {
    <#
    .SYNOPSIS
    現在のセッション情報を取得
    #>
    return @{
        success = $true
        sessionId = $global:UIpowershellState.SessionId
        startTime = $global:UIpowershellState.StartTime
        uptime = (Get-Date) - $global:UIpowershellState.StartTime
        currentProject = $global:UIpowershellState.CurrentProject
    }
}


function Reset-Session {
    <#
    .SYNOPSIS
    セッションをリセット（デバッグ用）
    #>
    $global:UIpowershellState.Nodes = @()
    $global:UIpowershellState.Edges = @()
    $global:UIpowershellState.Variables = @{}
    $global:UIpowershellState.CodeStore = @{}

    return @{
        success = $true
        message = "セッションをリセットしました"
        sessionId = $global:UIpowershellState.SessionId
    }
}


# ============================================
# プロジェクト管理関数
# ============================================

function Get-CurrentProject {
    <#
    .SYNOPSIS
    現在のプロジェクト情報を取得
    #>
    return @{
        success = $true
        project = $global:UIpowershellState.CurrentProject
    }
}


function Get-CurrentFolderPath {
    <#
    .SYNOPSIS
    現在のプロジェクトフォルダパスを取得

    .DESCRIPTION
    グローバル変数 $global:folderPath を返します。
    設定されていない場合はデフォルトパスを返します。
    #>

    # $global:folderPath が設定されている場合はそれを返す
    if ($global:folderPath) {
        return $global:folderPath
    }

    # UIpowershellState からも取得を試みる
    if ($global:UIpowershellState.CurrentProject.FolderPath) {
        return $global:UIpowershellState.CurrentProject.FolderPath
    }

    # どちらも設定されていない場合はデフォルトパスを返す
    # $PSScriptRoot は adapter/ ディレクトリなので、親ディレクトリがプロジェクトルート
    $rootDir = Split-Path -Parent $PSScriptRoot
    $defaultPath = Join-Path $rootDir "03_history\default"

    # デフォルトパスが存在しない場合は作成
    if (-not (Test-Path $defaultPath)) {
        New-Item -ItemType Directory -Path $defaultPath -Force | Out-Null
        Write-Host "[state-manager] デフォルトプロジェクトフォルダを作成しました: $defaultPath" -ForegroundColor Yellow
    }

    # グローバル変数にも設定
    $global:folderPath = $defaultPath

    return $defaultPath
}


function Set-CurrentProject {
    <#
    .SYNOPSIS
    現在のプロジェクトを設定

    .PARAMETER FolderPath
    プロジェクトフォルダパス
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$FolderPath
    )

    try {
        if (-not (Test-Path $FolderPath)) {
            return @{
                success = $false
                error = "フォルダが存在しません: $FolderPath"
            }
        }

        $global:UIpowershellState.CurrentProject = @{
            FolderPath = $FolderPath
            FolderName = Split-Path -Leaf $FolderPath
            JSONPath = Join-Path $FolderPath "variables.json"
            HistoryPath = Split-Path -Parent $FolderPath
        }

        # グローバル変数も更新（既存コードとの互換性）
        $global:folderPath = $FolderPath
        $global:JSONPath = Join-Path $FolderPath "variables.json"

        return @{
            success = $true
            message = "プロジェクトを設定しました"
            project = $global:UIpowershellState.CurrentProject
        }

    } catch {
        return @{
            success = $false
            error = "プロジェクト設定に失敗しました: $($_.Exception.Message)"
        }
    }
}


# ============================================
# ノード配列管理関数
# ============================================

function Get-AllNodes {
    <#
    .SYNOPSIS
    全ノードを取得
    #>
    return @{
        success = $true
        nodes = $global:UIpowershellState.Nodes
        count = $global:UIpowershellState.Nodes.Count
    }
}


function Set-AllNodes {
    <#
    .SYNOPSIS
    ノード配列を一括設定（React Flowから同期）

    .PARAMETER Nodes
    ノード配列
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Nodes
    )

    try {
        $global:UIpowershellState.Nodes = $Nodes

        return @{
            success = $true
            message = "ノード配列を更新しました"
            count = $Nodes.Count
        }

    } catch {
        return @{
            success = $false
            error = "ノード配列の更新に失敗しました: $($_.Exception.Message)"
        }
    }
}


function Get-NodeById {
    <#
    .SYNOPSIS
    IDでノードを取得

    .PARAMETER NodeId
    ノードID
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$NodeId
    )

    $node = $global:UIpowershellState.Nodes | Where-Object { $_.id -eq $NodeId }

    if ($node) {
        return @{
            success = $true
            node = $node
        }
    } else {
        return @{
            success = $false
            error = "ノードが見つかりません: $NodeId"
        }
    }
}


function Add-Node {
    <#
    .SYNOPSIS
    ノードを追加

    .PARAMETER Node
    追加するノード
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Node
    )

    try {
        $global:UIpowershellState.Nodes += $Node

        return @{
            success = $true
            message = "ノードを追加しました"
            nodeId = $Node.id
            totalCount = $global:UIpowershellState.Nodes.Count
        }

    } catch {
        return @{
            success = $false
            error = "ノード追加に失敗しました: $($_.Exception.Message)"
        }
    }
}


function Update-Node {
    <#
    .SYNOPSIS
    ノードを更新

    .PARAMETER NodeId
    更新するノードID

    .PARAMETER Updates
    更新内容
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$NodeId,

        [Parameter(Mandatory=$true)]
        [hashtable]$Updates
    )

    try {
        $node = $global:UIpowershellState.Nodes | Where-Object { $_.id -eq $NodeId }

        if (-not $node) {
            return @{
                success = $false
                error = "ノードが見つかりません: $NodeId"
            }
        }

        # 更新を適用
        foreach ($key in $Updates.Keys) {
            $node[$key] = $Updates[$key]
        }

        return @{
            success = $true
            message = "ノードを更新しました"
            nodeId = $NodeId
        }

    } catch {
        return @{
            success = $false
            error = "ノード更新に失敗しました: $($_.Exception.Message)"
        }
    }
}


function Remove-Node {
    <#
    .SYNOPSIS
    ノードを削除

    .PARAMETER NodeId
    削除するノードID
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$NodeId
    )

    try {
        $initialCount = $global:UIpowershellState.Nodes.Count
        $global:UIpowershellState.Nodes = $global:UIpowershellState.Nodes | Where-Object { $_.id -ne $NodeId }
        $finalCount = $global:UIpowershellState.Nodes.Count

        if ($finalCount -lt $initialCount) {
            return @{
                success = $true
                message = "ノードを削除しました"
                nodeId = $NodeId
                remainingCount = $finalCount
            }
        } else {
            return @{
                success = $false
                error = "ノードが見つかりません: $NodeId"
            }
        }

    } catch {
        return @{
            success = $false
            error = "ノード削除に失敗しました: $($_.Exception.Message)"
        }
    }
}


# ============================================
# エッジ配列管理関数
# ============================================

function Get-AllEdges {
    <#
    .SYNOPSIS
    全エッジを取得
    #>
    return @{
        success = $true
        edges = $global:UIpowershellState.Edges
        count = $global:UIpowershellState.Edges.Count
    }
}


function Set-AllEdges {
    <#
    .SYNOPSIS
    エッジ配列を一括設定（React Flowから同期）

    .PARAMETER Edges
    エッジ配列
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Edges
    )

    try {
        $global:UIpowershellState.Edges = $Edges

        return @{
            success = $true
            message = "エッジ配列を更新しました"
            count = $Edges.Count
        }

    } catch {
        return @{
            success = $false
            error = "エッジ配列の更新に失敗しました: $($_.Exception.Message)"
        }
    }
}


# ============================================
# 変数管理関数
# ============================================

function Get-AllVariables {
    <#
    .SYNOPSIS
    全変数を取得
    #>
    return @{
        success = $true
        variables = $global:UIpowershellState.Variables
        count = $global:UIpowershellState.Variables.Count
    }
}


function Set-Variable {
    <#
    .SYNOPSIS
    変数を設定

    .PARAMETER Name
    変数名

    .PARAMETER Value
    変数値
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        $Value
    )

    try {
        $global:UIpowershellState.Variables[$Name] = $Value

        return @{
            success = $true
            message = "変数を設定しました"
            name = $Name
        }

    } catch {
        return @{
            success = $false
            error = "変数設定に失敗しました: $($_.Exception.Message)"
        }
    }
}


# ============================================
# デバッグ関数
# ============================================

function Get-StateDebugInfo {
    <#
    .SYNOPSIS
    デバッグ情報を取得
    #>
    return @{
        success = $true
        state = @{
            sessionId = $global:UIpowershellState.SessionId
            startTime = $global:UIpowershellState.StartTime
            uptime = (Get-Date) - $global:UIpowershellState.StartTime
            currentProject = $global:UIpowershellState.CurrentProject
            nodeCount = $global:UIpowershellState.Nodes.Count
            edgeCount = $global:UIpowershellState.Edges.Count
            variableCount = $global:UIpowershellState.Variables.Count
            settings = $global:UIpowershellState.Settings
        }
    }
}


# ============================================
# スクリプトの終了
# ============================================
# 注: このファイルは . (dot-source) で読み込まれるため、
# Export-ModuleMember は使用しません。
# すべての関数は自動的にグローバルスコープで利用可能になります。
