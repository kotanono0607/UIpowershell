# Pode移行計画書

**作成日**: 2025年11月16日
**対象プロジェクト**: UIpowershell
**移行元**: Polaris (アーカイブ済み・開発終了)
**移行先**: Pode v2.12.1 (活発に開発中)

---

## 📋 エグゼクティブサマリー

### 移行の目的

1. **パフォーマンス改善**: 起動時間を15.3秒 → 3-5秒へ短縮 (70-80%改善)
2. **保守性向上**: 開発終了したPolarisから活発なPodeへ移行
3. **将来性確保**: セキュリティパッチと新機能の継続的な提供
4. **機能拡張の基盤**: WebSocket、認証、キャッシング等の高度な機能を利用可能に

### 想定効果

| 項目 | 現状 (Polaris) | 移行後 (Pode) | 改善率 |
|------|----------------|---------------|--------|
| API応答時間 | ~1000ms/リクエスト | ~10-50ms/リクエスト | **95-99%削減** |
| 総起動時間 | 15.3秒 | 約8-10秒 | **35-48%削減** |
| 並列化後の起動時間 | N/A | **3-5秒** | **67-80%削減** |
| メンテナンス | 終了 | 活発 | ∞ |

### 所要期間

**合計**: 2-3日
**推奨実施期間**: 2025年11月18日-20日

---

## 🔍 現状分析

### 変更対象ファイル一覧

#### 1. コアファイル（必須変更）

| ファイル | 変更箇所 | 重要度 | 推定時間 |
|----------|----------|--------|----------|
| `adapter/api-server-v2.ps1` | 46個のルート定義、258箇所のResponse、62箇所のRequest | ⭐⭐⭐⭐⭐ | 4-6時間 |
| `配布パッケージ作成.ps1` | Polarisモジュール → Pode | ⭐⭐⭐⭐☆ | 30分 |
| `quick-start.ps1` | Polarisチェック → Pode | ⭐⭐⭐☆☆ | 15分 |
| `チェック_組織PC互換性.ps1` | Polarisテスト → Pode | ⭐⭐☆☆☆ | 15分 |

#### 2. モジュール（置き換え）

| 現在 | 変更後 | サイズ |
|------|--------|--------|
| `Modules/Polaris/` (287KB) | `Modules/Pode/` (約2-3MB) | +2.7MB |

### API エンドポイント一覧

**合計**: 46個のエンドポイント

#### コア機能 (9個)
- `OPTIONS *` - CORS プリフライト
- `GET /api/health` - ヘルスチェック
- `GET /api/session` - セッション情報
- `GET /api/debug` - デバッグ情報
- `GET /api/nodes` - ノード一覧取得
- `PUT /api/nodes` - ノード更新
- `POST /api/nodes` - ノード作成
- `DELETE /api/nodes/all` - 全ノード削除
- `DELETE /api/nodes/:id` - ノード削除

#### 変数管理 (6個)
- `GET /api/variables` - 変数一覧
- `GET /api/variables/:name` - 変数取得
- `POST /api/variables` - 変数作成
- `PUT /api/variables/:name` - 変数更新
- `DELETE /api/variables/:name` - 変数削除
- `POST /api/variables/manage` - 変数管理ダイアログ

#### メニュー・実行 (3個)
- `GET /api/menu/structure` - メニュー構造
- `POST /api/menu/action/:actionId` - メニューアクション
- `POST /api/execute/generate` - コード生成実行
- `POST /api/code-result/show` - コード結果表示
- `POST /api/execute/script` - スクリプト実行

#### フォルダ管理 (10個)
- `GET /api/folders` - フォルダ一覧
- `POST /api/folders` - フォルダ作成
- `PUT /api/folders/:name` - フォルダ更新
- `POST /api/folders/switch-dialog` - フォルダ切り替えダイアログ
- `GET /api/main-json` - main.json取得
- `GET /api/folders/:name/memory` - memory.json取得
- `POST /api/folders/:name/memory` - memory.json保存
- `GET /api/folders/:name/code` - code.json取得
- `POST /api/folders/:name/code` - code.json保存
- `GET /api/folders/:name/variables` - フォルダ変数取得

#### その他機能 (8個)
- `POST /api/validate/drop` - ドロップ検証
- `POST /api/id/generate` - ID生成
- `POST /api/entry/add` - エントリ追加
- `GET /api/entry/:id` - エントリ取得
- `GET /api/entries/all` - 全エントリ取得
- `GET /api/node/functions` - ノード関数一覧
- `POST /api/node/execute/:functionName` - ノード関数実行
- `POST /api/node/edit-script` - スクリプト編集
- `POST /api/node/settings` - ノード設定

#### ログ機能 (2個)
- `POST /api/browser-logs` - ブラウザログ
- `POST /api/control-log` - コントロールログ

#### 静的ファイル配信 (8個)
- `GET /` - index-legacy.html
- `GET /index-legacy.html`
- `GET /style-legacy.css`
- `GET /app-legacy.js`
- `GET /layer-detail.html`
- `GET /layer-detail.js`
- `GET /modal-functions.js`
- `GET /button-settings.json`
- `GET /ボタン設定.json`

---

## 🗺️ 移行ロードマップ

### フェーズ0: 準備（0.5日）

#### タスク0-1: Pode調査・検証 (2時間)
- [ ] Pode v2.12.1 の公式ドキュメント確認
- [ ] サンプルコード作成と動作確認
- [ ] Polaris → Pode 変換パターンの確立

#### タスク0-2: バックアップとブランチ作成 (30分)
- [ ] 現在のコードを別ブランチにバックアップ
- [ ] 移行専用ブランチ作成: `feature/pode-migration`
- [ ] ロールバック手順の確認

#### タスク0-3: 開発環境セットアップ (30分)
- [ ] Pode モジュールインストール
```powershell
Install-Module -Name Pode -Scope CurrentUser -Force
```
- [ ] バージョン確認
```powershell
Get-Module -ListAvailable -Name Pode
```

---

### フェーズ1: コア移行（1日）

#### タスク1-1: api-server-v2.ps1 の基本構造変換 (3時間)

**変更内容**:

##### 1. モジュールインポート
```powershell
# Before (Polaris)
Import-Module Polaris -ErrorAction Stop

# After (Pode)
Import-Module Pode -ErrorAction Stop
```

##### 2. サーバー起動構造
```powershell
# Before (Polaris)
New-PolarisRoute -Path "/api/health" -Method GET -ScriptBlock { ... }
Start-Polaris -Port $Port -MinRunspaces 5 -MaxRunspaces 5

# After (Pode)
Start-PodeServer {
    # エンドポイント設定
    Add-PodeEndpoint -Address localhost -Port $Port -Protocol Http

    # スレッド設定（パフォーマンス向上）
    Set-PodeServerConfiguration -Threads 5

    # ルート定義
    Add-PodeRoute -Method Get -Path "/api/health" -ScriptBlock { ... }
}
```

##### 3. ルート定義パターン
```powershell
# Before (Polaris)
New-PolarisRoute -Path "/api/health" -Method GET -ScriptBlock {
    $response = @{ status = "OK" }
    $json = $response | ConvertTo-Json -Depth 10
    $Response.Send($json)
}

# After (Pode)
Add-PodeRoute -Method Get -Path "/api/health" -ScriptBlock {
    Write-PodeJsonResponse -Value @{ status = "OK" }
}
```

##### 4. パスパラメータ
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

##### 5. リクエストボディ
```powershell
# Before (Polaris)
$body = $Request.Body | ConvertFrom-Json

# After (Pode)
$body = $WebEvent.Data
# または
# $body = ConvertFrom-Json -InputObject $WebEvent.Request.Body
```

##### 6. CORS設定
```powershell
# Before (Polaris)
New-PolarisRoute -Path "*" -Method OPTIONS -ScriptBlock {
    $Response.SetHeader("Access-Control-Allow-Origin", "*")
    $Response.SetHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
    $Response.SetHeader("Access-Control-Allow-Headers", "Content-Type")
    $Response.Send('')
}

# After (Pode)
# Podeの組み込みCORSミドルウェアを使用
Add-PodeCors -Name 'AllowAll' -Origin '*' -Methods 'GET, POST, PUT, DELETE, OPTIONS' -Headers 'Content-Type'
```

##### 7. 静的ファイル配信
```powershell
# Before (Polaris)
New-PolarisRoute -Path "/style-legacy.css" -Method GET -ScriptBlock {
    $cssPath = Join-Path $script:RootDir "ui\style-legacy.css"
    $css = Get-Content $cssPath -Raw -Encoding UTF8
    $Response.SetHeader("Content-Type", "text/css; charset=utf-8")
    $Response.Send($css)
}

# After (Pode)
Add-PodeStaticRoute -Path '/ui' -Source (Join-Path $script:RootDir 'ui')
# または個別ルート
Add-PodeRoute -Method Get -Path "/style-legacy.css" -ScriptBlock {
    $cssPath = Join-Path $script:RootDir "ui\style-legacy.css"
    Write-PodeFileResponse -Path $cssPath -ContentType 'text/css'
}
```

#### タスク1-2: 全46エンドポイントの変換 (3-4時間)

**変換チェックリスト**:
- [ ] OPTIONS * (CORS)
- [ ] GET /api/health
- [ ] GET /api/session
- [ ] GET /api/debug
- [ ] GET /api/nodes
- [ ] PUT /api/nodes
- [ ] POST /api/nodes
- [ ] DELETE /api/nodes/all
- [ ] DELETE /api/nodes/:id
- [ ] GET /api/variables
- [ ] GET /api/variables/:name
- [ ] POST /api/variables
- [ ] PUT /api/variables/:name
- [ ] DELETE /api/variables/:name
- [ ] POST /api/variables/manage
- [ ] GET /api/menu/structure
- [ ] POST /api/menu/action/:actionId
- [ ] POST /api/execute/generate
- [ ] POST /api/code-result/show
- [ ] POST /api/execute/script
- [ ] GET /api/folders
- [ ] POST /api/folders
- [ ] PUT /api/folders/:name
- [ ] POST /api/folders/switch-dialog
- [ ] GET /api/main-json
- [ ] GET /api/folders/:name/memory
- [ ] POST /api/folders/:name/memory
- [ ] GET /api/folders/:name/code
- [ ] POST /api/folders/:name/code
- [ ] GET /api/folders/:name/variables
- [ ] POST /api/validate/drop
- [ ] POST /api/id/generate
- [ ] POST /api/entry/add
- [ ] GET /api/entry/:id
- [ ] GET /api/entries/all
- [ ] GET /api/node/functions
- [ ] POST /api/node/execute/:functionName
- [ ] POST /api/node/edit-script
- [ ] POST /api/node/settings
- [ ] POST /api/browser-logs
- [ ] POST /api/control-log
- [ ] GET / (index-legacy.html)
- [ ] GET /index-legacy.html
- [ ] GET /style-legacy.css
- [ ] GET /app-legacy.js
- [ ] GET /layer-detail.html
- [ ] GET /layer-detail.js
- [ ] GET /modal-functions.js
- [ ] GET /button-settings.json
- [ ] GET /ボタン設定.json

#### タスク1-3: エラーハンドリング追加 (1時間)
```powershell
# Podeのエラーハンドリング
Add-PodeRoute -Method Get -Path "/api/nodes" -ScriptBlock {
    try {
        # 処理
        Write-PodeJsonResponse -Value $result
    }
    catch {
        Write-PodeJsonResponse -Value @{
            error = $_.Exception.Message
            status = "error"
        } -StatusCode 500
    }
}
```

---

### フェーズ2: 配布関連ファイル修正（0.5日）

#### タスク2-1: 配布パッケージ作成.ps1 の修正 (30分)

```powershell
# ============================================
# 変更箇所1: モジュール名の変更
# ============================================

# Before
$polarisModule = Get-Module -ListAvailable -Name Polaris | Select-Object -First 1
if (-not $polarisModule) {
    Install-Module -Name Polaris -Scope CurrentUser -Force -AllowClobber
}

# After
$podeModule = Get-Module -ListAvailable -Name Pode | Select-Object -First 1
if (-not $podeModule) {
    Install-Module -Name Pode -Scope CurrentUser -Force -AllowClobber
}

# ============================================
# 変更箇所2: モジュールコピー先
# ============================================

# Before
$polarisSourcePath = $polarisModule.ModuleBase
$polarisDestPath = Join-Path $distUIpowershell "Modules\Polaris"
Copy-Item -Path $polarisSourcePath -Destination $polarisDestPath -Recurse -Force

# After
$podeSourcePath = $podeModule.ModuleBase
$podeDestPath = Join-Path $distUIpowershell "Modules\Pode"
Copy-Item -Path $podeSourcePath -Destination $podeDestPath -Recurse -Force

# ============================================
# 変更箇所3: README内容
# ============================================

# Before
- Polarisモジュール (Version $($polarisModule.Version)) - 同梱済み

# After
- Podeモジュール (Version $($podeModule.Version)) - 同梱済み
```

#### タスク2-2: quick-start.ps1 の修正 (15分)
```powershell
# モジュールチェック部分を Polaris → Pode に変更
Write-Host "【Step 3】Podeモジュールの確認..." -ForegroundColor Yellow
```

#### タスク2-3: チェック_組織PC互換性.ps1 の修正 (15分)
```powershell
# Polarisテスト → Pode テストに変更
$podePath = Join-Path $PSScriptRoot "Modules\Pode"
if (Test-Path $podePath) {
    Import-Module Pode -ErrorAction Stop
    $podeVersion = (Get-Module Pode).Version
    Write-Host "[OK] Podeモジュールを読み込めました (Version: $podeVersion)"
}
```

#### タスク2-4: Podeモジュールの配置 (15分)
```powershell
# 既存の Modules/Polaris を削除
Remove-Item -Path "Modules/Polaris" -Recurse -Force

# Podeモジュールをコピー
$podeModule = Get-Module -ListAvailable -Name Pode | Select-Object -First 1
Copy-Item -Path $podeModule.ModuleBase -Destination "Modules/Pode" -Recurse -Force
```

---

### フェーズ3: テスト・検証（0.5日）

#### タスク3-1: 単体テスト (2時間)

**テスト項目**:

1. **サーバー起動テスト**
   - [ ] サーバーが正常に起動する
   - [ ] ポート8080でリッスンしている
   - [ ] ブラウザ自動起動が動作する

2. **APIエンドポイントテスト** (各エンドポイントを順次確認)
   - [ ] GET /api/health → 200 OK
   - [ ] GET /api/session → セッション情報返却
   - [ ] GET /api/nodes → ノード一覧返却
   - [ ] POST /api/nodes → ノード作成成功
   - [ ] PUT /api/nodes → ノード更新成功
   - [ ] DELETE /api/nodes/:id → ノード削除成功
   - [ ] 変数管理API (6個) → 全て正常動作
   - [ ] フォルダ管理API (10個) → 全て正常動作
   - [ ] 実行系API (3個) → 全て正常動作
   - [ ] その他API (10個) → 全て正常動作

3. **静的ファイル配信テスト**
   - [ ] GET / → index-legacy.html表示
   - [ ] GET /style-legacy.css → CSS読み込み
   - [ ] GET /app-legacy.js → JavaScript読み込み
   - [ ] ブラウザコンソールエラーなし

4. **パフォーマンステスト**
   - [ ] API応答時間計測 (目標: <50ms)
   - [ ] 起動時間計測 (目標: Polaris比50%削減)
   - [ ] メモリ使用量確認

#### タスク3-2: 統合テスト (1時間)

**テストシナリオ**:

1. **ノード作成→編集→削除フロー**
   ```
   1. ブラウザでUIを開く
   2. ノードを作成
   3. ノードを編集
   4. ノードを削除
   5. すべて正常動作を確認
   ```

2. **フォルダ切り替えフロー**
   ```
   1. フォルダAでノード作成
   2. フォルダBに切り替え
   3. フォルダBでノード作成
   4. フォルダAに戻る
   5. フォルダAのノードが保持されていることを確認
   ```

3. **変数管理フロー**
   ```
   1. 変数を作成
   2. 変数を編集
   3. 変数を削除
   4. すべて正常動作を確認
   ```

4. **コード生成・実行フロー**
   ```
   1. ノードからコード生成
   2. 生成されたコードを確認
   3. コードを実行
   4. 結果が正しく表示されることを確認
   ```

#### タスク3-3: 回帰テスト (1時間)

**既存機能の動作確認**:
- [ ] 起動時のコントロールログが正常に記録される
- [ ] ミリ秒精度のタイムスタンプが表示される
- [ ] ブラウザコンソールログがサーバーに送信される
- [ ] エラーハンドリングが正常に動作する

---

### フェーズ4: ドキュメント更新（0.5日）

#### タスク4-1: README更新 (30分)
- [ ] Polaris → Pode に記述変更
- [ ] インストール手順の更新
- [ ] パフォーマンス改善の記載

#### タスク4-2: 配布用README更新 (15分)
- [ ] モジュール名の変更
- [ ] バージョン情報の更新

#### タスク4-3: 移行完了レポート作成 (1時間)
- [ ] 変更内容のサマリー
- [ ] パフォーマンス比較データ
- [ ] 既知の問題・制限事項
- [ ] 今後の最適化計画

---

## 🎯 変換パターン早見表

### 基本パターン

| 項目 | Polaris | Pode |
|------|---------|------|
| **モジュールインポート** | `Import-Module Polaris` | `Import-Module Pode` |
| **サーバー起動** | `Start-Polaris -Port 8080` | `Start-PodeServer { Add-PodeEndpoint -Port 8080 }` |
| **サーバー停止** | `Stop-Polaris` | `Close-PodeServer` (自動) |
| **GETルート** | `New-PolarisRoute -Path "/api/test" -Method GET` | `Add-PodeRoute -Method Get -Path "/api/test"` |
| **POSTルート** | `New-PolarisRoute -Path "/api/test" -Method POST` | `Add-PodeRoute -Method Post -Path "/api/test"` |
| **PUTルート** | `New-PolarisRoute -Path "/api/test" -Method PUT` | `Add-PodeRoute -Method Put -Path "/api/test"` |
| **DELETEルート** | `New-PolarisRoute -Path "/api/test" -Method DELETE` | `Add-PodeRoute -Method Delete -Path "/api/test"` |

### データアクセス

| 項目 | Polaris | Pode |
|------|---------|------|
| **リクエストボディ** | `$Request.Body \| ConvertFrom-Json` | `$WebEvent.Data` |
| **パスパラメータ** | `$Request.Parameters.id` | `$WebEvent.Parameters.id` |
| **クエリパラメータ** | `$Request.Query.name` | `$WebEvent.Query.name` |
| **ヘッダー取得** | `$Request.Headers['Content-Type']` | `$WebEvent.Request.Headers['Content-Type']` |

### レスポンス

| 項目 | Polaris | Pode |
|------|---------|------|
| **JSON送信** | `$Response.Send($json)` | `Write-PodeJsonResponse -Value $obj` |
| **テキスト送信** | `$Response.Send($text)` | `Write-PodeTextResponse -Value $text` |
| **ファイル送信** | `$Response.Send($content)` | `Write-PodeFileResponse -Path $path` |
| **ヘッダー設定** | `$Response.SetHeader("X-Custom", "value")` | `Set-PodeHeader -Name "X-Custom" -Value "value"` |
| **ステータスコード** | `$Response.StatusCode = 404` | `Set-PodeResponseStatus -Code 404` |

### 特殊機能

| 項目 | Polaris | Pode |
|------|---------|------|
| **CORS** | 手動でOPTIONSルート作成 | `Add-PodeCors -Name 'AllowAll'` |
| **静的ファイル** | 個別ルート作成 | `Add-PodeStaticRoute -Path '/ui' -Source $path` |
| **ミドルウェア** | `New-PolarisRouteMiddleware` | `Add-PodeMiddleware` |
| **スレッド設定** | `-MinRunspaces 5 -MaxRunspaces 5` | `Set-PodeServerConfiguration -Threads 5` |

---

## ⚠️ リスク評価

### 高リスク

| リスク | 影響 | 軽減策 | 優先度 |
|--------|------|--------|--------|
| **API互換性の欠如** | 既存のブラウザJSコードが動作しない | 全エンドポイントの動作確認テスト | ⭐⭐⭐⭐⭐ |
| **パスパラメータの違い** | `:id`形式のルートが機能しない | 変換パターンの事前検証 | ⭐⭐⭐⭐☆ |
| **静的ファイル配信の変更** | CSS/JSが読み込めない | 静的ルート優先実装 | ⭐⭐⭐⭐☆ |

### 中リスク

| リスク | 影響 | 軽減策 | 優先度 |
|--------|------|--------|--------|
| **エラーハンドリングの違い** | エラー時の挙動が変わる | Pode標準のエラーハンドリング実装 | ⭐⭐⭐☆☆ |
| **ログ出力の変更** | デバッグ情報が取得できない | Podeのログ機能を活用 | ⭐⭐⭐☆☆ |
| **モジュールサイズ増加** | 配布パッケージが大きくなる | 許容範囲内 (+2.7MB) | ⭐⭐☆☆☆ |

### 低リスク

| リスク | 影響 | 軽減策 | 優先度 |
|--------|------|--------|--------|
| **学習コストの増加** | 新しいAPIに慣れる必要がある | ドキュメント整備 | ⭐⭐☆☆☆ |
| **パフォーマンス調整** | 最適なスレッド数の決定 | 段階的に調整 | ⭐☆☆☆☆ |

---

## 🔄 ロールバック計画

### ロールバック条件

以下のいずれかに該当する場合、Polarisに戻す：

1. **致命的バグ**: 3時間以内に解決できない重大な不具合
2. **パフォーマンス劣化**: Polarisより遅い場合
3. **互換性問題**: ブラウザUIが正常に動作しない場合

### ロールバック手順

```powershell
# 1. 移行前のブランチに戻る
git checkout claude/timestamp-logging-nodes-01FoBKKdrBvpDTjdnUucnX9f

# 2. Podeモジュールを削除
Remove-Item -Path "Modules/Pode" -Recurse -Force

# 3. Polarisモジュールを復元（バックアップから）
Copy-Item -Path "backup/Modules/Polaris" -Destination "Modules/Polaris" -Recurse

# 4. 動作確認
.\adapter\api-server-v2.ps1 -Port 8080 -AutoOpenBrowser
```

**所要時間**: 15分以内

---

## 📊 成功基準

### 必須条件 (Must Have)

- [ ] 全46個のAPIエンドポイントが正常に動作
- [ ] ブラウザUIがエラーなく表示される
- [ ] ノードの作成・編集・削除が正常に機能
- [ ] フォルダの切り替えが正常に機能
- [ ] 変数管理が正常に機能
- [ ] コード生成・実行が正常に機能
- [ ] 既存のログ機能が維持される

### 推奨条件 (Should Have)

- [ ] API応答時間が50ms以下
- [ ] 起動時間がPolaris比50%削減
- [ ] メモリ使用量が許容範囲内 (<500MB)
- [ ] エラーハンドリングが適切

### 期待条件 (Nice to Have)

- [ ] CORS設定が組み込みミドルウェアで実装
- [ ] 静的ファイルが効率的に配信される
- [ ] ログ出力が見やすい
- [ ] 将来の機能拡張に対応できる構造

---

## 📅 実施スケジュール

### 推奨スケジュール（3日間）

**Day 1**: フェーズ0 + フェーズ1
- 午前: 準備・環境セットアップ (2.5時間)
- 午後: api-server-v2.ps1 変換 (4時間)

**Day 2**: フェーズ1完了 + フェーズ2 + フェーズ3開始
- 午前: エンドポイント変換完了 (3時間)
- 午後: 配布ファイル修正 + 単体テスト開始 (4時間)

**Day 3**: フェーズ3完了 + フェーズ4
- 午前: 統合テスト・回帰テスト (3時間)
- 午後: ドキュメント更新・移行完了レポート (2時間)

---

## 🛠️ 必要なツール・リソース

### 開発環境
- [ ] PowerShell 5.1 以降
- [ ] Pode モジュール v2.12.1
- [ ] Git (バージョン管理)
- [ ] テキストエディタ (VS Code推奨)

### テストツール
- [ ] ブラウザ (Chrome/Edge/Firefox)
- [ ] ブラウザ開発者ツール
- [ ] Stopwatchによる時間計測

### ドキュメント
- [ ] Pode公式ドキュメント: https://badgerati.github.io/Pode/
- [ ] この移行計画書
- [ ] 変換パターン早見表

---

## 📝 チェックリスト

### 移行開始前
- [ ] このドキュメントを読む
- [ ] バックアップブランチを作成
- [ ] Podeモジュールをインストール
- [ ] サンプルコードで動作確認

### 移行中
- [ ] 各フェーズのタスクを順次完了
- [ ] 変更内容をGitにコミット
- [ ] テストを並行実施
- [ ] 問題があればすぐに記録

### 移行完了後
- [ ] 全テストがパス
- [ ] ドキュメント更新完了
- [ ] 移行完了レポート作成
- [ ] コードレビュー実施

---

## 🎓 参考リソース

### Pode公式ドキュメント
- メインサイト: https://badgerati.github.io/Pode/
- Getting Started: https://badgerati.github.io/Pode/Getting-Started/
- Routes: https://badgerati.github.io/Pode/Tutorials/Routes/Overview/
- Responses: https://badgerati.github.io/Pode/Tutorials/Routes/Responses/

### GitHub
- Pode Repository: https://github.com/Badgerati/Pode
- Polaris Repository: https://github.com/PowerShell/Polaris (Archived)

---

## 📞 サポート

### 問題が発生した場合

1. **まずは変換パターン早見表を確認**
2. **Pode公式ドキュメントを参照**
3. **ロールバック計画を実行**（致命的な場合）

---

**作成者**: Claude Code
**最終更新**: 2025年11月16日
**バージョン**: 1.0
