# ================================================================
# 02-7_矢印描画.ps1
# ================================================================
# 責任: ノード間の矢印の描画・表示・削除
# 
# 含まれる関数:
#   - 矢印を描く
#   - 矢印を表示する
#   - 矢印を削除する
#
# リファクタリング: 2025-11-01
# 元ファイル: 02_メインフォームUI_foam関数.ps1 (行2378-2512)
# ================================================================

# 02-7_矢印描画.ps1

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
