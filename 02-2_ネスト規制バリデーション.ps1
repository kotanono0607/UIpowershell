# ================================================================
# 02-2_ネスト規制バリデーション.ps1
# ================================================================
# 責任: ドラッグ&ドロップ時のネスト規制・3層チェック
# 
# 含まれる関数:
#   - ドロップ禁止チェック_ネスト規制
#
# リファクタリング: 2025-11-01
# 元ファイル: 02_メインフォームUI_foam関数.ps1 (行210-510)
# ================================================================

function ドロップ禁止チェック_ネスト規制 {
    param (
        [System.Windows.Forms.Panel]$フレーム,      # ドロップ先パネル
        [System.Windows.Forms.Button]$移動ボタン,   # 今ドラッグしてるボタン
        [int]$設置希望Y                              # ドロップ後に置く予定のY
    )

    # ユーティリティ: 指定色+GroupIDのブロック縦範囲を返す(TopY/BottomY)
    # movingBtn だけは newY を反映して計算する
    function Get-GroupRangeAfterMove {
        param(
            [System.Windows.Forms.Panel]$panel,
            [System.Windows.Forms.Button]$movingBtn,
            [int]$newY,
            [System.Drawing.Color]$targetColor
        )

        if (-not $movingBtn.Tag) { return $null }
        $gid = $movingBtn.Tag.GroupID
        if ($null -eq $gid) { return $null }

        # 同じ GroupID の全ボタンを集める（色に関係なく）
        # 修正: 条件分岐の中間ノード(Gray)も含めるため、色フィルタを削除
        $sameGroupBtns = $panel.Controls |
            Where-Object {
                $_ -is [System.Windows.Forms.Button] -and
                $_.Tag -ne $null -and
                $_.Tag.GroupID -ne $null -and
                $_.Tag.GroupID.ToString() -eq $gid.ToString()
            }

        # "開始" "終了" の2本がそろってないと正しい範囲が出せない
        if ($sameGroupBtns.Count -lt 2) {
            return $null
        }

        $yList = @()
        foreach ($btn in $sameGroupBtns) {
            if ($btn -eq $movingBtn) {
                $yList += $newY
            } else {
                $yList += $btn.Location.Y
            }
        }

        $topY    = ($yList | Measure-Object -Minimum).Minimum
        $bottomY = ($yList | Measure-Object -Maximum).Maximum

        return [pscustomobject]@{
            GroupID  = $gid
            TopY     = [int]$topY
            BottomY  = [int]$bottomY
        }
    }

    # ユーティリティ: パネル全体から、指定色ごとに GroupID 単位の範囲を回収
    function Get-AllGroupRanges {
        param(
            [System.Windows.Forms.Panel]$panel,
            [System.Drawing.Color]$targetColor
        )

        # まず色でフィルタして、対象となるGroupIDを特定
        $colorBtns = $panel.Controls |
            Where-Object {
                $_ -is [System.Windows.Forms.Button] -and
                $_.Tag -ne $null -and
                $_.Tag.BackgroundColor -ne $null -and
                $_.Tag.BackgroundColor.ToArgb() -eq $targetColor.ToArgb()
            }

        $grouped = $colorBtns | Group-Object -Property { $_.Tag.GroupID }

        $ranges = @()

        foreach ($g in $grouped) {
            if ($g.Group.Count -lt 1) { continue }

            $gid = $g.Name

            # ★修正: そのGroupIDの全ノード（色に関係なく）を取得
            # 条件分岐の中間ノード(Gray)も含めるため
            # 型を文字列に統一して比較（Group-Objectは文字列を返すため）
            $allNodesInGroup = $panel.Controls |
                Where-Object {
                    $_ -is [System.Windows.Forms.Button] -and
                    $_.Tag -ne $null -and
                    $_.Tag.GroupID -ne $null -and
                    $_.Tag.GroupID.ToString() -eq $gid.ToString()
                }

            if ($allNodesInGroup.Count -lt 2) { continue }

            $sorted = $allNodesInGroup | Sort-Object { $_.Location.Y }
            $topY    = $sorted[0].Location.Y
            $bottomY = $sorted[-1].Location.Y

            $ranges += [pscustomobject]@{
                GroupID = $gid
                TopY    = [int]$topY
                BottomY = [int]$bottomY
            }
        }

        return $ranges
    }

    # 2つの範囲(condRange=緑 / loopRange=黄)の組み合わせが違反かどうか
    # 戻り値: $true = 違反
    function Is-IllegalPair {
        param(
            $condRange,
            $loopRange
        )

        if ($null -eq $condRange -or $null -eq $loopRange) {
            return $false
        }

        $cTop =  $condRange.TopY
        $cBot =  $condRange.BottomY
        $lTop =  $loopRange.TopY
        $lBot =  $loopRange.BottomY

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

    # ★★★ 新規追加: グループ分断チェック関数 ★★★
    # グループ内のボタンが境界をまたぐ（一部が内側、一部が外側）かチェック
    function Check-GroupFragmentation {
        param(
            [System.Windows.Forms.Panel]$panel,
            [System.Windows.Forms.Button]$movingBtn,
            [int]$newY,
            [System.Drawing.Color]$groupColor,
            [System.Drawing.Color]$boundaryColor
        )

        if (-not $movingBtn.Tag) { return $false }
        $gid = $movingBtn.Tag.GroupID
        if ($null -eq $gid) { return $false }

        # 同じGroupIDの全ボタンを取得（色に関係なく）
        # 修正: 条件分岐の中間ノード(Gray)も含めるため、色フィルタを削除
        $sameGroupBtns = $panel.Controls |
            Where-Object {
                $_ -is [System.Windows.Forms.Button] -and
                $_.Tag -ne $null -and
                $_.Tag.GroupID -ne $null -and
                $_.Tag.GroupID.ToString() -eq $gid.ToString()
            }

        if ($sameGroupBtns.Count -lt 2) {
            return $false
        }

        # 境界色のグループ範囲を全て取得
        $boundaryRanges = Get-AllGroupRanges -panel $panel -targetColor $boundaryColor

        foreach ($br in $boundaryRanges) {
            $insideCount = 0
            $outsideCount = 0

            # グループ内の各ボタンが境界の内側か外側かチェック
            foreach ($btn in $sameGroupBtns) {
                $btnY = if ($btn -eq $movingBtn) { $newY } else { $btn.Location.Y }

                if (($btnY -ge $br.TopY) -and ($btnY -le $br.BottomY)) {
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

    # ここから本体
    $元色 = $null
    if ($移動ボタン.Tag -and $移動ボタン.Tag.BackgroundColor) {
        $元色 = $移動ボタン.Tag.BackgroundColor
    }

    $isGreen  = ($元色 -ne $null -and $元色.ToArgb() -eq [System.Drawing.Color]::SpringGreen.ToArgb())
    $isYellow = ($元色 -ne $null -and $元色.ToArgb() -eq [System.Drawing.Color]::LemonChiffon.ToArgb())

    # パネル上の全条件分岐ブロック範囲と全ループブロック範囲を先に取っておく
    $allCondRanges = Get-AllGroupRanges -panel $フレーム -targetColor ([System.Drawing.Color]::SpringGreen)
    $allLoopRanges = Get-AllGroupRanges -panel $フレーム -targetColor ([System.Drawing.Color]::LemonChiffon)

    # まず「単体ノードが腹に落ちる」ケースの即時チェック
    if ($isYellow) {
        foreach ($cr in $allCondRanges) {
            if ($設置希望Y -ge $cr.TopY -and $設置希望Y -le $cr.BottomY) {
                # ループの任意ノードを条件分岐の腹の中に入れるのは禁止
                return $true
            }
        }
    }
    elseif ($isGreen) {
        foreach ($lr in $allLoopRanges) {
            if ($設置希望Y -ge $lr.TopY -and $設置希望Y -le $lr.BottomY) {
                # 条件分岐ノードをループの腹に刺すのは禁止
                # (＝ループの途中に条件分岐を割り込ませるのもダメ)
                return $true
            }
        }
    }

    # ★★★ 新規追加: グループ分断チェック ★★★
    if ($isGreen) {
        # 条件分岐グループがループの境界をまたぐかチェック
        $isFragmented = Check-GroupFragmentation `
            -panel $フレーム `
            -movingBtn $移動ボタン `
            -newY $設置希望Y `
            -groupColor ([System.Drawing.Color]::SpringGreen) `
            -boundaryColor ([System.Drawing.Color]::LemonChiffon)

        if ($isFragmented) {
            return $true
        }
    }

    if ($isYellow) {
        # ループグループが条件分岐の境界をまたぐかチェック
        $isFragmented = Check-GroupFragmentation `
            -panel $フレーム `
            -movingBtn $移動ボタン `
            -newY $設置希望Y `
            -groupColor ([System.Drawing.Color]::LemonChiffon) `
            -boundaryColor ([System.Drawing.Color]::SpringGreen)

        if ($isFragmented) {
            return $true
        }
    }

    # 次に、グループ全体としての整合性チェック
    if ($isGreen) {
        # この条件分岐グループが移動後どういう縦範囲になるか
        $movedCondRange = Get-GroupRangeAfterMove -panel $フレーム `
                                                 -movingBtn $移動ボタン `
                                                 -newY $設置希望Y `
                                                 -targetColor ([System.Drawing.Color]::SpringGreen)

        foreach ($lr in $allLoopRanges) {
            $isPairIllegal = Is-IllegalPair -condRange $movedCondRange -loopRange $lr
            if ($isPairIllegal) {
                return $true
            }
        }

        return $false
    }

    if ($isYellow) {
        # このループグループが移動後どういう縦範囲になるか
        $movedLoopRange = Get-GroupRangeAfterMove -panel $フレーム `
                                                 -movingBtn $移動ボタン `
                                                 -newY $設置希望Y `
                                                 -targetColor ([System.Drawing.Color]::LemonChiffon)

        foreach ($cr in $allCondRanges) {
            $isPairIllegal = Is-IllegalPair -condRange $cr -loopRange $movedLoopRange
            if ($isPairIllegal) {
                return $true
            }
        }

        return $false
    }

    # 緑でも黄でもないノードは規制しない
    return $false
}


