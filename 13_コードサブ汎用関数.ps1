# 必要なアセンブリの読み込み
Add-Type -AssemblyName System.Windows.Forms

# 汎用的なアイテム選択関数の定義
function リストから項目を選択 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$フォームタイトル,       # フォームのタイトル
       
        [Parameter(Mandatory = $true)]
        [string]$ラベルテキスト,       # ラベルのテキスト

        [Parameter(Mandatory = $true)]
        [string[]]$選択肢リスト           # 選択肢のリスト
    )

    #Write-Host "リストから項目を選択 関数が呼び出されました。"

    # フォームの作成
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = $フォームタイトル
    $フォーム.Size = New-Object System.Drawing.Size(400,200)
    $フォーム.StartPosition = "CenterScreen"

    # ラベルの作成
    $ラベル = New-Object System.Windows.Forms.Label
    $ラベル.Text = $ラベルテキスト
    $ラベル.AutoSize = $true
    $ラベル.Location = New-Object System.Drawing.Point(10,20)
    $フォーム.Controls.Add($ラベル)

    # コンボボックスの作成
    $コンボボックス = New-Object System.Windows.Forms.ComboBox
    $コンボボックス.Location = New-Object System.Drawing.Point(10,50)
    $コンボボックス.Size = New-Object System.Drawing.Size(360,20)
    $コンボボックス.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $コンボボックス.Items.AddRange($選択肢リスト)
    $コンボボックス.SelectedIndex = -1  # 何も選択されていない状態

    $フォーム.Controls.Add($コンボボックス)

    # OKボタンの作成
    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Size = New-Object System.Drawing.Size(75,23)
    $OKボタン.Location = New-Object System.Drawing.Point(220,100)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $フォーム.AcceptButton = $OKボタン
    $フォーム.Controls.Add($OKボタン)

    # Cancelボタンの作成
    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "Cancel"
    $キャンセルボタン.Size = New-Object System.Drawing.Size(75,23)
    $キャンセルボタン.Location = New-Object System.Drawing.Point(300,100)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $フォーム.CancelButton = $キャンセルボタン
    $フォーム.Controls.Add($キャンセルボタン)

    # フォームの表示
    #Write-Host "フォームを表示します。"
    $ダイアログ結果 = $フォーム.ShowDialog()

    # フォームの結果に応じて処理
    if ($ダイアログ結果 -eq [System.Windows.Forms.DialogResult]::OK) {
        if ($コンボボックス.SelectedItem -ne $null) {
            $選択項目 = $コンボボックス.SelectedItem
            #Write-Host "OKボタンがクリックされました。選択された項目: $選択項目"
            return $選択項目
        } else {
            [System.Windows.Forms.MessageBox]::Show("項目を選択してください。","エラー")
            #Write-Host "OKボタンがクリックされましたが、何も選択されていません。"
            return $null
        }
    } else {
        #Write-Host "Cancelボタンがクリックされました。選択をキャンセルします。"
        return $null
    }
}


# 文字列を入力する関数の定義
function 文字列を入力 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$フォームタイトル,       # フォームのタイトル
       
        [Parameter(Mandatory = $true)]
        [string]$ラベルテキスト        # ラベルのテキスト
    )

    #Write-Host "文字列を入力 関数が呼び出されました。"

    # フォームの作成
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = $フォームタイトル
    $フォーム.Size = New-Object System.Drawing.Size(400,250)
    $フォーム.StartPosition = "CenterScreen"

    # ラベルの作成
    $ラベル = New-Object System.Windows.Forms.Label
    $ラベル.Text = $ラベルテキスト
    $ラベル.AutoSize = $true
    $ラベル.Location = New-Object System.Drawing.Point(10,20)
    $フォーム.Controls.Add($ラベル)

    # テキストボックスの作成
    $テキストボックス = New-Object System.Windows.Forms.TextBox
    $テキストボックス.Location = New-Object System.Drawing.Point(10,50)
    $テキストボックス.Size = New-Object System.Drawing.Size(360,20)
    $フォーム.Controls.Add($テキストボックス)

    # OKボタンの作成
    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Size = New-Object System.Drawing.Size(75,23)
    $OKボタン.Location = New-Object System.Drawing.Point(220,150)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $フォーム.AcceptButton = $OKボタン
    $フォーム.Controls.Add($OKボタン)

    # Cancelボタンの作成
    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "Cancel"
    $キャンセルボタン.Size = New-Object System.Drawing.Size(75,23)
    $キャンセルボタン.Location = New-Object System.Drawing.Point(300,150)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $フォーム.CancelButton = $キャンセルボタン
    $フォーム.Controls.Add($キャンセルボタン)

    # 変数を使用ボタンの作成
    $変数使用ボタン = New-Object System.Windows.Forms.Button
    $変数使用ボタン.Text = "変数を使用"
    $変数使用ボタン.Size = New-Object System.Drawing.Size(100,23)
    $変数使用ボタン.Location = New-Object System.Drawing.Point(10,150)
    $フォーム.Controls.Add($変数使用ボタン)

    # 変数使用ボタンのイベントハンドラー
    $変数使用ボタン.Add_Click({
        #Write-Host "変数を使用ボタンがクリックされました。"


        　　#　＃＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝ここ決め打ち
             #$メインフォーム.Hide()
            #."C:\Users\hallo\Documents\WindowsPowerShell\chord\RPA-UI\20241117_変数管理システム.ps1"


            $variableName1 = Show-VariableManagerForm


                if ($variableName1 -ne $null) {
                    #Write-Host "選択された変数名1: $variableName1"
                } else {
                    #Write-Host "変数取得がキャンセルされました。"
                }


            #$メインフォーム.Show()


        # 変数管理システムを呼び出し、選択された変数名を取得
 

            $テキストボックス.Text += $variableName1
 
    })

    # フォームの表示
    #Write-Host "フォームを表示します。"
    $ダイアログ結果 = $フォーム.ShowDialog()

    # フォームの結果に応じて処理
    if ($ダイアログ結果 -eq [System.Windows.Forms.DialogResult]::OK) {
        if ($テキストボックス.Text.Trim() -ne "") {
            $入力文字列 = $テキストボックス.Text.Trim()
            #Write-Host "OKボタンがクリックされました。入力された文字列: $入力文字列"
            return $入力文字列
        } else {
            [System.Windows.Forms.MessageBox]::Show("文字列を入力してください。","エラー")
            #Write-Host "OKボタンがクリックされましたが、何も入力されていません。"
            return $null
        }
    } else {
        #Write-Host "Cancelボタンがクリックされました。入力をキャンセルします。"
        return $null
    }
}

# 数値を入力.ps1 - Ver 1.0
function 数値を入力 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$フォームタイトル,      # フォームのタイトル
        [Parameter(Mandatory = $true)]
        [string]$ラベルテキスト       # ラベルのテキスト
    )

    # フォームの作成
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = $フォームタイトル
    $フォーム.Size = New-Object System.Drawing.Size(400, 200)
    $フォーム.StartPosition = "CenterScreen"

    # ラベルの作成
    $ラベル = New-Object System.Windows.Forms.Label
    $ラベル.Text = $ラベルテキスト
    $ラベル.AutoSize = $true
    $ラベル.Location = New-Object System.Drawing.Point(10, 20)
    $フォーム.Controls.Add($ラベル)

    # 数値入力用 NumericUpDown コントロールの作成
    $数値入力 = New-Object System.Windows.Forms.NumericUpDown
    $数値入力.Location = New-Object System.Drawing.Point(10, 50)
    $数値入力.Size = New-Object System.Drawing.Size(360, 20)
    $数値入力.Minimum = [decimal]::MinValue   # 最小値を設定（必要に応じて変更可）
    $数値入力.Maximum = [decimal]::MaxValue   # 最大値を設定（必要に応じて変更可）
    $数値入力.DecimalPlaces = 0              # 整数のみ許可
    $フォーム.Controls.Add($数値入力)

    # OKボタンの作成
    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Size = New-Object System.Drawing.Size(75, 23)
    $OKボタン.Location = New-Object System.Drawing.Point(220, 120)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $フォーム.AcceptButton = $OKボタン
    $フォーム.Controls.Add($OKボタン)

    # Cancelボタンの作成
    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "Cancel"
    $キャンセルボタン.Size = New-Object System.Drawing.Size(75, 23)
    $キャンセルボタン.Location = New-Object System.Drawing.Point(300, 120)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $フォーム.CancelButton = $キャンセルボタン
    $フォーム.Controls.Add($キャンセルボタン)

    # フォームを表示
    $ダイアログ結果 = $フォーム.ShowDialog()

    # フォームの結果に応じて処理
    if ($ダイアログ結果 -eq [System.Windows.Forms.DialogResult]::OK) {
        $入力数値 = [int]$数値入力.Value
        return $入力数値
    } else {
        return $null
    }
}

# ============================================
# RPA実行用関数
# ============================================

# キー操作関数 - キーコマンドを送信する
function キー操作 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$キーコマンド
    )

    # キーコマンドをSendKeys形式に変換
    $sendKeysCommand = $キーコマンド

    # キーコマンドのマッピング（SendKeys形式に変換）
    $keyMap = @{
        "Ctrl+A" = "^a"
        "Ctrl+C" = "^c"
        "Ctrl+V" = "^v"
        "Ctrl+F" = "^f"
        "Alt+F4" = "%{F4}"
        "Del" = "{DELETE}"
        "Enter" = "{ENTER}"
        "Tab" = "{TAB}"
        "Shift+Tab" = "+{TAB}"
        "PageUp" = "{PGUP}"
        "PageDown" = "{PGDN}"
        "ArrowUp" = "{UP}"
        "ArrowDown" = "{DOWN}"
        "ArrowLeft" = "{LEFT}"
        "ArrowRight" = "{RIGHT}"
        "Esc" = "{ESC}"
    }

    if ($keyMap.ContainsKey($キーコマンド)) {
        $sendKeysCommand = $keyMap[$キーコマンド]
    }

    try {
        # SendKeysを使用してキーを送信
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.SendKeys]::SendWait($sendKeysCommand)
        Write-Host "キー操作を実行しました: $キーコマンド" -ForegroundColor Green
    }
    catch {
        Write-Warning "キー操作の実行に失敗しました: $($_.Exception.Message)"
    }
}

# 文字列入力関数 - 文字列をキーボード入力として送信する
function 文字列入力 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$入力文字列
    )

    try {
        # SendKeysを使用して文字列を送信
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.SendKeys]::SendWait($入力文字列)
        Write-Host "文字列を入力しました: $入力文字列" -ForegroundColor Green
    }
    catch {
        Write-Warning "文字列入力の実行に失敗しました: $($_.Exception.Message)"
    }
}

# 複数行テキストを編集する関数の定義
function 複数行テキストを編集 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$フォームタイトル,       # フォームのタイトル

        [Parameter(Mandatory = $true)]
        [string]$ラベルテキスト,        # ラベルのテキスト

        [Parameter(Mandatory = $false)]
        [string]$初期テキスト = ""      # 初期表示するテキスト
    )

    # フォームの作成
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = $フォームタイトル
    $フォーム.Size = New-Object System.Drawing.Size(800,600)
    $フォーム.StartPosition = "CenterScreen"

    # ラベルの作成
    $ラベル = New-Object System.Windows.Forms.Label
    $ラベル.Text = $ラベルテキスト
    $ラベル.AutoSize = $true
    $ラベル.Location = New-Object System.Drawing.Point(10,20)
    $フォーム.Controls.Add($ラベル)

    # 複数行テキストボックスの作成
    $テキストボックス = New-Object System.Windows.Forms.TextBox
    $テキストボックス.Location = New-Object System.Drawing.Point(10,50)
    $テキストボックス.Size = New-Object System.Drawing.Size(760,480)
    $テキストボックス.Multiline = $true
    $テキストボックス.ScrollBars = "Both"
    $テキストボックス.WordWrap = $false
    $テキストボックス.Font = New-Object System.Drawing.Font("Consolas",10)
    $テキストボックス.Text = $初期テキスト
    $フォーム.Controls.Add($テキストボックス)

    # OKボタンの作成
    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Size = New-Object System.Drawing.Size(100,30)
    $OKボタン.Location = New-Object System.Drawing.Point(580,540)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $フォーム.AcceptButton = $OKボタン
    $フォーム.Controls.Add($OKボタン)

    # Cancelボタンの作成
    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "Cancel"
    $キャンセルボタン.Size = New-Object System.Drawing.Size(100,30)
    $キャンセルボタン.Location = New-Object System.Drawing.Point(690,540)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $フォーム.CancelButton = $キャンセルボタン
    $フォーム.Controls.Add($キャンセルボタン)

    # フォームの表示
    $ダイアログ結果 = $フォーム.ShowDialog()

    # フォームの結果に応じて処理
    if ($ダイアログ結果 -eq [System.Windows.Forms.DialogResult]::OK) {
        return $テキストボックス.Text
    } else {
        return $null
    }
}
