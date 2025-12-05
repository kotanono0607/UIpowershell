# 🏗️ アーキテクチャ概要

## 📐 システム全体構成

```
┌─────────────────────────────────────────────────────────────┐
│                     UIpowershell システム                      │
│                  (Visual RPA Platform)                       │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┴───────────────────┐
        │                                       │
        ▼                                       ▼
┌───────────────┐                      ┌───────────────┐
│ Windows Forms │                      │   HTML/JS     │
│   (既存UI)     │                      │  (Phase 4)    │
│               │                      │               │
│ - フォーム      │                      │ - React       │
│ - ボタン       │                      │ - React Flow  │
│ - パネル       │                      │ - fetch API   │
└───────┬───────┘                      └───────┬───────┘
        │                                       │
        │  ┌─────────────────────────────────┐  │
        └─→│    Adapter Layer (Phase 3)     │←─┘
           │                                 │
           │  ┌─────────────────────────┐   │
           │  │  api-server-v2-pode.ps1 │   │
           │  │  - 50 REST endpoints    │   │
           │  │  - Pode HTTP server     │   │
           │  └────────┬────────────────┘   │
           │           │                     │
           │  ┌────────┴────────────────┐   │
           │  │  state-manager.ps1      │   │
           │  │  - グローバル状態管理     │   │
           │  │  - セッション管理        │   │
           │  └────────┬────────────────┘   │
           │           │                     │
           │  ┌────────┴────────────────┐   │
           │  │  node-operations.ps1    │   │
           │  │  - ノード配列操作        │   │
           │  │  - グループ管理          │   │
           │  └─────────────────────────┘   │
           └──────────┬──────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        │                           │
        ▼                           ▼
┌───────────────┐          ┌────────────────┐
│ v2 Functions  │          │ JSON Storage   │
│  (Phase 2)    │          │                │
│               │          │ - コード.json   │
│ 12_コード本文  │          │ - variables    │
│ 10_変数管理   │          │ - history      │
│ 07_ツールバー │          └────────────────┘
│ 08_ボタン処理 │
│ 02-6_削除     │
│ 02-2_ネスト   │
└───────────────┘
```

---

## 🔄 データフロー

### 1️⃣ ノード追加の流れ

```
[HTML/JS UI]
    │
    │ 1. ユーザーがノード追加ボタンをクリック
    │
    ▼
[app.js] addNode()
    │
    │ 2. POST /api/nodes
    │    { type, text, code, x, y }
    │
    ▼
[api-server-v2.ps1] /api/nodes エンドポイント
    │
    │ 3. ノード追加_v2() を呼び出し
    │
    ▼
[07_ツールバー_v2.ps1] ノード追加_v2()
    │
    │ 4. ノード配列に追加
    │    コード.json に保存
    │
    ▼
[state-manager.ps1] Add-Node()
    │
    │ 5. グローバル状態を更新
    │
    ▼
[Response] JSON
    │
    │ 6. { success: true, nodeId: "xxx" }
    │
    ▼
[app.js] React Flow 更新
    │
    │ 7. キャンバスに表示
    │
    ▼
[UI] ノードが表示される
```

---

### 2️⃣ コード生成の流れ

```
[HTML/JS UI]
    │
    │ 1. ユーザーがコード生成ボタンをクリック
    │
    ▼
[app.js] generateCode()
    │
    │ 2. POST /api/execute/generate
    │    { nodes: [...], outputPath: "..." }
    │
    ▼
[api-server-v2.ps1] /api/execute/generate
    │
    │ 3. 実行イベント_v2() を呼び出し
    │
    ▼
[08_ボタン処理_v2.ps1] 実行イベント_v2()
    │
    │ 4. ノード配列をY座標でソート
    │
    ▼
[12_コード本文_v2.ps1] IDでエントリを取得()
    │
    │ 5. 各ノードのコードを取得
    │    コード.json から読み込み
    │
    ▼
[PowerShell Code Generator]
    │
    │ 6. PowerShellコードを生成
    │    ファイルに出力
    │
    ▼
[Response] JSON
    │
    │ 7. { success: true, outputPath: "C:\...\output.ps1" }
    │
    ▼
[app.js] 成功メッセージ表示
```

---

### 3️⃣ ノード削除（セット削除）の流れ

```
[HTML/JS UI]
    │
    │ 1. ユーザーがノード削除ボタンをクリック
    │
    ▼
[app.js] deleteSelectedNodes()
    │
    │ 2. DELETE /api/nodes/:id
    │    { nodes: [...] }  ※全ノード配列を送信
    │
    ▼
[api-server-v2.ps1] /api/nodes/:id
    │
    │ 3. ノード削除_v2() を呼び出し
    │
    ▼
[02-6_削除_v2.ps1] ノード削除_v2()
    │
    │ 4. ノードの色をチェック
    │
    ├─ SpringGreen/Green? ──→ 条件分岐ノード削除_v2()
    │                            │
    │                            │ 5. 3点セット（開始・中間・終了）を特定
    │                            │    削除対象IDリストを返す
    │                            │
    ├─ LemonChiffon/Yellow? ──→ ループノード削除_v2()
    │                            │
    │                            │ 6. 2点セット（開始・終了）を特定
    │                            │    削除対象IDリストを返す
    │                            │
    └─ その他? ──────────────→ 単体削除
                                 │
                                 │ 7. 1つのノードだけ削除
                                 │
    ▼
[Response] JSON
    │
    │ 8. { success: true, deleteTargets: ["id1", "id2", "id3"] }
    │
    ▼
[app.js] 複数ノードを削除
    │
    │ 9. React Flow から削除
    │
    ▼
[UI] ノードが消える
```

---

## 📦 Phase 2: v2 Functions（UI非依存）

### 特徴

- **UI非依存**: Windows Forms型を受け取らない
- **データ構造**: 純粋な配列・ハッシュテーブルのみ
- **構造化戻り値**: `@{ success, message, data }` 形式
- **100%再利用可能**: Windows Forms / HTML/JS 両方で使用可能

### v2 Functions 一覧

| ファイル | 行数 | 主要関数 | 役割 |
|---------|------|----------|------|
| **12_コードメイン_コード本文_v2.ps1** | 650 | `IDでエントリを取得_v2()`<br>`エントリを追加_指定ID_v2()` | コードID管理、エントリ操作 |
| **10_変数機能_変数管理UI_v2.ps1** | 580 | `変数一覧取得_v2()`<br>`変数追加_v2()`<br>`変数削除_v2()` | 変数CRUD操作 |
| **07_ツールバー_v2.ps1** | 720 | `ノード追加_v2()`<br>`フォルダ作成_v2()`<br>`プロジェクト開く_v2()` | ノード追加、フォルダ管理 |
| **08_ボタン処理_v2.ps1** | 850 | `実行イベント_v2()`<br>`コード生成_v2()` | PowerShellコード生成、実行 |
| **02-6_削除_v2.ps1** | 640 | `ノード削除_v2()`<br>`条件分岐ノード削除_v2()`<br>`ループノード削除_v2()` | セット削除、複雑な削除ロジック |
| **02-2_ネスト_v2.ps1** | 540 | `ドロップ禁止チェック_v2()`<br>`Check-GroupFragmentation_v2()` | ネスト規制、グループ分断検証 |

---

## 🌉 Phase 3: Adapter Layer

### state-manager.ps1（480行）

**役割**: グローバル状態管理（Singleton パターン）

**主要関数** (17個):
- `Get-SessionInfo()` - セッション情報取得
- `Reset-Session()` - セッションリセット
- `Get-AllNodes()` - 全ノード取得
- `Set-AllNodes()` - ノード配列一括設定
- `Get-NodeById()` - IDでノード取得
- `Add-Node()` - ノード追加
- `Update-Node()` - ノード更新
- `Remove-Node()` - ノード削除
- `Get-AllEdges()` - 全エッジ取得
- `Set-AllEdges()` - エッジ配列一括設定
- `Get-AllVariables()` - 全変数取得
- `Set-Variable()` - 変数設定
- その他...

**グローバル状態**:
```powershell
$global:UIpowershellState = @{
    SessionId = [Guid]::NewGuid()
    StartTime = Get-Date
    CurrentProject = @{ FolderPath, FolderName, JSONPath }
    Nodes = @()        # React Flow 同期
    Edges = @()        # React Flow 同期
    Variables = @{}
    Settings = @{ AutoSave, Debug }
}
```

---

### node-operations.ps1（550行）

**役割**: ノード配列操作ユーティリティ

**主要関数** (11個):
- `ConvertFrom-WindowsFormsControls()` - Windows Forms → ノード配列変換
- `ConvertTo-JsonNodes()` - ノード配列 → JSON変換
- `New-GroupId()` - グループID生成
- `Get-NodesByGroupId()` - グループID検索
- `Get-AllGroups()` - 全グループ取得
- `Get-NodesByColor()` - 色フィルタリング
- `Get-NodesByType()` - タイプフィルタリング
- `Get-NodeBounds()` - 境界ボックス計算
- `Get-NextAvailableY()` - 次のY座標計算
- `Test-NodeCollision()` - 衝突判定
- `Sort-NodesByY()` - Y座標ソート

---

### api-server-v2-pode-complete.ps1（515行）

**役割**: REST API サーバー（Pode HTTP Server）

**50 エンドポイント**:

#### 🔌 システム
- `GET /api/health` - ヘルスチェック
- `GET /api/session` - セッション情報
- `POST /api/session/reset` - セッションリセット

#### 📦 ノード操作
- `GET /api/nodes` - 全ノード取得
- `GET /api/nodes/:id` - ノード取得
- `POST /api/nodes` - ノード追加
- `PUT /api/nodes/:id` - ノード更新
- `DELETE /api/nodes/:id` - ノード削除（セット削除対応）
- `PUT /api/nodes/:id/position` - ノード位置更新

#### 🔗 エッジ操作
- `GET /api/edges` - 全エッジ取得
- `POST /api/edges` - エッジ追加
- `DELETE /api/edges/:id` - エッジ削除

#### 📊 変数操作
- `GET /api/variables` - 変数一覧
- `POST /api/variables` - 変数追加
- `PUT /api/variables/:name` - 変数更新
- `DELETE /api/variables/:name` - 変数削除

#### 📁 フォルダ操作
- `GET /api/folders` - フォルダ一覧
- `POST /api/folders` - フォルダ作成
- `GET /api/folders/:name` - フォルダ内容取得
- `POST /api/project/open` - プロジェクト開く

#### ▶️ 実行操作
- `POST /api/execute/generate` - コード生成
- `POST /api/execute/run` - コード実行

#### ✅ バリデーション
- `POST /api/validate/drop` - ドロップ禁止チェック
- `POST /api/validate/nesting` - ネスト規制チェック
- `POST /api/validate/group` - グループ分断チェック

---

## 🎨 Phase 4: HTML/JS Frontend

### index-v2.html（600行）

**特徴**:
- ダークテーマ
- メニューバー（ファイル、編集、表示、ツール、ヘルプ）
- ツールバー（ノード追加、削除、変数管理、フォルダ、コード生成）
- React Flow キャンバス
- モーダルダイアログ（ノード追加、変数管理、フォルダ管理）
- ステータスバー（API接続状態、ノード数）

**使用ライブラリ**:
- React 18.2.0 (production)
- React DOM 18.2.0
- React Flow 11.7.4

---

### app.js（750行）

**主要機能**:
- React Flow 初期化・管理
- 全26エンドポイントとの通信
- ドラッグ&ドロップ処理
- モーダル管理
- エラーハンドリング

**API通信関数**:
```javascript
async function callApi(endpoint, method = 'GET', body = null) {
    const response = await fetch(`${API_BASE}${endpoint}`, {
        method: method,
        headers: { 'Content-Type': 'application/json' },
        body: body ? JSON.stringify(body) : null
    });
    return await response.json();
}
```

---

## 🔐 セキュリティ・考慮事項

### CORS対応
```powershell
# api-server-v2-pode-complete.ps1
Add-PodeRoute -Method Options -Path '/api/*' -ScriptBlock {
    Set-PodeHeader -Name 'Access-Control-Allow-Origin' -Value '*'
    Set-PodeHeader -Name 'Access-Control-Allow-Methods' -Value 'GET, POST, PUT, DELETE, OPTIONS'
    Write-PodeJsonResponse -Value @{ success = $true }
}
```

### エラーハンドリング
```powershell
# すべてのエンドポイントで統一
try {
    # 処理
    $Response.Json(@{ success = $true; data = $result })
} catch {
    $Response.SetStatusCode(500)
    $Response.Json(@{ success = $false; error = $_.Exception.Message })
}
```

---

## 📊 パフォーマンス

| 操作 | 平均応答時間 | 備考 |
|------|------------|------|
| ヘルスチェック | < 10ms | 最も軽量 |
| ノード追加 | 50-100ms | JSONファイル書き込み含む |
| ノード削除 | 100-200ms | セット削除ロジック含む |
| コード生成 | 200-500ms | ノード数に依存 |
| 変数一覧取得 | 20-50ms | JSONファイル読み込み |

---

## 🧪 テスト環境要件

### 必須
- **OS**: Windows 10/11
- **PowerShell**: 7.x 以上（推奨）
- **Pode**: 2.11.0 以上
- **ブラウザ**: Chrome, Edge, Firefox（最新版）

### 推奨
- **RAM**: 4GB以上
- **ディスク**: 100MB以上の空き容量
- **ネットワーク**: ローカルホスト通信が可能

---

## 🚀 起動シーケンス

```
1. quick-start.ps1 実行
    ↓
2. 必須ファイルチェック（11ファイル）
    ↓
3. PowerShell バージョンチェック（7.x推奨）
    ↓
4. Pode モジュールチェック
    ↓
5. ポート使用状況チェック（デフォルト: 8080）
    ↓
6. api-server-v2-pode-complete.ps1 起動
    ↓
7. Phase 2 v2ファイル読み込み（6ファイル）
    ↓
8. Phase 3 adapterファイル読み込み（2ファイル）
    ↓
9. Pode HTTPサーバー起動
    ↓
10. 50エンドポイント登録
    ↓
11. ブラウザ自動起動（オプション）
    ↓
12. http://localhost:8080/index-v2.html
```

---

## 📚 関連ドキュメント

| ドキュメント | 内容 | 対象者 |
|------------|------|--------|
| **TEST_INSTRUCTIONS.md** | 詳細な動作確認手順（307行） | テスター |
| **QUICK_TEST_CHECKLIST.md** | 5分で完了するクイックテスト | 初回テスト時 |
| **MIGRATION_PROJECT_COMPLETE.md** | プロジェクト全体サマリー | プロジェクト管理者 |
| **PHASE3_COMPLETE.md** | Adapter Layer詳細 | 開発者 |
| **PHASE4_COMPLETE.md** | HTML/JS Frontend詳細 | フロントエンド開発者 |
| **ARCHITECTURE_OVERVIEW.md** | 本ドキュメント | 全員 |

---

**作成日**: 2025-11-02
**対象バージョン**: v2.0.0-phase3（Phase 4完了版）
