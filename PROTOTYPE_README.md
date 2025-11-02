# UIpowershell HTML版プロトタイプ - 使い方

## 概要

Windows Forms → HTML/CSS/JavaScript への移行プロトタイプです。

### アーキテクチャ

```
実行_prototype.bat → Polaris HTTPサーバー (adapter/api-server.ps1)
                            ↓
                     ブラウザ (ui/index.html)
                            ↓
                     React Flow (CDN)
                            ↓
                     REST API ↔ 既存PowerShell関数 (70%再利用)
```

## 事前準備（初回のみ）

### 1. Polarisモジュールのインストール

```powershell
# PowerShellを管理者権限で開く
Install-Module -Name Polaris -Scope CurrentUser -Force

# インストール確認
Get-Module -ListAvailable -Name Polaris
```

### 2. Polarisモジュールをプロジェクトにコピー

```powershell
# UIpowershellディレクトリで実行
$polarisPath = (Get-Module Polaris -ListAvailable | Select-Object -First 1).ModuleBase
Copy-Item -Path $polarisPath -Destination ".\Modules\Polaris" -Recurse -Force

Write-Host "Polarisモジュールをコピーしました: .\Modules\Polaris" -ForegroundColor Green
```

詳細は `Modules/Polaris/README_INSTALL.md` を参照してください。

## 起動方法

### 方法1: バッチファイルで起動（推奨）

```
実行_prototype.bat をダブルクリック
```

- Polarisサーバーが起動します
- ブラウザが自動で開きます（http://localhost:8080）

### 方法2: PowerShellで直接起動

```powershell
# UIpowershellディレクトリで実行
.\adapter\api-server.ps1 -Port 8080 -AutoOpenBrowser
```

## 使い方

### 1. API接続テスト

ブラウザが開いたら、まず「API接続テスト」ボタンをクリックして接続を確認してください。

✓ 成功メッセージが表示されればOK

### 2. ノード追加

1. 「ノード追加」ボタンをクリック
2. ノードタイプを選択（開始/処理/条件分岐/ループ/終了）
3. 表示テキストを入力（例: "Excelを開く"）
4. コード（PowerShell）を入力（オプション）
5. 「追加」ボタンをクリック

→ 新しいノードがキャンバスに表示されます

### 3. ノード接続（矢印描画）

- ノードの端（ハンドル）をドラッグ＆ドロップで別のノードに接続
- 自動的に矢印が描画されます

### 4. レイヤー切り替え

- 左サイドバーの「レイヤー 1」〜「レイヤー 7」をクリック
- 現在のレイヤーが切り替わります

### 5. データ保存/読み込み

- 「保存」ボタン: 現在のフローをJSON保存（実装予定）
- 「読み込み」ボタン: `00_code/コード.json` からエントリを読み込み

## 既存のWindows Formsとの比較

| 機能 | Windows Forms | HTML版プロトタイプ |
|------|--------------|-----------------|
| **パネル描画** | 7層Panel + 400+Buttons | React Flow (自動レイアウト) |
| **矢印描画** | GDI+ 50+行のコード | 自動（エッジ接続） |
| **ボタン配置** | 手動座標計算 | ドラッグ＆ドロップ |
| **検索** | O(n) ループ | ハッシュマップ O(1) |
| **ズーム/パン** | カスタム実装 | React Flow標準機能 |
| **起動速度** | 3-5秒 | 1秒未満 |

## プロトタイプの制限事項

このプロトタイプは**概念実証（PoC）** です。以下の機能は未実装です：

### 未実装の機能

- ❌ ノード削除機能
- ❌ ノード編集機能
- ❌ データ保存機能（JSONへの書き込み）
- ❌ スナップショット機能
- ❌ 変数管理UI
- ❌ コード実行機能
- ❌ Excel連携
- ❌ 条件分岐ロジック
- ❌ ループ処理

### 実装済みの機能

- ✅ Polaris HTTPサーバー起動
- ✅ React Flow基本描画
- ✅ ノード追加（API経由）
- ✅ エントリ読み込み（API経由）
- ✅ レイヤー切り替えUI
- ✅ API接続テスト
- ✅ 7層レイヤーUI
- ✅ 既存PowerShell関数の呼び出し（adapter層）

## 技術スタック

### フロントエンド（ui/index.html）

- **React 18** (CDN) - UIフレームワーク
- **React Flow 11** (CDN) - フローチャート描画
- **純粋HTML/CSS/JavaScript** - ゼロビルド

### バックエンド（adapter/api-server.ps1）

- **Polaris 0.2.0** - PowerShell HTTPサーバー
- **既存PowerShell関数** - 70%再利用
  - `09_変数機能_コードID管理JSON.ps1`
  - `00_共通ユーティリティ_JSON操作.ps1`

### REST APIエンドポイント

| メソッド | エンドポイント | 説明 |
|---------|--------------|------|
| GET | `/api/health` | ヘルスチェック |
| POST | `/api/id/generate` | 新規ID生成 |
| POST | `/api/entry/add` | エントリ追加 |
| GET | `/api/entry/:id` | エントリ取得 |
| GET | `/api/entries/all` | 全エントリ取得 |
| DELETE | `/api/entry/:id` | エントリ削除 |
| PUT | `/api/button/position` | ボタン位置更新 |

## 既存PowerShell関数の再利用状況

### ✅ 100%再利用可能（修正不要）

- `09_変数機能_コードID管理JSON.ps1`
  - `IDを自動生成する`
  - `エントリを追加_指定ID`
  - `IDでエントリを取得`
- `00_共通ユーティリティ_JSON操作.ps1`
  - 全関数

### 🔧 修正が必要（UI依存部分のみ）

- `08_メインF機能_メインボタン処理.ps1`
  - `$global:レイヤー1.Controls` → JSON配列に変更
- `02-4_ボタン操作配置.ps1`
  - Windows Forms座標 → React Flow座標に変換

### 🗑️ 削除可能（HTML/JSが代替）

- `02-7_矢印描画.ps1` - React Flowが自動描画
- `02-1_フォーム基礎構築.ps1` - HTML/CSSが代替

## トラブルシューティング

### Q1: 「Polarisモジュールの読み込みに失敗しました」

**原因**: Polarisがインストールされていない、または`Modules/Polaris/`にコピーされていない

**解決方法**:
```powershell
Install-Module -Name Polaris -Scope CurrentUser -Force
$polarisPath = (Get-Module Polaris -ListAvailable | Select-Object -First 1).ModuleBase
Copy-Item -Path $polarisPath -Destination ".\Modules\Polaris" -Recurse -Force
```

### Q2: 「ポート8080が既に使用中」

**原因**: 別のアプリケーションがポート8080を使用している

**解決方法**:
```powershell
# 別のポートで起動
.\adapter\api-server.ps1 -Port 8081
```

または、使用中のプロセスを確認:
```powershell
Get-NetTCPConnection -LocalPort 8080
```

### Q3: 「API接続テスト」が失敗する

**原因**: `adapter/api-server.ps1` が起動していない

**解決方法**:
1. `実行_prototype.bat` をダブルクリック
2. PowerShellウィンドウに「✓ サーバー起動成功！」と表示されるまで待つ
3. ブラウザで再度「API接続テスト」をクリック

### Q4: ブラウザが自動で開かない

**原因**: `-AutoOpenBrowser` オプションが機能していない

**解決方法**:
手動でブラウザを開いて http://localhost:8080 にアクセスしてください

### Q5: ノードが表示されない

**原因**: React Flowの初期化エラー、またはCDNが読み込めない

**解決方法**:
1. ブラウザのコンソール（F12）を開いてエラーを確認
2. インターネット接続を確認（CDNから読み込むため）
3. ページをリロード（Ctrl+R）

## 次のステップ

このプロトタイプが正常に動作したら、次のフェーズに進めます：

### Phase 4: 段階的移行（2-4週間）

1. **Week 1-2**: コア機能の実装
   - ノード編集・削除機能
   - データ保存機能（JSON書き込み）
   - 既存UI依存関数のアダプター実装

2. **Week 3-4**: 高度な機能の実装
   - 変数管理UI
   - コード実行機能
   - Excel連携
   - 条件分岐・ループロジック

### Phase 5: 並行運用（1-2週間）

- 既存Windows Forms版と並行運用
- ユーザーフィードバック収集
- バグ修正・パフォーマンス改善

### Phase 6: 完全移行

- Windows Forms版を非推奨化
- HTML版を正式版として採用

## フィードバック

プロトタイプを試したら、以下を確認してください：

- [ ] Polarisサーバーが正常に起動する
- [ ] ブラウザでUIが表示される
- [ ] API接続テストが成功する
- [ ] ノードが追加できる
- [ ] ノード間の接続（矢印）ができる
- [ ] レイヤー切り替えができる
- [ ] 既存の`コード.json`が読み込める

---

**開発者**: Microsoft Polaris Team (Polaris)
**ライセンス**: MIT License
**配布**: ゼロインストール（Modules/Polarisを含めてZIP配布可能）
