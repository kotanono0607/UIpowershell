
# Excelファイルとシート名を選択し、パスとシート名を返す関数
function Excelファイルとシート名を選択 {
    param (
        [System.Windows.Forms.Form]$親フォーム = $null
    )

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
        # Excelアプリケーションの起動
        $Excelアプリ = New-Object -ComObject Excel.Application
        $Excelアプリ.Visible = $false
        $Excelアプリ.DisplayAlerts = $false

        # Excelファイルのオープン
        $ブック = $Excelアプリ.Workbooks.Open($Excelファイルパス)
        Write-Host "Excelファイルを開きました。"

        # シート名の取得
        $シート名一覧 = @()
        foreach ($シート in $ブック.Sheets) {
            $シート名一覧 += $シート.Name
        }
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
            $ブック.Close($false)
            $Excelアプリ.Quit()
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ブック) | Out-Null
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excelアプリ) | Out-Null
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
    finally {
        if ($ブック) {
            $ブック.Close($false)
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ブック) | Out-Null
        }
        if ($Excelアプリ) {
            $Excelアプリ.Quit()
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excelアプリ) | Out-Null
        }
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}


# Excelシートの内容を取得し、二次元配列（ジャグ配列）として返す関数
function Excelシートデータ取得 {
    param (
        [string]$Excelファイルパス,
        [string]$選択シート名
    )

    # 入力パラメータの検証
    if (-not (Test-Path -Path $Excelファイルパス)) {
        Write-Host "指定されたファイルが存在しません: $Excelファイルパス"
        return $null
    }

    # 必要なアセンブリの読み込み（メッセージボックス表示のため）
    Add-Type -AssemblyName System.Windows.Forms

    # Excelアプリケーションの起動
    try {
        $Excelアプリ = New-Object -ComObject Excel.Application
        $Excelアプリ.Visible = $false
        $Excelアプリ.DisplayAlerts = $false

        # Excelファイルのオープン
        $ブック = $Excelアプリ.Workbooks.Open($Excelファイルパス)
        Write-Host "Excelファイルを開きました: $Excelファイルパス"

        # シートの取得
        $選択シート = $ブック.Sheets.Item($選択シート名)
        if (-not $選択シート) {
            Write-Host "指定されたシートが見つかりません: $選択シート名"
            throw "シートが見つかりません"
        }
        Write-Host "シート '$選択シート名' を取得しました。"

        # 最終行の取得
        $最終行 = $選択シート.Cells.Find("*", [Type]::Missing, [Type]::Missing, [Type]::Missing, `
            [Microsoft.Office.Interop.Excel.XlSearchOrder]::xlByRows, `
            [Microsoft.Office.Interop.Excel.XlSearchDirection]::xlPrevious, `
            $false).Row
        Write-Host "シート '$選択シート名' の最終行は $最終行 行です。"

        # シートの内容を取得して二次元配列に格納
        $使用範囲 = $選択シート.UsedRange
        if ($使用範囲 -eq $null) {
            Write-Host "シートにデータがありません。"
            return $null
        }

        $データ配列 = $使用範囲.Value2

        # デバッグ: データ配列の型とランクを確認
        Write-Host "データ配列の型: $($データ配列.GetType())"
        Write-Host "データ配列のランク: $($データ配列.Rank)"

        # `UsedRange.Value2` は既に多次元配列（2次元配列）として返されるため、ジャグ配列に変換
        if ($データ配列 -is [System.Array] -and $データ配列.Rank -ge 2) {
            Write-Host "二次元配列としてデータを取得しました。"

            # 多次元配列（object[,]）をジャグ配列（object[][]）に変換
            $行数 = $データ配列.GetLength(0)
            $列数 = $データ配列.GetLength(1)
            $ジャグ配列 = @()

            for ($i = 1; $i -le $行数; $i++) {
                $行 = @()
                for ($j = 1; $j -le $列数; $j++) {
                    $セル値 = $データ配列[$i, $j]
                    if ($セル値 -eq $null) { $セル値 = "" }
                    $行 += $セル値
                }
                $ジャグ配列 += ,$行
            }

            # デバッグ: ジャグ配列の型と要素数を確認
            Write-Host "ジャグ配列の型: $($ジャグ配列.GetType())"  # Should be System.Object[][]
            Write-Host "ジャグ配列の要素数: $($ジャグ配列.Count)"
            if ($ジャグ配列.Count -gt 0) {
                Write-Host "最初の行の型: $($ジャグ配列[0].GetType())" # Should be System.Object[]
            }

            # 最終行の表示（メッセージボックス）の出力を抑制
            [void][System.Windows.Forms.MessageBox]::Show("シート '$選択シート名' の最終行は $最終行 行です。", `
                "最終行の表示", `
                [System.Windows.Forms.MessageBoxButtons]::OK, `
                [System.Windows.Forms.MessageBoxIcon]::Information)

            # ジャグ配列を返り値として返す
            return $ジャグ配列
        }
        else {
            Write-Host "取得したデータが二次元配列ではありません。"
            throw "二次元配列の値は二次元の配列である必要があります。"
        }
    }
    catch {
        Write-Host "エラーが発生しました: $_"
        return $null
    }
    finally {
        if ($ブック) {
            $ブック.Close($false)
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ブック) | Out-Null
        }
        if ($Excelアプリ) {
            $Excelアプリ.Quit()
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excelアプリ) | Out-Null
        }
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}

