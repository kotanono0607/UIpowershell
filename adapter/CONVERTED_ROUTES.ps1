# ==============================================================================
# Podeルート定義（自動変換）
# 元ファイル: api-server-v2.ps1
# 変換日: 2025-11-16
# 変換ルート数: 50個
# ==============================================================================

# ------------------------------
# ヘルスチェック
# ------------------------------
Add-PodeRoute -Method Get -Path "/api/health" -ScriptBlock {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    $result = @{
        status = "ok"
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        version = "2.0.0-phase3"
        phase = "Phase 3 - Adapter Layer Complete"
    }
    Write-PodeJsonResponse -Value $result

    $sw.Stop()
    Write-Host "⏱️ [API Timing] /health 処理時間: $($sw.ElapsedMilliseconds)ms" -ForegroundColor Yellow
}

# ------------------------------
# セッション情報
# ------------------------------
Add-PodeRoute -Method Get -Path "/api/session" -ScriptBlock {
    $result = Get-SessionInfo
    Write-PodeJsonResponse -Value $result
}

# ------------------------------
# デバッグ情報
# ------------------------------
Add-PodeRoute -Method Get -Path "/api/debug" -ScriptBlock {
    $result = Get-StateDebugInfo
    Write-PodeJsonResponse -Value $result
}

# ------------------------------
# 全ノード取得
# ------------------------------
Add-PodeRoute -Method Get -Path "/api/nodes" -ScriptBlock {
    $result = Get-AllNodes
    Write-PodeJsonResponse -Value $result
}

# ------------------------------
# ノード配列を一括設定
# ------------------------------
Add-PodeRoute -Method Put -Path "/api/nodes" -ScriptBlock {
    try {
        $body = $WebEvent.Data
        $result = Set-AllNodes -Nodes $body.nodes
        Write-PodeJsonResponse -Value $result
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# ノード追加
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/nodes" -ScriptBlock {
    try {
        $body = $WebEvent.Data
        $result = Add-Node -Node $body
        Write-PodeJsonResponse -Value $result
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# すべてのノードを削除
# ------------------------------
Add-PodeRoute -Method Delete -Path "/api/nodes/all" -ScriptBlock {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host "[API] 🔥 DELETE /api/nodes/all エンドポイントが呼ばれました！" -ForegroundColor Magenta
    Write-Host "[API] 🔍 Request.Method: $($WebEvent.Method)" -ForegroundColor Cyan
    Write-Host "[API] 🔍 Request.Path: $($WebEvent.Path)" -ForegroundColor Cyan

    try {
        Write-Host "[API] 全ノード削除リクエスト受信" -ForegroundColor Cyan

        $body = $WebEvent.Data
        Write-Host "[API] JSON解析成功" -ForegroundColor Green
        Write-Host "[API] body のプロパティ: $($body.PSObject.Properties.Name -join ', ')" -ForegroundColor Gray

        # $body.nodesのnullチェック
        $nodes = $body.nodes
        if ($null -eq $nodes) {
            Write-Host "[API] ⚠️ body.nodesがnullです。空配列として処理します" -ForegroundColor Yellow
            $nodes = @()
        } else {
            Write-Host "[API] body.nodesの型: $($nodes.GetType().FullName)" -ForegroundColor Gray
        }

        Write-Host "[API] 削除対象ノード数: $($nodes.Count)" -ForegroundColor Yellow

        # 最初の数個のノードIDを表示
        if ($nodes.Count -gt 0) {
            $sampleIds = $nodes | Select-Object -First 3 | ForEach-Object { $_.id }
            Write-Host "[API] サンプルノードID: $($sampleIds -join ', ')" -ForegroundColor Gray
        }

        # ノード配列が空でも関数を呼び出す（関数内で空チェックあり）
        $result = すべてのノードを削除_v2 -ノード配列 $nodes

        Write-Host "[API] ✅ 全ノード削除完了: $($result.deleteCount)個" -ForegroundColor Green

        Write-PodeJsonResponse -Value $result
    } catch {
        Write-Host "[API] ❌ エラー発生: $($_.Exception.Message)" -ForegroundColor Red
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# ノード削除（単一）
# ------------------------------
Add-PodeRoute -Method Delete -Path "/api/nodes/:id" -ScriptBlock {
    try {
        $nodeId = $WebEvent.Parameters['id']
        $body = $WebEvent.Data

        # ノード配列を受け取る
        $nodes = $body.nodes

        # v2関数で削除対象を特定
        $result = ノード削除_v2 -ノード配列 $nodes -TargetNodeId $nodeId

        Write-PodeJsonResponse -Value $result
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# 変数一覧取得
# ------------------------------
Add-PodeRoute -Method Get -Path "/api/variables" -ScriptBlock {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    $result = Get-VariableList_v2
    Write-PodeJsonResponse -Value $result

    $sw.Stop()
    Write-Host "⏱️ [API Timing] /variables 処理時間: $($sw.ElapsedMilliseconds)ms" -ForegroundColor Yellow
}

# ------------------------------
# 変数取得（名前指定）
# ------------------------------
Add-PodeRoute -Method Get -Path "/api/variables/:name" -ScriptBlock {
    try {
        $varName = $WebEvent.Parameters['name']
        $result = Get-Variable_v2 -Name $varName
        Write-PodeJsonResponse -Value $result
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# 変数追加
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/variables" -ScriptBlock {
    try {
        $body = $WebEvent.Data
        $result = Add-Variable_v2 -Name $body.name -Value $body.value -Type $body.type
        Write-PodeJsonResponse -Value $result
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# 変数更新
# ------------------------------
Add-PodeRoute -Method Put -Path "/api/variables/:name" -ScriptBlock {
    try {
        $varName = $WebEvent.Parameters['name']
        $body = $WebEvent.Data
        $result = Update-Variable_v2 -Name $varName -Value $body.value
        Write-PodeJsonResponse -Value $result
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# 変数削除
# ------------------------------
Add-PodeRoute -Method Delete -Path "/api/variables/:name" -ScriptBlock {
    try {
        $varName = $WebEvent.Parameters['name']
        $result = Remove-Variable_v2 -Name $varName
        Write-PodeJsonResponse -Value $result
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# 変数管理ダイアログ
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/variables/manage" -ScriptBlock {
    try {
        Write-Host "[API] /api/variables/manage - 変数管理ダイアログを表示" -ForegroundColor Cyan

        # 現在の変数一覧を取得
        $変数一覧結果 = Get-VariableList_v2
        if (-not $変数一覧結果.success) {
            $errorResult = @{
                success = $false
                error = "変数一覧の取得に失敗しました: $($変数一覧結果.error)"
            }
            Write-PodeJsonResponse -Value $errorResult -Depth 5
            return
        }

        Write-Host "[API] 現在の変数数: $($変数一覧結果.variables.Count)" -ForegroundColor Gray

        # 元の変数リストを保存（比較用）
        $元の変数リスト = $変数一覧結果.variables

        # 共通関数ファイルを読み込み
        . (Join-Path $using:RootDir "13_コードサブ汎用関数.ps1")

        # PowerShell Windows Forms ダイアログを表示
        $ダイアログ結果 = 変数管理を表示 -変数リスト $変数一覧結果.variables

        if ($null -eq $ダイアログ結果) {
            Write-Host "[API] 変数管理ダイアログがキャンセルされました" -ForegroundColor Yellow
            $result = @{
                success = $false
                cancelled = $true
                message = "変数管理がキャンセルされました"
            }
            Write-PodeJsonResponse -Value $result -Depth 5
            return
        }

        Write-Host "[API] ダイアログ完了 - 変数リストを比較して変更を適用します" -ForegroundColor Green

        # 変更を検出して適用
        $新しい変数リスト = $ダイアログ結果.variables
        $変更カウント = @{
            追加 = 0
            更新 = 0
            削除 = 0
        }

        # 元のリストから変数名のマップを作成
        $元の変数マップ = @{}
        foreach ($var in $元の変数リスト) {
            $元の変数マップ[$var.name] = $var
        }

        # 新しいリストから変数名のマップを作成
        $新しい変数マップ = @{}
        foreach ($var in $新しい変数リスト) {
            $新しい変数マップ[$var.name] = $var
        }

        # 追加・更新を検出
        foreach ($var in $新しい変数リスト) {
            if ($元の変数マップ.ContainsKey($var.name)) {
                # 既存の変数 - 値が変更されているか確認
                $元の値 = $元の変数マップ[$var.name].value
                $新しい値 = $var.value

                # 値を文字列化して比較
                $元の値文字列 = if ($元の値 -is [array]) { $元の値 -join "," } else { $元の値 }
                $新しい値文字列 = if ($新しい値 -is [array]) { $新しい値 -join "," } else { $新しい値 }

                if ($元の値文字列 -ne $新しい値文字列) {
                    Write-Host "[API] 変数を更新: $($var.name)" -ForegroundColor Cyan
                    $updateResult = Update-Variable_v2 -Name $var.name -Value $var.value
                    if ($updateResult.success) {
                        $変更カウント.更新++
                    }
                }
            } else {
                # 新しい変数
                Write-Host "[API] 変数を追加: $($var.name)" -ForegroundColor Green
                $addResult = Add-Variable_v2 -Name $var.name -Value $var.value -Type $var.type
                if ($addResult.success) {
                    $変更カウント.追加++
                }
            }
        }

        # 削除を検出
        foreach ($var in $元の変数リスト) {
            if (-not $新しい変数マップ.ContainsKey($var.name)) {
                Write-Host "[API] 変数を削除: $($var.name)" -ForegroundColor Yellow
                $removeResult = Remove-Variable_v2 -Name $var.name
                if ($removeResult.success) {
                    $変更カウント.削除++
                }
            }
        }

        Write-Host "[API] 変更完了 - 追加:$($変更カウント.追加), 更新:$($変更カウント.更新), 削除:$($変更カウント.削除)" -ForegroundColor Green

        # 変更を永続化
        $exportResult = Export-VariablesToJson_v2
        if (-not $exportResult.success) {
            Write-Host "[API] ⚠️ 変数のJSON保存に失敗: $($exportResult.error)" -ForegroundColor Yellow
        }

        # 成功レスポンス
        $result = @{
            success = $true
            cancelled = $false
            message = "変数管理が完了しました"
            changes = $変更カウント
        }

        Write-PodeJsonResponse -Value $result -Depth 5

    } catch {
        Write-Host "[API] ❌ エラー: $_" -ForegroundColor Red
        Write-Host "[API] スタックトレース: $($_.ScriptStackTrace)" -ForegroundColor Red
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# メニュー構造取得
# ------------------------------
Add-PodeRoute -Method Get -Path "/api/menu/structure" -ScriptBlock {
    $result = Get-MenuStructure_v2
    Write-PodeJsonResponse -Value $result
}

# ------------------------------
# メニューアクション実行
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/menu/action/:actionId" -ScriptBlock {
    try {
        $actionId = $WebEvent.Parameters['actionId']
        $body = $WebEvent.Data

        $params = if ($body.parameters) { $body.parameters } else { @{} }
        $result = Execute-MenuAction_v2 -ActionId $actionId -Parameters $params

        Write-PodeJsonResponse -Value $result
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# PowerShellコード生成
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/execute/generate" -ScriptBlock {
    try {
        # デバッグモード（環境変数で制御）
        $DebugMode = $env:UIPOWERSHELL_DEBUG -eq "1"

        if ($DebugMode) {
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
            Write-Host "[/api/execute/generate] リクエスト受信" -ForegroundColor Cyan
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        }

        $body = $WebEvent.Data

        # ノード配列の検証
        if ($null -eq $body.nodes -or $body.nodes.Count -eq 0) {
            Set-PodeResponseStatus -Code 400
            $errorResult = @{
                success = $false
                error = "ノード配列が空またはNULLです"
            }
            Write-PodeJsonResponse -Value $errorResult
            return
        }

        # 配列として確実に変換
        $nodeArray = @($body.nodes)

        # OutputPathとOpenFileのデフォルト値設定
        $outputPath = if ($body.outputPath) { $body.outputPath } else { $null }
        $openFile = if ($body.PSObject.Properties.Name -contains 'openFile') { [bool]$body.openFile } else { $false }

        if ($DebugMode) {
            Write-Host "[DEBUG] ノード数: $($nodeArray.Count)" -ForegroundColor Green
        }

        $result = 実行イベント_v2 `
            -ノード配列 $nodeArray `
            -OutputPath $outputPath `
            -OpenFile $openFile

        if ($DebugMode) {
            Write-Host "[DEBUG] 実行イベント_v2 completed - success: $($result.success)" -ForegroundColor Green
            if ($result.code) {
                Write-Host "[DEBUG] コード長: $($result.code.Length) 文字" -ForegroundColor Green
            }
        } else {
            # 通常モード: 簡潔なログのみ
            Write-Host "[実行] ノード数: $($nodeArray.Count), 成功: $($result.success)" -ForegroundColor $(if ($result.success) { "Green" } else { "Red" })
        }

        Write-PodeJsonResponse -Value $result

        if ($DebugMode) {
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
            Write-Host "[/api/execute/generate] ✅ 成功" -ForegroundColor Green
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
        }
    } catch {
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        Write-Host "[/api/execute/generate] ❌ エラー発生" -ForegroundColor Red
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        Write-Host "[ERROR] Exception: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[ERROR] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red

        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
            stackTrace = $_.ScriptStackTrace
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# コード結果表示ダイアログ
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/code-result/show" -ScriptBlock {
    try {
        Write-Host "[API] /api/code-result/show - コード結果ダイアログを表示" -ForegroundColor Cyan

        $body = $WebEvent.Data

        # 生成結果を構築
        $生成結果 = @{
            code = $body.code
            nodeCount = $body.nodeCount
            outputPath = $body.outputPath
            timestamp = if ($body.timestamp) { $body.timestamp } else { Get-Date -Format "yyyy/MM/dd HH:mm:ss" }
        }

        Write-Host "[API] ノード数: $($生成結果.nodeCount)" -ForegroundColor Gray
        Write-Host "[API] コード長: $($生成結果.code.Length)文字" -ForegroundColor Gray

        # 共通関数ファイルを読み込み
        . (Join-Path $using:RootDir "13_コードサブ汎用関数.ps1")

        # PowerShell Windows Forms ダイアログを表示
        $ダイアログ結果 = コード結果を表示 -生成結果 $生成結果

        Write-Host "[API] ✅ コード結果ダイアログ完了" -ForegroundColor Green

        # 成功レスポンス
        $result = @{
            success = $true
            message = "コード結果ダイアログを表示しました"
        }

        Write-PodeJsonResponse -Value $result -Depth 5

    } catch {
        Write-Host "[API] ❌ エラー: $_" -ForegroundColor Red
        Write-Host "[API] スタックトレース: $($_.ScriptStackTrace)" -ForegroundColor Red
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# PowerShellスクリプト実行
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/execute/script" -ScriptBlock {
    try {
        $body = $WebEvent.Data
        $scriptContent = $body.script
        $nodeName = $body.nodeName

        if ([string]::IsNullOrWhiteSpace($scriptContent)) {
            Set-PodeResponseStatus -Code 400
            $errorResult = @{
                success = $false
                error = "スクリプトが空です"
            }
            Write-PodeJsonResponse -Value $errorResult
            return
        }

        # 汎用関数を読み込み（13_コードサブ汎用関数.ps1）
        $汎用関数パス = Join-Path $using:RootDir "13_コードサブ汎用関数.ps1"
        if (Test-Path $汎用関数パス) {
            . $汎用関数パス
        }

        # スクリプトを実行して出力を取得
        $output = Invoke-Expression $scriptContent 2>&1 | Out-String

        $result = @{
            success = $true
            output = $output
            nodeName = $nodeName
        }
        Write-PodeJsonResponse -Value $result
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# フォルダ一覧取得
# ------------------------------
Add-PodeRoute -Method Get -Path "/api/folders" -ScriptBlock {
    $result = フォルダ切替イベント_v2 -FolderName "list"
    Write-PodeJsonResponse -Value $result
}

# ------------------------------
# フォルダ作成
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/folders" -ScriptBlock {
    try {
        $body = $WebEvent.Data
        $result = フォルダ作成イベント_v2 -FolderName $body.name
        Write-PodeJsonResponse -Value $result
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# フォルダ切り替え
# ------------------------------
Add-PodeRoute -Method Put -Path "/api/folders/:name" -ScriptBlock {
    try {
        $folderName = $WebEvent.Parameters['name']
        $result = フォルダ切替イベント_v2 -FolderName $folderName
        Write-PodeJsonResponse -Value $result
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# フォルダ切替ダイアログ
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/folders/switch-dialog" -ScriptBlock {
    try {
        Write-Host "[API] /api/folders/switch-dialog - フォルダ切替ダイアログを表示" -ForegroundColor Cyan

        # 現在のフォルダ一覧を取得
        $フォルダ一覧結果 = フォルダ切替イベント_v2 -FolderName "list"
        if (-not $フォルダ一覧結果.success) {
            $errorResult = @{
                success = $false
                error = "フォルダ一覧の取得に失敗しました: $($フォルダ一覧結果.error)"
            }
            Write-PodeJsonResponse -Value $errorResult -Depth 5
            return
        }

        $フォルダリスト = $フォルダ一覧結果.folders

        # 現在のフォルダを取得
        $rootDir = $using:RootDir
        $mainJsonPath = Join-Path $rootDir "03_history\メイン.json"
        $現在のフォルダ = ""

        if (Test-Path $mainJsonPath) {
            try {
                $content = Get-Content $mainJsonPath -Raw -Encoding UTF8
                $mainData = $content | ConvertFrom-Json
                $folderPath = $mainData.フォルダパス
                $現在のフォルダ = Split-Path -Leaf $folderPath
                Write-Host "[API] 現在のフォルダ: $現在のフォルダ" -ForegroundColor Gray
            } catch {
                Write-Host "[API] ⚠️ メイン.jsonの読み込みに失敗しました: $_" -ForegroundColor Yellow
            }
        }

        Write-Host "[API] フォルダ数: $($フォルダリスト.Count)" -ForegroundColor Gray

        # 共通関数ファイルを読み込み
        . (Join-Path $using:RootDir "13_コードサブ汎用関数.ps1")

        # PowerShell Windows Forms ダイアログを表示
        $ダイアログ結果 = フォルダ切替を表示 -フォルダリスト $フォルダリスト -現在のフォルダ $現在のフォルダ

        if ($null -eq $ダイアログ結果) {
            Write-Host "[API] フォルダ切替ダイアログがキャンセルされました" -ForegroundColor Yellow
            $result = @{
                success = $false
                cancelled = $true
                message = "フォルダ切替がキャンセルされました"
            }
            Write-PodeJsonResponse -Value $result -Depth 5
            return
        }

        Write-Host "[API] ダイアログ完了 - 選択されたフォルダ: $($ダイアログ結果.folderName)" -ForegroundColor Green

        # 新しいフォルダが作成された場合はAPI経由で作成
        if ($ダイアログ結果.newFolder) {
            Write-Host "[API] 新しいフォルダを作成: $($ダイアログ結果.newFolder)" -ForegroundColor Cyan
            $作成結果 = フォルダ作成イベント_v2 -FolderName $ダイアログ結果.newFolder
            if (-not $作成結果.success) {
                Write-Host "[API] ⚠️ フォルダ作成に失敗: $($作成結果.error)" -ForegroundColor Yellow
            }
        }

        # 選択されたフォルダが現在のフォルダと異なる場合は切り替え
        if ($ダイアログ結果.folderName -ne $現在のフォルダ) {
            Write-Host "[API] フォルダを切り替え: $($ダイアログ結果.folderName)" -ForegroundColor Cyan
            $切替結果 = フォルダ切替イベント_v2 -FolderName $ダイアログ結果.folderName

            if ($切替結果.success) {
                Write-Host "[API] ✅ フォルダ切り替え成功" -ForegroundColor Green
            } else {
                Write-Host "[API] ❌ フォルダ切り替え失敗: $($切替結果.error)" -ForegroundColor Red
            }

            # 成功レスポンス
            $result = @{
                success = $切替結果.success
                cancelled = $false
                message = "フォルダ「$($ダイアログ結果.folderName)」に切り替えました"
                folderName = $ダイアログ結果.folderName
                switched = $true
                error = $切替結果.error
            }
        } else {
            # 同じフォルダが選択された場合
            Write-Host "[API] 同じフォルダが選択されました（切り替えなし）" -ForegroundColor Gray
            $result = @{
                success = $true
                cancelled = $false
                message = "フォルダ選択完了（変更なし）"
                folderName = $ダイアログ結果.folderName
                switched = $false
            }
        }

        Write-PodeJsonResponse -Value $result -Depth 5

    } catch {
        Write-Host "[API] ❌ エラー: $_" -ForegroundColor Red
        Write-Host "[API] スタックトレース: $($_.ScriptStackTrace)" -ForegroundColor Red
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# メイン.json読み込み
# ------------------------------
Add-PodeRoute -Method Get -Path "/api/main-json" -ScriptBlock {
    try {
        $rootDir = $using:RootDir
        $mainJsonPath = Join-Path $rootDir "03_history\メイン.json"

        if (Test-Path $mainJsonPath) {
            $content = Get-Content $mainJsonPath -Raw -Encoding UTF8
            $mainData = $content | ConvertFrom-Json

            # フォルダパスからフォルダ名を抽出
            $folderPath = $mainData.フォルダパス
            $folderName = Split-Path -Leaf $folderPath

            $result = @{
                success = $true
                folderPath = $folderPath
                folderName = $folderName
            }
            Write-PodeJsonResponse -Value $result
        } else {
            $result = @{
                success = $false
                error = "メイン.jsonが存在しません"
            }
            Write-PodeJsonResponse -Value $result
        }
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# memory.json読み込み（フォルダごと）
# ------------------------------
Add-PodeRoute -Method Get -Path "/api/folders/:name/memory" -ScriptBlock {
    try {
        $folderName = $WebEvent.Parameters['name']
        $rootDir = $using:RootDir
        $memoryPath = Join-Path $rootDir "03_history\$folderName\memory.json"

        if (Test-Path $memoryPath) {
            $content = Get-Content $memoryPath -Raw -Encoding UTF8
            $memoryData = $content | ConvertFrom-Json

            $result = @{
                success = $true
                data = $memoryData
                folderName = $folderName
            }
            Write-PodeJsonResponse -Value $result -Depth 10
        } else {
            # memory.jsonが存在しない場合は空のレイヤー構造を返す
            $emptyMemory = @{
                "1" = @{ "構成" = @() }
                "2" = @{ "構成" = @() }
                "3" = @{ "構成" = @() }
                "4" = @{ "構成" = @() }
                "5" = @{ "構成" = @() }
                "6" = @{ "構成" = @() }
            }
            $result = @{
                success = $true
                data = $emptyMemory
                folderName = $folderName
                message = "memory.jsonが存在しないため、空のデータを返しました"
            }
            Write-PodeJsonResponse -Value $result -Depth 10
        }
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# memory.json保存（フォルダごと）
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/folders/:name/memory" -ScriptBlock {
    try {
        $folderName = $WebEvent.Parameters['name']
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host "[API] memory.json保存リクエスト受信" -ForegroundColor Cyan
        Write-Host "[API] フォルダ名: $folderName" -ForegroundColor Yellow

        $body = $WebEvent.Data
        Write-Host "[API] JSON解析成功" -ForegroundColor Green

        $layerStructure = $body.layerStructure
        Write-Host "[API] layerStructure取得: $($layerStructure.PSObject.Properties.Name.Count) レイヤー" -ForegroundColor Gray

        $rootDir = $using:RootDir
        $folderPath = Join-Path $rootDir "03_history\$folderName"
        $memoryPath = Join-Path $folderPath "memory.json"

        Write-Host "[API] 保存先パス: $memoryPath" -ForegroundColor Gray

        # フォルダが存在しない場合は作成
        if (-not (Test-Path $folderPath)) {
            Write-Host "[API] フォルダを作成します: $folderPath" -ForegroundColor Yellow
            New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
        } else {
            Write-Host "[API] フォルダは既に存在します" -ForegroundColor Gray
        }

        # memory.json形式に変換
        # [ordered]を使用してレイヤーの順序を保持（1, 2, 3, 4, 5, 6の順）
        $memoryData = [ordered]@{}
        $totalNodes = 0

        for ($i = 1; $i -le 6; $i++) {
            $layerNodes = $layerStructure."$i".nodes
            $構成 = @()

            foreach ($node in $layerNodes) {
                # [ordered] を使用してフィールドの順序を既存のPS1形式に合わせる
                # 既存PS1版: 05_メインフォームUI_矢印処理.ps1 1069-1081行
                $構成 += [ordered]@{
                    ボタン名 = $node.name
                    X座標 = if ($node.x) { $node.x } else { 10 }
                    Y座標 = $node.y
                    順番 = if ($node.順番) { $node.順番 } else { 1 }
                    ボタン色 = $node.color
                    テキスト = $node.text
                    処理番号 = if ($node.処理番号) { $node.処理番号 } else { "未設定" }
                    高さ = if ($node.height) { $node.height } else { 40 }
                    幅 = if ($node.width) { $node.width } else { 280 }
                    script = if ($null -ne $node.script) { $node.script } else { "未設定" }
                    GroupID = if ($node.groupId -ne $null -and $node.groupId -ne "") { $node.groupId } else { "" }
                }
                $totalNodes++
            }

            $memoryData["$i"] = @{ "構成" = $構成 }

            if ($構成.Count -gt 0) {
                Write-Host "[API] レイヤー$i : $($構成.Count)個のノード" -ForegroundColor Gray
            }
        }

        Write-Host "[API] 合計ノード数: $totalNodes" -ForegroundColor Yellow

        # JSON形式で保存
        $json = $memoryData | ConvertTo-Json -Depth 10
        Write-Host "[API] JSON生成完了 (長さ: $($json.Length) 文字)" -ForegroundColor Gray

        # UTF-8 without BOMで保存（文字化け防止）
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($memoryPath, $json, $utf8NoBom)
        Write-Host "[API] UTF-8 (BOMなし) でファイルを保存しました" -ForegroundColor Green

        # ファイル保存確認
        if (Test-Path $memoryPath) {
            $fileInfo = Get-Item $memoryPath
            Write-Host "[API] ✅ ファイル保存成功" -ForegroundColor Green
            Write-Host "[API]    ファイルサイズ: $($fileInfo.Length) バイト" -ForegroundColor Gray
            Write-Host "[API]    最終更新時刻: $($fileInfo.LastWriteTime)" -ForegroundColor Gray
        } else {
            Write-Host "[API] ❌ ファイル保存失敗" -ForegroundColor Red
        }

        $result = @{
            success = $true
            folderName = $folderName
            message = "memory.jsonを保存しました"
            nodeCount = $totalNodes
        }
        Write-PodeJsonResponse -Value $result

        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    } catch {
        Write-Host "[API] ❌ エラー発生: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[API] スタックトレース: $($_.ScriptStackTrace)" -ForegroundColor Red

        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# コード.json読み込み（フォルダごと）
# ------------------------------
Add-PodeRoute -Method Get -Path "/api/folders/:name/code" -ScriptBlock {
    try {
        $folderName = $WebEvent.Parameters['name']
        $rootDir = $using:RootDir
        $codePath = Join-Path $rootDir "03_history\$folderName\コード.json"

        if (Test-Path $codePath) {
            $content = Get-Content $codePath -Raw -Encoding UTF8
            $codeData = $content | ConvertFrom-Json

            # ✅ 修正: JSON読み込み後、LF(\n) を CRLF(\r\n) に変換
            # ConvertFrom-Jsonは既に\nを実際のLF文字に変換しているため、LF→CRLFの変換が必要
            if ($codeData."エントリ") {
                Write-Host "[GET /code] 🔧 改行文字の正規化を開始（LF → CRLF）..." -ForegroundColor Yellow
                $convertedCount = 0
                foreach ($key in $codeData."エントリ".PSObject.Properties.Name) {
                    $originalValue = $codeData."エントリ".$key
                    if ($originalValue) {
                        # LF(\n)のみをCRLF(\r\n)に変換（既にCRLFの場合は変更なし）
                        # まず既存のCRLFをプレースホルダーに置換し、LFをCRLFに変換してから戻す
                        $newValue = $originalValue -replace "`r`n", "<<CRLF>>" -replace "`n", "`r`n" -replace "<<CRLF>>", "`r`n"
                        if ($newValue -ne $originalValue) {
                            $codeData."エントリ".$key = $newValue
                            $convertedCount++
                            Write-Host "[GET /code]   - [$key] LF→CRLF変換: $($originalValue.Length)文字 → $($newValue.Length)文字" -ForegroundColor DarkGray
                        }
                    }
                }
                Write-Host "[GET /code] ✅ $convertedCount 個のエントリで改行を正規化しました" -ForegroundColor Green
            }

            $result = @{
                success = $true
                data = $codeData
                folderName = $folderName
            }
            Write-PodeJsonResponse -Value $result -Depth 10
        } else {
            # コード.jsonが存在しない場合は空の構造を返す
            $emptyCode = @{
                "エントリ" = @{}
                "最後のID" = 0
            }
            $result = @{
                success = $true
                data = $emptyCode
                folderName = $folderName
                message = "コード.jsonが存在しないため、空のデータを返しました"
            }
            Write-PodeJsonResponse -Value $result -Depth 10
        }
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# コード.json保存（フォルダごと）
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/folders/:name/code" -ScriptBlock {
    try {
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host "[API] コード.json保存リクエスト受信" -ForegroundColor Cyan

        $folderName = $WebEvent.Parameters['name']
        Write-Host "[API] フォルダ名: $folderName" -ForegroundColor Yellow

        $body = $WebEvent.Data
        Write-Host "[API] ✅ ConvertFrom-Json完了" -ForegroundColor Green

        if ($null -eq $body) {
            Write-Host "[API] ❌ エラー: bodyがnullです" -ForegroundColor Red
            throw "リクエストボディが空です"
        }

        Write-Host "[API] bodyの内容: $($body | ConvertTo-Json -Compress -Depth 2)" -ForegroundColor Yellow

        $codeData = $body.codeData
        if ($null -eq $codeData) {
            Write-Host "[API] ❌ エラー: codeDataがnullです" -ForegroundColor Red
            throw "codeDataが見つかりません"
        }

        # ✅ 修正: JSON読み込み後、LF(\n) を CRLF(\r\n) に変換
        # ConvertFrom-Jsonは既に\nを実際のLF文字に変換しているため、LF→CRLFの変換が必要
        if ($codeData."エントリ") {
            Write-Host "[API] 🔧 改行文字の正規化を開始（LF → CRLF）..." -ForegroundColor Yellow
            $convertedCount = 0
            foreach ($key in $codeData."エントリ".PSObject.Properties.Name) {
                $originalValue = $codeData."エントリ".$key
                if ($originalValue) {
                    # LF(\n)のみをCRLF(\r\n)に変換（既にCRLFの場合は変更なし）
                    # まず既存のCRLFをプレースホルダーに置換し、LFをCRLFに変換してから戻す
                    $newValue = $originalValue -replace "`r`n", "<<CRLF>>" -replace "`n", "`r`n" -replace "<<CRLF>>", "`r`n"
                    if ($newValue -ne $originalValue) {
                        $codeData."エントリ".$key = $newValue
                        $convertedCount++
                        Write-Host "[API]   - [$key] LF→CRLF変換: $($originalValue.Length)文字 → $($newValue.Length)文字" -ForegroundColor DarkGray
                    }
                }
            }
            Write-Host "[API] ✅ $convertedCount 個のエントリで改行を正規化しました" -ForegroundColor Green
        }

        Write-Host "[API] ✅ codeDataを取得しました" -ForegroundColor Green
        Write-Host "[API] codeDataの内容: $($codeData | ConvertTo-Json -Compress -Depth 2)" -ForegroundColor Yellow

        $rootDir = $using:RootDir
        $folderPath = Join-Path $rootDir "03_history\$folderName"
        $codePath = Join-Path $folderPath "コード.json"

        Write-Host "[API] 保存先パス: $codePath" -ForegroundColor Yellow
        Write-Host "[API] フォルダパス: $folderPath" -ForegroundColor Yellow

        # フォルダが存在しない場合は作成
        if (-not (Test-Path $folderPath)) {
            Write-Host "[API] フォルダが存在しないため作成します" -ForegroundColor Magenta
            New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
        } else {
            Write-Host "[API] フォルダは既に存在します" -ForegroundColor Green
        }

        # JSON形式で保存
        $json = $codeData | ConvertTo-Json -Depth 10
        Write-Host "[API] JSON生成完了 (長さ: $($json.Length) 文字)" -ForegroundColor Yellow
        Write-Host "[API] JSON内容の最初の200文字: $($json.Substring(0, [Math]::Min(200, $json.Length)))" -ForegroundColor Gray

        # UTF-8 without BOMで保存（文字化け防止）
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($codePath, $json, $utf8NoBom)
        Write-Host "[API] UTF-8 (BOMなし) でファイルを保存しました" -ForegroundColor Green

        # 保存確認
        if (Test-Path $codePath) {
            $fileInfo = Get-Item $codePath
            Write-Host "[API] ✅ ファイル保存成功" -ForegroundColor Green
            Write-Host "[API]    ファイルサイズ: $($fileInfo.Length) バイト" -ForegroundColor Green
            Write-Host "[API]    最終更新時刻: $($fileInfo.LastWriteTime)" -ForegroundColor Green
        } else {
            Write-Host "[API] ❌ ファイル保存後に存在確認失敗" -ForegroundColor Red
        }

        $result = @{
            success = $true
            folderName = $folderName
            message = "コード.jsonを保存しました"
            filePath = $codePath
        }
        Write-PodeJsonResponse -Value $result

        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    } catch {
        Write-Host "[API] ❌ エラー発生: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[API] スタックトレース: $($_.Exception.StackTrace)" -ForegroundColor Red

        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# variables.json読み込み（フォルダごと）
# ------------------------------
Add-PodeRoute -Method Get -Path "/api/folders/:name/variables" -ScriptBlock {
    try {
        $folderName = $WebEvent.Parameters['name']
        $rootDir = $using:RootDir
        $variablesPath = Join-Path $rootDir "03_history\$folderName\variables.json"

        if (Test-Path $variablesPath) {
            $content = Get-Content $variablesPath -Raw -Encoding UTF8
            $variablesData = $content | ConvertFrom-Json

            $result = @{
                success = $true
                data = $variablesData
                folderName = $folderName
            }
            Write-PodeJsonResponse -Value $result -Depth 10
        } else {
            # variables.jsonが存在しない場合は空のオブジェクトを返す
            $emptyVariables = @{}
            $result = @{
                success = $true
                data = $emptyVariables
                folderName = $folderName
                message = "variables.jsonが存在しないため、空のデータを返しました"
            }
            Write-PodeJsonResponse -Value $result -Depth 10
        }
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# ドロップ可否チェック
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/validate/drop" -ScriptBlock {
    try {
        $body = $WebEvent.Data

        $result = ドロップ禁止チェック_ネスト規制_v2 `
            -ノード配列 $body.nodes `
            -MovingNodeId $body.movingNodeId `
            -設置希望Y $body.targetY

        Write-PodeJsonResponse -Value $result
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# 新しいIDを自動生成
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/id/generate" -ScriptBlock {
    try {
        $newId = IDを自動生成する
        $result = @{
            success = $true
            id = $newId
        }
        Write-PodeJsonResponse -Value $result
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# エントリを追加（指定ID）
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/entry/add" -ScriptBlock {
    try {
        $body = $WebEvent.Data

        $result = エントリを追加_指定ID `
            -targetID $body.targetID `
            -TypeName $body.TypeName `
            -displayText $body.displayText `
            -code $body.code `
            -toID $body.toID `
            -order $body.order

        $responseObj = @{
            success = $true
            data = $result
        }
        Write-PodeJsonResponse -Value $responseObj
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# IDでエントリを取得
# ------------------------------
Add-PodeRoute -Method Get -Path "/api/entry/:id" -ScriptBlock {
    try {
        $id = $WebEvent.Parameters['id']
        $entry = IDでエントリを取得 -targetID $id

        if ($entry) {
            $result = @{
                success = $true
                data = $entry
            }
            Write-PodeJsonResponse -Value $result
        } else {
            Set-PodeResponseStatus -Code 404
            $errorResult = @{
                success = $false
                error = "エントリが見つかりません: ID=$id"
            }
            Write-PodeJsonResponse -Value $errorResult
        }
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# 全エントリを取得（フロー描画用）
# ------------------------------
Add-PodeRoute -Method Get -Path "/api/entries/all" -ScriptBlock {
    try {
        $jsonPath = Join-Path $using:RootDir "00_code\コード.json"

        if (Test-Path $jsonPath) {
            $jsonContent = Get-Content $jsonPath -Encoding UTF8 -Raw | ConvertFrom-Json

            $result = @{
                success = $true
                data = $jsonContent
            }
            Write-PodeJsonResponse -Value $result
        } else {
            $result = @{
                success = $true
                data = @()
                message = "コード.jsonが存在しません"
            }
            Write-PodeJsonResponse -Value $result
        }
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# 利用可能なノード関数一覧を取得
# ------------------------------
Add-PodeRoute -Method Get -Path "/api/node/functions" -ScriptBlock {
    try {
        $codeDir = Join-Path $using:RootDir "00_code"

        if (Test-Path $codeDir) {
            # 00_code/*.ps1 ファイルを取得
            $scriptFiles = Get-ChildItem -Path $codeDir -Filter "*.ps1"

            $functions = @()
            foreach ($file in $scriptFiles) {
                $functionName = $file.BaseName -replace '-', '_'
                $functions += @{
                    fileName = $file.Name
                    functionName = $functionName
                    scriptPath = $file.FullName
                }
            }

            $result = @{
                success = $true
                data = $functions
            }
            Write-PodeJsonResponse -Value $result -Depth 5
        } else {
            $result = @{
                success = $false
                error = "00_code directory not found"
            }
            Write-PodeJsonResponse -Value $result
        }
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# ノード関数を実行
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/node/execute/:functionName" -ScriptBlock {
    try {
        $functionName = $WebEvent.Parameters['functionName']
        Write-Host "[ノード関数実行] 関数名: $functionName" -ForegroundColor Cyan

        # 関数名をファイル名に変換（例: "8_1" -> "8-1.ps1"）
        $fileName = $functionName -replace '_', '-'
        $scriptPath = Join-Path $using:RootDir "00_code\$fileName.ps1"

        Write-Host "[ノード関数実行] スクリプトパス: $scriptPath" -ForegroundColor Gray

        if (-not (Test-Path $scriptPath)) {
            Set-PodeResponseStatus -Code 404
            $errorResult = @{
                success = $false
                error = "Script file not found: $fileName.ps1"
            }
            Write-PodeJsonResponse -Value $errorResult
            return
        }

        # スクリプトを読み込み
        Write-Host "[ノード関数実行] 📂 ファイルを読み込み中..." -ForegroundColor Yellow
        Write-Host "[ノード関数実行] 📄 ファイルパス: $scriptPath" -ForegroundColor Gray
        Write-Host "[ノード関数実行] ⏰ ファイル更新日時: $((Get-Item $scriptPath).LastWriteTime)" -ForegroundColor Gray

        # ファイル内容をプレビュー表示（デバッグ用）
        $fileContent = Get-Content $scriptPath -Raw
        $preview = $fileContent.Substring(0, [Math]::Min(200, $fileContent.Length))
        Write-Host "[ノード関数実行] 📝 ファイルプレビュー (先頭200文字):" -ForegroundColor Gray
        Write-Host $preview -ForegroundColor DarkGray

        # 汎用関数を読み込み（13_コードサブ汎用関数.ps1）
        $汎用関数パス = Join-Path $using:RootDir "13_コードサブ汎用関数.ps1"
        if (Test-Path $汎用関数パス) {
            . $汎用関数パス
            Write-Host "[ノード関数実行] ✅ 汎用関数を読み込みました" -ForegroundColor Green
        }

        . $scriptPath
        Write-Host "[ノード関数実行] ✅ スクリプト読み込み完了" -ForegroundColor Green

        # リクエストボディを取得
        $params = @{}
        $bodyJson = $WebEvent.Data
        if ($bodyJson) {
            # プロパティをハッシュテーブルに変換
            $bodyJson.PSObject.Properties | ForEach-Object {
                $params[$_.Name] = $_.Value
            }
            Write-Host "[ノード関数実行] パラメータ: $($params | ConvertTo-Json -Compress)" -ForegroundColor Gray
        }

        # 関数を実行
        Write-Host "[ノード関数実行] 🚀 関数 '$functionName' を実行中..." -ForegroundColor Yellow
        if ($params.Count -gt 0) {
            $code = & $functionName @params
        } else {
            $code = & $functionName
        }

        Write-Host "[ノード関数実行] ✅ 関数実行完了" -ForegroundColor Green

        # $codeが$nullの場合はキャンセルまたはエラー
        if ($null -eq $code) {
            Write-Host "[ノード関数実行] ⚠️ 関数が$nullを返しました（キャンセルまたはエラー）" -ForegroundColor Yellow
            $result = @{
                success = $false
                code = $null
                functionName = $functionName
                error = "関数が$nullを返しました（ユーザーキャンセルまたはエラー）"
            }
        } else {
            Write-Host "[ノード関数実行] 📤 生成されたコード (先頭200文字):" -ForegroundColor Gray
            $codePreview = $code.Substring(0, [Math]::Min(200, $code.Length))
            Write-Host $codePreview -ForegroundColor DarkGray

            $result = @{
                success = $true
                code = $code
                functionName = $functionName
            }
        }

        Write-PodeJsonResponse -Value $result -Depth 5

    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
            stackTrace = $_.ScriptStackTrace
        }
        Write-Host "[ノード関数実行エラー] $($_.Exception.Message)" -ForegroundColor Red
        Write-PodeJsonResponse -Value $errorResult -Depth 5
    }
}

# ------------------------------
# スクリプト編集ダイアログを表示
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/node/edit-script" -ScriptBlock {
    try {
        Write-Host "[スクリプト編集] リクエスト受信" -ForegroundColor Cyan

        $body = $WebEvent.Data
        $nodeId = $body.nodeId
        $nodeName = $body.nodeName
        $currentScript = $body.currentScript

        Write-Host "[スクリプト編集] ノードID: $nodeId, ノード名: $nodeName" -ForegroundColor Gray
        Write-Host "[スクリプト編集] 現在のスクリプト長: $($currentScript.Length)文字" -ForegroundColor Gray
        Write-Host "[スクリプト編集] 現在のスクリプト内容: [$currentScript]" -ForegroundColor Gray

        # ✅ 修正: JSON読み込み後、LF(\n) を CRLF(\r\n) に変換
        # ConvertFrom-Jsonは既に\nを実際のLF文字に変換しているため、LF→CRLFの変換が必要
        if ($currentScript) {
            Write-Host "[スクリプト編集] 🔧 改行文字の正規化を開始（LF → CRLF）..." -ForegroundColor Yellow
            $originalLength = $currentScript.Length
            # LF(\n)のみをCRLF(\r\n)に変換（既にCRLFの場合は変更なし）
            # まず既存のCRLFをプレースホルダーに置換し、LFをCRLFに変換してから戻す
            $currentScript = $currentScript -replace "`r`n", "<<CRLF>>" -replace "`n", "`r`n" -replace "<<CRLF>>", "`r`n"
            $newLength = $currentScript.Length
            if ($newLength -ne $originalLength) {
                Write-Host "[スクリプト編集] ✅ 改行を正規化しました: $originalLength 文字 → $newLength 文字" -ForegroundColor Green
            } else {
                Write-Host "[スクリプト編集] ✅ 改行の正規化は不要でした（既にCRLF）" -ForegroundColor Green
            }
        }

        # 汎用関数を読み込み（複数行テキストを編集）
        $汎用関数パス = Join-Path $using:RootDir "13_コードサブ汎用関数.ps1"
        if (Test-Path $汎用関数パス) {
            . $汎用関数パス
            Write-Host "[スクリプト編集] ✅ 汎用関数を読み込みました" -ForegroundColor Green
        } else {
            throw "汎用関数ファイルが見つかりません: $汎用関数パス"
        }

        # PowerShell Windows Formsダイアログを表示
        Write-Host "[スクリプト編集] 📝 編集ダイアログを表示します..." -ForegroundColor Cyan
        $editedScript = 複数行テキストを編集 -フォームタイトル "スクリプト編集 - $nodeName" -ラベルテキスト "スクリプトを編集してください:" -初期テキスト $currentScript

        if ($null -eq $editedScript) {
            # キャンセルされた
            Write-Host "[スクリプト編集] ⚠️ ユーザーがキャンセルしました" -ForegroundColor Yellow
            $result = @{
                success = $false
                cancelled = $true
                message = "編集がキャンセルされました"
            }
        } else {
            # 編集成功
            Write-Host "[スクリプト編集] ✅ 編集完了（長さ: $($editedScript.Length)文字）" -ForegroundColor Green
            $result = @{
                success = $true
                cancelled = $false
                newScript = $editedScript
            }
        }

        Write-PodeJsonResponse -Value $result -Depth 5

    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
            stackTrace = $_.ScriptStackTrace
        }
        Write-Host "[スクリプト編集エラー] $($_.Exception.Message)" -ForegroundColor Red
        Write-PodeJsonResponse -Value $errorResult -Depth 5
    }
}

# ------------------------------
# ノード設定ダイアログを表示
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/node/settings" -ScriptBlock {
    try {
        Write-Host "[ノード設定] リクエスト受信" -ForegroundColor Cyan

        $body = $WebEvent.Data

        # ノード情報をハッシュテーブルに変換
        $ノード情報 = @{
            id = $body.nodeId
            text = $body.nodeName
            color = $body.color
            width = $body.width
            height = $body.height
            x = $body.x
            y = $body.y
            script = $body.script
            処理番号 = $body.処理番号
        }

        # カスタムフィールド
        if ($body.conditionExpression) {
            $ノード情報.conditionExpression = $body.conditionExpression
        }
        if ($body.loopCount) {
            $ノード情報.loopCount = $body.loopCount
        }
        if ($body.loopVariable) {
            $ノード情報.loopVariable = $body.loopVariable
        }

        Write-Host "[ノード設定] ノードID: $($ノード情報.id), 処理番号: $($ノード情報.処理番号)" -ForegroundColor Gray

        # 汎用関数を読み込み（ノード設定を編集）
        $汎用関数パス = Join-Path $using:RootDir "13_コードサブ汎用関数.ps1"
        if (Test-Path $汎用関数パス) {
            . $汎用関数パス
            Write-Host "[ノード設定] ✅ 汎用関数を読み込みました" -ForegroundColor Green
        } else {
            throw "汎用関数ファイルが見つかりません: $汎用関数パス"
        }

        # PowerShell Windows Formsダイアログを表示
        Write-Host "[ノード設定] 📝 設定ダイアログを表示します..." -ForegroundColor Cyan
        $編集結果 = ノード設定を編集 -ノード情報 $ノード情報

        if ($null -eq $編集結果) {
            # キャンセルされた
            Write-Host "[ノード設定] ⚠️ ユーザーがキャンセルしました" -ForegroundColor Yellow
            $result = @{
                success = $false
                cancelled = $true
                message = "設定がキャンセルされました"
            }
        } else {
            # 編集成功
            Write-Host "[ノード設定] ✅ 編集完了" -ForegroundColor Green
            $result = @{
                success = $true
                cancelled = $false
                settings = $編集結果
            }
        }

        Write-PodeJsonResponse -Value $result -Depth 5

    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
            stackTrace = $_.ScriptStackTrace
        }
        Write-Host "[ノード設定エラー] $($_.Exception.Message)" -ForegroundColor Red
        Write-PodeJsonResponse -Value $errorResult -Depth 5
    }
}

# ------------------------------
# ブラウザコンソールログを受信
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/browser-logs" -ScriptBlock {
    try {
        $body = $WebEvent.Data

        # ログディレクトリの確認
        $logDir = Join-Path $using:RootDir "logs"
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }

        # ブラウザコンソールログファイル名（日付ごと）
        $dateStr = Get-Date -Format "yyyyMMdd"
        $browserLogFile = Join-Path $logDir "browser-console_$dateStr.log"

        # ログエントリを整形
        $logEntries = $body.logs | ForEach-Object {
            $timestamp = $_.timestamp
            $level = $_.level.ToUpper()
            $message = $_.message
            "[$timestamp] [$level] $message"
        }

        # ファイルに追記（UTF-8 BOMなし）
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        $existingContent = ""
        if (Test-Path $browserLogFile) {
            $existingContent = [System.IO.File]::ReadAllText($browserLogFile, $utf8NoBom)
        }

        $newContent = $existingContent + ($logEntries -join "`r`n") + "`r`n"
        [System.IO.File]::WriteAllText($browserLogFile, $newContent, $utf8NoBom)

        # 成功レスポンス
        $result = @{
            success = $true
            logCount = $body.logs.Count
            logFile = $browserLogFile
        }
        Write-PodeJsonResponse -Value $result

    } catch {
        Write-Host "[ブラウザログAPI] エラー: $($_.Exception.Message)" -ForegroundColor Red
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# ブラウザからのコントロールログを受信
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/control-log" -ScriptBlock {
    try {
        $body = $WebEvent.Data
        $message = $body.message

        # コントロールログに記録
        Write-ControlLog $message

        # 成功レスポンス
        $result = @{
            success = $true
            message = "ログを記録しました"
        }
        Write-PodeJsonResponse -Value $result

    } catch {
        Write-Host "[コントロールログAPI] エラー: $($_.Exception.Message)" -ForegroundColor Red
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ------------------------------
# 静的ファイル配信
# ------------------------------

# ルートパス "/" - index-legacy.htmlを提供
Add-PodeRoute -Method Get -Path "/" -ScriptBlock {
    $uiPath = $using:UiPath
    $indexPath = Join-Path $uiPath "index-legacy.html"
    if (Test-Path $indexPath) {
        $content = Get-Content $indexPath -Raw -Encoding UTF8
        Set-PodeHeader -Name "Content-Type" -Value "text/html; charset=utf-8"
        Write-PodeTextResponse -Value $content
    } else {
        Set-PodeResponseStatus -Code 404
        Write-PodeTextResponse -Value "index-legacy.html not found"
    }
}

# index-legacy.html
Add-PodeRoute -Method Get -Path "/index-legacy.html" -ScriptBlock {
    $uiPath = $using:UiPath
    $indexPath = Join-Path $uiPath "index-legacy.html"
    if (Test-Path $indexPath) {
        $content = Get-Content $indexPath -Raw -Encoding UTF8
        Set-PodeHeader -Name "Content-Type" -Value "text/html; charset=utf-8"
        Write-PodeTextResponse -Value $content
    } else {
        Set-PodeResponseStatus -Code 404
        Write-PodeTextResponse -Value "index-legacy.html not found"
    }
}

# style-legacy.css
Add-PodeRoute -Method Get -Path "/style-legacy.css" -ScriptBlock {
    $uiPath = $using:UiPath
    $cssPath = Join-Path $uiPath "style-legacy.css"
    if (Test-Path $cssPath) {
        $content = Get-Content $cssPath -Raw -Encoding UTF8
        Set-PodeHeader -Name "Content-Type" -Value "text/css; charset=utf-8"
        Write-PodeTextResponse -Value $content
    } else {
        Set-PodeResponseStatus -Code 404
        Write-PodeTextResponse -Value "style-legacy.css not found"
    }
}

# app-legacy.js
Add-PodeRoute -Method Get -Path "/app-legacy.js" -ScriptBlock {
    $uiPath = $using:UiPath
    $jsPath = Join-Path $uiPath "app-legacy.js"
    if (Test-Path $jsPath) {
        $content = Get-Content $jsPath -Raw -Encoding UTF8
        Set-PodeHeader -Name "Content-Type" -Value "application/javascript; charset=utf-8"
        Write-PodeTextResponse -Value $content
    } else {
        Set-PodeResponseStatus -Code 404
        Write-PodeTextResponse -Value "app-legacy.js not found"
    }
}

# layer-detail.html
Add-PodeRoute -Method Get -Path "/layer-detail.html" -ScriptBlock {
    $uiPath = $using:UiPath
    $htmlPath = Join-Path $uiPath "layer-detail.html"
    if (Test-Path $htmlPath) {
        $content = Get-Content $htmlPath -Raw -Encoding UTF8
        Set-PodeHeader -Name "Content-Type" -Value "text/html; charset=utf-8"
        Write-PodeTextResponse -Value $content
    } else {
        Set-PodeResponseStatus -Code 404
        Write-PodeTextResponse -Value "layer-detail.html not found"
    }
}

# layer-detail.js
Add-PodeRoute -Method Get -Path "/layer-detail.js" -ScriptBlock {
    $uiPath = $using:UiPath
    $jsPath = Join-Path $uiPath "layer-detail.js"
    if (Test-Path $jsPath) {
        $content = Get-Content $jsPath -Raw -Encoding UTF8
        Set-PodeHeader -Name "Content-Type" -Value "application/javascript; charset=utf-8"
        Write-PodeTextResponse -Value $content
    } else {
        Set-PodeResponseStatus -Code 404
        Write-PodeTextResponse -Value "layer-detail.js not found"
    }
}

# modal-functions.js
Add-PodeRoute -Method Get -Path "/modal-functions.js" -ScriptBlock {
    $uiPath = $using:UiPath
    $jsPath = Join-Path $uiPath "modal-functions.js"
    if (Test-Path $jsPath) {
        $content = Get-Content $jsPath -Raw -Encoding UTF8
        Set-PodeHeader -Name "Content-Type" -Value "application/javascript; charset=utf-8"
        Write-PodeTextResponse -Value $content
    } else {
        Set-PodeResponseStatus -Code 404
        Write-PodeTextResponse -Value "modal-functions.js not found"
    }
}

# ボタン設定.json (英語エイリアス: /button-settings.json)
Add-PodeRoute -Method Get -Path "/button-settings.json" -ScriptBlock {
    $rootDir = $using:RootDir
    $jsonPath = Join-Path $rootDir "ボタン設定.json"
    if (Test-Path $jsonPath) {
        $content = Get-Content $jsonPath -Raw -Encoding UTF8
        Set-PodeHeader -Name "Content-Type" -Value "application/json; charset=utf-8"
        Write-PodeTextResponse -Value $content
    } else {
        Set-PodeResponseStatus -Code 404
        $errorResult = @{ error = "ボタン設定.json not found" }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ボタン設定.json (日本語パス)
Add-PodeRoute -Method Get -Path "/ボタン設定.json" -ScriptBlock {
    $rootDir = $using:RootDir
    $jsonPath = Join-Path $rootDir "ボタン設定.json"
    if (Test-Path $jsonPath) {
        $content = Get-Content $jsonPath -Raw -Encoding UTF8
        Set-PodeHeader -Name "Content-Type" -Value "application/json; charset=utf-8"
        Write-PodeTextResponse -Value $content
    } else {
        Set-PodeResponseStatus -Code 404
        $errorResult = @{ error = "ボタン設定.json not found" }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ==============================================================================
# 変換完了
# ==============================================================================
