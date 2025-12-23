# Excel ファイル選択ダイアログ（外部プロセス用）
# 結果はJSONファイルに出力

param(
    [string]$OutputPath
)

Add-Type -AssemblyName System.Windows.Forms

$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
$dialog.Filter = "Excel Files (*.xlsx;*.xls)|*.xlsx;*.xls|All Files (*.*)|*.*"
$dialog.Title = "Excelファイルを選択してください"

$dialogResult = $dialog.ShowDialog()

if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
    $result = @{
        success = $true
        filePath = $dialog.FileName
    }
} else {
    $result = @{
        success = $false
        message = "キャンセルされました"
    }
}

$result | ConvertTo-Json | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
