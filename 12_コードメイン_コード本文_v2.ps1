# ============================================
# 12_コードメイン_コード本文_v2.ps1
# UI非依存版 - HTML/JS移行対応
# ============================================
# 変更内容:
#   - $メインフォーム.Hide()/Show() を条件分岐化
#   - Windows Forms型パラメータを削除
#   - 一覧-フレームパネルのボタン一覧_v2 を配列ベースに変更
#   - 戻り値を追加（API経由での呼び出しに対応）
#
# 互換性:
#   - 既存のWindows Forms版でも動作（$showUI = $true の場合）
#   - HTML/JS版でも動作（$showUI = $false の場合）
# ============================================

function 00_文字列処理内容_v2 {
    param (
        [string]$ボタン名,
        [string]$処理番号,
        [string]$直接エントリ = "",
        [bool]$showUI = $false,              # 🆕 UI表示フラグ（デフォルト: 非表示）
        [hashtable]$ボタン情報 = $null       # 🆕 Windows Forms Buttonの代替（Name, BackColor, Textを含む）
    )

    try {
        # UI操作を条件分岐化（Windows Forms版との互換性維持）
        if ($showUI -and $global:メインフォーム) {
            $global:メインフォーム.Hide()
        }

        # JSONファイルを読み込み（共通関数使用）
        $jsonData = Read-JsonSafe -Path ".\ボタン設定.json" -Required $true -Silent $false

        # 処理番号に対応する関数名を取得する辞書を作成
        $関数マッピング = @{}
        foreach ($entry in $jsonData) {
            $関数マッピング[$entry.処理番号] = $entry.関数名
        }

        if ($関数マッピング.ContainsKey($処理番号)) {
            $関数名 = $関数マッピング[$処理番号]

            # 99-1 の場合の特別処理
            if ($処理番号 -eq "99-1") {
                $entryString = & $関数名 -直接エントリ $直接エントリ
            } else {
                # 通常の関数呼び出し
                $entryString = & $関数名
            }

        } else {
            $errorMsg = "処理番号が未対応です: $処理番号"
            Write-Error $errorMsg
            return @{
                success = $false
                error = $errorMsg
            }
        }

        # $entryString が空でない場合のみ関数を呼び出す
        if (-not [string]::IsNullOrEmpty($entryString)) {
            エントリを追加_指定ID -ID $ボタン名 -文字列 $entryString
        } else {
            $errorMsg = "エラー: $entryString は空の文字列です。"
            Write-Error $errorMsg
            return @{
                success = $false
                error = $errorMsg
            }
        }

        # UI操作を条件分岐化
        if ($showUI -and $global:メインフォーム) {
            $global:メインフォーム.Show()
        }

        # -----------------------------------------
        # レイヤー２処理追加
        # -----------------------------------------

        # グローバル変数から数値を取得
        if (Get-Command "グローバル変数から数値取得" -ErrorAction SilentlyContinue) {
            $最後の文字 = グローバル変数から数値取得 -パネル $Global:可視左パネル
        } else {
            # 関数が存在しない場合は0を設定（HTML/JS版用）
            $最後の文字 = 0
        }

        if ($最後の文字 -ge 2) {
            # PINKの場合、統合後のPINKのみ追加

            # ボタン一覧の取得（UI非依存版を使用）
            $A = [int]$最後の文字
            $A = $A - 1

            # 🔧 修正: Windows Forms依存を除去
            # Windows Forms版とHTML/JS版の両方に対応
            if ($Global:可視左パネル -is [System.Windows.Forms.Panel]) {
                # Windows Forms版: 既存の関数を使用
                $ボタン一覧 = 一覧-フレームパネルのボタン一覧 -フレームパネル $Global:可視左パネル
            } elseif ($Global:可視左パネル -is [array] -or $Global:可視左パネル -is [System.Collections.ArrayList]) {
                # HTML/JS版: 配列ベースの関数を使用
                $ボタン一覧 = 一覧-ノード配列からボタン一覧_v2 -ノード配列 $Global:可視左パネル
            } else {
                Write-Warning "可視左パネルの型が不明です: $($Global:可視左パネル.GetType())"
                $ボタン一覧 = ""
            }

            $直接エントリ = "AAAA_" + $ボタン一覧
            $取得したエントリ = $直接エントリ -replace '_', "`r`n"

            if ($Global:Pink選択配列 -and $Global:Pink選択配列[$A]) {
                IDでエントリを置換 -ID $Global:Pink選択配列[$A].展開ボタン -新しい文字列 $取得したエントリ
                Write-Host $Global:現在展開中のスクリプト名 -ForegroundColor Green
            }
        }

        # 🆕 戻り値を追加（API経由での呼び出しに対応）
        return @{
            success = $true
            entry = $entryString
            id = $ボタン名
        }

    } catch {
        # エラーハンドリング
        $errorMsg = "00_文字列処理内容_v2でエラーが発生しました: $($_.Exception.Message)"
        Write-Error $errorMsg

        # UI操作を条件分岐化（エラー時もShowする）
        if ($showUI -and $global:メインフォーム) {
            $global:メインフォーム.Show()
        }

        return @{
            success = $false
            error = $errorMsg
            stackTrace = $_.ScriptStackTrace
        }
    }
}


# ============================================
# 既存の関数（Windows Forms版 - 互換性維持）
# ============================================

function 一覧-フレームパネルのボタン一覧 {
    param (
        [System.Windows.Forms.Panel]$フレームパネル
    )

    # フレームパネル内の全てのコントロールを取得
    $全コントロール = $フレームパネル.Controls

    # ボタンのみをフィルタリングし、Y座標でソート
    $ソート済みボタン = $全コントロール |
                        Where-Object { $_ -is [System.Windows.Forms.Button] } |
                        Sort-Object { $_.Location.Y }

    # ボタンが存在しない場合はメッセージを返す
    if ($ソート済みボタン.Count -eq 0) {
        return "フレームパネル内にボタンが存在しません。"
    }

    # 各ボタンの情報を収集
    $出力リスト = foreach ($ボタン in $ソート済みボタン) {
        "$($ボタン.Name);$($ボタン.BackColor.Name);$($ボタン.Text)"
    }

    # リストを '_' で結合して返す
    return ($出力リスト -join '_')
}


# ============================================
# 新しい関数（HTML/JS版 - UI非依存）
# ============================================

function 一覧-ノード配列からボタン一覧_v2 {
    <#
    .SYNOPSIS
    ノード配列からボタン一覧文字列を生成（UI非依存版）

    .DESCRIPTION
    HTML/JS版で使用する、配列ベースのボタン一覧生成関数。
    Windows Formsの Panel.Controls の代わりに、ノード配列を受け取ります。

    .PARAMETER ノード配列
    ノード情報を含むハッシュテーブルの配列
    各ノードは以下のプロパティを持つ:
      - id (または Name): ノードID
      - color (または BackColor): ノード色
      - text (または Text): 表示テキスト
      - y: Y座標（ソート用）

    .EXAMPLE
    $nodes = @(
        @{ id = "100-1"; color = "White"; text = "開始"; y = 50 },
        @{ id = "101-1"; color = "SpringGreen"; text = "処理A"; y = 100 }
    )
    $result = 一覧-ノード配列からボタン一覧_v2 -ノード配列 $nodes
    # 結果: "100-1;White;開始_101-1;SpringGreen;処理A"
    #>
    param (
        [array]$ノード配列
    )

    # ノード配列が空の場合
    if (-not $ノード配列 -or $ノード配列.Count -eq 0) {
        return "ノード配列が空です。"
    }

    # Y座標でソート
    $ソート済みノード = $ノード配列 | Sort-Object { $_.y }

    # 各ノードの情報を収集
    $出力リスト = foreach ($ノード in $ソート済みノード) {
        # プロパティ名の柔軟な取得（id/Name, color/BackColor, text/Textに対応）
        $nodeId = if ($ノード.id) { $ノード.id } elseif ($ノード.Name) { $ノード.Name } else { "unknown" }
        $nodeColor = if ($ノード.color) { $ノード.color } elseif ($ノード.BackColor) { $ノード.BackColor } else { "White" }
        $nodeText = if ($ノード.text) { $ノード.text } elseif ($ノード.Text) { $ノード.Text } else { "" }

        "$nodeId;$nodeColor;$nodeText"
    }

    # リストを '_' で結合して返す
    return ($出力リスト -join '_')
}


# ============================================
# 既存の関数（元のまま - 後方互換性維持）
# ============================================

function 00_文字列処理内容 {
    <#
    .SYNOPSIS
    既存のWindows Forms版関数（後方互換性維持）

    .DESCRIPTION
    この関数は既存のWindows Forms版との互換性維持のために残されています。
    新しいコードでは 00_文字列処理内容_v2 を使用してください。
    #>
    param (
        [string]$ボタン名,
        [string]$処理番号,
        [string]$直接エントリ = "",
        [System.Windows.Forms.Button]$ボタン
    )

    # 新しいv2関数を呼び出し（UI表示モード）
    $result = 00_文字列処理内容_v2 `
        -ボタン名 $ボタン名 `
        -処理番号 $処理番号 `
        -直接エントリ $直接エントリ `
        -showUI $true `
        -ボタン情報 @{
            Name = $ボタン.Name
            BackColor = $ボタン.BackColor.Name
            Text = $ボタン.Text
        }

    # 元の関数は戻り値を返さないため、成功/失敗のみ出力
    if (-not $result.success) {
        Write-Error $result.error
    }
}
