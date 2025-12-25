﻿# ============================================
# 02-6_削除処理_v2.ps1
# UI非依存版 - HTML/JS移行対応
# ============================================
# 変更内容:
#   - 条件分岐ノード削除_v2: ノード配列を受け取り、削除対象ノードIDを返却
#   - ループノード削除_v2: ノード配列を受け取り、削除対象ノードIDを返却
#   - ノード削除_v2: 単一ノードまたはセットノードの削除を判定して実行
#   - すべてのノードを削除_v2: ノード配列からすべてのノードIDを返却
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

function 条件分岐ノード削除_v2 {
    <#
    .SYNOPSIS
    条件分岐ノードセットの削除対象を特定（UI非依存版）

    .DESCRIPTION
    ノード配列から条件分岐の3点セット（開始・中間・終了）を特定し、削除対象ノードIDのリストを返します。
    実際の削除はフロントエンド（HTML/JSまたはWindows Forms）で行います。

    .PARAMETER ノード配列
    すべてのノード情報を含むハッシュテーブルの配列
    各ノードは以下のプロパティを持つ:
      - id: ノードID
      - text: 表示テキスト
      - color: ノード色
      - y: Y座標
      - groupId: グループID（オプション）

    .PARAMETER TargetNodeId
    削除トリガーとなったノードのID（"条件分岐 開始" または "条件分岐 終了"）

    .EXAMPLE
    $result = 条件分岐ノード削除_v2 -ノード配列 $nodes -TargetNodeId "76-1"
    if ($result.success) {
        Write-Host "削除対象: $($result.deleteTargets -join ', ')"
    }
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$ノード配列,

        [Parameter(Mandatory=$true)]
        [string]$TargetNodeId
    )

    try {
        # ターゲットノードを取得
        $ターゲットノード = $ノード配列 | Where-Object { $_.id -eq $TargetNodeId }

        if (-not $ターゲットノード) {
            return @{
                success = $false
                error = "ターゲットノードが見つかりません: $TargetNodeId"
            }
        }

        $myY = $ターゲットノード.y
        $myText = if ($ターゲットノード.text) { $ターゲットノード.text.Trim() } else { "" }

        # 探索方向と探索対象を決定
        switch ($myText) {
            '条件分岐 開始' {
                $方向 = '下'
                $欲しい順 = @('条件分岐 中間', '条件分岐 終了')
            }
            '条件分岐 終了' {
                $方向 = '上'
                $欲しい順 = @('条件分岐 中間', '条件分岐 開始')
            }
            default {
                return @{
                    success = $false
                    error = "SpringGreenだが対象外テキスト: $myText"
                }
            }
        }

        # 候補ノードを抽出
        $候補ハッシュ = @{}

        foreach ($node in $ノード配列) {
            $txt = if ($node.text) { $node.text.Trim() } else { "" }
            if ($txt -notin $欲しい順) { continue }

            # 色チェック（SpringGreen）
            $nodeColor = if ($node.color) { $node.color } else { "" }
            if ($nodeColor -ne "SpringGreen" -and $nodeColor -ne "Green") { continue }

            $delta = $node.y - $myY
            if (($方向 -eq '下' -and $delta -le 0) -or
                ($方向 -eq '上' -and $delta -ge 0)) { continue }

            $距離 = [math]::Abs($delta)

            # まだ登録されていない or もっと近いノードなら採用
            if (-not $候補ハッシュ.ContainsKey($txt) -or
                $距離 -lt $候補ハッシュ[$txt].距離) {

                $候補ハッシュ[$txt] = [pscustomobject]@{
                    Node = $node
                    距離 = $距離
                }
            }
        }

        # 3つ揃っているか判定
        $削除対象 = @($TargetNodeId)  # 自分自身は必ず削除
        foreach ($name in $欲しい順) {
            if ($候補ハッシュ.ContainsKey($name)) {
                $削除対象 += $候補ハッシュ[$name].Node.id
            }
        }

        if ($削除対象.Count -lt 3) {
            return @{
                success = $false
                error = "セットが揃わないため削除できません（見つかったノード: $($削除対象.Count)/3）"
                foundNodes = $削除対象
            }
        }

        return @{
            success = $true
            message = "条件分岐セット（3個）の削除対象を特定しました"
            deleteTargets = $削除対象
            deleteCount = $削除対象.Count
            nodeType = "条件分岐"
        }

    } catch {
        return @{
            success = $false
            error = "条件分岐ノード削除処理に失敗しました: $($_.Exception.Message)"
            stackTrace = $_.ScriptStackTrace
        }
    }
}


function ループノード削除_v2 {
    <#
    .SYNOPSIS
    ループノードセットの削除対象を特定（UI非依存版）

    .DESCRIPTION
    ノード配列からループの2点セット（開始・終了）を特定し、削除対象ノードIDのリストを返します。
    GroupIDが一致するループノードをペアとして扱います。

    .PARAMETER ノード配列
    すべてのノード情報を含むハッシュテーブルの配列

    .PARAMETER TargetNodeId
    削除トリガーとなったノードのID（"ループ 開始" または "ループ 終了"）

    .EXAMPLE
    $result = ループノード削除_v2 -ノード配列 $nodes -TargetNodeId "80-1"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$ノード配列,

        [Parameter(Mandatory=$true)]
        [string]$TargetNodeId
    )

    try {
        # ターゲットノードを取得
        $ターゲットノード = $ノード配列 | Where-Object { $_.id -eq $TargetNodeId }

        if (-not $ターゲットノード) {
            return @{
                success = $false
                error = "ターゲットノードが見つかりません: $TargetNodeId"
            }
        }

        # GroupIDを取得
        $targetGroupID = $ターゲットノード.groupId
        if (-not $targetGroupID) {
            return @{
                success = $false
                error = "ターゲットノードにGroupIDが設定されていません"
            }
        }

        # 同じGroupIDを持つLemonChiffonノードを収集
        $候補ノード一覧 = @()

        foreach ($node in $ノード配列) {
            # 色がLemonChiffon以外は無視
            $nodeColor = if ($node.color) { $node.color } else { "" }
            if ($nodeColor -ne "LemonChiffon" -and $nodeColor -ne "Yellow") { continue }

            # GroupIDが一致するものだけ拾う
            if ($node.groupId -eq $targetGroupID) {
                $候補ノード一覧 += $node.id
            }
        }

        # 2つ揃っているかチェック
        if ($候補ノード一覧.Count -lt 2) {
            return @{
                success = $false
                error = "ループ開始/終了のセットが揃わないため削除できません（見つかったノード: $($候補ノード一覧.Count)/2）"
                foundNodes = $候補ノード一覧
                groupId = $targetGroupID
            }
        }

        return @{
            success = $true
            message = "ループセット（2個）の削除対象を特定しました"
            deleteTargets = $候補ノード一覧
            deleteCount = $候補ノード一覧.Count
            nodeType = "ループ"
            groupId = $targetGroupID
        }

    } catch {
        return @{
            success = $false
            error = "ループノード削除処理に失敗しました: $($_.Exception.Message)"
            stackTrace = $_.ScriptStackTrace
        }
    }
}


function ノード削除_v2 {
    <#
    .SYNOPSIS
    ノード削除の総合処理（UI非依存版）

    .DESCRIPTION
    ノードの色やテキストに応じて適切な削除処理を選択します。
    - SpringGreen: 条件分岐セット削除
    - LemonChiffon: ループセット削除
    - その他: 単一ノード削除

    .PARAMETER ノード配列
    すべてのノード情報を含むハッシュテーブルの配列

    .PARAMETER TargetNodeId
    削除対象ノードのID

    .EXAMPLE
    $result = ノード削除_v2 -ノード配列 $nodes -TargetNodeId "76-1"
    if ($result.success) {
        # フロントエンドで削除実行
        foreach ($nodeId in $result.deleteTargets) {
            # ノードを削除...
        }
    }
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$ノード配列,

        [Parameter(Mandatory=$true)]
        [string]$TargetNodeId
    )

    try {
        # ターゲットノードを取得
        $ターゲットノード = $ノード配列 | Where-Object { $_.id -eq $TargetNodeId }

        if (-not $ターゲットノード) {
            return @{
                success = $false
                error = "ターゲットノードが見つかりません: $TargetNodeId"
            }
        }

        $nodeColor = if ($ターゲットノード.color) { $ターゲットノード.color } else { "" }

        # 条件分岐（SpringGreen）の場合
        if ($nodeColor -eq "SpringGreen" -or $nodeColor -eq "Green") {
            return 条件分岐ノード削除_v2 -ノード配列 $ノード配列 -TargetNodeId $TargetNodeId
        }

        # ループ（LemonChiffon）の場合
        if ($nodeColor -eq "LemonChiffon" -or $nodeColor -eq "Yellow") {
            return ループノード削除_v2 -ノード配列 $ノード配列 -TargetNodeId $TargetNodeId
        }

        # 通常の単一ノード削除
        return @{
            success = $true
            message = "単一ノードの削除対象を特定しました"
            deleteTargets = @($TargetNodeId)
            deleteCount = 1
            nodeType = "単一"
        }

    } catch {
        return @{
            success = $false
            error = "ノード削除処理に失敗しました: $($_.Exception.Message)"
            stackTrace = $_.ScriptStackTrace
        }
    }
}


function すべてのノードを削除_v2 {
    <#
    .SYNOPSIS
    すべてのノードを削除（UI非依存版）

    .DESCRIPTION
    ノード配列からすべてのノードIDのリストを返します。

    .PARAMETER ノード配列
    すべてのノード情報を含むハッシュテーブルの配列

    .EXAMPLE
    $result = すべてのノードを削除_v2 -ノード配列 $nodes
    if ($result.success) {
        Write-Host "削除対象ノード数: $($result.deleteCount)"
    }
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$ノード配列
    )

    try {
        if (-not $ノード配列 -or $ノード配列.Count -eq 0) {
            return @{
                success = $true
                message = "削除対象のノードがありません"
                deleteTargets = @()
                deleteCount = 0
            }
        }

        # すべてのノードIDを抽出
        $すべてのノードID = $ノード配列 | ForEach-Object { $_.id }

        return @{
            success = $true
            message = "すべてのノード（$($すべてのノードID.Count)個）を削除します"
            deleteTargets = $すべてのノードID
            deleteCount = $すべてのノードID.Count
        }

    } catch {
        return @{
            success = $false
            error = "すべてのノード削除処理に失敗しました: $($_.Exception.Message)"
            stackTrace = $_.ScriptStackTrace
        }
    }
}


# ============================================
# 既存の関数（Windows Forms版 - 後方互換性維持）
# ============================================

function 条件分岐ボタン削除処理 {
    <#
    .SYNOPSIS
    条件分岐ボタン削除処理（既存のWindows Forms版）

    .DESCRIPTION
    この関数は既存のWindows Forms版との互換性維持のために残されています。
    内部でv2関数を呼び出し、実際の削除を実行します。
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Windows.Forms.Button]$ボタン
    )

    $parent = $ボタン.Parent
    if (-not $parent) { return }

    # ボタン配列を作成
    $ノード配列 = @()
    foreach ($ctrl in $parent.Controls) {
        if ($ctrl -is [System.Windows.Forms.Button]) {
            $ノード配列 += @{
                id = $ctrl.Name
                text = $ctrl.Text
                color = $ctrl.BackColor.Name
                y = $ctrl.Location.Y
                groupId = if ($ctrl.Tag -and $ctrl.Tag.GroupID) { $ctrl.Tag.GroupID } else { $null }
                control = $ctrl  # 削除用に保持
            }
        }
    }

    # v2関数で削除対象を特定
    $result = 条件分岐ノード削除_v2 -ノード配列 $ノード配列 -TargetNodeId $ボタン.Name

    if (-not $result.success) {
        Write-Warning $result.error
        return
    }

    # レイヤー番号を取得
    $レイヤー番号 = if (Get-Command "グローバル変数から数値取得" -ErrorAction SilentlyContinue) {
        グローバル変数から数値取得 -パネル $parent
    } else {
        $null
    }
    $レイヤー表示 = if ($レイヤー番号) { "レイヤー$レイヤー番号" } else { "不明" }

    # 削除ログ
    Write-Host "[削除] $レイヤー表示`: 条件分岐 ($($result.deleteCount) 個)" -ForegroundColor Red

    # 実際に削除
    foreach ($nodeId in $result.deleteTargets) {
        $削除ノード = $ノード配列 | Where-Object { $_.id -eq $nodeId }
        if ($削除ノード -and $削除ノード.control) {
            try {
                $parent.Controls.Remove($削除ノード.control)
                $削除ノード.control.Dispose()
            }
            catch {
                Write-Warning "ボタン [$($削除ノード.text)] の削除に失敗: $_"
            }
        }
    }

    # 後処理
    if (Get-Command 00_ボタンの上詰め再配置関数 -ErrorAction SilentlyContinue) {
        00_ボタンの上詰め再配置関数 -フレーム $parent
    }
    if (Get-Command 00_矢印追記処理 -ErrorAction SilentlyContinue) {
        00_矢印追記処理 -フレームパネル $Global:可視左パネル
        # レイヤー3以降にも矢印処理を適用
        for ($i = 3; $i -le 6; $i++) {
            $レイヤー名 = "レイヤー$i"
            if (Get-Variable -Name $レイヤー名 -Scope Global -ErrorAction SilentlyContinue) {
                $パネル = (Get-Variable -Name $レイヤー名 -Scope Global).Value
                00_矢印追記処理 -フレームパネル $パネル
            }
        }
    }
}

function ループボタン削除処理 {
    <#
    .SYNOPSIS
    ループボタン削除処理（既存のWindows Forms版）
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Windows.Forms.Button]$ボタン
    )

    $parent = $ボタン.Parent
    if (-not $parent) { return }

    # ボタン配列を作成
    $ノード配列 = @()
    foreach ($ctrl in $parent.Controls) {
        if ($ctrl -is [System.Windows.Forms.Button]) {
            $ノード配列 += @{
                id = $ctrl.Name
                text = $ctrl.Text
                color = $ctrl.BackColor.Name
                y = $ctrl.Location.Y
                groupId = if ($ctrl.Tag -and $ctrl.Tag.GroupID) { $ctrl.Tag.GroupID } else { $null }
                control = $ctrl  # 削除用に保持
            }
        }
    }

    # v2関数で削除対象を特定
    $result = ループノード削除_v2 -ノード配列 $ノード配列 -TargetNodeId $ボタン.Name

    if (-not $result.success) {
        Write-Warning $result.error
        return
    }

    # レイヤー番号を取得
    $レイヤー番号 = if (Get-Command "グローバル変数から数値取得" -ErrorAction SilentlyContinue) {
        グローバル変数から数値取得 -パネル $parent
    } else {
        $null
    }
    $レイヤー表示 = if ($レイヤー番号) { "レイヤー$レイヤー番号" } else { "不明" }

    # 削除ログ
    Write-Host "[削除] $レイヤー表示`: ループ GroupID=$($result.groupId) ($($result.deleteCount) 個)" -ForegroundColor Red

    # 実際に削除
    foreach ($nodeId in $result.deleteTargets) {
        $削除ノード = $ノード配列 | Where-Object { $_.id -eq $nodeId }
        if ($削除ノード -and $削除ノード.control) {
            try {
                $parent.Controls.Remove($削除ノード.control)
                $削除ノード.control.Dispose()
            }
            catch {
                Write-Warning "ループボタン [$($削除ノード.text)] の削除に失敗: $_"
            }
        }
    }

    # 後処理
    if (Get-Command 00_ボタンの上詰め再配置関数 -ErrorAction SilentlyContinue) {
        00_ボタンの上詰め再配置関数 -フレーム $parent
    }
    if (Get-Command 00_矢印追記処理 -ErrorAction SilentlyContinue) {
        00_矢印追記処理 -フレームパネル $Global:可視左パネル
        # レイヤー3以降にも矢印処理を適用
        for ($i = 3; $i -le 6; $i++) {
            $レイヤー名 = "レイヤー$i"
            if (Get-Variable -Name $レイヤー名 -Scope Global -ErrorAction SilentlyContinue) {
                $パネル = (Get-Variable -Name $レイヤー名 -Scope Global).Value
                00_矢印追記処理 -フレームパネル $パネル
            }
        }
    }
}

function script:削除処理 {
    <#
    .SYNOPSIS
    削除処理メインエントリーポイント（既存のWindows Forms版）
    #>
    # 右クリック時に格納したボタンを取得
    $btn = $script:右クリックメニュー.Tag

    # ★★ 条件分岐（緑）専用削除 ★★
    if ($btn.BackColor -eq [System.Drawing.Color]::SpringGreen) {
        条件分岐ボタン削除処理 -ボタン $btn
        return
    }
    # ★★ ループ（黄）専用削除 ★★
    elseif ($btn.BackColor -eq [System.Drawing.Color]::LemonChiffon) {
        ループボタン削除処理 -ボタン $btn
        return
    }

    # 通常の単一ボタン削除
    if ($btn -ne $null) {
        if ($btn.Parent -ne $null) {
            try {
                # レイヤー番号を取得
                $レイヤー番号 = if (Get-Command "グローバル変数から数値取得" -ErrorAction SilentlyContinue) {
                    グローバル変数から数値取得 -パネル $btn.Parent
                } else {
                    $null
                }
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
                    # レイヤー3以降にも矢印処理を適用
                    for ($i = 3; $i -le 6; $i++) {
                        $レイヤー名 = "レイヤー$i"
                        if (Get-Variable -Name $レイヤー名 -Scope Global -ErrorAction SilentlyContinue) {
                            $パネル = (Get-Variable -Name $レイヤー名 -Scope Global).Value
                            00_矢印追記処理 -フレームパネル $パネル
                        }
                    }
                }
            }
            catch {
                Write-Error "ボタンの削除中にエラーが発生しました: $_"
            }
        }
    }
}

function フレームパネルからすべてのボタンを削除する {
    <#
    .SYNOPSIS
    フレームパネルからすべてのボタンを削除（既存のWindows Forms版）
    #>
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
        }
        catch {
            # エラーは無視
        }
    }

    # 必要に応じて、再描画をトリガー
    $フレームパネル.Invalidate()

    # 可視右パネルが空になった場合は非表示にする
    if ($フレームパネル -eq $Global:可視右パネル) {
        $残りのボタン数 = ($フレームパネル.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] }).Count
        if ($残りのボタン数 -eq 0) {
            if (Get-Command "00_フレームを非表示にする" -ErrorAction SilentlyContinue) {
                00_フレームを非表示にする -フレームパネル $Global:可視右パネル
                Write-Host "  可視右パネルを非表示にしました（空のため）" -ForegroundColor Yellow
            }
        }
    }

    # メインフォームを再描画（パネル間矢印を更新）
    if ($フレームパネル.Parent -and $フレームパネル.Parent -is [System.Windows.Forms.Form]) {
        $フレームパネル.Parent.Invalidate()
    }
}
