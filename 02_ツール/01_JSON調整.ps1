# RPA UI2 ボタン設定編集ツール UI付き Ver1.4.1 (DATA TABLE + DefaultView 版)
# このスクリプトは STA モードで実行してください。（例：powershell.exe -STA）

# 0. STAモードチェック
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne "STA") {
    Write-Error "このスクリプトは STA モードで実行してください。"
    exit
}
Write-Host "DEBUG: STAモードで実行中"

# 1. 必要なアセンブリの読み込み
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Write-Host "DEBUG: アセンブリ読み込み完了"

# 2. JSONファイルパス設定（スクリプトの親ディレクトリから相対パス）
$スクリプトの親ディレクトリ = Split-Path -Parent $PSScriptRoot
$ファイルパス = Join-Path $スクリプトの親ディレクトリ "ボタン設定.json"
Write-Host "DEBUG: JSONファイルパス設定 => $ファイルパス"

# ============================================================
# PSCustomObject の配列を DataTable に変換する関数
# ============================================================
function ConvertTo-DataTable {
    param (
        [Parameter(Mandatory)]
        [System.Collections.IEnumerable] $Objects
    )
    # 新規 DataTable 作成
    $dt = New-Object System.Data.DataTable

    # 配列が空なら空の DataTable を返す
    if ($Objects.Count -eq 0) {
        return $dt
    }

    # 最初のオブジェクトのプロパティを列定義として追加
    $first = $Objects | Select-Object -First 1
    foreach ($prop in $first.psobject.Properties) {
        $column = New-Object System.Data.DataColumn ($prop.Name, [System.String])
        $dt.Columns.Add($column) | Out-Null
    }

    # 各オブジェクトの値を行として追加
    foreach ($obj in $Objects) {
        $row = $dt.NewRow()
        foreach ($prop in $obj.psobject.Properties) {
            $row[$prop.Name] = $prop.Value
        }
        $dt.Rows.Add($row)
    }

    return $dt
}

# ============================================================
# 3. グリッド更新関数（JSON読み込み → DataTable変換 → DataGridViewにバインド）
# ============================================================
function 更新_グリッド {
    Write-Host "DEBUG: 更新_グリッド 開始"

    # 3-1. JSONファイルが存在しなければ空配列で新規作成
    if (-not (Test-Path $ファイルパス)) {
        Write-Host "DEBUG: JSONファイルが存在しません。新規作成します。"
        @() | ConvertTo-Json | Out-File $ファイルパス -Encoding UTF8
    }

    # 3-2. JSONを読み込む (UTF-8 前提。Shift-JISの場合は -Encoding Default に変更可能)
    try {
        $jsonRaw = Get-Content $ファイルパス -Raw -Encoding UTF8
    }
    catch {
        Write-Host "DEBUG: JSON読み込みエラー（UTF8）：$_"
        $jsonRaw = Get-Content $ファイルパス -Raw -Encoding Default
    }
    Write-Host "DEBUG: 読み込んだJSON => $jsonRaw"

    # 3-3. JSONをオブジェクトに変換
    $データ = $null
    try {
        $データ = $jsonRaw | ConvertFrom-Json
    }
    catch {
        Write-Host "DEBUG: JSONパースエラー: $_"
        $データ = @()
    }

    # 3-4. 単一オブジェクトの場合は配列化
    if ($データ -and -not ($データ -is [System.Collections.IEnumerable])) {
        Write-Host "DEBUG: JSONが単一オブジェクトのため配列化します。"
        $データ = @($データ)
    }

    # 3-5. 空または null の場合は空配列に置き換え
    if (-not $データ) {
        Write-Host "DEBUG: JSON内容が空です。空配列に設定します。"
        $データ = @()
    }

    Write-Host "DEBUG: JSONデータ件数 => $($データ.Count)"

    # 3-6. DataTableに変換し、DefaultView で DataGridView にバインド
    $dt = ConvertTo-DataTable -Objects $データ
    $DataGridView.DataSource = $dt.DefaultView
    $DataGridView.Refresh()

    Write-Host "DEBUG: 更新_グリッド 完了"
}

# ============================================================
# 4. 新規作成処理
# ============================================================
function 新規作成_実行 {
    Write-Host "DEBUG: 新規作成_実行 開始"
    [System.Windows.Forms.MessageBox]::Show("新規作成実行開始")

    $新規レコード = [PSCustomObject]@{
        処理番号 = $テキストBox_処理番号.Text
        テキスト   = $テキストBox_テキスト.Text
        ボタン名   = $テキストBox_ボタン名.Text
        背景色     = $テキストBox_背景色.Text
        コンテナ   = $テキストBox_コンテナ.Text
        説明       = $テキストBox_説明.Text
        関数名     = $テキストBox_関数名.Text
    }
    Write-Host "DEBUG: 新規レコード作成 => $($新規レコード | Out-String)"

    # JSONを配列として読み込み
    $データ = Get-Content $ファイルパス -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $データ) {
        Write-Host "DEBUG: JSONファイル内が空です。新規配列を作成します。"
        $データ = @()
    }

    $データ += $新規レコード
    $データ | ConvertTo-Json -Depth 5 | Set-Content $ファイルパス -Encoding UTF8
    Write-Host "DEBUG: 新規レコードを書き込み完了"

    更新_グリッド
    Write-Host "DEBUG: 新規作成_実行 完了"
}

# ============================================================
# 5. 編集処理
# ============================================================
function 編集_実行 {
    Write-Host "DEBUG: 編集_実行 開始"
    [System.Windows.Forms.MessageBox]::Show("編集実行開始")

    $処理番号 = $テキストBox_処理番号.Text
    Write-Host "DEBUG: 編集対象の処理番号 => $処理番号"

    $データ = Get-Content $ファイルパス -Raw -Encoding UTF8 | ConvertFrom-Json
    $更新済み = $false

    for ($i = 0; $i -lt $データ.Count; $i++) {
        Write-Host "DEBUG: チェック中の処理番号 => $($データ[$i].処理番号)"
        if ($データ[$i].処理番号 -eq $処理番号) {
            $データ[$i].テキスト   = $テキストBox_テキスト.Text
            $データ[$i].ボタン名   = $テキストBox_ボタン名.Text
            $データ[$i].背景色     = $テキストBox_背景色.Text
            $データ[$i].コンテナ   = $テキストBox_コンテナ.Text
            $データ[$i].説明       = $テキストBox_説明.Text
            $データ[$i].関数名     = $テキストBox_関数名.Text
            Write-Host "DEBUG: 編集対象が見つかりました。レコード更新完了"
            $更新済み = $true
            break
        }
    }

    if (-not $更新済み) {
        Write-Host "DEBUG: 編集対象の処理番号が見つかりません"
        [System.Windows.Forms.MessageBox]::Show("該当する処理番号が見つかりません。")
        return
    }

    $データ | ConvertTo-Json -Depth 5 | Set-Content $ファイルパス -Encoding UTF8
    Write-Host "DEBUG: 編集したデータを書き込み完了"

    更新_グリッド
    Write-Host "DEBUG: 編集_実行 完了"
}

# ============================================================
# 6. 削除処理
# ============================================================
function 削除_実行 {
    Write-Host "DEBUG: 削除_実行 開始"
    [System.Windows.Forms.MessageBox]::Show("削除実行開始")

    $処理番号 = $テキストBox_処理番号.Text
    Write-Host "DEBUG: 削除対象の処理番号 => $処理番号"

    $データ  = Get-Content $ファイルパス -Raw -Encoding UTF8 | ConvertFrom-Json
    $元件数  = $データ.Count
    Write-Host "DEBUG: 削除前の件数 => $元件数"

    $データ = $データ | Where-Object { $_.処理番号 -ne $処理番号 }

    if ($元件数 -eq $データ.Count) {
        Write-Host "DEBUG: 削除対象のレコードが見つかりません"
        [System.Windows.Forms.MessageBox]::Show("該当する処理番号が見つかりません。")
        return
    }

    Write-Host "DEBUG: 削除後の件数 => $($データ.Count)"
    $データ | ConvertTo-Json -Depth 5 | Set-Content $ファイルパス -Encoding UTF8

    更新_グリッド
    Write-Host "DEBUG: 削除_実行 完了"
}

# ============================================================
# 7. フォーム作成
# ============================================================
$form = New-Object System.Windows.Forms.Form
$form.Text          = "ボタン設定編集ツール UI付き"
$form.Size          = New-Object System.Drawing.Size(800,600)
$form.StartPosition = "CenterScreen"
Write-Host "DEBUG: フォーム作成完了"

# ============================================================
# 8. DataGridView作成【表示領域：10,10 ～ 760,250】
# ============================================================
$DataGridView = New-Object System.Windows.Forms.DataGridView
$DataGridView.Location            = New-Object System.Drawing.Point(10,10)
$DataGridView.Size                = New-Object System.Drawing.Size(760,250)
$DataGridView.ReadOnly            = $true
$DataGridView.SelectionMode       = "FullRowSelect"

# ■ 列ヘッダーを確実に表示するためのプロパティ設定 ■
$DataGridView.ColumnHeadersVisible = $true
$DataGridView.AutoSizeColumnsMode  = 'Fill'
$DataGridView.AutoGenerateColumns  = $true
$DataGridView.BackgroundColor      = [System.Drawing.Color]::White

$form.Controls.Add($DataGridView)
Write-Host "DEBUG: DataGridView作成完了"

# ============================================================
# 9. 入力用ラベル・テキストボックス作成（位置：Y軸270～）
# ============================================================
$ラベルX        = 10
$テキストBoxX   = 100
$初期Y          = 270
$間隔Y          = 30

$位置_処理番号_Y         = $初期Y
$位置_テキストラベル_Y     = $初期Y + $間隔Y
$位置_テキストBoxテキスト_Y = $初期Y + $間隔Y
$位置_ボタン名ラベル_Y     = $初期Y + (2 * $間隔Y)
$位置_テキストBoxボタン名_Y = $初期Y + (2 * $間隔Y)
$位置_背景色ラベル_Y       = $初期Y + (3 * $間隔Y)
$位置_テキストBox背景色_Y   = $初期Y + (3 * $間隔Y)
$位置_コンテナラベル_Y     = $初期Y + (4 * $間隔Y)
$位置_テキストBoxコンテナ_Y = $初期Y + (4 * $間隔Y)
$位置_説明ラベル_Y         = $初期Y + (5 * $間隔Y)
$位置_テキストBox説明_Y     = $初期Y + (5 * $間隔Y)
$位置_関数名ラベル_Y       = $初期Y + (6 * $間隔Y)
$位置_テキストBox関数名_Y   = $初期Y + (6 * $間隔Y)
Write-Host "DEBUG: 入力用コントロールの位置計算完了"

# 9-1. 処理番号ラベル・テキストボックス
$ラベル_処理番号 = New-Object System.Windows.Forms.Label
$ラベル_処理番号.Location = New-Object System.Drawing.Point($ラベルX, $位置_処理番号_Y)
$ラベル_処理番号.Size     = New-Object System.Drawing.Size(80,20)
$ラベル_処理番号.Text     = "処理番号"
$form.Controls.Add($ラベル_処理番号)

$テキストBox_処理番号 = New-Object System.Windows.Forms.TextBox
$テキストBox_処理番号.Location = New-Object System.Drawing.Point($テキストBoxX, $位置_処理番号_Y)
$テキストBox_処理番号.Size     = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($テキストBox_処理番号)

# 9-2. テキストラベル・テキストボックス
$ラベル_テキスト = New-Object System.Windows.Forms.Label
$ラベル_テキスト.Location = New-Object System.Drawing.Point($ラベルX, $位置_テキストラベル_Y)
$ラベル_テキスト.Size     = New-Object System.Drawing.Size(80,20)
$ラベル_テキスト.Text     = "テキスト"
$form.Controls.Add($ラベル_テキスト)

$テキストBox_テキスト = New-Object System.Windows.Forms.TextBox
$テキストBox_テキスト.Location = New-Object System.Drawing.Point($テキストBoxX, $位置_テキストBoxテキスト_Y)
$テキストBox_テキスト.Size     = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($テキストBox_テキスト)

# 9-3. ボタン名ラベル・テキストボックス
$ラベル_ボタン名 = New-Object System.Windows.Forms.Label
$ラベル_ボタン名.Location = New-Object System.Drawing.Point($ラベルX, $位置_ボタン名ラベル_Y)
$ラベル_ボタン名.Size     = New-Object System.Drawing.Size(80,20)
$ラベル_ボタン名.Text     = "ボタン名"
$form.Controls.Add($ラベル_ボタン名)

$テキストBox_ボタン名 = New-Object System.Windows.Forms.TextBox
$テキストBox_ボタン名.Location = New-Object System.Drawing.Point($テキストBoxX, $位置_テキストBoxボタン名_Y)
$テキストBox_ボタン名.Size     = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($テキストBox_ボタン名)

# 9-4. 背景色ラベル・テキストボックス
$ラベル_背景色 = New-Object System.Windows.Forms.Label
$ラベル_背景色.Location = New-Object System.Drawing.Point($ラベルX, $位置_背景色ラベル_Y)
$ラベル_背景色.Size     = New-Object System.Drawing.Size(80,20)
$ラベル_背景色.Text     = "背景色"
$form.Controls.Add($ラベル_背景色)

$テキストBox_背景色 = New-Object System.Windows.Forms.TextBox
$テキストBox_背景色.Location = New-Object System.Drawing.Point($テキストBoxX, $位置_テキストBox背景色_Y)
$テキストBox_背景色.Size     = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($テキストBox_背景色)

# 9-5. コンテナラベル・テキストボックス
$ラベル_コンテナ = New-Object System.Windows.Forms.Label
$ラベル_コンテナ.Location = New-Object System.Drawing.Point($ラベルX, $位置_コンテナラベル_Y)
$ラベル_コンテナ.Size     = New-Object System.Drawing.Size(80,20)
$ラベル_コンテナ.Text     = "コンテナ"
$form.Controls.Add($ラベル_コンテナ)

$テキストBox_コンテナ = New-Object System.Windows.Forms.TextBox
$テキストBox_コンテナ.Location = New-Object System.Drawing.Point($テキストBoxX, $位置_テキストBoxコンテナ_Y)
$テキストBox_コンテナ.Size     = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($テキストBox_コンテナ)

# 9-6. 説明ラベル・テキストボックス
$ラベル_説明 = New-Object System.Windows.Forms.Label
$ラベル_説明.Location = New-Object System.Drawing.Point($ラベルX, $位置_説明ラベル_Y)
$ラベル_説明.Size     = New-Object System.Drawing.Size(80,20)
$ラベル_説明.Text     = "説明"
$form.Controls.Add($ラベル_説明)

$テキストBox_説明 = New-Object System.Windows.Forms.TextBox
$テキストBox_説明.Location = New-Object System.Drawing.Point($テキストBoxX, $位置_テキストBox説明_Y)
$テキストBox_説明.Size     = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($テキストBox_説明)

# 9-7. 関数名ラベル・テキストボックス
$ラベル_関数名 = New-Object System.Windows.Forms.Label
$ラベル_関数名.Location = New-Object System.Drawing.Point($ラベルX, $位置_関数名ラベル_Y)
$ラベル_関数名.Size     = New-Object System.Drawing.Size(80,20)
$ラベル_関数名.Text     = "関数名"
$form.Controls.Add($ラベル_関数名)

$テキストBox_関数名 = New-Object System.Windows.Forms.TextBox
$テキストBox_関数名.Location = New-Object System.Drawing.Point($テキストBoxX, $位置_テキストBox関数名_Y)
$テキストBox_関数名.Size     = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($テキストBox_関数名)

Write-Host "DEBUG: 入力コントロール作成完了"

# ============================================================
# 10. 操作用ボタン作成
# ============================================================
# 10-1. 新規作成ボタン
$ボタン_新規 = New-Object System.Windows.Forms.Button
$ボタン_新規.Location = New-Object System.Drawing.Point(350, $位置_ボタン新規_Y)
$ボタン_新規.Size     = New-Object System.Drawing.Size(100,30)
$ボタン_新規.Text     = "新規作成"
$ボタン_新規.Add_Click({
    Write-Host "DEBUG: 新規作成ボタンクリック"
    新規作成_実行
})
$form.Controls.Add($ボタン_新規)

# 10-2. 編集ボタン
$ボタン_編集 = New-Object System.Windows.Forms.Button
$ボタン_編集.Location = New-Object System.Drawing.Point(350, $位置_ボタン編集_Y)
$ボタン_編集.Size     = New-Object System.Drawing.Size(100,30)
$ボタン_編集.Text     = "編集"
$ボタン_編集.Add_Click({
    Write-Host "DEBUG: 編集ボタンクリック"
    編集_実行
})
$form.Controls.Add($ボタン_編集)

# 10-3. 削除ボタン
$ボタン_削除 = New-Object System.Windows.Forms.Button
$ボタン_削除.Location = New-Object System.Drawing.Point(350, $位置_ボタン削除_Y)
$ボタン_削除.Size     = New-Object System.Drawing.Size(100,30)
$ボタン_削除.Text     = "削除"
$ボタン_削除.Add_Click({
    Write-Host "DEBUG: 削除ボタンクリック"
    削除_実行
})
$form.Controls.Add($ボタン_削除)

# 10-4. リロードボタン
$ボタン_リロード = New-Object System.Windows.Forms.Button
$ボタン_リロード.Location = New-Object System.Drawing.Point(350, $位置_ボタンリロード_Y)
$ボタン_リロード.Size     = New-Object System.Drawing.Size(100,30)
$ボタン_リロード.Text     = "リロード"
$ボタン_リロード.Add_Click({
    Write-Host "DEBUG: リロードボタンクリック"
    更新_グリッド
})
$form.Controls.Add($ボタン_リロード)

Write-Host "DEBUG: 操作用ボタン作成完了"

# ============================================================
# 11. DataGridView行選択時にテキストボックスへ値を反映
# ============================================================
$DataGridView.Add_SelectionChanged({
    Write-Host "DEBUG: DataGridView行選択変更イベント発生"
    if ($DataGridView.SelectedRows.Count -gt 0) {
        # DataSource を DataTable.DefaultView にしているので、
        # SelectedRows[0].DataBoundItem は DataRowView になる
        $rowView = $DataGridView.SelectedRows[0].DataBoundItem
        if ($rowView) {
            $テキストBox_処理番号.Text = $rowView["処理番号"]
            $テキストBox_テキスト.Text   = $rowView["テキスト"]
            $テキストBox_ボタン名.Text   = $rowView["ボタン名"]
            $テキストBox_背景色.Text     = $rowView["背景色"]
            $テキストBox_コンテナ.Text   = $rowView["コンテナ"]
            $テキストBox_説明.Text       = $rowView["説明"]
            $テキストBox_関数名.Text     = $rowView["関数名"]
        }
    }
})

# ============================================================
# 12. フォーム表示後に初期バインド
# ============================================================
$form.Add_Shown({
    Write-Host "DEBUG: フォーム表示後 Add_Shown イベント発生"
    更新_グリッド
})

# ============================================================
# 13. 初期グリッド更新＆フォーム表示
# ============================================================
Write-Host "DEBUG: 初期グリッド更新実行"
更新_グリッド

Write-Host "DEBUG: フォーム表示開始"
[System.Windows.Forms.Application]::Run($form)
