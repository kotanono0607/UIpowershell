# Excel データ読み込み（外部プロセス用）
# 結果はJSONファイルに出力

param(
    [string]$FilePath,
    [string]$SheetName,
    [string]$OutputPath
)

try {
    # ImportExcelモジュールを確認・インストール
    if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
        Install-Module -Name ImportExcel -Force -Scope CurrentUser -ErrorAction Stop
    }
    Import-Module ImportExcel -ErrorAction Stop

    # Excelデータを読み込み
    $excelData = Import-Excel -Path $FilePath -WorksheetName $SheetName

    # ヘッダーを取得
    $headers = @()
    if ($excelData -and $excelData.Count -gt 0) {
        $headers = @($excelData[0].PSObject.Properties.Name)
    } elseif ($excelData) {
        $headers = @($excelData.PSObject.Properties.Name)
    }

    # ジャグ配列に変換（ヘッダー行 + データ行）
    $data = @()
    $data += ,$headers

    if ($excelData) {
        $rows = @($excelData)
        foreach ($row in $rows) {
            $rowData = @()
            foreach ($header in $headers) {
                $cellValue = $row.$header
                if ($null -eq $cellValue) { $cellValue = "" }
                $rowData += [string]$cellValue
            }
            $data += ,$rowData
        }
    }

    $rowCount = $data.Count
    $colCount = if ($rowCount -gt 0 -and $data[0]) { $data[0].Count } else { 0 }

    $result = @{
        success = $true
        data = $data
        rowCount = $rowCount
        colCount = $colCount
        headers = $headers
    }
} catch {
    $result = @{
        success = $false
        error = $_.Exception.Message
    }
}

$result | ConvertTo-Json -Depth 100 | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
