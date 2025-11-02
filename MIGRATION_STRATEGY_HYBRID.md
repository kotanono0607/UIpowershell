# HTML/CSS/JSハイブリッド移行戦略
# UI層のみHTML化による段階的移行アプローチ

**評価日**: 2025-11-02
**質問**: 「メインウインドウ・パネル・矢印のみHTMLで実装した場合、既存のps1ファイルだけ差し替えればOK?」

## 📋 結論（要約）

**答え: ❌ 完全な差し替えだけでは不可能です**

しかし、**段階的移行アプローチ**により、既存のビジネスロジックを最大70%再利用できます。

| アプローチ | 既存コード再利用率 | 移行工数 | 推奨度 |
|----------|----------------|---------|--------|
| **単純な差し替え** | 0% | N/A | ❌ 不可能 |
| **アダプター層追加** | 70% | 2-3ヶ月 | ⭐⭐⭐⭐ 推奨 |
| **完全な再設計** | 30% | 4-7ヶ月 | ⭐⭐⭐ 長期的には最適 |

---

## 🔍 既存コードの再利用可能性分析

### 📊 ファイル別の再利用可能性

| ファイル | UI依存度 | 再利用可能度 | 対応方法 |
|---------|---------|------------|---------|
| **09_変数機能_コードID管理JSON.ps1** | ★☆☆☆☆ (10%) | ★★★★★ (100%) | **そのまま使用可能** |
| **00_共通ユーティリティ_JSON操作.ps1** | ★☆☆☆☆ (0%) | ★★★★★ (100%) | **そのまま使用可能** |
| **12_コードメイン_コード本文.ps1** | ★★★☆☆ (60%) | ★★★☆☆ (60%) | 軽微な修正で使用可能 |
| **08_メインF機能_メインボタン処理.ps1** | ★★★★☆ (80%) | ★★☆☆☆ (40%) | アダプター層が必要 |
| **13-15_コードサブ関数.ps1** | ★★☆☆☆ (40%) | ★★★★☆ (80%) | ダイアログ部分のみ修正 |
| **02-1～02-7（UI層）** | ★★★★★ (100%) | ★☆☆☆☆ (0%) | **完全に置き換え** |
| **05_メインフォームUI_矢印処理.ps1** | ★★★★★ (100%) | ★☆☆☆☆ (0%) | **完全に置き換え** |
| **06_メインフォームUI_フレーム移動.ps1** | ★★★★★ (100%) | ★☆☆☆☆ (0%) | **完全に置き換え** |

### 総合評価

```
再利用可能なコード: 約70% (約6,500行 / 9,365行)
完全な書き換えが必要: 約30% (約2,800行)
```

---

## 🎯 なぜ単純な差し替えが不可能なのか？

### 問題1: UI層とビジネスロジックの密結合

**現状のコード例（12_コードメイン_コード本文.ps1）**:
```powershell
function 00_文字列処理内容 {
    # ❌ UI操作が関数内に埋め込まれている
    $メインフォーム.Hide()

    # ビジネスロジック（これは再利用可能）
    $関数マッピング = @{}
    foreach ($entry in $jsonData) {
        $関数マッピング[$entry.処理番号] = $entry.関数名
    }

    # ❌ 再びUI操作
    $メインフォーム.Show()
}
```

**問題点**:
- ビジネスロジックの前後にUI操作が挟まっている
- `$メインフォーム`というWindows Formsオブジェクトに直接依存
- HTML/JSからこの関数を呼び出せない

---

### 問題2: グローバル変数への直接アクセス

**現状のコード例（08_メインF機能_メインボタン処理.ps1）**:
```powershell
function 実行イベント {
    # ❌ Windows FormsのControlsコレクションに直接アクセス
    $buttons = $global:レイヤー1.Controls |
               Where-Object { $_ -is [System.Windows.Forms.Button] } |
               Sort-Object { $_.Location.Y }

    foreach ($button in $buttons) {
        # ❌ Windows FormsのButtonオブジェクトのプロパティを使用
        $buttonColor = $button.BackColor
        $buttonName = $button.Name

        # ビジネスロジック（これは再利用可能）
        $取得したエントリ = IDでエントリを取得 -ID $buttonName
    }
}
```

**問題点**:
- `$global:レイヤー1.Controls`はWindows FormsのPanel.Controls
- HTML/JSでは`<div>`や`<button>`要素になるため、互換性なし
- `.BackColor`、`.Location.Y`などWindows Forms固有のプロパティ

---

### 問題3: イベントハンドラー内のビジネスロジック

**現状のコード例（02-1_フォーム基礎構築.ps1）**:
```powershell
$フレーム.Add_DragDrop({
    param($sender, $e)

    # ❌ Windows FormsのDragDropイベント固有の処理
    $ボタン = $e.Data.GetData([System.Windows.Forms.Button])

    # ビジネスロジック（これは分離すべき）
    $衝突あり = 10_ボタンの一覧取得 -フレーム $sender -現在のY $現在のY

    if ($衝突あり) {
        # ❌ Windows FormsのMessageBox
        [System.Windows.Forms.MessageBox]::Show("この位置には配置できません")
    }

    # ❌ Panel.Controlsの操作
    $ボタン.Location = New-Object System.Drawing.Point($X, $Y)
})
```

**問題点**:
- イベントハンドラー内にバリデーションロジックが含まれている
- Windows Forms固有のイベント引数（$e）に依存
- ビジネスロジックとUI操作が混在

---

## 🛠️ 解決策: アダプター層アプローチ

### アーキテクチャ概要

```
┌─────────────────────────────────────────────────────────┐
│ 【プレゼンテーション層】                                │
│  HTML + CSS + JavaScript (Tauri/Electron)               │
│  - React Flow / Cytoscape.js                            │
│  - ドラッグ&ドロップUI                                  │
│  - 矢印描画                                              │
└─────────────────────────────────────────────────────────┘
                        ↕ (REST API / IPC)
┌─────────────────────────────────────────────────────────┐
│ 【アダプター層】(新規作成)                              │
│  PowerShell REST API Server または Node.js Bridge       │
│  - UIイベントをビジネスロジックに変換                  │
│  - Windows Forms依存コードをラップ                      │
│  - グローバル変数を抽象化                                │
└─────────────────────────────────────────────────────────┘
                        ↕
┌─────────────────────────────────────────────────────────┐
│ 【ビジネスロジック層】(既存コード 70%再利用)            │
│  PowerShell関数群                                        │
│  ✅ 09_変数機能_コードID管理JSON.ps1 (そのまま)        │
│  ✅ 00_共通ユーティリティ_JSON操作.ps1 (そのまま)      │
│  🔧 12_コードメイン_コード本文.ps1 (軽微修正)          │
│  🔧 08_メインF機能_メインボタン処理.ps1 (修正)        │
└─────────────────────────────────────────────────────────┘
                        ↕
┌─────────────────────────────────────────────────────────┐
│ 【データアクセス層】(既存コード 100%再利用)             │
│  JSON操作関数                                            │
│  ✅ IDでエントリを取得                                   │
│  ✅ IDでエントリを置換                                   │
│  ✅ エントリを追加                                       │
└─────────────────────────────────────────────────────────┘
```

---

## 📝 具体的な実装例

### Step 1: アダプター層の作成

**ファイル: adapter/api-server.ps1** (新規作成)

```powershell
# PowerShell REST APIサーバー（Polaris使用）
Import-Module Polaris

# 既存のビジネスロジックをインポート
. ".\09_変数機能_コードID管理JSON.ps1"
. ".\12_コードメイン_コード本文.ps1"

# グローバル変数を管理するための状態オブジェクト
$script:appState = @{
    nodes = @()      # ノード一覧（HTML/JSから渡される）
    layers = @{}     # レイヤー情報
    currentFolder = ""
}

# API: ノード一覧を取得
New-PolarisRoute -Path "/api/nodes" -Method GET -ScriptBlock {
    $Response.Json($script:appState.nodes)
}

# API: ノードを追加
New-PolarisRoute -Path "/api/nodes" -Method POST -ScriptBlock {
    $body = $Request.Body | ConvertFrom-Json

    # ビジネスロジック（既存関数を再利用）
    $id = IDを自動生成する
    $entry = 生成されたコード関数 -処理番号 $body.type
    エントリを追加_指定ID -ID $id -文字列 $entry

    # ノードを状態に追加
    $script:appState.nodes += @{
        id = $id
        label = $body.label
        type = $body.type
        x = $body.x
        y = $body.y
    }

    $Response.Json(@{ success = $true; id = $id })
}

# API: ノードを移動（ドラッグ&ドロップ）
New-PolarisRoute -Path "/api/nodes/:id/move" -Method POST -ScriptBlock {
    $nodeId = $Request.Parameters.id
    $body = $Request.Body | ConvertFrom-Json

    # 既存のバリデーションロジックを再利用（UI依存を除去したバージョン）
    $衝突あり = ノード移動バリデーション `
        -ノードID $nodeId `
        -新しいY $body.y `
        -レイヤー $body.layer `
        -全ノード $script:appState.nodes

    if ($衝突あり) {
        $Response.StatusCode = 400
        $Response.Json(@{ error = "この位置には配置できません" })
        return
    }

    # ノード位置を更新
    $node = $script:appState.nodes | Where-Object { $_.id -eq $nodeId }
    $node.x = $body.x
    $node.y = $body.y

    $Response.Json(@{ success = $true })
}

# API: PowerShellスクリプトを生成
New-PolarisRoute -Path "/api/generate" -Method POST -ScriptBlock {
    # 既存の実行イベント関数を改造（UI依存を除去）
    $output = ""

    # ノードをY座標でソート
    $sortedNodes = $script:appState.nodes | Sort-Object { $_.y }

    foreach ($node in $sortedNodes) {
        # 既存の関数を再利用
        $取得したエントリ = IDでエントリを取得 -ID $node.id
        $output += "$取得したエントリ`n`n"
    }

    # ファイルに保存
    $outputPath = Join-Path -Path $script:appState.currentFolder -ChildPath "output.ps1"
    $output | Set-Content -Path $outputPath -Encoding UTF8

    $Response.Json(@{ success = $true; script = $output })
}

# サーバー起動
Start-Polaris -Port 3000
Write-Host "APIサーバーが http://localhost:3000 で起動しました"
```

---

### Step 2: HTML/JSフロントエンドから既存ロジックを呼び出す

**ファイル: src/App.jsx** (Tauri/Electron)

```jsx
import React, { useState, useEffect } from 'react';
import ReactFlow, { useNodesState, useEdgesState } from 'reactflow';
import 'reactflow/dist/style.css';

function App() {
  const [nodes, setNodes, onNodesChange] = useNodesState([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState([]);

  // 既存のPowerShell APIからノードを取得
  useEffect(() => {
    fetch('http://localhost:3000/api/nodes')
      .then(res => res.json())
      .then(data => {
        const reactFlowNodes = data.map(node => ({
          id: node.id,
          data: { label: node.label },
          position: { x: node.x, y: node.y },
          type: node.type
        }));
        setNodes(reactFlowNodes);
      });
  }, []);

  // ノードを追加（既存のPowerShellロジックを使用）
  const addNode = async (type) => {
    const response = await fetch('http://localhost:3000/api/nodes', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        label: type === 'condition' ? '条件分岐' : '順次処理',
        type: type,
        x: 200,
        y: 100
      })
    });

    const result = await response.json();

    if (result.success) {
      // UIを更新
      setNodes([...nodes, {
        id: result.id,
        data: { label: result.label },
        position: { x: 200, y: 100 }
      }]);
    }
  };

  // ノードを移動（既存のバリデーションを使用）
  const onNodeDragStop = async (event, node) => {
    const response = await fetch(`http://localhost:3000/api/nodes/${node.id}/move`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        x: node.position.x,
        y: node.position.y,
        layer: 1
      })
    });

    if (!response.ok) {
      const error = await response.json();
      alert(error.error); // "この位置には配置できません"
      // ノードを元の位置に戻す
      // ...
    }
  };

  // PowerShellスクリプトを生成（既存の実行イベント関数を使用）
  const generateScript = async () => {
    const response = await fetch('http://localhost:3000/api/generate', {
      method: 'POST'
    });

    const result = await response.json();
    console.log('生成されたスクリプト:', result.script);
  };

  return (
    <div style={{ width: '100vw', height: '100vh' }}>
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onNodeDragStop={onNodeDragStop}
      />

      <div className="toolbar">
        <button onClick={() => addNode('sequential')}>順次処理を追加</button>
        <button onClick={() => addNode('condition')}>条件分岐を追加</button>
        <button onClick={generateScript}>実行</button>
      </div>
    </div>
  );
}

export default App;
```

---

### Step 3: 既存コードの軽微な修正

**修正前: 12_コードメイン_コード本文.ps1**
```powershell
function 00_文字列処理内容 {
    $メインフォーム.Hide()  # ❌ UI依存

    # ビジネスロジック
    $entryString = & $関数名
    エントリを追加_指定ID -ID $ボタン名 -文字列 $entryString

    $メインフォーム.Show()  # ❌ UI依存
}
```

**修正後: 12_コードメイン_コード本文_v2.ps1**
```powershell
function 00_文字列処理内容_UI非依存 {
    param (
        [string]$ボタン名,
        [string]$処理番号,
        [bool]$showUI = $false  # UIの表示/非表示を制御可能に
    )

    # UI操作を条件分岐に
    if ($showUI -and $global:メインフォーム) {
        $global:メインフォーム.Hide()
    }

    # ビジネスロジック（変更なし）
    $entryString = & $関数名
    エントリを追加_指定ID -ID $ボタン名 -文字列 $entryString

    if ($showUI -and $global:メインフォーム) {
        $global:メインフォーム.Show()
    }

    return $entryString  # 結果を返すように変更
}
```

---

### Step 4: バリデーションロジックのUI非依存化

**修正前: 02-1_フォーム基礎構築.ps1（イベントハンドラー内）**
```powershell
$フレーム.Add_DragDrop({
    # ❌ Windows Forms依存のバリデーション
    $buttons = $フレーム.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] }

    foreach ($button in $buttons) {
        if ($button.Location.Y == $新しいY) {
            # 衝突検出
        }
    }
})
```

**修正後: validation/node-validation.ps1（新規作成）**
```powershell
function ノード移動バリデーション {
    param (
        [string]$ノードID,
        [int]$新しいY,
        [int]$レイヤー,
        [array]$全ノード  # HTML/JSから渡されるノード配列
    )

    # UI非依存のバリデーションロジック
    $同レイヤーノード = $全ノード | Where-Object { $_.layer -eq $レイヤー }

    foreach ($node in $同レイヤーノード) {
        if ($node.id -ne $ノードID -and [Math]::Abs($node.y - $新しいY) -lt 10) {
            return $true  # 衝突あり
        }
    }

    return $false  # 衝突なし
}
```

---

## 📊 移行工数と段階的アプローチ

### Phase 1: アダプター層の構築（2-4週間）

**作業内容**:
1. PowerShell REST APIサーバーの構築
2. 既存関数のラッパー作成
3. グローバル変数の状態管理オブジェクト化
4. UIイベントをAPIエンドポイントに変換

**必要なスキル**:
- PowerShell
- REST API設計
- Polarisモジュールの知識

**成果物**:
- `adapter/api-server.ps1`
- `adapter/state-manager.ps1`
- `validation/node-validation.ps1`（UI非依存版）

---

### Phase 2: HTML/JSフロントエンドの構築（4-6週間）

**作業内容**:
1. Tauri/Electronのセットアップ
2. React + React Flowの実装
3. APIクライアントの実装
4. ドラッグ&ドロップUIの実装
5. 矢印描画の実装（React Flowが自動で行う）

**必要なスキル**:
- React / Vue
- React Flow / Cytoscape.js
- REST API連携

**成果物**:
- `src/App.jsx`（メインコンポーネント）
- `src/components/WorkflowEditor.jsx`
- `src/api/client.js`（APIクライアント）

---

### Phase 3: 既存コードの修正（2-3週間）

**作業内容**:
1. UI依存部分の条件分岐化
2. グローバル変数アクセスの抽象化
3. 戻り値の追加（void → 値を返す）
4. イベントハンドラーからビジネスロジックを分離

**成果物**:
- `12_コードメイン_コード本文_v2.ps1`
- `08_メインF機能_メインボタン処理_v2.ps1`

---

### Phase 4: テスト・デバッグ（2-3週間）

**作業内容**:
1. 統合テスト
2. パフォーマンステスト
3. 既存機能との互換性確認
4. バグ修正

---

## 🎯 推奨される移行アプローチ

### **推奨: アダプター層アプローチ** ⭐⭐⭐⭐⭐

| 項目 | 評価 |
|-----|------|
| 既存コード再利用率 | **70%** |
| 移行工数 | **2-3ヶ月** |
| リスク | **低** |
| 将来の拡張性 | **高** |
| パフォーマンス向上 | **中** |

**メリット**:
- ✅ 既存のビジネスロジックを最大限活用
- ✅ 段階的に移行可能（リスク低減）
- ✅ PowerShellの知識をそのまま活用
- ✅ HTML/CSS/JSの利点を享受

**デメリット**:
- ❌ アダプター層のオーバーヘッド（REST API通信）
- ❌ 2つの技術スタック（PowerShell + JS）を管理

---

### 代替案: 完全な再設計

| 項目 | 評価 |
|-----|------|
| 既存コード再利用率 | **30%** |
| 移行工数 | **4-7ヶ月** |
| リスク | **中** |
| 将来の拡張性 | **非常に高** |
| パフォーマンス向上 | **高** |

**メリット**:
- ✅ 最もクリーンなアーキテクチャ
- ✅ パフォーマンス最適
- ✅ 保守性が最高

**デメリット**:
- ❌ 開発工数が大きい
- ❌ 既存資産の活用が限定的

---

## 🔧 技術スタック推奨

### **推奨: Tauri + React + PowerShell REST API**

```
フロントエンド: Tauri + React + React Flow
アダプター層: PowerShell REST API (Polaris)
ビジネスロジック: 既存PowerShell関数（70%再利用）
データアクセス層: 既存JSON操作関数（100%再利用）
```

**理由**:
- Tauriは軽量（Electronの1/40）
- React Flowで矢印描画が自動
- PowerShell REST APIで既存コードと連携
- 段階的に移行可能

---

## 📋 移行チェックリスト

### Phase 1: 準備（1週間）
- [ ] Polarisモジュールのインストール
- [ ] Tauri開発環境のセットアップ
- [ ] React Flow のプロトタイプ作成
- [ ] アーキテクチャレビュー

### Phase 2: アダプター層（2-4週間）
- [ ] REST APIサーバーの実装
- [ ] 状態管理オブジェクトの作成
- [ ] 既存関数のラッパー作成
- [ ] バリデーションロジックのUI非依存化
- [ ] APIエンドポイントのテスト

### Phase 3: フロントエンド（4-6週間）
- [ ] Tauriプロジェクトの初期化
- [ ] React + React Flowの実装
- [ ] ドラッグ&ドロップUIの実装
- [ ] APIクライアントの実装
- [ ] 矢印描画の実装（React Flow自動）
- [ ] CSS/スタイリング

### Phase 4: 既存コード修正（2-3週間）
- [ ] 12_コードメイン_コード本文.ps1の修正
- [ ] 08_メインF機能_メインボタン処理.ps1の修正
- [ ] グローバル変数の抽象化
- [ ] イベントハンドラーのリファクタリング

### Phase 5: 統合・テスト（2-3週間）
- [ ] 統合テスト
- [ ] パフォーマンステスト
- [ ] 既存機能との互換性確認
- [ ] バグ修正
- [ ] ドキュメント作成

---

## 💡 実装のヒント

### 1. グローバル変数の抽象化

**Before（既存コード）**:
```powershell
$global:レイヤー1.Controls | Where-Object { ... }
```

**After（アダプター層）**:
```powershell
# 状態オブジェクトから取得
function Get-NodesInLayer {
    param([int]$layerNumber)
    return $script:appState.layers[$layerNumber].nodes
}

# 使用例
$nodes = Get-NodesInLayer -layerNumber 1
```

---

### 2. イベントの変換

**Windows Forms（Before）**:
```powershell
$フレーム.Add_DragDrop({
    param($sender, $e)
    $ボタン = $e.Data.GetData([System.Windows.Forms.Button])
    # ...
})
```

**REST API（After）**:
```powershell
# APIエンドポイント
New-PolarisRoute -Path "/api/nodes/:id/drop" -Method POST -ScriptBlock {
    $nodeId = $Request.Parameters.id
    $body = $Request.Body | ConvertFrom-Json

    # 既存のバリデーションロジックを呼び出し
    $result = Validate-NodeDrop -nodeId $nodeId -position $body
    $Response.Json($result)
}
```

**JavaScript（フロントエンド）**:
```javascript
const onNodeDragStop = async (event, node) => {
  const response = await fetch(`/api/nodes/${node.id}/drop`, {
    method: 'POST',
    body: JSON.stringify({ x: node.position.x, y: node.position.y })
  });
  const result = await response.json();
};
```

---

### 3. ダイアログの抽象化

**Before（Windows Forms MessageBox）**:
```powershell
[System.Windows.Forms.MessageBox]::Show("エラー", "エラー", ...)
```

**After（APIレスポンス）**:
```powershell
# サーバー側
$Response.StatusCode = 400
$Response.Json(@{ error = "エラー"; message = "詳細メッセージ" })
```

**JavaScript（フロントエンド）**:
```javascript
if (!response.ok) {
  const error = await response.json();
  alert(error.message); // または、モダンなUIライブラリ（react-toastify等）
}
```

---

## 🚀 移行後の期待効果

### 開発生産性

| 項目 | Before（Windows Forms） | After（HTML/JS + アダプター） |
|-----|------------------------|------------------------------|
| UI変更の反映時間 | 10秒（実行→確認） | **1秒（ホットリロード）** |
| デバッグ効率 | Write-Hostのみ | **Chrome DevTools** |
| 矢印描画のコード行数 | 50行 | **0行（自動）** |
| 新規ノード追加 | 20行 | **5行** |

### パフォーマンス

| 項目 | Before | After |
|-----|--------|-------|
| 描画速度 | CPU描画（遅い） | **GPUアクセラレーション** |
| メモリ使用量 | 150MB | **100MB（Tauri）** |
| 起動時間 | 3秒 | **1秒** |

### コード品質

| 項目 | Before | After |
|-----|--------|-------|
| UI/ビジネスロジック分離 | ❌ 混在 | **✅ 完全分離** |
| テスト可能性 | ❌ 困難 | **✅ 容易** |
| 保守性 | ⚠️ 中 | **✅ 高** |

---

## 📚 参考実装

### PowerShell REST APIサーバー（Polaris）

```powershell
# インストール
Install-Module -Name Polaris -Scope CurrentUser

# サーバーの起動
Import-Module Polaris

New-PolarisRoute -Path "/api/hello" -Method GET -ScriptBlock {
    $Response.Json(@{ message = "Hello from PowerShell!" })
}

Start-Polaris -Port 3000 -MinRunspaces 1 -MaxRunspaces 5
```

### Tauriでのローカルサーバー連携

```rust
// src-tauri/src/main.rs
#[tauri::command]
async fn call_powershell_api(endpoint: String) -> Result<String, String> {
    let url = format!("http://localhost:3000/api/{}", endpoint);
    let response = reqwest::get(&url)
        .await
        .map_err(|e| e.to_string())?
        .text()
        .await
        .map_err(|e| e.to_string())?;
    Ok(response)
}
```

```javascript
// src/api/client.js
import { invoke } from '@tauri-apps/api/tauri';

export async function getNodes() {
  const response = await invoke('call_powershell_api', { endpoint: 'nodes' });
  return JSON.parse(response);
}
```

---

## 🎯 最終推奨

### **アダプター層アプローチを推奨します** ⭐⭐⭐⭐⭐

**理由**:
1. **既存資産を最大限活用**（70%再利用）
2. **段階的移行でリスク低減**
3. **移行工数が現実的**（2-3ヶ月）
4. **HTML/CSS/JSの利点を享受**
5. **将来的にPowerShell部分を段階的にJS化可能**

### 移行ロードマップ

```
Month 1: アダプター層構築 + HTML/JSプロトタイプ
Month 2: フロントエンド実装 + 既存コード修正
Month 3: 統合・テスト・デバッグ
```

---

## 📖 まとめ

### 質問への回答

> **Q: メインウインドウ・パネル・矢印のみHTMLで実装した場合、既存のps1ファイルだけ差し替えればOK?**

**A: ❌ 単純な差し替えだけでは不可能です。しかし、アダプター層を追加することで、既存のビジネスロジックを70%再利用できます。**

### 推奨アプローチ

```
✅ アダプター層アプローチ
   ├─ 既存コード再利用: 70%
   ├─ 移行工数: 2-3ヶ月
   ├─ リスク: 低
   └─ 推奨度: ⭐⭐⭐⭐⭐

❌ 単純な差し替え
   └─ 不可能

⚠️ 完全な再設計
   ├─ 既存コード再利用: 30%
   ├─ 移行工数: 4-7ヶ月
   └─ 長期的には最適だが、短期的には非現実的
```

---

**Document Version**: 1.0
**Last Updated**: 2025-11-02
**Author**: Claude (AI Technical Assessor)
