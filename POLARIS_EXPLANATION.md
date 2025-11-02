# Polarisの役割とは？
# PowerShellでHTTPサーバーを簡単に作るためのモジュール

**更新日**: 2025-11-02

---

## 🎯 Polarisとは？

**Polaris = PowerShell製のHTTPサーバー（Webサーバー）フレームワーク**

簡単に言うと：
```
PowerShellで書ける、軽量・シンプルなWebサーバー
```

---

## 🤔 なぜHTTPサーバーが必要なのか？

### 問題: HTML/JavaScriptとPowerShellを繋ぐ方法

```
ブラウザ（HTML/JavaScript）
    ↓
    ？？？ どうやって通信する？
    ↓
PowerShell（既存のビジネスロジック）
```

**ブラウザとPowerShellは直接通信できません！**

### 解決策: HTTPサーバーを間に挟む

```
ブラウザ（HTML/JavaScript）
    ↓ HTTP通信（fetch()）
HTTPサーバー ← Polarisの役割！
    ↓ PowerShellスクリプト実行
PowerShell（既存のビジネスロジック）
```

---

## 📊 具体例で理解する

### シナリオ: ボタンをクリックしたら新しいノードIDを生成したい

#### ❌ Polarisなしの場合（不可能）

```html
<!-- index.html -->
<button onclick="generateId()">IDを生成</button>

<script>
function generateId() {
    // ❌ ブラウザから直接PowerShellを呼び出せない！
    // どうすれば既存の「IDを自動生成する」関数を呼べる？
}
</script>
```

```powershell
# 09_変数機能_コードID管理JSON.ps1
function IDを自動生成する {
    # ... 既存のロジック
    return $newID
}
```

**問題**: ブラウザのJavaScriptから、PowerShellの関数を直接呼び出す方法がない！

---

#### ✅ Polarisありの場合（可能）

**Step 1: PolarisでHTTPサーバーを作る**

```powershell
# api-server.ps1
Import-Module Polaris

# 既存のPowerShell関数をインポート
. ".\09_変数機能_コードID管理JSON.ps1"

# APIエンドポイントを作成
New-PolarisRoute -Path "/api/generate-id" -Method GET -ScriptBlock {
    # 既存の関数を呼び出し
    $newId = IDを自動生成する

    # JSON形式で返す
    $Response.Json(@{ id = $newId })
}

# サーバー起動
Start-Polaris -Port 8080
Write-Host "サーバー起動: http://localhost:8080"
```

**Step 2: HTMLからAPIを呼び出す**

```html
<!-- index.html -->
<button onclick="generateId()">IDを生成</button>
<p id="result"></p>

<script>
async function generateId() {
    // ✅ HTTPリクエストでPowerShellの関数を呼び出せる！
    const response = await fetch('http://localhost:8080/api/generate-id');
    const data = await response.json();

    document.getElementById('result').textContent = '生成されたID: ' + data.id;
}
</script>
```

**フロー**:
```
1. ユーザーがボタンをクリック
2. JavaScript が fetch() で http://localhost:8080/api/generate-id にアクセス
3. Polaris が "/api/generate-id" を受け取る
4. PowerShellの「IDを自動生成する」関数を実行
5. 結果をJSON形式で返す
6. JavaScript が結果を受け取って画面に表示
```

---

## 🎭 Polarisの役割を劇場に例えると

```
【役者】
ブラウザ（観客）: "IDを生成してください！"
PowerShell（舞台裏のスタッフ）: 実際の処理を行う人

【問題】
観客は舞台裏に直接入れない
→ どうやって依頼する？

【解決】
Polaris（受付・案内係）: 観客の依頼を聞いて、舞台裏に伝える

【フロー】
1. 観客（ブラウザ）が受付（Polaris）に依頼
   「IDを生成してください」

2. 受付（Polaris）が舞台裏（PowerShell）に伝える
   「お客様がIDを生成したいそうです」

3. スタッフ（PowerShell）が処理を実行
   「はい、ID: 123 です」

4. 受付（Polaris）が観客に結果を伝える
   「ID: 123 が生成されました」

5. 観客（ブラウザ）が結果を受け取る
   「ありがとう！」
```

---

## 🔧 Polarisの主な機能

### 1. ルーティング（URLとPowerShell関数の紐付け）

```powershell
# GET /api/nodes → ノード一覧を取得
New-PolarisRoute -Path "/api/nodes" -Method GET -ScriptBlock {
    $nodes = Get-Content "memory.json" | ConvertFrom-Json
    $Response.Json($nodes)
}

# POST /api/nodes → ノードを追加
New-PolarisRoute -Path "/api/nodes" -Method POST -ScriptBlock {
    $body = $Request.Body | ConvertFrom-Json
    # ノードを追加する処理
    $Response.Json(@{ success = $true })
}

# DELETE /api/nodes/:id → ノードを削除
New-PolarisRoute -Path "/api/nodes/:id" -Method DELETE -ScriptBlock {
    $nodeId = $Request.Parameters.id
    # ノードを削除する処理
    $Response.Json(@{ success = $true })
}
```

**Polarisがやってくれること**:
- URLを解析して、対応するScriptBlockを実行
- HTTPメソッド（GET/POST/DELETE等）を判別
- リクエストのボディ（JSON等）を受け取る
- レスポンスを返す

---

### 2. 静的ファイル配信（HTML/CSS/JSファイルを配信）

```powershell
# ui/ フォルダの中身をブラウザに配信
New-PolarisStaticRoute -RoutePath "/" -FolderPath "$PSScriptRoot\ui"
```

**これで以下が可能に**:
```
http://localhost:8080/           → ui/index.html を返す
http://localhost:8080/style.css  → ui/style.css を返す
http://localhost:8080/app.js     → ui/app.js を返す
```

---

### 3. JSON形式での自動変換

```powershell
# PowerShellのハッシュテーブルを自動的にJSONに変換
$Response.Json(@{
    id = 123,
    name = "順次処理",
    type = "sequential"
})

# ↓ ブラウザには以下のJSONが返る
# {
#   "id": 123,
#   "name": "順次処理",
#   "type": "sequential"
# }
```

---

### 4. HTTPサーバーの起動・停止

```powershell
# サーバー起動
Start-Polaris -Port 8080 -MinRunspaces 1 -MaxRunspaces 5

# サーバー停止
Stop-Polaris
```

---

## 🆚 Polarisなしの場合（代替手段）

### 代替手段1: .NET HttpListener（標準機能）

```powershell
# Polarisを使わずに書くと...
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:8080/")
$listener.Start()

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    # ルーティングを手動で実装
    if ($request.Url.LocalPath -eq "/api/generate-id" -and $request.HttpMethod -eq "GET") {
        # 既存関数を呼び出し
        $id = IDを自動生成する

        # JSON形式に変換
        $json = @{ id = $id } | ConvertTo-Json
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)

        # レスポンスを返す
        $response.ContentType = "application/json; charset=utf-8"
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
    }
    elseif ($request.Url.LocalPath -eq "/" -and $request.HttpMethod -eq "GET") {
        # HTMLファイルを読み込んで返す
        $html = Get-Content ".\ui\index.html" -Raw
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)

        $response.ContentType = "text/html; charset=utf-8"
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
    }
    # ... 他のURLも同様に手動実装

    $response.Close()
}
```

**比較**:

| 項目 | Polaris | HttpListener（手動） |
|-----|---------|---------------------|
| コード量 | 10行 | 50行以上 |
| ルーティング | 自動 | 手動実装 |
| JSON変換 | 自動 | 手動実装 |
| 静的ファイル配信 | 1行 | 手動実装（20行以上） |
| 可読性 | 高い | 低い |

**Polarisを使うメリット**: コードが圧倒的にシンプル！

---

### 代替手段2: IIS（Internet Information Services）

Windows標準のWebサーバー

**メリット**:
- 高性能
- 安定性が高い

**デメリット**:
- ❌ **インストール・設定が必要**（ユーザー側でも設定必要）
- ❌ 管理者権限が必要
- ❌ ポータブルではない
- ❌ RPAツールとしての要件に合わない

**結論**: インストール不要という要件に反するため不可

---

## 💡 なぜPolarisが最適なのか？

### 1. インストール不要（配布可能）

```powershell
# 開発者が一度だけ実行
Install-Module Polaris
Copy-Item -Recurse (Get-Module -ListAvailable Polaris).ModuleBase ".\Modules\Polaris"

# ↓ プロジェクトに含めて配布
UIpowershell/
├── Modules/
│   └── Polaris/    ← これを配布
└── api-server.ps1

# api-server.ps1 でローカルモジュールをインポート
Import-Module "$PSScriptRoot\Modules\Polaris" -Force
```

**ユーザー側**: インストール不要！ ZIPを解凍するだけ

---

### 2. シンプルで分かりやすい

```powershell
# たった数行でAPIサーバーが作れる
Import-Module Polaris

New-PolarisRoute -Path "/api/hello" -Method GET -ScriptBlock {
    $Response.Json(@{ message = "Hello World" })
}

Start-Polaris -Port 8080
```

---

### 3. PowerShellとの親和性が高い

```powershell
# 既存のPowerShell関数をそのまま呼び出せる
. ".\09_変数機能_コードID管理JSON.ps1"

New-PolarisRoute -Path "/api/nodes" -Method POST -ScriptBlock {
    # 既存関数をそのまま使える！
    $id = IDを自動生成する
    エントリを追加_指定ID -ID $id -文字列 $body.code

    $Response.Json(@{ success = $true; id = $id })
}
```

---

## 📊 全体のアーキテクチャ（Polarisの位置づけ）

```
┌─────────────────────────────────────────────┐
│ 【プレゼンテーション層】                     │
│ ブラウザ（HTML/CSS/JavaScript）              │
│ - ユーザーが操作するUI                       │
│ - React Flow（フローエディタ）               │
└─────────────────────────────────────────────┘
                    ↕ HTTP通信（fetch API）
┌─────────────────────────────────────────────┐
│ 【HTTPサーバー層】 ← Polarisの役割！         │
│ PowerShell + Polaris                        │
│ - リクエストを受け取る                       │
│ - ルーティング（URL → 処理）                 │
│ - レスポンスを返す                           │
└─────────────────────────────────────────────┘
                    ↕ 関数呼び出し
┌─────────────────────────────────────────────┐
│ 【ビジネスロジック層】                       │
│ 既存のPowerShell関数（70%再利用）            │
│ - IDを自動生成する                           │
│ - エントリを追加                             │
│ - JSON操作                                   │
└─────────────────────────────────────────────┘
                    ↕ ファイルI/O
┌─────────────────────────────────────────────┐
│ 【データ層】                                 │
│ JSONファイル（memory.json、コード.json）     │
└─────────────────────────────────────────────┘
```

**Polarisの役割**: ブラウザとPowerShellの橋渡し

---

## 🚀 実際の動作フロー

### 例: ユーザーが「ノードを追加」ボタンをクリック

```
1. ユーザーがブラウザで「ノードを追加」ボタンをクリック

2. JavaScript が fetch() を実行
   fetch('http://localhost:8080/api/nodes', {
       method: 'POST',
       body: JSON.stringify({ type: 'sequential' })
   })

3. ブラウザがHTTPリクエストを送信
   → http://localhost:8080/api/nodes

4. Polaris がリクエストを受け取る
   → "/api/nodes" のルートを見つける

5. 対応するScriptBlockを実行
   New-PolarisRoute -Path "/api/nodes" -Method POST -ScriptBlock {
       $body = $Request.Body | ConvertFrom-Json
       $id = IDを自動生成する  ← 既存関数を呼び出し
       エントリを追加_指定ID -ID $id -文字列 "..."
       $Response.Json(@{ success = $true; id = $id })
   }

6. PowerShell が既存の関数を実行
   - IDを自動生成
   - JSONファイルに保存

7. Polaris が結果をJSON形式で返す
   { "success": true, "id": "123" }

8. ブラウザが結果を受け取る
   const data = await response.json();

9. JavaScript が画面を更新
   // 新しいノードを表示
```

---

## 💰 Polarisのコスト

### ライセンス

```
✅ 完全に無料（MIT License）
✅ 商用利用可能
✅ 再配布可能
```

### インストール

```powershell
# 開発者が一度だけ実行（5分）
Install-Module -Name Polaris -Scope CurrentUser

# プロジェクトにコピー（1分）
Copy-Item -Recurse (Get-Module -ListAvailable Polaris).ModuleBase ".\Modules\Polaris"
```

**総コスト**: ¥0 + 作業時間6分

---

## 🎯 まとめ

### Polarisとは？

**PowerShellで簡単にHTTPサーバーを作れるモジュール**

### Polarisの役割

**ブラウザ（HTML/JavaScript）とPowerShell（既存コード）を繋ぐ橋渡し**

### なぜPolarisが必要？

ブラウザから直接PowerShellの関数を呼び出せないため、HTTPサーバーを間に挟む必要がある

### Polarisのメリット

1. ✅ インストール不要（配布可能）
2. ✅ コードがシンプル（10行程度）
3. ✅ PowerShellとの親和性が高い
4. ✅ 無料（MIT License）
5. ✅ 既存コードをそのまま呼び出せる

### Polarisなしの場合

.NET HttpListener を使えば可能だが、コードが複雑（50行以上）になり、保守性が下がる

---

## 🔗 参考リソース

- **GitHub**: https://github.com/PowerShell/Polaris
- **Examples**: https://github.com/PowerShell/Polaris/tree/master/Examples
- **ドキュメント**: https://github.com/PowerShell/Polaris/wiki

---

**Document Version**: 1.0
**Last Updated**: 2025-11-02
**Author**: Claude (AI Technical Assessor)
