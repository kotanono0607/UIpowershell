function 1_2 {
    # ================================================================
    # 条件分岐ビルダー (PowerShell Windows Forms版)
    # ================================================================
    # 責任: 条件分岐 (if-else) のコードを生成する
    #
    # 処理フロー:
    #   1. 15_コードサブ_if文条件式作成.ps1 を読み込み
    #   2. ShowConditionBuilder を呼び出してダイアログを表示
    #   3. ユーザーが入力した条件式をコード文字列として返す
    #
    # 戻り値:
    #   - 生成されたif-else構文のコード文字列
    #   - キャンセル時は $null
    # ================================================================

    Write-Host "[1_2] ========== 関数開始 ==========" -ForegroundColor Cyan

    # スクリプトのルートパスを取得
    # API経由での実行時は$script:RootDirを使用、直接実行時は$PSScriptRootを使用
    if ($script:RootDir) {
        $メインPath = $script:RootDir  # API経由: UIpowershell/
        Write-Host "[1_2] パス取得: `$script:RootDir を使用 = $メインPath" -ForegroundColor Green
    } else {
        $スクリプトPath = $PSScriptRoot  # 00_code/
        $メインPath = Split-Path $スクリプトPath  # UIpowershell/
        Write-Host "[1_2] パス取得: `$PSScriptRoot を使用 = $メインPath" -ForegroundColor Green
    }

    # 共通ユーティリティを読み込み（取得-JSON値、Read-JsonSafe）
    $utilityPath = Join-Path $メインPath "00_共通ユーティリティ_JSON操作.ps1"
    Write-Host "[1_2] ユーティリティパス: $utilityPath" -ForegroundColor Gray
    if (Test-Path $utilityPath) {
        Write-Host "[1_2] ✅ ユーティリティファイル存在確認OK" -ForegroundColor Green
        . $utilityPath
        Write-Host "[1_2] ✅ ユーティリティ読み込み完了" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] 共通ユーティリティが見つかりません: $utilityPath" -ForegroundColor Red
        return $null
    }

    # 条件分岐ビルダーを読み込み
    $builderPath = Join-Path $メインPath "15_コードサブ_if文条件式作成.ps1"
    Write-Host "[1_2] ビルダーパス: $builderPath" -ForegroundColor Gray
    if (Test-Path $builderPath) {
        Write-Host "[1_2] ✅ ビルダーファイル存在確認OK" -ForegroundColor Green
        . $builderPath
        Write-Host "[1_2] ✅ ビルダー読み込み完了" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] 条件分岐ビルダーが見つかりません: $builderPath" -ForegroundColor Red
        return $null
    }

    try {
        # 条件分岐ダイアログを表示
        # JSONPathは未指定（関数内で自動取得される）
        Write-Host "[1_2] ShowConditionBuilder を呼び出します..." -ForegroundColor Cyan
        $conditionCode = ShowConditionBuilder
        Write-Host "[1_2] ShowConditionBuilder から戻りました。戻り値の型: $($conditionCode.GetType().Name)" -ForegroundColor Cyan

        # キャンセル時は $null が返る
        if ($null -eq $conditionCode) {
            Write-Host "[1_2] ⚠️ 戻り値が`$null です（キャンセルまたはエラー）" -ForegroundColor Yellow
            return $null
        }

        # 空文字列の場合はデフォルトの条件分岐コードを生成
        if ($conditionCode.Trim() -eq "") {
            Write-Host "[1_2] ⚠️ 戻り値が空文字列です。デフォルトの条件分岐を生成します" -ForegroundColor Yellow
            $conditionCode = @"
if (`$true) {
    # True の場合の処理をここに記述
} else {
    # False の場合の処理をここに記述
}
"@
            Write-Host "[1_2] ✅ デフォルトコードを生成しました" -ForegroundColor Green
        }

        # 生成されたコードを返す
        Write-Host "[1_2] ✅ コード生成成功（長さ: $($conditionCode.Length)文字）" -ForegroundColor Green
        return $conditionCode

    } catch {
        Write-Host "[ERROR] 条件分岐ビルダーの実行エラー: $_" -ForegroundColor Red
        Write-Host "[ERROR] エラー行: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
        Write-Host "[ERROR] スタックトレース: $($_.ScriptStackTrace)" -ForegroundColor Red
        return $null
    }
}
