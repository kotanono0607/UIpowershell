# ImportExcelモジュールを使用したExcel直接操作関数
# 更新: 2025-12-22 - セル単位の操作機能を提供

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
