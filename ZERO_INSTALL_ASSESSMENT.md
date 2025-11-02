# インストール不要・既存環境のみでの移行評価
# Pure HTML/CSS/JavaScript + PowerShell アプローチ

**更新日**: 2025-11-02
**重要な制約条件**:
- ❌ Node.js、Tauri、Rust等のインストール不可
- ❌ npm、外部パッケージマネージャー不可
- ✅ PowerShell + HTML/CSS/JavaScript のみ
- ✅ インストール不要・既存環境のみで動作
- ✅ これがRPAツールとしての本質的要件

---

## 🎯 制約条件の再確認

### なぜPowerShellベースなのか？

**RPAツールとしての要件**:
```
✅ インストール不要
  → ユーザーのPCに何もインストールせずに使える
  → .batファイルをダブルクリックするだけで起動
  → IT部門の承認不要

✅ 既存環境のみで動作
  → Windows標準のPowerShell（v5.1+）
  → Windows標準のブラウザ（Edge/Chrome）
  → 追加のランタイム不要

✅ ポータブル
  → USBメモリに入れて持ち運べる
  → ネットワークドライブから実行可能
  → 複数のPCで同じものが動く
```

**これまでの推奨技術スタック（Tauri、Node.js等）は使えません！**

---

## 📊 新しい技術スタック評価

### オプション1: PowerShell + Polaris + Pure HTML/CSS/JS ⭐⭐⭐⭐⭐ 推奨

**構成**:
```
起動スクリプト（実行.bat）
    ↓
PowerShell HTTPサーバー（Polaris）
    ↓
ブラウザ自動起動（http://localhost:8080）
    ↓
Pure HTML/CSS/JavaScript（単一ファイルまたは最小構成）
    ↓ fetch() API
PowerShell REST API（既存コード呼び出し）
```

**メリット**:
✅ **Polarisモジュールは一度インストールすればプロジェクトに含められる**
✅ ユーザーのPCへのインストール不要
✅ .batファイルをダブルクリックで起動
✅ ブラウザで動作（モダンなUI）
✅ CDN経由でライブラリ読み込み可能

**デメリット**:
⚠️ Polarisモジュールを配布に含める必要がある
⚠️ インターネット接続が必要（CDN使用時）

**インストール不要にする方法**:
```powershell
# Polarisモジュールをプロジェクトディレクトリに含める
UIpowershell/
├── Modules/
│   └── Polaris/          ← Polarisモジュールをコピー
├── adapter/
│   └── api-server.ps1
└── 実行.bat

# api-server.ps1 でローカルモジュールをインポート
Import-Module "$PSScriptRoot\..\Modules\Polaris" -Force
```

**評価**: ⭐⭐⭐⭐⭐ (95/100)

---

### オプション2: PowerShell + .NET HttpListener + Pure HTML ⭐⭐⭐⭐

**構成**:
```
PowerShell + .NET HttpListener（標準機能）
    ↓
Pure HTML/CSS/JavaScript
```

**メリット**:
✅ **完全にインストール不要**（.NET Framework標準）
✅ Windows標準機能のみ使用
✅ Polarisより軽量

**デメリット**:
⚠️ ルーティングを手動実装する必要がある
⚠️ Polarisよりコードが複雑

**実装例**:
```powershell
# simple-http-server.ps1
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:8080/")
$listener.Start()

Write-Host "サーバー起動: http://localhost:8080"

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    # ルーティング
    switch ($request.Url.LocalPath) {
        "/api/nodes" {
            # 既存関数を呼び出し
            . ".\09_変数機能_コードID管理JSON.ps1"
            $id = IDを自動生成する

            $json = @{ id = $id } | ConvertTo-Json
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)

            $response.ContentType = "application/json"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        "/" {
            # HTMLファイルを返す
            $html = Get-Content ".\ui\index.html" -Raw
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)

            $response.ContentType = "text/html"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
    }

    $response.Close()
}
```

**評価**: ⭐⭐⭐⭐ (85/100)

---

### オプション3: Pure HTML + file:// プロトコル ⭐⭐

**構成**:
```
HTMLファイル（index.html）
    ↓ 直接開く（file://）
JavaScript からPowerShellを呼び出し（制約あり）
```

**メリット**:
✅ 最もシンプル（HTTPサーバー不要）
✅ 完全にインストール不要

**デメリット**:
❌ **CORSの制約が厳しい**（ファイルI/Oが困難）
❌ JavaScriptからPowerShellを直接呼び出せない
❌ ローカルファイルアクセスに制限
❌ モダンなWebAPIが使えない

**評価**: ⭐⭐ (40/100) - 実用的ではない

---

### オプション4: PowerShell + WebBrowser Control (.NET) ⭐⭐⭐

**構成**:
```powershell
# Windows Forms + WebBrowserコントロール
$form = New-Object System.Windows.Forms.Form
$browser = New-Object System.Windows.Forms.WebBrowser

$browser.DocumentText = @"
<html>
<body>
  <div id="app"></div>
  <script>
    // JavaScriptでUI構築
  </script>
</body>
</html>
"@

$form.Controls.Add($browser)
$form.ShowDialog()
```

**メリット**:
✅ 完全にインストール不要
✅ PowerShellから直接HTML/JSを埋め込める
✅ JavaScriptとPowerShellの双方向通信が可能

**デメリット**:
❌ WebBrowserコントロールは古い（IE11ベース）
❌ モダンなJavaScript機能が使えない（ES6非対応）
❌ パフォーマンスが悪い

**評価**: ⭐⭐⭐ (60/100) - レガシー技術

---

## 🏆 最終推奨: PowerShell + Polaris + Pure HTML/CSS/JS

### アーキテクチャ

```
┌─────────────────────────────────────────────┐
│ 実行.bat（ダブルクリック）                   │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ PowerShell HTTPサーバー（Polaris）           │
│ - Modules/Polaris/ に含める（配布）          │
│ - http://localhost:8080 で起動              │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ ブラウザ自動起動（既存のEdge/Chrome）        │
│ - Start-Process で自動起動                  │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ Pure HTML/CSS/JavaScript                    │
│ - CDN経由でライブラリ読み込み               │
│   - React (CDN)                             │
│   - React Flow (CDN)                        │
│ - または、Vanilla JavaScript                │
└─────────────────────────────────────────────┘
                    ↓ fetch() API
┌─────────────────────────────────────────────┐
│ PowerShell REST API                         │
│ - 既存のビジネスロジック（70%再利用）        │
└─────────────────────────────────────────────┘
```

---

## 📁 ディレクトリ構成

```
UIpowershell/
├── 実行.bat                          ← ダブルクリックで起動
├── 実行_legacy.bat                   ← 既存版（Windows Forms）
│
├── Modules/                          ← 配布用モジュール
│   └── Polaris/                      ← Polarisをコピー（一度だけ）
│       ├── Polaris.psd1
│       └── Polaris.psm1
│
├── adapter/
│   └── api-server.ps1                ← REST APIサーバー
│
├── ui/                               ← フロントエンド
│   ├── index.html                    ← メインHTML（CDN使用）
│   ├── style.css                     ← スタイル
│   └── app.js                        ← JavaScript（Vanilla or React）
│
├── 09_変数機能_コードID管理JSON.ps1  ← 既存コード（そのまま）
├── 00_共通ユーティリティ_JSON操作.ps1
└── 03_history/                       ← データ
    └── AAAAAA111/
        ├── memory.json
        └── コード.json
```

---

## 🚀 起動フロー

### 実行.bat

```batch
@echo off
echo ===================================
echo UIpowershell (HTML版) 起動中...
echo ===================================

REM PowerShell HTTPサーバーをバックグラウンドで起動
start /B powershell -ExecutionPolicy Bypass -File "%~dp0adapter\api-server.ps1"

REM 1秒待機（サーバー起動待ち）
timeout /t 1 /nobreak >nul

REM ブラウザを開く
start http://localhost:8080

echo ブラウザが開きます...
echo 終了するにはこのウィンドウを閉じてください
pause
```

---

## 💻 実装例

### adapter/api-server.ps1

```powershell
# Polarisモジュールをローカルからインポート
$modulePath = Join-Path $PSScriptRoot "..\Modules\Polaris"
Import-Module $modulePath -Force

# 既存のビジネスロジックをインポート
. "$PSScriptRoot\..\09_変数機能_コードID管理JSON.ps1"
. "$PSScriptRoot\..\00_共通ユーティリティ_JSON操作.ps1"

# 静的ファイル配信（HTML/CSS/JS）
New-PolarisStaticRoute -RoutePath "/" -FolderPath "$PSScriptRoot\..\ui"

# API: ノード一覧取得
New-PolarisRoute -Path "/api/nodes" -Method GET -ScriptBlock {
    # memory.jsonから読み込み
    $nodes = @()  # 実際の実装
    $Response.Json($nodes)
}

# API: ノード追加
New-PolarisRoute -Path "/api/nodes" -Method POST -ScriptBlock {
    $body = $Request.Body | ConvertFrom-Json

    # 既存関数を使用
    $id = IDを自動生成する
    エントリを追加_指定ID -ID $id -文字列 $body.code

    $Response.Json(@{ success = $true; id = $id })
}

# API: PowerShellスクリプト生成
New-PolarisRoute -Path "/api/generate" -Method POST -ScriptBlock {
    # 既存の実行イベント関数を改造
    $output = "# 生成されたスクリプト`n"
    # ... ビジネスロジック

    $Response.Json(@{ success = $true; script = $output })
}

# サーバー起動
Start-Polaris -Port 8080 -MinRunspaces 1 -MaxRunspaces 5
Write-Host "サーバー起動: http://localhost:8080" -ForegroundColor Green
Write-Host "終了するには Ctrl+C を押してください"

# 待機
while ($true) {
    Start-Sleep -Seconds 1
}
```

---

### ui/index.html（CDN版 - React Flow）

```html
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>UIpowershell - Visual RPA</title>

    <!-- React + ReactDOM (CDN) -->
    <script crossorigin src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
    <script crossorigin src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>

    <!-- React Flow (CDN) -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/reactflow@11/dist/style.css">
    <script src="https://cdn.jsdelivr.net/npm/reactflow@11/dist/umd/index.js"></script>

    <!-- Babel Standalone（JSX変換用） -->
    <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>

    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div id="root"></div>

    <script type="text/babel">
        const { useState, useCallback } = React;
        const { ReactFlow, useNodesState, useEdgesState, addEdge } = window.ReactFlow;

        function App() {
            const [nodes, setNodes, onNodesChange] = useNodesState([
                { id: '1', position: { x: 0, y: 0 }, data: { label: '順次処理' } },
                { id: '2', position: { x: 0, y: 100 }, data: { label: '条件分岐' } },
            ]);
            const [edges, setEdges, onEdgesChange] = useEdgesState([
                { id: 'e1-2', source: '1', target: '2', animated: true },
            ]);

            const onConnect = useCallback((params) => {
                setEdges((eds) => addEdge(params, eds));
            }, []);

            // ノードを追加
            const addNode = async () => {
                const response = await fetch('/api/nodes', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ type: 'sequential', code: 'Write-Host "OK"' })
                });

                const result = await response.json();

                if (result.success) {
                    const newNode = {
                        id: result.id,
                        position: { x: Math.random() * 400, y: Math.random() * 400 },
                        data: { label: '新しいノード' }
                    };
                    setNodes((nds) => nds.concat(newNode));
                }
            };

            // スクリプト生成
            const generateScript = async () => {
                const response = await fetch('/api/generate', { method: 'POST' });
                const result = await response.json();
                alert('スクリプト生成完了:\n\n' + result.script);
            };

            return (
                <div style={{ width: '100vw', height: '100vh', display: 'flex', flexDirection: 'column' }}>
                    <div className="toolbar">
                        <h1>UIpowershell - Visual RPA</h1>
                        <button onClick={addNode}>➕ ノード追加</button>
                        <button onClick={generateScript}>▶️ 実行</button>
                    </div>

                    <div style={{ flex: 1 }}>
                        <ReactFlow
                            nodes={nodes}
                            edges={edges}
                            onNodesChange={onNodesChange}
                            onEdgesChange={onEdgesChange}
                            onConnect={onConnect}
                            fitView
                        >
                            <ReactFlow.Background />
                            <ReactFlow.Controls />
                            <ReactFlow.MiniMap />
                        </ReactFlow>
                    </div>
                </div>
            );
        }

        ReactDOM.render(<App />, document.getElementById('root'));
    </script>
</body>
</html>
```

---

### ui/index.html（Vanilla JavaScript版 - Cytoscape.js）

インターネット接続が不安定な環境向けに、より軽量な実装：

```html
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>UIpowershell - Visual RPA</title>

    <!-- Cytoscape.js (CDN) - 軽量なグラフライブラリ -->
    <script src="https://unpkg.com/cytoscape@3/dist/cytoscape.min.js"></script>

    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }

        .toolbar {
            height: 60px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            display: flex;
            align-items: center;
            padding: 0 20px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        .toolbar h1 { flex: 1; font-size: 24px; }
        .toolbar button {
            margin-left: 10px;
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            background: white;
            color: #667eea;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.3s;
        }
        .toolbar button:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        }

        #cy {
            width: 100%;
            height: calc(100vh - 60px);
            background: #f5f5f5;
        }
    </style>
</head>
<body>
    <div class="toolbar">
        <h1>UIpowershell - Visual RPA</h1>
        <button onclick="addNode()">➕ ノード追加</button>
        <button onclick="generateScript()">▶️ 実行</button>
    </div>

    <div id="cy"></div>

    <script>
        // Cytoscapeインスタンスの初期化
        const cy = cytoscape({
            container: document.getElementById('cy'),

            elements: [
                // ノード
                { data: { id: 'node1', label: '順次処理', type: 'sequential' } },
                { data: { id: 'node2', label: '条件分岐', type: 'condition' } },
                { data: { id: 'node3', label: 'ループ', type: 'loop' } },

                // エッジ（矢印）
                { data: { source: 'node1', target: 'node2' } },
                { data: { source: 'node2', target: 'node3' } }
            ],

            style: [
                {
                    selector: 'node',
                    style: {
                        'label': 'data(label)',
                        'text-valign': 'center',
                        'text-halign': 'center',
                        'background-color': '#fff',
                        'border-color': '#333',
                        'border-width': 2,
                        'width': 120,
                        'height': 40,
                        'shape': 'roundrectangle',
                        'font-size': 14,
                        'font-weight': 'bold'
                    }
                },
                {
                    selector: 'node[type="condition"]',
                    style: {
                        'background-color': '#90EE90',
                        'shape': 'diamond',
                        'width': 100,
                        'height': 100
                    }
                },
                {
                    selector: 'node[type="loop"]',
                    style: {
                        'background-color': '#FFFACD'
                    }
                },
                {
                    selector: 'edge',
                    style: {
                        'width': 3,
                        'line-color': '#FF69B4',
                        'target-arrow-color': '#FF69B4',
                        'target-arrow-shape': 'triangle',
                        'curve-style': 'bezier'
                    }
                }
            ],

            layout: {
                name: 'preset',
                positions: {
                    'node1': { x: 100, y: 100 },
                    'node2': { x: 300, y: 150 },
                    'node3': { x: 500, y: 200 }
                }
            },

            wheelSensitivity: 0.2,
            minZoom: 0.5,
            maxZoom: 2
        });

        // ノードを追加
        async function addNode() {
            const response = await fetch('/api/nodes', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    type: 'sequential',
                    code: 'Write-Host "新しいノード"'
                })
            });

            const result = await response.json();

            if (result.success) {
                cy.add({
                    group: 'nodes',
                    data: {
                        id: 'node' + result.id,
                        label: '新しいノード',
                        type: 'sequential'
                    },
                    position: { x: 200, y: 300 }
                });
            }
        }

        // スクリプト生成
        async function generateScript() {
            const response = await fetch('/api/generate', { method: 'POST' });
            const result = await response.json();

            if (result.success) {
                alert('スクリプト生成完了:\n\n' + result.script.substring(0, 200) + '...');
            }
        }

        // ドラッグ終了時にJSON保存
        cy.on('dragfree', 'node', async (event) => {
            const node = event.target;
            console.log('ノード移動:', node.id(), node.position());

            // TODO: APIでposition更新
        });
    </script>
</body>
</html>
```

---

## 📦 Polarisモジュールの配布方法

### 1. Polarisを一度インストール

```powershell
# 開発者のPCで一度だけ実行
Install-Module -Name Polaris -Scope CurrentUser
```

### 2. モジュールをプロジェクトにコピー

```powershell
# Polarisモジュールの場所を確認
$polarisPath = (Get-Module -ListAvailable Polaris).ModuleBase

# プロジェクトにコピー
Copy-Item -Recurse $polarisPath ".\Modules\Polaris"
```

### 3. 配布

```
UIpowershell/
├── Modules/
│   └── Polaris/    ← これをZIPに含める
├── adapter/
├── ui/
└── 実行.bat
```

**ユーザー側**: ZIPを解凍して`実行.bat`をダブルクリックするだけ！

---

## ⚖️ CDN vs ローカル埋め込み

### CDN経由（推奨）

**メリット**:
- ✅ ファイルサイズが小さい
- ✅ 最新版が使える
- ✅ キャッシュが効く

**デメリット**:
- ⚠️ インターネット接続が必要

---

### ローカル埋め込み

React/React Flowをローカルファイルとして含める：

```
ui/
├── index.html
├── libs/
│   ├── react.min.js           ← ダウンロードして配布
│   ├── react-dom.min.js
│   └── reactflow.min.js
```

**メリット**:
- ✅ オフラインで動作

**デメリット**:
- ⚠️ ファイルサイズが大きい（数MB）
- ⚠️ 更新が手動

---

## 🎯 推奨アプローチ

### **Phase 1: CDN版でプロトタイプ**

まずはCDN版で素早くプロトタイプを作成：
- インターネット接続が必要
- 開発が高速

### **Phase 2: 本番用にローカル埋め込み版を作成**

完成後、オフライン対応が必要なら：
- ライブラリをダウンロード
- プロジェクトに含める

---

## 📊 技術スタック比較（再評価）

| 技術スタック | インストール不要 | 既存環境のみ | 開発効率 | パフォーマンス | 推奨度 |
|------------|----------------|------------|---------|-------------|--------|
| **PowerShell + Polaris + HTML/CSS/JS (CDN)** | ✅ (Polaris配布) | ✅ | ★★★★★ | ★★★★☆ | ⭐⭐⭐⭐⭐ (95点) |
| **PowerShell + HttpListener + HTML/CSS/JS** | ✅ | ✅ | ★★★★☆ | ★★★★☆ | ⭐⭐⭐⭐ (85点) |
| **WebBrowser Control (.NET)** | ✅ | ✅ | ★★☆☆☆ | ★★☆☆☆ | ⭐⭐⭐ (60点) |
| **Pure HTML (file://)** | ✅ | ✅ | ★☆☆☆☆ | ★★☆☆☆ | ⭐⭐ (40点) |
| ~~Tauri + React~~ | ❌ | ❌ | ★★★★★ | ★★★★★ | ❌ 不可 |
| ~~Electron~~ | ❌ | ❌ | ★★★★★ | ★★★★☆ | ❌ 不可 |

---

## 💰 コスト再評価

### 開発コスト

```
Phase 1: PowerShell HTTPサーバー（1-2週間）
  ├─ Polaris または HttpListener 実装
  └─ 静的ファイル配信

Phase 2: Pure HTML/CSS/JS フロントエンド（3-5週間）
  ├─ Cytoscape.js または React Flow (CDN)
  ├─ ドラッグ&ドロップUI
  └─ API連携

Phase 3: 既存コード修正（2-3週間）
  ├─ UI依存の除去
  └─ REST API化

Phase 4: テスト・デバッグ（2-3週間）

合計: 8-13週間（2-3ヶ月）
```

**外部依存なし**: ツール費用 **¥0**

---

## ✅ 結論

### インストール不要・既存環境のみの制約下での最適解

**推奨: PowerShell + Polaris + Pure HTML/CSS/JavaScript (CDN)**

**理由**:
1. ✅ **ユーザー側でのインストール不要**
   - Polarisモジュールを配布に含める
   - ブラウザは既存のEdge/Chrome

2. ✅ **.batファイルダブルクリックで起動**
   - PowerShellでHTTPサーバー起動
   - ブラウザ自動起動

3. ✅ **ポータブル**
   - USBメモリで持ち運べる
   - ネットワークドライブから実行可能

4. ✅ **モダンなUI**
   - React Flow または Cytoscape.js (CDN)
   - 矢印描画が自動
   - 滑らかなアニメーション

5. ✅ **既存コード70%再利用**
   - PowerShell REST API経由

---

## 🚀 次のステップ

1. **Polarisモジュールの準備**（30分）
   ```powershell
   Install-Module Polaris
   Copy-Item -Recurse (Get-Module -ListAvailable Polaris).ModuleBase ".\Modules\Polaris"
   ```

2. **プロトタイプ作成**（2-3日）
   - `adapter/api-server.ps1` 作成
   - `ui/index.html` 作成（CDN版）
   - `実行.bat` 作成

3. **動作確認**（1日）
   - ダブルクリックで起動
   - ブラウザでUI表示
   - API連携テスト

---

**Document Version**: 1.0
**Last Updated**: 2025-11-02
**Author**: Claude (AI Technical Assessor)
