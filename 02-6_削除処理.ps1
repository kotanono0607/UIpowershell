# ================================================================
# 02-6_削除処理.ps1
# ================================================================
# 責任: ノード・ボタン・フレームの削除処理
# 
# 含まれる関数:
#   - 条件分岐ボタン削除処理
#   - ループボタン削除処理
#   - script:削除処理
#   - フレームパネルからすべてのボタンを削除する
#
# リファクタリング: 2025-11-01
# 元ファイル: 02_メインフォームUI_foam関数.ps1
# ================================================================

# 02-6_削除処理.ps1

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
