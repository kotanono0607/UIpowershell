# Windows Formsを利用するためのアセンブリを読み込み
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# メインフォームのPaintイベントでパネル間矢印を描画する関数
function 00_メインフォームのPaintイベントを設定する {
    param (
        [System.Windows.Forms.Form]$フォーム
    )

    $フォーム.Add_Paint({
        param($sender, $e)

        # ピンク選択中かチェック
        if ($Global:Pink選択中 -ne "true") {
            return
        }

        # 左パネルのピンクボタンを取得
        $leftPanelButtons = $Global:可視左パネル.Controls |
            Where-Object { $_ -is [System.Windows.Forms.Button] } |
            Sort-Object { $_.Location.Y }

        $selectedPinkButton = $leftPanelButtons | Where-Object {
            ($_.BackColor.ToArgb() -eq [System.Drawing.Color]::Pink.ToArgb()) -or
            ($_.BackColor.ToArgb() -eq $global:ピンク青色.ToArgb()) -or
            ($_.BackColor.ToArgb() -eq $global:ピンク赤色.ToArgb())
        } | Select-Object -First 1

        if (-not $selectedPinkButton) {
            return
        }

        # 右パネルの最初のボタンを取得
        $rightPanelFirstButton = $Global:可視右パネル.Controls |
            Where-Object { $_ -is [System.Windows.Forms.Button] } |
            Sort-Object { $_.Location.Y } |
            Select-Object -First 1

        if (-not $rightPanelFirstButton) {
            return
        }

        # 右パネルが表示されているかチェック
        if (-not $Global:可視右パネル.Visible) {
            return
        }

        # 座標をフォーム座標系に変換
        # 左パネルのピンクボタンの中央Y座標
        $leftButtonCenterY = $Global:可視左パネル.Location.Y + $selectedPinkButton.Location.Y + ($selectedPinkButton.Height / 2)

        # 右パネルの最初のボタンの中央Y座標
        $rightButtonCenterY = $Global:可視右パネル.Location.Y + $rightPanelFirstButton.Location.Y + ($rightPanelFirstButton.Height / 2)

        # 左パネルの右端と右パネルの左端
        $leftPanelRightX = $Global:可視左パネル.Location.X + $Global:可視左パネル.Width
        $rightPanelLeftX = $Global:可視右パネル.Location.X

        # 鮮やかなピンク色
        $pinkLineColor = [System.Drawing.Color]::HotPink
        $pen = New-Object System.Drawing.Pen($pinkLineColor, 3)

        # アンチエイリアシングを有効化
        $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

        # 矢印パス（パネル間のギャップ部分のみ）：左パネル右端 → 縦に移動 → 右パネル左端

        # 1. 横ライン（左パネル右端から右に少し延長）
        $gapStartX = $leftPanelRightX
        $gapExtendX = $leftPanelRightX + 10
        $startPoint1 = [System.Drawing.Point]::new($gapStartX, $leftButtonCenterY)
        $endPoint1 = [System.Drawing.Point]::new($gapExtendX, $leftButtonCenterY)
        $e.Graphics.DrawLine($pen, $startPoint1, $endPoint1)

        # 2. 縦ライン（左パネル右端付近 → 右ボタンの高さ）
        $startPoint2 = $endPoint1
        $endPoint2 = [System.Drawing.Point]::new($gapExtendX, $rightButtonCenterY)
        $e.Graphics.DrawLine($pen, $startPoint2, $endPoint2)

        # 3. 横ライン（左パネル右端付近 → 右パネル左端）
        $startPoint3 = $endPoint2
        $endPoint3 = [System.Drawing.Point]::new($rightPanelLeftX, $rightButtonCenterY)
        $e.Graphics.DrawLine($pen, $startPoint3, $endPoint3)

        # ========================================
        # 戻り矢印（右パネル → 左パネル）ループ形状
        # ========================================
        # 右パネルの最後のボタンを取得
        $rightPanelLastButton = $Global:可視右パネル.Controls |
            Where-Object { $_ -is [System.Windows.Forms.Button] } |
            Sort-Object { $_.Location.Y } |
            Select-Object -Last 1

        # 左パネルのピンクノードの次のボタンを取得
        $leftPanelButtons = $Global:可視左パネル.Controls |
            Where-Object { $_ -is [System.Windows.Forms.Button] } |
            Sort-Object { $_.Location.Y }

        $leftPanelPinkButton = $leftPanelButtons | Where-Object {
            ($_.BackColor.ToArgb() -eq [System.Drawing.Color]::Pink.ToArgb()) -or
            ($_.BackColor.ToArgb() -eq $global:ピンク青色.ToArgb()) -or
            ($_.BackColor.ToArgb() -eq $global:ピンク赤色.ToArgb())
        } | Select-Object -First 1

        if ($rightPanelLastButton) {
            # 右パネルの最後のボタンの中央Y座標
            $rightLastButtonCenterY = $Global:可視右パネル.Location.Y + $rightPanelLastButton.Location.Y + ($rightPanelLastButton.Height / 2)

            # 左パネルのピンクボタンの中央Y座標（ループの戻り先の高さ）
            $loopTopY = $leftButtonCenterY

            # 左パネルの戻り先を決定（ピンクノードの次のボタン）
            $leftReturnY = 0

            if ($leftPanelPinkButton) {
                # ピンクノードの次のボタンを取得
                $pinkIndex = [array]::IndexOf($leftPanelButtons, $leftPanelPinkButton)
                $leftPanelNextButton = $null
                if ($pinkIndex -ge 0 -and $pinkIndex -lt ($leftPanelButtons.Count - 1)) {
                    $leftPanelNextButton = $leftPanelButtons[$pinkIndex + 1]
                }

                if ($leftPanelNextButton) {
                    # 次のボタンがある場合：そのボタンの中央Y座標
                    $leftReturnY = $Global:可視左パネル.Location.Y + $leftPanelNextButton.Location.Y + ($leftPanelNextButton.Height / 2)
                } else {
                    # 次のボタンがない場合：ピンクノードの下50px
                    $leftReturnY = $Global:可視左パネル.Location.Y + $leftPanelPinkButton.Location.Y + $leftPanelPinkButton.Height + 50
                }
            } else {
                # ピンクノードがない場合：適当な位置（使われないはずだが念のため）
                $leftReturnY = $Global:可視左パネル.Location.Y + 100
            }

            # ループ形状の矢印パス：
            # 右パネル左端 → 左に延長 → 上に移動（ループのトップまで） → 左パネル右端 → 下に移動（戻り先まで）

            # 1. 横ライン（右パネル左端から左に延長）
            $returnGapStartX = $rightPanelLeftX
            $returnGapExtendX = $rightPanelLeftX - 10
            $returnStartPoint1 = [System.Drawing.Point]::new($returnGapStartX, $rightLastButtonCenterY)
            $returnEndPoint1 = [System.Drawing.Point]::new($returnGapExtendX, $rightLastButtonCenterY)
            $e.Graphics.DrawLine($pen, $returnStartPoint1, $returnEndPoint1)

            # 2. 縦ライン（右パネル左端付近 → 上に移動してループのトップまで）
            $returnStartPoint2 = $returnEndPoint1
            $returnEndPoint2 = [System.Drawing.Point]::new($returnGapExtendX, $loopTopY)
            $e.Graphics.DrawLine($pen, $returnStartPoint2, $returnEndPoint2)

            # 3. 横ライン（右パネル左端付近 → 左パネル右端）
            $returnStartPoint3 = $returnEndPoint2
            $returnEndPoint3 = [System.Drawing.Point]::new($leftPanelRightX, $loopTopY)
            $e.Graphics.DrawLine($pen, $returnStartPoint3, $returnEndPoint3)

            # 4. 縦ライン（左パネル右端 → 下に移動して戻り先まで）
            $returnStartPoint4 = $returnEndPoint3
            $returnEndPoint4 = [System.Drawing.Point]::new($leftPanelRightX, $leftReturnY)
            $e.Graphics.DrawLine($pen, $returnStartPoint4, $returnEndPoint4)
        }

        $pen.Dispose()
    })
}

function 00_矢印追記処理 {
    param (
        [System.Windows.Forms.Panel]$フレームパネル
    )

    # パネルごとの描画オブジェクトをクリア
    $フレームパネル.Tag.DrawObjects = @()

    # ピンク処理済みフラグを初期化
    $hasProcessedPink = $false

    # メインフレームパネル内のボタンを取得し、Y座標でソート
    $buttons = $フレームパネル.Controls |
        Where-Object { $_ -is [System.Windows.Forms.Button] } |
        Sort-Object { $_.Location.Y }

    # シーケンスボタン（白、赤、青）の処理
    $sequenceColors = @(
        [System.Drawing.Color]::White.ToArgb(),
        [System.Drawing.Color]::Salmon.ToArgb(),
        $global:青色.ToArgb(),
        $global:ピンク青色.ToArgb(),
        $global:ピンク赤色.ToArgb()
    )

    #^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^pink矢印真ん中
    # ピンクノード展開時の矢印表示（パネル内部分）
    if ($Global:Pink選択中 -eq "true") {
        $result = Check-Pink選択配列Objects

        if ($result -eq $true) {
            # 左パネル内：ピンクボタンから右端までの横線のみ（一本化のため戻り矢印は削除）
            if ($フレームパネル -eq $Global:可視左パネル) {
                # 選択中のピンクボタンを取得
                $selectedPinkButton = $buttons | Where-Object {
                    ($_.BackColor.ToArgb() -eq [System.Drawing.Color]::Pink.ToArgb()) -or
                    ($_.BackColor.ToArgb() -eq $global:ピンク青色.ToArgb()) -or
                    ($_.BackColor.ToArgb() -eq $global:ピンク赤色.ToArgb())
                } | Select-Object -First 1

                if ($selectedPinkButton) {
                    # 鮮やかなピンク色
                    $pinkLineColor = [System.Drawing.Color]::HotPink

                    # ピンクボタンの右端中央から開始
                    $pinkButtonRight = [System.Drawing.Point]::new(
                        $selectedPinkButton.Location.X + $selectedPinkButton.Width,
                        $selectedPinkButton.Location.Y + ($selectedPinkButton.Height / 2)
                    )

                    # 横ライン終点（パネル右端）
                    $horizontalEndPoint = [System.Drawing.Point]::new(
                        $フレームパネル.Width,
                        $pinkButtonRight.Y
                    )

                    # 横ライン描画（ピンクボタン → パネル右端）
                    $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                        Type = "Line"
                        StartPoint = $pinkButtonRight
                        EndPoint = $horizontalEndPoint
                        Color = $pinkLineColor
                        Width = 3
                    }
                }
            }
            # メインパネル（可視右パネル）内：左端から右端まで一本の横線
            elseif ($フレームパネル -eq $Global:可視右パネル) {
                # ピンク選択中で、左パネルにピンクボタンがある場合のみ描画
                $leftPanelButtons = $Global:可視左パネル.Controls |
                    Where-Object { $_ -is [System.Windows.Forms.Button] } |
                    Sort-Object { $_.Location.Y }

                $leftPanelPinkButton = $leftPanelButtons | Where-Object {
                    ($_.BackColor.ToArgb() -eq [System.Drawing.Color]::Pink.ToArgb()) -or
                    ($_.BackColor.ToArgb() -eq $global:ピンク青色.ToArgb()) -or
                    ($_.BackColor.ToArgb() -eq $global:ピンク赤色.ToArgb())
                } | Select-Object -First 1

                if ($leftPanelPinkButton) {
                    # 鮮やかなピンク色
                    $pinkLineColor = [System.Drawing.Color]::HotPink

                    # 左パネルのピンクボタンのY座標を取得（メインパネル座標系に変換）
                    $pinkButtonCenterY = $leftPanelPinkButton.Location.Y + ($leftPanelPinkButton.Height / 2)

                    # メインパネルの左端から右端まで一本の横線
                    $horizontalStartPoint = [System.Drawing.Point]::new(0, $pinkButtonCenterY)
                    $horizontalEndPoint = [System.Drawing.Point]::new($フレームパネル.Width, $pinkButtonCenterY)

                    # 横ライン描画（パネル左端 → パネル右端）
                    $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                        Type = "Line"
                        StartPoint = $horizontalStartPoint
                        EndPoint = $horizontalEndPoint
                        Color = $pinkLineColor
                        Width = 3
                    }
                }
            }
        }
    }




    # 条件分岐（緑色ボタン）内の処理をグループ化
    $conditionalGroups = @()
    $currentGroup = @()
    $insideConditional = $false

    foreach ($button in $buttons) {
        if ($button.BackColor.ToArgb() -eq [System.Drawing.Color]::SpringGreen.ToArgb()) {
            if (-not $insideConditional) {
                $insideConditional = $true
                $currentGroup = @()
                $currentGroup += $button
            } else {
                $currentGroup += $button
                $conditionalGroups += ,$currentGroup
                $insideConditional = $false
                $currentGroup = @()
            }
        }
        elseif ($insideConditional) {
            $currentGroup += $button
        }
    }

    # 各分類に対して設定を調整可能な変数を定義
    $yellowLineColor = [System.Drawing.Color]::Orange
    $yellowLineHorizontalOffset = -30
    $yellowLineVerticalOffset = 0

    $greenToBlueLineColor = $global:青色
    $greenToBlueLineHorizontalOffset = 0
    $greenToBlueLineVerticalOffset = 0

    $redToGreenLineColor = [System.Drawing.Color]::Salmon
    $redToGreenLineHorizontalOffset = -20
    $redToGreenLineVerticalOffset = 0

    # 条件分岐内のボタンへのライン描画と矢印追加
    foreach ($group in $conditionalGroups) {
        $conditionalButtons = $group
        $greenButtonTop = $conditionalButtons[0]
        $greenButtonBottom = $conditionalButtons[-1]

        # 条件分岐内の青いボタンを取得
        $blueButtons = $conditionalButtons |
            Where-Object { ($_.BackColor.ToArgb() -eq $global:青色.ToArgb()) -or ($_.BackColor.ToArgb() -eq $global:ピンク青色.ToArgb()) }


        if ($blueButtons.Count -gt 0) {
            # 一番上の青いボタンを取得
            $firstBlueButton = $blueButtons[0]

            # 緑色ボタン（上）の右側から横ラインを引く
            $horizontalStartPoint = [System.Drawing.Point]::new(
                $greenButtonTop.Location.X + $greenButtonTop.Width + $greenToBlueLineHorizontalOffset,
                $greenButtonTop.Location.Y + ($greenButtonTop.Height / 2) + $greenToBlueLineVerticalOffset
            )
            $horizontalEndPoint = [System.Drawing.Point]::new(
                $horizontalStartPoint.X + 20,  # 横幅を20ピクセル追加（必要に応じて調整）
                $horizontalStartPoint.Y
            )

            # 横ラインを描画（青）
            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "Line"
                StartPoint = $horizontalStartPoint
                EndPoint = $horizontalEndPoint
                Color = $greenToBlueLineColor
            }

            # 横ラインの終点から垂直ラインを引く（青ボタンのY位置に合わせて垂直に）
            $verticalStartPoint = $horizontalEndPoint
            $verticalEndPoint = [System.Drawing.Point]::new(
                $verticalStartPoint.X,
                $firstBlueButton.Location.Y + ($firstBlueButton.Height / 2) + $greenToBlueLineVerticalOffset
            )

            # 縦ラインを描画（青）
            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "Line"
                StartPoint = $verticalStartPoint
                EndPoint = $verticalEndPoint
                Color = $greenToBlueLineColor
            }

            # 青ボタンの右側からさらに横ラインを引く（正しい方向に）
            $blueHorizontalStartPoint = [System.Drawing.Point]::new(
                $firstBlueButton.Location.X + $firstBlueButton.Width + $greenToBlueLineHorizontalOffset,
                $firstBlueButton.Location.Y + ($firstBlueButton.Height / 2) + $greenToBlueLineVerticalOffset
            )
            $blueHorizontalEndPoint = [System.Drawing.Point]::new(
                $blueHorizontalStartPoint.X + 20,  # 横幅を20ピクセル追加（必要に応じて調整）
                $blueHorizontalStartPoint.Y
            )

            # 横ラインを描画（青）
            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "Line"
                StartPoint = $blueHorizontalStartPoint
                EndPoint = $blueHorizontalEndPoint
                Color = $greenToBlueLineColor
            }
        }

        # 条件分岐内の赤いボタンを取得
        $redButtons = $conditionalButtons |
            Where-Object { ($_.BackColor.ToArgb() -eq [System.Drawing.Color]::Salmon.ToArgb()) -or ($_.BackColor.ToArgb() -eq $global:ピンク赤色.ToArgb()) }


        if ($redButtons.Count -gt 0) {
            # 一番下の赤いボタンを取得
            $lastRedButton = $redButtons[-1]

            # 赤いボタンの左側からラインを引く
            $horizontalLineStartX = $lastRedButton.Location.X
            $horizontalLineEndX = $horizontalLineStartX + $redToGreenLineHorizontalOffset
            if ($horizontalLineEndX -lt 0) { $horizontalLineEndX = 0 }
            $horizontalLineY = $lastRedButton.Location.Y + ($lastRedButton.Height / 2) + $redToGreenLineVerticalOffset

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "Line"
                StartPoint = [System.Drawing.Point]::new($horizontalLineStartX, $horizontalLineY)
                EndPoint = [System.Drawing.Point]::new($horizontalLineEndX, $horizontalLineY)
                Color = $redToGreenLineColor
            }

            # 横線の左端から下に縦線を引く
            $verticalLineX = $horizontalLineEndX
            $verticalLineStartY = $horizontalLineY
            $verticalLineEndY = $greenButtonBottom.Location.Y + ($greenButtonBottom.Height / 2) + $redToGreenLineVerticalOffset

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "Line"
                StartPoint = [System.Drawing.Point]::new($verticalLineX, $verticalLineStartY)
                EndPoint = [System.Drawing.Point]::new($verticalLineX, $verticalLineEndY)
                Color = $redToGreenLineColor
            }

            # 緑色ボタン（下）への矢印
            $arrowStartX = $verticalLineX
            $arrowEndX = $greenButtonBottom.Location.X  # 緑色ボタンの左端
            $arrowY = $verticalLineEndY

            # 矢印の情報を追加
            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "Arrow"
                StartPoint = [System.Drawing.Point]::new($arrowStartX, $arrowY)
                EndPoint = [System.Drawing.Point]::new($arrowEndX, $arrowY)
                Direction = "Left"
                Color = $redToGreenLineColor
            }
        }

        # --- 新しい矢印表示条件の追加 ---
        # グループ内の緑色ボタンの上下のボタンをチェックして矢印を追加
        foreach ($group in $conditionalGroups) {
            $conditionalButtons = $group
            $greenButtonTop = $conditionalButtons[0]
            $greenButtonBottom = $conditionalButtons[-1]

            # 緑色ボタンの位置を基にボタンのインデックスを取得
            $topIndex = [array]::IndexOf($buttons, $greenButtonTop)
            $bottomIndex = [array]::IndexOf($buttons, $greenButtonBottom)

            # 上側の緑色ボタンの下にあるボタンが赤色の場合、赤の↓矢印を追加
            if ($topIndex -lt ($buttons.Count - 1)) {
                $buttonBelowTop = $buttons[$topIndex + 1]
                #if ($buttonBelowTop.BackColor.ToArgb() -eq [System.Drawing.Color]::Salmon.ToArgb()) {
                if (($buttonBelowTop.BackColor.ToArgb() -eq [System.Drawing.Color]::Salmon.ToArgb()) -or ($buttonBelowTop.BackColor.ToArgb() -eq $global:ピンク赤色.ToArgb())) {


                    # 赤色の下向き矢印を描画
                    $startPoint = [System.Drawing.Point]::new(
                        $greenButtonTop.Location.X + ($greenButtonTop.Width / 2),
                        $greenButtonTop.Location.Y + $greenButtonTop.Height
                    )
                    $endPoint = [System.Drawing.Point]::new(
                        $buttonBelowTop.Location.X + ($buttonBelowTop.Width / 2),
                        $buttonBelowTop.Location.Y
                    )

                    $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                        Type = "DownArrow"
                        StartPoint = $startPoint
                        EndPoint = $endPoint
                        Color = [System.Drawing.Color]::Salmon
                    }
                }
            }

            # 下側の緑色ボタンの上にあるボタンが青色の場合、青の↓矢印を追加
            if ($bottomIndex -gt 0) {
                $buttonAboveBottom = $buttons[$bottomIndex - 1]
                #if ($buttonAboveBottom.BackColor.ToArgb() -eq $global:青色.ToArgb()) {
                if (($buttonAboveBottom.BackColor.ToArgb() -eq $global:青色.ToArgb()) -or ($buttonAboveBottom.BackColor.ToArgb() -eq $global:ピンク青色.ToArgb())) {

                    # 青色の下向き矢印を描画
                    $startPoint = [System.Drawing.Point]::new(
                        $buttonAboveBottom.Location.X + ($buttonAboveBottom.Width / 2),
                        $buttonAboveBottom.Location.Y + $buttonAboveBottom.Height
                    )
                    $endPoint = [System.Drawing.Point]::new(
                        $greenButtonBottom.Location.X + ($greenButtonBottom.Width / 2),
                        $greenButtonBottom.Location.Y
                    )

                    $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                        Type = "DownArrow"
                        StartPoint = $startPoint
                        EndPoint = $endPoint
                        Color = $global:青色
                    }
                }
            }
        }
        # --- ここまで新しい矢印表示条件の追加 ---
    }

    # 通常のシーケンス処理における矢印描画条件の追加
    for ($i = 0; $i -lt ($buttons.Count - 1); $i++) {
        $currentButton = $buttons[$i]
        $nextButton = $buttons[$i + 1]

        $currentColor = $currentButton.BackColor.ToArgb()
        $nextColor = $nextButton.BackColor.ToArgb()

        # 下向きの矢印を描画する条件を変更
        if ($currentColor -eq [System.Drawing.Color]::White.ToArgb() -and $nextColor -eq [System.Drawing.Color]::White.ToArgb()) {
            # 下向きの矢印を描画（黒）
            $startPoint = [System.Drawing.Point]::new(
                $currentButton.Location.X + ($currentButton.Width / 2),
                $currentButton.Location.Y + $currentButton.Height
            )
            $endPoint = [System.Drawing.Point]::new(
                $nextButton.Location.X + ($nextButton.Width / 2),
                $nextButton.Location.Y
            )

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "DownArrow"
                StartPoint = $startPoint
                EndPoint = $endPoint
                Color = [System.Drawing.Color]::Black  # 黒色の矢印
            }
        }
        # 白→緑（条件分岐の開始前）
        elseif ($currentColor -eq [System.Drawing.Color]::White.ToArgb() -and
                $nextColor -eq [System.Drawing.Color]::SpringGreen.ToArgb()) {
            # 下向きの矢印を描画（黒）
            $startPoint = [System.Drawing.Point]::new(
                $currentButton.Location.X + ($currentButton.Width / 2),
                $currentButton.Location.Y + $currentButton.Height
            )
            $endPoint = [System.Drawing.Point]::new(
                $nextButton.Location.X + ($nextButton.Width / 2),
                $nextButton.Location.Y
            )

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "DownArrow"
                StartPoint = $startPoint
                EndPoint = $endPoint
                Color = [System.Drawing.Color]::Black  # 黒色の矢印
            }
        }
        # 緑→白（条件分岐の終了後）
        elseif ($currentColor -eq [System.Drawing.Color]::SpringGreen.ToArgb() -and
                $nextColor -eq [System.Drawing.Color]::White.ToArgb()) {
            # 下向きの矢印を描画（黒）
            $startPoint = [System.Drawing.Point]::new(
                $currentButton.Location.X + ($currentButton.Width / 2),
                $currentButton.Location.Y + $currentButton.Height
            )
            $endPoint = [System.Drawing.Point]::new(
                $nextButton.Location.X + ($nextButton.Width / 2),
                $nextButton.Location.Y
            )

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "DownArrow"
                StartPoint = $startPoint
                EndPoint = $endPoint
                Color = [System.Drawing.Color]::Black  # 黒色の矢印
            }
        }
        # 白→黄（ループの開始前）
        elseif ($currentColor -eq [System.Drawing.Color]::White.ToArgb() -and
                $nextColor -eq [System.Drawing.Color]::LemonChiffon.ToArgb()) {
            # 下向きの矢印を描画（黒）
            $startPoint = [System.Drawing.Point]::new(
                $currentButton.Location.X + ($currentButton.Width / 2),
                $currentButton.Location.Y + $currentButton.Height
            )
            $endPoint = [System.Drawing.Point]::new(
                $nextButton.Location.X + ($nextButton.Width / 2),
                $nextButton.Location.Y
            )

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "DownArrow"
                StartPoint = $startPoint
                EndPoint = $endPoint
                Color = [System.Drawing.Color]::Black  # 黒色の矢印
            }
        }
        # 黄→白（ループの終了後）
        elseif ($currentColor -eq [System.Drawing.Color]::LemonChiffon.ToArgb() -and
                $nextColor -eq [System.Drawing.Color]::White.ToArgb()) {
            # 下向きの矢印を描画（黒）
            $startPoint = [System.Drawing.Point]::new(
                $currentButton.Location.X + ($currentButton.Width / 2),
                $currentButton.Location.Y + $currentButton.Height
            )
            $endPoint = [System.Drawing.Point]::new(
                $nextButton.Location.X + ($nextButton.Width / 2),
                $nextButton.Location.Y
            )

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "DownArrow"
                StartPoint = $startPoint
                EndPoint = $endPoint
                Color = [System.Drawing.Color]::Black  # 黒色の矢印
            }
        }
        # 黄→緑（ループの後に条件分岐）
        elseif ($currentColor -eq [System.Drawing.Color]::LemonChiffon.ToArgb() -and
                $nextColor -eq [System.Drawing.Color]::SpringGreen.ToArgb()) {
            # 下向きの矢印を描画（黒）
            $startPoint = [System.Drawing.Point]::new(
                $currentButton.Location.X + ($currentButton.Width / 2),
                $currentButton.Location.Y + $currentButton.Height
            )
            $endPoint = [System.Drawing.Point]::new(
                $nextButton.Location.X + ($nextButton.Width / 2),
                $nextButton.Location.Y
            )

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "DownArrow"
                StartPoint = $startPoint
                EndPoint = $endPoint
                Color = [System.Drawing.Color]::Black  # 黒色の矢印
            }
        }
        # 緑→黄（条件分岐の後にループ）
        elseif ($currentColor -eq [System.Drawing.Color]::SpringGreen.ToArgb() -and
                $nextColor -eq [System.Drawing.Color]::LemonChiffon.ToArgb()) {
            # 下向きの矢印を描画（黒）
            $startPoint = [System.Drawing.Point]::new(
                $currentButton.Location.X + ($currentButton.Width / 2),
                $currentButton.Location.Y + $currentButton.Height
            )
            $endPoint = [System.Drawing.Point]::new(
                $nextButton.Location.X + ($nextButton.Width / 2),
                $nextButton.Location.Y
            )

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "DownArrow"
                StartPoint = $startPoint
                EndPoint = $endPoint
                Color = [System.Drawing.Color]::Black  # 黒色の矢印
            }
        }
        # 緑→緑（条件分岐が連続）
        elseif ($currentColor -eq [System.Drawing.Color]::SpringGreen.ToArgb() -and
                $nextColor -eq [System.Drawing.Color]::SpringGreen.ToArgb()) {
            # 下向きの矢印を描画（黒）
            $startPoint = [System.Drawing.Point]::new(
                $currentButton.Location.X + ($currentButton.Width / 2),
                $currentButton.Location.Y + $currentButton.Height
            )
            $endPoint = [System.Drawing.Point]::new(
                $nextButton.Location.X + ($nextButton.Width / 2),
                $nextButton.Location.Y
            )

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "DownArrow"
                StartPoint = $startPoint
                EndPoint = $endPoint
                Color = [System.Drawing.Color]::Black  # 黒色の矢印
            }
        }
        # 黄→黄（ループが連続、ただしGroupIDが異なる場合のみ）
        elseif ($currentColor -eq [System.Drawing.Color]::LemonChiffon.ToArgb() -and
                $nextColor -eq [System.Drawing.Color]::LemonChiffon.ToArgb() -and
                $currentButton.Tag.GroupID -ne $nextButton.Tag.GroupID) {
            # 下向きの矢印を描画（黒）
            $startPoint = [System.Drawing.Point]::new(
                $currentButton.Location.X + ($currentButton.Width / 2),
                $currentButton.Location.Y + $currentButton.Height
            )
            $endPoint = [System.Drawing.Point]::new(
                $nextButton.Location.X + ($nextButton.Width / 2),
                $nextButton.Location.Y
            )

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "DownArrow"
                StartPoint = $startPoint
                EndPoint = $endPoint
                Color = [System.Drawing.Color]::Black  # 黒色の矢印
            }
        }
        # Pink→Pink（スクリプト化が連続）
        elseif ($currentColor -eq [System.Drawing.Color]::Pink.ToArgb() -and
                $nextColor -eq [System.Drawing.Color]::Pink.ToArgb()) {
            # 下向きの矢印を描画（黒）
            $startPoint = [System.Drawing.Point]::new(
                $currentButton.Location.X + ($currentButton.Width / 2),
                $currentButton.Location.Y + $currentButton.Height
            )
            $endPoint = [System.Drawing.Point]::new(
                $nextButton.Location.X + ($nextButton.Width / 2),
                $nextButton.Location.Y
            )

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "DownArrow"
                StartPoint = $startPoint
                EndPoint = $endPoint
                Color = [System.Drawing.Color]::Black  # 黒色の矢印
            }
        }
        # Pink→White（スクリプト化の後に順次処理）
        elseif ($currentColor -eq [System.Drawing.Color]::Pink.ToArgb() -and
                $nextColor -eq [System.Drawing.Color]::White.ToArgb()) {
            # 下向きの矢印を描画（黒）
            $startPoint = [System.Drawing.Point]::new(
                $currentButton.Location.X + ($currentButton.Width / 2),
                $currentButton.Location.Y + $currentButton.Height
            )
            $endPoint = [System.Drawing.Point]::new(
                $nextButton.Location.X + ($nextButton.Width / 2),
                $nextButton.Location.Y
            )

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "DownArrow"
                StartPoint = $startPoint
                EndPoint = $endPoint
                Color = [System.Drawing.Color]::Black  # 黒色の矢印
            }
        }
        # White→Pink（順次処理の後にスクリプト化）
        elseif ($currentColor -eq [System.Drawing.Color]::White.ToArgb() -and
                $nextColor -eq [System.Drawing.Color]::Pink.ToArgb()) {
            # 下向きの矢印を描画（黒）
            $startPoint = [System.Drawing.Point]::new(
                $currentButton.Location.X + ($currentButton.Width / 2),
                $currentButton.Location.Y + $currentButton.Height
            )
            $endPoint = [System.Drawing.Point]::new(
                $nextButton.Location.X + ($nextButton.Width / 2),
                $nextButton.Location.Y
            )

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "DownArrow"
                StartPoint = $startPoint
                EndPoint = $endPoint
                Color = [System.Drawing.Color]::Black  # 黒色の矢印
            }
        }
        # Pink→Green（スクリプト化の後に条件分岐）
        elseif ($currentColor -eq [System.Drawing.Color]::Pink.ToArgb() -and
                $nextColor -eq [System.Drawing.Color]::SpringGreen.ToArgb()) {
            # 下向きの矢印を描画（黒）
            $startPoint = [System.Drawing.Point]::new(
                $currentButton.Location.X + ($currentButton.Width / 2),
                $currentButton.Location.Y + $currentButton.Height
            )
            $endPoint = [System.Drawing.Point]::new(
                $nextButton.Location.X + ($nextButton.Width / 2),
                $nextButton.Location.Y
            )

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "DownArrow"
                StartPoint = $startPoint
                EndPoint = $endPoint
                Color = [System.Drawing.Color]::Black  # 黒色の矢印
            }
        }
        # Green→Pink（条件分岐の後にスクリプト化）
        elseif ($currentColor -eq [System.Drawing.Color]::SpringGreen.ToArgb() -and
                $nextColor -eq [System.Drawing.Color]::Pink.ToArgb()) {
            # 下向きの矢印を描画（黒）
            $startPoint = [System.Drawing.Point]::new(
                $currentButton.Location.X + ($currentButton.Width / 2),
                $currentButton.Location.Y + $currentButton.Height
            )
            $endPoint = [System.Drawing.Point]::new(
                $nextButton.Location.X + ($nextButton.Width / 2),
                $nextButton.Location.Y
            )

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "DownArrow"
                StartPoint = $startPoint
                EndPoint = $endPoint
                Color = [System.Drawing.Color]::Black  # 黒色の矢印
            }
        }
        # Pink→Yellow（スクリプト化の後にループ）
        elseif ($currentColor -eq [System.Drawing.Color]::Pink.ToArgb() -and
                $nextColor -eq [System.Drawing.Color]::LemonChiffon.ToArgb()) {
            # 下向きの矢印を描画（黒）
            $startPoint = [System.Drawing.Point]::new(
                $currentButton.Location.X + ($currentButton.Width / 2),
                $currentButton.Location.Y + $currentButton.Height
            )
            $endPoint = [System.Drawing.Point]::new(
                $nextButton.Location.X + ($nextButton.Width / 2),
                $nextButton.Location.Y
            )

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "DownArrow"
                StartPoint = $startPoint
                EndPoint = $endPoint
                Color = [System.Drawing.Color]::Black  # 黒色の矢印
            }
        }
        # Yellow→Pink（ループの後にスクリプト化）
        elseif ($currentColor -eq [System.Drawing.Color]::LemonChiffon.ToArgb() -and
                $nextColor -eq [System.Drawing.Color]::Pink.ToArgb()) {
            # 下向きの矢印を描画（黒）
            $startPoint = [System.Drawing.Point]::new(
                $currentButton.Location.X + ($currentButton.Width / 2),
                $currentButton.Location.Y + $currentButton.Height
            )
            $endPoint = [System.Drawing.Point]::new(
                $nextButton.Location.X + ($nextButton.Width / 2),
                $nextButton.Location.Y
            )

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "DownArrow"
                StartPoint = $startPoint
                EndPoint = $endPoint
                Color = [System.Drawing.Color]::Black  # 黒色の矢印
            }
        }
        #elseif ($currentColor -eq [System.Drawing.Color]::Salmon.ToArgb() -and $nextColor -eq [System.Drawing.Color]::Salmon.ToArgb()) {
        elseif ((($currentColor -eq [System.Drawing.Color]::Salmon.ToArgb()) -or ($currentColor -eq $global:ピンク赤色.ToArgb())) -and
        (($nextColor -eq [System.Drawing.Color]::Salmon.ToArgb()) -or ($nextColor -eq $global:ピンク赤色.ToArgb()))) {



            # 下向きの矢印を描画（赤）
            $startPoint = [System.Drawing.Point]::new(
                $currentButton.Location.X + ($currentButton.Width / 2),
                $currentButton.Location.Y + $currentButton.Height
            )
            $endPoint = [System.Drawing.Point]::new(
                $nextButton.Location.X + ($nextButton.Width / 2),
                $nextButton.Location.Y
            )

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "Arrow"
                StartPoint = $startPoint
                EndPoint = $endPoint
                Direction = "Left"
                Color = [System.Drawing.Color]::Salmon  # 赤色の矢印
            }
        }
    elseif ((($currentColor -eq $global:青色.ToArgb()) -or ($currentColor -eq $global:ピンク青色.ToArgb())) -and
            (($nextColor -eq $global:青色.ToArgb()) -or ($nextColor -eq $global:ピンク青色.ToArgb()))) {

            # 下向きの矢印を描画（青）
            $startPoint = [System.Drawing.Point]::new(
                $currentButton.Location.X + ($currentButton.Width / 2),
                $currentButton.Location.Y + $currentButton.Height
            )
            $endPoint = [System.Drawing.Point]::new(
                $nextButton.Location.X + ($nextButton.Width / 2),
                $nextButton.Location.Y
            )

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "DownArrow"
                StartPoint = $startPoint
                EndPoint = $endPoint
                Color = $global:青色  # 青色の矢印
            }
        }
    }

    # 黄色ボタンの処理
    $yellowButtons = $buttons | Where-Object { $_.BackColor.ToArgb() -eq [System.Drawing.Color]::LemonChiffon.ToArgb() }

    # グループIDでグループ化
    $groupedYellowButtons = $yellowButtons | Group-Object -Property { $_.Tag.GroupID }

    foreach ($group in $groupedYellowButtons) {
        if ($group.Count -eq 2) {
            $button1 = $group.Group[0]
            $button2 = $group.Group[1]

            # 上下関係を確認
            if ($button1.Location.Y -le $button2.Location.Y) {
                $upperButton = $button1
                $lowerButton = $button2
            }
            else {
                $upperButton = $button2
                $lowerButton = $button1
            }

            # 上段のボタンの左側に矢印を引く（修正箇所）
            $horizontalLineStartX = $upperButton.Location.X  # ボタンの左端
            $horizontalLineEndX = $horizontalLineStartX + $yellowLineHorizontalOffset  # 正方向に変更
            if ($horizontalLineEndX -lt 0) {
                $horizontalLineEndX = 0
            }
            $horizontalLineY = $upperButton.Location.Y + ($upperButton.Height / 2) + $yellowLineVerticalOffset

            # 矢印の情報を追加（Typeを "Arrow" に変更）
            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "Arrow"  # 修正箇所
                #StartPoint = [System.Drawing.Point]::new($horizontalLineStartX, $horizontalLineY)
                #EndPoint = [System.Drawing.Point]::new($horizontalLineEndX, $horizontalLineY)
                StartPoint = [System.Drawing.Point]::new($horizontalLineEndX, $horizontalLineY)
                EndPoint = [System.Drawing.Point]::new($horizontalLineStartX, $horizontalLineY)
                Direction = "Right"
                Color = $yellowLineColor
            }

            # 横線の左端から下に縦線を引く
            $verticalLineX = $horizontalLineEndX
            $verticalLineStartY = $horizontalLineY
            $verticalLineEndY = $lowerButton.Location.Y + ($lowerButton.Height / 2) + $yellowLineVerticalOffset

            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "Line"
                StartPoint = [System.Drawing.Point]::new($verticalLineX, $verticalLineStartY)
                EndPoint = [System.Drawing.Point]::new($verticalLineX, $verticalLineEndY)
                Color = $yellowLineColor
            }

            # 縦線の下端から下段のボタンの左側に向けて横線を引く（修正箇所）
            $arrowStartX = $verticalLineX
            $arrowEndX = $lowerButton.Location.X  # 下段ボタンの左端
            $arrowY = $verticalLineEndY

            # 横線の情報を追加（Typeを "Line" に変更）
            $フレームパネル.Tag.DrawObjects += [PSCustomObject]@{
                Type = "Line"  # 修正箇所
                StartPoint = [System.Drawing.Point]::new($arrowStartX, $arrowY)
                EndPoint = [System.Drawing.Point]::new($arrowEndX, $arrowY)
                Color = $yellowLineColor
            }
        }
    }


        # pinkボタンの処理
    $pinkButtons = $buttons | Where-Object { $_.BackColor.ToArgb() -eq [System.Drawing.Color]::LemonChiffon.ToArgb() }

    # グループIDでグループ化
    $groupedpinkButtons = $pinkButtons | Group-Object -Property { $_.Tag.GroupID }

    # メインフレームパネルを再描画
    $フレームパネル.Invalidate()

    取得-ボタン一覧 -フレームパネル $Global:可視左パネル
    #取得-ボタン一覧 -フレームパネル $global:レイヤー0
    #取得-ボタン一覧 -フレームパネル $global:レイヤー1
    #取得-ボタン一覧 -フレームパネル $global:レイヤー2
    #取得-ボタン一覧 -フレームパネル $global:レイヤー3
    #取得-ボタン一覧 -フレームパネル $global:レイヤー4
    #取得-ボタン一覧 -フレームパネル $global:レイヤー5
    #取得-ボタン一覧 -フレームパネル $global:レイヤー6

}
# 【タイトル: 取得-ボタン一覧 階層別JSON出力 Ver1.0】
# 【タイトル: 取得-ボタン一覧 階層別JSON出力 Ver1.1】

function 取得-ボタン一覧 {
    param (
        [System.Windows.Forms.Panel]$フレームパネル
    )

    #--- 0) 階層番号（1〜5）を取得 --------------------------------------------
    $最後の文字 = グローバル変数から数値取得 -パネル $フレームパネル

    if (-not ($最後の文字 -as [int] -and 1..5 -contains [int]$最後の文字)) {
        throw "不正な階層番号です。（1〜5 の整数が必要）"
    }

    #--- 1) パネル内ボタンを収集 ----------------------------------------------
    $buttons       = $フレームパネル.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] }
    $sortedButtons = $buttons | Sort-Object { $_.Location.Y }

    $index       = 1
    $outputList  = @()

    foreach ($button in $sortedButtons) {
        $tag            = $button.Tag
        $processingNum  = if ($tag.処理番号) { $tag.処理番号 } else { "未設定" }
        $scriptFlag     = if ($tag.script)  { $tag.script   } else { "未設定" }

        # GroupIDを取得（存在しない場合は空文字列）
        $groupID = if ($tag.GroupID -ne $null) { $tag.GroupID } else { "" }

        $outputList += [PSCustomObject]@{
            ボタン名 = $button.Name
            X座標    = $button.Location.X
            Y座標    = $button.Location.Y
            順番     = $index
            ボタン色 = $button.BackColor.Name
            テキスト = $button.Text
            処理番号 = $processingNum
            高さ     = $button.Height
            幅       = $button.Width
            script   = $scriptFlag
            GroupID  = $groupID
        }
        $index++
    }

    #--- 2) JSON 読込／テンプレート初期化（共通関数使用） ----------------
    $jsonPath   = Join-Path $global:folderPath 'memory.json'
    $baseObject = @{}

    if (Test-Path $jsonPath) {
        try {
            $baseObject = Read-JsonSafe -Path $jsonPath -Required $false -Silent $true
            if (-not $baseObject) {
                Write-Host "既存 JSON を読込めなかったため再生成します。"
            }
        }
        catch { Write-Host "既存 JSON を読込めなかったため再生成します。" }
    }

    # 既存が空なら新規の PSCustomObject を用意
    if (-not $baseObject) { $baseObject = [pscustomobject]@{} }

    #--- 3) 1〜5 の階層プロパティを揃える -------------------------------------
    foreach ($n in 1..5) {
        if (-not ($baseObject.PSObject.Properties.Name -contains "$n")) {
            # Add-Member で NoteProperty を動的追加
            $baseObject | Add-Member -MemberType NoteProperty -Name "$n" `
                -Value ([pscustomobject]@{ 構成 = @() })
        }
        elseif (-not ($baseObject."$n").PSObject.Properties.Name -contains '構成') {
            # 過去に構成が無かった場合も補完
            $baseObject."$n" | Add-Member -MemberType NoteProperty -Name '構成' -Value @()
        }
    }

    #--- 4) 指定階層へ今回のデータをセット -----------------------------------
    $baseObject."$最後の文字".構成 = $outputList

    #--- 5) JSON 保存（共通関数使用） -----------------------------------------
    Write-JsonSafe -Path $jsonPath -Data $baseObject -Depth 8 -Silent $false
}

# カスタム矢印を描画するヘルパー関数
function Draw-CustomArrow {
    param (
        [System.Drawing.Graphics]$graphics,
        [System.Drawing.Pen]$pen,
        [System.Drawing.Point]$startPoint,
        [System.Drawing.Point]$endPoint,
        [float]$arrowSize = 7.0,    # 矢印ヘッドのサイズを小さく
        [float]$arrowAngle = 45.0   # 矢印ヘッドの角度を鋭く
    )

    # アンチエイリアシングを有効にして描画品質を向上
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

    # メインラインを描画
    $graphics.DrawLine($pen, $startPoint, $endPoint)

    # メインラインのベクトルを計算
    $dx = $endPoint.X - $startPoint.X
    $dy = $endPoint.Y - $startPoint.Y
    $length = [math]::Sqrt($dx * $dx + $dy * $dy)

    if ($length -eq 0) { return }

    # 単位ベクトルを計算
    $ux = $dx / $length
    $uy = $dy / $length

    # 矢印ヘッドの角度をラジアンに変換
    $angleRad = [math]::PI * $arrowAngle / 180.0

    # 矢印ヘッドの2つのポイントを計算
    $sin = [math]::Sin($angleRad)
    $cos = [math]::Cos($angleRad)

    $point1X = [math]::Round($endPoint.X - $arrowSize * ($cos * $ux + $sin * $uy))
    $point1Y = [math]::Round($endPoint.Y - $arrowSize * ($cos * $uy - $sin * $ux))
    $point2X = [math]::Round($endPoint.X - $arrowSize * ($cos * $ux - $sin * $uy))
    $point2Y = [math]::Round($endPoint.Y - $arrowSize * ($cos * $uy + $sin * $ux))

    $point1 = New-Object System.Drawing.Point($point1X, $point1Y)
    $point2 = New-Object System.Drawing.Point($point2X, $point2Y)

    # 矢印ヘッドを描画
    $graphics.DrawLine($pen, $endPoint, $point1)
    $graphics.DrawLine($pen, $endPoint, $point2)
}



# 修正後のコード Ver1
function 00_メインフレームパネルのPaintイベントを設定する {
    param (
        [System.Windows.Forms.Panel]$フレームパネル
    )

    $フレームパネル.Add_Paint({
        param($sender, $e)
        
        # スクロール位置を考慮（修正箇所 Ver1）
        $e.Graphics.TranslateTransform($sender.AutoScrollPosition.X, $sender.AutoScrollPosition.Y)
        
        # 描画品質を向上
        $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

        # パネルごとの DrawObjects を取得
        $drawObjects = $sender.Tag.DrawObjects

        foreach ($obj in $drawObjects) {
            if ($obj.Type -eq "Line") {
                # 色の設定（既存のロジックを使用）
                $lineColor = if (($obj.Color.ToArgb() -eq $global:青色.ToArgb()) -or ($obj.Color.ToArgb() -eq $global:ピンク青色.ToArgb())) {
                    [System.Drawing.Color]::Blue
                }
                elseif ($obj.Color.ToArgb() -eq [System.Drawing.Color]::SpringGreen.ToArgb()) {
                    [System.Drawing.Color]::Green
                }
                elseif ($obj.Color.ToArgb() -eq [System.Drawing.Color]::LemonChiffon.ToArgb()) {
                    [System.Drawing.Color]::Yellow
                }
                elseif (($obj.Color.ToArgb() -eq [System.Drawing.Color]::Salmon.ToArgb()) -or ($obj.Color.ToArgb() -eq $global:ピンク赤色.ToArgb())) {
                    [System.Drawing.Color]::Red
                }
                elseif ($obj.PSObject.Properties.Match("Color").Count -gt 0) {
                    $obj.Color
                }
                else {
                    [System.Drawing.Color]::Black
                }

                # ラインを描画（Widthプロパティがあれば使用、なければ1）
                $lineWidth = if ($obj.PSObject.Properties.Match("Width").Count -gt 0) { $obj.Width } else { 1 }
                $pen = New-Object System.Drawing.Pen($lineColor, $lineWidth)
                $e.Graphics.DrawLine($pen, $obj.StartPoint, $obj.EndPoint)
                $pen.Dispose()
            }
            elseif ($obj.Type -eq "Arrow" -or $obj.Type -eq "DownArrow") {
                # 矢印の色を設定（既存のロジックを使用）
                $arrowColor = if (($obj.Color.ToArgb() -eq $global:青色.ToArgb()) -or ($obj.Color.ToArgb() -eq $global:ピンク青色.ToArgb())) {
                    [System.Drawing.Color]::Blue
                }
                elseif ($obj.Color.ToArgb() -eq [System.Drawing.Color]::SpringGreen.ToArgb()) {
                    [System.Drawing.Color]::Green
                }
                elseif ($obj.Color.ToArgb() -eq [System.Drawing.Color]::LemonChiffon.ToArgb()) {
                    [System.Drawing.Color]::Yellow
                }
                elseif (($obj.Color.ToArgb() -eq [System.Drawing.Color]::Salmon.ToArgb()) -or ($obj.Color.ToArgb() -eq $global:ピンク赤色.ToArgb())) {
                    [System.Drawing.Color]::Red
                }
                elseif ($obj.PSObject.Properties.Match("Color").Count -gt 0) {
                    $obj.Color
                }
                else {
                    [System.Drawing.Color]::Black
                }

                # ペンの設定（Widthプロパティがあれば使用、なければ1）
                $arrowWidth = if ($obj.PSObject.Properties.Match("Width").Count -gt 0) { $obj.Width } else { 1 }
                $pen = New-Object System.Drawing.Pen($arrowColor, $arrowWidth)

                # 矢印サイズの設定（ArrowSizeプロパティがあれば使用、なければデフォルト7.0）
                $arrowSize = if ($obj.PSObject.Properties.Match("ArrowSize").Count -gt 0) { $obj.ArrowSize } else { 7.0 }

                # 矢印の描画方向を調整
                $endPoint = $obj.EndPoint
                $startPoint = $obj.StartPoint

                if ($obj.Type -eq "DownArrow") {
                    # 下向きの場合、特別な調整が必要な場合はここに追加
                    # ここでは既存の StartPoint と EndPoint を使用
                }
                elseif ($obj.Direction -eq "Right") {
                    # 右向きの場合、矢印の向きを右に調整
                    # 必要に応じて座標を変更
                    # ここでは既存の StartPoint と EndPoint を使用
                    #$endPoint = $obj.EndPoint
                    #$startPoint = $obj.StartPoint
                }
                elseif ($obj.Direction -eq "Left") {
                    # 左向きの場合、矢印の向きを左に調整
                    # 必要に応じて座標を変更
                    # ここでは既存の StartPoint と EndPoint を使用
                }
                else {
                    # その他の方向の場合、特別な調整が必要な場合はここに追加
                    # ここでは既存の StartPoint と EndPoint を使用
                }

                # カスタム矢印を描画（カスタムサイズを適用）
                Draw-CustomArrow -graphics $e.Graphics -pen $pen -startPoint $startPoint -endPoint $endPoint -arrowSize $arrowSize

                $pen.Dispose()
            }
        }
    })
}

