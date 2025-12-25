# ImportExcelモジュールを使用したExcel直接操作関数
# 更新: 2025-12-22 - セル単位の操作機能を提供

# ========================================
# 列番号 → 列文字変換関数
# ========================================
function 列番号を列文字に変換 {
    param(
        [Parameter(Mandatory=$true)]
        [int]$列番号
    )

    $result = ""
    while ($列番号 -gt 0) {
        $列番号--
        $result = [char](($列番号 % 26) + [int][char]'A') + $result
        $列番号 = [math]::Floor($列番号 / 26)
    }
    return $result
}

# ========================================
# 列文字 → 列番号変換関数
# ========================================
function 列文字を列番号に変換 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$列文字
    )

    $result = 0
    $列文字 = $列文字.ToUpper()
    for ($i = 0; $i -lt $列文字.Length; $i++) {
        $result = $result * 26 + ([int][char]$列文字[$i] - [int][char]'A' + 1)
    }
    return $result
}

# ========================================
# セルアドレス生成関数（列番号・行番号からA1形式を生成）
# ========================================
function セルアドレス生成 {
    param(
        [Parameter(Mandatory=$true)]
        [int]$列番号,
        [Parameter(Mandatory=$true)]
        [int]$行番号
    )

    $列文字 = 列番号を列文字に変換 -列番号 $列番号
    return "$列文字$行番号"
}

# ========================================
# セル値取得関数（列番号・行番号指定）
# ========================================
function Excel操作_セル値取得_行列 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイルパス,
        [Parameter(Mandatory=$true)]
        [int]$列番号,
        [Parameter(Mandatory=$true)]
        [int]$行番号,
        [string]$シート名 = ""
    )

    $セルアドレス = セルアドレス生成 -列番号 $列番号 -行番号 $行番号
    return Excel操作_セル値取得 -ファイルパス $ファイルパス -セルアドレス $セルアドレス -シート名 $シート名
}

# ========================================
# セル値設定関数（列番号・行番号指定）
# ========================================
function Excel操作_セル値設定_行列 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイルパス,
        [Parameter(Mandatory=$true)]
        [int]$列番号,
        [Parameter(Mandatory=$true)]
        [int]$行番号,
        [Parameter(Mandatory=$true)]
        $値,
        [string]$シート名 = ""
    )

    $セルアドレス = セルアドレス生成 -列番号 $列番号 -行番号 $行番号
    return Excel操作_セル値設定 -ファイルパス $ファイルパス -セルアドレス $セルアドレス -値 $値 -シート名 $シート名
}

# ========================================
# セル値取得関数（ファイルから直接）
# ========================================
function Excel操作_セル値取得 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイルパス,
        [Parameter(Mandatory=$true)]
        [string]$セルアドレス,
        [string]$シート名 = ""
    )

    # ImportExcelモジュールの確認
    if (-not (Ensure-ImportExcelModule)) {
        throw "ImportExcelモジュールが利用できません"
    }

    if (-not (Test-Path $ファイルパス)) {
        throw "ファイルが存在しません: $ファイルパス"
    }

    try {
        $excelPackage = Open-ExcelPackage -Path $ファイルパス

        # シート取得
        if ([string]::IsNullOrEmpty($シート名)) {
            $worksheet = $excelPackage.Workbook.Worksheets[1]
        } else {
            $worksheet = $excelPackage.Workbook.Worksheets[$シート名]
        }

        if ($null -eq $worksheet) {
            throw "シートが見つかりません: $シート名"
        }

        $値 = $worksheet.Cells[$セルアドレス].Value
        Close-ExcelPackage $excelPackage -NoSave

        return $値
    }
    catch {
        throw "セル値取得エラー: $_"
    }
}

# ========================================
# セル値設定関数（ファイルに直接書き込み）
# ========================================
function Excel操作_セル値設定 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイルパス,
        [Parameter(Mandatory=$true)]
        [string]$セルアドレス,
        [Parameter(Mandatory=$true)]
        $値,
        [string]$シート名 = ""
    )

    # ImportExcelモジュールの確認
    if (-not (Ensure-ImportExcelModule)) {
        throw "ImportExcelモジュールが利用できません"
    }

    # ファイルが存在しない場合は新規作成
    if (-not (Test-Path $ファイルパス)) {
        # 空のExcelファイルを作成
        $newData = [PSCustomObject]@{ Dummy = "" }
        $newData | Export-Excel -Path $ファイルパス -WorksheetName "Sheet1"
        # ダミーデータをクリア
        $pkg = Open-ExcelPackage -Path $ファイルパス
        $pkg.Workbook.Worksheets[1].Cells["A1"].Value = $null
        $pkg.Workbook.Worksheets[1].DeleteRow(1)
        Close-ExcelPackage $pkg
    }

    try {
        $excelPackage = Open-ExcelPackage -Path $ファイルパス

        # シート取得
        if ([string]::IsNullOrEmpty($シート名)) {
            $worksheet = $excelPackage.Workbook.Worksheets[1]
        } else {
            $worksheet = $excelPackage.Workbook.Worksheets[$シート名]
            if ($null -eq $worksheet) {
                # シートが存在しない場合は作成
                $worksheet = $excelPackage.Workbook.Worksheets.Add($シート名)
            }
        }

        $worksheet.Cells[$セルアドレス].Value = $値
        Close-ExcelPackage $excelPackage

        Write-Host "セル $セルアドレス に値を設定しました: $値" -ForegroundColor Green
        return $true
    }
    catch {
        throw "セル値設定エラー: $_"
    }
}

# ========================================
# 背景色設定関数
# ========================================
function Excel操作_背景色設定 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイルパス,
        [Parameter(Mandatory=$true)]
        [string]$セル範囲,
        [Parameter(Mandatory=$true)]
        [string]$色,
        [string]$シート名 = ""
    )

    if (-not (Ensure-ImportExcelModule)) {
        throw "ImportExcelモジュールが利用できません"
    }

    if (-not (Test-Path $ファイルパス)) {
        throw "ファイルが存在しません: $ファイルパス"
    }

    try {
        $excelPackage = Open-ExcelPackage -Path $ファイルパス

        if ([string]::IsNullOrEmpty($シート名)) {
            $worksheet = $excelPackage.Workbook.Worksheets[1]
        } else {
            $worksheet = $excelPackage.Workbook.Worksheets[$シート名]
        }

        if ($null -eq $worksheet) {
            throw "シートが見つかりません: $シート名"
        }

        # 色をSystem.Drawing.Colorに変換
        $colorValue = [System.Drawing.Color]::FromName($色)
        if ($colorValue.IsEmpty -or $colorValue.A -eq 0) {
            # 名前で見つからない場合、HTMLカラーコードとして解釈
            if ($色 -match "^#[0-9A-Fa-f]{6}$") {
                $colorValue = [System.Drawing.ColorTranslator]::FromHtml($色)
            } else {
                $colorValue = [System.Drawing.Color]::Yellow  # デフォルト
            }
        }

        $worksheet.Cells[$セル範囲].Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
        $worksheet.Cells[$セル範囲].Style.Fill.BackgroundColor.SetColor($colorValue)

        Close-ExcelPackage $excelPackage

        Write-Host "セル $セル範囲 の背景色を $色 に設定しました" -ForegroundColor Green
        return $true
    }
    catch {
        throw "背景色設定エラー: $_"
    }
}

# ========================================
# フォント設定関数
# ========================================
function Excel操作_フォント設定 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイルパス,
        [Parameter(Mandatory=$true)]
        [string]$セル範囲,
        [string]$シート名 = "",
        [string]$フォント色 = "",
        [switch]$太字,
        [switch]$斜体,
        [int]$サイズ = 0
    )

    if (-not (Ensure-ImportExcelModule)) {
        throw "ImportExcelモジュールが利用できません"
    }

    if (-not (Test-Path $ファイルパス)) {
        throw "ファイルが存在しません: $ファイルパス"
    }

    try {
        $excelPackage = Open-ExcelPackage -Path $ファイルパス

        if ([string]::IsNullOrEmpty($シート名)) {
            $worksheet = $excelPackage.Workbook.Worksheets[1]
        } else {
            $worksheet = $excelPackage.Workbook.Worksheets[$シート名]
        }

        if ($null -eq $worksheet) {
            throw "シートが見つかりません: $シート名"
        }

        $cells = $worksheet.Cells[$セル範囲]

        if (-not [string]::IsNullOrEmpty($フォント色)) {
            $colorValue = [System.Drawing.Color]::FromName($フォント色)
            if ($colorValue.IsEmpty -or $colorValue.A -eq 0) {
                if ($フォント色 -match "^#[0-9A-Fa-f]{6}$") {
                    $colorValue = [System.Drawing.ColorTranslator]::FromHtml($フォント色)
                }
            }
            if (-not $colorValue.IsEmpty) {
                $cells.Style.Font.Color.SetColor($colorValue)
            }
        }

        if ($太字) {
            $cells.Style.Font.Bold = $true
        }

        if ($斜体) {
            $cells.Style.Font.Italic = $true
        }

        if ($サイズ -gt 0) {
            $cells.Style.Font.Size = $サイズ
        }

        Close-ExcelPackage $excelPackage

        Write-Host "セル $セル範囲 のフォントを設定しました" -ForegroundColor Green
        return $true
    }
    catch {
        throw "フォント設定エラー: $_"
    }
}

# ========================================
# 罫線設定関数
# ========================================
function Excel操作_罫線設定 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイルパス,
        [Parameter(Mandatory=$true)]
        [string]$セル範囲,
        [string]$シート名 = "",
        [ValidateSet("Thin", "Medium", "Thick", "None")]
        [string]$線種 = "Thin",
        [ValidateSet("All", "Top", "Bottom", "Left", "Right", "Outline")]
        [string]$位置 = "All"
    )

    if (-not (Ensure-ImportExcelModule)) {
        throw "ImportExcelモジュールが利用できません"
    }

    if (-not (Test-Path $ファイルパス)) {
        throw "ファイルが存在しません: $ファイルパス"
    }

    try {
        $excelPackage = Open-ExcelPackage -Path $ファイルパス

        if ([string]::IsNullOrEmpty($シート名)) {
            $worksheet = $excelPackage.Workbook.Worksheets[1]
        } else {
            $worksheet = $excelPackage.Workbook.Worksheets[$シート名]
        }

        if ($null -eq $worksheet) {
            throw "シートが見つかりません: $シート名"
        }

        $cells = $worksheet.Cells[$セル範囲]
        $borderStyle = [OfficeOpenXml.Style.ExcelBorderStyle]::$線種

        switch ($位置) {
            "All" {
                $cells.Style.Border.Top.Style = $borderStyle
                $cells.Style.Border.Bottom.Style = $borderStyle
                $cells.Style.Border.Left.Style = $borderStyle
                $cells.Style.Border.Right.Style = $borderStyle
            }
            "Top" { $cells.Style.Border.Top.Style = $borderStyle }
            "Bottom" { $cells.Style.Border.Bottom.Style = $borderStyle }
            "Left" { $cells.Style.Border.Left.Style = $borderStyle }
            "Right" { $cells.Style.Border.Right.Style = $borderStyle }
            "Outline" {
                $cells.Style.Border.BorderAround($borderStyle)
            }
        }

        Close-ExcelPackage $excelPackage

        Write-Host "セル $セル範囲 に罫線を設定しました" -ForegroundColor Green
        return $true
    }
    catch {
        throw "罫線設定エラー: $_"
    }
}

# ========================================
# 数式設定関数
# ========================================
function Excel操作_数式設定 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイルパス,
        [Parameter(Mandatory=$true)]
        [string]$セルアドレス,
        [Parameter(Mandatory=$true)]
        [string]$数式,
        [string]$シート名 = ""
    )

    if (-not (Ensure-ImportExcelModule)) {
        throw "ImportExcelモジュールが利用できません"
    }

    if (-not (Test-Path $ファイルパス)) {
        throw "ファイルが存在しません: $ファイルパス"
    }

    try {
        $excelPackage = Open-ExcelPackage -Path $ファイルパス

        if ([string]::IsNullOrEmpty($シート名)) {
            $worksheet = $excelPackage.Workbook.Worksheets[1]
        } else {
            $worksheet = $excelPackage.Workbook.Worksheets[$シート名]
        }

        if ($null -eq $worksheet) {
            throw "シートが見つかりません: $シート名"
        }

        # 数式の先頭に=がない場合は追加
        if (-not $数式.StartsWith("=")) {
            $数式 = "=" + $数式
        }

        $worksheet.Cells[$セルアドレス].Formula = $数式

        Close-ExcelPackage $excelPackage

        Write-Host "セル $セルアドレス に数式を設定しました: $数式" -ForegroundColor Green
        return $true
    }
    catch {
        throw "数式設定エラー: $_"
    }
}

# ========================================
# シート追加関数
# ========================================
function Excel操作_シート追加 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイルパス,
        [Parameter(Mandatory=$true)]
        [string]$新シート名
    )

    if (-not (Ensure-ImportExcelModule)) {
        throw "ImportExcelモジュールが利用できません"
    }

    if (-not (Test-Path $ファイルパス)) {
        throw "ファイルが存在しません: $ファイルパス"
    }

    try {
        $excelPackage = Open-ExcelPackage -Path $ファイルパス

        # 既存シート名チェック
        $existing = $excelPackage.Workbook.Worksheets | Where-Object { $_.Name -eq $新シート名 }
        if ($existing) {
            Close-ExcelPackage $excelPackage -NoSave
            throw "同じ名前のシートが既に存在します: $新シート名"
        }

        $worksheet = $excelPackage.Workbook.Worksheets.Add($新シート名)

        Close-ExcelPackage $excelPackage

        Write-Host "シート '$新シート名' を追加しました" -ForegroundColor Green
        return $true
    }
    catch {
        throw "シート追加エラー: $_"
    }
}

# ========================================
# シート名変更関数
# ========================================
function Excel操作_シート名変更 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイルパス,
        [Parameter(Mandatory=$true)]
        [string]$現シート名,
        [Parameter(Mandatory=$true)]
        [string]$新シート名
    )

    if (-not (Ensure-ImportExcelModule)) {
        throw "ImportExcelモジュールが利用できません"
    }

    if (-not (Test-Path $ファイルパス)) {
        throw "ファイルが存在しません: $ファイルパス"
    }

    try {
        $excelPackage = Open-ExcelPackage -Path $ファイルパス

        $worksheet = $excelPackage.Workbook.Worksheets[$現シート名]
        if ($null -eq $worksheet) {
            Close-ExcelPackage $excelPackage -NoSave
            throw "シートが見つかりません: $現シート名"
        }

        $worksheet.Name = $新シート名

        Close-ExcelPackage $excelPackage

        Write-Host "シート名を '$現シート名' から '$新シート名' に変更しました" -ForegroundColor Green
        return $true
    }
    catch {
        throw "シート名変更エラー: $_"
    }
}

# ========================================
# シート削除関数
# ========================================
function Excel操作_シート削除 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイルパス,
        [Parameter(Mandatory=$true)]
        [string]$シート名
    )

    if (-not (Ensure-ImportExcelModule)) {
        throw "ImportExcelモジュールが利用できません"
    }

    if (-not (Test-Path $ファイルパス)) {
        throw "ファイルが存在しません: $ファイルパス"
    }

    try {
        $excelPackage = Open-ExcelPackage -Path $ファイルパス

        $worksheet = $excelPackage.Workbook.Worksheets[$シート名]
        if ($null -eq $worksheet) {
            Close-ExcelPackage $excelPackage -NoSave
            throw "シートが見つかりません: $シート名"
        }

        # シートが1つしかない場合はエラー
        if ($excelPackage.Workbook.Worksheets.Count -le 1) {
            Close-ExcelPackage $excelPackage -NoSave
            throw "最後のシートは削除できません"
        }

        $excelPackage.Workbook.Worksheets.Delete($シート名)

        Close-ExcelPackage $excelPackage

        Write-Host "シート '$シート名' を削除しました" -ForegroundColor Green
        return $true
    }
    catch {
        throw "シート削除エラー: $_"
    }
}

# ========================================
# 範囲クリア関数
# ========================================
function Excel操作_範囲クリア {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイルパス,
        [Parameter(Mandatory=$true)]
        [string]$セル範囲,
        [string]$シート名 = "",
        [switch]$書式もクリア
    )

    if (-not (Ensure-ImportExcelModule)) {
        throw "ImportExcelモジュールが利用できません"
    }

    if (-not (Test-Path $ファイルパス)) {
        throw "ファイルが存在しません: $ファイルパス"
    }

    try {
        $excelPackage = Open-ExcelPackage -Path $ファイルパス

        if ([string]::IsNullOrEmpty($シート名)) {
            $worksheet = $excelPackage.Workbook.Worksheets[1]
        } else {
            $worksheet = $excelPackage.Workbook.Worksheets[$シート名]
        }

        if ($null -eq $worksheet) {
            throw "シートが見つかりません: $シート名"
        }

        $cells = $worksheet.Cells[$セル範囲]

        # 値をクリア
        foreach ($cell in $cells) {
            $cell.Value = $null
            $cell.Formula = $null
        }

        if ($書式もクリア) {
            $cells.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::None
            $cells.Style.Font.Bold = $false
            $cells.Style.Font.Italic = $false
            $cells.Style.Border.Top.Style = [OfficeOpenXml.Style.ExcelBorderStyle]::None
            $cells.Style.Border.Bottom.Style = [OfficeOpenXml.Style.ExcelBorderStyle]::None
            $cells.Style.Border.Left.Style = [OfficeOpenXml.Style.ExcelBorderStyle]::None
            $cells.Style.Border.Right.Style = [OfficeOpenXml.Style.ExcelBorderStyle]::None
        }

        Close-ExcelPackage $excelPackage

        Write-Host "セル $セル範囲 をクリアしました" -ForegroundColor Green
        return $true
    }
    catch {
        throw "範囲クリアエラー: $_"
    }
}

# ========================================
# 最終行取得関数
# ========================================
function Excel操作_最終行取得 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイルパス,
        [string]$シート名 = "",
        [string]$列 = "A"
    )

    if (-not (Ensure-ImportExcelModule)) {
        throw "ImportExcelモジュールが利用できません"
    }

    if (-not (Test-Path $ファイルパス)) {
        throw "ファイルが存在しません: $ファイルパス"
    }

    try {
        $excelPackage = Open-ExcelPackage -Path $ファイルパス

        if ([string]::IsNullOrEmpty($シート名)) {
            $worksheet = $excelPackage.Workbook.Worksheets[1]
        } else {
            $worksheet = $excelPackage.Workbook.Worksheets[$シート名]
        }

        if ($null -eq $worksheet) {
            throw "シートが見つかりません: $シート名"
        }

        # 最終行を取得（Dimensionプロパティを使用）
        $最終行 = 0
        if ($null -ne $worksheet.Dimension) {
            $最終行 = $worksheet.Dimension.End.Row
        }

        Close-ExcelPackage $excelPackage -NoSave

        Write-Host "最終行: $最終行" -ForegroundColor Green
        return $最終行
    }
    catch {
        throw "最終行取得エラー: $_"
    }
}

# ========================================
# 最終列取得関数
# ========================================
function Excel操作_最終列取得 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイルパス,
        [string]$シート名 = ""
    )

    if (-not (Ensure-ImportExcelModule)) {
        throw "ImportExcelモジュールが利用できません"
    }

    if (-not (Test-Path $ファイルパス)) {
        throw "ファイルが存在しません: $ファイルパス"
    }

    try {
        $excelPackage = Open-ExcelPackage -Path $ファイルパス

        if ([string]::IsNullOrEmpty($シート名)) {
            $worksheet = $excelPackage.Workbook.Worksheets[1]
        } else {
            $worksheet = $excelPackage.Workbook.Worksheets[$シート名]
        }

        if ($null -eq $worksheet) {
            throw "シートが見つかりません: $シート名"
        }

        # 最終列を取得
        $最終列 = 0
        if ($null -ne $worksheet.Dimension) {
            $最終列 = $worksheet.Dimension.End.Column
        }

        Close-ExcelPackage $excelPackage -NoSave

        Write-Host "最終列: $最終列" -ForegroundColor Green
        return $最終列
    }
    catch {
        throw "最終列取得エラー: $_"
    }
}

# ========================================
# 行挿入関数
# ========================================
function Excel操作_行挿入 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイルパス,
        [Parameter(Mandatory=$true)]
        [int]$行番号,
        [int]$挿入行数 = 1,
        [string]$シート名 = ""
    )

    if (-not (Ensure-ImportExcelModule)) {
        throw "ImportExcelモジュールが利用できません"
    }

    if (-not (Test-Path $ファイルパス)) {
        throw "ファイルが存在しません: $ファイルパス"
    }

    try {
        $excelPackage = Open-ExcelPackage -Path $ファイルパス

        if ([string]::IsNullOrEmpty($シート名)) {
            $worksheet = $excelPackage.Workbook.Worksheets[1]
        } else {
            $worksheet = $excelPackage.Workbook.Worksheets[$シート名]
        }

        if ($null -eq $worksheet) {
            throw "シートが見つかりません: $シート名"
        }

        $worksheet.InsertRow($行番号, $挿入行数)

        Close-ExcelPackage $excelPackage

        Write-Host "行 $行番号 に $挿入行数 行を挿入しました" -ForegroundColor Green
        return $true
    }
    catch {
        throw "行挿入エラー: $_"
    }
}

# ========================================
# 行削除関数
# ========================================
function Excel操作_行削除 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイルパス,
        [Parameter(Mandatory=$true)]
        [int]$行番号,
        [int]$削除行数 = 1,
        [string]$シート名 = ""
    )

    if (-not (Ensure-ImportExcelModule)) {
        throw "ImportExcelモジュールが利用できません"
    }

    if (-not (Test-Path $ファイルパス)) {
        throw "ファイルが存在しません: $ファイルパス"
    }

    try {
        $excelPackage = Open-ExcelPackage -Path $ファイルパス

        if ([string]::IsNullOrEmpty($シート名)) {
            $worksheet = $excelPackage.Workbook.Worksheets[1]
        } else {
            $worksheet = $excelPackage.Workbook.Worksheets[$シート名]
        }

        if ($null -eq $worksheet) {
            throw "シートが見つかりません: $シート名"
        }

        $worksheet.DeleteRow($行番号, $削除行数)

        Close-ExcelPackage $excelPackage

        Write-Host "行 $行番号 から $削除行数 行を削除しました" -ForegroundColor Green
        return $true
    }
    catch {
        throw "行削除エラー: $_"
    }
}

# ========================================
# 列幅自動調整関数
# ========================================
function Excel操作_列幅自動調整 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイルパス,
        [string]$列範囲 = "",
        [string]$シート名 = ""
    )

    if (-not (Ensure-ImportExcelModule)) {
        throw "ImportExcelモジュールが利用できません"
    }

    if (-not (Test-Path $ファイルパス)) {
        throw "ファイルが存在しません: $ファイルパス"
    }

    try {
        $excelPackage = Open-ExcelPackage -Path $ファイルパス

        if ([string]::IsNullOrEmpty($シート名)) {
            $worksheet = $excelPackage.Workbook.Worksheets[1]
        } else {
            $worksheet = $excelPackage.Workbook.Worksheets[$シート名]
        }

        if ($null -eq $worksheet) {
            throw "シートが見つかりません: $シート名"
        }

        if ([string]::IsNullOrEmpty($列範囲)) {
            # 全列を自動調整
            if ($null -ne $worksheet.Dimension) {
                $worksheet.Cells[$worksheet.Dimension.Address].AutoFitColumns()
            }
        } else {
            # 指定範囲を自動調整
            $worksheet.Cells[$列範囲].AutoFitColumns()
        }

        Close-ExcelPackage $excelPackage

        Write-Host "列幅を自動調整しました" -ForegroundColor Green
        return $true
    }
    catch {
        throw "列幅自動調整エラー: $_"
    }
}

# ========================================
# シート一覧取得関数
# ========================================
function Excel操作_シート一覧取得 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイルパス
    )

    if (-not (Ensure-ImportExcelModule)) {
        throw "ImportExcelモジュールが利用できません"
    }

    if (-not (Test-Path $ファイルパス)) {
        throw "ファイルが存在しません: $ファイルパス"
    }

    try {
        $シート情報 = Get-ExcelSheetInfo -Path $ファイルパス
        $シート名一覧 = @($シート情報 | ForEach-Object { $_.Name })

        Write-Host "シート一覧: $($シート名一覧 -join ', ')" -ForegroundColor Green
        return $シート名一覧
    }
    catch {
        throw "シート一覧取得エラー: $_"
    }
}
