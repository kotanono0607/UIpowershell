# ==============================================================================
# Podeルート定義（自動変換）
# 元ファイル: api-server-v2.ps1
# 変換日: 2025-11-16
# 変換ルート数: 50個
# ==============================================================================

# ==============================================================================
# v2ファイルとAdapterファイルをルート定義スコープ内で読み込み
# （Podeのスレッド分離問題を回避するため）
# ==============================================================================


# RootDirを取得（Get-PodeStateから）
$RootDir = Get-PodeState -Name 'RootDir'
$adapterDir = Split-Path -Parent $PSCommandPath

# Phase 2 v2ファイルを読み込み
$v2FilesToLoad = @(
    "00_共通ユーティリティ_JSON操作.ps1",
    "09_変数機能_コードID管理JSON.ps1",
    "12_コードメイン_コード本文_v2.ps1",
    "10_変数機能_変数管理UI_v2.ps1",
    "07_メインF機能_ツールバー作成_v2.ps1",
    "08_メインF機能_メインボタン処理_v2.ps1",
    "02-6_削除処理_v2.ps1",
    "02-2_ネスト規制バリデーション_v2.ps1",
    "16_スナップショット機能.ps1",
    "17_操作履歴管理.ps1"
)

# 読み込み前の関数リストを取得
$beforeFunctions = Get-Command -CommandType Function -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name

foreach ($file in $v2FilesToLoad) {
    $filePath = Join-Path $RootDir $file
    if (Test-Path $filePath) {
        . $filePath
    } else {
    }
}

# Phase 3 Adapterファイルを読み込み
$adapterFiles = @("state-manager.ps1", "node-operations.ps1")

foreach ($file in $adapterFiles) {
    $filePath = Join-Path $adapterDir $file
    if (Test-Path $filePath) {
        . $filePath
    } else {
    }
}

# 読み込み後の関数リストを取得し、新しい関数をグローバル化
$afterFunctions = Get-Command -CommandType Function -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
$newFunctions = $afterFunctions | Where-Object { $_ -notin $beforeFunctions }


if ($newFunctions.Count -gt 0) {
    $exportCount = 0
    $exportedFunctions = @()
    foreach ($funcName in $newFunctions) {
        if (Test-Path "function:$funcName") {
            $funcDef = Get-Content "function:$funcName"
            Set-Item -Path "function:global:$funcName" -Value $funcDef -Force
            $exportCount++
            $exportedFunctions += $funcName
        }
    }

} else {
}

# ==============================================================================
# 【重要】Podeランスペース分離問題の解決策
# ==============================================================================
# 問題: Add-PodeRoute -ScriptBlock は独立したランスペースで実行され、
#       親スコープのグローバル関数にアクセスできない
#
# 解決策: 各スクリプトブロック内で必要なファイルをドットソースする
#         パフォーマンス最適化のため、既に読み込まれているかチェック
# ==============================================================================

# 共通初期化コード（文字列として定義）
$script:InitCode = @'
# v2関数の初期化（未読み込みの場合のみ）
if (-not (Get-Command Get-VariableList_v2 -ErrorAction SilentlyContinue)) {
    $RootDir = Get-PodeState -Name 'RootDir'
    $adapterDir = Get-PodeState -Name 'AdapterDir'

    . (Join-Path $RootDir "12_コードメイン_コード本文_v2.ps1")
        . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
    . (Join-Path $RootDir "10_変数機能_変数管理UI_v2.ps1")
    . (Join-Path $RootDir "07_メインF機能_ツールバー作成_v2.ps1")
    . (Join-Path $RootDir "08_メインF機能_メインボタン処理_v2.ps1")
    . (Join-Path $RootDir "02-6_削除処理_v2.ps1")
    . (Join-Path $RootDir "02-2_ネスト規制バリデーション_v2.ps1")
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
    . (Join-Path $adapterDir "state-manager.ps1")
    . (Join-Path $adapterDir "node-operations.ps1")
}
'@

# AdapterDirをPode Stateに保存（各スクリプトブロックからアクセス可能にする）
$adapterDir = Split-Path -Parent $PSCommandPath
Set-PodeState -Name 'AdapterDir' -Value $adapterDir


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

        # PSCustomObject を hashtable に変換
        $nodeHashtable = @{}
        foreach ($prop in $body.PSObject.Properties) {
            $nodeHashtable[$prop.Name] = $prop.Value
        }

        # idが存在しない場合は新規生成
        if (-not $nodeHashtable.ContainsKey('id') -or -not $nodeHashtable['id']) {

            # タイムスタンプベースのユニークIDを生成
            $timestamp = [DateTime]::Now.ToString("yyyyMMddHHmmssfff")
            $random = Get-Random -Minimum 100 -Maximum 999
            $nodeHashtable['id'] = "node-$timestamp-$random"

        }

        # nameが存在しない場合は、idから生成
        if (-not $nodeHashtable.ContainsKey('name') -or -not $nodeHashtable['name']) {
            $nodeHashtable['name'] = $nodeHashtable['id']
        }


        $result = Add-Node -Node $nodeHashtable

        if ($result.success) {
        } else {
        }

        Write-PodeJsonResponse -Value $result
    } catch {
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
# ノードをコピー（新しいIDで複製）
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/nodes/copy" -ScriptBlock {
    try {

        $body = $WebEvent.Data

        $originalNodeId = $body.nodeId

        if (-not $originalNodeId) {
            Set-PodeResponseStatus -Code 400
            $errorResult = @{
                success = $false
                error = "nodeId パラメータが必要です"
            }
            Write-PodeJsonResponse -Value $errorResult
            return
        }


        # 元のノードを取得（直接検索）

        # Get-AllNodes を使用してすべてのノードを取得
        $allNodesResult = Get-AllNodes
        if (-not $allNodesResult -or -not $allNodesResult.success) {
            Set-PodeResponseStatus -Code 500
            $errorResult = @{
                success = $false
                error = "ノード一覧の取得に失敗しました"
            }
            Write-PodeJsonResponse -Value $errorResult
            return
        }

        $allNodes = $allNodesResult.nodes
        $nodeCount = $allNodes.Count

        if ($nodeCount -gt 0) {
            $nodeIds = $allNodes | Select-Object -First 5 | ForEach-Object { $_.id }
        }

        # 元のノードを検索
        $sourceNode = $allNodes | Where-Object { $_.id -eq $originalNodeId }

        if (-not $sourceNode) {
            Set-PodeResponseStatus -Code 404
            $errorResult = @{
                success = $false
                error = "ノードID $originalNodeId が見つかりません (現在のノード数: $nodeCount)"
            }
            Write-PodeJsonResponse -Value $errorResult
            return
        }


        # 新しいIDを生成
        $newId = IDを自動生成する

        if (-not $newId) {
            Set-PodeResponseStatus -Code 500
            $errorResult = @{
                success = $false
                error = "新しいIDの生成に失敗しました"
            }
            Write-PodeJsonResponse -Value $errorResult
            return
        }

        $newNodeId = "$newId-1"

        # Y座標をオフセット（30px下に配置）
        $offsetY = 30
        $originalY = [int]$sourceNode.y
        $newY = $originalY + $offsetY

        # 新しいノードを作成（元のノードのプロパティをコピー）

        # hashtableとして新しいノードを作成
        $newNode = @{
            id = $newNodeId
            name = $sourceNode.name
            text = $sourceNode.text
            color = $sourceNode.color
            layer = $sourceNode.layer
            y = $newY
            x = $sourceNode.x
            width = $sourceNode.width
            height = $sourceNode.height
            groupId = $sourceNode.groupId
            処理番号 = $sourceNode.処理番号
            script = $sourceNode.script
            関数名 = $sourceNode.関数名
        }


        # コードエントリもコピー（元のノードにコードがある場合）
        try {
            $元のコード = IDでエントリを取得 -ID $originalNodeId
            if ($元のコード) {
                $コード追加結果 = エントリを追加_指定ID -文字列 $元のコード -ID $newNodeId
            }
        } catch {
            # エラーを無視（意図的）
        }

        # ノードを追加
        $result = Add-Node -Node $newNode

        if ($result.success) {

            $response = @{
                success = $true
                message = "ノードをコピーしました"
                originalNodeId = $originalNodeId
                newNodeId = $newNodeId
                newNode = $newNode
            }
            Write-PodeJsonResponse -Value $response
        } else {
            throw "ノードの追加に失敗しました: $($result.message)"
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
# すべてのノードを削除
# ------------------------------
Add-PodeRoute -Method Delete -Path "/api/nodes/all" -ScriptBlock {
    # v2関数の初期化（未読み込みの場合のみ）
    if (-not (Get-Command すべてのノードを削除_v2 -ErrorAction SilentlyContinue)) {
        $RootDir = Get-PodeState -Name 'RootDir'
        $adapterDir = Get-PodeState -Name 'AdapterDir'
        . (Join-Path $RootDir "12_コードメイン_コード本文_v2.ps1")
        . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
        . (Join-Path $RootDir "10_変数機能_変数管理UI_v2.ps1")
        . (Join-Path $RootDir "07_メインF機能_ツールバー作成_v2.ps1")
        . (Join-Path $RootDir "08_メインF機能_メインボタン処理_v2.ps1")
        . (Join-Path $RootDir "02-6_削除処理_v2.ps1")
        . (Join-Path $RootDir "02-2_ネスト規制バリデーション_v2.ps1")
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
        . (Join-Path $adapterDir "state-manager.ps1")
        . (Join-Path $adapterDir "node-operations.ps1")
    }


    try {

        $body = $WebEvent.Data

        # $body.nodesのnullチェック
        $nodes = $body.nodes
        if ($null -eq $nodes) {
            $nodes = @()
        } else {
        }


        # 最初の数個のノードIDを表示
        if ($nodes.Count -gt 0) {
            $sampleIds = $nodes | Select-Object -First 3 | ForEach-Object { $_.id }
        }

        # ノード配列が空でも関数を呼び出す（関数内で空チェックあり）
        $result = すべてのノードを削除_v2 -ノード配列 $nodes


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
# ノード削除（単一）
# ------------------------------
Add-PodeRoute -Method Delete -Path "/api/nodes/:id" -ScriptBlock {
    # v2関数の初期化（未読み込みの場合のみ）
    if (-not (Get-Command ノード削除_v2 -ErrorAction SilentlyContinue)) {
        $RootDir = Get-PodeState -Name 'RootDir'
        $adapterDir = Get-PodeState -Name 'AdapterDir'
        . (Join-Path $RootDir "12_コードメイン_コード本文_v2.ps1")
        . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
        . (Join-Path $RootDir "10_変数機能_変数管理UI_v2.ps1")
        . (Join-Path $RootDir "07_メインF機能_ツールバー作成_v2.ps1")
        . (Join-Path $RootDir "08_メインF機能_メインボタン処理_v2.ps1")
        . (Join-Path $RootDir "02-6_削除処理_v2.ps1")
        . (Join-Path $RootDir "02-2_ネスト規制バリデーション_v2.ps1")
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
        . (Join-Path $adapterDir "state-manager.ps1")
        . (Join-Path $adapterDir "node-operations.ps1")
    }

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
    # v2関数の初期化（未読み込みの場合のみ）
    if (-not (Get-Command Get-VariableList_v2 -ErrorAction SilentlyContinue)) {
        $RootDir = Get-PodeState -Name 'RootDir'
        $adapterDir = Get-PodeState -Name 'AdapterDir'
        . (Join-Path $RootDir "12_コードメイン_コード本文_v2.ps1")
        . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
        . (Join-Path $RootDir "10_変数機能_変数管理UI_v2.ps1")
        . (Join-Path $RootDir "07_メインF機能_ツールバー作成_v2.ps1")
        . (Join-Path $RootDir "08_メインF機能_メインボタン処理_v2.ps1")
        . (Join-Path $RootDir "02-6_削除処理_v2.ps1")
        . (Join-Path $RootDir "02-2_ネスト規制バリデーション_v2.ps1")
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
        . (Join-Path $adapterDir "state-manager.ps1")
        . (Join-Path $adapterDir "node-operations.ps1")
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    $result = Get-VariableList_v2
    Write-PodeJsonResponse -Value $result

    $sw.Stop()
}

# ------------------------------
# 変数取得（名前指定）
# ------------------------------
Add-PodeRoute -Method Get -Path "/api/variables/:name" -ScriptBlock {
    # v2関数の初期化（未読み込みの場合のみ）
    if (-not (Get-Command Get-Variable_v2 -ErrorAction SilentlyContinue)) {
        $RootDir = Get-PodeState -Name 'RootDir'
        $adapterDir = Get-PodeState -Name 'AdapterDir'
        . (Join-Path $RootDir "12_コードメイン_コード本文_v2.ps1")
        . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
        . (Join-Path $RootDir "10_変数機能_変数管理UI_v2.ps1")
        . (Join-Path $RootDir "07_メインF機能_ツールバー作成_v2.ps1")
        . (Join-Path $RootDir "08_メインF機能_メインボタン処理_v2.ps1")
        . (Join-Path $RootDir "02-6_削除処理_v2.ps1")
        . (Join-Path $RootDir "02-2_ネスト規制バリデーション_v2.ps1")
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
        . (Join-Path $adapterDir "state-manager.ps1")
        . (Join-Path $adapterDir "node-operations.ps1")
    }

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
    # v2関数の初期化（未読み込みの場合のみ）
    if (-not (Get-Command Add-Variable_v2 -ErrorAction SilentlyContinue)) {
        $RootDir = Get-PodeState -Name 'RootDir'
        $adapterDir = Get-PodeState -Name 'AdapterDir'
        . (Join-Path $RootDir "12_コードメイン_コード本文_v2.ps1")
        . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
        . (Join-Path $RootDir "10_変数機能_変数管理UI_v2.ps1")
        . (Join-Path $RootDir "07_メインF機能_ツールバー作成_v2.ps1")
        . (Join-Path $RootDir "08_メインF機能_メインボタン処理_v2.ps1")
        . (Join-Path $RootDir "02-6_削除処理_v2.ps1")
        . (Join-Path $RootDir "02-2_ネスト規制バリデーション_v2.ps1")
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
        . (Join-Path $adapterDir "state-manager.ps1")
        . (Join-Path $adapterDir "node-operations.ps1")
    }

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
    # v2関数の初期化（未読み込みの場合のみ）
    if (-not (Get-Command Update-Variable_v2 -ErrorAction SilentlyContinue)) {
        $RootDir = Get-PodeState -Name 'RootDir'
        $adapterDir = Get-PodeState -Name 'AdapterDir'
        . (Join-Path $RootDir "12_コードメイン_コード本文_v2.ps1")
        . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
        . (Join-Path $RootDir "10_変数機能_変数管理UI_v2.ps1")
        . (Join-Path $RootDir "07_メインF機能_ツールバー作成_v2.ps1")
        . (Join-Path $RootDir "08_メインF機能_メインボタン処理_v2.ps1")
        . (Join-Path $RootDir "02-6_削除処理_v2.ps1")
        . (Join-Path $RootDir "02-2_ネスト規制バリデーション_v2.ps1")
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
        . (Join-Path $adapterDir "state-manager.ps1")
        . (Join-Path $adapterDir "node-operations.ps1")
    }

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
    # v2関数の初期化（未読み込みの場合のみ）
    if (-not (Get-Command Remove-Variable_v2 -ErrorAction SilentlyContinue)) {
        $RootDir = Get-PodeState -Name 'RootDir'
        $adapterDir = Get-PodeState -Name 'AdapterDir'
        . (Join-Path $RootDir "12_コードメイン_コード本文_v2.ps1")
        . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
        . (Join-Path $RootDir "10_変数機能_変数管理UI_v2.ps1")
        . (Join-Path $RootDir "07_メインF機能_ツールバー作成_v2.ps1")
        . (Join-Path $RootDir "08_メインF機能_メインボタン処理_v2.ps1")
        . (Join-Path $RootDir "02-6_削除処理_v2.ps1")
        . (Join-Path $RootDir "02-2_ネスト規制バリデーション_v2.ps1")
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
        . (Join-Path $adapterDir "state-manager.ps1")
        . (Join-Path $adapterDir "node-operations.ps1")
    }

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
    # v2関数の初期化（未読み込みの場合のみ）
    if (-not (Get-Command Get-VariableList_v2 -ErrorAction SilentlyContinue)) {
        $RootDir = Get-PodeState -Name 'RootDir'
        $adapterDir = Get-PodeState -Name 'AdapterDir'
        . (Join-Path $RootDir "12_コードメイン_コード本文_v2.ps1")
        . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
        . (Join-Path $RootDir "10_変数機能_変数管理UI_v2.ps1")
        . (Join-Path $RootDir "07_メインF機能_ツールバー作成_v2.ps1")
        . (Join-Path $RootDir "08_メインF機能_メインボタン処理_v2.ps1")
        . (Join-Path $RootDir "02-6_削除処理_v2.ps1")
        . (Join-Path $RootDir "02-2_ネスト規制バリデーション_v2.ps1")
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
        . (Join-Path $adapterDir "state-manager.ps1")
        . (Join-Path $adapterDir "node-operations.ps1")
    }

    try {

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


        # 元の変数リストを保存（比較用）
        $元の変数リスト = $変数一覧結果.variables

        # 共通関数ファイルを読み込み
        . (Join-Path (Get-PodeState -Name 'RootDir') "13_コードサブ汎用関数.ps1")

        # PowerShell Windows Forms ダイアログを表示
        $ダイアログ結果 = 変数管理を表示 -変数リスト $変数一覧結果.variables

        if ($null -eq $ダイアログ結果) {
            $result = @{
                success = $false
                cancelled = $true
                message = "変数管理がキャンセルされました"
            }
            Write-PodeJsonResponse -Value $result -Depth 5
            return
        }


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
                    $updateResult = Update-Variable_v2 -Name $var.name -Value $var.value
                    if ($updateResult.success) {
                        $変更カウント.更新++
                    }
                }
            } else {
                # 新しい変数
                $addResult = Add-Variable_v2 -Name $var.name -Value $var.value -Type $var.type
                if ($addResult.success) {
                    $変更カウント.追加++
                }
            }
        }

        # 削除を検出
        foreach ($var in $元の変数リスト) {
            if (-not $新しい変数マップ.ContainsKey($var.name)) {
                $removeResult = Remove-Variable_v2 -Name $var.name
                if ($removeResult.success) {
                    $変更カウント.削除++
                }
            }
        }


        # 変更を永続化
        $exportResult = Export-VariablesToJson_v2

        # 成功レスポンス
        $result = @{
            success = $true
            cancelled = $false
            message = "変数管理が完了しました"
            changes = $変更カウント
        }

        Write-PodeJsonResponse -Value $result -Depth 5

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
# メニュー構造取得
# ------------------------------
Add-PodeRoute -Method Get -Path "/api/menu/structure" -ScriptBlock {
    # v2関数の初期化（未読み込みの場合のみ）
    if (-not (Get-Command Get-MenuStructure_v2 -ErrorAction SilentlyContinue)) {
        $RootDir = Get-PodeState -Name 'RootDir'
        $adapterDir = Get-PodeState -Name 'AdapterDir'
        . (Join-Path $RootDir "12_コードメイン_コード本文_v2.ps1")
        . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
        . (Join-Path $RootDir "10_変数機能_変数管理UI_v2.ps1")
        . (Join-Path $RootDir "07_メインF機能_ツールバー作成_v2.ps1")
        . (Join-Path $RootDir "08_メインF機能_メインボタン処理_v2.ps1")
        . (Join-Path $RootDir "02-6_削除処理_v2.ps1")
        . (Join-Path $RootDir "02-2_ネスト規制バリデーション_v2.ps1")
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
        . (Join-Path $adapterDir "state-manager.ps1")
        . (Join-Path $adapterDir "node-operations.ps1")
    }

    $result = Get-MenuStructure_v2
    Write-PodeJsonResponse -Value $result
}

# ------------------------------
# メニューアクション実行
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/menu/action/:actionId" -ScriptBlock {
    # v2関数の初期化（未読み込みの場合のみ）
    if (-not (Get-Command Execute-MenuAction_v2 -ErrorAction SilentlyContinue)) {
        $RootDir = Get-PodeState -Name 'RootDir'
        $adapterDir = Get-PodeState -Name 'AdapterDir'
        . (Join-Path $RootDir "12_コードメイン_コード本文_v2.ps1")
        . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
        . (Join-Path $RootDir "10_変数機能_変数管理UI_v2.ps1")
        . (Join-Path $RootDir "07_メインF機能_ツールバー作成_v2.ps1")
        . (Join-Path $RootDir "08_メインF機能_メインボタン処理_v2.ps1")
        . (Join-Path $RootDir "02-6_削除処理_v2.ps1")
        . (Join-Path $RootDir "02-2_ネスト規制バリデーション_v2.ps1")
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
        . (Join-Path $adapterDir "state-manager.ps1")
        . (Join-Path $adapterDir "node-operations.ps1")
    }

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
    # v2関数の初期化（未読み込みの場合のみ）
    if (-not (Get-Command 実行イベント_v2 -ErrorAction SilentlyContinue)) {
        $RootDir = Get-PodeState -Name 'RootDir'
        $adapterDir = Get-PodeState -Name 'AdapterDir'
        . (Join-Path $RootDir "12_コードメイン_コード本文_v2.ps1")
        . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
        . (Join-Path $RootDir "10_変数機能_変数管理UI_v2.ps1")
        . (Join-Path $RootDir "07_メインF機能_ツールバー作成_v2.ps1")
        . (Join-Path $RootDir "08_メインF機能_メインボタン処理_v2.ps1")
        . (Join-Path $RootDir "02-6_削除処理_v2.ps1")
        . (Join-Path $RootDir "02-2_ネスト規制バリデーション_v2.ps1")
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
        . (Join-Path $adapterDir "state-manager.ps1")
        . (Join-Path $adapterDir "node-operations.ps1")
    }

    try {
        # デバッグモード（環境変数で制御）


        # $global:folderPath と $global:jsonパス を設定（IDでエントリを取得 で使用）
        # メイン.json からフォルダパスを読み取る
        $RootDir = Get-PodeState -Name 'RootDir'
        $mainJsonPath = Join-Path $RootDir "03_history\メイン.json"
        if (Test-Path $mainJsonPath) {
            try {
                $mainContent = Get-Content -Path $mainJsonPath -Raw -Encoding UTF8
                $mainData = $mainContent | ConvertFrom-Json
                # 相対パス対応: フォルダ名からフルパスを構築
                $folderName = $mainData.フォルダパス
                $global:folderPath = Join-Path $RootDir "03_history\$folderName"
                $global:jsonパス = Join-Path $global:folderPath "コード.json"
            } catch {
                # エラーを無視（意図的）
            }
        } else {
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

        # 全レイヤーのノード配列（関数ノードのscript取得用）
        if ($body.allNodes) {
            $global:全レイヤーノード配列 = @($body.allNodes)
        } else {
            $global:全レイヤーノード配列 = $nodeArray
        }

        # OutputPathとOpenFileのデフォルト値設定
        $outputPath = if ($body.outputPath) { $body.outputPath } else { $null }
        $openFile = if ($body.PSObject.Properties.Name -contains 'openFile') { [bool]$body.openFile } else { $false }


        $result = 実行イベント_v2 `
            -ノード配列 $nodeArray `
            -OutputPath $outputPath `
            -OpenFile $openFile


        Write-PodeJsonResponse -Value $result

    } catch {

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

        $body = $WebEvent.Data

        # 生成結果を構築
        $生成結果 = @{
            code = $body.code
            nodeCount = $body.nodeCount
            outputPath = $body.outputPath
            timestamp = if ($body.timestamp) { $body.timestamp } else { Get-Date -Format "yyyy/MM/dd HH:mm:ss" }
        }


        # 共通関数ファイルを読み込み
        . (Join-Path (Get-PodeState -Name 'RootDir') "13_コードサブ汎用関数.ps1")

        # PowerShell Windows Forms ダイアログを表示
        $ダイアログ結果 = コード結果を表示 -生成結果 $生成結果


        # 成功レスポンス
        $result = @{
            success = $true
            message = "コード結果ダイアログを表示しました"
        }

        Write-PodeJsonResponse -Value $result -Depth 5

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

        $RootDir = Get-PodeState -Name 'RootDir'

        # 汎用関数を読み込み（13_コードサブ汎用関数.ps1）
        $汎用関数パス = Join-Path $RootDir "13_コードサブ汎用関数.ps1"
        if (Test-Path $汎用関数パス) {
            . $汎用関数パス
        }

        # win32API.psm1を読み込み（マウス・キーボード操作等）
        $win32ApiPath = Join-Path $RootDir "win32API.psm1"
        if (Test-Path $win32ApiPath) {
            Import-Module $win32ApiPath -Force -ErrorAction SilentlyContinue
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
    # v2関数の初期化（未読み込みの場合のみ）
    if (-not (Get-Command フォルダ切替イベント_v2 -ErrorAction SilentlyContinue)) {
        $RootDir = Get-PodeState -Name 'RootDir'
        $adapterDir = Get-PodeState -Name 'AdapterDir'
        . (Join-Path $RootDir "12_コードメイン_コード本文_v2.ps1")
        . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
        . (Join-Path $RootDir "10_変数機能_変数管理UI_v2.ps1")
        . (Join-Path $RootDir "07_メインF機能_ツールバー作成_v2.ps1")
        . (Join-Path $RootDir "08_メインF機能_メインボタン処理_v2.ps1")
        . (Join-Path $RootDir "02-6_削除処理_v2.ps1")
        . (Join-Path $RootDir "02-2_ネスト規制バリデーション_v2.ps1")
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
        . (Join-Path $adapterDir "state-manager.ps1")
        . (Join-Path $adapterDir "node-operations.ps1")
    }

    $result = フォルダ切替イベント_v2 -FolderName "list"
    Write-PodeJsonResponse -Value $result
}

# ------------------------------
# フォルダ作成
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/folders" -ScriptBlock {
    # v2関数の初期化（未読み込みの場合のみ）
    if (-not (Get-Command フォルダ作成イベント_v2 -ErrorAction SilentlyContinue)) {
        $RootDir = Get-PodeState -Name 'RootDir'
        $adapterDir = Get-PodeState -Name 'AdapterDir'
        . (Join-Path $RootDir "12_コードメイン_コード本文_v2.ps1")
        . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
        . (Join-Path $RootDir "10_変数機能_変数管理UI_v2.ps1")
        . (Join-Path $RootDir "07_メインF機能_ツールバー作成_v2.ps1")
        . (Join-Path $RootDir "08_メインF機能_メインボタン処理_v2.ps1")
        . (Join-Path $RootDir "02-6_削除処理_v2.ps1")
        . (Join-Path $RootDir "02-2_ネスト規制バリデーション_v2.ps1")
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
        . (Join-Path $adapterDir "state-manager.ps1")
        . (Join-Path $adapterDir "node-operations.ps1")
    }

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
    # v2関数の初期化（未読み込みの場合のみ）
    if (-not (Get-Command フォルダ切替イベント_v2 -ErrorAction SilentlyContinue)) {
        $RootDir = Get-PodeState -Name 'RootDir'
        $adapterDir = Get-PodeState -Name 'AdapterDir'
        . (Join-Path $RootDir "12_コードメイン_コード本文_v2.ps1")
        . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
        . (Join-Path $RootDir "10_変数機能_変数管理UI_v2.ps1")
        . (Join-Path $RootDir "07_メインF機能_ツールバー作成_v2.ps1")
        . (Join-Path $RootDir "08_メインF機能_メインボタン処理_v2.ps1")
        . (Join-Path $RootDir "02-6_削除処理_v2.ps1")
        . (Join-Path $RootDir "02-2_ネスト規制バリデーション_v2.ps1")
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
        . (Join-Path $adapterDir "state-manager.ps1")
        . (Join-Path $adapterDir "node-operations.ps1")
    }

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
    # v2関数の初期化（未読み込みの場合のみ）
    if (-not (Get-Command フォルダ切替イベント_v2 -ErrorAction SilentlyContinue)) {
        $RootDir = Get-PodeState -Name 'RootDir'
        $adapterDir = Get-PodeState -Name 'AdapterDir'
        . (Join-Path $RootDir "12_コードメイン_コード本文_v2.ps1")
        . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
        . (Join-Path $RootDir "10_変数機能_変数管理UI_v2.ps1")
        . (Join-Path $RootDir "07_メインF機能_ツールバー作成_v2.ps1")
        . (Join-Path $RootDir "08_メインF機能_メインボタン処理_v2.ps1")
        . (Join-Path $RootDir "02-6_削除処理_v2.ps1")
        . (Join-Path $RootDir "02-2_ネスト規制バリデーション_v2.ps1")
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
        . (Join-Path $adapterDir "state-manager.ps1")
        . (Join-Path $adapterDir "node-operations.ps1")
    }

    try {

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
        $rootDir = Get-PodeState -Name 'RootDir'
        $mainJsonPath = Join-Path $rootDir "03_history\メイン.json"
        $現在のフォルダ = ""

        if (Test-Path $mainJsonPath) {
            try {
                $content = Get-Content $mainJsonPath -Raw -Encoding UTF8
                $mainData = $content | ConvertFrom-Json
                # 相対パス対応: フォルダ名を直接取得
                $現在のフォルダ = $mainData.フォルダパス
            } catch {
                # エラーを無視（意図的）
            }
        }


        # 共通関数ファイルを読み込み
        . (Join-Path (Get-PodeState -Name 'RootDir') "13_コードサブ汎用関数.ps1")

        # PowerShell Windows Forms ダイアログを表示
        $ダイアログ結果 = フォルダ切替を表示 -フォルダリスト $フォルダリスト -現在のフォルダ $現在のフォルダ

        if ($null -eq $ダイアログ結果) {
            $result = @{
                success = $false
                cancelled = $true
                message = "フォルダ切替がキャンセルされました"
            }
            Write-PodeJsonResponse -Value $result -Depth 5
            return
        }


        # 新しいフォルダが作成された場合はAPI経由で作成
        if ($ダイアログ結果.newFolder) {
            $作成結果 = フォルダ作成イベント_v2 -FolderName $ダイアログ結果.newFolder
        }

        # 選択されたフォルダが現在のフォルダと異なる場合は切り替え
        if ($ダイアログ結果.folderName -ne $現在のフォルダ) {
            $切替結果 = フォルダ切替イベント_v2 -FolderName $ダイアログ結果.folderName

            if ($切替結果.success) {
            } else {
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
        $rootDir = Get-PodeState -Name 'RootDir'
        $mainJsonPath = Join-Path $rootDir "03_history\メイン.json"

        if (Test-Path $mainJsonPath) {
            $content = Get-Content $mainJsonPath -Raw -Encoding UTF8
            $mainData = $content | ConvertFrom-Json

            # 相対パス対応: フォルダ名からフルパスを構築
            $folderName = $mainData.フォルダパス
            $folderPath = Join-Path $rootDir "03_history\$folderName"

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
        $rootDir = Get-PodeState -Name 'RootDir'
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
            # v1.1.0: edges配列も含める
            $emptyMemory = @{
                "1" = @{ "構成" = @(); "edges" = @() }
                "2" = @{ "構成" = @(); "edges" = @() }
                "3" = @{ "構成" = @(); "edges" = @() }
                "4" = @{ "構成" = @(); "edges" = @() }
                "5" = @{ "構成" = @(); "edges" = @() }
                "6" = @{ "構成" = @(); "edges" = @() }
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

        $body = $WebEvent.Data

        $layerStructure = $body.layerStructure

        $rootDir = Get-PodeState -Name 'RootDir'
        $folderPath = Join-Path $rootDir "03_history\$folderName"
        $memoryPath = Join-Path $folderPath "memory.json"


        # フォルダが存在しない場合は作成
        if (-not (Test-Path $folderPath)) {
            New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
        } else {
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
                $nodeId = if ($node.id) { $node.id } else { "" }
                $nodeScript = if ($null -ne $node.script) { $node.script } else { "" }

                $構成 += [ordered]@{
                    ID = $nodeId
                    ボタン名 = $node.name
                    X座標 = if ($node.x) { $node.x } else { 10 }
                    Y座標 = $node.y
                    順番 = if ($node.順番) { $node.順番 } else { 1 }
                    ボタン色 = $node.color
                    テキスト = $node.text
                    処理番号 = if ($node.処理番号) { $node.処理番号 } else { "未設定" }
                    高さ = if ($node.height) { $node.height } else { 40 }
                    幅 = if ($node.width) { $node.width } else { 280 }
                    script = $nodeScript
                    GroupID = if ($node.groupId -ne $null -and $node.groupId -ne "") { $node.groupId } else { "" }
                }
                $totalNodes++
            }

            # v1.1.0: エッジデータも保存
            $layerEdges = $layerStructure."$i".edges
            if ($layerEdges -and $layerEdges.Count -gt 0) {
                $memoryData["$i"] = @{ "構成" = $構成; "edges" = $layerEdges }
            } else {
                $memoryData["$i"] = @{ "構成" = $構成 }
            }
        }


        # 履歴記録: 保存前の状態を取得
        $memoryBefore = $null
        if (Test-Path $memoryPath) {
            try {
                $memoryBeforeContent = Get-Content $memoryPath -Raw -Encoding UTF8
                $memoryBefore = $memoryBeforeContent | ConvertFrom-Json
            } catch {
                # エラーを無視（意図的）
            }
        }

        # JSON形式で保存
        $json = $memoryData | ConvertTo-Json -Depth 10

        # UTF-8 without BOMで保存（文字化け防止）
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($memoryPath, $json, $utf8NoBom)

        # 履歴記録: 保存後の状態を記録
        try {
            # 履歴管理関数の初期化（未読み込みの場合のみ）
            if (-not (Get-Command Record-Operation -ErrorAction SilentlyContinue)) {
                $RootDir = Get-PodeState -Name 'RootDir'
                . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
                . (Join-Path $RootDir "17_操作履歴管理.ps1")
            }

            Record-Operation `
                -FolderPath $folderPath `
                -OperationType "NodeUpdate" `
                -Description "ノード配置を更新 ($totalNodes ノード)" `
                -MemoryBefore $memoryBefore `
                -MemoryAfter $memoryData
        } catch {
            # エラーを無視（意図的）
        }

        # ファイル保存確認
        if (Test-Path $memoryPath) {
            $fileInfo = Get-Item $memoryPath
        } else {
        }

        $result = @{
            success = $true
            folderName = $folderName
            message = "memory.jsonを保存しました"
            nodeCount = $totalNodes
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
# コード.json読み込み（フォルダごと）
# ------------------------------
Add-PodeRoute -Method Get -Path "/api/folders/:name/code" -ScriptBlock {
    try {
        $folderName = $WebEvent.Parameters['name']
        $rootDir = Get-PodeState -Name 'RootDir'
        $codePath = Join-Path $rootDir "03_history\$folderName\コード.json"

        if (Test-Path $codePath) {
            $content = Get-Content $codePath -Raw -Encoding UTF8
            $codeData = $content | ConvertFrom-Json

            # ✅ 修正: JSON読み込み後、LF(\n) を CRLF(\r\n) に変換
            # ConvertFrom-Jsonは既に\nを実際のLF文字に変換しているため、LF→CRLFの変換が必要
            if ($codeData."エントリ") {
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
                        }
                    }
                }
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

        $folderName = $WebEvent.Parameters['name']

        $body = $WebEvent.Data

        if ($null -eq $body) {
            throw "リクエストボディが空です"
        }


        $codeData = $body.codeData
        if ($null -eq $codeData) {
            throw "codeDataが見つかりません"
        }

        # ✅ 修正: JSON読み込み後、LF(\n) を CRLF(\r\n) に変換
        # ConvertFrom-Jsonは既に\nを実際のLF文字に変換しているため、LF→CRLFの変換が必要
        if ($codeData."エントリ") {
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
                    }
                }
            }
        }


        $rootDir = Get-PodeState -Name 'RootDir'
        $folderPath = Join-Path $rootDir "03_history\$folderName"
        $codePath = Join-Path $folderPath "コード.json"


        # フォルダが存在しない場合は作成
        if (-not (Test-Path $folderPath)) {
            New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
        } else {
        }

        # JSON形式で保存
        $json = $codeData | ConvertTo-Json -Depth 10

        # UTF-8 without BOMで保存（文字化け防止）
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($codePath, $json, $utf8NoBom)

        # 保存確認
        if (Test-Path $codePath) {
            $fileInfo = Get-Item $codePath
        } else {
        }

        $result = @{
            success = $true
            folderName = $folderName
            message = "コード.jsonを保存しました"
            filePath = $codePath
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
# variables.json読み込み（フォルダごと）
# ------------------------------
Add-PodeRoute -Method Get -Path "/api/folders/:name/variables" -ScriptBlock {
    try {
        $folderName = $WebEvent.Parameters['name']
        $rootDir = Get-PodeState -Name 'RootDir'
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
    # v2関数の初期化（未読み込みの場合のみ）
    if (-not (Get-Command ドロップ禁止チェック_ネスト規制_v2 -ErrorAction SilentlyContinue)) {
        $RootDir = Get-PodeState -Name 'RootDir'
        $adapterDir = Get-PodeState -Name 'AdapterDir'
        . (Join-Path $RootDir "12_コードメイン_コード本文_v2.ps1")
        . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
        . (Join-Path $RootDir "10_変数機能_変数管理UI_v2.ps1")
        . (Join-Path $RootDir "07_メインF機能_ツールバー作成_v2.ps1")
        . (Join-Path $RootDir "08_メインF機能_メインボタン処理_v2.ps1")
        . (Join-Path $RootDir "02-6_削除処理_v2.ps1")
        . (Join-Path $RootDir "02-2_ネスト規制バリデーション_v2.ps1")
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
        . (Join-Path $adapterDir "state-manager.ps1")
        . (Join-Path $adapterDir "node-operations.ps1")
    }

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
    # コードID管理関数の初期化（未読み込みの場合のみ）
    if (-not (Get-Command IDを自動生成する -ErrorAction SilentlyContinue)) {
        $RootDir = Get-PodeState -Name 'RootDir'
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
        . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
    }

    # $global:jsonパス を設定（IDを自動生成する で使用）
    $RootDir = Get-PodeState -Name 'RootDir'
    $mainJsonPath = Join-Path $RootDir "03_history\メイン.json"
    if (Test-Path $mainJsonPath) {
        try {
            $mainContent = Get-Content -Path $mainJsonPath -Raw -Encoding UTF8
            $mainData = $mainContent | ConvertFrom-Json
            # 相対パス対応: フォルダ名からフルパスを構築
            $folderName = $mainData.フォルダパス
            $global:folderPath = Join-Path $RootDir "03_history\$folderName"
            $global:jsonパス = Join-Path $global:folderPath "コード.json"
        } catch {
            # エラーを無視（意図的）
        }
    }

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
    # コードID管理関数の初期化（未読み込みの場合のみ）
    if (-not (Get-Command エントリを追加_指定ID -ErrorAction SilentlyContinue)) {
        $RootDir = Get-PodeState -Name 'RootDir'
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
        . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
    }

    # $global:jsonパス を設定（エントリを追加_指定ID で使用）
    $RootDir = Get-PodeState -Name 'RootDir'
    $mainJsonPath = Join-Path $RootDir "03_history\メイン.json"
    if (Test-Path $mainJsonPath) {
        try {
            $mainContent = Get-Content -Path $mainJsonPath -Raw -Encoding UTF8
            $mainData = $mainContent | ConvertFrom-Json
            # 相対パス対応: フォルダ名からフルパスを構築
            $folderName = $mainData.フォルダパス
            $global:folderPath = Join-Path $RootDir "03_history\$folderName"
            $global:jsonパス = Join-Path $global:folderPath "コード.json"
        } catch {
            # エラーを無視（意図的）
        }
    }

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
    # コードID管理関数の初期化（未読み込みの場合のみ）
    if (-not (Get-Command IDでエントリを取得 -ErrorAction SilentlyContinue)) {
        $RootDir = Get-PodeState -Name 'RootDir'
        . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
        . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
    }

    # $global:jsonパス を設定（IDでエントリを取得 で使用）
    $RootDir = Get-PodeState -Name 'RootDir'
    $mainJsonPath = Join-Path $RootDir "03_history\メイン.json"
    if (Test-Path $mainJsonPath) {
        try {
            $mainContent = Get-Content -Path $mainJsonPath -Raw -Encoding UTF8
            $mainData = $mainContent | ConvertFrom-Json
            # 相対パス対応: フォルダ名からフルパスを構築
            $folderName = $mainData.フォルダパス
            $global:folderPath = Join-Path $RootDir "03_history\$folderName"
            $global:jsonパス = Join-Path $global:folderPath "コード.json"
        } catch {
            # エラーを無視（意図的）
        }
    }

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
        $jsonPath = Join-Path (Get-PodeState -Name 'RootDir') "00_code\コード.json"

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
        $codeDir = Join-Path (Get-PodeState -Name 'RootDir') "00_code"

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

        # RootDirを取得してグローバル変数に設定（関数内で使用するため）
        $RootDir = Get-PodeState -Name 'RootDir'
        $global:RootDir = $RootDir
        $script:RootDir = $RootDir

        # 関数名をファイル名に変換（例: "8_1" -> "8-1.ps1"）
        $fileName = $functionName -replace '_', '-'
        $scriptPath = Join-Path $RootDir "00_code\$fileName.ps1"


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

        # ファイル内容をプレビュー表示（デバッグ用）
        $fileContent = Get-Content $scriptPath -Raw
        $preview = $fileContent.Substring(0, [Math]::Min(200, $fileContent.Length))

        # 汎用関数を読み込み（13_コードサブ汎用関数.ps1）
        $汎用関数パス = Join-Path $RootDir "13_コードサブ汎用関数.ps1"
        if (Test-Path $汎用関数パス) {
            . $汎用関数パス
        }

        # スクリプトのディレクトリを取得（$PSScriptRoot の置換に使用）
        $scriptDir = Split-Path -Parent $scriptPath

        # スクリプトを読み込み（エンコーディング自動判定）
        # まず UTF-8 で試して、失敗したら Default (Shift-JIS) で試す
        $scriptContent = $null
        $scriptLoaded = $false
        try {
            # UTF-8 で試す
            $scriptContent = Get-Content -Path $scriptPath -Raw -Encoding UTF8
            $scriptLoaded = $true
        } catch {
            # エラーを無視（意図的）
        }

        if (-not $scriptLoaded) {
            try {
                # Default (Shift-JIS) で試す
                $scriptContent = Get-Content -Path $scriptPath -Raw -Encoding Default
                $scriptLoaded = $true
            } catch {
                throw "スクリプトの読み込みに失敗しました: $_"
            }
        }

        # $PSScriptRoot の参照を実際のパスで置換（関数内で使用できるようにする）
        # PowerShell の自動変数 $PSScriptRoot は Invoke-Expression では動作しないため
        $scriptDirEscaped = $scriptDir -replace '\\', '\\'
        $scriptContent = $scriptContent -replace '\$PSScriptRoot', "'$scriptDirEscaped'"

        # スクリプトを実行して関数を定義
        Invoke-Expression $scriptContent

        # リクエストボディを取得
        $params = @{}
        $bodyJson = $WebEvent.Data
        if ($bodyJson) {
            # プロパティをハッシュテーブルに変換
            $bodyJson.PSObject.Properties | ForEach-Object {
                $params[$_.Name] = $_.Value
            }
        }

        # 関数を実行（UI関数用にSTAアパートメントで実行）

        # STA runspace を作成（WPF UIに必要）
        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.ApartmentState = [System.Threading.ApartmentState]::STA
        $runspace.ThreadOptions = [System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread
        $runspace.Open()

        # 必要な変数を runspace に設定
        $runspace.SessionStateProxy.SetVariable('RootDir', $RootDir)
        $runspace.SessionStateProxy.SetVariable('scriptDir', $scriptDir)

        # $global:folderPath と $global:jsonパス を設定（エントリを追加_指定ID で使用）
        # メイン.json からフォルダパスを読み取る
        $mainJsonPath = Join-Path $RootDir "03_history\メイン.json"
        if (Test-Path $mainJsonPath) {
            try {
                $mainContent = Get-Content -Path $mainJsonPath -Raw -Encoding UTF8
                $mainData = $mainContent | ConvertFrom-Json
                # 相対パス対応: フォルダ名からフルパスを構築
                $folderName = $mainData.フォルダパス
                $folderPath = Join-Path $RootDir "03_history\$folderName"
                $jsonパス = Join-Path $folderPath "コード.json"

                $runspace.SessionStateProxy.SetVariable('global:folderPath', $folderPath)
                $runspace.SessionStateProxy.SetVariable('global:jsonパス', $jsonパス)
                # $global:JSONPath を設定（8-1等で変数管理に使用）
                $JSONPath = Join-Path $folderPath "variables.json"
                $runspace.SessionStateProxy.SetVariable('global:JSONPath', $JSONPath)
            } catch {
                # エラーを無視（意図的）
            }
        } else {
        }

        # PowerShell インスタンスを作成
        $ps = [PowerShell]::Create()
        $ps.Runspace = $runspace

        # 汎用関数を読み込み（13_コードサブ汎用関数.ps1）
        $汎用関数パス = Join-Path $RootDir "13_コードサブ汎用関数.ps1"
        if (Test-Path $汎用関数パス) {
            # 汎用関数の内容を読み込んで実行
            try {
                $汎用関数Content = Get-Content -Path $汎用関数パス -Raw -Encoding UTF8
            } catch {
                $汎用関数Content = Get-Content -Path $汎用関数パス -Raw -Encoding Default
            }
            $ps.AddScript($汎用関数Content) | Out-Null
            $result = $ps.Invoke()
            if ($ps.HadErrors) {
                $errorMsg = ($ps.Streams.Error | ForEach-Object { $_.ToString() }) -join "`n"
                $ps.Streams.Error.Clear()
            }
            $ps.Commands.Clear()
        } else {
        }

        # Excel関数を読み込み（8-1ノード等で使用）
        $Excel関数パス = Join-Path $RootDir "14_コードサブ_EXCEL.ps1"
        if (Test-Path $Excel関数パス) {
            try {
                $Excel関数Content = Get-Content -Path $Excel関数パス -Raw -Encoding UTF8
            } catch {
                $Excel関数Content = Get-Content -Path $Excel関数パス -Raw -Encoding Default
            }
            $ps.AddScript($Excel関数Content) | Out-Null
            $result = $ps.Invoke()
            if ($ps.HadErrors) {
                $errorMsg = ($ps.Streams.Error | ForEach-Object { $_.ToString() }) -join "`n"
                $ps.Streams.Error.Clear()
            }
            $ps.Commands.Clear()
        }

        # JSON操作ユーティリティを読み込み（Read-JsonSafe, Write-JsonSafe等）
        $JSON操作パス = Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1"
        if (Test-Path $JSON操作パス) {
            try {
                $JSON操作Content = Get-Content -Path $JSON操作パス -Raw -Encoding UTF8
            } catch {
                $JSON操作Content = Get-Content -Path $JSON操作パス -Raw -Encoding Default
            }
            $ps.AddScript($JSON操作Content) | Out-Null
            $result = $ps.Invoke()
            if ($ps.HadErrors) {
                $errorMsg = ($ps.Streams.Error | ForEach-Object { $_.ToString() }) -join "`n"
                $ps.Streams.Error.Clear()
            }
            $ps.Commands.Clear()
        }

        # 変数管理関数を読み込み（8-1ノード等で使用）
        $変数管理関数パス = Join-Path $RootDir "11_変数機能_変数管理を外から読み込む関数.ps1"
        if (Test-Path $変数管理関数パス) {
            try {
                $変数管理関数Content = Get-Content -Path $変数管理関数パス -Raw -Encoding UTF8
            } catch {
                $変数管理関数Content = Get-Content -Path $変数管理関数パス -Raw -Encoding Default
            }
            $ps.AddScript($変数管理関数Content) | Out-Null
            $result = $ps.Invoke()
            if ($ps.HadErrors) {
                $errorMsg = ($ps.Streams.Error | ForEach-Object { $_.ToString() }) -join "`n"
                $ps.Streams.Error.Clear()
            }
            $ps.Commands.Clear()
        }

        # PowerShell プロファイルを読み込み（デバッグ表示、ウインドウハンドルでアクティブにする等の依存関数）
        # 環境変数から直接パスを構築（STA runspace では $PROFILE 変数が設定されていないため）
        $userProfile = [System.Environment]::GetEnvironmentVariable('USERPROFILE')
        $profilePaths = @(
            "$userProfile\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1",
            "$userProfile\Documents\WindowsPowerShell\profile.ps1",
            "$userProfile\Documents\PowerShell\Microsoft.PowerShell_profile.ps1",
            "$userProfile\Documents\PowerShell\profile.ps1"
        )

        $profileLoaded = $false
        foreach ($profilePath in $profilePaths) {
            if (Test-Path $profilePath) {
                try {
                    # エンコーディング自動判定
                    try {
                        $profileContent = Get-Content -Path $profilePath -Raw -Encoding UTF8 -ErrorAction Stop
                    } catch {
                        $profileContent = Get-Content -Path $profilePath -Raw -Encoding Default -ErrorAction Stop
                    }

                    $ps.AddScript($profileContent) | Out-Null
                    $result = $ps.Invoke()
                    if ($ps.HadErrors) {
                        $errorMsg = ($ps.Streams.Error | ForEach-Object { $_.ToString() }) -join "`n"
                        $ps.Streams.Error.Clear()
                    } else {
                        $profileLoaded = $true
                    }
                    $ps.Commands.Clear()
                    break
                } catch {
                    # エラーを無視（意図的）
                }
            }
        }

        if (-not $profileLoaded) {
            foreach ($path in $profilePaths) {
            }
        }

        # スクリプトを読み込んで関数を定義
        $ps.AddScript($scriptContent) | Out-Null
        $result = $ps.Invoke()
        if ($ps.HadErrors) {
            $errorMsg = ($ps.Streams.Error | ForEach-Object { $_.ToString() }) -join "`n"
            $ps.Streams.Error.Clear()
        }
        $ps.Commands.Clear()

        # 関数を実行
        $ps.AddCommand($functionName)
        if ($params.Count -gt 0) {
            $ps.AddParameters($params)
        }

        try {
            $code = $ps.Invoke()
            if ($ps.HadErrors) {
                $errorMsg = ($ps.Streams.Error | ForEach-Object { $_.ToString() }) -join "`n"
                throw "関数実行中にエラーが発生しました: $errorMsg"
            }

            # 配列を文字列に変換（$ps.Invoke() は Collection<PSObject> を返すため）
            if ($code -is [System.Collections.ICollection] -and $code.Count -gt 0) {
                $code = ($code | Out-String).Trim()
            } elseif ($null -ne $code -and $code -isnot [string]) {
                $code = $code.ToString()
            }
        } finally {
            # クリーンアップ
            $ps.Dispose()
            $runspace.Close()
            $runspace.Dispose()
        }


        # $codeが$nullの場合、またはキャンセル文字列の場合はキャンセル扱い
        $isCancel = ($null -eq $code) -or ($code -eq "# キャンセルされました")
        if ($isCancel) {
            $result = @{
                success = $false
                cancelled = $true
                code = $null
                functionName = $functionName
                error = "ユーザーがキャンセルしました"
            }
        } else {
            $codePreview = $code.Substring(0, [Math]::Min(200, $code.Length))

            $result = @{
                success = $true
                code = $code
                functionName = $functionName
            }

            # 生成されたコードを コード.json に保存（実行時に読み取るため）
            # functionName を ノードID に変換（例: "4_1" -> "4"）
            # エントリを追加_指定ID は自動的に "-1" サフィックスを追加するため、親IDのみを渡す
            $parentId = ($functionName -replace '_.*$', '')

            # 警告: コードに "---" が含まれる場合、複数エントリに分割される

            # コードID管理関数の初期化（未読み込みの場合のみ）
            if (-not (Get-Command エントリを追加_指定ID -ErrorAction SilentlyContinue)) {
                $RootDir = Get-PodeState -Name 'RootDir'
                . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
                . (Join-Path $RootDir "09_変数機能_コードID管理JSON.ps1")
            }

            try {
                $savedId = エントリを追加_指定ID -文字列 $code -ID $parentId
            } catch {
                # エラーを無視（意図的）
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
        Write-PodeJsonResponse -Value $errorResult -Depth 5
    }
}

# ------------------------------
# スクリプト編集ダイアログを表示
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/node/edit-script" -ScriptBlock {
    try {

        $body = $WebEvent.Data
        $nodeId = $body.nodeId
        $nodeName = $body.nodeName
        $currentScript = $body.currentScript


        # ✅ 修正: JSON読み込み後、LF(\n) を CRLF(\r\n) に変換
        # ConvertFrom-Jsonは既に\nを実際のLF文字に変換しているため、LF→CRLFの変換が必要
        if ($currentScript) {
            $originalLength = $currentScript.Length
            # LF(\n)のみをCRLF(\r\n)に変換（既にCRLFの場合は変更なし）
            # まず既存のCRLFをプレースホルダーに置換し、LFをCRLFに変換してから戻す
            $currentScript = $currentScript -replace "`r`n", "<<CRLF>>" -replace "`n", "`r`n" -replace "<<CRLF>>", "`r`n"
            $newLength = $currentScript.Length
            if ($newLength -ne $originalLength) {
            } else {
            }
        }

        # 汎用関数を読み込み（複数行テキストを編集）
        $汎用関数パス = Join-Path (Get-PodeState -Name 'RootDir') "13_コードサブ汎用関数.ps1"
        if (Test-Path $汎用関数パス) {
            . $汎用関数パス
        } else {
            throw "汎用関数ファイルが見つかりません: $汎用関数パス"
        }

        # PowerShell Windows Formsダイアログを表示
        $editedScript = 複数行テキストを編集 -フォームタイトル "スクリプト編集 - $nodeName" -ラベルテキスト "スクリプトを編集してください:" -初期テキスト $currentScript

        if ($null -eq $editedScript) {
            # キャンセルされた
            $result = @{
                success = $false
                cancelled = $true
                message = "編集がキャンセルされました"
            }
        } else {
            # 編集成功
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
        Write-PodeJsonResponse -Value $errorResult -Depth 5
    }
}

# ------------------------------
# ノード設定ダイアログを表示
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/node/settings" -ScriptBlock {
    try {

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


        # 汎用関数を読み込み（ノード設定を編集）
        $汎用関数パス = Join-Path (Get-PodeState -Name 'RootDir') "13_コードサブ汎用関数.ps1"
        if (Test-Path $汎用関数パス) {
            . $汎用関数パス
        } else {
            throw "汎用関数ファイルが見つかりません: $汎用関数パス"
        }

        # PowerShell Windows Formsダイアログを表示
        $編集結果 = ノード設定を編集 -ノード情報 $ノード情報

        if ($null -eq $編集結果) {
            # キャンセルされた
            $result = @{
                success = $false
                cancelled = $true
                message = "設定がキャンセルされました"
            }
        } else {
            # 編集成功
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
        $logDir = Join-Path (Get-PodeState -Name 'RootDir') "logs"
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
# 注: 静的ファイル（HTML, CSS, JS）はAdd-PodeStaticRouteで処理されます
# 個別ルートは不要のためコメントアウト

# # ルートパス "/" - index-legacy.htmlを提供
# Add-PodeRoute -Method Get -Path "/" -ScriptBlock {
#     $uiPath = Get-PodeState -Name 'uiPath'
#     $indexPath = Join-Path $uiPath "index-legacy.html"
#     if (Test-Path $indexPath) {
#         $content = Get-Content $indexPath -Raw -Encoding UTF8
#         Set-PodeHeader -Name "Content-Type" -Value "text/html; charset=utf-8"
#         Write-PodeTextResponse -Value $content
#     } else {
#         Set-PodeResponseStatus -Code 404
#         Write-PodeTextResponse -Value "index-legacy.html not found"
#     }
# }

# # index-legacy.html
# Add-PodeRoute -Method Get -Path "/index-legacy.html" -ScriptBlock {
#     $uiPath = Get-PodeState -Name 'uiPath'
#     $indexPath = Join-Path $uiPath "index-legacy.html"
#     if (Test-Path $indexPath) {
#         $content = Get-Content $indexPath -Raw -Encoding UTF8
#         Set-PodeHeader -Name "Content-Type" -Value "text/html; charset=utf-8"
#         Write-PodeTextResponse -Value $content
#     } else {
#         Set-PodeResponseStatus -Code 404
#         Write-PodeTextResponse -Value "index-legacy.html not found"
#     }
# }

# # style-legacy.css
# Add-PodeRoute -Method Get -Path "/style-legacy.css" -ScriptBlock {
#     $uiPath = Get-PodeState -Name 'uiPath'
#     $cssPath = Join-Path $uiPath "style-legacy.css"
#     if (Test-Path $cssPath) {
#         $content = Get-Content $cssPath -Raw -Encoding UTF8
#         Set-PodeHeader -Name "Content-Type" -Value "text/css; charset=utf-8"
#         Write-PodeTextResponse -Value $content
#     } else {
#         Set-PodeResponseStatus -Code 404
#         Write-PodeTextResponse -Value "style-legacy.css not found"
#     }
# }

# # app-legacy.js
# Add-PodeRoute -Method Get -Path "/app-legacy.js" -ScriptBlock {
#     $uiPath = Get-PodeState -Name 'uiPath'
#     $jsPath = Join-Path $uiPath "app-legacy.js"
#     if (Test-Path $jsPath) {
#         $content = Get-Content $jsPath -Raw -Encoding UTF8
#         Set-PodeHeader -Name "Content-Type" -Value "application/javascript; charset=utf-8"
#         Write-PodeTextResponse -Value $content
#     } else {
#         Set-PodeResponseStatus -Code 404
#         Write-PodeTextResponse -Value "app-legacy.js not found"
#     }
# }

# # layer-detail.html
# Add-PodeRoute -Method Get -Path "/layer-detail.html" -ScriptBlock {
#     $uiPath = Get-PodeState -Name 'uiPath'
#     $htmlPath = Join-Path $uiPath "layer-detail.html"
#     if (Test-Path $htmlPath) {
#         $content = Get-Content $htmlPath -Raw -Encoding UTF8
#         Set-PodeHeader -Name "Content-Type" -Value "text/html; charset=utf-8"
#         Write-PodeTextResponse -Value $content
#     } else {
#         Set-PodeResponseStatus -Code 404
#         Write-PodeTextResponse -Value "layer-detail.html not found"
#     }
# }

# # layer-detail.js
# Add-PodeRoute -Method Get -Path "/layer-detail.js" -ScriptBlock {
#     $uiPath = Get-PodeState -Name 'uiPath'
#     $jsPath = Join-Path $uiPath "layer-detail.js"
#     if (Test-Path $jsPath) {
#         $content = Get-Content $jsPath -Raw -Encoding UTF8
#         Set-PodeHeader -Name "Content-Type" -Value "application/javascript; charset=utf-8"
#         Write-PodeTextResponse -Value $content
#     } else {
#         Set-PodeResponseStatus -Code 404
#         Write-PodeTextResponse -Value "layer-detail.js not found"
#     }
# }

# # modal-functions.js
# Add-PodeRoute -Method Get -Path "/modal-functions.js" -ScriptBlock {
#     $uiPath = Get-PodeState -Name 'uiPath'
#     $jsPath = Join-Path $uiPath "modal-functions.js"
#     if (Test-Path $jsPath) {
#         $content = Get-Content $jsPath -Raw -Encoding UTF8
#         Set-PodeHeader -Name "Content-Type" -Value "application/javascript; charset=utf-8"
#         Write-PodeTextResponse -Value $content
#     } else {
#         Set-PodeResponseStatus -Code 404
#         Write-PodeTextResponse -Value "modal-functions.js not found"
#     }
# }

# ボタン設定.json (英語エイリアス: /button-settings.json)
Add-PodeRoute -Method Get -Path "/button-settings.json" -ScriptBlock {
    $rootDir = Get-PodeState -Name 'RootDir'
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
    $rootDir = Get-PodeState -Name 'RootDir'
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

# カテゴリ設定.json (英語エイリアス: /category-settings.json)
Add-PodeRoute -Method Get -Path "/category-settings.json" -ScriptBlock {
    $rootDir = Get-PodeState -Name 'RootDir'
    $jsonPath = Join-Path $rootDir "カテゴリ設定.json"
    if (Test-Path $jsonPath) {
        $content = Get-Content $jsonPath -Raw -Encoding UTF8
        Set-PodeHeader -Name "Content-Type" -Value "application/json; charset=utf-8"
        Write-PodeTextResponse -Value $content
    } else {
        Set-PodeResponseStatus -Code 404
        $errorResult = @{ error = "カテゴリ設定.json not found" }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# カテゴリ設定.json (日本語パス)
Add-PodeRoute -Method Get -Path "/カテゴリ設定.json" -ScriptBlock {
    $rootDir = Get-PodeState -Name 'RootDir'
    $jsonPath = Join-Path $rootDir "カテゴリ設定.json"
    if (Test-Path $jsonPath) {
        $content = Get-Content $jsonPath -Raw -Encoding UTF8
        Set-PodeHeader -Name "Content-Type" -Value "application/json; charset=utf-8"
        Write-PodeTextResponse -Value $content
    } else {
        Set-PodeResponseStatus -Code 404
        $errorResult = @{ error = "カテゴリ設定.json not found" }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ==============================================================================
# Undo/Redo 操作履歴管理 APIエンドポイント
# ==============================================================================

# 履歴状態取得
Add-PodeRoute -Method Get -Path "/api/history/status" -ScriptBlock {
    try {
        # 履歴管理関数の初期化（未読み込みの場合のみ）
        if (-not (Get-Command Initialize-HistoryStack -ErrorAction SilentlyContinue)) {
            $RootDir = Get-PodeState -Name 'RootDir'
            . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
            . (Join-Path $RootDir "17_操作履歴管理.ps1")
        }

        $RootDir = Get-PodeState -Name 'RootDir'
        $mainJsonPath = Join-Path $RootDir "03_history\メイン.json"

        if (Test-Path $mainJsonPath) {
            $mainContent = Get-Content -Path $mainJsonPath -Raw -Encoding UTF8
            $mainData = $mainContent | ConvertFrom-Json
            # 相対パス対応: フォルダ名からフルパスを構築
            $folderName = $mainData.フォルダパス
            $folderPath = Join-Path $RootDir "03_history\$folderName"


            # Get-HistoryStatus関数を使用（Pode Runspace分離対策）
            $result = Get-HistoryStatus -FolderPath $folderPath


            # レスポンス形式をフロントエンドに合わせる
            $responseData = @{
                success = $result.success
                canUndo = $result.canUndo
                canRedo = $result.canRedo
                position = $result.position
                count = $result.totalCount
            }


            Write-PodeJsonResponse -Value $responseData
        } else {
            $result = @{
                success = $false
                canUndo = $false
                canRedo = $false
                error = "メイン.jsonが見つかりません"
            }
            Write-PodeJsonResponse -Value $result
        }
    } catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
            canUndo = $false
            canRedo = $false
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# Undo実行
Add-PodeRoute -Method Post -Path "/api/history/undo" -ScriptBlock {
    try {
        # 履歴管理関数の初期化（未読み込みの場合のみ）
        if (-not (Get-Command Undo-Operation -ErrorAction SilentlyContinue)) {
            $RootDir = Get-PodeState -Name 'RootDir'
            . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
            . (Join-Path $RootDir "17_操作履歴管理.ps1")
        }

        $RootDir = Get-PodeState -Name 'RootDir'
        $mainJsonPath = Join-Path $RootDir "03_history\メイン.json"

        if (-not (Test-Path $mainJsonPath)) {
            Set-PodeResponseStatus -Code 404
            $errorResult = @{
                success = $false
                error = "メイン.jsonが見つかりません"
            }
            Write-PodeJsonResponse -Value $errorResult
            return
        }

        $mainContent = Get-Content -Path $mainJsonPath -Raw -Encoding UTF8
        $mainData = $mainContent | ConvertFrom-Json
        # 相対パス対応: フォルダ名からフルパスを構築
        $folderName = $mainData.フォルダパス
        $folderPath = Join-Path $RootDir "03_history\$folderName"

        # Undo実行
        $result = Undo-Operation -FolderPath $folderPath


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

# Redo実行
Add-PodeRoute -Method Post -Path "/api/history/redo" -ScriptBlock {
    try {
        # 履歴管理関数の初期化（未読み込みの場合のみ）
        if (-not (Get-Command Redo-Operation -ErrorAction SilentlyContinue)) {
            $RootDir = Get-PodeState -Name 'RootDir'
            . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
            . (Join-Path $RootDir "17_操作履歴管理.ps1")
        }

        $RootDir = Get-PodeState -Name 'RootDir'
        $mainJsonPath = Join-Path $RootDir "03_history\メイン.json"

        if (-not (Test-Path $mainJsonPath)) {
            Set-PodeResponseStatus -Code 404
            $errorResult = @{
                success = $false
                error = "メイン.jsonが見つかりません"
            }
            Write-PodeJsonResponse -Value $errorResult
            return
        }

        $mainContent = Get-Content -Path $mainJsonPath -Raw -Encoding UTF8
        $mainData = $mainContent | ConvertFrom-Json
        # 相対パス対応: フォルダ名からフルパスを構築
        $folderName = $mainData.フォルダパス
        $folderPath = Join-Path $RootDir "03_history\$folderName"

        # Redo実行
        $result = Redo-Operation -FolderPath $folderPath


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

# 履歴の初期化
Add-PodeRoute -Method Post -Path "/api/history/init" -ScriptBlock {
    try {
        # 履歴管理関数の初期化（未読み込みの場合のみ）
        if (-not (Get-Command Initialize-HistoryStack -ErrorAction SilentlyContinue)) {
            $RootDir = Get-PodeState -Name 'RootDir'
            . (Join-Path $RootDir "00_共通ユーティリティ_JSON操作.ps1")
            . (Join-Path $RootDir "17_操作履歴管理.ps1")
        }

        $RootDir = Get-PodeState -Name 'RootDir'
        $mainJsonPath = Join-Path $RootDir "03_history\メイン.json"

        if (-not (Test-Path $mainJsonPath)) {
            Set-PodeResponseStatus -Code 404
            $errorResult = @{
                success = $false
                error = "メイン.jsonが見つかりません"
            }
            Write-PodeJsonResponse -Value $errorResult
            return
        }

        $mainContent = Get-Content -Path $mainJsonPath -Raw -Encoding UTF8
        $mainData = $mainContent | ConvertFrom-Json
        # 相対パス対応: フォルダ名からフルパスを構築
        $folderName = $mainData.フォルダパス
        $folderPath = Join-Path $RootDir "03_history\$folderName"

        # 履歴初期化
        $result = Initialize-HistoryStack -FolderPath $folderPath

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
# アプリケーション終了
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/shutdown" -ScriptBlock {
    try {

        $result = @{
            success = $true
            message = "アプリケーションを終了します"
        }
        Write-PodeJsonResponse -Value $result

        # バックグラウンドでプロセスを終了（レスポンス送信後に実行）
        $currentPID = $PID
        Start-Job -ScriptBlock {
            param($processId)
            Start-Sleep -Seconds 1
            Stop-Process -Id $processId -Force
        } -ArgumentList $currentPID | Out-Null

        # サーバーを終了
        Close-PodeServer

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
# ロボットプロファイル取得
# ------------------------------
Add-PodeRoute -Method Get -Path "/api/robot-profile" -ScriptBlock {
    try {
        $RootDir = Get-PodeState -Name 'RootDir'
        $profilePath = Join-Path $RootDir "robot-profile.json"

        if (Test-Path $profilePath) {
            $content = Get-Content -Path $profilePath -Raw -Encoding UTF8
            $profile = $content | ConvertFrom-Json
            $result = @{
                success = $true
                profile = $profile
            }
        } else {
            # デフォルトプロファイル
            $result = @{
                success = $true
                profile = @{
                    name = ""
                    author = ""
                    role = ""
                    memo = ""
                    image = ""
                    bgcolor = "#e8f4fc"
                }
            }
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
# ロボットプロファイル保存
# ------------------------------
Add-PodeRoute -Method Post -Path "/api/robot-profile" -ScriptBlock {
    try {
        $RootDir = Get-PodeState -Name 'RootDir'
        $profilePath = Join-Path $RootDir "robot-profile.json"

        $body = $WebEvent.Data
        # 既存のプロファイルを読み込んでバージョンを保持
        $existingVersion = "1.0.0.0"
        if (Test-Path $profilePath) {
            try {
                $existingProfile = Get-Content -Path $profilePath -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($existingProfile.version) {
                    $existingVersion = $existingProfile.version
                }
            } catch { }
        }

        $profile = @{
            name = if ($body.name) { $body.name } else { "" }
            author = if ($body.author) { $body.author } else { "" }
            role = if ($body.role) { $body.role } else { "" }
            memo = if ($body.memo) { $body.memo } else { "" }
            image = if ($body.image) { $body.image } else { "" }
            bgcolor = if ($body.bgcolor) { $body.bgcolor } else { "#e8f4fc" }
            hasVoice = if ($null -ne $body.hasVoice) { [bool]$body.hasVoice } else { $true }
            hasDisplay = if ($null -ne $body.hasDisplay) { [bool]$body.hasDisplay } else { $true }
            version = $existingVersion
        }

        $json = $profile | ConvertTo-Json -Depth 10
        $json | Out-File -FilePath $profilePath -Encoding UTF8 -Force


        $result = @{
            success = $true
            message = "プロファイルを保存しました"
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

# ==============================================================================
# Excel接続API
# ==============================================================================

# Excelファイル選択ダイアログ
Add-PodeRoute -Method Post -Path "/api/excel/browse" -ScriptBlock {
    try {
        $RootDir = Get-PodeState -Name 'RootDir'
        $adapterDir = Join-Path $RootDir "adapter"

        # 一時ファイルパスを生成
        $tempFile = Join-Path $env:TEMP "excel-dialog-result-$([guid]::NewGuid().ToString('N')).json"

        # 外部スクリプトのパス
        $dialogScript = Join-Path $adapterDir "excel-file-dialog.ps1"


        # 外部プロセスでダイアログを実行（STAモード必須）
        $process = Start-Process -FilePath "powershell.exe" -ArgumentList @(
            "-NoProfile",
            "-STA",
            "-ExecutionPolicy", "Bypass",
            "-File", $dialogScript,
            "-OutputPath", $tempFile
        ) -Wait -PassThru -WindowStyle Hidden


        # 結果ファイルを読み込み
        if (Test-Path $tempFile) {
            $resultJson = Get-Content $tempFile -Encoding UTF8 -Raw
            $result = $resultJson | ConvertFrom-Json

            # 一時ファイルを削除
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue


            # ハッシュテーブルに変換して返す
            $response = @{
                success = [bool]$result.success
                filePath = if ($result.filePath) { $result.filePath } else { "" }
                message = if ($result.message) { $result.message } else { "" }
            }
            Write-PodeJsonResponse -Value $response
        } else {
            throw "ダイアログ結果ファイルが見つかりません"
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

# Excelシート一覧取得
Add-PodeRoute -Method Post -Path "/api/excel/sheets" -ScriptBlock {
    try {
        $body = $WebEvent.Data
        $filePath = $body.filePath


        if (-not $filePath -or -not (Test-Path $filePath)) {
            throw "ファイルが見つかりません: $filePath"
        }

        $RootDir = Get-PodeState -Name 'RootDir'
        $adapterDir = Join-Path $RootDir "adapter"

        # 一時ファイルパスを生成
        $tempFile = Join-Path $env:TEMP "excel-sheets-result-$([guid]::NewGuid().ToString('N')).json"

        # 外部スクリプトのパス
        $sheetsScript = Join-Path $adapterDir "excel-get-sheets.ps1"


        # 外部プロセスでシート一覧を取得
        $process = Start-Process -FilePath "powershell.exe" -ArgumentList @(
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-File", $sheetsScript,
            "-FilePath", $filePath,
            "-OutputPath", $tempFile
        ) -Wait -PassThru -WindowStyle Hidden


        # 結果ファイルを読み込み
        if (Test-Path $tempFile) {
            $resultJson = Get-Content $tempFile -Encoding UTF8 -Raw
            $result = $resultJson | ConvertFrom-Json

            # 一時ファイルを削除
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

            if ($result.success) {
                $response = @{
                    success = $true
                    sheets = @($result.sheets)
                }
                Write-PodeJsonResponse -Value $response
            } else {
                throw $result.error
            }
        } else {
            throw "シート取得結果ファイルが見つかりません"
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

# Excel接続（データ読み込み）
Add-PodeRoute -Method Post -Path "/api/excel/connect" -ScriptBlock {
    try {
        $body = $WebEvent.Data
        $filePath = $body.filePath
        $sheetName = $body.sheetName
        $variableName = if ($body.variableName) { $body.variableName } else { "Excel2次元配列" }

        if (-not $filePath -or -not (Test-Path $filePath)) {
            throw "ファイルが見つかりません: $filePath"
        }

        if (-not $sheetName) {
            throw "シート名が指定されていません"
        }

        $RootDir = Get-PodeState -Name 'RootDir'
        $adapterDir = Join-Path $RootDir "adapter"

        # 一時ファイルパスを生成
        $tempFile = Join-Path $env:TEMP "excel-data-result-$([guid]::NewGuid().ToString('N')).json"

        # 外部スクリプトのパス
        $readScript = Join-Path $adapterDir "excel-read-data.ps1"


        # 外部プロセスでデータを読み込み
        $process = Start-Process -FilePath "powershell.exe" -ArgumentList @(
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-File", $readScript,
            "-FilePath", $filePath,
            "-SheetName", $sheetName,
            "-OutputPath", $tempFile
        ) -Wait -PassThru -WindowStyle Hidden


        # 結果ファイルを読み込み
        if (Test-Path $tempFile) {
            $resultJson = Get-Content $tempFile -Encoding UTF8 -Raw
            $excelResult = $resultJson | ConvertFrom-Json

            # 一時ファイルを削除
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

            if ($excelResult.success) {
                $data = $excelResult.data
                $rowCount = $excelResult.rowCount
                $colCount = $excelResult.colCount
                $headers = @($excelResult.headers)


                # 変数ファイルに保存
                $folderInfo = Get-Content (Join-Path $RootDir "03_history\メイン.json") -Encoding UTF8 | ConvertFrom-Json
                $currentFolder = $folderInfo.currentFolder
                $variablesPath = Join-Path $RootDir "03_history\$currentFolder\variables.json"

                # 既存の変数を読み込み
                $variables = @{}
                if (Test-Path $variablesPath) {
                    $existingVars = Get-Content $variablesPath -Encoding UTF8 -Raw | ConvertFrom-Json
                    if ($existingVars) {
                        $existingVars.PSObject.Properties | ForEach-Object {
                            $variables[$_.Name] = $_.Value
                        }
                    }
                }

                # 新しい変数を追加
                $variables[$variableName] = @{
                    type = "二次元"
                    value = $data
                }

                # 保存
                $variables | ConvertTo-Json -Depth 100 | Out-File -FilePath $variablesPath -Encoding UTF8 -Force

                # $global:variablesも更新（メモリ内の変数辞書）
                if (-not $global:variables) {
                    $global:variables = @{}
                }
                $global:variables[$variableName] = $data

                # データ全体を返すと接続がタイムアウトするため、統計情報のみ返す
                $result = @{
                    success = $true
                    rowCount = $rowCount
                    colCount = $colCount
                    headers = $headers
                    variableName = $variableName
                }

                Write-PodeJsonResponse -Value $result
            } else {
                throw $excelResult.error
            }
        } else {
            throw "データ読み込み結果ファイルが見つかりません"
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

# ==============================================================================
# 接続情報永続化 API
# ==============================================================================

# 接続情報を取得
Add-PodeRoute -Method Get -Path '/api/connection' -ScriptBlock {
    try {
        $RootDir = Get-PodeState -Name 'RootDir'

        # クエリパラメータからフォルダ名を取得
        $currentFolder = $WebEvent.Query['folder']

        if (-not $currentFolder) {
            $result = @{
                success = $true
                data = $null
            }
            Write-PodeJsonResponse -Value $result
            return
        }

        $connectionPath = Join-Path $RootDir "03_history\$currentFolder\connection.json"

        if (Test-Path $connectionPath) {
            $connectionData = Get-Content $connectionPath -Encoding UTF8 -Raw | ConvertFrom-Json
            $result = @{
                success = $true
                data = $connectionData
            }
        } else {
            $result = @{
                success = $true
                data = $null
            }
        }

        Write-PodeJsonResponse -Value $result
    }
    catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# 接続情報を保存
Add-PodeRoute -Method Post -Path '/api/connection' -ScriptBlock {
    try {
        $RootDir = Get-PodeState -Name 'RootDir'
        $body = $WebEvent.Data

        # bodyからフォルダ名を取得
        $currentFolder = $body.folder

        if (-not $currentFolder) {
            Set-PodeResponseStatus -Code 400
            $errorResult = @{
                success = $false
                error = "フォルダが指定されていません"
            }
            Write-PodeJsonResponse -Value $errorResult
            return
        }

        $connectionPath = Join-Path $RootDir "03_history\$currentFolder\connection.json"

        # 接続情報を保存（folderキーは除外して保存）
        $saveData = @{
            excel = $body.excel
        }
        $saveData | ConvertTo-Json -Depth 10 | Out-File -FilePath $connectionPath -Encoding UTF8 -Force


        $result = @{
            success = $true
        }
        Write-PodeJsonResponse -Value $result
    }
    catch {
        Set-PodeResponseStatus -Code 500
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
        }
        Write-PodeJsonResponse -Value $errorResult
    }
}

# ==============================================================================
# 変換完了
# ==============================================================================
