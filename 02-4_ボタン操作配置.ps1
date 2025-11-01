# ================================================================
# 02-4_ボタン操作配置.ps1
# ================================================================
# 責任: ボタンの配置・整列・情報取得
# 
# 含まれる関数:
#   - 10_ボタンの一覧取得
#   - 00_ボタンの上詰め再配置関数
#   - script:ボタンクリック情報表示
#   - Get-ButtonIndex
#
# リファクタリング: 2025-11-01
# 元ファイル: 02_メインフォームUI_foam関数.ps1
# ================================================================

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

