# Excel シート一覧取得（外部プロセス用）
# 結果はJSONファイルに出力

param(
    [string]$FilePath,
    [string]$OutputPath
)

try {
    # ImportExcelモジュールを確認・インストール
    if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
        Install-Module -Name ImportExcel -Force -Scope CurrentUser -ErrorAction Stop
    }
    Import-Module ImportExcel -ErrorAction Stop

    # シート情報を取得
    $sheetInfo = Get-ExcelSheetInfo -Path $FilePath
    $sheets = @($sheetInfo | ForEach-Object { $_.Name })

    $result = @{
        success = $true
        sheets = $sheets
    }
} catch {
    $result = @{
        success = $false
        error = $_.Exception.Message
    }
}

$result | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
