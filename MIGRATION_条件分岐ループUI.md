# 条件分岐・ループUI 移行ドキュメント

**作成日**: 2025-11-15
**対象**: 条件分岐・ループノードの編集UI
**移行内容**: Web UIモーダル → PowerShell Windows Forms

---

## 📋 概要

条件分岐（処理番号1-2）とループ（処理番号1-3）のパラメータ入力UIを、Web UIモーダルダイアログからPowerShell Windows Forms方式に移行しました。

### 移行の目的

1. **コードの一貫性向上**
   - 他のパラメータ入力UI（3-1.ps1、5-1.ps1、1-8.ps1など）と同じ実装方式に統一
   - メンテナンス性とコードの理解しやすさを向上

2. **アーキテクチャの統一**
   - Web UI（JavaScript）とPowerShell Windows Formsの二重実装を解消
   - すべてのパラメータ入力をPowerShell側で統一的に処理

---

## 🔄 変更内容

### 1. 新規ファイル作成

#### `00_code/1-2.ps1` (条件分岐ラッパー)
```powershell
function 1_2 {
    # 責任: ShowConditionBuilderを呼び出し、条件分岐コードを生成
    # 戻り値: 生成された条件分岐コード（キャンセル時はnull）

    # 依存ファイル読み込み:
    # - 00_共通ユーティリティ_JSON操作.ps1
    # - 15_コードサブ_if文条件式作成.ps1

    $conditionCode = ShowConditionBuilder
    return $conditionCode
}
```

#### `00_code/1-3.ps1` (ループラッパー)
```powershell
function 1_3 {
    # 責任: ShowLoopBuilderを呼び出し、ループコードを生成
    # 戻り値: 生成されたループコード（キャンセル時はnull）

    # 依存ファイル読み込み:
    # - 00_共通ユーティリティ_JSON操作.ps1
    # - 15_コードサブ_if文条件式作成.ps1

    $loopCode = ShowLoopBuilder
    return $loopCode
}
```

---

### 2. 既存ファイル修正

#### `00_共通ユーティリティ_JSON操作.ps1`
**追加内容**: `取得-JSON値` 関数を追加（行320-358）

```powershell
function 取得-JSON値 {
    param (
        [Parameter(Mandatory=$true)]
        [string]$jsonFilePath,

        [Parameter(Mandatory=$true)]
        [string]$keyName
    )

    # JSONファイルから指定されたキーの値を取得
    # Read-JsonSafeを使用した安全な読み込み
}
```

**理由**:
- archive/02-5_コンテキストメニュー編集.ps1に存在していた関数を共通化
- ShowConditionBuilder/ShowLoopBuilderがJSONPathを自動取得する際に必要

---

#### `15_コードサブ_if文条件式作成.ps1`
**修正箇所**: ShowConditionBuilder、ShowLoopBuilder両関数のJSONPath取得ロジック

**変更前**:
```powershell
function ShowConditionBuilder {
    param(
        [string]$JSONPath = $global:JSONPath  # グローバル変数に依存
    )
    # ...
}
```

**変更後**:
```powershell
function ShowConditionBuilder {
    param(
        [string]$JSONPath  # デフォルト値なし
    )

    # JSONPathが未指定の場合は、プロジェクトルートから取得
    if (-not $JSONPath) {
        try {
            if ($script:RootDir) {
                $rootPath = $script:RootDir
            } else {
                $rootPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
            }
            $メインJsonPath = Join-Path $rootPath "03_history\メイン.json"
            $utilityPath = Join-Path $rootPath "00_共通ユーティリティ_JSON操作.ps1"

            if (Test-Path $utilityPath) {
                . $utilityPath
            }

            if (Test-Path $メインJsonPath) {
                $folderPath = 取得-JSON値 -jsonFilePath $メインJsonPath -keyName "フォルダパス"
                $JSONPath = Join-Path $folderPath "variables.json"
            }
        } catch {
            Write-Host "[WARNING] JSONPath取得エラー: $_" -ForegroundColor Yellow
            $JSONPath = $null
        }
    }
    # ...
}
```

**削除箇所**:
- 行926-928のグローバル変数初期化コード削除
```powershell
# 削除されたコード:
# if (-not $global:JSONPath) {
#     $global:JSONPath = "C:\default\path\variables.json"
# }
```

**理由**:
- グローバル変数への依存を排除
- 00_code/配下のラッパー関数から呼び出し可能にするため
- 動的なパス解決でより柔軟な実行環境に対応

---

#### `ボタン設定.json`
**修正箇所**: 処理番号1-2、1-3の関数名マッピング

```json
// 変更前:
{
    "処理番号": "1-2",
    "関数名": "ShowConditionBuilder"
}

// 変更後:
{
    "処理番号": "1-2",
    "関数名": "1_2"
}
```

```json
// 変更前:
{
    "処理番号": "1-3",
    "関数名": "ShowLoopBuilder"
}

// 変更後:
{
    "処理番号": "1-3",
    "関数名": "1_3"
}
```

---

#### `ui/app-legacy.js`
**修正箇所1**: ボタンクリックハンドラ（行1519-1542）

**変更前**:
```javascript
if (functionName === 'ShowConditionBuilder') {
    await showConditionBuilderDialog(setting);
} else if (functionName === 'ShowLoopBuilder') {
    await showLoopBuilderDialog(setting);
} else {
    await addNodeToLayer(setting);
}
```

**変更後**:
```javascript
// 全てのボタンで統一的にノード追加処理
await addNodeToLayer(setting);
```

**修正箇所2**: codeGeneratorFunctions マッピング（行5493-5499）

**変更前**:
```javascript
const codeGeneratorFunctions = {
    '1_1': generate_1_1,
    '1_6': generate_1_6,
    '99_1': generate_99_1,
    'ShowConditionBuilder': async () => { /* Web UIダイアログ処理 */ },
    'ShowLoopBuilder': async () => { /* Web UIダイアログ処理 */ }
};
```

**変更後**:
```javascript
const codeGeneratorFunctions = {
    '1_1': generate_1_1,
    '1_6': generate_1_6,
    '99_1': generate_99_1
    // ShowConditionBuilder, ShowLoopBuilderを削除
};
```

**修正箇所3**: generateCode関数の簡素化（行5522-5533）

**変更前**:
```javascript
if (generatorFunc) {
    if (functionName === 'ShowConditionBuilder') {
        entryString = await showConditionBuilderModal();
    } else if (functionName === 'ShowLoopBuilder') {
        entryString = await showLoopBuilderModal();
    } else if (処理番号 === '99-1') {
        entryString = await generatorFunc(直接エントリ);
    } else {
        entryString = await generatorFunc();
    }
}
```

**変更後**:
```javascript
if (generatorFunc) {
    if (処理番号 === '99-1') {
        entryString = await generatorFunc(直接エントリ);
    } else {
        entryString = await generatorFunc();
    }
}
```

---

#### `ui/index-legacy.html`
**修正箇所**: 行310-365のモーダルダイアログHTML削除

**削除されたHTML要素**:
- `condition-builder-modal` (条件分岐ダイアログ)
- `loop-builder-modal` (ループダイアログ)

**変更後**:
```html
<!-- ============================================ -->
<!-- 条件分岐・ループダイアログ (廃止) -->
<!-- ============================================ -->
<!--
[移行完了] 2025-11-15
条件分岐・ループの編集UIをWeb UIモーダルからPowerShell Windows Forms版に移行しました。

変更内容:
- 条件分岐: ShowConditionBuilder → 1_2 (00_code/1-2.ps1)
- ループ: ShowLoopBuilder → 1_3 (00_code/1-3.ps1)

理由:
- 他のパラメータ入力UI (3-1.ps1, 5-1.ps1, 1-8.ps1など) との一貫性向上
- コードの統一化によるメンテナンス性向上

以下のモーダルダイアログは使用されなくなりました:
- condition-builder-modal
- loop-builder-modal
-->
```

---

## 🔍 動作フロー

### 移行前（Web UIモーダル方式）
```
ユーザー操作
  ↓
UI: ボタンクリック (処理番号 1-2 or 1-3)
  ↓
app-legacy.js: showConditionBuilderDialog() / showLoopBuilderDialog()
  ↓
index-legacy.html: モーダルダイアログ表示
  ↓
JavaScript: ユーザー入力収集 → コード生成
  ↓
API: POST /api/node/execute/ShowConditionBuilder (コード文字列を送信)
  ↓
PowerShell: ShowConditionBuilder/ShowLoopBuilder 実行
  ↓
結果返却
```

### 移行後（PowerShell Windows Forms方式）
```
ユーザー操作
  ↓
UI: ボタンクリック (処理番号 1-2 or 1-3)
  ↓
app-legacy.js: addNodeToLayer() (統一的な処理)
  ↓
API: POST /api/node/execute/1_2 or 1_3 (パラメータなし)
  ↓
PowerShell: 00_code/1-2.ps1 or 1-3.ps1 実行
  ↓
PowerShell: 15_コードサブ_if文条件式作成.ps1 読み込み
  ↓
PowerShell Windows Forms: ShowConditionBuilder/ShowLoopBuilder ダイアログ表示
  ↓
PowerShell: ユーザー入力収集 → コード生成
  ↓
結果返却
```

**主な違い**:
- Web UIでのコード生成 → PowerShell側でのコード生成
- JavaScript → PowerShell へ責任が移行
- ダイアログ表示がブラウザ → Windows Formsに変更

---

## ⚠️ 注意事項

### 1. UX変更
- **ダイアログ表示位置**: ブラウザ内 → Windowsネイティブダイアログ
- **見た目**: Web UI（HTML/CSS） → Windows Forms（ネイティブUI）
- **操作感**: ブラウザ内で完結 → PowerShellプロセスが起動

### 2. 依存関係
以下のファイルが正しく配置されている必要があります:
- `00_共通ユーティリティ_JSON操作.ps1`
- `15_コードサブ_if文条件式作成.ps1`
- `03_history/メイン.json` (JSONPath自動取得時に使用)

### 3. エラーハンドリング
- ダイアログのキャンセル時は `$null` を返す
- 依存ファイルが見つからない場合はエラーメッセージを表示し `$null` を返す
- JSONPath取得エラー時は警告を表示して続行（変数なしモード）

---

## 🧪 テスト項目

### 基本動作テスト
- [ ] ボタン「2」（条件分岐）をクリック → PowerShell Windows Formsダイアログが表示される
- [ ] ボタン「3」（ループ）をクリック → PowerShell Windows Formsダイアログが表示される
- [ ] 条件分岐ダイアログで条件を入力 → 正しいコードが生成される
- [ ] ループダイアログでループ設定を入力 → 正しいコードが生成される

### エラーケーステスト
- [ ] 依存ファイル（00_共通ユーティリティ_JSON操作.ps1）が存在しない場合のエラー表示
- [ ] 依存ファイル（15_コードサブ_if文条件式作成.ps1）が存在しない場合のエラー表示
- [ ] ダイアログキャンセル時の挙動（ノードが追加されない）
- [ ] JSONPath取得失敗時の挙動（変数なしモードで続行）

### 統合テスト
- [ ] 条件分岐ノード作成 → ノード展開 → プレビュー表示 → スクリプト保存
- [ ] ループノード作成 → ノード展開 → プレビュー表示 → スクリプト保存
- [ ] 他のパラメータ入力UI（3-1.ps1など）との一貫性確認

---

## 📝 ロールバック手順

万が一問題が発生した場合の復元手順:

### 1. ファイル復元
```powershell
# Gitから変更前の状態を復元
git checkout HEAD~1 -- ボタン設定.json
git checkout HEAD~1 -- ui/app-legacy.js
git checkout HEAD~1 -- ui/index-legacy.html
git checkout HEAD~1 -- 15_コードサブ_if文条件式作成.ps1
```

### 2. 新規ファイル削除
```powershell
Remove-Item "00_code/1-2.ps1"
Remove-Item "00_code/1-3.ps1"
```

### 3. 共通ユーティリティの修正取り消し
`00_共通ユーティリティ_JSON操作.ps1` の行320-358（取得-JSON値関数）を削除

### 4. サーバー再起動
```powershell
# Node.jsサーバーを再起動
# (app.jsを実行しているプロセスを再起動)
```

---

## 📊 移行の影響範囲

### 直接影響のあるファイル（変更済み）
- ✅ `00_code/1-2.ps1` (新規作成)
- ✅ `00_code/1-3.ps1` (新規作成)
- ✅ `00_共通ユーティリティ_JSON操作.ps1` (関数追加)
- ✅ `15_コードサブ_if文条件式作成.ps1` (パス解決修正)
- ✅ `ボタン設定.json` (関数名変更)
- ✅ `ui/app-legacy.js` (ダイアログ処理削除)
- ✅ `ui/index-legacy.html` (モーダルHTML削除)

### 間接影響のあるファイル（変更不要）
- `app.js` (APIエンドポイント /api/node/execute/:functionName は変更なし)
- `13_コードサブ汎用関数.ps1` (リストから項目を選択などの関数は変更なし)

### 影響のないファイル
- 他の00_code/配下のスクリプト（1-1.ps1、1-4.ps1など）
- 他のボタン設定（処理番号2-1以降）
- レイヤー管理、ノード管理の既存ロジック

---

## ✅ 完了チェックリスト

- [x] 新規ファイル作成 (1-2.ps1, 1-3.ps1)
- [x] 共通ユーティリティへの関数追加 (取得-JSON値)
- [x] パス解決ロジックの修正 (ShowConditionBuilder, ShowLoopBuilder)
- [x] ボタン設定の更新 (関数名変更)
- [x] Web UIコードの整理 (app-legacy.js)
- [x] HTMLモーダルの削除 (index-legacy.html)
- [x] 移行ドキュメント作成 (本ドキュメント)
- [ ] 動作テスト実施
- [ ] ユーザー確認

---

## 📚 参考情報

### 関連する他のパラメータ入力UI
以下は同様のPowerShell Windows Forms方式を使用しています:

| 処理番号 | ファイル | 説明 |
|---------|---------|------|
| 1-6 | 00_code/1-6.ps1 | メッセージボックス表示 |
| 1-8 | 00_code/1-8.ps1 | 指定時間待機 |
| 3-1 | 00_code/3-1.ps1 | キー操作（リストから項目を選択） |
| 5-1 | 00_code/5-1.ps1 | アプリ実行 |
| 8-1 | 00_code/8-1.ps1 | Excel操作 |
| 99-1 | 00_code/99-1.ps1 | カスタム処理 |

### 実装パターン
```powershell
function X_Y {
    # 1. パス取得
    $スクリプトPath = $PSScriptRoot  # 00_code/
    $メインPath = Split-Path $スクリプトPath  # UIpowershell/

    # 2. 依存ファイル読み込み
    $modulePath = Join-Path $メインPath "02_modules/XXX.psm1"
    Import-Module $modulePath -Force

    # 3. Windows Formsダイアログ実行
    $result = Invoke-SomeDialog -Caller "CallerName"

    # 4. 結果をコード文字列として返す
    return $result
}
```

---

**作成者**: Claude Code
**レビュー**: [ユーザー確認待ち]
**ステータス**: 移行完了・テスト待ち
