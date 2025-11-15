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

    # フォームの表示
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

    # フォームの表示
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
