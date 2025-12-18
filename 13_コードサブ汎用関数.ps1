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

    # フォームの表示（常に前面に表示）
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({ $this.Activate(); $this.BringToFront() })
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

    # フォームの表示（常に前面に表示）
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({ $this.Activate(); $this.BringToFront() })
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

    # フォームを表示（常に前面に表示）
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({ $this.Activate(); $this.BringToFront() })
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

# ファイルを選択する関数の定義 Ver1.0
function ファイルを選択 {
    param(
        [Parameter(Mandatory = $false)]
        [string]$タイトル = "ファイルを選択してください",

        [Parameter(Mandatory = $false)]
        [string]$フィルタ = "All Files (*.*)|*.*",

        [Parameter(Mandatory = $false)]
        [string]$初期ディレクトリ = [Environment]::GetFolderPath('Desktop')
    )

    # ファイル選択ダイアログの作成
    $ダイアログ = New-Object System.Windows.Forms.OpenFileDialog
    $ダイアログ.Title = $タイトル
    $ダイアログ.Filter = $フィルタ
    $ダイアログ.InitialDirectory = $初期ディレクトリ

    # ダイアログを表示
    $結果 = $ダイアログ.ShowDialog()

    if ($結果 -eq [System.Windows.Forms.DialogResult]::OK) {
        return $ダイアログ.FileName
    } else {
        return $null
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

    Write-Host "[複数行テキストを編集] 関数呼び出し - タイトル: $フォームタイトル" -ForegroundColor Cyan
    Write-Host "[複数行テキストを編集] 初期テキスト長: $($初期テキスト.Length)文字" -ForegroundColor Gray
    Write-Host "[複数行テキストを編集] 初期テキスト内容: [$初期テキスト]" -ForegroundColor Gray

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

    # フォームの表示（常に前面に表示）
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({ $this.Activate(); $this.BringToFront() })
    $ダイアログ結果 = $フォーム.ShowDialog()

    # フォームの結果に応じて処理
    if ($ダイアログ結果 -eq [System.Windows.Forms.DialogResult]::OK) {
        return $テキストボックス.Text
    } else {
        return $null
    }
}

# ノード設定編集フォーム関数の定義
function ノード設定を編集 {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ノード情報       # ノードの全情報を含むハッシュテーブル
    )

    Write-Host "[ノード設定を編集] 関数呼び出し - ノードID: $($ノード情報.id)" -ForegroundColor Cyan
    Write-Host "[ノード設定を編集] 処理番号: $($ノード情報.処理番号)" -ForegroundColor Gray

    # フォームの作成
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "ノード設定: $($ノード情報.text)"
    $フォーム.Size = New-Object System.Drawing.Size(850,750)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false

    $currentY = 10

    # ========================================
    # ノード名
    # ========================================
    $ラベル_ノード名 = New-Object System.Windows.Forms.Label
    $ラベル_ノード名.Text = "ノード名:"
    $ラベル_ノード名.AutoSize = $true
    $ラベル_ノード名.Location = New-Object System.Drawing.Point(10, $currentY)
    $ラベル_ノード名.Font = New-Object System.Drawing.Font("MS UI Gothic", 10, [System.Drawing.FontStyle]::Bold)
    $フォーム.Controls.Add($ラベル_ノード名)
    $currentY += 25

    $テキスト_ノード名 = New-Object System.Windows.Forms.TextBox
    $テキスト_ノード名.Location = New-Object System.Drawing.Point(10, $currentY)
    $テキスト_ノード名.Size = New-Object System.Drawing.Size(810, 25)
    $テキスト_ノード名.Text = $ノード情報.text
    $フォーム.Controls.Add($テキスト_ノード名)
    $currentY += 40

    # ========================================
    # 外観設定グループ
    # ========================================
    $グループ_外観 = New-Object System.Windows.Forms.GroupBox
    $グループ_外観.Text = "外観設定"
    $グループ_外観.Location = New-Object System.Drawing.Point(10, $currentY)
    $グループ_外観.Size = New-Object System.Drawing.Size(810, 180)
    $フォーム.Controls.Add($グループ_外観)

    # 背景色
    $ラベル_色 = New-Object System.Windows.Forms.Label
    $ラベル_色.Text = "背景色:"
    $ラベル_色.Location = New-Object System.Drawing.Point(15, 25)
    $ラベル_色.AutoSize = $true
    $グループ_外観.Controls.Add($ラベル_色)

    $コンボ_色 = New-Object System.Windows.Forms.ComboBox
    $コンボ_色.Location = New-Object System.Drawing.Point(15, 48)
    $コンボ_色.Size = New-Object System.Drawing.Size(200, 25)
    $コンボ_色.DropDownStyle = "DropDownList"
    $コンボ_色.Items.AddRange(@("White", "Pink", "LightGray", "LightBlue", "LightGreen", "LightYellow", "LightCoral", "Lavender"))
    if ($ノード情報.color) {
        $コンボ_色.SelectedItem = $ノード情報.color
    } else {
        $コンボ_色.SelectedItem = "White"
    }
    $グループ_外観.Controls.Add($コンボ_色)

    # 幅
    $ラベル_幅 = New-Object System.Windows.Forms.Label
    $ラベル_幅.Text = "幅:"
    $ラベル_幅.Location = New-Object System.Drawing.Point(240, 25)
    $ラベル_幅.AutoSize = $true
    $グループ_外観.Controls.Add($ラベル_幅)

    $数値_幅 = New-Object System.Windows.Forms.NumericUpDown
    $数値_幅.Location = New-Object System.Drawing.Point(240, 48)
    $数値_幅.Size = New-Object System.Drawing.Size(100, 25)
    $数値_幅.Minimum = 80
    $数値_幅.Maximum = 500
    $数値_幅.Value = if ($ノード情報.width) { $ノード情報.width } else { 120 }
    $グループ_外観.Controls.Add($数値_幅)

    # 高さ
    $ラベル_高さ = New-Object System.Windows.Forms.Label
    $ラベル_高さ.Text = "高さ:"
    $ラベル_高さ.Location = New-Object System.Drawing.Point(360, 25)
    $ラベル_高さ.AutoSize = $true
    $グループ_外観.Controls.Add($ラベル_高さ)

    $数値_高さ = New-Object System.Windows.Forms.NumericUpDown
    $数値_高さ.Location = New-Object System.Drawing.Point(360, 48)
    $数値_高さ.Size = New-Object System.Drawing.Size(100, 25)
    $数値_高さ.Minimum = 30
    $数値_高さ.Maximum = 200
    $数値_高さ.Value = if ($ノード情報.height) { $ノード情報.height } else { 40 }
    $グループ_外観.Controls.Add($数値_高さ)

    # X座標
    $ラベル_X = New-Object System.Windows.Forms.Label
    $ラベル_X.Text = "X座標:"
    $ラベル_X.Location = New-Object System.Drawing.Point(15, 90)
    $ラベル_X.AutoSize = $true
    $グループ_外観.Controls.Add($ラベル_X)

    $数値_X = New-Object System.Windows.Forms.NumericUpDown
    $数値_X.Location = New-Object System.Drawing.Point(15, 113)
    $数値_X.Size = New-Object System.Drawing.Size(150, 25)
    $数値_X.Minimum = 0
    $数値_X.Maximum = 2000
    $数値_X.Value = if ($ノード情報.x) { $ノード情報.x } else { 10 }
    $グループ_外観.Controls.Add($数値_X)

    # Y座標
    $ラベル_Y = New-Object System.Windows.Forms.Label
    $ラベル_Y.Text = "Y座標:"
    $ラベル_Y.Location = New-Object System.Drawing.Point(185, 90)
    $ラベル_Y.AutoSize = $true
    $グループ_外観.Controls.Add($ラベル_Y)

    $数値_Y = New-Object System.Windows.Forms.NumericUpDown
    $数値_Y.Location = New-Object System.Drawing.Point(185, 113)
    $数値_Y.Size = New-Object System.Drawing.Size(150, 25)
    $数値_Y.Minimum = 0
    $数値_Y.Maximum = 5000
    $数値_Y.Value = if ($ノード情報.y) { $ノード情報.y } else { 10 }
    $グループ_外観.Controls.Add($数値_Y)

    $currentY += 195

    # ========================================
    # カスタムフィールド（処理番号に応じて）
    # ========================================
    $テキスト_条件式 = $null
    $数値_ループ回数 = $null
    $テキスト_ループ変数 = $null

    if ($ノード情報.処理番号 -eq '1-2') {
        # 条件分岐
        $グループ_カスタム = New-Object System.Windows.Forms.GroupBox
        $グループ_カスタム.Text = "条件分岐設定"
        $グループ_カスタム.Location = New-Object System.Drawing.Point(10, $currentY)
        $グループ_カスタム.Size = New-Object System.Drawing.Size(810, 80)
        $グループ_カスタム.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 243, 205)
        $フォーム.Controls.Add($グループ_カスタム)

        $ラベル_条件式 = New-Object System.Windows.Forms.Label
        $ラベル_条件式.Text = "条件式:"
        $ラベル_条件式.Location = New-Object System.Drawing.Point(15, 25)
        $ラベル_条件式.AutoSize = $true
        $グループ_カスタム.Controls.Add($ラベル_条件式)

        $テキスト_条件式 = New-Object System.Windows.Forms.TextBox
        $テキスト_条件式.Location = New-Object System.Drawing.Point(15, 48)
        $テキスト_条件式.Size = New-Object System.Drawing.Size(780, 25)
        $テキスト_条件式.Text = if ($ノード情報.conditionExpression) { $ノード情報.conditionExpression } else { "" }
        $グループ_カスタム.Controls.Add($テキスト_条件式)

        $currentY += 95
    } elseif ($ノード情報.処理番号 -eq '1-3') {
        # ループ
        $グループ_カスタム = New-Object System.Windows.Forms.GroupBox
        $グループ_カスタム.Text = "ループ設定"
        $グループ_カスタム.Location = New-Object System.Drawing.Point(10, $currentY)
        $グループ_カスタム.Size = New-Object System.Drawing.Size(810, 110)
        $グループ_カスタム.BackColor = [System.Drawing.Color]::FromArgb(255, 209, 236, 241)
        $フォーム.Controls.Add($グループ_カスタム)

        $ラベル_ループ回数 = New-Object System.Windows.Forms.Label
        $ラベル_ループ回数.Text = "ループ回数:"
        $ラベル_ループ回数.Location = New-Object System.Drawing.Point(15, 25)
        $ラベル_ループ回数.AutoSize = $true
        $グループ_カスタム.Controls.Add($ラベル_ループ回数)

        $数値_ループ回数 = New-Object System.Windows.Forms.NumericUpDown
        $数値_ループ回数.Location = New-Object System.Drawing.Point(15, 48)
        $数値_ループ回数.Size = New-Object System.Drawing.Size(150, 25)
        $数値_ループ回数.Minimum = 1
        $数値_ループ回数.Maximum = 10000
        $数値_ループ回数.Value = if ($ノード情報.loopCount) { $ノード情報.loopCount } else { 1 }
        $グループ_カスタム.Controls.Add($数値_ループ回数)

        $ラベル_ループ変数 = New-Object System.Windows.Forms.Label
        $ラベル_ループ変数.Text = "ループ変数名:"
        $ラベル_ループ変数.Location = New-Object System.Drawing.Point(185, 25)
        $ラベル_ループ変数.AutoSize = $true
        $グループ_カスタム.Controls.Add($ラベル_ループ変数)

        $テキスト_ループ変数 = New-Object System.Windows.Forms.TextBox
        $テキスト_ループ変数.Location = New-Object System.Drawing.Point(185, 48)
        $テキスト_ループ変数.Size = New-Object System.Drawing.Size(200, 25)
        $テキスト_ループ変数.Text = if ($ノード情報.loopVariable) { $ノード情報.loopVariable } else { "i" }
        $グループ_カスタム.Controls.Add($テキスト_ループ変数)

        $currentY += 125
    }

    # ========================================
    # スクリプト
    # ========================================
    $ラベル_スクリプト = New-Object System.Windows.Forms.Label
    $ラベル_スクリプト.Text = "スクリプト:"
    $ラベル_スクリプト.AutoSize = $true
    $ラベル_スクリプト.Location = New-Object System.Drawing.Point(10, $currentY)
    $ラベル_スクリプト.Font = New-Object System.Drawing.Font("MS UI Gothic", 10, [System.Drawing.FontStyle]::Bold)
    $フォーム.Controls.Add($ラベル_スクリプト)
    $currentY += 25

    $テキスト_スクリプト = New-Object System.Windows.Forms.TextBox
    $テキスト_スクリプト.Location = New-Object System.Drawing.Point(10, $currentY)
    $テキスト_スクリプト.Size = New-Object System.Drawing.Size(810, 260)
    $テキスト_スクリプト.Multiline = $true
    $テキスト_スクリプト.ScrollBars = "Both"
    $テキスト_スクリプト.WordWrap = $false
    $テキスト_スクリプト.Font = New-Object System.Drawing.Font("Consolas", 10)
    $テキスト_スクリプト.Text = if ($ノード情報.script) { $ノード情報.script } else { "" }
    $フォーム.Controls.Add($テキスト_スクリプト)
    $currentY += 275

    # ========================================
    # OK/Cancelボタン
    # ========================================
    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "保存"
    $OKボタン.Size = New-Object System.Drawing.Size(100, 35)
    $OKボタン.Location = New-Object System.Drawing.Point(620, $currentY)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $フォーム.AcceptButton = $OKボタン
    $フォーム.Controls.Add($OKボタン)

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Size = New-Object System.Drawing.Size(100, 35)
    $キャンセルボタン.Location = New-Object System.Drawing.Point(730, $currentY)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $フォーム.CancelButton = $キャンセルボタン
    $フォーム.Controls.Add($キャンセルボタン)

    # フォームの表示（常に前面に表示）
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({ $this.Activate(); $this.BringToFront() })
    $ダイアログ結果 = $フォーム.ShowDialog()

    # フォームの結果に応じて処理
    if ($ダイアログ結果 -eq [System.Windows.Forms.DialogResult]::OK) {
        Write-Host "[ノード設定を編集] ✅ 保存ボタンが押されました" -ForegroundColor Green
        
        $結果 = @{
            text = $テキスト_ノード名.Text
            color = $コンボ_色.SelectedItem.ToString()
            width = [int]$数値_幅.Value
            height = [int]$数値_高さ.Value
            x = [int]$数値_X.Value
            y = [int]$数値_Y.Value
            script = $テキスト_スクリプト.Text
        }

        # カスタムフィールドを追加
        if ($テキスト_条件式) {
            $結果.conditionExpression = $テキスト_条件式.Text
            Write-Host "[ノード設定を編集] 条件式: $($テキスト_条件式.Text)" -ForegroundColor Gray
        }
        if ($数値_ループ回数) {
            $結果.loopCount = [int]$数値_ループ回数.Value
            Write-Host "[ノード設定を編集] ループ回数: $($数値_ループ回数.Value)" -ForegroundColor Gray
        }
        if ($テキスト_ループ変数) {
            $結果.loopVariable = $テキスト_ループ変数.Text
            Write-Host "[ノード設定を編集] ループ変数: $($テキスト_ループ変数.Text)" -ForegroundColor Gray
        }

        return $結果
    } else {
        Write-Host "[ノード設定を編集] ⚠️ キャンセルされました" -ForegroundColor Yellow
        return $null
    }
}


# ============================================
# 変数管理ダイアログ
# ============================================
function 変数管理を表示 {
    <#
    .SYNOPSIS
    変数管理ダイアログを表示（PowerShell Windows Forms版）

    .DESCRIPTION
    変数の一覧を表示し、追加・編集・削除を行うダイアログを表示します。

    .PARAMETER 変数リスト
    現在の変数リスト（配列形式）
    各要素は @{ name = "変数名"; value = "値"; type = "タイプ" } のハッシュテーブル

    .EXAMPLE
    $result = 変数管理を表示 -変数リスト $variables
    #>
    param(
        [Parameter(Mandatory = $false)]
        [array]$変数リスト = @()
    )

    Write-Host "[変数管理] ========== ダイアログ開始 ==========" -ForegroundColor Cyan
    Write-Host "[変数管理] 変数数: $($変数リスト.Count)" -ForegroundColor Gray

    # フォーム作成
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "変数管理"
    $フォーム.Size = New-Object System.Drawing.Size(700, 500)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $フォーム.MaximizeBox = $false

    # 変数を保持するためのスクリプト変数
    $script:現在の変数リスト = $変数リスト

    # ListView作成（変数一覧表示）
    $リストビュー = New-Object System.Windows.Forms.ListView
    $リストビュー.Location = New-Object System.Drawing.Point(20, 20)
    $リストビュー.Size = New-Object System.Drawing.Size(640, 350)
    $リストビュー.View = [System.Windows.Forms.View]::Details
    $リストビュー.FullRowSelect = $true
    $リストビュー.GridLines = $true
    $リストビュー.MultiSelect = $false

    # 列を追加
    $リストビュー.Columns.Add("変数名", 200) | Out-Null
    $リストビュー.Columns.Add("値", 300) | Out-Null
    $リストビュー.Columns.Add("タイプ", 100) | Out-Null

    $フォーム.Controls.Add($リストビュー)

    # ListView更新関数
    function Update-VariableListView {
        $リストビュー.Items.Clear()

        foreach ($var in $script:現在の変数リスト) {
            $item = New-Object System.Windows.Forms.ListViewItem($var.name)

            # 値の表示形式を調整
            $displayValue = ""
            if ($var.type -eq "一次元" -or $var.type -eq "二次元") {
                $displayValue = $var.displayValue
            } else {
                $displayValue = $var.value
            }

            # 長すぎる場合は省略
            if ($displayValue.Length -gt 80) {
                $displayValue = $displayValue.Substring(0, 77) + "..."
            }

            $item.SubItems.Add($displayValue) | Out-Null
            $item.SubItems.Add($var.type) | Out-Null
            $item.Tag = $var

            $リストビュー.Items.Add($item) | Out-Null
        }

        Write-Host "[変数管理] ListView更新: $($script:現在の変数リスト.Count)個の変数" -ForegroundColor Gray
    }

    # 追加ボタン
    $ボタン_追加 = New-Object System.Windows.Forms.Button
    $ボタン_追加.Text = "➕ 追加"
    $ボタン_追加.Location = New-Object System.Drawing.Point(20, 390)
    $ボタン_追加.Size = New-Object System.Drawing.Size(100, 30)
    $フォーム.Controls.Add($ボタン_追加)

    # 編集ボタン
    $ボタン_編集 = New-Object System.Windows.Forms.Button
    $ボタン_編集.Text = "✏️ 編集"
    $ボタン_編集.Location = New-Object System.Drawing.Point(130, 390)
    $ボタン_編集.Size = New-Object System.Drawing.Size(100, 30)
    $フォーム.Controls.Add($ボタン_編集)

    # 削除ボタン
    $ボタン_削除 = New-Object System.Windows.Forms.Button
    $ボタン_削除.Text = "🗑️ 削除"
    $ボタン_削除.Location = New-Object System.Drawing.Point(240, 390)
    $ボタン_削除.Size = New-Object System.Drawing.Size(100, 30)
    $フォーム.Controls.Add($ボタン_削除)

    # 閉じるボタン
    $ボタン_閉じる = New-Object System.Windows.Forms.Button
    $ボタン_閉じる.Text = "閉じる"
    $ボタン_閉じる.Location = New-Object System.Drawing.Point(560, 390)
    $ボタン_閉じる.Size = New-Object System.Drawing.Size(100, 30)
    $ボタン_閉じる.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $フォーム.Controls.Add($ボタン_閉じる)

    # 追加ボタンクリックイベント
    $ボタン_追加.Add_Click({
        Write-Host "[変数管理] 追加ボタンがクリックされました" -ForegroundColor Cyan

        # 変数追加ダイアログを表示
        $result = Show-AddVariableDialog

        if ($result) {
            Write-Host "[変数管理] 新しい変数を追加: $($result.name)" -ForegroundColor Green
            # リストに追加（実際のAPI呼び出しはJavaScript側で行う）
            $script:現在の変数リスト += $result
            Update-VariableListView
        }
    })

    # 編集ボタンクリックイベント
    $ボタン_編集.Add_Click({
        if ($リストビュー.SelectedItems.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "編集する変数を選択してください。",
                "変数管理",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            return
        }

        $selectedVar = $リストビュー.SelectedItems[0].Tag
        Write-Host "[変数管理] 編集ボタンがクリックされました: $($selectedVar.name)" -ForegroundColor Cyan

        # 変数編集ダイアログを表示
        $result = Show-EditVariableDialog -変数情報 $selectedVar

        if ($result) {
            Write-Host "[変数管理] 変数を更新: $($result.name)" -ForegroundColor Green
            # リストを更新
            $index = 0
            for ($i = 0; $i -lt $script:現在の変数リスト.Count; $i++) {
                if ($script:現在の変数リスト[$i].name -eq $selectedVar.name) {
                    $index = $i
                    break
                }
            }
            $script:現在の変数リスト[$index] = $result
            Update-VariableListView
        }
    })

    # 削除ボタンクリックイベント
    $ボタン_削除.Add_Click({
        if ($リストビュー.SelectedItems.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "削除する変数を選択してください。",
                "変数管理",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            return
        }

        $selectedVar = $リストビュー.SelectedItems[0].Tag
        Write-Host "[変数管理] 削除ボタンがクリックされました: $($selectedVar.name)" -ForegroundColor Cyan

        # 確認ダイアログ
        $confirmResult = [System.Windows.Forms.MessageBox]::Show(
            "変数「$($selectedVar.name)」を削除しますか？",
            "削除確認",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )

        if ($confirmResult -eq [System.Windows.Forms.DialogResult]::Yes) {
            Write-Host "[変数管理] 変数を削除: $($selectedVar.name)" -ForegroundColor Green
            # リストから削除
            $script:現在の変数リスト = $script:現在の変数リスト | Where-Object { $_.name -ne $selectedVar.name }
            Update-VariableListView
        }
    })

    # 初期表示
    Update-VariableListView

    # ダイアログ表示（常に前面に表示）
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({ $this.Activate(); $this.BringToFront() })
    $ダイアログ結果 = $フォーム.ShowDialog()

    Write-Host "[変数管理] ダイアログ結果: $ダイアログ結果" -ForegroundColor Gray

    if ($ダイアログ結果 -eq [System.Windows.Forms.DialogResult]::OK) {
        Write-Host "[変数管理] ✅ 変数管理を閉じました" -ForegroundColor Green
        return @{
            success = $true
            variables = $script:現在の変数リスト
        }
    } else {
        Write-Host "[変数管理] ⚠️ キャンセルされました" -ForegroundColor Yellow
        return $null
    }
}


# 変数追加ダイアログ
function Show-AddVariableDialog {
    $ダイアログ = New-Object System.Windows.Forms.Form
    $ダイアログ.Text = "変数を追加"
    $ダイアログ.Size = New-Object System.Drawing.Size(450, 220)
    $ダイアログ.StartPosition = "CenterParent"
    $ダイアログ.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $ダイアログ.MaximizeBox = $false
    $ダイアログ.MinimizeBox = $false

    # 変数名ラベル
    $ラベル_変数名 = New-Object System.Windows.Forms.Label
    $ラベル_変数名.Text = "変数名:"
    $ラベル_変数名.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル_変数名.AutoSize = $true
    $ダイアログ.Controls.Add($ラベル_変数名)

    # 変数名テキストボックス
    $テキスト_変数名 = New-Object System.Windows.Forms.TextBox
    $テキスト_変数名.Location = New-Object System.Drawing.Point(120, 20)
    $テキスト_変数名.Size = New-Object System.Drawing.Size(290, 20)
    $ダイアログ.Controls.Add($テキスト_変数名)

    # 値ラベル
    $ラベル_値 = New-Object System.Windows.Forms.Label
    $ラベル_値.Text = "値:"
    $ラベル_値.Location = New-Object System.Drawing.Point(20, 60)
    $ラベル_値.AutoSize = $true
    $ダイアログ.Controls.Add($ラベル_値)

    # 値テキストボックス
    $テキスト_値 = New-Object System.Windows.Forms.TextBox
    $テキスト_値.Location = New-Object System.Drawing.Point(120, 60)
    $テキスト_値.Size = New-Object System.Drawing.Size(290, 20)
    $ダイアログ.Controls.Add($テキスト_値)

    # タイプラベル
    $ラベル_タイプ = New-Object System.Windows.Forms.Label
    $ラベル_タイプ.Text = "タイプ:"
    $ラベル_タイプ.Location = New-Object System.Drawing.Point(20, 100)
    $ラベル_タイプ.AutoSize = $true
    $ダイアログ.Controls.Add($ラベル_タイプ)

    # タイプコンボボックス
    $コンボ_タイプ = New-Object System.Windows.Forms.ComboBox
    $コンボ_タイプ.Location = New-Object System.Drawing.Point(120, 100)
    $コンボ_タイプ.Size = New-Object System.Drawing.Size(290, 20)
    $コンボ_タイプ.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $コンボ_タイプ.Items.AddRange(@("単一値", "一次元", "二次元"))
    $コンボ_タイプ.SelectedIndex = 0
    $ダイアログ.Controls.Add($コンボ_タイプ)

    # OKボタン
    $ボタン_OK = New-Object System.Windows.Forms.Button
    $ボタン_OK.Text = "OK"
    $ボタン_OK.Location = New-Object System.Drawing.Point(230, 140)
    $ボタン_OK.Size = New-Object System.Drawing.Size(80, 30)
    $ボタン_OK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $ダイアログ.Controls.Add($ボタン_OK)

    # キャンセルボタン
    $ボタン_キャンセル = New-Object System.Windows.Forms.Button
    $ボタン_キャンセル.Text = "キャンセル"
    $ボタン_キャンセル.Location = New-Object System.Drawing.Point(320, 140)
    $ボタン_キャンセル.Size = New-Object System.Drawing.Size(90, 30)
    $ボタン_キャンセル.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $ダイアログ.Controls.Add($ボタン_キャンセル)

    $ダイアログ.AcceptButton = $ボタン_OK
    $ダイアログ.CancelButton = $ボタン_キャンセル

    # ダイアログ表示（常に前面に表示）
    $ダイアログ.Topmost = $true
    $ダイアログ.Add_Shown({ $this.Activate(); $this.BringToFront() })
    $result = $ダイアログ.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        if ([string]::IsNullOrWhiteSpace($テキスト_変数名.Text)) {
            [System.Windows.Forms.MessageBox]::Show(
                "変数名を入力してください。",
                "エラー",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
            return $null
        }

        return @{
            name = $テキスト_変数名.Text.Trim()
            value = $テキスト_値.Text
            type = $コンボ_タイプ.SelectedItem.ToString()
            displayValue = $テキスト_値.Text
        }
    }

    return $null
}


# 変数編集ダイアログ
function Show-EditVariableDialog {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$変数情報
    )

    $ダイアログ = New-Object System.Windows.Forms.Form
    $ダイアログ.Text = "変数を編集"
    $ダイアログ.Size = New-Object System.Drawing.Size(450, 220)
    $ダイアログ.StartPosition = "CenterParent"
    $ダイアログ.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $ダイアログ.MaximizeBox = $false
    $ダイアログ.MinimizeBox = $false

    # 変数名ラベル
    $ラベル_変数名 = New-Object System.Windows.Forms.Label
    $ラベル_変数名.Text = "変数名:"
    $ラベル_変数名.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル_変数名.AutoSize = $true
    $ダイアログ.Controls.Add($ラベル_変数名)

    # 変数名テキストボックス（読み取り専用）
    $テキスト_変数名 = New-Object System.Windows.Forms.TextBox
    $テキスト_変数名.Location = New-Object System.Drawing.Point(120, 20)
    $テキスト_変数名.Size = New-Object System.Drawing.Size(290, 20)
    $テキスト_変数名.Text = $変数情報.name
    $テキスト_変数名.ReadOnly = $true
    $テキスト_変数名.BackColor = [System.Drawing.SystemColors]::Control
    $ダイアログ.Controls.Add($テキスト_変数名)

    # 値ラベル
    $ラベル_値 = New-Object System.Windows.Forms.Label
    $ラベル_値.Text = "値:"
    $ラベル_値.Location = New-Object System.Drawing.Point(20, 60)
    $ラベル_値.AutoSize = $true
    $ダイアログ.Controls.Add($ラベル_値)

    # 値テキストボックス
    $テキスト_値 = New-Object System.Windows.Forms.TextBox
    $テキスト_値.Location = New-Object System.Drawing.Point(120, 60)
    $テキスト_値.Size = New-Object System.Drawing.Size(290, 20)

    # 現在の値を設定
    if ($変数情報.type -eq "一次元" -or $変数情報.type -eq "二次元") {
        $テキスト_値.Text = $変数情報.displayValue
    } else {
        $テキスト_値.Text = $変数情報.value
    }

    $ダイアログ.Controls.Add($テキスト_値)

    # タイプラベル
    $ラベル_タイプ = New-Object System.Windows.Forms.Label
    $ラベル_タイプ.Text = "タイプ:"
    $ラベル_タイプ.Location = New-Object System.Drawing.Point(20, 100)
    $ラベル_タイプ.AutoSize = $true
    $ダイアログ.Controls.Add($ラベル_タイプ)

    # タイプコンボボックス（読み取り専用）
    $コンボ_タイプ = New-Object System.Windows.Forms.ComboBox
    $コンボ_タイプ.Location = New-Object System.Drawing.Point(120, 100)
    $コンボ_タイプ.Size = New-Object System.Drawing.Size(290, 20)
    $コンボ_タイプ.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $コンボ_タイプ.Items.AddRange(@("単一値", "一次元", "二次元"))
    $コンボ_タイプ.SelectedItem = $変数情報.type
    $コンボ_タイプ.Enabled = $false
    $ダイアログ.Controls.Add($コンボ_タイプ)

    # OKボタン
    $ボタン_OK = New-Object System.Windows.Forms.Button
    $ボタン_OK.Text = "OK"
    $ボタン_OK.Location = New-Object System.Drawing.Point(230, 140)
    $ボタン_OK.Size = New-Object System.Drawing.Size(80, 30)
    $ボタン_OK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $ダイアログ.Controls.Add($ボタン_OK)

    # キャンセルボタン
    $ボタン_キャンセル = New-Object System.Windows.Forms.Button
    $ボタン_キャンセル.Text = "キャンセル"
    $ボタン_キャンセル.Location = New-Object System.Drawing.Point(320, 140)
    $ボタン_キャンセル.Size = New-Object System.Drawing.Size(90, 30)
    $ボタン_キャンセル.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $ダイアログ.Controls.Add($ボタン_キャンセル)

    $ダイアログ.AcceptButton = $ボタン_OK
    $ダイアログ.CancelButton = $ボタン_キャンセル

    # ダイアログ表示（常に前面に表示）
    $ダイアログ.Topmost = $true
    $ダイアログ.Add_Shown({ $this.Activate(); $this.BringToFront() })
    $result = $ダイアログ.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return @{
            name = $テキスト_変数名.Text.Trim()
            value = $テキスト_値.Text
            type = $変数情報.type
            displayValue = $テキスト_値.Text
        }
    }

    return $null
}


# ============================================
# フォルダ切替ダイアログ
# ============================================
function フォルダ切替を表示 {
    <#
    .SYNOPSIS
    フォルダ切替ダイアログを表示（PowerShell Windows Forms版）

    .DESCRIPTION
    フォルダの一覧を表示し、選択・新規作成を行うダイアログを表示します。

    .PARAMETER フォルダリスト
    現在のフォルダリスト（配列）

    .PARAMETER 現在のフォルダ
    現在選択されているフォルダ名

    .EXAMPLE
    $result = フォルダ切替を表示 -フォルダリスト @("folder1", "folder2") -現在のフォルダ "folder1"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$フォルダリスト,

        [Parameter(Mandatory = $false)]
        [string]$現在のフォルダ = ""
    )

    Write-Host "[フォルダ切替] ========== ダイアログ開始 ==========" -ForegroundColor Cyan
    Write-Host "[フォルダ切替] フォルダ数: $($フォルダリスト.Count)" -ForegroundColor Gray
    Write-Host "[フォルダ切替] 現在のフォルダ: $現在のフォルダ" -ForegroundColor Gray

    # フォルダリストをスクリプト変数に保存
    $script:現在のフォルダリスト = [System.Collections.ArrayList]::new($フォルダリスト)
    $script:選択されたフォルダ = $null
    $script:新規作成されたフォルダ = $null

    # フォーム作成
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "フォルダ管理"
    $フォーム.Size = New-Object System.Drawing.Size(500, 450)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $フォーム.MaximizeBox = $false

    # 説明ラベル
    $ラベル_説明 = New-Object System.Windows.Forms.Label
    $ラベル_説明.Text = "フォルダを選択してください:"
    $ラベル_説明.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル_説明.AutoSize = $true
    $フォーム.Controls.Add($ラベル_説明)

    # 現在のフォルダ表示ラベル
    if ($現在のフォルダ) {
        $ラベル_現在 = New-Object System.Windows.Forms.Label
        $ラベル_現在.Text = "現在のフォルダ: $現在のフォルダ"
        $ラベル_現在.Location = New-Object System.Drawing.Point(20, 45)
        $ラベル_現在.AutoSize = $true
        $ラベル_現在.ForeColor = [System.Drawing.Color]::Blue
        $フォーム.Controls.Add($ラベル_現在)
    }

    # ListBox作成（フォルダ一覧表示）
    $リストボックス = New-Object System.Windows.Forms.ListBox
    $リストボックス.Location = New-Object System.Drawing.Point(20, 75)
    $リストボックス.Size = New-Object System.Drawing.Size(440, 250)
    $リストボックス.Font = New-Object System.Drawing.Font("Consolas", 10)
    $フォーム.Controls.Add($リストボックス)

    # ListBox更新関数
    function Update-FolderListBox {
        $リストボックス.Items.Clear()
        foreach ($folder in $script:現在のフォルダリスト) {
            $リストボックス.Items.Add($folder) | Out-Null
        }

        # 現在のフォルダを選択状態にする
        if ($現在のフォルダ -and $script:現在のフォルダリスト.Contains($現在のフォルダ)) {
            $index = $script:現在のフォルダリスト.IndexOf($現在のフォルダ)
            $リストボックス.SelectedIndex = $index
        }

        Write-Host "[フォルダ切替] ListBox更新: $($script:現在のフォルダリスト.Count)個のフォルダ" -ForegroundColor Gray
    }

    # 選択ボタン
    $ボタン_選択 = New-Object System.Windows.Forms.Button
    $ボタン_選択.Text = "選択"
    $ボタン_選択.Location = New-Object System.Drawing.Point(20, 345)
    $ボタン_選択.Size = New-Object System.Drawing.Size(100, 35)
    $フォーム.Controls.Add($ボタン_選択)

    # 新規作成ボタン
    $ボタン_新規作成 = New-Object System.Windows.Forms.Button
    $ボタン_新規作成.Text = "新規作成"
    $ボタン_新規作成.Location = New-Object System.Drawing.Point(130, 345)
    $ボタン_新規作成.Size = New-Object System.Drawing.Size(100, 35)
    $フォーム.Controls.Add($ボタン_新規作成)

    # 削除ボタン
    $ボタン_削除 = New-Object System.Windows.Forms.Button
    $ボタン_削除.Text = "削除"
    $ボタン_削除.Location = New-Object System.Drawing.Point(240, 345)
    $ボタン_削除.Size = New-Object System.Drawing.Size(100, 35)
    $ボタン_削除.ForeColor = [System.Drawing.Color]::Red
    $フォーム.Controls.Add($ボタン_削除)

    # キャンセルボタン
    $ボタン_キャンセル = New-Object System.Windows.Forms.Button
    $ボタン_キャンセル.Text = "キャンセル"
    $ボタン_キャンセル.Location = New-Object System.Drawing.Point(360, 345)
    $ボタン_キャンセル.Size = New-Object System.Drawing.Size(100, 35)
    $ボタン_キャンセル.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $フォーム.Controls.Add($ボタン_キャンセル)

    # 選択ボタンクリックイベント
    $ボタン_選択.Add_Click({
        if ($リストボックス.SelectedItem) {
            $script:選択されたフォルダ = $リストボックス.SelectedItem.ToString()
            Write-Host "[フォルダ切替] フォルダが選択されました: $($script:選択されたフォルダ)" -ForegroundColor Green
            $フォーム.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $フォーム.Close()
        } else {
            [System.Windows.Forms.MessageBox]::Show(
                "フォルダを選択してください。",
                "フォルダ切替",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
        }
    })

    # 新規作成ボタンクリックイベント
    $ボタン_新規作成.Add_Click({
        # 新規フォルダ名入力ダイアログ
        $入力フォーム = New-Object System.Windows.Forms.Form
        $入力フォーム.Text = "新しいフォルダを作成"
        $入力フォーム.Size = New-Object System.Drawing.Size(400, 150)
        $入力フォーム.StartPosition = "CenterParent"
        $入力フォーム.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
        $入力フォーム.MaximizeBox = $false
        $入力フォーム.MinimizeBox = $false

        $ラベル = New-Object System.Windows.Forms.Label
        $ラベル.Text = "新しいフォルダ名:"
        $ラベル.Location = New-Object System.Drawing.Point(20, 20)
        $ラベル.AutoSize = $true
        $入力フォーム.Controls.Add($ラベル)

        $テキストボックス = New-Object System.Windows.Forms.TextBox
        $テキストボックス.Location = New-Object System.Drawing.Point(20, 50)
        $テキストボックス.Size = New-Object System.Drawing.Size(340, 20)
        $入力フォーム.Controls.Add($テキストボックス)

        $ボタン_OK = New-Object System.Windows.Forms.Button
        $ボタン_OK.Text = "作成"
        $ボタン_OK.Location = New-Object System.Drawing.Point(200, 80)
        $ボタン_OK.Size = New-Object System.Drawing.Size(75, 25)
        $ボタン_OK.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $入力フォーム.Controls.Add($ボタン_OK)

        $ボタン_キャンセル2 = New-Object System.Windows.Forms.Button
        $ボタン_キャンセル2.Text = "キャンセル"
        $ボタン_キャンセル2.Location = New-Object System.Drawing.Point(285, 80)
        $ボタン_キャンセル2.Size = New-Object System.Drawing.Size(75, 25)
        $ボタン_キャンセル2.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $入力フォーム.Controls.Add($ボタン_キャンセル2)

        $入力フォーム.AcceptButton = $ボタン_OK
        $入力フォーム.CancelButton = $ボタン_キャンセル2

        # ダイアログ表示（常に前面に表示）
        $入力フォーム.Topmost = $true
        $入力フォーム.Add_Shown({ $this.Activate(); $this.BringToFront() })
        $result = $入力フォーム.ShowDialog()

        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $新しいフォルダ名 = $テキストボックス.Text.Trim()

            if ([string]::IsNullOrWhiteSpace($新しいフォルダ名)) {
                [System.Windows.Forms.MessageBox]::Show(
                    "フォルダ名を入力してください。",
                    "エラー",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                ) | Out-Null
                return
            }

            if ($script:現在のフォルダリスト.Contains($新しいフォルダ名)) {
                [System.Windows.Forms.MessageBox]::Show(
                    "そのフォルダは既に存在します。",
                    "エラー",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                ) | Out-Null
                return
            }

            Write-Host "[フォルダ切替] 新しいフォルダを作成: $新しいフォルダ名" -ForegroundColor Green
            $script:現在のフォルダリスト.Add($新しいフォルダ名) | Out-Null
            $script:新規作成されたフォルダ = $新しいフォルダ名
            Update-FolderListBox

            # 作成したフォルダを選択状態にする
            $index = $script:現在のフォルダリスト.IndexOf($新しいフォルダ名)
            $リストボックス.SelectedIndex = $index
        }
    })

    # 削除ボタンクリックイベント
    $ボタン_削除.Add_Click({
        if ($リストボックス.SelectedItem) {
            $削除対象フォルダ = $リストボックス.SelectedItem.ToString()

            # 現在使用中のフォルダは削除不可
            if ($削除対象フォルダ -eq $現在のフォルダ) {
                [System.Windows.Forms.MessageBox]::Show(
                    "現在使用中のフォルダは削除できません。`n別のフォルダに切り替えてから削除してください。",
                    "削除エラー",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                ) | Out-Null
                return
            }

            # 確認ダイアログ
            $確認結果 = [System.Windows.Forms.MessageBox]::Show(
                "フォルダ「$削除対象フォルダ」を削除しますか？`n`nこの操作は元に戻せません。",
                "フォルダ削除の確認",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )

            if ($確認結果 -eq [System.Windows.Forms.DialogResult]::Yes) {
                Write-Host "[フォルダ管理] フォルダを削除: $削除対象フォルダ" -ForegroundColor Red

                # 03_historyフォルダからフォルダを削除
                $historyPath = Join-Path $global:RootDir "03_history"
                $削除パス = Join-Path $historyPath $削除対象フォルダ

                if (Test-Path $削除パス) {
                    try {
                        Remove-Item -Path $削除パス -Recurse -Force
                        Write-Host "[フォルダ管理] フォルダ削除完了: $削除パス" -ForegroundColor Green

                        # リストから削除
                        $script:現在のフォルダリスト.Remove($削除対象フォルダ)
                        Update-FolderListBox

                        [System.Windows.Forms.MessageBox]::Show(
                            "フォルダ「$削除対象フォルダ」を削除しました。",
                            "削除完了",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Information
                        ) | Out-Null
                    } catch {
                        Write-Host "[フォルダ管理] フォルダ削除エラー: $($_.Exception.Message)" -ForegroundColor Red
                        [System.Windows.Forms.MessageBox]::Show(
                            "フォルダの削除に失敗しました。`n$($_.Exception.Message)",
                            "削除エラー",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Error
                        ) | Out-Null
                    }
                } else {
                    Write-Host "[フォルダ管理] フォルダが見つかりません: $削除パス" -ForegroundColor Yellow
                    # リストからは削除
                    $script:現在のフォルダリスト.Remove($削除対象フォルダ)
                    Update-FolderListBox
                }
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show(
                "削除するフォルダを選択してください。",
                "フォルダ削除",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
        }
    })

    # ListBoxダブルクリックで選択
    $リストボックス.Add_DoubleClick({
        if ($リストボックス.SelectedItem) {
            $script:選択されたフォルダ = $リストボックス.SelectedItem.ToString()
            Write-Host "[フォルダ切替] フォルダが選択されました（ダブルクリック）: $($script:選択されたフォルダ)" -ForegroundColor Green
            $フォーム.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $フォーム.Close()
        }
    })

    # 初期表示
    Update-FolderListBox

    # ダイアログ表示（常に前面に表示）
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })
    $ダイアログ結果 = $フォーム.ShowDialog()

    Write-Host "[フォルダ管理] ダイアログ結果: $ダイアログ結果" -ForegroundColor Gray

    if ($ダイアログ結果 -eq [System.Windows.Forms.DialogResult]::OK) {
        Write-Host "[フォルダ切替] ✅ フォルダが選択されました: $($script:選択されたフォルダ)" -ForegroundColor Green
        return @{
            success = $true
            action = "select"
            folderName = $script:選択されたフォルダ
            newFolder = $script:新規作成されたフォルダ
        }
    } else {
        Write-Host "[フォルダ切替] ⚠️ キャンセルされました" -ForegroundColor Yellow
        return $null
    }
}


# ============================================
# コード結果表示ダイアログ
# ============================================
function コード結果を表示 {
    <#
    .SYNOPSIS
    コード生成結果を表示（PowerShell Windows Forms版）

    .DESCRIPTION
    生成されたコードと情報を表示し、コピーやファイルを開く操作を提供します。

    .PARAMETER 生成結果
    コード生成結果を含むハッシュテーブル
    - code: 生成されたコード
    - nodeCount: ノード数
    - outputPath: 出力先パス
    - timestamp: 生成時刻

    .EXAMPLE
    $result = コード結果を表示 -生成結果 @{ code = "..."; nodeCount = 5; outputPath = "C:\path\to\file.ps1"; timestamp = "2025-11-15 10:30:00" }
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$生成結果
    )

    Write-Host "[コード結果] ========== ダイアログ開始 ==========" -ForegroundColor Cyan
    Write-Host "[コード結果] ノード数: $($生成結果.nodeCount)" -ForegroundColor Gray
    Write-Host "[コード結果] 出力先: $($生成結果.outputPath)" -ForegroundColor Gray
    Write-Host "[コード結果] コード長: $($生成結果.code.Length)文字" -ForegroundColor Gray

    # フォーム作成
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "✅ コード生成完了"
    $フォーム.Size = New-Object System.Drawing.Size(900, 700)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
    $フォーム.MinimumSize = New-Object System.Drawing.Size(700, 500)

    # 情報パネル
    $パネル_情報 = New-Object System.Windows.Forms.Panel
    $パネル_情報.Location = New-Object System.Drawing.Point(20, 20)
    $パネル_情報.Size = New-Object System.Drawing.Size(840, 100)
    $パネル_情報.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $パネル_情報.BackColor = [System.Drawing.Color]::FromArgb(232, 245, 233)  # Light green
    $フォーム.Controls.Add($パネル_情報)

    # ノード数ラベル
    $ラベル_ノード数 = New-Object System.Windows.Forms.Label
    $ラベル_ノード数.Text = "📊 ノード数: $($生成結果.nodeCount)個"
    $ラベル_ノード数.Location = New-Object System.Drawing.Point(15, 15)
    $ラベル_ノード数.AutoSize = $true
    $ラベル_ノード数.Font = New-Object System.Drawing.Font("メイリオ", 10, [System.Drawing.FontStyle]::Regular)
    $パネル_情報.Controls.Add($ラベル_ノード数)

    # 出力先ラベル
    $出力先テキスト = if ($生成結果.outputPath) { $生成結果.outputPath } else { "（メモリ内のみ）" }
    $ラベル_出力先 = New-Object System.Windows.Forms.Label
    $ラベル_出力先.Text = "📁 出力先: $出力先テキスト"
    $ラベル_出力先.Location = New-Object System.Drawing.Point(15, 40)
    $ラベル_出力先.Size = New-Object System.Drawing.Size(800, 20)
    $ラベル_出力先.Font = New-Object System.Drawing.Font("メイリオ", 10, [System.Drawing.FontStyle]::Regular)
    $パネル_情報.Controls.Add($ラベル_出力先)

    # 生成時刻ラベル
    $時刻テキスト = if ($生成結果.timestamp) { $生成結果.timestamp } else { Get-Date -Format "yyyy/MM/dd HH:mm:ss" }
    $ラベル_時刻 = New-Object System.Windows.Forms.Label
    $ラベル_時刻.Text = "⏱️ 生成時刻: $時刻テキスト"
    $ラベル_時刻.Location = New-Object System.Drawing.Point(15, 65)
    $ラベル_時刻.AutoSize = $true
    $ラベル_時刻.Font = New-Object System.Drawing.Font("メイリオ", 10, [System.Drawing.FontStyle]::Regular)
    $パネル_情報.Controls.Add($ラベル_時刻)

    # コードプレビューラベル
    $ラベル_コード = New-Object System.Windows.Forms.Label
    $ラベル_コード.Text = "生成されたコード:"
    $ラベル_コード.Location = New-Object System.Drawing.Point(20, 135)
    $ラベル_コード.AutoSize = $true
    $ラベル_コード.Font = New-Object System.Drawing.Font("メイリオ", 10, [System.Drawing.FontStyle]::Bold)
    $フォーム.Controls.Add($ラベル_コード)

    # コードプレビュー TextBox
    $テキスト_コード = New-Object System.Windows.Forms.TextBox
    $テキスト_コード.Location = New-Object System.Drawing.Point(20, 160)
    $テキスト_コード.Size = New-Object System.Drawing.Size(840, 430)
    $テキスト_コード.Multiline = $true
    $テキスト_コード.ReadOnly = $true
    $テキスト_コード.ScrollBars = [System.Windows.Forms.ScrollBars]::Both
    $テキスト_コード.Font = New-Object System.Drawing.Font("Consolas", 10)
    $テキスト_コード.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
    $テキスト_コード.Text = $生成結果.code
    $テキスト_コード.WordWrap = $false
    $フォーム.Controls.Add($テキスト_コード)

    # リサイズイベント（コントロールのサイズを調整）
    $フォーム.Add_Resize({
        $newWidth = $フォーム.ClientSize.Width - 40
        $newHeight = $フォーム.ClientSize.Height - 180

        $パネル_情報.Width = $newWidth
        $テキスト_コード.Size = New-Object System.Drawing.Size($newWidth, ($newHeight - 70))

        # ボタンの位置を調整
        $ボタンY = $フォーム.ClientSize.Height - 50
        $ボタン_コピー.Location = New-Object System.Drawing.Point(20, $ボタンY)
        $ボタン_ファイル開く.Location = New-Object System.Drawing.Point(160, $ボタンY)
        $ボタン_EXE作成.Location = New-Object System.Drawing.Point(320, $ボタンY)
        $ボタン_実行.Location = New-Object System.Drawing.Point(460, $ボタンY)
        $ボタン_閉じる.Location = New-Object System.Drawing.Point(($フォーム.ClientSize.Width - 120), $ボタンY)
    })

    # コピーボタン
    $ボタン_コピー = New-Object System.Windows.Forms.Button
    $ボタン_コピー.Text = "📋 コピー"
    $ボタン_コピー.Location = New-Object System.Drawing.Point(20, 600)
    $ボタン_コピー.Size = New-Object System.Drawing.Size(130, 35)
    $フォーム.Controls.Add($ボタン_コピー)

    # ファイルを開くボタン
    $ボタン_ファイル開く = New-Object System.Windows.Forms.Button
    $ボタン_ファイル開く.Text = "📂 ファイルを開く"
    $ボタン_ファイル開く.Location = New-Object System.Drawing.Point(160, 600)
    $ボタン_ファイル開く.Size = New-Object System.Drawing.Size(150, 35)
    $フォーム.Controls.Add($ボタン_ファイル開く)

    # ファイルパスがない場合は無効化
    if (-not $生成結果.outputPath) {
        $ボタン_ファイル開く.Enabled = $false
    }

    # EXE作成ボタン
    $ボタン_EXE作成 = New-Object System.Windows.Forms.Button
    $ボタン_EXE作成.Text = "🔧 EXE作成"
    $ボタン_EXE作成.Location = New-Object System.Drawing.Point(320, 600)
    $ボタン_EXE作成.Size = New-Object System.Drawing.Size(130, 35)
    $ボタン_EXE作成.BackColor = [System.Drawing.Color]::FromArgb(255, 243, 224)  # Light orange
    $フォーム.Controls.Add($ボタン_EXE作成)

    # ファイルパスがない場合は無効化
    if (-not $生成結果.outputPath) {
        $ボタン_EXE作成.Enabled = $false
    }

    # 実行ボタン
    $ボタン_実行 = New-Object System.Windows.Forms.Button
    $ボタン_実行.Text = "🔥 実行"
    $ボタン_実行.Location = New-Object System.Drawing.Point(460, 600)
    $ボタン_実行.Size = New-Object System.Drawing.Size(100, 35)
    $ボタン_実行.BackColor = [System.Drawing.Color]::FromArgb(255, 200, 150)  # Orange
    $フォーム.Controls.Add($ボタン_実行)

    # 閉じるボタン
    $ボタン_閉じる = New-Object System.Windows.Forms.Button
    $ボタン_閉じる.Text = "閉じる"
    $ボタン_閉じる.Location = New-Object System.Drawing.Point(760, 600)
    $ボタン_閉じる.Size = New-Object System.Drawing.Size(100, 35)
    $ボタン_閉じる.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $フォーム.Controls.Add($ボタン_閉じる)

    # コピーボタンクリックイベント
    $ボタン_コピー.Add_Click({
        try {
            # 一時ファイル経由 + STAプロセスで日本語対応クリップボードコピー
            $tempFile = [System.IO.Path]::GetTempFileName()
            $テキスト_コード.Text | Out-File -FilePath $tempFile -Encoding UTF8 -NoNewline

            # STAモードの別プロセスでクリップボードにコピー
            $copyScript = "Get-Content -Path '$tempFile' -Raw -Encoding UTF8 | Set-Clipboard; Remove-Item -Path '$tempFile' -Force"
            Start-Process powershell -ArgumentList "-STA", "-NoProfile", "-WindowStyle", "Hidden", "-Command", $copyScript -Wait

            Write-Host "[コード結果] ✅ クリップボードにコピーしました" -ForegroundColor Green
            [System.Windows.Forms.MessageBox]::Show(
                "生成されたコードをクリップボードにコピーしました！",
                "コピー完了",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
        } catch {
            Write-Host "[コード結果] ❌ コピーエラー: $_" -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show(
                "コピーに失敗しました: $_",
                "エラー",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        }
    })

    # ファイルを開くボタンクリックイベント
    $ボタン_ファイル開く.Add_Click({
        if ($生成結果.outputPath -and (Test-Path $生成結果.outputPath)) {
            try {
                Write-Host "[コード結果] ファイルを開きます: $($生成結果.outputPath)" -ForegroundColor Cyan
                Start-Process $生成結果.outputPath
            } catch {
                Write-Host "[コード結果] ❌ ファイルを開けませんでした: $_" -ForegroundColor Red
                [System.Windows.Forms.MessageBox]::Show(
                    "ファイルを開けませんでした: $_",
                    "エラー",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                ) | Out-Null
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show(
                "ファイルが見つかりません。",
                "エラー",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
        }
    })

    # EXE作成ボタンクリックイベント
    $ボタン_EXE作成.Add_Click({
        if (-not $生成結果.outputPath -or -not (Test-Path $生成結果.outputPath)) {
            [System.Windows.Forms.MessageBox]::Show(
                "PowerShellファイルが見つかりません。",
                "エラー",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            return
        }

        try {
            Write-Host "[EXE作成] ps2exeによるEXE変換を開始..." -ForegroundColor Cyan

            # ps2exeモジュールのパス
            $ps2exeModulePath = "C:\Users\hello\Documents\WindowsPowerShell\Modules\ps2exe\1.0.15\ps2exe.psm1"

            # モジュールの存在確認
            if (-not (Test-Path $ps2exeModulePath)) {
                throw "ps2exeモジュールが見つかりません: $ps2exeModulePath"
            }

            # 出力EXEパス（.ps1 → .exe）
            $exePath = $生成結果.outputPath -replace '\.ps1$', '.exe'

            Write-Host "[EXE作成] 入力: $($生成結果.outputPath)" -ForegroundColor Gray
            Write-Host "[EXE作成] 出力: $exePath" -ForegroundColor Gray

            # 確認ダイアログ
            $確認結果 = [System.Windows.Forms.MessageBox]::Show(
                "EXEファイルを作成しますか？`n`n出力先: $exePath",
                "EXE作成確認",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )

            if ($確認結果 -ne [System.Windows.Forms.DialogResult]::Yes) {
                Write-Host "[EXE作成] キャンセルされました" -ForegroundColor Yellow
                return
            }

            # win32API.psm1を埋め込んだ一時ファイルを作成
            Write-Host "[EXE作成] win32API.psm1を埋め込みます..." -ForegroundColor Cyan

            # win32API.psm1のパスを解決（複数の方法でフォールバック）
            $win32ApiPath = $null

            # 方法1: $global:RootDir から取得
            if ($global:RootDir -and (Test-Path (Join-Path $global:RootDir "win32API.psm1"))) {
                $win32ApiPath = Join-Path $global:RootDir "win32API.psm1"
                Write-Host "[EXE作成] RootDirから検出: $win32ApiPath" -ForegroundColor Gray
            }
            # 方法2: $global:folderPath から2階層上（03_history/XXXX → root）
            elseif ($global:folderPath) {
                $rootFromFolder = Split-Path (Split-Path $global:folderPath -Parent) -Parent
                $pathFromFolder = Join-Path $rootFromFolder "win32API.psm1"
                if (Test-Path $pathFromFolder) {
                    $win32ApiPath = $pathFromFolder
                    Write-Host "[EXE作成] folderPathから検出: $win32ApiPath" -ForegroundColor Gray
                }
            }
            # 方法3: 出力ファイルから3階層上（03_history/XXXX/output.ps1 → root）
            if (-not $win32ApiPath -and $生成結果.outputPath) {
                $rootFromOutput = Split-Path (Split-Path (Split-Path $生成結果.outputPath -Parent) -Parent) -Parent
                $pathFromOutput = Join-Path $rootFromOutput "win32API.psm1"
                if (Test-Path $pathFromOutput) {
                    $win32ApiPath = $pathFromOutput
                    Write-Host "[EXE作成] 出力パスから検出: $win32ApiPath" -ForegroundColor Gray
                }
            }

            $tempScriptPath = $生成結果.outputPath -replace '\.ps1$', '_combined.ps1'

            if ($win32ApiPath -and (Test-Path $win32ApiPath)) {
                # win32API.psm1の内容を読み込み
                $win32ApiContent = Get-Content -Path $win32ApiPath -Raw -Encoding UTF8

                # 元のスクリプトを読み込み
                $originalScript = Get-Content -Path $生成結果.outputPath -Raw -Encoding UTF8

                # 結合（win32API.psm1の関数を先頭に配置）
                $combinedScript = @"
# ============================================
# win32API.psm1 埋め込み（EXE用）
# ============================================
$win32ApiContent

# ============================================
# 生成されたスクリプト
# ============================================
$originalScript
"@
                # 一時ファイルに保存
                Set-Content -Path $tempScriptPath -Value $combinedScript -Encoding UTF8 -Force
                Write-Host "[EXE作成] ✅ win32API.psm1を埋め込みました" -ForegroundColor Green
                Write-Host "[EXE作成] 一時ファイル: $tempScriptPath" -ForegroundColor Gray

                $inputFileForExe = $tempScriptPath
            } else {
                Write-Host "[EXE作成] ⚠ win32API.psm1が見つかりません。埋め込みなしで続行します" -ForegroundColor Yellow
                $inputFileForExe = $生成結果.outputPath
            }

            # ps2exeを実行
            Import-Module $ps2exeModulePath -Force
            Invoke-ps2exe -inputFile $inputFileForExe -outputFile $exePath -noConsole

            # 一時ファイルを削除
            if ((Test-Path $tempScriptPath) -and ($tempScriptPath -ne $生成結果.outputPath)) {
                Remove-Item -Path $tempScriptPath -Force -ErrorAction SilentlyContinue
                Write-Host "[EXE作成] 一時ファイルを削除しました" -ForegroundColor Gray
            }

            # 成功確認
            if (Test-Path $exePath) {
                Write-Host "[EXE作成] ✅ EXE作成成功: $exePath" -ForegroundColor Green
                $開く結果 = [System.Windows.Forms.MessageBox]::Show(
                    "EXEファイルを作成しました！`n`n$exePath`n`nフォルダを開きますか？",
                    "EXE作成完了",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )

                if ($開く結果 -eq [System.Windows.Forms.DialogResult]::Yes) {
                    # フォルダを開いてファイルを選択状態にする
                    Start-Process explorer.exe -ArgumentList "/select,`"$exePath`""
                }
            } else {
                throw "EXEファイルの作成に失敗しました"
            }

        } catch {
            Write-Host "[EXE作成] ❌ エラー: $_" -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show(
                "EXE作成中にエラーが発生しました:`n`n$_",
                "EXE作成エラー",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        }
    })

    # 実行ボタンクリックイベント
    $ボタン_実行.Add_Click({
        try {
            Write-Host "[実行] 生成コードを実行します..." -ForegroundColor Cyan

            # テキストボックスの内容を取得（編集されている可能性あり）
            $実行コード = $テキスト_コード.Text

            if ([string]::IsNullOrWhiteSpace($実行コード)) {
                [System.Windows.Forms.MessageBox]::Show(
                    "実行するコードがありません。",
                    "エラー",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                ) | Out-Null
                return
            }

            # 確認ダイアログ
            $確認結果 = [System.Windows.Forms.MessageBox]::Show(
                "生成されたコードを実行しますか？`n`n※ マウス・キーボード操作が含まれる場合、`n　 実行中は操作しないでください。",
                "実行確認",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )

            if ($確認結果 -ne [System.Windows.Forms.DialogResult]::Yes) {
                Write-Host "[実行] キャンセルされました" -ForegroundColor Yellow
                return
            }

            # RootDirを解決（複数の方法でフォールバック）
            $resolvedRootDir = $null

            # 方法1: $global:RootDir から取得
            if ($global:RootDir -and (Test-Path $global:RootDir)) {
                $resolvedRootDir = $global:RootDir
                Write-Host "[実行] RootDirから検出: $resolvedRootDir" -ForegroundColor Gray
            }
            # 方法2: $global:folderPath から2階層上（03_history/XXXX → root）
            elseif ($global:folderPath) {
                $rootFromFolder = Split-Path (Split-Path $global:folderPath -Parent) -Parent
                if (Test-Path $rootFromFolder) {
                    $resolvedRootDir = $rootFromFolder
                    Write-Host "[実行] folderPathから検出: $resolvedRootDir" -ForegroundColor Gray
                }
            }
            # 方法3: 出力ファイルから3階層上（03_history/XXXX/output.ps1 → root）
            if (-not $resolvedRootDir -and $生成結果.outputPath) {
                $rootFromOutput = Split-Path (Split-Path (Split-Path $生成結果.outputPath -Parent) -Parent) -Parent
                if (Test-Path $rootFromOutput) {
                    $resolvedRootDir = $rootFromOutput
                    Write-Host "[実行] 出力パスから検出: $resolvedRootDir" -ForegroundColor Gray
                }
            }

            if (-not $resolvedRootDir) {
                Write-Host "[実行] ⚠ RootDirを解決できませんでした" -ForegroundColor Yellow
            }

            # win32API.psm1を読み込み
            if ($resolvedRootDir) {
                $win32ApiPath = Join-Path $resolvedRootDir "win32API.psm1"
                if (Test-Path $win32ApiPath) {
                    Import-Module $win32ApiPath -Force -ErrorAction SilentlyContinue
                    Write-Host "[実行] win32API.psm1を読み込みました" -ForegroundColor Gray
                }

                # 汎用関数を読み込み
                $汎用関数パス = Join-Path $resolvedRootDir "13_コードサブ汎用関数.ps1"
                if (Test-Path $汎用関数パス) {
                    . $汎用関数パス
                    Write-Host "[実行] 汎用関数を読み込みました" -ForegroundColor Gray
                }
            }

            # スクリプトを実行
            Write-Host "[実行] コード実行開始..." -ForegroundColor Cyan
            $output = Invoke-Expression $実行コード 2>&1 | Out-String

            Write-Host "[実行] ✅ 実行完了" -ForegroundColor Green
            [System.Windows.Forms.MessageBox]::Show(
                "🔥 コード実行完了！`n`n出力:`n$output",
                "実行完了",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null

        } catch {
            Write-Host "[実行] ❌ エラー: $_" -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show(
                "実行中にエラーが発生しました:`n`n$($_.Exception.Message)",
                "実行エラー",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        }
    })

    # ダイアログ表示（常に前面に表示）
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({ $this.Activate(); $this.BringToFront() })
    $ダイアログ結果 = $フォーム.ShowDialog()

    Write-Host "[コード結果] ダイアログ結果: $ダイアログ結果" -ForegroundColor Gray
    Write-Host "[コード結果] ✅ ダイアログを閉じました" -ForegroundColor Green

    return @{
        success = $true
    }
}
