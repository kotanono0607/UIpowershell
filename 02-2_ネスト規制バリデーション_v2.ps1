﻿# ============================================
# 02-2_ネスト規制バリデーション_v2.ps1
# UI非依存版 - HTML/JS移行対応
# ============================================
# 変更内容:
#   - ドロップ禁止チェック_ネスト規制_v2: ノード配列を受け取り、バリデーション結果を返却
#   - Get-GroupRangeAfterMove_v2: ノード配列から移動後のグループ範囲を計算
#   - Get-AllGroupRanges_v2: ノード配列から全グループ範囲を取得
#   - Is-IllegalPair_v2: 2つの範囲の違法性を判定
#   - Check-GroupFragmentation_v2: グループ分断をチェック
#   - すべての関数が構造化データを返却（REST API対応）
#   - 既存の関数も維持（後方互換性）
#
# 互換性:
#   - 既存のWindows Forms版でも動作
#   - HTML/JS版でも動作（REST API経由）
# ============================================

# ============================================
# 新しい関数（UI非依存版 - HTML/JS対応）
# ============================================

function Get-GroupRangeAfterMove_v2 {
    <#
    .SYNOPSIS
    移動後のグループ範囲を計算（UI非依存版）

    .DESCRIPTION
    ノード配列から、指定されたノードが移動した後のグループの縦範囲(TopY/BottomY)を計算します。

    .PARAMETER ノード配列
    すべてのノード情報を含むハッシュテーブルの配列

    .PARAMETER MovingNodeId
    移動中のノードID

    .PARAMETER NewY
    移動後のY座標

    .EXAMPLE
    $range = Get-GroupRangeAfterMove_v2 -ノード配列 $nodes -MovingNodeId "76-1" -NewY 150
    #>
    param(
        [array]$ノード配列,
        [string]$MovingNodeId,
        [int]$NewY
    )

    # 移動中のノードを取得
    $移動ノード = $ノード配列 | Where-Object { $_.id -eq $MovingNodeId }
    if (-not $移動ノード) { return $null }

    $gid = $移動ノード.groupId
    if ($null -eq $gid) { return $null }

    # 同じGroupIDの全ノードを集める（色に関係なく）
    $sameGroupNodes = $ノード配列 | Where-Object {
        $_.groupId -ne $null -and
        $_.groupId.ToString() -eq $gid.ToString()
    }

    # 最低2本必要
    if ($sameGroupNodes.Count -lt 2) {
        return $null
    }

    $yList = @()
    foreach ($node in $sameGroupNodes) {
        if ($node.id -eq $MovingNodeId) {
            $yList += $NewY
        } else {
            $yList += $node.y
        }
    }

    $topY = ($yList | Measure-Object -Minimum).Minimum
    $bottomY = ($yList | Measure-Object -Maximum).Maximum

    return [pscustomobject]@{
        GroupID = $gid
        TopY = [int]$topY
        BottomY = [int]$bottomY
    }
}


function Get-AllGroupRanges_v2 {
    <#
    .SYNOPSIS
    指定色のすべてのグループ範囲を取得（UI非依存版）

    .DESCRIPTION
    ノード配列から、指定された色のすべてのGroupIDごとの縦範囲を返します。

    .PARAMETER ノード配列
    すべてのノード情報を含むハッシュテーブルの配列

    .PARAMETER TargetColor
    対象の色（SpringGreen, LemonChiffonなど）

    .EXAMPLE
    $ranges = Get-AllGroupRanges_v2 -ノード配列 $nodes -TargetColor "SpringGreen"
    #>
    param(
        [array]$ノード配列,
        [string]$TargetColor
    )

    # 色でフィルタ
    $colorNodes = $ノード配列 | Where-Object {
        $_.color -ne $null -and
        $_.color -eq $TargetColor
    }

    # GroupIDでグループ化
    $grouped = $colorNodes | Group-Object -Property groupId

    $ranges = @()

    foreach ($g in $grouped) {
        if ($g.Group.Count -lt 1) { continue }

        $gid = $g.Name

        # そのGroupIDの全ノード（色に関係なく）を取得
        # 条件分岐の中間ノード(Gray)も含めるため
        $allNodesInGroup = $ノード配列 | Where-Object {
            $_.groupId -ne $null -and
            $_.groupId.ToString() -eq $gid.ToString()
        }

        if ($allNodesInGroup.Count -lt 2) { continue }

        $sorted = $allNodesInGroup | Sort-Object { $_.y }
        $topY = $sorted[0].y
        $bottomY = $sorted[-1].y

        $ranges += [pscustomobject]@{
            GroupID = $gid
            TopY = [int]$topY
            BottomY = [int]$bottomY
        }
    }

    return $ranges
}


function Is-IllegalPair_v2 {
    <#
    .SYNOPSIS
    2つの範囲の違法性を判定（UI非依存版）

    .DESCRIPTION
    条件分岐範囲とループ範囲の組み合わせが違法かどうかを判定します。

    .PARAMETER CondRange
    条件分岐の範囲（TopY, BottomY）

    .PARAMETER LoopRange
    ループの範囲（TopY, BottomY）

    .EXAMPLE
    $isIllegal = Is-IllegalPair_v2 -CondRange $condRange -LoopRange $loopRange
    #>
    param(
        $CondRange,
        $LoopRange
    )

    if ($null -eq $CondRange -or $null -eq $LoopRange) {
        return $false
    }

    $cTop = $CondRange.TopY
    $cBot = $CondRange.BottomY
    $lTop = $LoopRange.TopY
    $lBot = $LoopRange.BottomY

    # まず重なってるかどうか
    $overlap = ($cBot -gt $lTop) -and ($cTop -lt $lBot)
    if (-not $overlap) {
        # 完全に上下に離れてる → OK
        return $false
    }

    # 条件分岐がループの完全内側ならOK
    $condInsideLoop = ($cTop -ge $lTop) -and ($cBot -le $lBot)
    if ($condInsideLoop) {
        # OK (ループが外側、条件分岐が内側) は合法
        return $false
    }

    # それ以外の重なりはダメ
    # - 交差 (片足だけ突っ込んでる)
    # - ループが条件分岐の内側に丸ごと入る
    return $true
}


function Check-GroupFragmentation_v2 {
    <#
    .SYNOPSIS
    グループ分断をチェック（UI非依存版）

    .DESCRIPTION
    グループ内のノードが境界をまたぐ（一部が内側、一部が外側）かチェックします。

    .PARAMETER ノード配列
    すべてのノード情報を含むハッシュテーブルの配列

    .PARAMETER MovingNodeId
    移動中のノードID

    .PARAMETER NewY
    移動後のY座標

    .PARAMETER GroupColor
    チェック対象のグループ色

    .PARAMETER BoundaryColor
    境界となるグループ色

    .EXAMPLE
    $isFragmented = Check-GroupFragmentation_v2 -ノード配列 $nodes -MovingNodeId "76-1" -NewY 150 -GroupColor "SpringGreen" -BoundaryColor "LemonChiffon"
    #>
    param(
        [array]$ノード配列,
        [string]$MovingNodeId,
        [int]$NewY,
        [string]$GroupColor,
        [string]$BoundaryColor
    )

    # 移動中のノードを取得
    $移動ノード = $ノード配列 | Where-Object { $_.id -eq $MovingNodeId }
    if (-not $移動ノード) { return $false }

    $gid = $移動ノード.groupId
    if ($null -eq $gid) { return $false }

    # 同じGroupIDの全ノードを取得（色に関係なく）
    $sameGroupNodes = $ノード配列 | Where-Object {
        $_.groupId -ne $null -and
        $_.groupId.ToString() -eq $gid.ToString()
    }

    if ($sameGroupNodes.Count -lt 2) {
        return $false
    }

    # 境界色のグループ範囲を全て取得
    $boundaryRanges = Get-AllGroupRanges_v2 -ノード配列 $ノード配列 -TargetColor $BoundaryColor

    foreach ($br in $boundaryRanges) {
        $insideCount = 0
        $outsideCount = 0

        # グループ内の各ノードが境界の内側か外側かチェック
        foreach ($node in $sameGroupNodes) {
            $nodeY = if ($node.id -eq $MovingNodeId) { $NewY } else { $node.y }

            if (($nodeY -ge $br.TopY) -and ($nodeY -le $br.BottomY)) {
                $insideCount++
            } else {
                $outsideCount++
            }
        }

        # 一部が内側、一部が外側 = グループ分断 = 禁止
        if ($insideCount -gt 0 -and $outsideCount -gt 0) {
            return $true
        }
    }

    return $false
}


function ドロップ禁止チェック_ネスト規制_v2 {
    <#
    .SYNOPSIS
    ドラッグ&ドロップ時のネスト規制チェック（UI非依存版）

    .DESCRIPTION
    ノード配列を使用して、ドラッグ&ドロップ操作が違法なネストを引き起こすかチェックします。

    .PARAMETER ノード配列
    すべてのノード情報を含むハッシュテーブルの配列
    各ノードは以下のプロパティを持つ:
      - id: ノードID
      - text: 表示テキスト
      - color: ノード色（SpringGreen, LemonChiffonなど）
      - y: Y座標
      - groupId: グループID（条件分岐・ループの場合）

    .PARAMETER MovingNodeId
    移動中のノードID

    .PARAMETER 設置希望Y
    ドロップ後の希望Y座標

    .EXAMPLE
    $result = ドロップ禁止チェック_ネスト規制_v2 -ノード配列 $nodes -MovingNodeId "76-1" -設置希望Y 150
    if ($result.isProhibited) {
        Write-Host "ドロップ禁止: $($result.reason)"
    }
    #>
    param (
        [Parameter(Mandatory=$true)]
        [array]$ノード配列,

        [Parameter(Mandatory=$true)]
        [string]$MovingNodeId,

        [Parameter(Mandatory=$true)]
        [int]$設置希望Y
    )

    try {
        # 移動中のノードを取得
        $移動ノード = $ノード配列 | Where-Object { $_.id -eq $MovingNodeId }

        if (-not $移動ノード) {
            return @{
                success = $false
                error = "移動ノードが見つかりません: $MovingNodeId"
            }
        }

        $元色 = $移動ノード.color

        # 色の正規化（SpringGreen/Green, LemonChiffon/Yellow）
        $isGreen = ($元色 -eq "SpringGreen" -or $元色 -eq "Green")
        $isYellow = ($元色 -eq "LemonChiffon" -or $元色 -eq "Yellow")

        # パネル上の全条件分岐ブロック範囲と全ループブロック範囲を先に取っておく
        $allCondRanges = Get-AllGroupRanges_v2 -ノード配列 $ノード配列 -TargetColor "SpringGreen"
        if (-not $allCondRanges) {
            $allCondRanges = @()
        }

        $allLoopRanges = Get-AllGroupRanges_v2 -ノード配列 $ノード配列 -TargetColor "LemonChiffon"
        if (-not $allLoopRanges) {
            $allLoopRanges = @()
        }

        # まず「単体ノードが腹に落ちる」ケースの即時チェック
        if ($isYellow) {
            foreach ($cr in $allCondRanges) {
                if ($設置希望Y -ge $cr.TopY -and $設置希望Y -le $cr.BottomY) {
                    # ループの任意ノードを条件分岐の腹の中に入れるのは禁止
                    return @{
                        success = $true
                        isProhibited = $true
                        reason = "ループノードを条件分岐の内部に配置することはできません"
                        violationType = "loop_in_conditional"
                        conflictGroupId = $cr.GroupID
                    }
                }
            }
        }
        elseif ($isGreen) {
            foreach ($lr in $allLoopRanges) {
                if ($設置希望Y -ge $lr.TopY -and $設置希望Y -le $lr.BottomY) {
                    # 条件分岐ノードをループの腹に刺すのは禁止
                    return @{
                        success = $true
                        isProhibited = $true
                        reason = "条件分岐ノードをループの内部に配置することはできません"
                        violationType = "conditional_in_loop"
                        conflictGroupId = $lr.GroupID
                    }
                }
            }
        }

        # グループ分断チェック
        if ($isGreen) {
            # 条件分岐グループがループの境界をまたぐかチェック
            $isFragmented = Check-GroupFragmentation_v2 `
                -ノード配列 $ノード配列 `
                -MovingNodeId $MovingNodeId `
                -NewY $設置希望Y `
                -GroupColor "SpringGreen" `
                -BoundaryColor "LemonChiffon"

            if ($isFragmented) {
                return @{
                    success = $true
                    isProhibited = $true
                    reason = "条件分岐グループがループの境界をまたぐことはできません（グループ分断）"
                    violationType = "group_fragmentation"
                    groupType = "conditional"
                }
            }
        }

        if ($isYellow) {
            # ループグループが条件分岐の境界をまたぐかチェック
            $isFragmented = Check-GroupFragmentation_v2 `
                -ノード配列 $ノード配列 `
                -MovingNodeId $MovingNodeId `
                -NewY $設置希望Y `
                -GroupColor "LemonChiffon" `
                -BoundaryColor "SpringGreen"

            if ($isFragmented) {
                return @{
                    success = $true
                    isProhibited = $true
                    reason = "ループグループが条件分岐の境界をまたぐことはできません（グループ分断）"
                    violationType = "group_fragmentation"
                    groupType = "loop"
                }
            }
        }

        # 次に、グループ全体としての整合性チェック
        if ($isGreen) {
            # この条件分岐グループが移動後どういう縦範囲になるか
            $movedCondRange = Get-GroupRangeAfterMove_v2 `
                -ノード配列 $ノード配列 `
                -MovingNodeId $MovingNodeId `
                -NewY $設置希望Y

            foreach ($lr in $allLoopRanges) {
                $isPairIllegal = Is-IllegalPair_v2 -CondRange $movedCondRange -LoopRange $lr
                if ($isPairIllegal) {
                    return @{
                        success = $true
                        isProhibited = $true
                        reason = "条件分岐とループの配置が不正です（交差または包含関係の違反）"
                        violationType = "illegal_nesting"
                        conflictGroupId = $lr.GroupID
                    }
                }
            }

            return @{
                success = $true
                isProhibited = $false
                message = "ドロップ可能です"
            }
        }

        if ($isYellow) {
            # このループグループが移動後どういう縦範囲になるか
            $movedLoopRange = Get-GroupRangeAfterMove_v2 `
                -ノード配列 $ノード配列 `
                -MovingNodeId $MovingNodeId `
                -NewY $設置希望Y

            foreach ($cr in $allCondRanges) {
                $isPairIllegal = Is-IllegalPair_v2 -CondRange $cr -LoopRange $movedLoopRange
                if ($isPairIllegal) {
                    return @{
                        success = $true
                        isProhibited = $true
                        reason = "ループと条件分岐の配置が不正です（交差または包含関係の違反）"
                        violationType = "illegal_nesting"
                        conflictGroupId = $cr.GroupID
                    }
                }
            }

            return @{
                success = $true
                isProhibited = $false
                message = "ドロップ可能です"
            }
        }

        # 緑でも黄でもないノードは規制しない
        return @{
            success = $true
            isProhibited = $false
            message = "ドロップ可能です（規制対象外の色）"
        }

    } catch {
        return @{
            success = $false
            error = "ネスト規制チェックに失敗しました: $($_.Exception.Message)"
            stackTrace = $_.ScriptStackTrace
        }
    }
}


# ============================================
# 既存の関数（Windows Forms版 - 後方互換性維持）
# ============================================

function ドロップ禁止チェック_ネスト規制 {
    <#
    .SYNOPSIS
    ドラッグ&ドロップ時のネスト規制チェック（既存のWindows Forms版）

    .DESCRIPTION
    この関数は既存のWindows Forms版との互換性維持のために残されています。
    内部でv2関数を呼び出し、バリデーション結果を返します。
    #>
    param (
        [System.Windows.Forms.Panel]$フレーム,
        [System.Windows.Forms.Button]$移動ボタン,
        [int]$設置希望Y
    )

    # ノード配列を作成
    $ノード配列 = @()
    foreach ($ctrl in $フレーム.Controls) {
        if ($ctrl -is [System.Windows.Forms.Button]) {
            $ノード配列 += @{
                id = $ctrl.Name
                text = $ctrl.Text
                color = if ($ctrl.Tag -and $ctrl.Tag.BackgroundColor) {
                    $ctrl.Tag.BackgroundColor.Name
                } else {
                    $ctrl.BackColor.Name
                }
                y = $ctrl.Location.Y
                groupId = if ($ctrl.Tag -and $ctrl.Tag.GroupID) { $ctrl.Tag.GroupID } else { $null }
            }
        }
    }

    # v2関数でバリデーション
    $result = ドロップ禁止チェック_ネスト規制_v2 `
        -ノード配列 $ノード配列 `
        -MovingNodeId $移動ボタン.Name `
        -設置希望Y $設置希望Y

    if (-not $result.success) {
        Write-Warning "バリデーションエラー: $($result.error)"
        return $true  # エラー時は禁止扱い
    }

    return $result.isProhibited
}
