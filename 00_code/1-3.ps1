function 1_3 {
    # ================================================================
    # ループビルダー (PowerShell Windows Forms版)
    # ================================================================
    # 責任: ループ構文 (for/foreach/while) のコードを生成する
    #
    # 処理フロー:
    #   1. 15_コードサブ_if文条件式作成.ps1 を読み込み
    #   2. ShowLoopBuilder を呼び出してダイアログを表示
    #   3. ユーザーが入力したループ構文をコード文字列として返す
    #
    # 戻り値:
    #   - 生成されたループ構文のコード文字列
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

    # ループビルダーを読み込み
    $builderPath = Join-Path $メインPath "15_コードサブ_if文条件式作成.ps1"
    if (Test-Path $builderPath) {
        . $builderPath
    } else {
        Write-Host "[ERROR] ループビルダーが見つかりません: $builderPath" -ForegroundColor Red
        return $null
    }

    try {
        # ループダイアログを表示
        # JSONPathは未指定（関数内で自動取得される）
        $loopCode = ShowLoopBuilder

        # キャンセル時は $null が返る
        if ($null -eq $loopCode -or $loopCode.Trim() -eq "") {
            Write-Host "[INFO] ループの作成がキャンセルされました" -ForegroundColor Yellow
            return $null
        }

        # 生成されたコードを返す
        return $loopCode

    } catch {
        Write-Host "[ERROR] ループビルダーの実行エラー: $_" -ForegroundColor Red
        Write-Host "[ERROR] スタックトレース: $($_.ScriptStackTrace)" -ForegroundColor Red
        return $null
    }
}
