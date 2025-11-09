# 20241117_メインfoam関数.ps1

function 実行イベント {

            try {
                # メインフレームパネル内のボタンを取得し、Y座標でソート
                $buttons = $global:レイヤー1.Controls |
                           Where-Object { $_ -is [System.Windows.Forms.Button] } |
                           Sort-Object { $_.Location.Y }

                # 出力用の文字列変数を初期化
                $output = ""

                # ボタンの総数を取得
                $buttonCount = $buttons.Count
                write-host "ボタンカウント" + $buttons.Count
                # 最後に見つかったGreenボタンの親IDを格納
                $lastGreenParentId = $null

                for ($i = 0; $i -lt $buttonCount; $i++) {
                    $button = $buttons[$i]
                    $buttonName = $button.Name
                    $buttonText = $button.Text
                    $buttonColor = $button.BackColor  # ボタンの背景色を取得

                    # 背景色の情報を取得（色名）
                    $colorName = $buttonColor.Name

                    # ボタン情報をコンソールに出力
                    $buttonInfo = "ボタン名: $buttonName, テキスト: $buttonText, 色: $colorName"
                    #Write-Host $buttonInfo

                    # ボタン名のみをIDとして使用
                    $id = $buttonName

                    # エントリを取得
                    $取得したエントリ = IDでエントリを取得 -ID $id
                    Write-Host "取得したエントリ:$取得したエントリ"
                    if ($取得したエントリ -ne $null) {
                        # エントリの内容をコンソールに出力
                        Write-Host "エントリID: $id`n内容:`n$取得したエントリ`n"

                        # エントリが "AAAA" で始まる場合は展開（Pinkノード）
                        if ($取得したエントリ -match "^AAAA") {
                            Write-Host "Pinkノード（スクリプト化されたノード）を展開します"
                            $取得したエントリ = ノードリストを展開 -ノードリスト文字列 $取得したエントリ
                        }

                        # エントリの内容のみを$outputに追加（空行を追加）
                        $output += "$取得したエントリ`n`n"
                    }
                    else {
                        # エントリが存在しない場合のメッセージをコンソールに出力
                        #Write-Host "エントリID: $id は存在しません。`n"
                    }

                    # 現在のボタンがGreenの場合、lastGreenParentIdを更新
                    if ($colorName -eq "Green") {
                        # 親IDを抽出（例: "76-1" -> "76"）
                        $lastGreenParentId = ($id -split '-')[0]
                    }

                    # 現在のボタンがRedで、次のボタンがBlueの場合に特定のIDを挿入
                    if ($colorName -eq "Red" -and ($i + 1) -lt $buttonCount) {
                        $nextButton = $buttons[$i + 1]
                        $nextColorName = $nextButton.BackColor.Name

                        if ($nextColorName -eq "Blue") {
                            if ($lastGreenParentId -ne $null) {
                                # 特定のIDをlastGreenParentIdに基づいて設定（例: "76-2"）
                                $specialId = "$lastGreenParentId-2"

                                # 特定のIDでエントリを取得
                                $specialEntry = IDでエントリを取得 -ID $specialId
                                if ($specialEntry -ne $null) {
                                    # エントリの内容をコンソールに出力
                                    #Write-Host "エントリID: $specialId`n内容:`n$specialEntry`n"

                                    # エントリの内容のみを$outputに追加（空行を追加）
                                    $output += "$specialEntry`n`n"
                                }
                                else {
                                    # エントリが存在しない場合のメッセージをコンソールに出力
                                    #Write-Host "エントリID: $specialId は存在しません。`n"
                                }
                            }
                            else {
                                # lastGreenParentIdがない場合のメッセージをコンソールに出力
                                #Write-Host "直近のGreenボタンが存在しません。特別なIDを挿入できません。`n"
                            }
                        }
                    }
                }

                # テキストファイルのパスを設定（ps1と同じディレクトリ）
                $outputFilePath = Join-Path -Path $global:folderPath  -ChildPath "output.ps1"

                # 出力をファイルに書き込む
                try {
                    $output | Set-Content -Path $outputFilePath -Force -Encoding UTF8
                    #Write-Host "出力をファイルに書き込みました。ファイルパス: $outputFilePath"
                }
                catch {
                    Write-Error "出力ファイルの書き込みに失敗しました。"
                    return
                }

                # テキストファイルをモニター1で最大化して開く
                try {
                    # Notepadを最大化された状態で起動
                    #Start-Process notepad.exe -ArgumentList $outputFilePath -WindowStyle Maximized
                    #Start-Process -FilePath "powershell_ise.exe" -ArgumentList $outputFilePath -WindowStyle Maximized
                    # -NoProfile を付けることで新しいプロセスとして起動
                   Start-Process -FilePath "powershell_ise.exe" -ArgumentList $outputFilePath -NoNewWindow

                    # 修正版コード
                   #Start-Process -FilePath "powershell_ise.exe" -ArgumentList $outputFilePath -Separate


                    #Write-Host "テキストファイルをモニター1で最大化して開きました。"
                }
                catch {
                    Write-Error "テキストファイルを開く際にエラーが発生しました。"
                }
            }
            catch {
                Write-Error "エラーが発生しました: $_"
            }
  
       # Set-ExecuteButtonClickEvent 関数の閉じ中括弧
    }

# ノードリストを展開する再帰関数
function ノードリストを展開 {
    param (
        [string]$ノードリスト文字列
    )

    Write-Host "=== ノードリスト展開開始 ==="
    Write-Host "入力: $ノードリスト文字列"

    # "AAAA" を除去
    $ノードリスト文字列 = $ノードリスト文字列 -replace "^AAAA\s*", ""

    # 行ごとに分割
    $lines = $ノードリスト文字列 -split "`r?`n" | Where-Object { $_.Trim() -ne "" }

    Write-Host "ノード数: $($lines.Count)"

    $output = ""

    foreach ($line in $lines) {
        # 形式: <ノードID>;<背景色>;<テキスト>;
        $parts = $line -split ";"
        if ($parts.Count -ge 1) {
            $nodeId = $parts[0].Trim()
            Write-Host "処理中のノードID: $nodeId"

            # このノードのエントリを取得
            $entry = IDでエントリを取得 -ID $nodeId

            if ($entry -ne $null) {
                Write-Host "取得したエントリ: $entry"

                # エントリが "AAAA" で始まる場合は再帰的に展開
                if ($entry -match "^AAAA") {
                    Write-Host "再帰的に展開します"
                    $entry = ノードリストを展開 -ノードリスト文字列 $entry
                }

                $output += "$entry`n"
            } else {
                Write-Host "エントリが見つかりません: $nodeId"
            }
        }
    }

    Write-Host "=== ノードリスト展開完了 ==="
    return $output
}

function 変数イベント {

            $メインフォーム.Hide()
            $スクリプトPath = $PSScriptRoot # 現在のスクリプトのディレクトリを変数に格納
            #."$スクリプトPath\20241117_変数管理UI.ps1"
            $variableName = Show-VariableManagerForm
            $メインフォーム.Show()     
}

function フォルダ作成イベント {

            $メインフォーム.Hide()
            新規フォルダ作成
            $メインフォーム.Show()
     
}

function フォルダ切替イベント {

            $メインフォーム.Hide()
           フォルダ選択と保存 
            $メインフォーム.Show()     
}

function Update-説明ラベル {
    param (
        [string]$説明文
    )
    if ($説明文) {
        $global:説明ラベル.Text = $説明文
        #Write-Host "説明文を更新: $説明文"
    } else {
        $global:説明ラベル.Text = "ここに説明文が表示されます。"
        #Write-Host "説明文をクリア"
    }
}

function 切替ボタンイベント {
    param (
        [array]$SwitchButtons,
        [array]$SwitchTexts
    )

    for ($i = 0; $i -lt $SwitchButtons.Count; $i++) {
        $ボタン = $SwitchButtons[$i]
        $ボタンテキスト = $SwitchTexts[$i]
        $説明文 = $global:切替ボタン説明[$ボタン.Text]

        # 各ボタンのTagプロパティに説明文を設定
        $ボタン.Tag = $説明文

        # GotFocusイベント
        $ボタン.Add_GotFocus({
            param($sender, $e)
            Update-説明ラベル -説明文 $sender.Tag
            #Write-Host "$($sender.Text) ボタンにフォーカスが当たりました。"
        })

        # LostFocusイベント
        $ボタン.Add_LostFocus({
            param($sender, $e)
            Update-説明ラベル -説明文 $null
            #Write-Host "$($sender.Text) ボタンのフォーカスが外れました。"
        })

        # MouseEnterイベント
        $ボタン.Add_MouseEnter({
            param($sender, $e)
            Update-説明ラベル -説明文 $sender.Tag
            #Write-Host "$($sender.Text) ボタンにマウスが入りました。"
        })

        # MouseLeaveイベント
        $ボタン.Add_MouseLeave({
            param($sender, $e)
            Update-説明ラベル -説明文 $null
            #Write-Host "$($sender.Text) ボタンからマウスが離れました。"
        })
    }
} # Set-SwitchButtonEventHandlers 関数の閉じ中括弧

# Windowsフォームを利用するための必要なアセンブリを読み込み
Add-Type -AssemblyName System.Windows.Forms

function 新規フォルダ作成 {
    # 保存先をスクリプトの同じ場所とする新規フォルダ作成スクリプト

    # 現在のスクリプトのパスを取得
    $保存先ディレクトリ = $PSScriptRoot
    #Write-Host "保存先ディレクトリ: $保存先ディレクトリ"


    $保存先ディレクトリ = $保存先ディレクトリ + "\03_history"

    # インプットボックスでフォルダ名を取得
    $入力フォーム = New-Object Windows.Forms.Form
    $入力フォーム.Text = "フォルダ名入力"
    $入力フォーム.Size = New-Object Drawing.Size(400,150)

    $ラベル = New-Object Windows.Forms.Label
    $ラベル.Text = "新しいフォルダ名を入力してください:"
    $ラベル.AutoSize = $true
    $ラベル.Location = New-Object Drawing.Point(10,20)

    $テキストボックス = New-Object Windows.Forms.TextBox
    $テキストボックス.Size = New-Object Drawing.Size(350,30)
    $テキストボックス.Location = New-Object Drawing.Point(10,50)

    $ボタン = New-Object Windows.Forms.Button
    $ボタン.Text = "作成"
    $ボタン.Location = New-Object Drawing.Point(10,90)
    $ボタン.Add_Click({$入力フォーム.Close()})

    $入力フォーム.Controls.Add($ラベル)
    $入力フォーム.Controls.Add($テキストボックス)
    $入力フォーム.Controls.Add($ボタン)

    $入力フォーム.ShowDialog()

    $フォルダ名 = $テキストボックス.Text

    if (-not $フォルダ名) {
        #Write-Host "フォルダ名が入力されませんでした。処理を中止します。"
        return
    }

    

    # 保存先のフルパスを生成
    $フォルダパス = Join-Path -Path $保存先ディレクトリ -ChildPath $フォルダ名

    # 新規フォルダを作成
    if (-not (Test-Path -Path $フォルダパス)) {
        New-Item -Path $フォルダパス -ItemType Directory | Out-Null
        #Write-Host "フォルダが作成されました: $フォルダパス"
    } else {
        #Write-Host "フォルダは既に存在しています: $フォルダパス"
    }

    # メイン.json ファイルに保存
    $jsonFilePath = Join-Path -Path $保存先ディレクトリ -ChildPath "メイン.json"

    # JSONデータを作成
    $jsonData = @{}
    if (Test-Path -Path $jsonFilePath) {
        # 既存のJSONファイルがある場合は読み込む（共通関数使用）
        $existingData = Read-JsonSafe -Path $jsonFilePath -Required $false -Silent $true
        if ($existingData) {
            $jsonData = $existingData
        }
    }
    $jsonData.フォルダパス = $フォルダパス

    # JSONファイルに書き込み（共通関数使用）
    Write-JsonSafe -Path $jsonFilePath -Data $jsonData -Depth 10 -Silent $true
    #Write-Host "フォルダパスがメイン.jsonに保存されました: $jsonFilePath"


    $スクリプトPath = $PSScriptRoot # 現在のスクリプトのディレクトリを変数に格納

    # 関数の呼び出し例
$global:folderPath = 取得-JSON値 -jsonFilePath "$スクリプトPath\03_history\メイン.json" -keyName "フォルダパス"
$global:JSONPath = "$global:folderPath\variables.json"

            $outputFile = $global:JSONPath
        try {
            # 出力フォルダが存在しない場合は作成
            $outputFolder = Split-Path -Parent $outputFile

            [System.Windows.Forms.MessageBox]::Show($outputFolder)

            # JSON保存（共通関数使用 - ディレクトリ作成も自動）
            Write-JsonSafe -Path $outputFile -Data $global:variables -Depth 10 -CreateDirectory $true -Silent $true
            [System.Windows.Forms.MessageBox]::Show("変数がJSON形式で保存されました: `n$outputFile") | Out-Null
        } catch {
            [System.Windows.Forms.MessageBox]::Show("JSONの保存に失敗しました: $_") | Out-Null
        }

        #."C:\Users\hallo\Documents\WindowsPowerShell\chord\RPA-UI2\20241112_(メイン)コードID管理JSON.ps1"
        JSON初回
        JSONストアを初期化


}

# Windowsフォームを利用するための必要なアセンブリを読み込み
Add-Type -AssemblyName System.Windows.Forms

# Windowsフォームを利用するための必要なアセンブリを読み込み
Add-Type -AssemblyName System.Windows.Forms

function フォルダ選択と保存 {
    # 保存先ディレクトリを取得
    $保存先ディレクトリ = Join-Path -Path $PSScriptRoot -ChildPath "03_history"
    
    if (-not (Test-Path -Path $保存先ディレクトリ)) {
        New-Item -Path $保存先ディレクトリ -ItemType Directory | Out-Null
    }
    
    # 保存先ディレクトリ内のフォルダ一覧を取得
    $フォルダ一覧 = Get-ChildItem -Path $保存先ディレクトリ -Directory | Select-Object -ExpandProperty Name

    # フォーム作成
    $入力フォーム = New-Object Windows.Forms.Form
    $入力フォーム.Text = "フォルダ選択"
    $入力フォーム.Size = New-Object Drawing.Size(400,300)
    
    $ラベル = New-Object Windows.Forms.Label
    $ラベル.Text = "フォルダを選択してください:"
    $ラベル.AutoSize = $true
    $ラベル.Location = New-Object Drawing.Point(10,10)

    $リストボックス = New-Object Windows.Forms.ListBox
    $リストボックス.Size = New-Object Drawing.Size(350,200)
    $リストボックス.Location = New-Object Drawing.Point(10,40)
    $リストボックス.Items.AddRange($フォルダ一覧)
    
    $ボタン = New-Object Windows.Forms.Button
    $ボタン.Text = "保存"
    $ボタン.Location = New-Object Drawing.Point(10,250)
    $ボタン.Add_Click({
        if ($リストボックス.SelectedItem) {
            $global:選択フォルダ = $リストボックス.SelectedItem
            $入力フォーム.Close()
        } else {
            Show-WarningDialog "フォルダを選択してください。" -Title "エラー"
        }
    })
    
    $入力フォーム.Controls.Add($ラベル)
    $入力フォーム.Controls.Add($リストボックス)
    $入力フォーム.Controls.Add($ボタン)

    # フォームを表示
    $入力フォーム.ShowDialog()

    if (-not $global:選択フォルダ) {
        #Write-Host "フォルダが選択されませんでした。処理を中止します。"
        return
    }

    # フォルダパスを取得
    $選択フォルダパス = Join-Path -Path $保存先ディレクトリ -ChildPath $global:選択フォルダ

    # JSONファイルへの保存
    $jsonFilePath = Join-Path -Path $保存先ディレクトリ -ChildPath "メイン.json"

    # JSONデータを作成
    $jsonData = @{ フォルダパス = $選択フォルダパス }
    if (Test-Path -Path $jsonFilePath) {
        # JSON読み込み（共通関数使用）
        $existingData = Read-JsonSafe -Path $jsonFilePath -Required $false -Silent $true
        if ($existingData) {
            $existingData.フォルダパス = $選択フォルダパス
            $jsonData = $existingData
        }
    }

    # JSONファイルに書き込み（共通関数使用）
    Write-JsonSafe -Path $jsonFilePath -Data $jsonData -Depth 10 -Silent $true
    #Write-Host "選択されたフォルダパスがメイン.jsonに保存されました: $選択フォルダパス"

    # 関数の呼び出し例
    $スクリプトPath = $PSScriptRoot # 現在のスクリプトのディレクトリを変数に格納
    $global:folderPath = 取得-JSON値 -jsonFilePath "$スクリプトPath\03_history\メイン.json" -keyName "フォルダパス"
    $global:JSONPath = "$global:folderPath\variables.json"
}

function 作成ボタンとイベント設定 {
    param (
        [string]$処理番号,
        [string]$テキスト,
        [string]$ボタン名,
        [System.Drawing.Color]$背景色,
        [object]$コンテナ,
        [string]$説明  # 新しく追加
    )
    
#
    # 新しいボタンを作成
    $新しいボタン = 00_汎用色ボタンを作成する -コンテナ $コンテナ -テキスト $テキスト -ボタン名 $ボタン名 -幅 160 -高さ 30 -X位置 10 -Y位置 $Y位置 -背景色 $背景色

    
$新しいボタン.Tag = @{
処理番号 = $処理番号
説明 = $説明
  } 



    # クリックイベントを設定（必要に応じて保持）
    00_汎用色ボタンのクリックイベントを設定する -ボタン $新しいボタン -処理番号 $処理番号


    # 説明文をハッシュテーブルに追加
    $global:作成ボタン説明[$処理番号] = $説明
    #Write-Host "作成ボタン説明追加: 処理番号=$処理番号, 説明=$説明"

    # MouseEnter イベントを設定
    $新しいボタン.Add_MouseEnter({
        param($sender, $eventArgs)
        #Write-Host "MouseEnter イベント発生: sender=$sender, Text=$($sender.Text)"
        

                $global:説明ラベル.Text = $説明
                   $tag = $sender.Tag
           $処理番号 = $tag.処理番号
             $説明 = $tag.説明

        if ($null -eq $処理番号) {
            #Write-Host "Error: 処理番号が null です。"
        }

        if ($global:作成ボタン説明.ContainsKey($処理番号)) {
            #Write-Host "説明文を設定: $($global:作成ボタン説明[$処理番号])"
            $global:説明ラベル.Text = $global:作成ボタン説明[$処理番号]
        } else {
            #Write-Host "説明文が見つかりません: 処理番号=$処理番号"
            $global:説明ラベル.Text = "このボタンには説明が設定されていません。"
        }
    })



    # MouseLeave イベントを設定
    $新しいボタン.Add_MouseLeave({
        #Write-Host "MouseLeave イベント発生: 説明ラベルをクリア"
        $global:説明ラベル.Text = ""
    })

    # GotFocus イベントを設定
    $新しいボタン.Add_GotFocus({
        param($sender, $eventArgs)
        #Write-Host "GotFocus イベント発生: sender=$sender, Text=$($sender.Text)"
        
        $global:説明ラベル.Text = $説明
                   $tag = $sender.Tag
           $処理番号 = $tag.処理番号
             $説明 = $tag.説明


        if ($null -eq $処理番号) {
            #Write-Host "Error: 処理番号が null です。"
        }

        if ($global:作成ボタン説明.ContainsKey($処理番号)) {
            #Write-Host "説明文を設定: $($global:作成ボタン説明[$処理番号])"
            #$global:説明ラベル.Text = $global:作成ボタン説明[$処理番号]
            $global:説明ラベル.Text = $説明
        } else {
            #Write-Host "説明文が見つかりません: 処理番号=$処理番号"
            $global:説明ラベル.Text = $説明
            #$global:説明ラベル.Text = "このボタンには説明が設定されていません。"
        }
    })

    # LostFocus イベントを設定
    $新しいボタン.Add_LostFocus({
        #Write-Host "LostFocus イベント発生: 説明ラベルをクリア"
        $global:説明ラベル.Text = ""
    })
}
