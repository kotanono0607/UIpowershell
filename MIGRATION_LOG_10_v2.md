# 10_変数機能_変数管理UI_v2.ps1 - 変更ログ

## 📋 概要

**ファイル名**: `10_変数機能_変数管理UI_v2.ps1`
**作成日**: 2025-11-02
**目的**: Windows Formsダイアログを使わずにデータ操作のみを提供し、REST API経由で呼び出せるようにする
**難易度**: ★★☆☆☆（軽微〜中程度の修正）

---

## 📊 変更統計

| 項目 | 元のファイル | v2ファイル | 変更 |
|-----|------------|-----------|------|
| **行数** | 453行 | 776行 | +323行 |
| **関数数** | 3個 | 10個 | +7個 |
| **UI依存関数** | 1個（全体） | 0個（v2関数群） | UI完全分離 |

**行数が増えた理由**:
- UI非依存の関数を7個追加（280行）
- 詳細なコメント・ドキュメント追加（40行）
- 既存のWindows Forms版を維持（453行）

---

## 🔧 主な変更内容

### 戦略: UI完全分離アプローチ

元のファイルは**全体が1つのWindows Formsダイアログ**（453行）だったため、以下の戦略を採用：

```
既存の Show-VariableManagerForm (453行)
    ↓
分離
    ↓
┌─────────────────────────────────────┐
│ UI非依存関数群（新規追加）          │
│  - Get-VariableList_v2              │
│  - Get-Variable_v2                  │
│  - Add-Variable_v2                  │
│  - Remove-Variable_v2               │
│  - Export-VariablesToJson_v2        │
│  - Import-VariablesFromJson_v2      │
│  - Add-VariableToGlobal_v2          │
└─────────────────────────────────────┘
            ↓
HTML/JS版からREST API経由で呼び出し
```

---

## 🆕 新しい関数群（UI非依存版）

### 1. `Get-VariableList_v2` - 変数一覧取得

**目的**: すべての変数を取得し、構造化データとして返す

**シグネチャ**:
```powershell
function Get-VariableList_v2 {
    param (
        [bool]$IncludeDisplayValue = $true
    )
}
```

**戻り値**:
```powershell
@{
    success = $true
    variables = @(
        @{ name = "Excel2次元配列"; value = @(...); type = "二次元"; displayValue = "..." },
        @{ name = "GINPパス"; value = "C:\..."; type = "単一値"; displayValue = "C:\..." }
    )
    count = 2
}
```

**使用例（REST API）**:
```powershell
New-PolarisRoute -Path "/api/variables" -Method GET -ScriptBlock {
    $result = Get-VariableList_v2
    $Response.Json($result)
}
```

---

### 2. `Get-Variable_v2` - 特定の変数取得

**目的**: 変数名を指定して変数を取得

**シグネチャ**:
```powershell
function Get-Variable_v2 {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
}
```

**戻り値**:
```powershell
@{
    success = $true
    name = "Excel2次元配列"
    value = @(@("A", "B"), @("C", "D"))
    type = "二次元"
}
```

**使用例（REST API）**:
```powershell
New-PolarisRoute -Path "/api/variables/:name" -Method GET -ScriptBlock {
    $name = $Request.Parameters.name
    $result = Get-Variable_v2 -Name $name
    $Response.Json($result)
}
```

---

### 3. `Add-Variable_v2` - 変数追加/更新

**目的**: 変数を追加または更新

**シグネチャ**:
```powershell
function Add-Variable_v2 {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        $Value,

        [ValidateSet("単一値", "一次元", "二次元")]
        [string]$Type = "単一値"
    )
}
```

**使用例**:
```powershell
# 単一値
$result = Add-Variable_v2 -Name "test" -Value "hello" -Type "単一値"

# 一次元配列
$result = Add-Variable_v2 -Name "arr" -Value @("A", "B", "C") -Type "一次元"

# 二次元配列
$result = Add-Variable_v2 -Name "matrix" -Value @(@("A", "B"), @("C", "D")) -Type "二次元"
```

**戻り値**:
```powershell
@{
    success = $true
    message = "変数 'test' を追加/更新しました"
    name = "test"
    type = "単一値"
}
```

**使用例（REST API）**:
```powershell
New-PolarisRoute -Path "/api/variables" -Method POST -ScriptBlock {
    $body = $Request.Body | ConvertFrom-Json

    $result = Add-Variable_v2 `
        -Name $body.name `
        -Value $body.value `
        -Type $body.type

    if ($result.success) {
        $Response.Json($result)
    } else {
        $Response.SetStatusCode(400)
        $Response.Json($result)
    }
}
```

---

### 4. `Remove-Variable_v2` - 変数削除

**目的**: 変数を削除

**シグネチャ**:
```powershell
function Remove-Variable_v2 {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
}
```

**戻り値**:
```powershell
@{
    success = $true
    message = "変数 'test' を削除しました"
}
```

**使用例（REST API）**:
```powershell
New-PolarisRoute -Path "/api/variables/:name" -Method DELETE -ScriptBlock {
    $name = $Request.Parameters.name
    $result = Remove-Variable_v2 -Name $name
    $Response.Json($result)
}
```

---

### 5. `Export-VariablesToJson_v2` - JSON出力

**目的**: 変数をJSONファイルに保存

**シグネチャ**:
```powershell
function Export-VariablesToJson_v2 {
    param (
        [string]$Path = $null,
        [bool]$CreateDirectory = $true
    )
}
```

**戻り値**:
```powershell
@{
    success = $true
    message = "変数がJSON形式で保存されました"
    path = "C:\path\to\variables.json"
    count = 5
}
```

**使用例（REST API）**:
```powershell
New-PolarisRoute -Path "/api/variables/export" -Method POST -ScriptBlock {
    $result = Export-VariablesToJson_v2
    $Response.Json($result)
}
```

---

### 6. `Import-VariablesFromJson_v2` - JSON読み込み

**目的**: JSONファイルから変数を読み込む

**シグネチャ**:
```powershell
function Import-VariablesFromJson_v2 {
    param (
        [string]$Path = $null,
        [bool]$Merge = $true
    )
}
```

**パラメータ**:
- `Path`: 読み込み元ファイルパス（省略時は `$global:JSONPath` を使用）
- `Merge`: 既存の変数とマージするか（`$false` の場合、既存の変数をクリア）

**戻り値**:
```powershell
@{
    success = $true
    message = "JSONファイルを読み込みました"
    path = "C:\path\to\variables.json"
    count = 5
}
```

**使用例（REST API）**:
```powershell
New-PolarisRoute -Path "/api/variables/import" -Method POST -ScriptBlock {
    $body = $Request.Body | ConvertFrom-Json

    $result = Import-VariablesFromJson_v2 `
        -Path $body.path `
        -Merge $body.merge

    $Response.Json($result)
}
```

---

### 7. `Add-VariableToGlobal_v2` - 内部ヘルパー関数

**目的**: 変数をグローバル変数辞書に追加する（型判定付き）

**シグネチャ**:
```powershell
function Add-VariableToGlobal_v2 {
    param($key, $value)
}
```

**効果**:
- 単一値、一次元配列、二次元配列を自動判定
- JSON読み込み時に使用

---

## 🔄 既存関数の変更

### `Show-VariableManagerForm` - 後方互換性維持

**Before（元のファイル）**:
```powershell
function Show-VariableManagerForm {
    # 全体がWindows Formsダイアログ（453行）
}
```

**After（v2ファイル）**:
```powershell
function Show-VariableManagerForm {
    param (
        [bool]$showUI = $true    # 🆕 UI表示フラグ
    )

    # UI非表示の場合は、変数一覧をJSON形式で返す
    if (-not $showUI) {
        return Get-VariableList_v2
    }

    # 既存のWindows Formsダイアログ（元のまま）
    # ただし、ボタンイベントでv2関数を使用
}
```

**変更点**:
1. `$showUI` パラメータを追加
2. `$showUI = $false` の場合、v2関数を使用
3. ボタンイベント内で v2関数を呼び出すように変更:
   - `$btnAddUpdate.add_Click` → `Add-Variable_v2` を使用
   - `$btnDelete.add_Click` → `Remove-Variable_v2` を使用
   - `$btnExportJson.add_Click` → `Export-VariablesToJson_v2` を使用
   - `$btnImportJson.add_Click` → `Import-VariablesFromJson_v2` を使用

**効果**:
- ✅ Windows Forms版とv2関数が同じロジックを共有
- ✅ ロジックの重複を削減
- ✅ バグ修正が1箇所で済む

---

## 📚 使用例

### Windows Forms版での使用（変更なし）

```powershell
# 既存のコード（変更不要）
. ".\10_変数機能_変数管理UI_v2.ps1"

$selectedVar = Show-VariableManagerForm
```

### HTML/JS版での使用（REST API経由）

#### ① 変数一覧取得

**PowerShell（adapter/api-server.ps1）**:
```powershell
New-PolarisRoute -Path "/api/variables" -Method GET -ScriptBlock {
    $result = Get-VariableList_v2
    $Response.Json($result)
}
```

**JavaScript（フロントエンド）**:
```javascript
const response = await fetch('/api/variables');
const result = await response.json();

if (result.success) {
    console.log('変数一覧:', result.variables);
    console.log('変数数:', result.count);
}
```

#### ② 変数追加

**PowerShell（adapter/api-server.ps1）**:
```powershell
New-PolarisRoute -Path "/api/variables" -Method POST -ScriptBlock {
    $body = $Request.Body | ConvertFrom-Json

    $result = Add-Variable_v2 `
        -Name $body.name `
        -Value $body.value `
        -Type $body.type

    $Response.Json($result)
}
```

**JavaScript（フロントエンド）**:
```javascript
const response = await fetch('/api/variables', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        name: 'testVar',
        value: 'hello',
        type: '単一値'
    })
});

const result = await response.json();

if (result.success) {
    console.log(result.message); // "変数 'testVar' を追加/更新しました"
}
```

#### ③ 変数削除

**JavaScript（フロントエンド）**:
```javascript
const response = await fetch('/api/variables/testVar', {
    method: 'DELETE'
});

const result = await response.json();

if (result.success) {
    console.log(result.message); // "変数 'testVar' を削除しました"
}
```

---

## ✅ テスト項目

### 手動テスト

- [ ] Windows Forms版で変数管理ダイアログが表示されることを確認
- [ ] Windows Forms版で変数の追加/更新/削除が動作することを確認
- [ ] v2関数で変数一覧を取得できることを確認
- [ ] v2関数で変数を追加/更新/削除できることを確認
- [ ] v2関数でJSON出力/読み込みが動作することを確認
- [ ] エラー時に適切なエラー情報が返されることを確認

### 自動テスト（将来的に実装）

```powershell
Describe "10_変数機能_変数管理UI_v2" {
    BeforeEach {
        $global:variables = @{}
    }

    It "Get-VariableList_v2: 空の変数一覧を取得" {
        $result = Get-VariableList_v2
        $result.success | Should -Be $true
        $result.count | Should -Be 0
    }

    It "Add-Variable_v2: 単一値を追加" {
        $result = Add-Variable_v2 -Name "test" -Value "hello" -Type "単一値"
        $result.success | Should -Be $true
        $global:variables["test"] | Should -Be "hello"
    }

    It "Add-Variable_v2: 一次元配列を追加" {
        $result = Add-Variable_v2 -Name "arr" -Value @("A", "B") -Type "一次元"
        $result.success | Should -Be $true
        $global:variables["arr"].Count | Should -Be 2
    }

    It "Remove-Variable_v2: 変数を削除" {
        $global:variables["test"] = "hello"
        $result = Remove-Variable_v2 -Name "test"
        $result.success | Should -Be $true
        $global:variables.ContainsKey("test") | Should -Be $false
    }
}
```

---

## 🎯 移行への影響

### ポジティブな影響

| 項目 | 効果 |
|-----|------|
| **UI完全分離** | ✅ HTML/JS版で完全に再実装可能 |
| **REST API対応** | ✅ すべての変数操作がAPI経由で可能 |
| **テスタビリティ** | ✅ UIなしで変数操作をテスト可能 |
| **コードの再利用性** | ✅ Windows Forms版とv2関数が同じロジックを共有 |
| **後方互換性** | ✅ 既存のコードが動作 |

### 注意点

| 項目 | 対応方法 |
|-----|---------|
| **行数増加** | 機能追加のため（UI非依存関数7個） |
| **グローバル変数依存** | 将来的にstate-manager.ps1で管理予定 |
| **Windows Forms版の維持** | 段階的移行のために必要 |

---

## 📝 次のステップ

### すぐに実施すべきこと

1. ✅ このファイルをGit commitする
2. ⬜ 残り4個のv2ファイルを作成する
3. ⬜ adapter/api-server.ps1 にv2関数群を統合する

### 将来的に実施すべきこと

1. ⬜ HTML/JSで変数管理UIを実装
2. ⬜ グローバル変数を state-manager.ps1 で管理
3. ⬜ 単体テストを追加

---

## 📈 Phase 2 進捗状況

```
Phase 2: v2ファイル作成（6個）

1/6 ✅ 12_コードメイン_コード本文_v2.ps1         完了
2/6 ✅ 10_変数機能_変数管理UI_v2.ps1             完了 ← 今ここ
3/6 ⬜ 07_メインF機能_ツールバー作成_v2.ps1      未着手
4/6 ⬜ 08_メインF機能_メインボタン処理_v2.ps1    未着手
5/6 ⬜ 02-6_削除処理_v2.ps1                      未着手
6/6 ⬜ 02-2_ネスト規制バリデーション_v2.ps1      未着手

進捗: 33.3% (2/6)
```

---

**作成者**: Claude AI Assistant
**バージョン**: 1.0
**最終更新**: 2025-11-02
