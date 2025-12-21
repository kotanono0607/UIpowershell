# ========================================
# UIpowershell 共通モジュール
# output.ps1実行時に必要な関数を提供
# ========================================

$ModuleRoot = $PSScriptRoot

# JSON操作ユーティリティ（他の関数が依存）
$JsonUtilPath = Join-Path $ModuleRoot "00_共通ユーティリティ_JSON操作.ps1"
if (Test-Path $JsonUtilPath) {
    . $JsonUtilPath
}

# 変数管理関数
$VarMgrPath = Join-Path $ModuleRoot "11_変数機能_変数管理を外から読み込む関数.ps1"
if (Test-Path $VarMgrPath) {
    . $VarMgrPath
}

# Excel操作関数
$ExcelPath = Join-Path $ModuleRoot "14_コードサブ_EXCEL.ps1"
if (Test-Path $ExcelPath) {
    . $ExcelPath
}

# 全関数をエクスポート
Export-ModuleMember -Function *
