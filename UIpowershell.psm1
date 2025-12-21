# ========================================
# UIpowershell 共通モジュール
# output.ps1実行時に必要な関数を提供
# ========================================

$モジュールルート = $PSScriptRoot

# JSON操作ユーティリティ（他の関数が依存）
$JSON操作パス = Join-Path $モジュールルート "00_共通ユーティリティ_JSON操作.ps1"
if (Test-Path $JSON操作パス) {
    . $JSON操作パス
}

# 変数管理関数（変数を追加する、変数をJSONに保存する、変数をグリッド表示など）
$変数管理パス = Join-Path $モジュールルート "11_変数機能_変数管理を外から読み込む関数.ps1"
if (Test-Path $変数管理パス) {
    . $変数管理パス
}

# Excel操作関数（Excelシートデータ取得など）
$Excel操作パス = Join-Path $モジュールルート "14_コードサブ_EXCEL.ps1"
if (Test-Path $Excel操作パス) {
    . $Excel操作パス
}

# 全関数をエクスポート
Export-ModuleMember -Function *
