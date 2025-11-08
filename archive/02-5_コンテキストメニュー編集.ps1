# ================================================================
# 02-5_コンテキストメニュー編集.ps1
# ================================================================
# 責任: 右クリックメニュー・ノード編集・スクリプト実行
# 
# 含まれる関数:
#   - script:コンテキストメニューを初期化する
#   - script:名前変更処理
#   - script:スクリプト編集処理
#   - script:スクリプト実行処理
#   - 取得-JSON値
#   - 適用-赤枠に挟まれたボタンスタイル
#   - 表示-赤枠ボタン名一覧
#
# リファクタリング: 2025-11-01
# 元ファイル: 02_メインフォームUI_foam関数.ps1
# ================================================================

function script:コンテキストメニューを初期化する {
    ###Write-Host "コンテキストメニューを初期化します。"
    if (-not $script:ContextMenuInitialized) {
        # コンテキストメニューをスクリプトスコープで定義
        $script:右クリックメニュー = New-Object System.Windows.Forms.ContextMenuStrip
        $script:名前変更メニューアイテム = $script:右クリックメニュー.Items.Add("名前変更")
        $script:スクリプト編集メニューアイテム = $script:右クリックメニュー.Items.Add("スクリプト編集")
        $script:スクリプト実行メニューアイテム = $script:右クリックメニュー.Items.Add("スクリプト実行")
        $script:レイヤー化メニューアイテム = $script:右クリックメニュー.Items.Add("レイヤー化")
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
        $script:レイヤー化メニューアイテム.Add_Click({
            ###Write-Host "レイヤー化メニューがクリックされました。"
            script:レイヤー化処理
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
        Write-WarningLog "ボタンが取得できませんでした。"
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
        Write-WarningLog "ボタンが取得できませんでした。"
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
        Write-WarningLog "ボタンが取得できませんでした。"
    }

    if ($null -ne $メインフォーム) {
        ###Write-Host "メインフォームを再表示します。"
        $メインフォーム.Show()
    }
    ###Write-Host "スクリプト実行処理が完了しました。"
}

function script:レイヤー化処理 {
    ###Write-Host "レイヤー化処理を開始します。"

    # 右クリック時に格納したボタンを取得
    $btn = $script:右クリックメニュー.Tag
    ###Write-Host "取得したボタン: $($btn.Name)"

    if ($btn -ne $null) {
        # ボタンの親パネルを取得
        $フレームパネル = $btn.Parent

        if ($フレームパネル -ne $null) {
            # 赤枠ボタンの数を確認
            $赤枠カウント = 0
            foreach ($コントロール in $フレームパネル.Controls) {
                if ($コントロール -is [System.Windows.Forms.Button] -and
                    $コントロール.FlatStyle -eq 'Flat' -and
                    $コントロール.FlatAppearance.BorderColor.ToArgb() -eq [System.Drawing.Color]::Red.ToArgb()) {
                    $赤枠カウント++
                }
            }

            if ($赤枠カウント -gt 0) {
                ###Write-Host "赤枠ボタンが $赤枠カウント 個見つかりました。レイヤー化を実行します。"
                # レイヤー化を実行
                表示-赤枠ボタン名一覧 -フレームパネル $フレームパネル
            } else {
                Show-WarningDialog "レイヤー化するには、まず赤枠でボタンを選択してください。" -Title "レイヤー化エラー"
            }
        } else {
            Write-WarningLog "親パネルが取得できませんでした。"
        }
    } else {
        Write-WarningLog "ボタンが取得できませんでした。"
    }

    ###Write-Host "レイヤー化処理が完了しました。"
}


function 取得-JSON値 {
    param (
        [string]$jsonFilePath, # JSONファイルのパス
        [string]$keyName       # 取得したいキー名
    )
    # ファイルを確認
    # JSONファイルを読み込み（共通関数使用）
    $jsonContent = Read-JsonSafe -Path $jsonFilePath -Required $true -Silent $false
    if (-not $jsonContent) {
        throw "指定されたファイルが見つかりません: $jsonFilePath"
    }

    # 指定されたキーの値を取得
    if ($jsonContent.PSObject.Properties[$keyName]) {
        return $jsonContent.$keyName
    } else {
        throw "指定されたキーがJSONに存在しません: $keyName"
    }
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

            $削除対象ボタン = $フレームパネル.Controls | Where-Object { $_.Name -eq $名前 }            # ボタンを取得

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

