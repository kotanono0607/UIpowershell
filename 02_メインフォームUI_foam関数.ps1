
# グローバル変数の初期化
$global:ボタンカウンタ = 1
$global:黄色ボタングループカウンタ = 1000  # ループ用（1000番台）
$global:緑色ボタングループカウンタ = 2000  # 条件分岐用（2000番台）
$global:ドラッグ中のボタン = $null


function 00_フォームを作成する {
    param(
        [int]$幅 = 1400,
        [int]$高さ = 900
    )

    # タイトル: フォーム生成（最小化対策込み）Ver1.2
    # 目的:
    # - 初期状態を必ず Normal にする
    # - TopMost 常時ONをやめ、前面化はイベントで制御
    # - Shown/Resize イベントで最小化に落ちた場合の復帰を保証

    # フォームの作成と基本設定
    $メインフォーム = New-Object System.Windows.Forms.Form

    # 画面系の基本プロパティ
    $メインフォーム.Text            = "ドラッグ＆ドロップでボタンの位置を変更"  # タイトル
    $メインフォーム.Width           = $幅
    $メインフォーム.Height          = $高さ
    $メインフォーム.StartPosition   = "CenterScreen"                              # 画面中央
    $メインフォーム.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
    $メインフォーム.ShowInTaskbar   = $true
    $メインフォーム.MinimizeBox     = $true
    $メインフォーム.MaximizeBox     = $true
    $メインフォーム.Name            = "メインフォーム"                           # Nameプロパティ
    $メインフォーム.AllowDrop       = $false                                       # フォーム自体のドロップ無効
    $メインフォーム.BackColor       = [System.Drawing.Color]::FromArgb(255,255,255)

    # ■最小化対策: 初期状態を明示的にNormalへ
    $メインフォーム.WindowState     = [System.Windows.Forms.FormWindowState]::Normal

    # ■常時前面はやめる（他のフォームやOSと喧嘩しやすい）
    $メインフォーム.TopMost = $false

    # ■Shown時の保険: 最小化なら即Normalへ戻し、前面化
    $メインフォーム.Add_Shown({
        param($s,$e)
        # しつこい最小化癖をここで矯正
        if ($s.WindowState -eq [System.Windows.Forms.FormWindowState]::Minimized) {
            $s.WindowState = [System.Windows.Forms.FormWindowState]::Normal
        }
        # 一瞬だけTopMostにして前面化してから戻す（Zオーダー安定用の小技）
        $s.TopMost = $true
        $s.TopMost = $false
        $s.Activate()
    })

    # ■Resize時の保険: もし最小化に落ちたら即復帰
    $メインフォーム.Add_Resize({
        param($s,$e)
        switch ($s.WindowState) {
            ([System.Windows.Forms.FormWindowState]::Minimized) {
                # 最小化に落ちた瞬間に引き戻す
                $s.WindowState = [System.Windows.Forms.FormWindowState]::Normal
                $s.Activate()
            }
            ([System.Windows.Forms.FormWindowState]::Normal) {
                # 特に処理なし
            }
            ([System.Windows.Forms.FormWindowState]::Maximized) {
                # 特に処理なし
            }
        }
    })

    # フォームを返す
    return $メインフォーム
}

function 00_フレームのDragDropイベントを設定する {
    param (
        [System.Windows.Forms.Panel]$フレーム
    )

    $フレーム.Add_DragDrop({
        param($sender, $e)

        # ドラッグ中のボタンを取得
        $ボタン = $e.Data.GetData([System.Windows.Forms.Button])

        if ($ボタン -ne $null -and $ボタン.Tag.IsDragging) {

            # ドロップ先のフレーム内の座標に変換
            $ドロップ画面座標 = New-Object System.Drawing.Point($e.X, $e.Y)
            $ドロップ点 = $sender.PointToClient($ドロップ画面座標)

            # 現在の位置と色
            $現在のY   = $ボタン.Location.Y
            $現在の色  = $ボタン.BackColor

            # ボタンの中心Yを基準に配置したいYを計算
            $中心Y   = $ドロップ点.Y
            $配置Y   = $中心Y - ($ボタン.Height / 2) + 10

            # ============================
            # スクリプト展開中チェック（レイヤー2以降）
            # ============================
            $ドロップ先レイヤー番号 = グローバル変数から数値取得 -パネル $sender
            if ($ドロップ先レイヤー番号 -ge 2) {
                # レイヤー2以降の場合、親レイヤーでスクリプト展開中かチェック
                $親レイヤー番号 = $ドロップ先レイヤー番号 - 1

                if ($Global:Pink選択配列[$親レイヤー番号].値 -ne 1) {
                    # スクリプト展開中でない場合、エラーメッセージを表示
                    $メッセージ = "レイヤー$ドロップ先レイヤー番号 にノードを配置するには、`n" +
                                "レイヤー$親レイヤー番号 でスクリプト化ノードを展開してください。`n`n" +
                                "操作手順:`n" +
                                "1. レイヤー$親レイヤー番号 で Shift を押しながら複数のノードをクリック`n" +
                                "2. 「レイヤー化」ボタンをクリック`n" +
                                "3. 作成されたスクリプト化ノード（ピンク色）をクリック`n" +
                                "4. レイヤー$ドロップ先レイヤー番号 に展開されます"

                    [System.Windows.Forms.MessageBox]::Show(
                        $メッセージ,
                        "スクリプト展開が必要です",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Warning
                    ) | Out-Null

                    Write-Host "[❌ ドロップ] レイヤー$ドロップ先レイヤー番号 へのノード配置が拒否されました（スクリプト未展開）" -ForegroundColor Red

                    # ドラッグ状態をリセットして終了
                    $ボタン.Tag.IsDragging = $false
                    $ボタン.Tag.StartPoint = [System.Drawing.Point]::Empty
                    $global:ドラッグ中のボタン = $null
                    return
                }

                Write-Host "[✅ ドロップ] レイヤー$親レイヤー番号 でスクリプト展開中を確認。レイヤー$ドロップ先レイヤー番号 へのノード配置を許可" -ForegroundColor Green
            }

            # ============================
            # ネスト禁止チェック:
            #   - 条件分岐(緑)をループ(黄)の中に入れるな
            #   - ループ(黄)を条件分岐(緑)の中に入れるな
            # ============================
            $禁止フラグ = ドロップ禁止チェック_ネスト規制 `
                -フレーム $sender `
                -移動ボタン $ボタン `
                -設置希望Y $配置Y

            if ($禁止フラグ) {
                [System.Windows.Forms.MessageBox]::Show(
                    "この位置には配置できません。`r`nネストは禁止です。",
                    "配置禁止",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                ) | Out-Null

                # ドラッグ状態をリセットして終了
                $ボタン.Tag.IsDragging = $false
                $ボタン.Tag.StartPoint = [System.Drawing.Point]::Empty
                $global:ドラッグ中のボタン = $null
                return
            }

            # ============================
            # 既存の同色ブロック衝突チェック
            # （今の 10_ボタンの一覧取得 は bool を返してるのでそれに合わせる）
            # ============================
            $衝突あり = 10_ボタンの一覧取得 `
                -フレーム $sender `
                -現在のY $現在のY `
                -設置希望Y $配置Y `
                -現在の色 $現在の色

            if ($衝突あり) {
                # 同色ブロックの領域をまたぐ/割り込む等で拒否
                # ここでは何もしないで抜ける
            }
            else {
                # スナップXをフレーム中央にそろえる
                $スナップX = [Math]::Floor(($sender.ClientSize.Width - $ボタン.Width) / 2)

                # 実際に移動
                $元の位置Y = $ボタン.Location.Y
                $ボタン.Location = New-Object System.Drawing.Point($スナップX, $配置Y)

                # レイヤー番号を取得
                $レイヤー番号 = グローバル変数から数値取得 -パネル $sender
                $レイヤー表示 = if ($レイヤー番号) { "レイヤー$レイヤー番号" } else { "不明" }

                # 移動ログ（大きな移動のみ）
                if ([Math]::Abs($元の位置Y - $配置Y) -gt 10) {
                    Write-Host "[移動] $レイヤー表示`: $($ボタン.Name) - $($ボタン.Text)" -ForegroundColor Cyan
                }

                # ドラッグ状態のリセット
                $ボタン.Tag.IsDragging = $false
                $ボタン.Tag.StartPoint = [System.Drawing.Point]::Empty
                $global:ドラッグ中のボタン = $null

                # 全体の整列とライン再描画
                00_ボタンの上詰め再配置関数 -フレーム $sender
                00_矢印追記処理 -フレームパネル $Global:可視左パネル
            }
        }
    })
}


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


function 00_フレームのDragEnterイベントを設定する {
  param (
    [System.Windows.Forms.Panel]$フレーム
  )

  $フレーム.Add_DragEnter({
    param($sender, $e)
    if ($e.Data.GetDataPresent([System.Windows.Forms.Button])) {
      $e.Effect = [System.Windows.Forms.DragDropEffects]::Move
    } else {
      $e.Effect = [System.Windows.Forms.DragDropEffects]::None
    }
  })
}

function 10_ボタンの一覧取得 {
    param (
        [System.Windows.Forms.Panel]$フレーム,
        [Int]$現在のY,
        [System.Drawing.Color]$現在の色,
        [Int]$設置希望Y
    )
    
    # 現在の色がSpringGreenまたはLemonChiffonでない場合、フラグを返す
    if (-not ($現在の色 -eq [System.Drawing.Color]::SpringGreen -or $現在の色 -eq [System.Drawing.Color]::LemonChiffon)) {
        return $false
    }

    # 現在のボタンをY位置順にソート
    $ソート済みボタン = $フレーム.Controls |
                      Where-Object { $_ -is [System.Windows.Forms.Button] } |
                      Sort-Object { $_.Location.Y }
    
    # Y座標の範囲を決定
    $minY = [Math]::Min($現在のY, $設置希望Y)
    $maxY = [Math]::Max($現在のY, $設置希望Y)
    
    # フラグを初期化
    $SameColorExists = $false
    
    foreach ($ボタン in $ソート済みボタン) {
        $ボタンY = $ボタン.Location.Y
        $ボタン色 = $ボタン.BackColor
        
        ##Write-Host "色: $ボタン色" +  " ボタンY座標: $ボタンY"
    
        if ($現在の色 -eq [System.Drawing.Color]::SpringGreen) {
    
        # Y座標が範囲内かつBackColorが現在の色かをチェック
        if ($ボタンY -ge $minY -and $ボタンY -le $maxY -and $ボタン色 -eq [System.Drawing.Color]::SpringGreen -and $ボタンY -ne $現在のY) {
            ##Write-Host "ボタン '$($ボタン.Text)' が指定範囲内にあり、BackColorが現在の色です。1"
            $SameColorExists = $true
            break  # 最初に見つけたらループを抜ける
        }


        } elseif($現在の色 -eq [System.Drawing.Color]::LemonChiffon) {

        if ($ボタンY -ge $minY -and $ボタンY -le $maxY -and $ボタン色 -eq [System.Drawing.Color]::LemonChiffon -and $ボタンY -ne $現在のY) {
            ##Write-Host "ボタン '$($ボタン.Text)' が指定範囲内にあり、BackColorが現在の色です2。"
            $SameColorExists = $true
            break  # 最初に見つけたらループを抜ける
        }
            
        }

    }
    
    # フラグを返り値として返す
    return $SameColorExists
}

function 00_ボタンの上詰め再配置関数 {
  param (
    [System.Windows.Forms.Panel]$フレーム,
    [int]$ボタン高さ = 30,
    [int]$間隔 = 20  
  )

  # ボタンの高さと間隔を設定
  $ボタン高さ = 30
  $ボタン間隔 = $間隔

  # 現在のボタンをY位置順にソート
  $ソート済みボタン = $フレーム.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] } | Sort-Object { $_.Location.Y }

  $現在のY位置 = 0  # ボタン配置の初期位置

  # "条件分岐 開始"、"条件分岐 中間"、"条件分岐 終了"の位置を特定
  $開始インデックス = -1
  $中間インデックス = -1
  $終了インデックス = -1

  for ($i = 0; $i -lt $ソート済みボタン.Count; $i++) {
    if ($ソート済みボタン[$i].Text -eq "条件分岐 開始") {
      $開始インデックス = $i
    }
    if ($ソート済みボタン[$i].Text -eq "条件分岐 中間") {
      $中間インデックス = $i
    }
    if ($ソート済みボタン[$i].Text -eq "条件分岐 終了") {
      $終了インデックス = $i
    }
  }

  for ($インデックス = 0; $インデックス -lt $ソート済みボタン.Count; $インデックス++) {
    $ボタンテキスト = $ソート済みボタン[$インデックス].Text

    # ボタンの色を設定する条件分岐
    if ($開始インデックス -ne -1 -and $中間インデックス -ne -1 -and $インデックス -gt $開始インデックス -and $インデックス -lt $中間インデックス) {

 
if ($ソート済みボタン[$インデックス].Tag.script -eq "スクリプト") {
       $ソート済みボタン[$インデックス].BackColor = $global:ピンク赤色
} else {
       $ソート済みボタン[$インデックス].BackColor = [System.Drawing.Color]::Salmon
}




    } elseif ($中間インデックス -ne -1 -and $終了インデックス -ne -1 -and $インデックス -gt $中間インデックス -and $インデックス -lt $終了インデックス) {



if ($ソート済みボタン[$インデックス].Tag.script -eq "スクリプト") {
      $ソート済みボタン[$インデックス].BackColor = $global:ピンク青色
} else {
       $ソート済みボタン[$インデックス].BackColor =$global:青色
}


    } else {
      # 現在の色を取得
      $現在の色 = $ソート済みボタン[$インデックス].BackColor

      # 現在の色が Salmon または FromArgb(200, 220, 255) の場合のみ White に変更
      if ($現在の色.ToArgb() -eq [System.Drawing.Color]::Salmon.ToArgb() -or $現在の色.ToArgb() -eq $global:青色.ToArgb()) {
        $ソート済みボタン[$インデックス].BackColor = [System.Drawing.Color]::White
      }
      if ($ソート済みボタン[$インデックス].Tag.script -eq "スクリプト") {
        $ソート済みボタン[$インデックス].BackColor = [System.Drawing.Color]::Pink
      }
    }


    # ボタン間隔と高さの調整（"条件分岐 中間"の場合は0とする）
    if ($ボタンテキスト -eq "条件分岐 中間") {
      $使用する間隔 = 10
      $使用する高さ = 0
    } else {
      $使用する間隔 = $ボタン間隔
      $使用する高さ = $ボタン高さ
    }

    # 希望位置を計算
    $希望位置Y = $現在のY位置 + $使用する間隔

    # ボタンの配置を更新
    $ソート済みボタン[$インデックス].Location = New-Object System.Drawing.Point(
      [Math]::Floor(($フレーム.ClientSize.Width - $ソート済みボタン[$インデックス].Width) / 2),
      $希望位置Y
    )

    # 現在のY位置を更新
    $現在のY位置 = $希望位置Y + $使用する高さ
  }
}

function 00_フレームを作成する {
    param (
        [System.Windows.Forms.Form]$フォーム,           # フレームを追加するフォーム
        [int]$幅 = 300,                                # フレームの幅
        [int]$高さ = 600,                              # フレームの高さ
        [int]$X位置 = 100,                              # フレームのX座標
        [int]$Y位置 = 20,                               # フレームのY座標
        [string]$フレーム名 = "フレームパネル",         # フレームの名前
        [bool]$Visible = $true,                        # パネルの初期表示状態
        [System.Drawing.Color]$背景色 = ([System.Drawing.Color]::FromArgb(240,240,240)),  # 背景色
        [bool]$枠線あり = $false                        # 枠線の有無
    )

    # パネル作成
    $フレームパネル = New-Object System.Windows.Forms.Panel
    $フレームパネル.Size = New-Object System.Drawing.Size($幅, $高さ)
    $フレームパネル.Location = New-Object System.Drawing.Point($X位置, $Y位置)
    $フレームパネル.AllowDrop = $true
    $フレームパネル.AutoScroll = $true
    $フレームパネル.Name = $フレーム名
    $フレームパネル.Visible = $Visible
    $フレームパネル.BackColor = $背景色

    if ($枠線あり) {
        $フレームパネル.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    }
    else {
        $フレームパネル.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    }

    # 描画オブジェクト用のプロパティを Tag に追加
    $フレームパネル.Tag = @{ DrawObjects = @() }

    # フレームのClickイベントを設定
    $フレームパネル.Add_Click({
        param($sender, $e)
        [System.Windows.Forms.MessageBox]::Show("フレームがクリックされました。")
    })

    # フレームをフォームに追加
    $フォーム.Controls.Add($フレームパネル)

    # Paintイベントの設定
    00_メインフレームパネルのPaintイベントを設定する -フレームパネル $フレームパネル

    # フレームを返す
    return $フレームパネル
}

function script:コンテキストメニューを初期化する {
    ###Write-Host "コンテキストメニューを初期化します。"
    if (-not $script:ContextMenuInitialized) {
        # コンテキストメニューをスクリプトスコープで定義
        $script:右クリックメニュー = New-Object System.Windows.Forms.ContextMenuStrip
        $script:名前変更メニューアイテム = $script:右クリックメニュー.Items.Add("名前変更")
        $script:スクリプト編集メニューアイテム = $script:右クリックメニュー.Items.Add("スクリプト編集")
        $script:スクリプト実行メニューアイテム = $script:右クリックメニュー.Items.Add("スクリプト実行")
        $script:削除メニューアイテム = $script:右クリックメニュー.Items.Add("削除")

        ###Write-Host "コンテキストメニュー項目を追加しました。"

        # イベントハンドラーの設定
        $script:名前変更メニューアイテム.Add_Click({ 
            ###Write-Host "名前変更メニューがクリックされました。"
            script:名前変更処理 
        })
        $script:スクリプト編集メニューアイテム.Add_Click({ 
            ###Write-Host "スクリプト編集メニューがクリックされました。"
            script:スクリプト編集処理 
        })
        $script:スクリプト実行メニューアイテム.Add_Click({ 
            ###Write-Host "スクリプト編集メニューがクリックされました。"
            script:スクリプト実行処理 
        })
        $script:削除メニューアイテム.Add_Click({ 
            ###Write-Host "削除メニューがクリックされました。"
            script:削除処理 
        })

        # イベントハンドラーが一度だけ設定されたことを記録
        $script:ContextMenuInitialized = $true
        ###Write-Host "コンテキストメニューの初期化が完了しました。"
    }
    else {
        ###Write-Host "コンテキストメニューは既に初期化されています。"
    }
}

function script:名前変更処理 {
    ###Write-Host "名前変更処理を開始します。"
    if ($null -ne $メインフォーム) {
        ###Write-Host "メインフォームを非表示にします。"
        $メインフォーム.Hide()
    }

    # 右クリック時に格納したボタンを取得
    $btn = $script:右クリックメニュー.Tag
    ###Write-Host "取得したボタン: $($btn.Name)"

    if ($btn -ne $null) {
        # 入力ボックスを表示して新しい名前を取得
        ###Write-Host "入力ボックスを表示して新しい名前を取得します。"
        $新しい名前 = [Microsoft.VisualBasic.Interaction]::InputBox(
            "新しいボタン名を入力してください:",  # プロンプト
            "ボタン名の変更",                    # タイトル
            $btn.Text                            # デフォルト値
        )
        ###Write-Host "ユーザーが入力した新しい名前: '$新しい名前'"

        # ユーザーが入力した場合のみテキストを更新
        if (![string]::IsNullOrWhiteSpace($新しい名前)) {
            ###Write-Host "ボタンのテキストを更新します。"
            $btn.Text = $新しい名前
        }
        else {
            ###Write-Host "新しい名前が入力されませんでした。変更をキャンセルします。"
        }
    }
    else {
        Write-Warning "ボタンが取得できませんでした。"
    }

    if ($null -ne $メインフォーム) {
        ###Write-Host "メインフォームを再表示します。"
        $メインフォーム.Show()
    }
    ###Write-Host "名前変更処理が完了しました。"
}

function script:スクリプト編集処理 {
    ###Write-Host "スクリプト編集処理を開始します。"
    if ($null -ne $メインフォーム) {
        ###Write-Host "メインフォームを非表示にします。"
        $メインフォーム.Hide()
    }

    # 右クリック時に格納したボタンを取得
    $btn = $script:右クリックメニュー.Tag
    ###Write-Host "取得したボタン: $($btn.Name)"

    if ($btn -ne $null) {
        $エントリID = $btn.Name.ToString()
        ###Write-Host "エントリID: $エントリID"

        # スクリプト編集用のフォームを作成
        ###Write-Host "スクリプト編集用フォームを作成します。"
        $編集フォーム = New-Object System.Windows.Forms.Form
        $編集フォーム.Text = "スクリプト編集"
        $編集フォーム.Size = New-Object System.Drawing.Size(600, 400)
        $編集フォーム.StartPosition = "CenterScreen"

        # スクリプト取得関数が存在する前提
        ###Write-Host "IDでエントリを取得します。"
        try {
            $取得したエントリ = IDでエントリを取得 -ID $エントリID
            ###Write-Host "取得したエントリ: $取得したエントリ"
        }
        catch {
            Write-Error "エントリの取得中にエラーが発生しました: $_"
            return
        }

        # テキストボックスの作成
        ###Write-Host "テキストボックスを作成します。"
        $テキストボックス = New-Object System.Windows.Forms.TextBox
        $テキストボックス.Multiline = $true
        $テキストボックス.ScrollBars = "Both"
        $テキストボックス.WordWrap = $false
        $テキストボックス.Size = New-Object System.Drawing.Size(580, 300)
        $テキストボックス.Font = New-Object System.Drawing.Font("Consolas", 10)
        $テキストボックス.Location = New-Object System.Drawing.Point(10, 10)
        $テキストボックス.Text = $取得したエントリ  # ボタンのタグに保存されたスクリプトを読み込む
        ###Write-Host "テキストボックスにスクリプトを設定しました。"

        # 保存ボタンの作成
        ###Write-Host "保存ボタンを作成します。"
        $保存ボタン = New-Object System.Windows.Forms.Button
        $保存ボタン.Text = "保存"
        $保存ボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $保存ボタン.Anchor = "Bottom, Right"
        $保存ボタン.Location = New-Object System.Drawing.Point(420, 330)
        $保存ボタン.Size = New-Object System.Drawing.Size(75, 25)

        # キャンセルボタンの作成
        ###Write-Host "キャンセルボタンを作成します。"
        $キャンセルボタン = New-Object System.Windows.Forms.Button
        $キャンセルボタン.Text = "キャンセル"
        $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $キャンセルボタン.Anchor = "Bottom, Right"
        $キャンセルボタン.Location = New-Object System.Drawing.Point(500, 330)
        $キャンセルボタン.Size = New-Object System.Drawing.Size(75, 25)

        # フォームにコントロールを追加
        ###Write-Host "フォームにコントロールを追加します。"
        $編集フォーム.Controls.Add($テキストボックス)
        $編集フォーム.Controls.Add($保存ボタン)
        $編集フォーム.Controls.Add($キャンセルボタン)

        # フォームのボタンを設定
        $編集フォーム.AcceptButton = $保存ボタン
        $編集フォーム.CancelButton = $キャンセルボタン

        # フォームをモーダルで表示
        ###Write-Host "スクリプト編集フォームを表示します。"
        $結果 = $編集フォーム.ShowDialog()
        ###Write-Host "スクリプト編集フォームが閉じられました。"

        if ($結果 -eq [System.Windows.Forms.DialogResult]::OK) {
            ###Write-Host "保存ボタンがクリックされました。エントリを置換します。"
            try {
                IDでエントリを置換 -ID $エントリID -新しい文字列 $テキストボックス.Text
                ###Write-Host "エントリの置換が完了しました。"
            }
            catch {
                Write-Error "エントリの置換中にエラーが発生しました: $_"
            }
        }
        else {
            ###Write-Host "編集がキャンセルされました。"
        }

        # 編集フォームを破棄
        ###Write-Host "編集フォームを破棄します。"
        $編集フォーム.Dispose()
    }
    else {
        Write-Warning "ボタンが取得できませんでした。"
    }

    if ($null -ne $メインフォーム) {
        ###Write-Host "メインフォームを再表示します。"
        $メインフォーム.Show()
    }
    ###Write-Host "スクリプト編集処理が完了しました。"
}

function script:スクリプト実行処理 {
    ###Write-Host "スクリプト実行処理を開始します。"
    if ($null -ne $メインフォーム) {
        ###Write-Host "メインフォームを非表示にします。"
        $メインフォーム.Hide()
    }

    # 右クリック時に格納したボタンを取得
    $btn = $script:右クリックメニュー.Tag
    ###Write-Host "取得したボタン: $($btn.Name)"

    if ($btn -ne $null) {
        $エントリID = $btn.Name.ToString()
        ###Write-Host "エントリID: $エントリID"

        # スクリプト実行用のフォームを作成
        ###Write-Host "スクリプト実行用フォームを作成します。"
        $実行フォーム = New-Object System.Windows.Forms.Form
        $実行フォーム.Text = "スクリプト実行"
        $実行フォーム.Size = New-Object System.Drawing.Size(600, 500)
        $実行フォーム.StartPosition = "CenterScreen"

        # スクリプト取得関数が存在する前提
        ###Write-Host "IDでエントリを取得します。"
        try {
            $取得したエントリ = IDでエントリを取得 -ID $エントリID
            ###Write-Host "取得したエントリ: $取得したエントリ"
        }
        catch {
            Write-Error "エントリの取得中にエラーが発生しました: $_"
            return
        }

        # スクリプト入力用テキストボックスの作成
        ###Write-Host "スクリプト入力用テキストボックスを作成します。"
        $テキストボックス = New-Object System.Windows.Forms.TextBox
        $テキストボックス.Multiline = $true
        $テキストボックス.ScrollBars = "Both"
        $テキストボックス.WordWrap = $false
        $テキストボックス.Size = New-Object System.Drawing.Size(580, 250)
        $テキストボックス.Font = New-Object System.Drawing.Font("Consolas", 10)
        $テキストボックス.Location = New-Object System.Drawing.Point(10, 10)
        $テキストボックス.Text = $取得したエントリ
        
        # コンソール出力用テキストボックスの作成
        ###Write-Host "コンソール用テキストボックスを作成します。"
        $コンソールボックス = New-Object System.Windows.Forms.TextBox
        $コンソールボックス.Multiline = $true
        $コンソールボックス.ScrollBars = "Both"
        $コンソールボックス.WordWrap = $false
        $コンソールボックス.ReadOnly = $true
        $コンソールボックス.Size = New-Object System.Drawing.Size(580, 150)
        $コンソールボックス.Font = New-Object System.Drawing.Font("Consolas", 10)
        $コンソールボックス.Location = New-Object System.Drawing.Point(10, 270)

        # 実行ボタンの作成
        ###Write-Host "実行ボタンを作成します。"
        $実行ボタン = New-Object System.Windows.Forms.Button
        $実行ボタン.Text = "実行"
        $実行ボタン.Anchor = "Bottom, Right"
        $実行ボタン.Location = New-Object System.Drawing.Point(420, 430)
        $実行ボタン.Size = New-Object System.Drawing.Size(75, 25)
        $実行ボタン.Add_Click({
            $output = Invoke-Expression $テキストボックス.Text 2>&1
            $コンソールボックス.Text = $output
        })

        # キャンセルボタンの作成
        ###Write-Host "キャンセルボタンを作成します。"
        $キャンセルボタン = New-Object System.Windows.Forms.Button
        $キャンセルボタン.Text = "キャンセル"
        $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $キャンセルボタン.Anchor = "Bottom, Right"
        $キャンセルボタン.Location = New-Object System.Drawing.Point(500, 430)
        $キャンセルボタン.Size = New-Object System.Drawing.Size(75, 25)

        # フォームにコントロールを追加
        ###Write-Host "フォームにコントロールを追加します。"
        $実行フォーム.Controls.Add($テキストボックス)
        $実行フォーム.Controls.Add($コンソールボックス)
        $実行フォーム.Controls.Add($実行ボタン)
        $実行フォーム.Controls.Add($キャンセルボタン)

        # フォームのボタンを設定
        $実行フォーム.CancelButton = $キャンセルボタン

        # フォームをモーダルで表示
        ###Write-Host "スクリプト実行フォームを表示します。"
        $実行フォーム.ShowDialog()
        ###Write-Host "スクリプト実行フォームが閉じられました。"
    }
    else {
        Write-Warning "ボタンが取得できませんでした。"
    }

    if ($null -ne $メインフォーム) {
        ###Write-Host "メインフォームを再表示します。"
        $メインフォーム.Show()
    }
    ###Write-Host "スクリプト実行処理が完了しました。"
}


function 条件分岐ボタン削除処理 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Windows.Forms.Button]$ボタン
    )

    #-----------------------------
    # ① 基本情報の取得
    #-----------------------------
    $parent  = $ボタン.Parent
    if (-not $parent) { return }

    $myY     = $ボタン.Location.Y
    $myText  = $ボタン.Text.Trim()

    #-----------------------------
    # ② 探索ターゲットを決定
    #-----------------------------
    switch ($myText) {
        '条件分岐 開始' {
            $方向     = '下'       # 自分より下側を探す
            $欲しい順 = @('条件分岐 中間','条件分岐 終了')
        }
        '条件分岐 終了' {
            $方向     = '上'       # 自分より上側を探す
            $欲しい順 = @('条件分岐 中間','条件分岐 開始')
        }
        default {
            Write-Verbose "SpringGreen だが対象外テキスト [$myText]"
            return
        }
    }

    #-----------------------------
    # ③ 兄弟コントロールから候補を抽出
    #-----------------------------
    #   $候補ハッシュ[テキスト] = 最も近い Control
    $候補ハッシュ = @{}

    foreach ($ctrl in $parent.Controls) {
        if (-not ($ctrl -is [System.Windows.Forms.Button])) { continue }
        $txt = $ctrl.Text.Trim()
        if ($txt -notin $欲しい順) { continue }

        $delta = $ctrl.Location.Y - $myY
        if (($方向 -eq '下' -and $delta -le 0) -or
            ($方向 -eq '上' -and $delta -ge 0)) { continue }   # 方向が逆なら除外

        $距離 = [math]::Abs($delta)

        # まだ登録されていない or もっと近いボタンなら採用
        if (-not $候補ハッシュ.ContainsKey($txt) -or
            $距離 -lt $候補ハッシュ[$txt].距離) {

            $候補ハッシュ[$txt] = [pscustomobject]@{
                Ctrl  = $ctrl
                距離  = $距離
            }
        }
    }

    #-----------------------------
    # ④ ３つ揃っているか判定
    #-----------------------------
    $削除対象 = @($ボタン)   # 自分自身は必ず削除
    foreach ($name in $欲しい順) {
        if ($候補ハッシュ.ContainsKey($name)) {
            $削除対象 += $候補ハッシュ[$name].Ctrl
        }
    }

    if ($削除対象.Count -lt 3) {
        Write-Warning "セットが揃わないため削除しません。"
        return
    }

    #-----------------------------
    # ⑤ 削除実行
    #-----------------------------
    # レイヤー番号を取得
    $レイヤー番号 = グローバル変数から数値取得 -パネル $parent
    $レイヤー表示 = if ($レイヤー番号) { "レイヤー$レイヤー番号" } else { "不明" }

    # 削除ログ
    Write-Host "[削除] $レイヤー表示`: 条件分岐 GroupID=$targetGID ($($削除対象.Count) 個)" -ForegroundColor Red

    foreach ($b in $削除対象) {
        try {
            $parent.Controls.Remove($b)
            $b.Dispose()
        }
        catch {
            Write-Warning "ボタン [$($b.Text)] の削除に失敗: $_"
        }
    }

    #-----------------------------
    # ⑥ 後処理（配置調整など）
    #-----------------------------
    if (Get-Command 00_ボタンの上詰め再配置関数 -ErrorAction SilentlyContinue) {
        00_ボタンの上詰め再配置関数 -フレーム $parent
    }
    if (Get-Command 00_矢印追記処理 -ErrorAction SilentlyContinue) {
        00_矢印追記処理 -フレームパネル $Global:可視左パネル
    }
}

function ループボタン削除処理 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Windows.Forms.Button]$ボタン
    )

    #-----------------------------
    # ① 親コンテナとGroupIDの取得
    #-----------------------------
    $parent = $ボタン.Parent
    if (-not $parent) { return }

    # ループ開始／終了ボタンには同じGroupIDが入っている想定
    $targetGroupID = $ボタン.Tag.GroupID

    #-----------------------------
    # ② 同じGroupIDを持つ LemonChiffon ボタンを収集
    #    （開始・終了の2個がそろうはず）
    #-----------------------------
    $候補ボタン一覧 = @()

    foreach ($ctrl in $parent.Controls) {
        # ボタン以外は無視
        if (-not ($ctrl -is [System.Windows.Forms.Button])) {
            continue
        }

        # 色がLemonChiffon以外は無視（ループ以外は対象外）
        if ($ctrl.BackColor.ToArgb() -ne [System.Drawing.Color]::LemonChiffon.ToArgb()) {
            continue
        }

        # GroupIDが一致するものだけ拾う
        if ($ctrl.Tag.GroupID -eq $targetGroupID) {
            $候補ボタン一覧 += $ctrl
        }
    }

    #-----------------------------
    # ③ 2つ揃っているかチェック
    #    片方だけ壊れてる場合は何もしないで警告
    #-----------------------------
    if ($候補ボタン一覧.Count -lt 2) {
        Write-Warning "ループ開始/終了のセットが揃わないため削除しません。"
        return
    }

    #-----------------------------
    # ④ 実際に削除
    #-----------------------------
    # レイヤー番号を取得
    $レイヤー番号 = グローバル変数から数値取得 -パネル $parent
    $レイヤー表示 = if ($レイヤー番号) { "レイヤー$レイヤー番号" } else { "不明" }

    # 削除ログ
    Write-Host "[削除] $レイヤー表示`: ループ GroupID=$targetGID ($($候補ボタン一覧.Count) 個)" -ForegroundColor Red

    foreach ($b in $候補ボタン一覧) {
        try {
            $parent.Controls.Remove($b)
            $b.Dispose()
        }
        catch {
            Write-Warning "ループボタン [$($b.Text)] の削除に失敗: $_"
        }
    }

    #-----------------------------
    # ⑤ 後処理（詰め直しと矢印再描画）
    #    条件分岐ボタン削除処理と同じ流れにそろえる
    #-----------------------------
    if (Get-Command 00_ボタンの上詰め再配置関数 -ErrorAction SilentlyContinue) {
        00_ボタンの上詰め再配置関数 -フレーム $parent
    }
    if (Get-Command 00_矢印追記処理 -ErrorAction SilentlyContinue) {
        00_矢印追記処理 -フレームパネル $Global:可視左パネル
    }
}





function script:削除処理 {
    # 右クリック時に格納したボタンを取得
    $btn = $script:右クリックメニュー.Tag

    # ★★ 条件分岐（緑）専用削除 ★★
    if ($btn.BackColor -eq [System.Drawing.Color]::SpringGreen) {
        条件分岐ボタン削除処理 -ボタン $btn
        return   # 条件分岐はここで完結
    }
    # ★★ ループ（黄）専用削除 ★★
    elseif ($btn.BackColor -eq [System.Drawing.Color]::LemonChiffon) {
        ループボタン削除処理 -ボタン $btn
        return   # ループはここで完結
    }

    # ここから下は従来の「普通の1個だけ消す」ルート
    if ($btn -ne $null) {
        if ($btn.Parent -ne $null) {
            try {
                # レイヤー番号を取得
                $レイヤー番号 = グローバル変数から数値取得 -パネル $btn.Parent
                $レイヤー表示 = if ($レイヤー番号) { "レイヤー$レイヤー番号" } else { "不明" }

                # 削除ログ
                Write-Host "[削除] $レイヤー表示`: $($btn.Name) - $($btn.Text)" -ForegroundColor Red

                $btn.Parent.Controls.Remove($btn)
                $btn.Dispose()

                # 外部関数が定義されている場合のみ実行
                if (Get-Command 00_ボタンの上詰め再配置関数 -ErrorAction SilentlyContinue) {
                    00_ボタンの上詰め再配置関数 -フレーム $btn.Parent
                }

                if (Get-Command 00_矢印追記処理 -ErrorAction SilentlyContinue) {
                    00_矢印追記処理 -フレームパネル $Global:可視左パネル
                }
            }
            catch {
                Write-Error "ボタンの削除中にエラーが発生しました: $_"
            }
        }
    }
}

function script:ボタンクリック情報表示 {
    param (
        [System.Windows.Forms.Button]$sender
    )
   
#    if ($global:グループモード -eq 1 -and $sender.Parent.Name -eq $Global:可視左パネル.Name) {
   


    # Shiftキーが押されている場合に処理を変更
    if ([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift -and $sender.Parent.Name -eq $Global:可視左パネル.Name) {





        # グループモードの場合の処理内容をここに記述
 $グループ情報 = @"
グループモード情報:
  ボタン名: $($sender.Name)
  ボタンテキスト: $($sender.Text)
  グループ内での処理を実行中...
"@

        # 既にグループモードが適用されている場合はリセット
        if ($sender.FlatStyle -eq [System.Windows.Forms.FlatStyle]::Flat -and $sender.FlatAppearance.BorderColor -eq [System.Drawing.Color]::Red) {
            ###Write-Host "既にグループモードが適用されているため、リセットします。"

            #$sender.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
            $sender.FlatAppearance.BorderColor = [System.Drawing.Color]::Black
            $sender.FlatAppearance.BorderSize = 1

        }
        else {
            ###Write-Host "グループモードを適用します。"

            # グループモードの適用処理
            #$sender.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $sender.FlatAppearance.BorderColor = [System.Drawing.Color]::Red
            $sender.FlatAppearance.BorderSize = 3
        }
        適用-赤枠に挟まれたボタンスタイル -フレームパネル $Global:可視左パネル #$global:レイヤーパネル
               #Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show("g3", "タイトル")

    }
    else {
        ##Write-Host "通常モードで処理を実行します。"

        # ========================================
        # 🔍 Tag.script チェック（常に出力）
        # ========================================
        Write-Host "" -ForegroundColor Magenta
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
        Write-Host "[🔍 TAG CHECK] ノードクリック時のTag.script確認" -ForegroundColor Magenta
        Write-Host "    ノード名: $($sender.Name)" -ForegroundColor White
        Write-Host "    背景色: $($sender.BackColor)" -ForegroundColor White
        Write-Host "    Tag: $($sender.Tag)" -ForegroundColor White
        Write-Host "    Tag.script: $($sender.Tag.script)" -ForegroundColor White
        Write-Host "    条件判定: `$sender.Tag.script -eq 'スクリプト' → $($sender.Tag.script -eq 'スクリプト')" -ForegroundColor Yellow
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
        Write-Host "" -ForegroundColor Magenta

      #  if ($sender.BackColor -eq [System.Drawing.Color]::Pink -and $sender.Parent.Name -eq $Global:可視左パネル.Name) {
        if ($sender.Tag.script -eq "スクリプト") {  # 親パネルチェックを削除

            # ========================================
            # 🔍 デバッグログ: スクリプト化ノードクリック開始
            # ========================================
            Write-Host "" -ForegroundColor Cyan
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
            Write-Host "[🔍 DEBUG] スクリプト化ノードがクリックされました" -ForegroundColor Cyan
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

            # Pinkノードの親パネルを取得
            $親パネル = $sender.Parent
            Write-Host "[1] ノード情報:" -ForegroundColor Yellow
            Write-Host "    ノード名: $($sender.Name)" -ForegroundColor White
            Write-Host "    テキスト: $($sender.Text)" -ForegroundColor White
            Write-Host "    親パネル: $($親パネル.Name)" -ForegroundColor White
            Write-Host "    Tag.script: $($sender.Tag.script)" -ForegroundColor White

            # 親パネルのレイヤー番号を取得
            $親レイヤー番号 = グローバル変数から数値取得 -パネル $親パネル
            Write-Host "" -ForegroundColor Yellow
            Write-Host "[2] 親レイヤー番号: $親レイヤー番号" -ForegroundColor Yellow

            if ($親レイヤー番号 -eq $null) {
                Write-Host "❌ エラー: 親パネルのレイヤー番号を取得できませんでした" -ForegroundColor Red
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                return
            }

            # 次のレイヤー番号を計算
            $次のレイヤー番号 = [int]$親レイヤー番号 + 1
            Write-Host "    次のレイヤー番号: $次のレイヤー番号" -ForegroundColor White

            # 次のレイヤーパネルを取得
            $次のレイヤー変数名 = "レイヤー$次のレイヤー番号"
            Write-Host "" -ForegroundColor Yellow
            Write-Host "[3] 次のパネル確認:" -ForegroundColor Yellow
            Write-Host "    変数名: `$Global:$次のレイヤー変数名" -ForegroundColor White

            if (Get-Variable -Name $次のレイヤー変数名 -Scope Global -ErrorAction SilentlyContinue) {
                $次のパネル = (Get-Variable -Name $次のレイヤー変数名 -Scope Global).Value
                Write-Host "    ✅ パネル取得成功" -ForegroundColor Green
                Write-Host "       パネル名: $($次のパネル.Name)" -ForegroundColor White
                Write-Host "       表示状態: $($次のパネル.Visible)" -ForegroundColor White
                Write-Host "       位置: X=$($次のパネル.Location.X), Y=$($次のパネル.Location.Y)" -ForegroundColor White
                Write-Host "       サイズ: W=$($次のパネル.Width), H=$($次のパネル.Height)" -ForegroundColor White
            } else {
                Write-Host "    ❌ エラー: レイヤー$次のレイヤー番号 は存在しません（最大レイヤー数を超えています）" -ForegroundColor Red
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                return
            }

            # 現在の可視パネルの状態を確認
            Write-Host "" -ForegroundColor Yellow
            Write-Host "[4] 現在の可視パネル状態:" -ForegroundColor Yellow
            Write-Host "    可視左パネル: $($Global:可視左パネル.Name)" -ForegroundColor White
            Write-Host "    可視右パネル: $($Global:可視右パネル.Name)" -ForegroundColor White
            Write-Host "    不可視右の右パネル: $($Global:不可視右の右パネル.Name)" -ForegroundColor White

            # グローバル変数に座標を格納
            $A = [int]$親レイヤー番号
            Write-Host "" -ForegroundColor Yellow
            Write-Host "[5] Pink選択配列の更新:" -ForegroundColor Yellow
            Write-Host "    更新前の値: $($Global:Pink選択配列[$A].値)" -ForegroundColor White
            Write-Host "    更新前の展開ボタン: $($Global:Pink選択配列[$A].展開ボタン)" -ForegroundColor White

            $Global:Pink選択配列[$A].Y座標 = $sender.Location.Y +15
            $Global:Pink選択配列[$A].値 = 1
            $Global:Pink選択配列[$A].展開ボタン = $sender.Name
            $Global:現在展開中のスクリプト名 = $sender.Name
            $Global:Pink選択中 = $true

            Write-Host "    更新後の値: $($Global:Pink選択配列[$A].値)" -ForegroundColor Green
            Write-Host "    更新後の展開ボタン: $($Global:Pink選択配列[$A].展開ボタン)" -ForegroundColor Green
            Write-Host "    Y座標: $($Global:Pink選択配列[$A].Y座標)" -ForegroundColor White

            # 次のパネルをクリアして展開
            Write-Host "" -ForegroundColor Yellow
            Write-Host "[6] 次のパネルをクリア:" -ForegroundColor Yellow
            Write-Host "    クリア対象: $($次のパネル.Name)" -ForegroundColor White
            $クリア前のボタン数 = ($次のパネル.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] }).Count
            Write-Host "    クリア前のボタン数: $クリア前のボタン数" -ForegroundColor White

            フレームパネルからすべてのボタンを削除する -フレームパネル $次のパネル

            $クリア後のボタン数 = ($次のパネル.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] }).Count
            Write-Host "    クリア後のボタン数: $クリア後のボタン数" -ForegroundColor Green

            Write-Host "" -ForegroundColor Yellow
            Write-Host "[7] コードエントリ取得:" -ForegroundColor Yellow
            $取得したエントリ = IDでエントリを取得 -ID $sender.Name
            Write-Host "    ノードID: $($sender.Name)" -ForegroundColor White
            if ($取得したエントリ) {
                Write-Host "    ✅ エントリ取得成功" -ForegroundColor Green
                $エントリ行数 = ($取得したエントリ -split "`r?`n").Count
                Write-Host "       エントリ行数: $エントリ行数" -ForegroundColor White
                Write-Host "       エントリ内容（最初の3行）:" -ForegroundColor White
                ($取得したエントリ -split "`r?`n" | Select-Object -First 3) | ForEach-Object {
                    Write-Host "         $_" -ForegroundColor Gray
                }
            } else {
                Write-Host "    ❌ エラー: エントリが取得できませんでした" -ForegroundColor Red
            }

            # ノード数をカウント
            $ノード行 = ($取得したエントリ -split "`r?`n" | Where-Object { $_.Trim() -ne "" -and $_ -notmatch "^AAAA" }).Count
            Write-Host "    展開するノード数: $ノード行 個" -ForegroundColor White

            # Pink展開ログ
            Write-Host "" -ForegroundColor Magenta
            Write-Host "[Pink展開] レイヤー$親レイヤー番号 → レイヤー$次のレイヤー番号`: $($sender.Name) - $($sender.Text) ($ノード行 個)" -ForegroundColor Magenta

            # 展開先パネルを指定してボタンを作成
            Write-Host "" -ForegroundColor Yellow
            Write-Host "[8] PINKからボタン作成を呼び出します:" -ForegroundColor Yellow
            Write-Host "    展開先パネル: $($次のパネル.Name)" -ForegroundColor White

            PINKからボタン作成 -文字列 $取得したエントリ -展開先パネル $次のパネル

            $作成後のボタン数 = ($次のパネル.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] }).Count
            Write-Host "    作成後のボタン数: $作成後のボタン数" -ForegroundColor Green

            # レイヤー階層の深さを更新
            Write-Host "" -ForegroundColor Yellow
            Write-Host "[9] レイヤー階層の深さ更新:" -ForegroundColor Yellow
            Write-Host "    更新前: $($Global:レイヤー階層の深さ)" -ForegroundColor White
            $Global:レイヤー階層の深さ = $次のレイヤー番号
            Write-Host "    更新後: $($Global:レイヤー階層の深さ)" -ForegroundColor Green

            # 矢印追記処理
            Write-Host "" -ForegroundColor Yellow
            Write-Host "[10] 矢印追記処理:" -ForegroundColor Yellow
            Write-Host "     対象パネル: $($親パネル.Name)" -ForegroundColor White
            00_矢印追記処理 -フレームパネル $親パネル
            Write-Host "     ✅ 矢印追記完了" -ForegroundColor Green

            Write-Host "" -ForegroundColor Cyan
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
            Write-Host "[✅ DEBUG] スクリプト化ノード展開処理完了" -ForegroundColor Cyan
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
            Write-Host "" -ForegroundColor Cyan
        }

$情報 = @"
ボタン情報:
  名前: $($sender.Name)
  テキスト: $($sender.Text)
  サイズ: $($sender.Size.Width) x $($sender.Size.Height)
  位置: X=$($sender.Location.X), Y=$($sender.Location.Y)
  背景色: $($sender.BackColor)
"@

        ##Write-Host "情報をメッセージボックスで表示します。"
        [System.Windows.Forms.MessageBox]::Show($情報, "ボタン情報", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }

    ###Write-Host "ボタンクリック情報表示処理が完了しました。"
}



function PINKからボタン作成 {
    param (
        [string]$文字列,
        [System.Windows.Forms.Panel]$展開先パネル = $Global:可視右パネル  # デフォルトは可視右パネル
    )

    Write-Host "========== [PINKからボタン作成] 開始 ==========" -ForegroundColor Cyan
    Write-Host "  展開先パネル名: $($展開先パネル.Name)" -ForegroundColor Cyan
    Write-Host "  展開先パネル位置: X=$($展開先パネル.Location.X), Y=$($展開先パネル.Location.Y)" -ForegroundColor Cyan
    Write-Host "  展開先パネル可視: $($展開先パネル.Visible)" -ForegroundColor Cyan
    $プレビュー文字列 = $文字列.Substring(0, [Math]::Min(100, $文字列.Length)) -replace "`r", "" -replace "`n", " | "
    Write-Host "  文字列プレビュー: $プレビュー文字列" -ForegroundColor Cyan

    $初期Y = 20 # Y座標の初期値
    $作成されたボタン数 = 0

    # 文字列を改行で分割し、最初の1行をスキップ
    $文字列 -split "`r?`n" | Select-Object -Skip 1 | ForEach-Object {
        # 各行をセミコロンで分割
        $parts = $_ -split ';'

        # 各部分を変数に割り当て
        $ボタン名 = $parts[0].Trim()
        $背景色名 = $parts[1].Trim()
        $テキスト = $parts[2].Trim()

        # タイプが存在しない場合（スクリプト化ノード）は、テキストをタイプとして使用
        if ($parts.Count -ge 4 -and $parts[3]) {
            $タイプ = $parts[3].Trim()
        } else {
            $タイプ = $テキスト  # スクリプト化ノードの場合、テキスト（"スクリプト"）をタイプとして使用
        }

        #-----------------------------------------------------------------------------------------------------

        # 色名からSystem.Drawing.Colorオブジェクトを取得
        try {
            # 色名から色を取得
            $背景色 = [System.Drawing.Color]::FromName($背景色名)
            if (!$背景色.IsKnownColor) {
                throw "無効な色名"
            }
        }
        catch {
            # 色名が無効な場合、色コードとして解析を試みる
            try {
                # HEXカラーコード（#なし）を検出し、自動で#を付加
                if ($背景色名 -match '^[0-9A-Fa-f]{6}$' -or $背景色名 -match '^[0-9A-Fa-f]{8}$') {
                    $hexColor = "#$背景色名"
                    $背景色 = [System.Drawing.ColorTranslator]::FromHtml($hexColor)
                }
                # HEXカラーコード（#あり）を検出
                elseif ($背景色名 -match '^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$') {
                    $背景色 = [System.Drawing.ColorTranslator]::FromHtml($背景色名)
                }
                # RGB形式（例: 255,0,255）を検出
                elseif ($背景色名 -match '^\d{1,3},\d{1,3},\d{1,3}$') {
                    $rgb = $背景色名 -split ','
                    $背景色 = [System.Drawing.Color]::FromArgb(
                        [int]$rgb[0],
                        [int]$rgb[1],
                        [int]$rgb[2]
                    )
                }
                else {
                    throw "無効な色指定"
                }
            }
            catch {
                Write-Host "    警告: 色名または色コードが無効です。ボタンの作成をスキップします。 - 色名: $背景色名" -ForegroundColor Yellow
                Write-Host "    - 内容: $_" -ForegroundColor Yellow
                return
            }
        }

        # デバッグ出力
        ##Write-Host "ボタン名: $ボタン名, 背景色: $背景色名, テキスト: $テキスト" -ForegroundColor Green

        $幅 = 120
        $初期X = [Math]::Floor(($展開先パネル.ClientSize.Width - $幅) / 2)# 中央配置のためのX座標を計算

        # ボタンテキストが "条件分岐 中間" の場合
        if ($テキスト -eq "条件分岐 中間") {
        $調整Y = $初期Y - 5
        $新ボタン = 00_ボタンを作成する -コンテナ $展開先パネル -テキスト $テキスト -ボタン名 $ボタン名 -幅 $幅 -高さ 1 -X位置 $初期X -Y位置 $調整Y -枠線 1 -背景色 $背景色 -ドラッグ可能 $false
        Write-Host "    作成: [$ボタン名] $テキスト (中間ボタン) Y=$調整Y" -ForegroundColor DarkCyan
        $初期Y += 10
        }else{
        $新ボタン = 00_ボタンを作成する -コンテナ $展開先パネル -テキスト $テキスト -ボタン名 $ボタン名 -幅 $幅 -高さ 30 -X位置 $初期X -Y位置 $初期Y -枠線 1 -背景色 $背景色 -ドラッグ可能 $true　-ボタンタイプ "ノード"　-ボタンタイプ2 $タイプ
        Write-Host "    作成: [$ボタン名] $テキスト (通常ボタン) Y=$初期Y 色=$背景色名 タイプ=$タイプ" -ForegroundColor DarkCyan
        Write-Host "           → Tag.script設定: $($新ボタン.Tag.script)" -ForegroundColor $(if ($新ボタン.Tag.script -eq 'スクリプト') {'Green'} else {'Yellow'})
        $初期Y += 50
        }

        $作成されたボタン数++

    }

    Write-Host "  合計作成ボタン数: $作成されたボタン数" -ForegroundColor Cyan
    Write-Host "  最終パネル内ボタン総数: $($展開先パネル.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] } | Measure-Object).Count" -ForegroundColor Cyan
    Write-Host "  矢印処理を実行..." -ForegroundColor Cyan
    # Paintイベントはパネル作成時に既に設定されているため、ここでは矢印の更新のみ実行
    00_矢印追記処理 -フレームパネル $展開先パネル
    Write-Host "========== [PINKからボタン作成] 完了 ==========" -ForegroundColor Cyan
}

function 00_ボタンを作成する {
    param (
        [System.Windows.Forms.Control]$コンテナ,          # ボタンを追加するコンテナ（フレーム）
        [string]$テキスト = "ドラッグで移動",              # ボタンのテキスト
        [string]$ボタン名,                                # ボタン名
        [int]$幅 = 120,                                   # ボタンの幅
        [int]$高さ = 30,                                  # ボタンの高さ
        [int]$X位置 = 10,                                 # ボタンのX座標
        [int]$Y位置 = 20,                                 # ボタンのY座標
        [int]$枠線 = 0,                                   # ボタンの枠線サイズ
        [System.Drawing.Color]$背景色,                    # ボタンの背景色（必須）
        [bool]$ドラッグ可能 = $true,                      # ドラッグ可能かどうか
        [int]$フォントサイズ = 10,
        [string]$ボタンタイプ = "なし",
        [string]$ボタンタイプ2 = "なし",
        [string]$処理番号 = "なし"
    )

    ###Write-Host "00_ボタンを作成します。ボタン名: $ボタン名"
    
    # コンテキストメニューの初期化
    script:コンテキストメニューを初期化する

    # ボタンの作成
    ###Write-Host "ボタンを作成します。"
    $ボタン = New-Object System.Windows.Forms.Button
    $ボタン.Text = $テキスト #$ボタン名 # 
    $ボタン.Size = New-Object System.Drawing.Size($幅, $高さ)
    $ボタン.Location = New-Object System.Drawing.Point($X位置, $Y位置)
    $ボタン.AllowDrop = $false                            # ボタン自体のドロップを無効化
    $ボタン.Name = $ボタン名                              # ボタンのNameプロパティを設定
    $ボタン.BackColor = $背景色                           # ボタンの背景色を設定
    $ボタン.UseVisualStyleBackColor = $false              # BackColorを有効にする

    ###Write-Host "ボタンのフォントを設定します。"
    # フォントサイズの設定
    $ボタン.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", $フォントサイズ)

    $ボタン.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ボタン.FlatAppearance.BorderSize = $枠線

    $ボタン.Tag = @{
        BackgroundColor = $背景色
        GroupID = $null
        MultiLineTags = $null # 必要に応じて設定
        script = $null # 必要に応じて設定
        処理番号 = $処理番号
    } # 背景色をTagプロパティに保存

      if ($ボタンタイプ2 -eq "スクリプト") {
      $ボタン.Tag.script = "スクリプト"
      }

    # コンテキストメニューを設定
    $ボタン.ContextMenuStrip = $script:右クリックメニュー

    if ($ドラッグ可能) {
        ###Write-Host "ドラッグ可能なボタンの設定をします。"
        # フラグを追加
        $ボタン.Tag.IsDragging = $false
        $ボタン.Tag.StartPoint = [System.Drawing.Point]::Empty

        # ボタンのMouseDownイベントでドラッグの開始と右クリックの処理を設定
        ###Write-Host "MouseDownイベントハンドラーを追加します。"
        $ボタン.Add_MouseDown({
            param($sender, $e)
            ###Write-Host "MouseDownイベントが発生しました。ボタン: $($sender.Name), ボタン: $($e.Button)"
            if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
                # ドラッグ開始位置を記録
                ###Write-Host "左クリックが検出されました。ドラッグ開始位置を記録します。"
                $sender.Tag.StartPoint = $e.Location
                $sender.Tag.IsDragging = $false
            }
            elseif ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
                ###Write-Host "右クリックが検出されました。"
                # 右クリック処理（必要に応じて追加）
            }
        })

        # ボタンのMouseMoveイベントでドラッグの判定
        ###Write-Host "MouseMoveイベントハンドラーを追加します。"
        $ボタン.Add_MouseMove({
            param($sender, $e)
            if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
                if (-not $sender.Tag.IsDragging) {
                    # マウスが移動した距離を計算
                    $dx = [Math]::Abs($e.X - $sender.Tag.StartPoint.X)
                    $dy = [Math]::Abs($e.Y - $sender.Tag.StartPoint.Y)
                    ###Write-Host "マウス移動距離: dx=$dx, dy=$dy"
                    if ($dx -ge 5 -or $dy -ge 5) {
                        ###Write-Host "ドラッグを開始します。"
                        $sender.Tag.IsDragging = $true
                        # ドラッグ中のボタンを設定
                        $global:ドラッグ中のボタン = $sender
                        # ドラッグを開始
                        $sender.DoDragDrop($sender, [System.Windows.Forms.DragDropEffects]::Move)
                    }
                }
            }
        })

        # ボタンのDragDropイベントで位置を更新
        ###Write-Host "DragDropイベントハンドラーを追加します。"
        $ボタン.Add_DragDrop({
            param($sender, $e)
            ###Write-Host "DragDropイベントが発生しました。"
            if ($global:ドラッグ中のボタン -ne $null) {
                $targetButton = $e.Data.GetData([System.Windows.Forms.DataFormats]::Object)
                if ($targetButton -ne $null -and $targetButton -is [System.Windows.Forms.Button]) {
                    ###Write-Host "ドラッグ中のボタンを移動します。ボタン: $($targetButton.Name)"
                    # 親コンテナ内でボタンのインデックスを変更
                    $sender.Parent.Controls.SetChildIndex($targetButton, 0)
                    # 新しい位置を計算
                    $newLocation = $sender.PointToClient($e.Location)
                    ###Write-Host "新しい位置: X=$($newLocation.X), Y=$($newLocation.Y)"
                    $targetButton.Location = $newLocation
                    $global:ドラッグ中のボタン = $null
                }
                else {
                    Write-Warning "ドラッグデータがボタンではありません。"
                }
            }
            else {
                Write-Warning "ドラッグ中のボタンが存在しません。"
            }
        })

        # ボタンのDragEnterイベントでエフェクトを設定
        ###Write-Host "DragEnterイベントハンドラーを追加します。"
        $ボタン.Add_DragEnter({
            param($sender, $e)
            if ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::Object)) {
                ###Write-Host "DragEnter: Moveエフェクトを設定します。"
                $e.Effect = [System.Windows.Forms.DragDropEffects]::Move
            }
            else {
                ###Write-Host "DragEnter: Moveエフェクトを設定できません。"
            }
        })
    }

    # ボタンクリック時に情報を表示するイベントハンドラーを追加
    ###Write-Host "Clickイベントハンドラーを追加します。"
    if ($ボタンタイプ -eq "ノード") {

    $ボタン.Add_Click({
        param($sender, $e)


        ###Write-Host "Clickイベントが発生しました。ボタン: $($sender.Name)"
        script:ボタンクリック情報表示 -sender $sender
    })
    } else {
        # Falseの処理内容
    }

    


    # 右クリック時にメニュー表示、その時点で対象ボタンをTagへ
    ###Write-Host "MouseUpイベントハンドラーを追加します。"
    $ボタン.Add_MouseUp({
        param($sender, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
            ###Write-Host "右クリックが検出されました。メニューを表示します。"
            $script:右クリックメニュー.Tag = $sender
            $script:右クリックメニュー.Show($sender, $e.Location)
        }
    })

    # コンテナにボタンを追加
    ###Write-Host "ボタンをコンテナに追加します。"
    $コンテナ.Controls.Add($ボタン)

    # ボタンオブジェクトを返す
    ###Write-Host "ボタンの作成が完了しました。"
    return $ボタン
}

function 00_メインにボタンを作成する {
    param (
        [System.Windows.Forms.Control]$コンテナ,          # ボタンを追加するコンテナ（フレーム）
        [string]$テキスト = "ドラッグで移動",              # ボタンのテキスト
        [string]$ボタン名,                                # ボタン名
        [int]$幅 = 120,                                   # ボタンの幅
        [int]$高さ = 30,                                  # ボタンの高さ
        [int]$X位置 = 10,                                 # ボタンのX座標
        [int]$Y位置 = 20,                                 # ボタンのY座標
        [int]$枠線 = 1,                                   # ボタンの枠線サイズ
        [System.Drawing.Color]$背景色,                    # ボタンの背景色（必須）
        [int]$フォントサイズ = 10,                        # フォントサイズ
        [scriptblock]$クリックアクション                   # ボタンクリック時のアクション
    )

    $ボタン = New-Object System.Windows.Forms.Button
    $ボタン.Text = $テキスト -replace "`n", [Environment]::NewLine # 改行を反映
    $ボタン.Size = New-Object System.Drawing.Size($幅, $高さ)
    $ボタン.Location = New-Object System.Drawing.Point($X位置, $Y位置)
    $ボタン.AllowDrop = $false                            # ボタン自体のドロップを無効化
    $ボタン.Name = $ボタン名                              # ボタンのNameプロパティを設定
    $ボタン.BackColor = $背景色                           # ボタンの背景色を設定
    $ボタン.UseVisualStyleBackColor = $false              # BackColorを有効にする
    $ボタン.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

    ###Write-Host "ボタンのフォントを設定します。"
    # フォントサイズの設定
    $ボタン.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", $フォントサイズ)

    $ボタン.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ボタン.FlatAppearance.BorderSize = $枠線

    # クリックイベントの登録
    $ボタン.Add_Click({
        param($sender, $e)
        ###Write-Host "Clickイベントが発生しました。ボタン: $($sender.Name)"
    
        if ($sender.Name -eq "001") {
            # 001 に対するアクション
            表示-赤枠ボタン名一覧 -フレームパネル $Global:可視左パネル
        } elseif ($sender.Name -eq "002") {
            # 002 に対するアクション
        $global:グループモード = 1
        } elseif ($sender.Name -eq "003右") {
            # 右矢印クリック時（画面が右に移動 = レイヤーを戻る）

            $最後の文字 = グローバル変数から数値取得　-パネル $Global:可視左パネル
            ##Write-Host "左パネル" $最後の文字

            if ($最後の文字 -ge 2) {
                # Trueの処理内容（$数値が2以上の場合）
                矢印を削除する -フォーム $メインフォーム
                メインフレームの右を押した場合の処理
            } else {
                # Falseの処理内容（$数値が1以下の場合）
            }

            00_矢印追記処理 -フレームパネル $Global:可視左パネル
       } elseif ($sender.Name -eq "004左") {
            # 左矢印クリック時（画面が左に移動 = レイヤーを進む）

            $最後の文字 = グローバル変数から数値取得　-パネル $Global:可視左パネル
            ##Write-Host "左パネル" $最後の文字

            # ========================================
            # バリデーション: スクリプト展開中かチェック
            # ========================================
            if ($最後の文字 -ge 1) {
                # レイヤー1以降の場合、スクリプト展開中かチェック
                $現在のレイヤー番号 = [int]$最後の文字

                if ($Global:Pink選択配列[$現在のレイヤー番号].値 -ne 1) {
                    # スクリプト展開中でない場合、エラーメッセージを表示
                    $メッセージ = "レイヤー$($現在のレイヤー番号 + 1) に進むには、`n" +
                                "レイヤー$現在のレイヤー番号 でスクリプト化ノードを展開してください。`n`n" +
                                "操作手順:`n" +
                                "1. Shift を押しながら複数のノードをクリック（赤枠が付きます）`n" +
                                "2. 「レイヤー化」ボタンをクリック`n" +
                                "3. 作成されたスクリプト化ノード（ピンク色）をクリック`n" +
                                "4. 次のレイヤーに展開されます"

                    [System.Windows.Forms.MessageBox]::Show(
                        $メッセージ,
                        "スクリプト展開が必要です",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Warning
                    )

                    Write-Host "[❌ 左矢印] レイヤー$現在のレイヤー番号 でスクリプト展開中ではないため、進めません" -ForegroundColor Red
                    return  # 処理を中断
                }

                Write-Host "[✅ 左矢印] レイヤー$現在のレイヤー番号 でスクリプト展開中を確認。レイヤー$($現在のレイヤー番号 + 1) に進みます" -ForegroundColor Green
            }

            if ($最後の文字 -le 3) {
                # Trueの処理内容（$数値が3以下の場合）
                矢印を削除する -フォーム $メインフォーム
                メインフレームの左を押した場合の処理
            } else {
                # Falseの処理内容（$数値が4以上の場合）
            }

            00_矢印追記処理 -フレームパネル $Global:可視左パネル


        } elseif ($sender.Name -eq "CLEAR_ALL") {
            # 全ノード削除ボタンの処理
            $result = [System.Windows.Forms.MessageBox]::Show(
                "現在のレイヤーの全てのノードを削除しますか？`nこの操作は元に戻せません。",
                "全ノード削除の確認",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )

            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                # 削除前のノード数をカウント
                $削除数 = ($Global:可視左パネル.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] }).Count
                $レイヤー番号 = グローバル変数から数値取得 -パネル $Global:可視左パネル
                $レイヤー表示 = if ($レイヤー番号) { "レイヤー$レイヤー番号" } else { "不明" }

                # 現在のレイヤーの全ボタンを削除
                フレームパネルからすべてのボタンを削除する -フレームパネル $Global:可視左パネル
                # 矢印も更新
                00_矢印追記処理 -フレームパネル $Global:可視左パネル

                # 全削除ログ
                Write-Host "[全削除] $レイヤー表示`: $削除数 個のノードを削除" -ForegroundColor Yellow
            }

        }else {
            ###Write-Host "ボタン名が001または002ではありません。アクションは実行されません。"
        }

# メインフレームのPaintイベントを設定
00_メインフレームパネルのPaintイベントを設定する -フレームパネル $Global:可視左パネル

# メインフレームのDragEnterイベントを設定
00_フレームのDragEnterイベントを設定する -フレーム $Global:可視左パネル

# メインフレームのDragDropイベントを設定
00_フレームのDragDropイベントを設定する -フレーム $Global:可視左パネル



    })

    # コンテナにボタンを追加
    ###Write-Host "ボタンをコンテナに追加します。"
    $コンテナ.Controls.Add($ボタン)

    # ボタンオブジェクトを返す
    ###Write-Host "ボタンの作成が完了しました。"
    return $ボタン
}


function 00_汎用色ボタンを作成する {
  param (
    [System.Windows.Forms.Control]$コンテナ,     # ボタンを追加するコンテナ（フレーム）
    [string]$テキスト,                # ボタンのテキスト
    [string]$ボタン名,                # ボタン名
    [int]$幅,                     # ボタンの幅
    [int]$高さ,                    # ボタンの高さ
    [int]$X位置,                   # ボタンのX座標
    [int]$Y位置,                   # ボタンのY座標
    [System.Drawing.Color]$背景色           # ボタンの背景色
  )

  # ボタンの作成
  $色ボタン = New-Object System.Windows.Forms.Button

  # --- 基本レイアウト関連 ---
  $色ボタン.Text = $テキスト                                     # ボタン上に表示するテキスト
  $色ボタン.Size = New-Object System.Drawing.Size($幅, $高さ)     # ボタンの表示サイズ
  $色ボタン.Location = New-Object System.Drawing.Point($X位置, $Y位置) # ボタンの配置座標
  $色ボタン.Name = $ボタン名                                     # コントロール名
  $色ボタン.Font = New-Object System.Drawing.Font("Meiryo UI", 10, [System.Drawing.FontStyle]::Bold)
  # ↑ 太字＋読みやすいフォント。細字がいいなら Bold 外してもOK。

  # --- 背景色と文字色の適用 ---
  $色ボタン.BackColor = $背景色
  $色ボタン.ForeColor = [System.Drawing.Color]::Black             # ← 文字色を黒に固定
  $色ボタン.UseVisualStyleBackColor = $false                      # テーマ依存にしない

  # --- フラット&枠線なし設定 ---
  $色ボタン.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat    # フラット表示
  $色ボタン.FlatAppearance.BorderSize = 0                         # 枠線なし
  $色ボタン.FlatAppearance.BorderColor = $背景色                  # 念のため同色で塗りつぶし扱い

  # --- ホバー・クリック時の色変化を抑止 ---
  $色ボタン.FlatAppearance.MouseOverBackColor = $背景色           # ホバー時の背景色
  $色ボタン.FlatAppearance.MouseDownBackColor = $背景色           # クリック時の背景色

  # --- メタ情報をTagに保存（元コードの意図を維持）---
  $色ボタン.Tag = @{
    BackgroundColor = $背景色
    GroupID = $null
  }

  # --- コンテナに追加 ---
  $コンテナ.Controls.Add($色ボタン)

  # --- 作ったボタンを返す（後でイベントとか貼る用）---
  return $色ボタン
}


function 00_汎用色ボタンのクリックイベントを設定する {
    param(
        [System.Windows.Forms.Button]$ボタン,
        [int]$生成ボタンの高さ = 30,
        [int]$生成ボタンの幅 = 120,
        [int]$生成ボタンの間隔 = 20,
        [int]$引数 = 0,
        [string]$処理番号
    )

    # ボタンのTagに関連情報を保存
    $ボタン.Tag = @{
        ボタン高さ      = $生成ボタンの高さ
        間隔           = $生成ボタンの間隔
        幅             = $生成ボタンの幅
        処理番号       = $処理番号
        BackgroundColor = $ボタン.BackColor
    }

    # クリックイベントを設定
    $ボタン.Add_Click({
        param($sender, $e)

        # Tagから必要な情報を取得
        $tag = $sender.Tag
        $buttonColor = $tag.BackgroundColor
        $buttonText  = $sender.Text
        $buttonName  = IDを自動生成する

        $ボタン高さ = $tag.ボタン高さ
        $間隔     = $tag.間隔
        $幅       = $tag.幅

        $メインフレームパネル = $Global:可視左パネル
        $global:レイヤーパネル = $メインフレームパネル
        $初期X = [Math]::Floor(($メインフレームパネル.ClientSize.Width - $幅) / 2)

        # 初期Y位置を計算する関数
        function Get-NextYPosition {
            param(
                [System.Windows.Forms.Control]$panel,
                [int]$高さ,
                [int]$間隔
            )
            if ($panel.Controls.Count -eq 0) {
                return $間隔
            }
            else {
                $最下ボタン = $panel.Controls |
                    Where-Object { $_ -is [System.Windows.Forms.Button] } |
                    Sort-Object { $_.Location.Y } |
                    Select-Object -Last 1
                return $最下ボタン.Location.Y + $高さ + $間隔
            }
        }

        $初期Y = Get-NextYPosition -panel $メインフレームパネル -高さ $ボタン高さ -間隔 $間隔

        switch ($buttonText) {
            "ループ" {
                # グループIDを取得・更新
                $currentGroupID = $global:黄色ボタングループカウンタ
                Write-Host "[ループ作成] GroupID=$currentGroupID を割り当て"
                $global:黄色ボタングループカウンタ++

                # 開始ボタンの作成
                $ボタン1 = 00_ボタンを作成する -コンテナ $メインフレームパネル -テキスト "$buttonText 開始" -ボタン名 "$buttonName-1" -幅 $幅 -高さ $ボタン高さ -X位置 $初期X -Y位置 $初期Y -枠線 1 -背景色 $buttonColor -ドラッグ可能 $true　-ボタンタイプ "ノード" -処理番号 $tag.処理番号
                $ボタン1.Tag.GroupID = $currentGroupID
                Write-Host "[設定完了] $($ボタン1.Name) にGroupID=$($ボタン1.Tag.GroupID) を設定"
                $global:ボタンカウンタ++

                # 終了ボタンの作成
                $初期Y += $ボタン高さ + $間隔
                $ボタン2 = 00_ボタンを作成する -コンテナ $メインフレームパネル -テキスト "$buttonText 終了" -ボタン名 "$buttonName-2" -幅 $幅 -高さ $ボタン高さ -X位置 $初期X -Y位置 $初期Y -枠線 1 -背景色 $buttonColor -ドラッグ可能 $true　-ボタンタイプ "ノード" -処理番号 $tag.処理番号
                00_文字列処理内容 -ボタン名 $buttonName -処理番号 $tag.処理番号
                $ボタン2.Tag.GroupID = $currentGroupID
                Write-Host "[設定完了] $($ボタン2.Name) にGroupID=$($ボタン2.Tag.GroupID) を設定"
                $global:ボタンカウンタ++
            }
            "条件分岐" {
                # グループIDを取得・更新
                $currentGroupID = $global:緑色ボタングループカウンタ
                Write-Host "[条件分岐作成] GroupID=$currentGroupID を割り当て"
                $global:緑色ボタングループカウンタ++

                # 開始ボタンの作成
                $ボタン1 = 00_ボタンを作成する -コンテナ $メインフレームパネル -テキスト "$buttonText 開始" -ボタン名 "$buttonName-1" -幅 $幅 -高さ $ボタン高さ -X位置 $初期X -Y位置 $初期Y -枠線 1 -背景色 $buttonColor -ドラッグ可能 $true　-ボタンタイプ "ノード" -処理番号 $tag.処理番号
                $ボタン1.Tag.GroupID = $currentGroupID
                Write-Host "[設定完了] $($ボタン1.Name) にGroupID=$($ボタン1.Tag.GroupID) を設定"
                $global:ボタンカウンタ++

                # 中間ボタン（グレーライン）の作成
                $初期Y += $ボタン高さ + $間隔
                $ボタン中間 = 00_ボタンを作成する -コンテナ $メインフレームパネル -テキスト "$buttonText 中間" -ボタン名 "$buttonName-2" -幅 $幅 -高さ 1 -X位置 $初期X -Y位置 ($初期Y - 10) -枠線 1 -背景色 ([System.Drawing.Color]::Gray) -ドラッグ可能 $false　-ボタンタイプ "ノード" -処理番号 $tag.処理番号
                $ボタン中間.Tag.GroupID = $currentGroupID
                Write-Host "[設定完了] $($ボタン中間.Name) にGroupID=$($ボタン中間.Tag.GroupID) を設定（中間ノード）"

                # 終了ボタンの作成
                $ボタン2 = 00_ボタンを作成する -コンテナ $メインフレームパネル -テキスト "$buttonText 終了" -ボタン名 "$buttonName-3" -幅 $幅 -高さ $ボタン高さ -X位置 $初期X -Y位置 $初期Y -枠線 1 -背景色 $buttonColor -ドラッグ可能 $true　-ボタンタイプ "ノード" -処理番号 $tag.処理番号
                00_文字列処理内容 -ボタン名 $buttonName -処理番号 $tag.処理番号
                $ボタン2.Tag.GroupID = $currentGroupID
                Write-Host "[設定完了] $($ボタン2.Name) にGroupID=$($ボタン2.Tag.GroupID) を設定"
                $global:ボタンカウンタ++
            }
            default {

                # 順次実行ボタンの作成
                $新ボタン = 00_ボタンを作成する -コンテナ $メインフレームパネル -テキスト $buttonText -ボタン名 "$buttonName-1" -幅 $幅 -高さ $ボタン高さ -X位置 $初期X -Y位置 $初期Y -枠線 1 -背景色 $buttonColor -ドラッグ可能 $true　-ボタンタイプ "ノード" -処理番号 $tag.処理番号
                00_文字列処理内容 -ボタン名 $buttonName -処理番号 $tag.処理番号 -ボタン $新ボタン

                #$currentIndex = Get-ButtonIndex -対象ボタン $新ボタン -フレームパネル $メインフレームパネル
                $global:ボタンカウンタ++

            }
        }

        # 矢印の追記処理
        00_矢印追記処理 -フレームパネル $Global:可視左パネル
    })
}

# JSONファイルから指定キーの値を取得する関数
function 取得-JSON値 {
    param (
        [string]$jsonFilePath, # JSONファイルのパス
        [string]$keyName       # 取得したいキー名
    )
    # ファイルを確認
    if (-Not (Test-Path $jsonFilePath)) {
        throw "指定されたファイルが見つかりません: $jsonFilePath"
    }

    # JSONファイルを読み込み
    $jsonContent = Get-Content -Path $jsonFilePath | ConvertFrom-Json

    # 指定されたキーの値を取得
    if ($jsonContent.PSObject.Properties[$keyName]) {
        return $jsonContent.$keyName
    } else {
        throw "指定されたキーがJSONに存在しません: $keyName"
    }
}

function フォームにラベル追加 {
    param (
        [Parameter(Mandatory)]
        [System.Windows.Forms.Form]$フォーム, # フォームオブジェクト
        
        [Parameter(Mandatory)]
        [string]$テキスト, # ラベルに表示するテキスト
        
        [Parameter(Mandatory)]
        [int]$X座標, # ラベルのX座標
        
        [Parameter(Mandatory)]
        [int]$Y座標  # ラベルのY座標
    )
    # ラベルを作成
    $ラベル = New-Object System.Windows.Forms.Label
    $ラベル.Text = $テキスト
    $ラベル.Location = New-Object System.Drawing.Point($X座標, $Y座標)
    #$ラベル.AutoSize = $true

    # フォントスタイルを設定（型キャストを追加）
    $フォントスタイル = [System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold)
    $ラベル.Font = New-Object System.Drawing.Font("Arial", 10, $フォントスタイル)

    # テキストの色を設定
    $ラベル.ForeColor = [System.Drawing.Color]::black

    # 背景色を設定（透明にする場合は不要）
    #$ラベル.BackColor = [System.Drawing.Color]::LightYellow

    # テキストの配置を設定
    $ラベル.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

    # フォームにラベルを追加
    $フォーム.Controls.Add($ラベル)
}

# ボタンのインデックスを取得する関数
function Get-ButtonIndex {
    param (
        [System.Windows.Forms.Button]$対象ボタン,
        [System.Windows.Forms.Panel]$フレームパネル
    )

    # フレーム内のボタンをY座標でソート
    $sortedButtons = $フレームパネル.Controls |
                     Where-Object { $_ -is [System.Windows.Forms.Button] } |
                     Sort-Object { $_.Location.Y }

    # インデックスを取得
    $index = 0
    foreach ($btn in $sortedButtons) {
        if ($btn -eq $対象ボタン) {
            return $index
        }
        $index++
    }

    # ボタンが見つからない場合は-1を返す
    return -1
}

function 適用-赤枠に挟まれたボタンスタイル {
    param (
        [System.Windows.Forms.Panel]$フレームパネル
    )
          #Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show($フレームパネル.Name, "タイトル")
    # コントロールをデバッグ出力
    ###Write-Host "=== デバッグ: コントロール一覧 ==="
    foreach ($control in $フレームパネル.Controls) {
        ##Write-Host "コントロール: $($control.GetType().Name), Text: $($control.Text)"
    }
    ###Write-Host "==============================="

    # フレーム内のボタンを取得してソート
    $ソート済みボタン = $フレームパネル.Controls |
                        Where-Object { $_ -is [System.Windows.Forms.Button] } |
                        Sort-Object { $_.Location.Y }

    #Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show($ソート済みボタン.Count, "タイトル")

    # デバッグ: ボタン情報を出力
    ###Write-Host "=== デバッグ: ボタン情報 ==="
    foreach ($ボタン in $ソート済みボタン) {
        $枠色 = if ($ボタン.FlatStyle -eq 'Flat') {
            $ボタン.FlatAppearance.BorderColor
                      #Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show("q", "タイトル")
        } else {
            "未設定"

        }
        ###Write-Host "ボタン: $($ボタン.Text), 枠の色: $枠色, FlatStyle: $($ボタン.FlatStyle), Location: $($ボタン.Location)"
    }
    ###Write-Host "==========================="

    # 赤枠のボタンのインデックスを探す
    $赤枠ボタンインデックス = @()
    for ($i = 0; $i -lt $ソート済みボタン.Count; $i++) {
        $ボタン = $ソート済みボタン[$i]
        # デバッグ: 色比較の結果を詳細に出力
        if ($ボタン.FlatStyle -eq 'Flat') {
            $現在の色 = $ボタン.FlatAppearance.BorderColor
            ###Write-Host "デバッグ: ボタン[$($ボタン.Text)] の枠色 (ARGB): $($現在の色.ToArgb())"

            if ($現在の色.ToArgb() -eq [System.Drawing.Color]::Red.ToArgb()) {
                ###Write-Host "赤枠ボタン検出: $($ボタン.Text) (インデックス: $i)"
                $赤枠ボタンインデックス += $i
            }
        }
    }

    # 赤枠ボタンが2つ以上ある場合に処理を実行
    if ($赤枠ボタンインデックス.Count -ge 2) {
        $開始インデックス = $赤枠ボタンインデックス[0]
        $終了インデックス = $赤枠ボタンインデックス[-1]
          #Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show("aka2izyo", "タイトル")
        # 赤枠に挟まれたボタンにスタイルを適用
        ###Write-Host "赤枠に挟まれたボタン:"
        for ($i = $開始インデックス + 1; $i -lt $終了インデックス; $i++) {
            $挟まれたボタン = $ソート済みボタン[$i]
            ###Write-Host " - $($挟まれたボタン.Text) にスタイルを適用します。"

            # スタイルを適用
            $挟まれたボタン.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $挟まれたボタン.FlatAppearance.BorderColor = [System.Drawing.Color]::Red
            $挟まれたボタン.FlatAppearance.BorderSize = 3
        }


    } else {
        ###Write-Host "赤枠のボタンが2つ以上存在しません。"
    }
}

function 表示-赤枠ボタン名一覧 {
    param (
        [System.Windows.Forms.Panel]$フレームパネル
    )
    $global:グループモード = 0

    # フレーム内のボタンを取得してソート
    $ソート済みボタン = $フレームパネル.Controls |
                        Where-Object { $_ -is [System.Windows.Forms.Button] } |
                        Sort-Object { $_.Location.Y }

    # 赤枠のボタンの名前とY位置を収集
    $赤枠ボタンリスト = @()
    foreach ($ボタン in $ソート済みボタン) {
        if ($ボタン.FlatStyle -eq 'Flat' -and 
            $ボタン.FlatAppearance.BorderColor.ToArgb() -eq [System.Drawing.Color]::Red.ToArgb()) {
            $赤枠ボタンリスト += @{
                Name = $ボタン.Name
                Y位置 = $ボタン.Location.Y
            }
        }
    }



    # 赤枠のボタンの名前一覧を出力し、削除
    if ($赤枠ボタンリスト.Count -gt 0) {


        $最小Y位置 = [int]::MaxValue  # 削除対象ボタンの最小Y位置を取得するための変数
        $削除したボタン情報 = @()         # 削除したボタンの情報を格納する配列

        foreach ($ボタン情報 in $赤枠ボタンリスト) {
            $名前 = $ボタン情報.Name
            $Y位置 = $ボタン情報.Y位置


            if ($Y位置 -lt $最小Y位置) {            # 最小Y位置を更新
                $最小Y位置 = $Y位置
            }

            $削除対象ボタン = $フレームパネル.Controls[$名前]            # ボタンを取得
            
            if ($削除対象ボタン -ne $null) {
                $ボタン色 = $削除対象ボタン.BackColor.Name                # ボタンの背景色とテキストを取得
                $テキスト = $削除対象ボタン.Text
                $タイプ = $削除対象ボタン.Tag.script

                $フレームパネル.Controls.Remove($削除対象ボタン)                # ボタンをパネルから削除
                $削除対象ボタン.Dispose()                # 必要に応じてボタンを破棄
          
                $削除したボタン情報 += "$名前;$ボタン色;$テキスト;$タイプ"                # 削除したボタンの情報を配列に追加（名前-ボタン色-テキスト）

            }
            else {
                ###Write-Host "ボタン '$名前' が見つかりませんでした。"
            }
        }

        $初期Y = $最小Y位置        # 削除された赤枠ボタンの中で最も上のY位置を初期Y位置として設定
        $entryString = $削除したボタン情報 -join "_"         # 削除したボタンの情報をアンダースコアで連結した文字列に変換

       # [System.Windows.Forms.MessageBox]::Show($entryString , "debug情報表示", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

        $最後の文字 = グローバル変数から数値取得　-パネル $Global:可視左パネル 

        $A = [int]$最後の文字

        # $フレームパネル   $初期Y
        $Global:Pink選択配列[$A].初期Y = $初期Y
        $Global:Pink選択配列[$A].値 = 1



        # 新しいボタンの作成
        $buttonName  = IDを自動生成する
        $幅 = 120
        $初期X = [Math]::Floor(($フレームパネル.ClientSize.Width - $幅) / 2)
        $新ボタン = 00_ボタンを作成する -コンテナ $フレームパネル -テキスト "スクリプト" -ボタン名 "$buttonName-1" -幅 120 -高さ 30 -X位置 $初期X -Y位置 $初期Y -枠線 1 -背景色 ([System.Drawing.Color]::Pink) -ドラッグ可能 $true -ボタンタイプ "ノード" -ボタンタイプ2 "スクリプト"

        00_文字列処理内容 -ボタン名 "$buttonName" -処理番号 "99-1" -直接エントリ $entryString -ボタン $新ボタン

        # レイヤー番号を取得
        $レイヤー番号 = グローバル変数から数値取得 -パネル $フレームパネル
        $レイヤー表示 = if ($レイヤー番号) { "レイヤー$レイヤー番号" } else { "不明" }

        # レイヤー化ログ
        Write-Host "[レイヤー化] $レイヤー表示`: $($赤枠ボタンリスト.Count) 個 → $buttonName-1" -ForegroundColor Green

        # ボタンカウンタのインクリメント
        $global:ボタンカウンタ++

        # ボタンの再配置（必要に応じて）
        00_ボタンの上詰め再配置関数 -フレーム $フレームパネル
        00_矢印追記処理 -フレームパネル $フレームパネル
    } else {
        #Write-Host "赤枠のボタンが存在しません。"
    }
}

function フレームパネルからすべてのボタンを削除する {
    param (
        [System.Windows.Forms.Panel]$フレームパネル
    )

    # パネル内のすべてのボタンを取得
    $ボタンリスト = $フレームパネル.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] }

    foreach ($ボタン in $ボタンリスト) {
        try {
            # ボタンをパネルから削除
            $フレームパネル.Controls.Remove($ボタン)

            # ボタンのリソースを解放
            $ボタン.Dispose()

            ##Write-Host "ボタン '$($ボタン.Name)' を削除しました。" -ForegroundColor Green
        }
        catch {
            ##Write-Host "ボタン '$($ボタン.Name)' の削除中にエラーが発生しました。 - $_" -ForegroundColor Red
        }
    }

    # 必要に応じて、再描画をトリガー
    $フレームパネル.Invalidate()
}

# 矢印を描く関数
function 矢印を描く {
    param (
        [int]$幅,
        [int]$高さ,
        [System.Drawing.Point]$始点,
        [System.Drawing.Point]$終点,
        [float]$矢印サイズ = 10.0,    # 矢印ヘッドのサイズ
        [float]$矢印角度 = 30.0      # 矢印ヘッドの角度（度数法）
    )

    # デバッグ: 受け取った始点と終点を表示
    #Write-Host "矢印を描く - 始点: ($($始点.X), $($始点.Y)), 終点: ($($終点.X), $($終点.Y))"

    # Bitmap を作成（32bppArgb で透明度をサポート）
    $bitmap = New-Object System.Drawing.Bitmap($幅, $高さ, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $グラフィックス = [System.Drawing.Graphics]::FromImage($bitmap)

    # 背景色を透明に設定
    $グラフィックス.Clear([System.Drawing.Color]::Transparent)

    # ペンの設定
    $ペン = New-Object System.Drawing.Pen([System.Drawing.Color]::Pink, 2)

    try {
        # メインラインを描画
        $グラフィックス.DrawLine($ペン, $始点, $終点)

        # ベクトルの計算
        $dx = $終点.X - $始点.X
        $dy = $終点.Y - $始点.Y
        $長さ = [math]::Sqrt($dx * $dx + $dy * $dy)

        if ($長さ -eq 0) { 
            #Write-Host "矢印の長さが0のため、矢印ヘッドを描画できません。"
            return $bitmap
        }

        # 単位ベクトル
        $ux = $dx / $長さ
        $uy = $dy / $長さ

        # 矢印ヘッドの角度をラジアンに変換
        $角度ラジアン = [math]::PI * $矢印角度 / 180.0

        # 矢印ヘッドのポイント計算
        $sin = [math]::Sin($角度ラジアン)
        $cos = [math]::Cos($角度ラジアン)

        $点1X = [math]::Round($終点.X - $矢印サイズ * ($cos * $ux + $sin * $uy))
        $点1Y = [math]::Round($終点.Y - $矢印サイズ * ($cos * $uy - $sin * $ux))
        $点2X = [math]::Round($終点.X - $矢印サイズ * ($cos * $ux - $sin * $uy))
        $点2Y = [math]::Round($終点.Y - $矢印サイズ * ($cos * $uy + $sin * $ux))

        $点1 = New-Object System.Drawing.Point -ArgumentList $点1X, $点1Y
        $点2 = New-Object System.Drawing.Point -ArgumentList $点2X, $点2Y

        # デバッグ: 矢印ヘッドの点を表示
        #Write-Host "矢印ヘッドの点1: ($($点1.X), $($点1.Y)), 点2: ($($点2.X), $($点2.Y))"

        # 矢印ヘッドを描画
        $グラフィックス.DrawLine($ペン, $終点, $点1)
        $グラフィックス.DrawLine($ペン, $終点, $点2)
    }
    catch {
        #Write-Host "描画中にエラーが発生しました: $_"
    }
    finally {
        # リソースの解放
        $ペン.Dispose()
        $グラフィックス.Dispose()
    }

    return $bitmap
}

# 矢印を表示する関数
function 矢印を表示する {
    param (
        [System.Windows.Forms.Form]$フォーム,
        [int]$幅,
        [int]$高さ,
        [System.Drawing.Point]$始点,
        [System.Drawing.Point]$終点,
        [float]$矢印サイズ = 10.0,    # 矢印ヘッドのサイズ
        [float]$矢印角度 = 30.0,     # 矢印ヘッドの角度（度数法）
        [int]$PictureBoxX = 0,        # PictureBoxのX座標
        [int]$PictureBoxY = 0,        # PictureBoxのY座標
        [int]$PictureBox幅 = 1400,    # PictureBoxの幅
        [int]$PictureBox高さ = 900     # PictureBoxの高さ
    )

    # デバッグ: 受け取った始点と終点を表示
    #Write-Host "矢印を表示する - 始点: ($($始点.X), $($始点.Y)), 終点: ($($終点.X), $($終点.Y))"

    # 矢印を描く関数を呼び出して Bitmap を取得
    $bitmap = 矢印を描く -幅 $幅 -高さ $高さ -始点 $始点 -終点 $終点 -矢印サイズ $矢印サイズ -矢印角度 $矢印角度
    #Write-Host "矢印の描画が完了しました。"

    # PictureBox を作成
    $pictureBox = New-Object System.Windows.Forms.PictureBox
    $pictureBox.Name = "ArrowPictureBox"  # 名前を設定
    $pictureBox.Image = $bitmap
    $pictureBox.Location = New-Object System.Drawing.Point($PictureBoxX, $PictureBoxY)
    $pictureBox.Size = New-Object System.Drawing.Size($PictureBox幅, $PictureBox高さ)
    $pictureBox.SizeMode = "Normal"  # AutoSize ではなく Normal に設定
    $pictureBox.BackColor =  [System.Drawing.Color]::FromArgb(255, 255, 255)  # 背景を一時的に黄色に設定して確認
    $pictureBox.Parent = $フォーム  # 親をフォームに設定
    $pictureBox.BringToFront()      # PictureBoxを前面に移動

    # デバッグ: PictureBox の位置とサイズを表示
    #Write-Host "PictureBox の位置: ($PictureBoxX, $PictureBoxY), サイズ: ($PictureBox幅, $PictureBox高さ)"

    # PictureBox をフォームに追加
    $フォーム.Controls.Add($pictureBox)
}

function 矢印を削除する {
    param (
        [System.Windows.Forms.Form]$フォーム
    )

    # 名前でPictureBoxを検索
    $pictureBox = $フォーム.Controls | Where-Object { $_.Name -eq "ArrowPictureBox" }

    if ($pictureBox) {
        # PictureBoxをフォームから削除
        $フォーム.Controls.Remove($pictureBox)
        $pictureBox.Dispose()
        #Write-Host "矢印を削除しました。"
    }
    else {
        ##Write-Host "矢印が見つかりませんでした。"
    }
}

function Check-Pink選択配列Objects {
    #Write-Host "---- Check-Pink選択配列Objects 関数開始 ----"

    # グローバル変数が存在するか確認
    if (-not (Test-Path variable:Global:Pink選択配列)) {
        Write-Warning "グローバル変数 'Pink選択配列' が存在しません。"
        #Write-Host "結果: FALSE"
        return $false
    } else {
        #Write-Host "グローバル変数 'Pink選択配列' は存在します。"
    }

    # グローバル変数が配列であるか確認
    if (-not ($Global:Pink選択配列 -is [System.Array])) {
        Write-Warning "'Pink選択配列' は配列ではありません。"
        #Write-Host "現在の値: $($Global:Pink選択配列)"
        #Write-Host "結果: FALSE"
        return $false
    } else {
        #Write-Host "'Pink選択配列' は配列です。"
    }

    # 各オブジェクトをループして、'値' プロパティが1かどうかをチェック
    foreach ($item in $Global:Pink選択配列) {
        #Write-Host "`n--- レイヤー $($item.レイヤー) の内容 ---"
        #Write-Host "初期Y: $($item.初期Y)"
        #Write-Host "値: $($item.値)"

        if ($item.値 -eq 1) {
            #Write-Host "レイヤー $($item.レイヤー) の値が1です。"
            #Write-Host "結果: TRUE"
            return $true
        } else {
            #Write-Host "レイヤー $($item.レイヤー) の値は1ではありません。"
        }
    }

    # すべてのレイヤーの値が0の場合
    #Write-Host "`nすべてのレイヤーの値が0です。"
    #Write-Host "結果: FALSE"
    return $false
}

# ========================================
# 階層パス表示機能
# ========================================

function 階層パスを取得する {
    <#
    .SYNOPSIS
    現在のレイヤーまでの階層パスを取得します。

    .DESCRIPTION
    Pink選択配列から展開ボタン名を取得し、階層パスを構築します。
    例: "レイヤー0 → 82-1(スクリプト) → レイヤー1 → 85-1(スクリプト) → レイヤー2"

    .PARAMETER 現在のレイヤー番号
    現在表示しているレイヤーの番号（0-6）

    .OUTPUTS
    System.String 階層パス文字列
    #>
    param (
        [int]$現在のレイヤー番号
    )

    if ($現在のレイヤー番号 -eq 0) {
        return "レイヤー0"
    }

    $パス部分 = @()
    $パス部分 += "レイヤー0"

    for ($i = 0; $i -lt $現在のレイヤー番号; $i++) {
        $展開ボタン = $Global:Pink選択配列[$i].展開ボタン

        # ★ 修正（問題#3対応）: レイヤー0→レイヤー1は初期状態なので特別扱い
        if ($i -eq 0 -and ($展開ボタン -eq $null -or $展開ボタン -eq 0 -or $展開ボタン -eq "")) {
            # レイヤー0→レイヤー1は初期レイヤーなので、展開ボタンなしで直接遷移
            $パス部分 += "→ レイヤー1"
        } elseif ($展開ボタン -and $展開ボタン -ne 0) {
            # 展開ボタン名を取得
            $パス部分 += "→ $展開ボタン"
            $パス部分 += "→ レイヤー$($i + 1)"
        } else {
            # 展開ボタンが記録されていない場合（通常は発生しない）
            $パス部分 += "→ [不明]"
            $パス部分 += "→ レイヤー$($i + 1)"
        }
    }

    return ($パス部分 -join " ")
}

function 階層パス表示を更新する {
    <#
    .SYNOPSIS
    階層パス表示ラベルを更新します。

    .DESCRIPTION
    現在のレイヤー番号を取得し、階層パスを計算してラベルに表示します。
    #>

    # 階層パスラベルが存在するか確認
    if (-not $Global:階層パス表示ラベル) {
        Write-Warning "階層パス表示ラベルが初期化されていません。"
        return
    }

    # 現在のレイヤー番号を取得
    $現在のレイヤー番号 = グローバル変数から数値取得 -パネル $Global:可視左パネル

    if ($null -eq $現在のレイヤー番号) {
        $現在のレイヤー番号 = 0
    }

    # 階層パスを取得
    $階層パス = 階層パスを取得する -現在のレイヤー番号 $現在のレイヤー番号

    # ラベルのテキストを更新
    $Global:階層パス表示ラベル.Text = "📍 階層パス: $階層パス"

    # デバッグログ出力
    Write-Host "[階層パス] $階層パス" -ForegroundColor Cyan
}

