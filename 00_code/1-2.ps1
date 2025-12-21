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

    # スクリプトのルートパスを取得
    # API経由での実行時は$script:RootDirを使用、直接実行時は$PSScriptRootを使用
    if ($script:RootDir) {
        $メインPath = $script:RootDir  # API経由: UIpowershell/
    } else {
        $スクリプトPath = $PSScriptRoot  # 00_code/
        $メインPath = Split-Path $スクリプトPath  # UIpowershell/
    }

    # 共通ユーティリティを読み込み（取得-JSON値、Read-JsonSafe）
    $utilityPath = Join-Path $メインPath "00_共通ユーティリティ_JSON操作.ps1"
    if (Test-Path $utilityPath) {
        . $utilityPath
    } else {
        Write-Host "[ERROR] 共通ユーティリティが見つかりません: $utilityPath" -ForegroundColor Red
        return $null
    }

    # 条件分岐ビルダーを読み込み
    $builderPath = Join-Path $メインPath "15_コードサブ_if文条件式作成.ps1"
    if (Test-Path $builderPath) {
        . $builderPath
    } else {
        Write-Host "[ERROR] 条件分岐ビルダーが見つかりません: $builderPath" -ForegroundColor Red
        return $null
    }

    try {
        # 条件分岐ダイアログを表示
        # JSONPathは未指定（関数内で自動取得される）
        # 戻り値: JSON形式 {"branchCount": N, "code": "..."}
        $result = ShowConditionBuilder

        # キャンセル時は $null が返る
        if ($null -eq $result) {
            return $null
        }

        # JSON形式の戻り値をそのまま返す
        # ShowConditionBuilderが返すJSON: {"branchCount": N, "code": "..."}
        return $result

    } catch {
        Write-Host "[ERROR] 条件分岐ビルダーの実行エラー: $_" -ForegroundColor Red
        Write-Host "[ERROR] エラー行: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
        Write-Host "[ERROR] スタックトレース: $($_.ScriptStackTrace)" -ForegroundColor Red
        return $null
    }
}
