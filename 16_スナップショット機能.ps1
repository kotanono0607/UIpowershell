# ====================================================================
# タイトル: スナップショット機能
# 目的: 試行錯誤時に元の状態に戻せるようにする
# 将来: Undo/Redo機能への拡張を想定した設計
# ====================================================================

# スナップショット作成関数
function スナップショット作成 {
    <#
    .SYNOPSIS
        現在のノード配置とコードをスナップショットとして保存

    .DESCRIPTION
        memory.json と コード.json をバックアップし、
        いつでも現在の状態に戻れるようにする。
        将来的にはUndo/Redoの基盤として使用予定。
    #>

    try {
        # パス定義
        $memoryPath = Join-Path $global:folderPath 'memory.json'
        $codePath = Join-Path $global:folderPath 'コード.json'
        $snapshotMemoryPath = Join-Path $global:folderPath 'memory_snapshot.json'
        $snapshotCodePath = Join-Path $global:folderPath 'コード_snapshot.json'

        # memory.jsonをバックアップ
        if (Test-Path $memoryPath) {
            Copy-Item -Path $memoryPath -Destination $snapshotMemoryPath -Force
        }

        # コード.jsonをバックアップ
        if (Test-Path $codePath) {
            Copy-Item -Path $codePath -Destination $snapshotCodePath -Force
        }

        # スナップショット情報を記録（将来のUndo/Redo用）
        $snapshotInfo = @{
            作成日時 = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
            説明 = "スナップショット"
            タイプ = "手動"
        }

        $snapshotInfoPath = Join-Path $global:folderPath 'snapshot_info.json'
        # JSON保存（共通関数使用）
        Write-JsonSafe -Path $snapshotInfoPath -Data $snapshotInfo -Depth 5 -Silent $false

        # 成功通知
        [System.Windows.Forms.MessageBox]::Show(
            "現在の状態をスナップショットとして保存しました。`r`n`r`n作成日時: $($snapshotInfo.作成日時)`r`n`r`n「復元」ボタンでこの状態に戻すことができます。",
            "📸 スナップショット作成完了",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null

        Write-Host "スナップショット作成: $($snapshotInfo.作成日時)" -ForegroundColor Green

    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "スナップショット作成中にエラーが発生しました:`r`n$_",
            "エラー",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null

        Write-Error "スナップショット作成エラー: $_"
    }
}


# スナップショット復元関数
function スナップショット復元 {
    <#
    .SYNOPSIS
        スナップショットから状態を復元

    .DESCRIPTION
        保存されたスナップショットから元の状態に戻す。
        現在の変更は失われるため、確認ダイアログを表示。
    #>

    try {
        # パス定義
        $snapshotMemoryPath = Join-Path $global:folderPath 'memory_snapshot.json'
        $snapshotCodePath = Join-Path $global:folderPath 'コード_snapshot.json'
        $snapshotInfoPath = Join-Path $global:folderPath 'snapshot_info.json'

        # スナップショット存在確認
        if (-not (Test-Path $snapshotMemoryPath)) {
            [System.Windows.Forms.MessageBox]::Show(
                "スナップショットが存在しません。`r`n`r`n先に「スナップショット」ボタンで現在の状態を保存してください。",
                "スナップショットなし",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            return
        }

        # スナップショット情報を取得（共通関数使用）
        $snapshotInfo = $null
        if (Test-Path $snapshotInfoPath) {
            $snapshotInfo = Read-JsonSafe -Path $snapshotInfoPath -Required $false -Silent $true
        }

        $snapshotDate = if ($snapshotInfo) { $snapshotInfo.作成日時 } else { "不明" }

        # 確認ダイアログ
        $result = [System.Windows.Forms.MessageBox]::Show(
            "スナップショットの状態に復元します。`r`n`r`nスナップショット作成日時: $snapshotDate`r`n`r`n現在の変更は失われますがよろしいですか？",
            "⚠️ 確認",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )

        if ($result -ne [System.Windows.Forms.DialogResult]::Yes) {
            return
        }

        # 復元実行
        $memoryPath = Join-Path $global:folderPath 'memory.json'
        $codePath = Join-Path $global:folderPath 'コード.json'

        # memory.jsonを復元
        if (Test-Path $snapshotMemoryPath) {
            Copy-Item -Path $snapshotMemoryPath -Destination $memoryPath -Force
        }

        # コード.jsonを復元
        if (Test-Path $snapshotCodePath) {
            Copy-Item -Path $snapshotCodePath -Destination $codePath -Force
        }

        # UIをリロード
        UIをリロード

        # 成功通知
        [System.Windows.Forms.MessageBox]::Show(
            "スナップショットから復元しました。`r`n`r`n復元日時: $snapshotDate",
            "✅ 復元完了",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null

        Write-Host "スナップショット復元: $snapshotDate" -ForegroundColor Cyan

    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "スナップショット復元中にエラーが発生しました:`r`n$_",
            "エラー",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null

        Write-Error "スナップショット復元エラー: $_"
    }
}


# UIリロード関数
function UIをリロード {
    <#
    .SYNOPSIS
        現在のレイヤーのノードをmemory.jsonから再読み込み

    .DESCRIPTION
        スナップショット復元後やUndo/Redo実行後に、
        UIを最新のmemory.jsonの状態に更新する。
    #>

    try {
        Write-Host "UIをリロード中..." -ForegroundColor Yellow

        # 現在のレイヤーを特定
        $現在のレイヤー番号 = グローバル変数から数値取得 -パネル $Global:可視左パネル

        # 現在のレイヤーのボタンをすべて削除
        フレームパネルからすべてのボタンを削除する -フレームパネル $Global:可視左パネル

        # memory.jsonから読み込み
        $memoryPath = Join-Path $global:folderPath 'memory.json'

        if (-not (Test-Path $memoryPath)) {
            Write-Host "memory.jsonが見つかりません" -ForegroundColor Red
            return
        }

        # JSON読み込み（共通関数使用）
        $memoryData = Read-JsonSafe -Path $memoryPath -Required $true -Silent $false

        # 現在のレイヤーのノードデータを取得
        $レイヤーデータ = $memoryData."$現在のレイヤー番号"

        if (-not $レイヤーデータ -or -not $レイヤーデータ.構成) {
            Write-Host "レイヤー $現在のレイヤー番号 のデータが存在しません" -ForegroundColor Yellow
            # 矢印を再描画
            00_矢印追記処理 -フレームパネル $Global:可視左パネル
            00_矢印追記処理 -フレームパネル $Global:可視右パネル
            return
        }

        # ノードを再作成
        foreach ($ノード in $レイヤーデータ.構成) {
            # ボタンを作成
            $ボタン = New-Object System.Windows.Forms.Button
            $ボタン.Name = $ノード.ボタン名
            $ボタン.Text = $ノード.テキスト
            $ボタン.Width = $ノード.幅
            $ボタン.Height = $ノード.高さ
            $ボタン.Location = New-Object System.Drawing.Point($ノード.X座標, $ノード.Y座標)

            # 背景色を設定
            try {
                $ボタン.BackColor = [System.Drawing.Color]::FromName($ノード.ボタン色)
            } catch {
                # ARGB形式の場合（例: ffc8dcff）
                if ($ノード.ボタン色 -match '^[0-9a-fA-F]{8}$') {
                    $argb = [Convert]::ToInt64($ノード.ボタン色, 16)
                    $ボタン.BackColor = [System.Drawing.Color]::FromArgb($argb)
                } else {
                    $ボタン.BackColor = [System.Drawing.Color]::White
                }
            }

            # Tagに情報を保存
            $ボタン.Tag = @{
                処理番号 = $ノード.処理番号
                script = $ノード.script
                GroupID = $ノード.GroupID
                IsDragging = $false
                StartPoint = [System.Drawing.Point]::Empty
            }

            # ドラッグ&ドロップイベントを設定
            $ボタン.AllowDrop = $true
            $ボタン.Add_MouseDown({
                param($s, $e)
                if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
                    $s.Tag.IsDragging = $true
                    $s.Tag.StartPoint = $e.Location
                    $global:ドラッグ中のボタン = $s
                    $s.DoDragDrop($s, [System.Windows.Forms.DragDropEffects]::Move)
                }
            })

            # クリックイベントを設定（ノード設定ダイアログ）
            $ボタン.Add_Click({
                param($sender, $e)
                if (-not $sender.Tag.IsDragging) {
                    # ノード設定処理を呼ぶ
                    00_文字列処理内容 -ボタン名 $sender.Name -処理番号 $sender.Tag.処理番号 -ボタン $sender
                }
            })

            # パネルに追加
            $Global:可視左パネル.Controls.Add($ボタン)
        }

        # ボタンを上詰めに再配置
        00_ボタンの上詰め再配置関数 -フレーム $Global:可視左パネル

        # 矢印を再描画
        00_矢印追記処理 -フレームパネル $Global:可視左パネル
        00_矢印追記処理 -フレームパネル $Global:可視右パネル

        Write-Host "UIリロード完了" -ForegroundColor Green

    } catch {
        Write-Error "UIリロードエラー: $_"
        [System.Windows.Forms.MessageBox]::Show(
            "UI再読み込み中にエラーが発生しました:`r`n$_",
            "エラー",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
}


# 将来のUndo/Redo機能用の構造（現時点では未実装）
# ====================================================================
# グローバル変数（将来用）
# $global:操作履歴 = @()  # 操作履歴スタック
# $global:履歴位置 = 0    # 現在の履歴位置
#
# function 操作を記録 {
#     param($操作タイプ, $操作データ)
#     # Undo/Redo実装時にここで操作を記録
# }
#
# function Undo実行 {
#     # 操作を1つ戻す
# }
#
# function Redo実行 {
#     # 操作を1つ進める
# }
# ====================================================================
