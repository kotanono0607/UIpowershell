﻿# ================================================================
# 17_操作履歴管理.Tests.ps1
# ================================================================
# Pester テストファイル: 操作履歴管理モジュールの包括的テスト
# 対応バージョン: Pester v3.4.0以上
#
# テスト対象関数:
#   - Initialize-HistoryStack  : 操作履歴スタックの初期化
#   - Record-Operation        : 操作を記録（差分保存方式）
#   - Undo-Operation          : Undo実行（差分復元方式）
#   - Redo-Operation          : Redo実行（差分復元方式）
#   - Get-HistoryStatus       : 履歴状態取得
#   - Clear-HistoryStack      : 履歴クリア
#
# 実行方法: Invoke-Pester -Path ./tests/17_操作履歴管理.Tests.ps1 -Verbose
# ================================================================

# テスト対象スクリプトのパスを設定
$ScriptRoot = Split-Path -Parent $PSScriptRoot

# 依存する共通ユーティリティを読み込み
. "$ScriptRoot\00_共通ユーティリティ_JSON操作.ps1"

# テスト対象スクリプトを読み込み
. "$ScriptRoot\17_操作履歴管理.ps1"

# テスト用一時ディレクトリのルート
$TestRootPath = Join-Path $env:TEMP "UIpowershell_tests_$(Get-Random)"

# ================================================================
# Initialize-HistoryStack のテスト
# ================================================================
Describe "Initialize-HistoryStack" {

    BeforeEach {
        # 各テストの前にグローバル変数をリセット
        $global:HistoryStack = $null
        $global:CurrentHistoryPosition = 0
        $global:MaxHistoryCount = 50

        # テスト用フォルダを作成
        $script:TestFolder = Join-Path $TestRootPath "test_$(Get-Random)"
        New-Item -ItemType Directory -Path $script:TestFolder -Force | Out-Null
    }

    AfterEach {
        # 各テストの後にテストフォルダをクリーンアップ
        if (Test-Path $script:TestFolder) {
            Remove-Item -Path $script:TestFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "新規履歴ファイル作成" {
        It "history.jsonが存在しない場合、新規作成される" {
            $result = Initialize-HistoryStack -FolderPath $script:TestFolder

            $result.success | Should Be $true
            $result.count | Should Be 0
            $result.position | Should Be 0

            # ファイルが作成されたか確認
            $historyPath = Join-Path $script:TestFolder 'history.json'
            Test-Path $historyPath | Should Be $true
        }

        It "新規作成時にグローバル変数が正しく初期化される" {
            Initialize-HistoryStack -FolderPath $script:TestFolder | Out-Null

            $global:HistoryStack | Should Not BeNullOrEmpty
            $global:HistoryStack.Count | Should Be 0
            $global:CurrentHistoryPosition | Should Be 0
        }

        It "新規作成されたhistory.jsonの構造が正しい" {
            Initialize-HistoryStack -FolderPath $script:TestFolder | Out-Null

            $historyPath = Join-Path $script:TestFolder 'history.json'
            $data = Get-Content -Path $historyPath -Raw | ConvertFrom-Json

            $data.HistoryStack | Should Not BeNullOrEmpty
            $data.CurrentHistoryPosition | Should Be 0
            $data.MaxHistoryCount | Should Be 50
        }
    }

    Context "既存履歴ファイルの読み込み" {
        It "既存のhistory.jsonが正しく読み込まれる" {
            # 事前にhistory.jsonを作成
            $existingData = @{
                HistoryStack = @(
                    @{
                        operationId = "test-id-1"
                        operationType = "NodeAdd"
                        description = "テスト操作1"
                        timestamp = "2025-01-01 00:00:00"
                    },
                    @{
                        operationId = "test-id-2"
                        operationType = "NodeDelete"
                        description = "テスト操作2"
                        timestamp = "2025-01-01 00:01:00"
                    }
                )
                CurrentHistoryPosition = 2
                MaxHistoryCount = 30
            }
            $historyPath = Join-Path $script:TestFolder 'history.json'
            $existingData | ConvertTo-Json -Depth 10 | Set-Content -Path $historyPath -Encoding UTF8

            $result = Initialize-HistoryStack -FolderPath $script:TestFolder

            $result.success | Should Be $true
            $result.count | Should Be 2
            $result.position | Should Be 2
            $global:MaxHistoryCount | Should Be 30
        }

        It "空のhistory.jsonの場合、新規スタックが作成される" {
            # 空のhistory.jsonを作成
            $historyPath = Join-Path $script:TestFolder 'history.json'
            "" | Set-Content -Path $historyPath -Encoding UTF8

            $result = Initialize-HistoryStack -FolderPath $script:TestFolder

            $result.success | Should Be $true
            $global:HistoryStack.Count | Should Be 0
            $global:CurrentHistoryPosition | Should Be 0
        }
    }
}

# ================================================================
# Record-Operation のテスト
# ================================================================
Describe "Record-Operation" {

    BeforeEach {
        $global:HistoryStack = $null
        $global:CurrentHistoryPosition = 0
        $global:MaxHistoryCount = 50

        $script:TestFolder = Join-Path $TestRootPath "test_$(Get-Random)"
        New-Item -ItemType Directory -Path $script:TestFolder -Force | Out-Null

        # 履歴を初期化
        Initialize-HistoryStack -FolderPath $script:TestFolder | Out-Null
    }

    AfterEach {
        if (Test-Path $script:TestFolder) {
            Remove-Item -Path $script:TestFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "基本的な操作記録" {
        It "NodeAdd操作が正しく記録される" {
            $memBefore = @{ "1" = @() }
            $memAfter = @{ "1" = @(@{ id = "node-1"; name = "テストノード" }) }

            $result = Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeAdd" `
                -Description "ノードを追加" `
                -MemoryBefore $memBefore `
                -MemoryAfter $memAfter

            $result.success | Should Be $true
            $result.position | Should Be 1
            $result.count | Should Be 1
        }

        It "NodeDelete操作が正しく記録される" {
            $result = Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeDelete" `
                -Description "ノードを削除"

            $result.success | Should Be $true
            $result.operationId | Should Not BeNullOrEmpty
        }

        It "NodeMove操作が正しく記録される" {
            $result = Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeMove" `
                -Description "ノードを移動"

            $result.success | Should Be $true
        }

        It "NodeUpdate操作が正しく記録される" {
            $result = Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeUpdate" `
                -Description "ノードを更新"

            $result.success | Should Be $true
        }

        It "CodeUpdate操作が正しく記録される" {
            $codeBefore = @{ entries = @{} }
            $codeAfter = @{ entries = @{ "1" = "code1" } }

            $result = Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "CodeUpdate" `
                -Description "コードを更新" `
                -CodeBefore $codeBefore `
                -CodeAfter $codeAfter

            $result.success | Should Be $true
        }

        It "Other操作が正しく記録される" {
            $result = Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "Other" `
                -Description "その他の操作"

            $result.success | Should Be $true
        }
    }

    Context "差分検出" {
        It "変更されたレイヤーのみが検出される" {
            $memBefore = @{
                "1" = @(@{ id = "n1" })
                "2" = @(@{ id = "n2" })
                "3" = @(@{ id = "n3" })
            }
            $memAfter = @{
                "1" = @(@{ id = "n1" })  # 変更なし
                "2" = @(@{ id = "n2-modified" })  # 変更あり
                "3" = @(@{ id = "n3" })  # 変更なし
            }

            $result = Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeUpdate" `
                -Description "レイヤー2を更新" `
                -MemoryBefore $memBefore `
                -MemoryAfter $memAfter

            $result.success | Should Be $true
            $result.affectedLayers -contains "2" | Should Be $true
            $result.affectedLayers -contains "1" | Should Be $false
            $result.affectedLayers -contains "3" | Should Be $false
        }

        It "複数レイヤーの変更が正しく検出される" {
            $memBefore = @{
                "1" = @(@{ id = "n1" })
                "2" = @(@{ id = "n2" })
            }
            $memAfter = @{
                "1" = @(@{ id = "n1-modified" })  # 変更あり
                "2" = @(@{ id = "n2-modified" })  # 変更あり
            }

            $result = Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeUpdate" `
                -Description "複数レイヤーを更新" `
                -MemoryBefore $memBefore `
                -MemoryAfter $memAfter

            $result.affectedLayers.Count | Should Be 2
            $result.affectedLayers -contains "1" | Should Be $true
            $result.affectedLayers -contains "2" | Should Be $true
        }

        It "新規レイヤー追加が検出される" {
            $memBefore = @{ "1" = @() }
            $memAfter = @{
                "1" = @()
                "2" = @(@{ id = "new-node" })  # 新規レイヤー
            }

            $result = Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeAdd" `
                -Description "新規レイヤーにノード追加" `
                -MemoryBefore $memBefore `
                -MemoryAfter $memAfter

            $result.affectedLayers -contains "2" | Should Be $true
        }
    }

    Context "履歴スタックの管理" {
        It "連続した操作が正しく記録される" {
            for ($i = 1; $i -le 5; $i++) {
                Record-Operation `
                    -FolderPath $script:TestFolder `
                    -OperationType "NodeAdd" `
                    -Description "操作 $i" | Out-Null
            }

            $global:HistoryStack.Count | Should Be 5
            $global:CurrentHistoryPosition | Should Be 5
        }

        It "最大履歴数を超えた場合、古い履歴が削除される" {
            $global:MaxHistoryCount = 5

            for ($i = 1; $i -le 10; $i++) {
                Record-Operation `
                    -FolderPath $script:TestFolder `
                    -OperationType "NodeAdd" `
                    -Description "操作 $i" | Out-Null
            }

            $global:HistoryStack.Count | Should Be 5
            # 最初の5件（操作1-5）が削除され、操作6-10が残る
            $global:HistoryStack[0].description | Should Be "操作 6"
        }
    }

    Context "Redo分岐の削除" {
        It "途中位置から新しい操作を記録するとRedo分岐が削除される" {
            # 5つの操作を記録
            for ($i = 1; $i -le 5; $i++) {
                Record-Operation `
                    -FolderPath $script:TestFolder `
                    -OperationType "NodeAdd" `
                    -Description "操作 $i" | Out-Null
            }

            # 位置を3に戻す（Undo 2回相当）
            $global:CurrentHistoryPosition = 3

            # 新しい操作を記録
            Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeAdd" `
                -Description "新しい操作" | Out-Null

            # 操作4, 5が削除され、新しい操作が追加される
            $global:HistoryStack.Count | Should Be 4
            $global:HistoryStack[3].description | Should Be "新しい操作"
        }
    }

    Context "履歴が未初期化の場合" {
        It "自動的に初期化される" {
            $global:HistoryStack = $null

            $newFolder = Join-Path $TestRootPath "auto_init_$(Get-Random)"
            New-Item -ItemType Directory -Path $newFolder -Force | Out-Null

            try {
                $result = Record-Operation `
                    -FolderPath $newFolder `
                    -OperationType "NodeAdd" `
                    -Description "自動初期化テスト"

                $result.success | Should Be $true
                $global:HistoryStack | Should Not BeNullOrEmpty
            }
            finally {
                Remove-Item -Path $newFolder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

# ================================================================
# Undo-Operation のテスト
# ================================================================
Describe "Undo-Operation" {

    BeforeEach {
        $global:HistoryStack = $null
        $global:CurrentHistoryPosition = 0
        $global:MaxHistoryCount = 50

        $script:TestFolder = Join-Path $TestRootPath "test_$(Get-Random)"
        New-Item -ItemType Directory -Path $script:TestFolder -Force | Out-Null

        Initialize-HistoryStack -FolderPath $script:TestFolder | Out-Null

        # memory.jsonを作成
        $memoryPath = Join-Path $script:TestFolder 'memory.json'
        @{ "1" = @() } | ConvertTo-Json -Depth 10 | Set-Content -Path $memoryPath -Encoding UTF8
    }

    AfterEach {
        if (Test-Path $script:TestFolder) {
            Remove-Item -Path $script:TestFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "基本的なUndo操作" {
        It "Undo可能な状態でUndoが成功する" {
            # 操作を記録
            $memBefore = @{ "1" = @() }
            $memAfter = @{ "1" = @(@{ id = "node-1" }) }

            Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeAdd" `
                -Description "ノードを追加" `
                -MemoryBefore $memBefore `
                -MemoryAfter $memAfter | Out-Null

            $result = Undo-Operation -FolderPath $script:TestFolder

            $result.success | Should Be $true
            $result.position | Should Be 0
            $result.canUndo | Should Be $false
            $result.canRedo | Should Be $true
        }

        It "Undoした操作の情報が返される" {
            Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeDelete" `
                -Description "ノードを削除" | Out-Null

            $result = Undo-Operation -FolderPath $script:TestFolder

            $result.operation.type | Should Be "NodeDelete"
            $result.operation.description | Should Be "ノードを削除"
        }
    }

    Context "Undo不可能な状態" {
        It "履歴が空の場合、Undoが失敗する" {
            $result = Undo-Operation -FolderPath $script:TestFolder

            $result.success | Should Be $false
            $result.error | Should Match "Undo不可"
            $result.canUndo | Should Be $false
        }

        It "既にすべてUndoした場合、さらなるUndoが失敗する" {
            Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeAdd" `
                -Description "操作1" | Out-Null

            Undo-Operation -FolderPath $script:TestFolder | Out-Null
            $result = Undo-Operation -FolderPath $script:TestFolder

            $result.success | Should Be $false
            $result.canUndo | Should Be $false
        }

        It "history.jsonが存在しない場合、エラーが返される" {
            $emptyFolder = Join-Path $TestRootPath "empty_$(Get-Random)"
            New-Item -ItemType Directory -Path $emptyFolder -Force | Out-Null

            try {
                $result = Undo-Operation -FolderPath $emptyFolder

                $result.success | Should Be $false
                $result.error | Should Match "履歴ファイルが見つかりません"
            }
            finally {
                Remove-Item -Path $emptyFolder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context "差分復元（v2形式）" {
        It "影響を受けたレイヤーのみが復元される" {
            # 初期状態
            $memoryPath = Join-Path $script:TestFolder 'memory.json'
            $initialMemory = @{
                "1" = @(@{ id = "n1"; value = "original" })
                "2" = @(@{ id = "n2"; value = "unchanged" })
            }
            $initialMemory | ConvertTo-Json -Depth 10 | Set-Content -Path $memoryPath -Encoding UTF8

            # 操作を記録（レイヤー1のみ変更）
            $memBefore = @{
                "1" = @(@{ id = "n1"; value = "original" })
                "2" = @(@{ id = "n2"; value = "unchanged" })
            }
            $memAfter = @{
                "1" = @(@{ id = "n1"; value = "modified" })
                "2" = @(@{ id = "n2"; value = "unchanged" })
            }

            Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeUpdate" `
                -Description "レイヤー1を更新" `
                -MemoryBefore $memBefore `
                -MemoryAfter $memAfter | Out-Null

            # memory.jsonを更新後の状態に
            $memAfter | ConvertTo-Json -Depth 10 | Set-Content -Path $memoryPath -Encoding UTF8

            # Undo実行
            $result = Undo-Operation -FolderPath $script:TestFolder

            $result.success | Should Be $true

            # memory.jsonを確認
            $restoredMemory = Get-Content -Path $memoryPath -Raw | ConvertFrom-Json
            $restoredMemory."1"[0].value | Should Be "original"
            $restoredMemory."2"[0].value | Should Be "unchanged"
        }
    }

    Context "旧形式（v1形式）との互換性" {
        It "memory_beforeフィールドを持つ旧形式データでもUndoできる" {
            # 旧形式のhistory.jsonを作成
            $historyPath = Join-Path $script:TestFolder 'history.json'
            $oldFormatHistory = @{
                HistoryStack = @(
                    @{
                        operationId = "old-format-id"
                        operationType = "NodeAdd"
                        description = "旧形式操作"
                        timestamp = "2025-01-01 00:00:00"
                        memory_before = @{ "1" = @(@{ id = "before" }) }
                        memory_after = @{ "1" = @(@{ id = "after" }) }
                        code_before = $null
                        code_after = $null
                    }
                )
                CurrentHistoryPosition = 1
                MaxHistoryCount = 50
                version = 1
            }
            $oldFormatHistory | ConvertTo-Json -Depth 10 | Set-Content -Path $historyPath -Encoding UTF8

            # memory.jsonを更新後の状態に
            $memoryPath = Join-Path $script:TestFolder 'memory.json'
            @{ "1" = @(@{ id = "after" }) } | ConvertTo-Json -Depth 10 | Set-Content -Path $memoryPath -Encoding UTF8

            $result = Undo-Operation -FolderPath $script:TestFolder

            $result.success | Should Be $true
        }
    }

    Context "連続Undo" {
        It "複数回のUndoが正しく動作する" {
            # 3つの操作を記録
            for ($i = 1; $i -le 3; $i++) {
                Record-Operation `
                    -FolderPath $script:TestFolder `
                    -OperationType "NodeAdd" `
                    -Description "操作 $i" | Out-Null
            }

            # 3回Undo
            $result1 = Undo-Operation -FolderPath $script:TestFolder
            $result2 = Undo-Operation -FolderPath $script:TestFolder
            $result3 = Undo-Operation -FolderPath $script:TestFolder

            $result1.position | Should Be 2
            $result2.position | Should Be 1
            $result3.position | Should Be 0
            $result3.canUndo | Should Be $false
        }
    }
}

# ================================================================
# Redo-Operation のテスト
# ================================================================
Describe "Redo-Operation" {

    BeforeEach {
        $global:HistoryStack = $null
        $global:CurrentHistoryPosition = 0
        $global:MaxHistoryCount = 50

        $script:TestFolder = Join-Path $TestRootPath "test_$(Get-Random)"
        New-Item -ItemType Directory -Path $script:TestFolder -Force | Out-Null

        Initialize-HistoryStack -FolderPath $script:TestFolder | Out-Null

        # memory.jsonを作成
        $memoryPath = Join-Path $script:TestFolder 'memory.json'
        @{ "1" = @() } | ConvertTo-Json -Depth 10 | Set-Content -Path $memoryPath -Encoding UTF8
    }

    AfterEach {
        if (Test-Path $script:TestFolder) {
            Remove-Item -Path $script:TestFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "基本的なRedo操作" {
        It "Undo後にRedoが成功する" {
            # 操作を記録してUndo
            $memBefore = @{ "1" = @() }
            $memAfter = @{ "1" = @(@{ id = "node-1" }) }

            Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeAdd" `
                -Description "ノードを追加" `
                -MemoryBefore $memBefore `
                -MemoryAfter $memAfter | Out-Null

            Undo-Operation -FolderPath $script:TestFolder | Out-Null

            $result = Redo-Operation -FolderPath $script:TestFolder

            $result.success | Should Be $true
            $result.position | Should Be 1
            $result.canRedo | Should Be $false
            $result.canUndo | Should Be $true
        }

        It "Redoした操作の情報が返される" {
            Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "CodeUpdate" `
                -Description "コードを更新" | Out-Null

            Undo-Operation -FolderPath $script:TestFolder | Out-Null
            $result = Redo-Operation -FolderPath $script:TestFolder

            $result.operation.type | Should Be "CodeUpdate"
            $result.operation.description | Should Be "コードを更新"
        }
    }

    Context "Redo不可能な状態" {
        It "Undoしていない場合、Redoが失敗する" {
            Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeAdd" `
                -Description "操作1" | Out-Null

            $result = Redo-Operation -FolderPath $script:TestFolder

            $result.success | Should Be $false
            $result.error | Should Match "Redo不可"
            $result.canRedo | Should Be $false
        }

        It "履歴が空の場合、Redoが失敗する" {
            $result = Redo-Operation -FolderPath $script:TestFolder

            $result.success | Should Be $false
        }

        It "history.jsonが存在しない場合、エラーが返される" {
            $emptyFolder = Join-Path $TestRootPath "empty_$(Get-Random)"
            New-Item -ItemType Directory -Path $emptyFolder -Force | Out-Null

            try {
                $result = Redo-Operation -FolderPath $emptyFolder

                $result.success | Should Be $false
                $result.error | Should Match "履歴ファイルが見つかりません"
            }
            finally {
                Remove-Item -Path $emptyFolder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context "差分復元（v2形式）" {
        It "影響を受けたレイヤーのみが復元される" {
            # 初期状態
            $memoryPath = Join-Path $script:TestFolder 'memory.json'
            $initialMemory = @{
                "1" = @(@{ id = "n1"; value = "original" })
            }
            $initialMemory | ConvertTo-Json -Depth 10 | Set-Content -Path $memoryPath -Encoding UTF8

            # 操作を記録
            $memBefore = @{ "1" = @(@{ id = "n1"; value = "original" }) }
            $memAfter = @{ "1" = @(@{ id = "n1"; value = "modified" }) }

            Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeUpdate" `
                -Description "ノードを更新" `
                -MemoryBefore $memBefore `
                -MemoryAfter $memAfter | Out-Null

            # Undo
            Undo-Operation -FolderPath $script:TestFolder | Out-Null

            # Redo
            $result = Redo-Operation -FolderPath $script:TestFolder

            $result.success | Should Be $true

            # memory.jsonを確認
            $restoredMemory = Get-Content -Path $memoryPath -Raw | ConvertFrom-Json
            $restoredMemory."1"[0].value | Should Be "modified"
        }
    }

    Context "連続Redo" {
        It "複数回のRedoが正しく動作する" {
            # 3つの操作を記録
            for ($i = 1; $i -le 3; $i++) {
                Record-Operation `
                    -FolderPath $script:TestFolder `
                    -OperationType "NodeAdd" `
                    -Description "操作 $i" | Out-Null
            }

            # 3回Undo
            Undo-Operation -FolderPath $script:TestFolder | Out-Null
            Undo-Operation -FolderPath $script:TestFolder | Out-Null
            Undo-Operation -FolderPath $script:TestFolder | Out-Null

            # 3回Redo
            $result1 = Redo-Operation -FolderPath $script:TestFolder
            $result2 = Redo-Operation -FolderPath $script:TestFolder
            $result3 = Redo-Operation -FolderPath $script:TestFolder

            $result1.position | Should Be 1
            $result2.position | Should Be 2
            $result3.position | Should Be 3
            $result3.canRedo | Should Be $false
        }
    }

    Context "Undo/Redo組み合わせ" {
        It "Undo→Redo→Undoのシーケンスが正しく動作する" {
            Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeAdd" `
                -Description "操作1" | Out-Null

            $undoResult = Undo-Operation -FolderPath $script:TestFolder
            $redoResult = Redo-Operation -FolderPath $script:TestFolder
            $undoAgain = Undo-Operation -FolderPath $script:TestFolder

            $undoResult.position | Should Be 0
            $redoResult.position | Should Be 1
            $undoAgain.position | Should Be 0
        }
    }
}

# ================================================================
# Get-HistoryStatus のテスト
# ================================================================
Describe "Get-HistoryStatus" {

    BeforeEach {
        $global:HistoryStack = $null
        $global:CurrentHistoryPosition = 0
        $global:MaxHistoryCount = 50

        $script:TestFolder = Join-Path $TestRootPath "test_$(Get-Random)"
        New-Item -ItemType Directory -Path $script:TestFolder -Force | Out-Null

        Initialize-HistoryStack -FolderPath $script:TestFolder | Out-Null
    }

    AfterEach {
        if (Test-Path $script:TestFolder) {
            Remove-Item -Path $script:TestFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "履歴が空の状態" {
        It "空の履歴で正しいステータスが返される" {
            $status = Get-HistoryStatus -FolderPath $script:TestFolder

            $status.success | Should Be $true
            $status.canUndo | Should Be $false
            $status.canRedo | Should Be $false
            $status.position | Should Be 0
            $status.totalCount | Should Be 0
        }
    }

    Context "履歴がある状態" {
        It "操作追加後に正しいステータスが返される" {
            Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeAdd" `
                -Description "操作1" | Out-Null

            $status = Get-HistoryStatus -FolderPath $script:TestFolder

            $status.success | Should Be $true
            $status.canUndo | Should Be $true
            $status.canRedo | Should Be $false
            $status.position | Should Be 1
            $status.totalCount | Should Be 1
        }

        It "Undo後に正しいステータスが返される" {
            Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeAdd" `
                -Description "操作1" | Out-Null

            Undo-Operation -FolderPath $script:TestFolder | Out-Null

            $status = Get-HistoryStatus -FolderPath $script:TestFolder

            $status.canUndo | Should Be $false
            $status.canRedo | Should Be $true
            $status.position | Should Be 0
        }

        It "複数操作後の中間位置で正しいステータスが返される" {
            for ($i = 1; $i -le 5; $i++) {
                Record-Operation `
                    -FolderPath $script:TestFolder `
                    -OperationType "NodeAdd" `
                    -Description "操作 $i" | Out-Null
            }

            Undo-Operation -FolderPath $script:TestFolder | Out-Null
            Undo-Operation -FolderPath $script:TestFolder | Out-Null

            $status = Get-HistoryStatus -FolderPath $script:TestFolder

            $status.canUndo | Should Be $true
            $status.canRedo | Should Be $true
            $status.position | Should Be 3
            $status.totalCount | Should Be 5
        }
    }

    Context "最近の操作履歴" {
        It "最近の操作が取得できる" {
            for ($i = 1; $i -le 3; $i++) {
                Record-Operation `
                    -FolderPath $script:TestFolder `
                    -OperationType "NodeAdd" `
                    -Description "操作 $i" | Out-Null
            }

            $status = Get-HistoryStatus -FolderPath $script:TestFolder

            $status.recentOperations.Count | Should Be 3
            $status.recentOperations[0].description | Should Be "操作 1"
            $status.recentOperations[2].description | Should Be "操作 3"
        }

        It "最大5件の履歴が返される" {
            for ($i = 1; $i -le 10; $i++) {
                Record-Operation `
                    -FolderPath $script:TestFolder `
                    -OperationType "NodeAdd" `
                    -Description "操作 $i" | Out-Null
            }

            $status = Get-HistoryStatus -FolderPath $script:TestFolder

            $status.recentOperations.Count | Should Be 5
        }
    }

    Context "history.jsonが存在しない場合" {
        It "自動的に初期化される" {
            $newFolder = Join-Path $TestRootPath "no_history_$(Get-Random)"
            New-Item -ItemType Directory -Path $newFolder -Force | Out-Null

            try {
                $status = Get-HistoryStatus -FolderPath $newFolder

                $status.success | Should Be $true
                $status.position | Should Be 0
            }
            finally {
                Remove-Item -Path $newFolder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context "maxCount設定" {
        It "カスタムMaxHistoryCountが正しく取得される" {
            # カスタム設定のhistory.jsonを作成
            $historyPath = Join-Path $script:TestFolder 'history.json'
            $customHistory = @{
                HistoryStack = @()
                CurrentHistoryPosition = 0
                MaxHistoryCount = 100
            }
            $customHistory | ConvertTo-Json -Depth 10 | Set-Content -Path $historyPath -Encoding UTF8

            $status = Get-HistoryStatus -FolderPath $script:TestFolder

            $status.maxCount | Should Be 100
        }
    }
}

# ================================================================
# Clear-HistoryStack のテスト
# ================================================================
Describe "Clear-HistoryStack" {

    BeforeEach {
        $global:HistoryStack = $null
        $global:CurrentHistoryPosition = 0
        $global:MaxHistoryCount = 50

        $script:TestFolder = Join-Path $TestRootPath "test_$(Get-Random)"
        New-Item -ItemType Directory -Path $script:TestFolder -Force | Out-Null

        Initialize-HistoryStack -FolderPath $script:TestFolder | Out-Null
    }

    AfterEach {
        if (Test-Path $script:TestFolder) {
            Remove-Item -Path $script:TestFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "基本的なクリア操作" {
        It "履歴が正しくクリアされる" {
            # 操作を追加
            for ($i = 1; $i -le 5; $i++) {
                Record-Operation `
                    -FolderPath $script:TestFolder `
                    -OperationType "NodeAdd" `
                    -Description "操作 $i" | Out-Null
            }

            $result = Clear-HistoryStack -FolderPath $script:TestFolder

            $result.success | Should Be $true
            $global:HistoryStack.Count | Should Be 0
            $global:CurrentHistoryPosition | Should Be 0
        }

        It "history.jsonがクリアされる" {
            Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeAdd" `
                -Description "操作1" | Out-Null

            Clear-HistoryStack -FolderPath $script:TestFolder | Out-Null

            $historyPath = Join-Path $script:TestFolder 'history.json'
            $data = Get-Content -Path $historyPath -Raw | ConvertFrom-Json

            $data.HistoryStack.Count | Should Be 0
            $data.CurrentHistoryPosition | Should Be 0
        }
    }

    Context "クリア後のUndo/Redo" {
        It "クリア後はUndo/Redoができない" {
            Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeAdd" `
                -Description "操作1" | Out-Null

            Clear-HistoryStack -FolderPath $script:TestFolder | Out-Null

            $status = Get-HistoryStatus -FolderPath $script:TestFolder

            $status.canUndo | Should Be $false
            $status.canRedo | Should Be $false
        }
    }

    Context "空の履歴のクリア" {
        It "空の履歴でもクリアが成功する" {
            $result = Clear-HistoryStack -FolderPath $script:TestFolder

            $result.success | Should Be $true
        }
    }
}

# ================================================================
# 統合テスト
# ================================================================
Describe "統合テスト" {

    BeforeEach {
        $global:HistoryStack = $null
        $global:CurrentHistoryPosition = 0
        $global:MaxHistoryCount = 50

        $script:TestFolder = Join-Path $TestRootPath "integration_$(Get-Random)"
        New-Item -ItemType Directory -Path $script:TestFolder -Force | Out-Null

        # memory.jsonを作成
        $memoryPath = Join-Path $script:TestFolder 'memory.json'
        @{ "1" = @() } | ConvertTo-Json -Depth 10 | Set-Content -Path $memoryPath -Encoding UTF8
    }

    AfterEach {
        if (Test-Path $script:TestFolder) {
            Remove-Item -Path $script:TestFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "完全なワークフロー" {
        It "初期化→記録→Undo→Redo→クリアのフローが正しく動作する" {
            # 1. 初期化
            $initResult = Initialize-HistoryStack -FolderPath $script:TestFolder
            $initResult.success | Should Be $true

            # 2. 操作を記録
            $memBefore = @{ "1" = @() }
            $memAfter = @{ "1" = @(@{ id = "n1" }) }

            $recordResult = Record-Operation `
                -FolderPath $script:TestFolder `
                -OperationType "NodeAdd" `
                -Description "ノード追加" `
                -MemoryBefore $memBefore `
                -MemoryAfter $memAfter
            $recordResult.success | Should Be $true

            # 3. ステータス確認
            $status = Get-HistoryStatus -FolderPath $script:TestFolder
            $status.canUndo | Should Be $true
            $status.canRedo | Should Be $false

            # 4. Undo
            $undoResult = Undo-Operation -FolderPath $script:TestFolder
            $undoResult.success | Should Be $true

            # 5. ステータス確認
            $status = Get-HistoryStatus -FolderPath $script:TestFolder
            $status.canUndo | Should Be $false
            $status.canRedo | Should Be $true

            # 6. Redo
            $redoResult = Redo-Operation -FolderPath $script:TestFolder
            $redoResult.success | Should Be $true

            # 7. クリア
            $clearResult = Clear-HistoryStack -FolderPath $script:TestFolder
            $clearResult.success | Should Be $true

            # 8. 最終ステータス確認
            $status = Get-HistoryStatus -FolderPath $script:TestFolder
            $status.totalCount | Should Be 0
        }
    }

    Context "複雑なUndo/Redoシナリオ" {
        It "分岐操作後のUndo/Redoが正しく動作する" {
            Initialize-HistoryStack -FolderPath $script:TestFolder | Out-Null

            # 操作A, B, C を記録
            Record-Operation -FolderPath $script:TestFolder -OperationType "NodeAdd" -Description "操作A" | Out-Null
            Record-Operation -FolderPath $script:TestFolder -OperationType "NodeAdd" -Description "操作B" | Out-Null
            Record-Operation -FolderPath $script:TestFolder -OperationType "NodeAdd" -Description "操作C" | Out-Null

            # 2回Undo（操作A位置に戻る）
            Undo-Operation -FolderPath $script:TestFolder | Out-Null
            Undo-Operation -FolderPath $script:TestFolder | Out-Null

            # 新しい操作Dを記録（操作B, Cは消える）
            Record-Operation -FolderPath $script:TestFolder -OperationType "NodeAdd" -Description "操作D" | Out-Null

            $status = Get-HistoryStatus -FolderPath $script:TestFolder
            $status.totalCount | Should Be 2  # 操作AとD
            $status.position | Should Be 2

            # Redo不可能（分岐が消えたため）
            $status.canRedo | Should Be $false
        }
    }

    Context "大量操作のパフォーマンス" {
        It "50件の操作を記録してもエラーが発生しない" {
            Initialize-HistoryStack -FolderPath $script:TestFolder | Out-Null

            for ($i = 1; $i -le 50; $i++) {
                $result = Record-Operation `
                    -FolderPath $script:TestFolder `
                    -OperationType "NodeAdd" `
                    -Description "操作 $i"

                $result.success | Should Be $true
            }

            $status = Get-HistoryStatus -FolderPath $script:TestFolder
            $status.totalCount | Should Be 50
        }

        It "最大履歴数を超える操作で古い履歴が削除される" {
            $global:MaxHistoryCount = 10
            Initialize-HistoryStack -FolderPath $script:TestFolder | Out-Null

            for ($i = 1; $i -le 20; $i++) {
                Record-Operation `
                    -FolderPath $script:TestFolder `
                    -OperationType "NodeAdd" `
                    -Description "操作 $i" | Out-Null
            }

            $status = Get-HistoryStatus -FolderPath $script:TestFolder
            $status.totalCount | Should Be 10

            # 最初の10件（操作1-10）が削除されている
            # 残っているのは操作11-20
        }
    }
}

# ================================================================
# テスト後のクリーンアップ
# ================================================================
if (Test-Path $TestRootPath) {
    Remove-Item -Path $TestRootPath -Recurse -Force -ErrorAction SilentlyContinue
}
