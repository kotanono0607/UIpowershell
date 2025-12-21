
# ImportExcelモジュールを使用したExcel操作関数
# 更新: 2025-12-21 - COMからImportExcelに移行

# ImportExcelモジュールの確認とインストール
function Ensure-ImportExcelModule {
    if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
        Write-Host "ImportExcelモジュールをインストールしています..."
        try {
            Install-Module -Name ImportExcel -Force -Scope CurrentUser -AllowClobber
            Write-Host "ImportExcelモジュールのインストールが完了しました。"
        }
        catch {
            Write-Host "ImportExcelモジュールのインストールに失敗しました: $_"
            Add-Type -AssemblyName System.Windows.Forms
            [System.Windows.Forms.MessageBox]::Show(
                "ImportExcelモジュールのインストールに失敗しました。`n管理者権限でPowerShellを実行し、以下のコマンドを実行してください:`n`nInstall-Module -Name ImportExcel -Force",
                "エラー",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            return $false
        }
    }
    Import-Module ImportExcel -ErrorAction SilentlyContinue
    return $true
}

# Excelファイルとシート名を選択し、パスとシート名を返す関数
function Excelファイルとシート名を選択 {
    param (
        [System.Windows.Forms.Form]$親フォーム = $null
    )

    # ImportExcelモジュールの確認
    if (-not (Ensure-ImportExcelModule)) {
        return $null
    }

    # 必要なアセンブリの読み込み
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # ファイル選択ダイアログの作成
    $ファイル選択ダイアログ = New-Object System.Windows.Forms.OpenFileDialog
    $ファイル選択ダイアログ.InitialDirectory = [Environment]::GetFolderPath('Desktop')
    $ファイル選択ダイアログ.Filter = "Excel Files (*.xlsx;*.xls)|*.xlsx;*.xls"
    $ファイル選択ダイアログ.Title = "Excelファイルを選択してください"

    # ファイル選択ダイアログを表示
    $メインメニューハンドル = メインメニューを最小化
    $選択結果 = $ファイル選択ダイアログ.ShowDialog($親フォーム)
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($選択結果 -ne [System.Windows.Forms.DialogResult]::OK) {
        Write-Host "ファイルの選択がキャンセルされました。"
        return $null
    }

    $Excelファイルパス = $ファイル選択ダイアログ.FileName
    Write-Host "選択されたExcelファイル: $Excelファイルパス"

    try {
        # ImportExcelでシート名一覧を取得
        $シート情報 = Get-ExcelSheetInfo -Path $Excelファイルパス
        $シート名一覧 = $シート情報 | ForEach-Object { $_.Name }
        Write-Host "取得したシート一覧: $($シート名一覧 -join ', ')"

        # シート選択用のフォームの作成
        $シート選択フォーム = New-Object System.Windows.Forms.Form
        $シート選択フォーム.Text = "シートを選択してください"
        $シート選択フォーム.Size = New-Object System.Drawing.Size(400, 150)
        $シート選択フォーム.StartPosition = "CenterScreen"
        $シート選択フォーム.FormBorderStyle = "FixedDialog"
        $シート選択フォーム.MaximizeBox = $false
        $シート選択フォーム.MinimizeBox = $false
        $シート選択フォーム.Topmost = $true

        # コンボボックスの作成
        $シートコンボボックス = New-Object System.Windows.Forms.ComboBox
        $シートコンボボックス.Location = New-Object System.Drawing.Point(20, 20)
        $シートコンボボックス.Size = New-Object System.Drawing.Size(340, 30)
        $シートコンボボックス.DropDownStyle = "DropDownList"
        $シートコンボボックス.Items.AddRange($シート名一覧)
        if ($シート名一覧.Count -gt 0) {
            $シートコンボボックス.SelectedIndex = 0
        }

        # OKボタンの作成
        $OKボタン = New-Object System.Windows.Forms.Button
        $OKボタン.Text = "OK"
        $OKボタン.Location = New-Object System.Drawing.Point(200, 70)
        $OKボタン.Size = New-Object System.Drawing.Size(75, 30)
        $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

        # キャンセルボタンの作成
        $キャンセルボタン = New-Object System.Windows.Forms.Button
        $キャンセルボタン.Text = "キャンセル"
        $キャンセルボタン.Location = New-Object System.Drawing.Point(285, 70)
        $キャンセルボタン.Size = New-Object System.Drawing.Size(75, 30)
        $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

        # フォームにコントロールを追加
        $シート選択フォーム.Controls.Add($シートコンボボックス)
        $シート選択フォーム.Controls.Add($OKボタン)
        $シート選択フォーム.Controls.Add($キャンセルボタン)

        # ダイアログとして表示
        $シート選択フォーム.AcceptButton = $OKボタン
        $シート選択フォーム.CancelButton = $キャンセルボタン

        $メインメニューハンドル2 = メインメニューを最小化
        $シート選択結果 = $シート選択フォーム.ShowDialog($親フォーム)
        メインメニューを復元 -ハンドル $メインメニューハンドル2

        if ($シート選択結果 -ne [System.Windows.Forms.DialogResult]::OK) {
            Write-Host "シートの選択がキャンセルされました。"
            return $null
        }

        $選択シート名 = $シートコンボボックス.SelectedItem
        Write-Host "選択されたシート: $選択シート名"

        # 結果をオブジェクトとして返す
        $結果オブジェクト = [PSCustomObject]@{
            Excelファイルパス = $Excelファイルパス
            シート名           = $選択シート名
        }

        return $結果オブジェクト
    }
    catch {
        Write-Host "エラーが発生しました: $_"
        return $null
    }
}


# Excelシートの内容を取得し、二次元配列（ジャグ配列）として返す関数
function Excelシートデータ取得 {
    param (
        [string]$Excelファイルパス,
        [string]$選択シート名
    )

    # ImportExcelモジュールの確認
    if (-not (Ensure-ImportExcelModule)) {
        return $null
    }

    # 入力パラメータの検証
    if (-not (Test-Path -Path $Excelファイルパス)) {
        Write-Host "指定されたファイルが存在しません: $Excelファイルパス"
        return $null
    }

    # 必要なアセンブリの読み込み
    Add-Type -AssemblyName System.Windows.Forms

    try {
        Write-Host "Excelファイルを読み込んでいます: $Excelファイルパス"

        # ImportExcelでデータを取得
        $データ = Import-Excel -Path $Excelファイルパス -WorksheetName $選択シート名

        if ($null -eq $データ -or $データ.Count -eq 0) {
            Write-Host "シートにデータがありません。"
            return $null
        }

        Write-Host "シート '$選択シート名' からデータを取得しました。行数: $($データ.Count)"

        # ヘッダー（プロパティ名）を取得
        $ヘッダー = $データ[0].PSObject.Properties.Name
        Write-Host "ヘッダー: $($ヘッダー -join ', ')"

        # ジャグ配列に変換（ヘッダー行を含む）
        $ジャグ配列 = @()

        # ヘッダー行を追加
        $ヘッダー行 = @()
        foreach ($列名 in $ヘッダー) {
            $ヘッダー行 += $列名
        }
        $ジャグ配列 += ,$ヘッダー行

        # データ行を追加
        foreach ($行 in $データ) {
            $行データ = @()
            foreach ($列名 in $ヘッダー) {
                $値 = $行.$列名
                if ($null -eq $値) { $値 = "" }
                $行データ += $値
            }
            $ジャグ配列 += ,$行データ
        }

        $最終行 = $ジャグ配列.Count
        Write-Host "ジャグ配列に変換完了。行数: $最終行"

        # デバッグ出力：配列構造の確認
        Write-Host "ジャグ配列の型: $($ジャグ配列.GetType().FullName)"
        if ($ジャグ配列.Count -gt 0) {
            Write-Host "ジャグ配列[0]の型: $($ジャグ配列[0].GetType().FullName)"
        }

        # 最終行の表示（メッセージボックス）
        [void][System.Windows.Forms.MessageBox]::Show(
            "シート '$選択シート名' の最終行は $最終行 行です。",
            "最終行の表示",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )

        # カンマ演算子でラップしてジャグ配列のアンロールを防止
        return ,$ジャグ配列
    }
    catch {
        Write-Host "エラーが発生しました: $_"
        return $null
    }
}

# ========================================
# Excel書き込み関数
# ========================================
function Excel書き込み {
    param(
        [Parameter(Mandatory=$true)]
        [array]$データ,
        [Parameter(Mandatory=$true)]
        [string]$出力パス,
        [string]$シート名 = "Sheet1"
    )

    # ImportExcelモジュールの確認
    Ensure-ImportExcelModule

    try {
        # 既存ファイルがあれば削除
        if (Test-Path $出力パス) {
            Remove-Item $出力パス -Force
        }

        # データをExcelに書き込み
        $excelPackage = $データ | ForEach-Object {
            $row = $_
            $obj = New-Object PSObject
            for ($i = 0; $i -lt $row.Count; $i++) {
                $colName = if ($i -lt $データ[0].Count) { $データ[0][$i] } else { "Col$i" }
                $obj | Add-Member -NotePropertyName $colName -NotePropertyValue $row[$i]
            }
            $obj
        } | Select-Object -Skip 1 | Export-Excel -Path $出力パス -WorksheetName $シート名 -AutoSize -PassThru

        $excelPackage.Save()
        $excelPackage.Dispose()

        Write-Host "Excelファイルを書き込みました: $出力パス" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Excel書き込みエラー: $_" -ForegroundColor Red
        return $false
    }
}

# ========================================
# セル値取得関数
# ========================================
function セル値取得 {
    param(
        [Parameter(Mandatory=$true)]
        [array]$データ,
        [Parameter(Mandatory=$true)]
        [int]$行番号,
        [Parameter(Mandatory=$true)]
        [int]$列番号
    )

    if ($行番号 -lt 0 -or $行番号 -ge $データ.Count) {
        throw "行番号が範囲外です。(0-$($データ.Count - 1))"
    }
    if ($列番号 -lt 0 -or $列番号 -ge $データ[$行番号].Count) {
        throw "列番号が範囲外です。(0-$($データ[$行番号].Count - 1))"
    }

    return $データ[$行番号][$列番号]
}

# ========================================
# 列名から列番号を取得
# ========================================
function 列番号取得 {
    param(
        [Parameter(Mandatory=$true)]
        [array]$データ,
        [Parameter(Mandatory=$true)]
        [string]$列名
    )

    $ヘッダー = $データ[0]
    for ($i = 0; $i -lt $ヘッダー.Count; $i++) {
        if ($ヘッダー[$i] -eq $列名) {
            return $i
        }
    }
    return -1
}

# ========================================
# 条件検索関数
# ========================================
function 条件検索 {
    param(
        [Parameter(Mandatory=$true)]
        [array]$データ,
        [Parameter(Mandatory=$true)]
        [string]$検索列名,
        [Parameter(Mandatory=$true)]
        [string]$検索値,
        [ValidateSet("完全一致", "部分一致", "前方一致", "後方一致")]
        [string]$一致方法 = "完全一致"
    )

    $列番号 = 列番号取得 -データ $データ -列名 $検索列名
    if ($列番号 -eq -1) {
        throw "列 '$検索列名' が見つかりません。"
    }

    $結果 = @()
    for ($行 = 1; $行 -lt $データ.Count; $行++) {
        $セル値 = $データ[$行][$列番号]
        if ($null -eq $セル値) { $セル値 = "" }
        $セル値 = $セル値.ToString()

        $一致 = $false
        switch ($一致方法) {
            "完全一致" { $一致 = ($セル値 -eq $検索値) }
            "部分一致" { $一致 = ($セル値 -like "*$検索値*") }
            "前方一致" { $一致 = ($セル値 -like "$検索値*") }
            "後方一致" { $一致 = ($セル値 -like "*$検索値") }
        }

        if ($一致) {
            $結果 += $行
        }
    }

    return $結果
}

# ========================================
# 列値一覧取得関数
# ========================================
function 列値一覧 {
    param(
        [Parameter(Mandatory=$true)]
        [array]$データ,
        [Parameter(Mandatory=$true)]
        [string]$列名,
        [switch]$ヘッダー除外 = $true,
        [switch]$重複除外 = $false
    )

    $列番号 = 列番号取得 -データ $データ -列名 $列名
    if ($列番号 -eq -1) {
        throw "列 '$列名' が見つかりません。"
    }

    $開始行 = if ($ヘッダー除外) { 1 } else { 0 }
    $値一覧 = @()

    for ($行 = $開始行; $行 -lt $データ.Count; $行++) {
        $値 = $データ[$行][$列番号]
        if ($null -eq $値) { $値 = "" }
        $値一覧 += $値.ToString()
    }

    if ($重複除外) {
        $値一覧 = $値一覧 | Select-Object -Unique
    }

    return $値一覧
}

# ========================================
# 行データ取得関数
# ========================================
function 行データ取得 {
    param(
        [Parameter(Mandatory=$true)]
        [array]$データ,
        [Parameter(Mandatory=$true)]
        [int]$行番号
    )

    if ($行番号 -lt 0 -or $行番号 -ge $データ.Count) {
        throw "行番号が範囲外です。(0-$($データ.Count - 1))"
    }

    return ,$データ[$行番号]
}

# ========================================
# セル更新関数
# ========================================
function セル更新 {
    param(
        [Parameter(Mandatory=$true)]
        [array]$データ,
        [Parameter(Mandatory=$true)]
        [int]$行番号,
        [Parameter(Mandatory=$true)]
        [int]$列番号,
        [Parameter(Mandatory=$true)]
        $新しい値
    )

    if ($行番号 -lt 0 -or $行番号 -ge $データ.Count) {
        throw "行番号が範囲外です。(0-$($データ.Count - 1))"
    }
    if ($列番号 -lt 0 -or $列番号 -ge $データ[$行番号].Count) {
        throw "列番号が範囲外です。(0-$($データ[$行番号].Count - 1))"
    }

    $データ[$行番号][$列番号] = $新しい値
    return ,$データ
}

# ========================================
# 列名でセル更新関数
# ========================================
function 列名でセル更新 {
    param(
        [Parameter(Mandatory=$true)]
        [array]$データ,
        [Parameter(Mandatory=$true)]
        [int]$行番号,
        [Parameter(Mandatory=$true)]
        [string]$列名,
        [Parameter(Mandatory=$true)]
        $新しい値
    )

    $列番号 = 列番号取得 -データ $データ -列名 $列名
    if ($列番号 -eq -1) {
        throw "列 '$列名' が見つかりません。"
    }

    return セル更新 -データ $データ -行番号 $行番号 -列番号 $列番号 -新しい値 $新しい値
}

# ========================================
# 行追加関数
# ========================================
function 行追加 {
    param(
        [Parameter(Mandatory=$true)]
        [array]$データ,
        [Parameter(Mandatory=$false)]
        [array]$新しい行 = $null
    )

    # 新しい行が指定されていない場合、空行を作成
    if ($null -eq $新しい行) {
        $列数 = $データ[0].Count
        $新しい行 = @("") * $列数
    }

    # 配列に行を追加
    $データ += ,$新しい行
    return ,$データ
}

# ========================================
# データ件数取得関数
# ========================================
function データ件数 {
    param(
        [Parameter(Mandatory=$true)]
        [array]$データ,
        [switch]$ヘッダー除外 = $true
    )

    $件数 = $データ.Count
    if ($ヘッダー除外) {
        $件数 = $件数 - 1
    }
    return $件数
}

# ========================================
# 列名でセル値取得関数
# ========================================
function 列名セル取得 {
    param(
        [Parameter(Mandatory=$true)]
        [array]$データ,
        [Parameter(Mandatory=$true)]
        [int]$行番号,
        [Parameter(Mandatory=$true)]
        [string]$列名
    )

    $列番号 = 列番号取得 -データ $データ -列名 $列名
    if ($列番号 -eq -1) {
        throw "列 '$列名' が見つかりません。"
    }

    return セル値取得 -データ $データ -行番号 $行番号 -列番号 $列番号
}