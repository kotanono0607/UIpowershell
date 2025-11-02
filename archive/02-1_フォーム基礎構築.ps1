# ================================================================
# 02-1_フォーム基礎構築.ps1
# ================================================================
# 責任: メインフォーム・フレームの作成と初期化、グローバル変数初期化
# 
# 含まれる関数:
#   - 00_フォームを作成する
#   - 00_フレームのDragDropイベントを設定する
#   - 00_フレームのDragEnterイベントを設定する
#   - 00_フレームを作成する
#   - フォームにラベル追加
#
# グローバル変数:
#   - $global:ボタンカウンタ
#   - $global:黄色ボタングループカウンタ
#   - $global:緑色ボタングループカウンタ
#   - $global:ドラッグ中のボタン
#
# リファクタリング: 2025-11-01
# 元ファイル: 02_メインフォームUI_foam関数.ps1
# ================================================================


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
                # レイヤー3以降にも矢印処理を適用
                for ($i = 3; $i -le 6; $i++) {
                    $レイヤー名 = "レイヤー$i"
                    if (Get-Variable -Name $レイヤー名 -Scope Global -ErrorAction SilentlyContinue) {
                        $パネル = (Get-Variable -Name $レイヤー名 -Scope Global).Value
                        00_矢印追記処理 -フレームパネル $パネル
                    }
                }

                # ============================
                # レイヤー2以降: 親ノードのエントリを更新
                # ============================
                if ($レイヤー番号 -ge 2) {
                    # 親レイヤー番号を取得
                    $親レイヤー番号 = $レイヤー番号 - 1

                    # 親レイヤーの展開元ノードIDを取得
                    $親ノードID = $Global:Pink選択配列[$親レイヤー番号].展開ボタン

                    if ($親ノードID) {
                        # 現在のレイヤーのボタン一覧を取得
                        $ボタン一覧 = 一覧-フレームパネルのボタン一覧 -フレームパネル $sender

                        # エントリ文字列を作成
                        $直接エントリ = "AAAA_" + $ボタン一覧
                        $更新エントリ = $直接エントリ -replace '_', "`r`n"

                        # 親ノードのエントリを更新
                        IDでエントリを置換 -ID $親ノードID -新しい文字列 $更新エントリ

                        Write-Host "[ドロップ後更新] レイヤー$親レイヤー番号 の展開元ノード '$親ノードID' のエントリを更新しました" -ForegroundColor Cyan
                    } else {
                        Write-Host "[警告] レイヤー$親レイヤー番号 の展開元ノードIDが見つかりません" -ForegroundColor Yellow
                    }
                }
            }
        }
    })
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
