# ================================================================
# 02-3_ボタン作成管理.ps1
# ================================================================
# 責任: ボタンの作成・生成・イベント設定
# 
# 含まれる関数:
#   - PINKからボタン作成
#   - 00_ボタンを作成する
#   - 00_メインにボタンを作成する
#   - 00_汎用色ボタンを作成する
#   - 00_汎用色ボタンのクリックイベントを設定する
#   - Get-NextYPosition
#
# リファクタリング: 2025-11-01
# 元ファイル: 02_メインフォームUI_foam関数.ps1 (行1480-2094)
# ================================================================

# ================================================================
# ヘルパー関数: ボタンにツールチップと省略表示を設定
# ================================================================
function Set-ButtonTextAndTooltip {
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.Button]$Button,

        [Parameter(Mandatory=$true)]
        [string]$FullText
    )

    # 改行文字を除去して文字数をカウント（表示用）
    $表示用テキスト = $FullText -replace "`r`n", "" -replace "`n", "" -replace "`r", ""

    # 8文字を超える場合は省略表示
    if ($表示用テキスト.Length -gt 8) {
        $Button.Text = $表示用テキスト.Substring(0, 8) + "..."
    } else {
        $Button.Text = $表示用テキスト
    }

    # すべてのボタンにツールチップで全文を表示
    $global:ToolTip.SetToolTip($Button, $FullText)
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
    Set-ButtonTextAndTooltip -Button $ボタン -FullText $テキスト
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
    # 元のテキストをそのまま渡す（Set-ButtonTextAndTooltip内で改行処理）
    Set-ButtonTextAndTooltip -Button $ボタン -FullText $テキスト
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
            $result = Show-ConfirmDialog "現在のレイヤーの全てのノードを削除しますか？`nこの操作は元に戻せません。" -Title "全ノード削除の確認"

            if ($result) {
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
  Set-ButtonTextAndTooltip -Button $色ボタン -FullText $テキスト
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
