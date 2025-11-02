# ============================================
# adapter/node-operations.ps1
# ノード配列操作ユーティリティ
# ============================================
# 役割：ノード配列の変換、グループ操作、座標計算
# アーキテクチャ：Utility Functions
# ============================================

# ============================================
# ノード配列変換関数
# ============================================

function ConvertFrom-WindowsFormsControls {
    <#
    .SYNOPSIS
    Windows FormsのControlsをノード配列に変換

    .PARAMETER Panel
    Windows FormsのPanel

    .EXAMPLE
    $nodes = ConvertFrom-WindowsFormsControls -Panel $global:レイヤー1
    #>
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.Panel]$Panel
    )

    try {
        $nodes = @()

        foreach ($ctrl in $Panel.Controls) {
            if ($ctrl -is [System.Windows.Forms.Button]) {
                $nodes += @{
                    id = $ctrl.Name
                    text = $ctrl.Text
                    color = if ($ctrl.Tag -and $ctrl.Tag.BackgroundColor) {
                        $ctrl.Tag.BackgroundColor.Name
                    } else {
                        $ctrl.BackColor.Name
                    }
                    x = $ctrl.Location.X
                    y = $ctrl.Location.Y
                    width = $ctrl.Width
                    height = $ctrl.Height
                    groupId = if ($ctrl.Tag -and $ctrl.Tag.GroupID) { $ctrl.Tag.GroupID } else { $null }
                    control = $ctrl  # 実際のコントロール参照（削除時などに使用）
                }
            }
        }

        return @{
            success = $true
            nodes = $nodes
            count = $nodes.Count
        }

    } catch {
        return @{
            success = $false
            error = "Windows Formsコントロールの変換に失敗しました: $($_.Exception.Message)"
        }
    }
}


function ConvertTo-JsonNodes {
    <#
    .SYNOPSIS
    ノード配列をJSON用にシリアライズ可能な形式に変換

    .PARAMETER Nodes
    ノード配列

    .EXAMPLE
    $jsonNodes = ConvertTo-JsonNodes -Nodes $nodes
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Nodes
    )

    try {
        $jsonNodes = @()

        foreach ($node in $Nodes) {
            # controlプロパティは除外（シリアライズ不可）
            $jsonNode = @{
                id = $node.id
                text = $node.text
                color = $node.color
                x = $node.x
                y = $node.y
                width = if ($node.width) { $node.width } else { 160 }
                height = if ($node.height) { $node.height } else { 30 }
                groupId = $node.groupId
            }

            $jsonNodes += $jsonNode
        }

        return @{
            success = $true
            nodes = $jsonNodes
            count = $jsonNodes.Count
        }

    } catch {
        return @{
            success = $false
            error = "JSON形式への変換に失敗しました: $($_.Exception.Message)"
        }
    }
}


# ============================================
# グループ操作関数
# ============================================

function New-GroupId {
    <#
    .SYNOPSIS
    新しいグループIDを生成

    .PARAMETER Prefix
    プレフィックス（例: "cond", "loop"）

    .EXAMPLE
    $groupId = New-GroupId -Prefix "cond"
    #>
    param(
        [Parameter(Mandatory=$false)]
        [string]$Prefix = "group"
    )

    try {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $random = Get-Random -Minimum 1000 -Maximum 9999
        $groupId = "$Prefix-$timestamp-$random"

        return @{
            success = $true
            groupId = $groupId
        }

    } catch {
        return @{
            success = $false
            error = "グループID生成に失敗しました: $($_.Exception.Message)"
        }
    }
}


function Get-NodesByGroupId {
    <#
    .SYNOPSIS
    グループIDでノードを取得

    .PARAMETER Nodes
    ノード配列

    .PARAMETER GroupId
    グループID

    .EXAMPLE
    $result = Get-NodesByGroupId -Nodes $nodes -GroupId "cond-123"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Nodes,

        [Parameter(Mandatory=$true)]
        [string]$GroupId
    )

    try {
        $groupNodes = $Nodes | Where-Object {
            $_.groupId -ne $null -and
            $_.groupId.ToString() -eq $GroupId.ToString()
        }

        return @{
            success = $true
            nodes = $groupNodes
            count = $groupNodes.Count
            groupId = $GroupId
        }

    } catch {
        return @{
            success = $false
            error = "グループノード取得に失敗しました: $($_.Exception.Message)"
        }
    }
}


function Get-AllGroups {
    <#
    .SYNOPSIS
    すべてのグループを取得

    .PARAMETER Nodes
    ノード配列

    .EXAMPLE
    $result = Get-AllGroups -Nodes $nodes
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Nodes
    )

    try {
        # グループIDでグループ化
        $groups = @{}

        foreach ($node in $Nodes) {
            if ($node.groupId) {
                $gid = $node.groupId.ToString()

                if (-not $groups.ContainsKey($gid)) {
                    $groups[$gid] = @{
                        groupId = $gid
                        nodes = @()
                        color = $node.color
                    }
                }

                $groups[$gid].nodes += $node
            }
        }

        return @{
            success = $true
            groups = $groups.Values
            count = $groups.Count
        }

    } catch {
        return @{
            success = $false
            error = "グループ一覧取得に失敗しました: $($_.Exception.Message)"
        }
    }
}


# ============================================
# ノードフィルタリング関数
# ============================================

function Get-NodesByColor {
    <#
    .SYNOPSIS
    色でノードをフィルタリング

    .PARAMETER Nodes
    ノード配列

    .PARAMETER Color
    色（SpringGreen, LemonChiffonなど）

    .EXAMPLE
    $result = Get-NodesByColor -Nodes $nodes -Color "SpringGreen"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Nodes,

        [Parameter(Mandatory=$true)]
        [string]$Color
    )

    try {
        $filteredNodes = $Nodes | Where-Object {
            $_.color -eq $Color
        }

        return @{
            success = $true
            nodes = $filteredNodes
            count = $filteredNodes.Count
            color = $Color
        }

    } catch {
        return @{
            success = $false
            error = "色フィルタリングに失敗しました: $($_.Exception.Message)"
        }
    }
}


function Get-NodesByType {
    <#
    .SYNOPSIS
    タイプでノードをフィルタリング

    .PARAMETER Nodes
    ノード配列

    .PARAMETER Type
    タイプ（conditional, loop, normalなど）

    .EXAMPLE
    $result = Get-NodesByType -Nodes $nodes -Type "conditional"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Nodes,

        [Parameter(Mandatory=$true)]
        [string]$Type
    )

    try {
        $filteredNodes = @()

        switch ($Type) {
            "conditional" {
                $filteredNodes = $Nodes | Where-Object {
                    $_.color -eq "SpringGreen" -or $_.color -eq "Green"
                }
            }
            "loop" {
                $filteredNodes = $Nodes | Where-Object {
                    $_.color -eq "LemonChiffon" -or $_.color -eq "Yellow"
                }
            }
            "normal" {
                $filteredNodes = $Nodes | Where-Object {
                    $_.color -ne "SpringGreen" -and
                    $_.color -ne "Green" -and
                    $_.color -ne "LemonChiffon" -and
                    $_.color -ne "Yellow"
                }
            }
            default {
                return @{
                    success = $false
                    error = "不明なタイプ: $Type"
                }
            }
        }

        return @{
            success = $true
            nodes = $filteredNodes
            count = $filteredNodes.Count
            type = $Type
        }

    } catch {
        return @{
            success = $false
            error = "タイプフィルタリングに失敗しました: $($_.Exception.Message)"
        }
    }
}


# ============================================
# 座標計算関数
# ============================================

function Get-NodeBounds {
    <#
    .SYNOPSIS
    ノード配列の境界ボックスを計算

    .PARAMETER Nodes
    ノード配列

    .EXAMPLE
    $bounds = Get-NodeBounds -Nodes $nodes
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Nodes
    )

    try {
        if ($Nodes.Count -eq 0) {
            return @{
                success = $true
                minX = 0
                minY = 0
                maxX = 0
                maxY = 0
                width = 0
                height = 0
            }
        }

        $minX = ($Nodes | Measure-Object -Property x -Minimum).Minimum
        $minY = ($Nodes | Measure-Object -Property y -Minimum).Minimum
        $maxX = ($Nodes | Measure-Object -Property x -Maximum).Maximum
        $maxY = ($Nodes | Measure-Object -Property y -Maximum).Maximum

        return @{
            success = $true
            minX = $minX
            minY = $minY
            maxX = $maxX
            maxY = $maxY
            width = $maxX - $minX
            height = $maxY - $minY
        }

    } catch {
        return @{
            success = $false
            error = "境界ボックス計算に失敗しました: $($_.Exception.Message)"
        }
    }
}


function Get-NextAvailableY {
    <#
    .SYNOPSIS
    次に配置可能なY座標を取得

    .PARAMETER Nodes
    ノード配列

    .PARAMETER StartY
    開始Y座標（デフォルト: 0）

    .PARAMETER Spacing
    ノード間のスペース（デフォルト: 10）

    .EXAMPLE
    $nextY = Get-NextAvailableY -Nodes $nodes
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Nodes,

        [Parameter(Mandatory=$false)]
        [int]$StartY = 0,

        [Parameter(Mandatory=$false)]
        [int]$Spacing = 10
    )

    try {
        if ($Nodes.Count -eq 0) {
            return @{
                success = $true
                nextY = $StartY
            }
        }

        # Y座標でソート
        $sortedNodes = $Nodes | Sort-Object { $_.y }
        $lastNode = $sortedNodes[-1]

        $nextY = $lastNode.y + $lastNode.height + $Spacing

        return @{
            success = $true
            nextY = $nextY
        }

    } catch {
        return @{
            success = $false
            error = "次のY座標計算に失敗しました: $($_.Exception.Message)"
        }
    }
}


function Test-NodeCollision {
    <#
    .SYNOPSIS
    ノードの衝突をチェック

    .PARAMETER Node1
    ノード1

    .PARAMETER Node2
    ノード2

    .EXAMPLE
    $collision = Test-NodeCollision -Node1 $node1 -Node2 $node2
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Node1,

        [Parameter(Mandatory=$true)]
        [hashtable]$Node2
    )

    try {
        # 簡単な矩形衝突判定
        $collision = (
            $Node1.x -lt ($Node2.x + $Node2.width) -and
            ($Node1.x + $Node1.width) -gt $Node2.x -and
            $Node1.y -lt ($Node2.y + $Node2.height) -and
            ($Node1.y + $Node1.height) -gt $Node2.y
        )

        return @{
            success = $true
            collision = $collision
        }

    } catch {
        return @{
            success = $false
            error = "衝突判定に失敗しました: $($_.Exception.Message)"
        }
    }
}


# ============================================
# ノードソート関数
# ============================================

function Sort-NodesByY {
    <#
    .SYNOPSIS
    ノードをY座標でソート

    .PARAMETER Nodes
    ノード配列

    .PARAMETER Descending
    降順にする場合は$true

    .EXAMPLE
    $sorted = Sort-NodesByY -Nodes $nodes
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Nodes,

        [Parameter(Mandatory=$false)]
        [bool]$Descending = $false
    )

    try {
        if ($Descending) {
            $sortedNodes = $Nodes | Sort-Object { $_.y } -Descending
        } else {
            $sortedNodes = $Nodes | Sort-Object { $_.y }
        }

        return @{
            success = $true
            nodes = $sortedNodes
            count = $sortedNodes.Count
        }

    } catch {
        return @{
            success = $false
            error = "ソートに失敗しました: $($_.Exception.Message)"
        }
    }
}


# ============================================
# スクリプトの終了
# ============================================
# 注: このファイルは . (dot-source) で読み込まれるため、
# Export-ModuleMember は使用しません。
# すべての関数は自動的にグローバルスコープで利用可能になります。
