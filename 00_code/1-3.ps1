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

    Write-Host "[1_3] ========== 関数開始 ==========" -ForegroundColor Cyan

    # スクリプトのルートパスを取得
    # API経由での実行時は$script:RootDirを使用、直接実行時は$PSScriptRootを使用
    if ($script:RootDir) {
        $メインPath = $script:RootDir  # API経由: UIpowershell/
        Write-Host "[1_3] パス取得: `$script:RootDir を使用 = $メインPath" -ForegroundColor Green
    } else {
        $スクリプトPath = $PSScriptRoot  # 00_code/
        $メインPath = Split-Path $スクリプトPath  # UIpowershell/
        Write-Host "[1_3] パス取得: `$PSScriptRoot を使用 = $メインPath" -ForegroundColor Green
    }

    # 共通ユーティリティを読み込み（取得-JSON値、Read-JsonSafe）
    $utilityPath = Join-Path $メインPath "00_共通ユーティリティ_JSON操作.ps1"
    Write-Host "[1_3] ユーティリティパス: $utilityPath" -ForegroundColor Gray
    if (Test-Path $utilityPath) {
        Write-Host "[1_3] ✅ ユーティリティファイル存在確認OK" -ForegroundColor Green
        . $utilityPath
        Write-Host "[1_3] ✅ ユーティリティ読み込み完了" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] 共通ユーティリティが見つかりません: $utilityPath" -ForegroundColor Red
        return $null
    }

    # ループビルダーを読み込み
    $builderPath = Join-Path $メインPath "15_コードサブ_if文条件式作成.ps1"
    Write-Host "[1_3] ビルダーパス: $builderPath" -ForegroundColor Gray
    if (Test-Path $builderPath) {
        Write-Host "[1_3] ✅ ビルダーファイル存在確認OK" -ForegroundColor Green
        . $builderPath
        Write-Host "[1_3] ✅ ビルダー読み込み完了" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] ループビルダーが見つかりません: $builderPath" -ForegroundColor Red
        return $null
    }

    try {
        # ループダイアログを表示
        # JSONPathは未指定（関数内で自動取得される）
        Write-Host "[1_3] ShowLoopBuilder を呼び出します..." -ForegroundColor Cyan
        $loopCode = ShowLoopBuilder
        Write-Host "[1_3] ShowLoopBuilder から戻りました。戻り値の型: $($loopCode.GetType().Name)" -ForegroundColor Cyan

        # キャンセル時は $null が返る
        if ($null -eq $loopCode) {
            Write-Host "[1_3] ⚠️ 戻り値が`$null です（キャンセルまたはエラー）" -ForegroundColor Yellow
            return $null
        }

        if ($loopCode.Trim() -eq "") {
            Write-Host "[1_3] ⚠️ 戻り値が空文字列です" -ForegroundColor Yellow
            return $null
        }

        # 生成されたコードを返す
        Write-Host "[1_3] ✅ コード生成成功（長さ: $($loopCode.Length)文字）" -ForegroundColor Green
        return $loopCode

    } catch {
        Write-Host "[ERROR] ループビルダーの実行エラー: $_" -ForegroundColor Red
        Write-Host "[ERROR] エラー行: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
        Write-Host "[ERROR] スタックトレース: $($_.ScriptStackTrace)" -ForegroundColor Red
        return $null
    }
}
