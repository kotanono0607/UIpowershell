# 07_メインF機能_ツールバー作成_v2.ps1 - 変更ログ

## 📋 概要

**ファイル名**: `07_メインF機能_ツールバー作成_v2.ps1`
**作成日**: 2025-11-02
**目的**: メニュー構造をデータとして管理し、REST API経由でメニュー操作を可能にする
**難易度**: ★★☆☆☆（中程度の修正）

---

## 📊 変更統計

| 項目 | 元のファイル | v2ファイル | 変更 |
|-----|------------|-----------|------|
| **行数** | 70行 | 355行 | +285行 |
| **関数数** | 3個 | 8個 | +5個 |
| **UI依存関数** | 3個（全体） | 0個（v2関数群） | UI完全分離 |

**行数が増えた理由**:
- UI非依存の関数を5個追加（200行）
- 詳細なコメント・ドキュメント追加（80行）
- 既存のWindows Forms版を維持（70行）

---

## 🔧 主な変更内容

### 戦略: メニューデータ管理アプローチ

元のファイルは**Windows Formsオブジェクトを直接操作**していたため、以下の戦略を採用：

```
既存: Windows Forms ToolStrip/ToolStripMenuItem を直接作成
    ↓
分離
    ↓
新: メニュー構造をデータ（ハッシュテーブル）として管理
    + アクションをグローバル辞書に登録
    + アクションIDで実行可能
    ↓
HTML/JS版からREST API経由で呼び出し
```

---

## 🆕 新しい関数群（UI非依存版）

### 1. `Get-MenuStructure_v2` - メニュー構造をデータとして取得

**目的**: メニュー構造をWindows Formsオブジェクトではなく、ハッシュテーブルとして返す

**シグネチャ**:
```powershell
function Get-MenuStructure_v2 {
    param (
        [Parameter(Mandatory=$true)]
        [array]$MenuStructure,

        [bool]$IncludeActionIds = $true
    )
}
```

**Before（Windows Forms版）**:
```powershell
# メニュー構造から直接ToolStripMenuItemを作成
$項目 = New-Object System.Windows.Forms.ToolStripMenuItem
$項目.Text = $テキスト
$項目.Add_Click($アクション)
```

**After（UI非依存版）**:
```powershell
# メニュー構造をデータとして返す
@{
    success = $true
    menus = @(
        @{
            name = "ファイル"
            tooltip = "ファイル操作"
            items = @(
                @{ text = "開く"; actionId = "ファイル_開く" },
                @{ text = "保存"; actionId = "ファイル_保存" }
            )
        }
    )
    count = 1
}
```

**使用例（REST API）**:
```powershell
New-PolarisRoute -Path "/api/menus" -Method GET -ScriptBlock {
    $menus = @(
        @{
            名前 = "ファイル"
            ツールチップ = "ファイル操作"
            項目 = @(
                @{ テキスト = "開く"; アクション = { 開くアクション } },
                @{ テキスト = "保存"; アクション = { 保存アクション } }
            )
        }
    )

    $result = Get-MenuStructure_v2 -MenuStructure $menus
    $Response.Json($result)
}
```

**JavaScript（フロントエンド）**:
```javascript
const response = await fetch('/api/menus');
const result = await response.json();

if (result.success) {
    // メニューを描画
    result.menus.forEach(menu => {
        console.log('メニュー名:', menu.name);
        menu.items.forEach(item => {
            console.log('  項目:', item.text, 'アクションID:', item.actionId);
        });
    });
}
```

---

### 2. `Register-MenuAction_v2` - メニューアクションを登録

**目的**: メニュー項目のアクション（ScriptBlock）を、アクションIDで登録

**シグネチャ**:
```powershell
function Register-MenuAction_v2 {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ActionId,

        [Parameter(Mandatory=$true)]
        [scriptblock]$Action
    )
}
```

**使用例**:
```powershell
# アクションを登録
Register-MenuAction_v2 -ActionId "file_open" -Action {
    Write-Host "ファイルを開きます"
    # ファイルを開く処理
}

Register-MenuAction_v2 -ActionId "file_save" -Action {
    Write-Host "ファイルを保存します"
    # ファイルを保存する処理
}
```

**戻り値**:
```powershell
@{
    success = $true
    message = "アクション 'file_open' を登録しました"
    actionId = "file_open"
}
```

---

### 3. `Execute-MenuAction_v2` - メニューアクションを実行

**目的**: 登録されたアクションIDを指定して、アクションを実行

**シグネチャ**:
```powershell
function Execute-MenuAction_v2 {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ActionId,

        [hashtable]$Parameters = @{}
    )
}
```

**使用例**:
```powershell
# パラメータなし
$result = Execute-MenuAction_v2 -ActionId "file_open"

# パラメータあり
$result = Execute-MenuAction_v2 -ActionId "file_save" -Parameters @{
    path = "C:\test.txt"
    overwrite = $true
}
```

**戻り値**:
```powershell
@{
    success = $true
    message = "アクション 'file_open' を実行しました"
    actionId = "file_open"
    result = ... # アクションの戻り値
}
```

**使用例（REST API）**:
```powershell
New-PolarisRoute -Path "/api/menus/execute" -Method POST -ScriptBlock {
    $body = $Request.Body | ConvertFrom-Json

    $result = Execute-MenuAction_v2 `
        -ActionId $body.actionId `
        -Parameters $body.parameters

    if ($result.success) {
        $Response.Json($result)
    } else {
        $Response.SetStatusCode(500)
        $Response.Json($result)
    }
}
```

**JavaScript（フロントエンド）**:
```javascript
const response = await fetch('/api/menus/execute', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        actionId: 'file_open',
        parameters: {}
    })
});

const result = await response.json();

if (result.success) {
    console.log('アクション実行成功:', result.message);
}
```

---

### 4. `Get-RegisteredActions_v2` - 登録されているアクション一覧を取得

**目的**: グローバルアクション辞書に登録されているすべてのアクションIDを取得

**シグネチャ**:
```powershell
function Get-RegisteredActions_v2 {
    param ()
}
```

**使用例**:
```powershell
$result = Get-RegisteredActions_v2
```

**戻り値**:
```powershell
@{
    success = $true
    actionIds = @("file_open", "file_save", "edit_copy", "edit_paste")
    count = 4
}
```

**使用例（REST API）**:
```powershell
New-PolarisRoute -Path "/api/menus/actions" -Method GET -ScriptBlock {
    $result = Get-RegisteredActions_v2
    $Response.Json($result)
}
```

---

### 5. `Clear-MenuActions_v2` - 登録されているアクションをクリア

**目的**: グローバルアクション辞書をクリア

**シグネチャ**:
```powershell
function Clear-MenuActions_v2 {
    param ()
}
```

**使用例**:
```powershell
$result = Clear-MenuActions_v2
# 結果: @{ success = $true; message = "4 個のアクションをクリアしました"; count = 4 }
```

---

## 🔄 既存関数の変更

### `ツールバーを追加` - v2関数との統合

**Before（元のファイル）**:
```powershell
function ツールバーを追加 {
    param (
        [System.Windows.Forms.Form]$フォーム,
        [array]$メニュー構造
    )

    # ツールバーを作成（Windows Forms）
    # ...
}
```

**After（v2ファイル）**:
```powershell
function ツールバーを追加 {
    param (
        [System.Windows.Forms.Form]$フォーム,
        [array]$メニュー構造,
        [bool]$RegisterActions = $true    # 🆕 v2関数にアクションを登録
    )

    # 🆕 v2関数にアクションを登録（オプション）
    if ($RegisterActions) {
        Get-MenuStructure_v2 -MenuStructure $メニュー構造 | Out-Null
    }

    # ツールバーを作成（既存のコード）
    # ...
}
```

**変更点**:
- `$RegisterActions` パラメータを追加
- `$RegisterActions = $true` の場合、v2関数にアクションを登録
- Windows Forms版とv2関数が同じアクションを共有

**効果**:
- ✅ Windows Forms版でメニューを作成すると、自動的にv2関数にもアクションが登録される
- ✅ HTML/JS版から同じアクションを実行できる

---

## 📚 使用例

### Windows Forms版での使用

```powershell
# 既存のコード（変更なし）
. ".\07_メインF機能_ツールバー作成_v2.ps1"

$menus = @(
    @{
        名前 = "ファイル"
        ツールチップ = "ファイル操作"
        項目 = @(
            @{ テキスト = "開く"; アクション = { Write-Host "開く" } },
            @{ テキスト = "保存"; アクション = { Write-Host "保存" } }
        )
    }
)

ツールバーを追加 -フォーム $form -メニュー構造 $menus
```

### HTML/JS版での使用（REST API経由）

#### ① メニュー構造取得

**PowerShell（adapter/api-server.ps1）**:
```powershell
. ".\07_メインF機能_ツールバー作成_v2.ps1"

# メニュー構造を定義
$menus = @(
    @{
        名前 = "ファイル"
        ツールチップ = "ファイル操作"
        項目 = @(
            @{ テキスト = "開く"; アクション = { 開くアクション } },
            @{ テキスト = "保存"; アクション = { 保存アクション } }
        )
    },
    @{
        名前 = "編集"
        ツールチップ = "編集操作"
        項目 = @(
            @{ テキスト = "コピー"; アクション = { コピーアクション } },
            @{ テキスト = "貼り付け"; アクション = { 貼り付けアクション } }
        )
    }
)

New-PolarisRoute -Path "/api/menus" -Method GET -ScriptBlock {
    $result = Get-MenuStructure_v2 -MenuStructure $using:menus
    $Response.Json($result)
}
```

**JavaScript（フロントエンド）**:
```javascript
const response = await fetch('/api/menus');
const result = await response.json();

if (result.success) {
    // メニューバーを描画
    const menuBar = document.getElementById('menubar');

    result.menus.forEach(menu => {
        const dropdown = document.createElement('div');
        dropdown.className = 'menu-dropdown';
        dropdown.textContent = menu.name;
        dropdown.title = menu.tooltip;

        const items = document.createElement('div');
        items.className = 'menu-items';

        menu.items.forEach(item => {
            const menuItem = document.createElement('div');
            menuItem.className = 'menu-item';
            menuItem.textContent = item.text;
            menuItem.onclick = () => executeMenuAction(item.actionId);
            items.appendChild(menuItem);
        });

        dropdown.appendChild(items);
        menuBar.appendChild(dropdown);
    });
}
```

#### ② メニューアクション実行

**PowerShell（adapter/api-server.ps1）**:
```powershell
New-PolarisRoute -Path "/api/menus/execute" -Method POST -ScriptBlock {
    $body = $Request.Body | ConvertFrom-Json

    $result = Execute-MenuAction_v2 `
        -ActionId $body.actionId `
        -Parameters $body.parameters

    $Response.Json($result)
}
```

**JavaScript（フロントエンド）**:
```javascript
async function executeMenuAction(actionId, parameters = {}) {
    const response = await fetch('/api/menus/execute', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            actionId: actionId,
            parameters: parameters
        })
    });

    const result = await response.json();

    if (result.success) {
        console.log('アクション実行成功:', result.message);
    } else {
        console.error('アクション実行エラー:', result.error);
    }
}
```

---

## 🔑 重要な設計パターン

### アクションID命名規則

アクションIDは `{メニュー名}_{項目名}` の形式で自動生成されます：

```
ファイル → 開く      = "ファイル_開く"
ファイル → 保存      = "ファイル_保存"
編集 → コピー        = "編集_コピー"
編集 → 貼り付け      = "編集_貼り付け"
```

**メリット**:
- 一意性が保証される
- 人間が読みやすい
- デバッグが容易

---

### グローバルアクション辞書

```powershell
# グローバル辞書の構造
$global:menuActions = @{
    "ファイル_開く" = { Write-Host "開く" }
    "ファイル_保存" = { Write-Host "保存" }
    "編集_コピー" = { Write-Host "コピー" }
    "編集_貼り付け" = { Write-Host "貼り付け" }
}
```

**メリット**:
- Windows Forms版とHTML/JS版でアクションを共有
- アクションの一元管理
- REST API経由で実行可能

---

## ✅ テスト項目

### 手動テスト

- [ ] Windows Forms版でツールバーが表示されることを確認
- [ ] Windows Forms版でメニュー項目をクリックしてアクションが実行されることを確認
- [ ] v2関数でメニュー構造を取得できることを確認
- [ ] v2関数でアクションを登録・実行できることを確認
- [ ] `ツールバーを追加` でv2関数にアクションが自動登録されることを確認

### 自動テスト（将来的に実装）

```powershell
Describe "07_メインF機能_ツールバー作成_v2" {
    BeforeEach {
        $global:menuActions = @{}
    }

    It "Register-MenuAction_v2: アクションを登録" {
        $result = Register-MenuAction_v2 -ActionId "test" -Action { "test" }
        $result.success | Should -Be $true
        $global:menuActions.ContainsKey("test") | Should -Be $true
    }

    It "Execute-MenuAction_v2: アクションを実行" {
        Register-MenuAction_v2 -ActionId "test" -Action { "hello" }
        $result = Execute-MenuAction_v2 -ActionId "test"
        $result.success | Should -Be $true
        $result.result | Should -Be "hello"
    }

    It "Get-MenuStructure_v2: メニュー構造を取得" {
        $menus = @(
            @{
                名前 = "ファイル"
                項目 = @(
                    @{ テキスト = "開く"; アクション = { "open" } }
                )
            }
        )
        $result = Get-MenuStructure_v2 -MenuStructure $menus
        $result.success | Should -Be $true
        $result.menus.Count | Should -Be 1
        $result.menus[0].items[0].actionId | Should -Be "ファイル_開く"
    }
}
```

---

## 🎯 移行への影響

### ポジティブな影響

| 項目 | 効果 |
|-----|------|
| **UI完全分離** | ✅ メニュー構造をデータとして管理 |
| **REST API対応** | ✅ メニュー取得・アクション実行がAPI経由で可能 |
| **アクション共有** | ✅ Windows Forms版とHTML/JS版で同じアクションを使用 |
| **テスタビリティ** | ✅ UIなしでメニューアクションをテスト可能 |
| **後方互換性** | ✅ 既存のコードが動作 |

### 注意点

| 項目 | 対応方法 |
|-----|---------|
| **グローバル辞書依存** | 将来的にstate-manager.ps1で管理予定 |
| **アクションIDの一意性** | 命名規則を統一（メニュー名_項目名） |
| **Windows Forms版の維持** | 段階的移行のために必要 |

---

## 📝 次のステップ

### すぐに実施すべきこと

1. ✅ このファイルをGit commitする
2. ⬜ 残り3個のv2ファイルを作成する
3. ⬜ adapter/api-server.ps1 にv2関数群を統合する

### 将来的に実施すべきこと

1. ⬜ HTML/JSでメニューバーUIを実装
2. ⬜ グローバルアクション辞書を state-manager.ps1 で管理
3. ⬜ 単体テストを追加

---

## 📈 Phase 2 進捗状況

```
Phase 2: v2ファイル作成（6個）

1/6 ✅ 12_コードメイン_コード本文_v2.ps1         完了
2/6 ✅ 10_変数機能_変数管理UI_v2.ps1             完了
3/6 ✅ 07_メインF機能_ツールバー作成_v2.ps1      完了 ← 今ここ
4/6 ⬜ 08_メインF機能_メインボタン処理_v2.ps1    未着手
5/6 ⬜ 02-6_削除処理_v2.ps1                      未着手
6/6 ⬜ 02-2_ネスト規制バリデーション_v2.ps1      未着手

進捗: 50.0% (3/6)
```

---

**作成者**: Claude AI Assistant
**バージョン**: 1.0
**最終更新**: 2025-11-02
