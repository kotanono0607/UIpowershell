
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

        # 最終行の表示（メッセージボックス）
        [void][System.Windows.Forms.MessageBox]::Show(
            "シート '$選択シート名' の最終行は $最終行 行です。",
            "最終行の表示",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )

        return $ジャグ配列
    }
    catch {
        Write-Host "エラーが発生しました: $_"
        return $null
    }
}