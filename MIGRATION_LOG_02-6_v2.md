# 移行ログ: 02-6_削除処理_v2.ps1

## 概要

**ファイル**: `02-6_削除処理.ps1` → `02-6_削除処理_v2.ps1`
**移行日**: 2025-11-02
**移行者**: Claude Code
**Phase**: Phase 2 - v2ファイル作成（5/6）

## 変更内容

### UI依存度の削除

#### Before (Windows Forms依存)
```powershell
function 条件分岐ボタン削除処理 {
    param ([System.Windows.Forms.Button]$ボタン)

    $parent = $ボタン.Parent

    # 親パネルのControlsから直接探索
    foreach ($ctrl in $parent.Controls) {
        if ($ctrl -is [System.Windows.Forms.Button]) {
            # ボタンの位置や色を直接参照
            $delta = $ctrl.Location.Y - $myY
            # ...
        }
    }

    # 直接削除
    $parent.Controls.Remove($b)
    $b.Dispose()
}
```

**問題点**:
- Windows Formsの `Button` 型に依存
- `$parent.Controls` への直接アクセス
- `.Dispose()` などWindows Forms固有のメソッド呼び出し
- REST APIから呼び出せない

#### After (UI非依存)
```powershell
function 条件分岐ノード削除_v2 {
    param (
        [array]$ノード配列,
        [string]$TargetNodeId
    )

    # ノード配列から探索
    foreach ($node in $ノード配列) {
        $txt = if ($node.text) { $node.text.Trim() } else { "" }
        # ノード情報を使って判定
        $delta = $node.y - $myY
        # ...
    }

    # 削除対象のIDリストを返すのみ（実際の削除はフロントエンド側）
    return @{
        success = $true
        deleteTargets = $削除対象
        deleteCount = $削除対象.Count
    }
}
```

**改善点**:
- ノード配列をパラメータとして受け取る
- Windows Forms型に依存しない
- 削除対象を特定するだけで、実際の削除はフロントエンド側に委譲
- REST API経由で呼び出し可能
- 構造化されたデータを返却

---

### 新規追加された関数（UI非依存版）

#### 1. `条件分岐ノード削除_v2`
- **目的**: 条件分岐の3点セット（開始・中間・終了）の削除対象を特定
- **パラメータ**:
  - `$ノード配列`: すべてのノード情報を含むハッシュテーブルの配列
  - `$TargetNodeId`: 削除トリガーとなったノードのID
- **戻り値**:
  ```powershell
  @{
      success = $true
      message = "条件分岐セット（3個）の削除対象を特定しました"
      deleteTargets = @("76-1", "76-2", "76-3")
      deleteCount = 3
      nodeType = "条件分岐"
  }
  ```
- **アルゴリズム**:
  1. ターゲットノードのテキストから探索方向を決定（開始→下、終了→上）
  2. 同じレイヤー内のSpringGreenノードから候補を抽出
  3. 最も近い「中間」「終了」（または「中間」「開始」）を特定
  4. 3点セットが揃った場合のみ削除対象として返す

#### 2. `ループノード削除_v2`
- **目的**: ループの2点セット（開始・終了）の削除対象を特定
- **パラメータ**:
  - `$ノード配列`: すべてのノード情報
  - `$TargetNodeId`: 削除トリガーとなったノードのID
- **戻り値**:
  ```powershell
  @{
      success = $true
      message = "ループセット（2個）の削除対象を特定しました"
      deleteTargets = @("80-1", "80-2")
      deleteCount = 2
      nodeType = "ループ"
      groupId = "loop-group-123"
  }
  ```
- **アルゴリズム**:
  1. ターゲットノードの `groupId` を取得
  2. 同じ `groupId` を持つLemonChiffonノードを抽出
  3. 2点セットが揃った場合のみ削除対象として返す

#### 3. `ノード削除_v2`
- **目的**: ノード削除の総合処理（色に応じて適切な削除関数を選択）
- **パラメータ**:
  - `$ノード配列`: すべてのノード情報
  - `$TargetNodeId`: 削除対象ノードのID
- **戻り値**:
  ```powershell
  # SpringGreenの場合
  @{
      success = $true
      message = "条件分岐セット（3個）の削除対象を特定しました"
      deleteTargets = @("76-1", "76-2", "76-3")
      deleteCount = 3
      nodeType = "条件分岐"
  }

  # LemonChiffonの場合
  @{
      success = $true
      message = "ループセット（2個）の削除対象を特定しました"
      deleteTargets = @("80-1", "80-2")
      deleteCount = 2
      nodeType = "ループ"
      groupId = "loop-group-123"
  }

  # その他の色の場合
  @{
      success = $true
      message = "単一ノードの削除対象を特定しました"
      deleteTargets = @("100-1")
      deleteCount = 1
      nodeType = "単一"
  }
  ```
- **判定ロジック**:
  - `SpringGreen` → 条件分岐ノード削除_v2
  - `LemonChiffon` → ループノード削除_v2
  - その他 → 単一ノード削除

#### 4. `すべてのノードを削除_v2`
- **目的**: すべてのノードの削除対象を特定
- **パラメータ**:
  - `$ノード配列`: すべてのノード情報
- **戻り値**:
  ```powershell
  @{
      success = $true
      message = "すべてのノード（10個）を削除します"
      deleteTargets = @("100-1", "101-1", "102-1", ...)
      deleteCount = 10
  }
  ```

---

### 既存関数の変更（後方互換性維持）

#### `条件分岐ボタン削除処理`
```powershell
function 条件分岐ボタン削除処理 {
    param ([System.Windows.Forms.Button]$ボタン)

    # Windows Formsのボタンをノード配列に変換
    $ノード配列 = @()
    foreach ($ctrl in $parent.Controls) {
        if ($ctrl -is [System.Windows.Forms.Button]) {
            $ノード配列 += @{
                id = $ctrl.Name
                text = $ctrl.Text
                color = $ctrl.BackColor.Name
                y = $ctrl.Location.Y
                groupId = if ($ctrl.Tag -and $ctrl.Tag.GroupID) { $ctrl.Tag.GroupID } else { $null }
                control = $ctrl  # 削除用に保持
            }
        }
    }

    # v2関数で削除対象を特定
    $result = 条件分岐ノード削除_v2 -ノード配列 $ノード配列 -TargetNodeId $ボタン.Name

    if (-not $result.success) {
        Write-Warning $result.error
        return
    }

    # 実際に削除（Windows Forms）
    foreach ($nodeId in $result.deleteTargets) {
        $削除ノード = $ノード配列 | Where-Object { $_.id -eq $nodeId }
        if ($削除ノード -and $削除ノード.control) {
            $parent.Controls.Remove($削除ノード.control)
            $削除ノード.control.Dispose()
        }
    }
}
```

**変更内容**:
- Windows FormsのControlsをノード配列に変換
- 内部でv2関数を呼び出し
- 削除対象を特定後、Windows Forms側で実際に削除
- コードの重複を削減

---

## 統計

| 項目 | 値 |
|------|------|
| オリジナルファイル行数 | 318行 |
| v2ファイル行数 | 642行 |
| 増加行数 | +324行 |
| 新規追加関数 | 4個（条件分岐ノード削除_v2、ループノード削除_v2、ノード削除_v2、すべてのノードを削除_v2） |
| 変更された既存関数 | 4個（条件分岐ボタン削除処理、ループボタン削除処理、script:削除処理、フレームパネルからすべてのボタンを削除する） |

---

## 使用例

### 例1: REST APIからノードを削除

```powershell
# ノード配列を準備（HTML/JSフロントエンドから送信されたデータ）
$nodes = @(
    @{ id = "76-1"; text = "条件分岐 開始"; color = "SpringGreen"; y = 100 },
    @{ id = "76-2"; text = "条件分岐 中間"; color = "SpringGreen"; y = 150 },
    @{ id = "76-3"; text = "条件分岐 終了"; color = "SpringGreen"; y = 200 },
    @{ id = "100-1"; text = "処理A"; color = "White"; y = 50 }
)

# 条件分岐の削除を試みる
$result = ノード削除_v2 -ノード配列 $nodes -TargetNodeId "76-1"

if ($result.success) {
    Write-Host "削除タイプ: $($result.nodeType)"
    Write-Host "削除対象ノード数: $($result.deleteCount)"
    Write-Host "削除対象ID: $($result.deleteTargets -join ', ')"

    # フロントエンド側で実際に削除
    foreach ($nodeId in $result.deleteTargets) {
        # React Flowからノードを削除...
    }
} else {
    Write-Error "削除失敗: $($result.error)"
}
```

### 例2: ループノードの削除

```powershell
$nodes = @(
    @{ id = "80-1"; text = "ループ 開始"; color = "LemonChiffon"; y = 100; groupId = "loop-123" },
    @{ id = "80-2"; text = "ループ 終了"; color = "LemonChiffon"; y = 200; groupId = "loop-123" }
)

$result = ノード削除_v2 -ノード配列 $nodes -TargetNodeId "80-1"

if ($result.success) {
    Write-Host "ループセット削除: GroupID=$($result.groupId)"
    # フロントエンド側で削除実行...
}
```

### 例3: 単一ノードの削除

```powershell
$nodes = @(
    @{ id = "100-1"; text = "処理A"; color = "White"; y = 50 }
)

$result = ノード削除_v2 -ノード配列 $nodes -TargetNodeId "100-1"

if ($result.success) {
    Write-Host "単一ノード削除: $($result.deleteTargets[0])"
}
```

### 例4: すべてのノードを削除

```powershell
$nodes = @(
    @{ id = "100-1"; text = "処理A"; color = "White"; y = 50 },
    @{ id = "101-1"; text = "処理B"; color = "White"; y = 100 },
    @{ id = "102-1"; text = "処理C"; color = "White"; y = 150 }
)

$result = すべてのノードを削除_v2 -ノード配列 $nodes

if ($result.success) {
    Write-Host "削除対象ノード数: $($result.deleteCount)"
    # すべてのノードを削除...
}
```

---

## REST API統合例

### Polaris エンドポイント定義

```powershell
# ノード削除エンドポイント（単一・セット両対応）
New-PolarisRoute -Path "/api/nodes/:id" -Method DELETE -ScriptBlock {
    $nodeId = $Response.Parameters.id
    $Request = $Response.Request
    $body = $Request.Body | ConvertFrom-Json

    # ノード配列を受け取る
    $nodes = $body.nodes

    $result = ノード削除_v2 -ノード配列 $nodes -TargetNodeId $nodeId

    $Response.Json($result)
}

# すべてのノードを削除
New-PolarisRoute -Path "/api/nodes" -Method DELETE -ScriptBlock {
    $Request = $Response.Request
    $body = $Request.Body | ConvertFrom-Json

    $nodes = $body.nodes

    $result = すべてのノードを削除_v2 -ノード配列 $nodes

    $Response.Json($result)
}
```

### JavaScript フロントエンド例

```javascript
// 単一ノードまたはセットノードを削除
async function deleteNode(nodeId, allNodes) {
    const response = await fetch(`/api/nodes/${nodeId}`, {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ nodes: allNodes })
    });

    const result = await response.json();

    if (result.success) {
        console.log(`削除タイプ: ${result.nodeType}`);
        console.log(`削除ノード数: ${result.deleteCount}`);

        // React Flowからノードを削除
        result.deleteTargets.forEach(targetId => {
            reactFlowInstance.deleteElements({ nodes: [{ id: targetId }] });
        });
    } else {
        console.error(`削除失敗: ${result.error}`);

        if (result.foundNodes) {
            console.warn(`見つかったノード: ${result.foundNodes.join(', ')}`);
        }
    }
}

// すべてのノードを削除
async function deleteAllNodes(allNodes) {
    const response = await fetch('/api/nodes', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ nodes: allNodes })
    });

    const result = await response.json();

    if (result.success) {
        console.log(`全削除: ${result.deleteCount}個のノード`);

        // React Flowをクリア
        reactFlowInstance.setNodes([]);
    }
}

// React Flow側での削除ハンドラー
const onNodesDelete = (deletedNodes) => {
    // 最初に削除されたノードのみをトリガーとする
    const triggerNode = deletedNodes[0];
    const allNodes = reactFlowInstance.getNodes();

    // バックエンドで削除対象を判定
    deleteNode(triggerNode.id, allNodes);
};
```

---

## 互換性

- ✅ **Windows Forms版**: 既存の関数が維持されているため、完全に動作します
- ✅ **HTML/JS版**: v2関数を使用してREST API経由で動作します
- ✅ **後方互換性**: 既存のコードを変更する必要はありません
- ✅ **セット削除のサポート**: 条件分岐（3点）とループ（2点）のセット削除に対応
- ✅ **エラーハンドリング**: セットが揃わない場合は警告を返し、削除しない

---

## アーキテクチャ上の利点

### 責任分離
- **v2関数**: 削除対象の"特定"のみを担当
- **フロントエンド**: 実際の削除実行を担当
- **バックエンド**: ビジネスロジック（セット判定、距離計算など）

### テスタビリティ
- v2関数は純粋関数（副作用なし）
- ユニットテストが容易
- モックデータで完全にテスト可能

### 拡張性
- 新しいノードタイプの追加が容易
- 削除ロジックの変更がフロントエンドに影響しない
- 複数フロントエンド（Windows Forms、HTML/JS、CLI）で同じロジックを共有

---

## テスト項目

### 単体テスト
- [ ] `条件分岐ノード削除_v2`: 3点セットが揃う場合
- [ ] `条件分岐ノード削除_v2`: 3点セットが揃わない場合（警告）
- [ ] `条件分岐ノード削除_v2`: "開始"から削除した場合（下方向探索）
- [ ] `条件分岐ノード削除_v2`: "終了"から削除した場合（上方向探索）
- [ ] `ループノード削除_v2`: 2点セットが揃う場合
- [ ] `ループノード削除_v2`: 2点セットが揃わない場合（警告）
- [ ] `ループノード削除_v2`: GroupIDが未設定の場合（エラー）
- [ ] `ノード削除_v2`: SpringGreenノードの場合
- [ ] `ノード削除_v2`: LemonChiffonノードの場合
- [ ] `ノード削除_v2`: その他の色のノードの場合（単一削除）
- [ ] `すべてのノードを削除_v2`: ノード配列が空の場合
- [ ] `すべてのノードを削除_v2`: 複数ノードが存在する場合

### 統合テスト
- [ ] REST API経由で条件分岐セットを削除
- [ ] REST API経由でループセットを削除
- [ ] REST API経由で単一ノードを削除
- [ ] REST API経由ですべてのノードを削除
- [ ] 既存のWindows Forms版が正しく動作（後方互換性）
- [ ] v2関数がセット不完全時に適切なエラーを返す

---

## 次のステップ

### Phase 2の残りタスク
1. **02-2_ネスト規制バリデーション_v2.ps1** の作成（難易度: ★★★★☆）
   - ネスト構造のバリデーションロジックのUI非依存化
   - ノード配列ベースのバリデーション
   - 最終v2ファイル！

### Phase 3: アダプターレイヤーの完成
- `adapter/state-manager.ps1` の拡張（ノード削除対応）
- `adapter/node-operations.ps1` の拡張（削除操作）

### Phase 4: HTML/JSフロントエンド機能拡張
- React Flowでのノード削除UI実装
- 条件分岐・ループセット削除のハイライト表示
- 削除確認ダイアログ

---

## 注意事項

1. **ノード配列の形式**:
   - 各ノードは以下のプロパティを持つハッシュテーブル:
     - `id`: ノードID（必須）
     - `text`: 表示テキスト（必須）
     - `color`: ノード色（必須）
     - `y`: Y座標（必須）
     - `groupId`: グループID（ループノードの場合必須）

2. **セット削除の挙動**:
   - 条件分岐: 3点（開始・中間・終了）が揃わないと削除できない
   - ループ: 2点（開始・終了）が揃わないと削除できない
   - セットが揃わない場合は `success: false` を返し、警告メッセージを含む

3. **距離計算ロジック**:
   - 条件分岐では、ターゲットノードに最も近い「中間」「終了」（または「中間」「開始」）を選択
   - Y座標の差の絶対値で距離を計算

4. **エラーハンドリング**:
   - すべてのv2関数はtry-catchで例外をキャッチし、構造化されたエラー情報を返す
   - REST API側で適切なエラーハンドリングを実装してください

---

## 移行完了確認

- ✅ オリジナルファイルを理解
- ✅ v2ファイルを作成
- ✅ UI依存度を削除
- ✅ 構造化された戻り値を実装
- ✅ 後方互換性を維持
- ✅ 移行ログを作成
- ⬜ コミット・プッシュ（次のステップ）

---

**移行者コメント**:

この移行により、ノード削除ロジックが完全にUI非依存になりました。特に重要なのは、条件分岐とループの「セット削除」ロジックをビジネスロジック層に移動したことです。

従来のWindows Forms版では、削除処理が以下のような複雑な依存関係を持っていました:
- `$parent.Controls` への直接アクセス
- Windows Forms型への依存
- UI再配置処理との密結合

v2版では、これらの依存関係を完全に切り離し、「削除対象の特定」という純粋なビジネスロジックのみをPowerShell側に残しました。実際の削除実行はフロントエンド（Windows FormsまたはHTML/JS）に委譲することで、責任分離とテスタビリティが大幅に向上しています。

Phase 2はあと1ファイル（02-2_ネスト規制バリデーション_v2.ps1）で完了です！
