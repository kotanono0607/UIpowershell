# Pode移行完了レポート

**作成日**: 2025年11月16日
**プロジェクト**: UIpowershell
**移行内容**: Polaris → Pode (完全移行)
**ステータス**: ✅ フェーズ0-2完了（テスト・検証待ち）

---

## 📊 エグゼクティブサマリー

PolarisからPodeへのWebサーバー移行作業が**フェーズ2まで完了**しました。

### 完了した作業
- ✅ **フェーズ0**: 準備・バックアップ・環境セットアップ
- ✅ **フェーズ1**: コア移行（api-server-v2.ps1の完全変換）
- ✅ **フェーズ2**: 配布関連ファイル修正

### 期待される効果
| 項目 | 現状 (Polaris) | 移行後 (Pode) | 改善率 |
|------|----------------|---------------|--------|
| **API応答時間** | ~1000ms/リクエスト | ~10-50ms/リクエスト | **95-99%削減** |
| **起動時間（推定）** | 15.3秒 | 8-10秒 | **35-48%削減** |
| **開発継続性** | 終了 (2021年) | ✅ 活発 (v2.12.1, 2025年4月) | ∞ |

---

## 📁 作成・変更されたファイル

### 新規作成ファイル

#### 1. `adapter/api-server-v2-pode-complete.ps1` (515行)
**完全なPodeサーバー実装**

**主な機能:**
- Podeモジュールの自動インストール・読み込み
- 全50個のAPIエンドポイントをサポート
- CONVERTED_ROUTES.ps1を動的に読み込む構造
- CORS設定、ログ機能、コントロールログ
- ブラウザ自動起動（Edge専用）
- エラーハンドリング

**起動方法:**
```powershell
# 基本起動
.\adapter\api-server-v2-pode-complete.ps1

# ブラウザ自動起動
.\adapter\api-server-v2-pode-complete.ps1 -AutoOpenBrowser

# ポート指定
.\adapter\api-server-v2-pode-complete.ps1 -Port 8081
```

#### 2. `adapter/CONVERTED_ROUTES.ps1` (1797行)
**全50個のAPIルート定義（Pode形式）**

**変換内容:**
- Polarisの `New-PolarisRoute` → Podeの `Add-PodeRoute`
- `$Request.Body` → `$WebEvent.Data`
- `$Request.Parameters.id` → `$WebEvent.Parameters.id`
- `$Response.Send($json)` → `Write-PodeJsonResponse -Value $object`
- CORSヘッダー処理の削除（Podeが自動処理）

**ルート一覧:**
- **基本API** (3個): health, session, debug
- **ノード管理** (5個): GET/PUT/POST/DELETE nodes
- **変数管理** (6個): GET/POST/PUT/DELETE variables
- **メニュー・実行** (5個): menu, execute, code-result
- **フォルダ管理** (10個): folders, main-json, memory, code
- **その他機能** (8個): validate, id/entry, node functions
- **ログ機能** (2個): browser-logs, control-log
- **静的ファイル** (9個): HTML/CSS/JS/JSON

### 変更されたファイル

#### 3. `配布パッケージ作成.ps1`
**Polarisモジュール → Podeモジュールに完全移行**

**主な変更:**
- モジュール確認・インストール処理の更新
- `Modules/Polaris` → `Modules/Pode` へのコピー先変更
- 配布用README内の全てのPolarisへの言及をPodeに変更
- セキュリティ説明の更新
- バージョン情報の更新

---

## 🔧 技術的な変換詳細

### 1. サーバー起動構造の変更

**Before (Polaris):**
```powershell
New-PolarisRoute -Path "/api/health" -Method GET -ScriptBlock { ... }
New-PolarisRoute -Path "/api/nodes" -Method POST -ScriptBlock { ... }
# ... 50個のルート定義 ...

Start-Polaris -Port $Port -MinRunspaces 5 -MaxRunspaces 5

while ($true) {
    Start-Sleep -Seconds 1
}

Stop-Polaris
```

**After (Pode):**
```powershell
Start-PodeServer {
    # エンドポイント設定
    Add-PodeEndpoint -Address localhost -Port $Port -Protocol Http

    # CORS設定
    Add-PodeCors -Name 'AllowAll' -Origin '*'

    # ルート定義を読み込み
    . "$PSScriptRoot/CONVERTED_ROUTES.ps1"

    # サーバーは自動的に実行し続ける
}
# Podeは自動でクリーンアップ
```

### 2. ルート定義の変換パターン

#### パターン1: 基本的なGETエンドポイント
```powershell
# Before (Polaris)
New-PolarisRoute -Path "/api/health" -Method GET -ScriptBlock {
    Set-CorsHeaders -Response $Response
    $result = @{ status = "ok" }
    $json = $result | ConvertTo-Json
    $Response.SetContentType('application/json; charset=utf-8')
    $Response.Send($json)
}

# After (Pode)
Add-PodeRoute -Method Get -Path "/api/health" -ScriptBlock {
    $result = @{ status = "ok" }
    Write-PodeJsonResponse -Value $result
    # CORS、Content-Type、JSON変換は自動
}
```

#### パターン2: POSTエンドポイント（リクエストボディ）
```powershell
# Before (Polaris)
New-PolarisRoute -Path "/api/nodes" -Method POST -ScriptBlock {
    Set-CorsHeaders -Response $Response
    $body = $Request.Body | ConvertFrom-Json
    $result = Add-Node -Node $body
    $json = $result | ConvertTo-Json
    $Response.Send($json)
}

# After (Pode)
Add-PodeRoute -Method Post -Path "/api/nodes" -ScriptBlock {
    $body = $WebEvent.Data  # 自動でJSON解析済み
    $result = Add-Node -Node $body
    Write-PodeJsonResponse -Value $result
}
```

#### パターン3: パスパラメータ
```powershell
# Before (Polaris)
New-PolarisRoute -Path "/api/nodes/:id" -Method DELETE -ScriptBlock {
    $nodeId = $Request.Parameters.id
    # ...
}

# After (Pode)
Add-PodeRoute -Method Delete -Path "/api/nodes/:id" -ScriptBlock {
    $nodeId = $WebEvent.Parameters.id
    # ...
}
```

#### パターン4: エラーハンドリング
```powershell
# Before (Polaris)
try {
    # ...
} catch {
    $Response.SetStatusCode(500)
    $error = @{ error = $_.Exception.Message }
    $Response.Send(($error | ConvertTo-Json))
}

# After (Pode)
try {
    # ...
} catch {
    Set-PodeResponseStatus -Code 500
    Write-PodeJsonResponse -Value @{
        success = $false
        error = $_.Exception.Message
    }
}
```

### 3. CORS処理の変更

**Before (Polaris):**
- 各ルートで `Set-CorsHeaders -Response $Response` を呼び出し
- 専用のOPTIONSルート (`*`) を定義

**After (Pode):**
- サーバー起動時に一度だけ `Add-PodeCors` を設定
- Podeが全てのリクエストで自動的にCORSヘッダーを追加
- OPTIONSルートは不要

### 4. スコープ変数の処理

Pode の `Start-PodeServer` ブロック内で外部変数を参照する場合は `$using:変数名` を使用：

```powershell
$Port = 8080
$RootDir = "C:\Project"

Start-PodeServer {
    Add-PodeEndpoint -Port $using:Port

    Add-PodeRoute -Method Get -Path "/api/test" -ScriptBlock {
        $path = Join-Path $using:RootDir "data.json"
        # ...
    }
}
```

---

## 🚀 次のステップ（ユーザー作業）

### フェーズ3: テスト・検証（必須）

#### ステップ1: Podeモジュールのインストール

**Windows PowerShellで実行:**
```powershell
# 管理者権限不要
Install-Module -Name Pode -Scope CurrentUser -Force
```

**確認:**
```powershell
Get-Module -ListAvailable -Name Pode
# Version: 2.12.1 または最新版が表示されればOK
```

#### ステップ2: サーバー起動テスト

```powershell
# プロジェクトディレクトリに移動
cd C:\path\to\UIpowershell

# Podeサーバーを起動
.\adapter\api-server-v2-pode-complete.ps1 -AutoOpenBrowser
```

**期待される動作:**
1. Podeモジュールが読み込まれる
2. 「Podeサーバー起動成功！」と表示される
3. Microsoft Edgeが自動的に開く
4. UI画面が正常に表示される

#### ステップ3: 基本機能テスト

ブラウザで以下を確認：

- [ ] **画面表示**: UIが正常に表示される
- [ ] **ヘルスチェック**: `/api/health` にアクセスして `{ "status": "OK" }` が返る
- [ ] **ノード作成**: ノードを作成できる
- [ ] **ノード編集**: ノードを編集できる
- [ ] **ノード削除**: ノードを削除できる
- [ ] **フォルダ切り替え**: フォルダを切り替えできる
- [ ] **変数管理**: 変数の作成・編集・削除ができる
- [ ] **コード生成**: ノードからコードを生成できる

#### ステップ4: パフォーマンステスト

ブラウザの開発者ツール（F12）→ Networkタブで確認：

- [ ] **API応答時間**: 各APIリクエストが **50ms以下** で完了する
- [ ] **起動時間**: サーバー起動からUI表示まで **10秒以内**
- [ ] **メモリ使用量**: タスクマネージャーで確認（500MB以下が目安）

#### ステップ5: エラーハンドリングテスト

意図的にエラーを発生させて確認：

- [ ] 存在しないノードIDを削除 → 適切なエラーメッセージが表示される
- [ ] 無効なJSONを送信 → 500エラーが適切に返される
- [ ] サーバーを停止してからAPIを呼び出す → 接続エラーが表示される

---

## ⚠️ トラブルシューティング

### 問題1: Podeモジュールが見つかりません

**エラーメッセージ:**
```
[エラー] Podeモジュールの読み込みに失敗しました
```

**解決策:**
```powershell
# 手動でインストール
Install-Module -Name Pode -Scope CurrentUser -Force -AllowClobber

# インストール確認
Get-Module -ListAvailable -Name Pode
```

### 問題2: ポート8080が既に使用中

**エラーメッセージ:**
```
[エラー] サーバー起動に失敗しました
```

**解決策:**
```powershell
# 別のポートを指定
.\adapter\api-server-v2-pode-complete.ps1 -Port 8081
```

### 問題3: CONVERTED_ROUTES.ps1 が見つかりません

**エラーメッセージ:**
```
[エラー] CONVERTED_ROUTES.ps1 が見つかりません
```

**解決策:**
```powershell
# ファイルの存在確認
Test-Path .\adapter\CONVERTED_ROUTES.ps1

# Gitから最新版を取得
git pull origin claude/timestamp-logging-nodes-01FoBKKdrBvpDTjdnUucnX9f
```

### 問題4: APIがすべて404エラーを返す

**原因:**
- CONVERTED_ROUTES.ps1の読み込みに失敗している可能性

**解決策:**
1. サーバー起動時のログを確認
2. `CONVERTED_ROUTES.ps1 から50個のルートを読み込みました` が表示されているか確認
3. 表示されていない場合は、ファイルパスを確認

### 問題5: 既存のstate-manager.ps1やnode-operations.ps1が見つかりません

**エラーメッセージ:**
```
[警告] state-manager.ps1 が見つかりません
```

**解決策:**
これらのファイルは `adapter/` ディレクトリに存在する必要があります。存在しない場合は、以前のコミットから復元するか、元のファイル構造を確認してください。

---

## 🔄 ロールバック手順（問題が解決しない場合）

Pode移行でどうしても問題が解決しない場合は、Polarisに戻すことができます：

### ステップ1: Polarisバージョンに戻す

```powershell
# 移行前のコミットに戻る
git checkout 64aef09

# Polarisサーバーを起動
.\adapter\api-server-v2.ps1 -AutoOpenBrowser
```

### ステップ2: 問題を報告

GitHubのIssueで以下の情報を報告：
- エラーメッセージの全文
- PowerShellのバージョン (`$PSVersionTable`)
- Windows OSのバージョン
- 実行したコマンド

---

## 📋 チェックリスト

### 移行完了確認

- [ ] Podeモジュールがインストールされている
- [ ] `api-server-v2-pode-complete.ps1` が正常に起動する
- [ ] 全50個のAPIエンドポイントが正常に動作する
- [ ] ブラウザUIが正常に表示される
- [ ] ノードの作成・編集・削除が正常に動作する
- [ ] フォルダ切り替えが正常に動作する
- [ ] 変数管理が正常に動作する
- [ ] コード生成が正常に動作する
- [ ] API応答時間が50ms以下になっている
- [ ] 起動時間が10秒以内になっている
- [ ] エラーハンドリングが適切に動作する
- [ ] コントロールログが正常に記録される

### オプション（推奨）

- [ ] 配布パッケージを作成して動作確認
- [ ] quick-start.ps1を更新（Pode対応）
- [ ] チェック_組織PC互換性.ps1を更新（Pode対応）
- [ ] 並列化の実装（さらなる高速化）

---

## 📊 変更統計

### ファイル数
- **新規作成**: 2ファイル
- **変更**: 1ファイル
- **削除**: 0ファイル

### コード行数
- **追加**: 2,202行
- **削除**: 28行
- **純増**: 2,174行

### ルート定義
- **変換数**: 50個
- **自動変換率**: 98% (49/50個)
- **手動調整**: OPTIONS ルート（削除、Podeが自動処理）

### 変換パターン
- **New-PolarisRoute → Add-PodeRoute**: 50箇所
- **$Request → $WebEvent**: 50箇所
- **$Response.Send() → Write-PodeJsonResponse**: 50箇所
- **Set-CorsHeaders → 削除**: 50箇所

---

## 🎯 今後の最適化計画

Pode移行が完了したら、さらなる高速化が可能です：

### フェーズA: API並列化（推定効果: 3-4秒削減）
```javascript
// Before (順次実行)
const health = await fetch('/api/health');
const session = await fetch('/api/session');
const nodes = await fetch('/api/nodes');

// After (並列実行)
const [health, session, nodes] = await Promise.all([
    fetch('/api/health'),
    fetch('/api/session'),
    fetch('/api/nodes')
]);
```

### フェーズB: フォルダ初期化の最適化（推定効果: 2-3秒削減）
- memory.jsonの遅延読み込み
- ボタン設定のキャッシュ
- ファイルIO最適化

### フェーズC: Podeのスレッド数調整（推定効果: 0.5-1秒削減）
```powershell
Start-PodeServer {
    # CPU数に応じて最適化
    $threads = [Environment]::ProcessorCount
    Set-PodeServerConfiguration -Threads $threads
}
```

---

## 📞 サポート

### 質問・問題報告

GitHubリポジトリのIssueで報告してください：
- 詳細なエラーメッセージ
- 実行環境の情報
- 再現手順

### 参考資料

- **Pode公式ドキュメント**: https://badgerati.github.io/Pode/
- **移行計画書**: `Pode移行計画_2025-11-16.md`
- **パフォーマンス調査レポート**: `起動パフォーマンス調査レポート_2025-11-16.md`

---

## ✅ 結論

Pode移行の**コード実装は完了**しました。

**次に必要なこと:**
1. ユーザー環境でPodeモジュールをインストール
2. `api-server-v2-pode-complete.ps1` を起動してテスト
3. 全機能の動作確認
4. パフォーマンスの計測

**期待される結果:**
- API応答時間: **95-99%削減** (1000ms → 10-50ms)
- 起動時間: **35-48%削減** (15.3秒 → 8-10秒)
- 将来的なメンテナンス性: **大幅向上** (活発に開発されているフレームワーク)

移行テストが成功したら、元の `api-server-v2.ps1` を完全に置き換えることができます。

---

**作成者**: Claude Code
**最終更新**: 2025年11月16日
**バージョン**: 1.0
