﻿# UIpowershell HTML版プロトタイプ - 配布手順

## 🎯 配布の目的

**完全スタンドアロン・完全オフライン配布**を実現し、配布先で以下を不要にします：

- ❌ インターネット接続（完全オフライン動作）
- ❌ 管理者権限
- ❌ Install-Moduleコマンド
- ❌ 対話的プロンプト
- ❌ CDN依存（すべてのJavaScriptライブラリをローカルに同梱）

## 📦 配布方法

### 開発者側：配布パッケージの作成

#### 1. 配布パッケージ作成スクリプトを実行

```powershell
# UIpowershellディレクトリで実行
.\配布パッケージ作成.ps1
```

#### 実行内容

1. ✅ Polarisモジュールの確認（なければ自動インストール）
2. ✅ 配布ディレクトリの作成（`.\配布\UIpowershell\`）
3. ✅ 必要なファイルをコピー
   - `adapter/` - API server
   - `ui/` - HTML/JS/CSS
   - `00_code/` - 既存JSON
   - 既存PowerShell関数
   - ドキュメント
4. ✅ **Polarisモジュール全体をコピー**（重要！）
   - `Modules/Polaris/` に完全版を配置
   - 配布先でInstall-Module不要
5. ✅ 配布用READMEを作成
6. ✅ ZIPファイル作成（オプション）

#### 2. 出力されるファイル構成

```
配布/
└── UIpowershell/
    ├── Modules/
    │   └── Polaris/          ← Polarisモジュール完全版（重要！）
    │       ├── Polaris.psd1
    │       ├── Polaris.psm1
    │       └── ... (全ファイル)
    ├── adapter/
    │   └── api-server.ps1
    ├── ui/
    │   ├── index.html
    │   └── libs/              ← JavaScriptライブラリ（完全オフライン対応）
    │       ├── react.production.min.js (11KB)
    │       ├── react-dom.production.min.js (129KB)
    │       ├── reactflow.min.js (151KB)
    │       └── reactflow.min.css (7.5KB)
    ├── 00_code/
    │   └── コード.json
    ├── 00_共通ユーティリティ_JSON操作.ps1
    ├── 09_変数機能_コードID管理JSON.ps1
    ├── 実行_prototype.bat
    ├── PROTOTYPE_README.md
    └── 配布用README.txt
```

#### 3. ZIP作成

スクリプト実行時に自動作成、または手動で：

```powershell
Compress-Archive -Path ".\配布\UIpowershell" -DestinationPath ".\配布\UIpowershell_配布版.zip" -Force
```

---

### エンドユーザー側：展開と実行

#### 1. ZIPを展開

任意の場所に展開（管理者権限不要）：

- ✅ デスクトップ
- ✅ USBメモリ
- ✅ ネットワークドライブ
- ✅ ユーザーフォルダ内

#### 2. 起動

```
実行_prototype.bat をダブルクリック
```

#### 3. 初回起動時の動作

```
==================================
UIpowershell - Polaris API Server
==================================

[OK] Polarisモジュールを読み込みます: ...\Modules\Polaris
[OK] Polarisモジュールを読み込みました (Version: 0.2.0)

既存のPowerShell関数を読み込みます...
[OK] JSON操作ユーティリティ
[OK] コードID管理JSON

[OK] 静的ファイル配信: ...\ui

==================================
✓ サーバー起動成功！
==================================

アクセス先: http://localhost:8080
```

→ **Install-Moduleが実行されない！** ✅

---

## 🔍 技術詳細

### なぜ管理者権限不要か

#### 1. Polarisモジュール

- ❌ **旧実装**: `Install-Module -Scope CurrentUser`（インターネット必須）
- ✅ **新実装**: `Modules/Polaris/` に実体を同梱（オフライン可）

#### 2. api-server.ps1のロジック

```powershell
# 1. ローカルのModules/Polaris/を優先
$polarisModulePath = Join-Path $script:RootDir "Modules\Polaris"
if (Test-Path $polarisModulePath) {
    $env:PSModulePath = "$polarisModulePath;$env:PSModulePath"
}

# 2. Import-Module（ローカルから読み込み）
Import-Module Polaris -ErrorAction Stop
# → Install-Module不要！
```

#### 3. 実行ポリシー

`実行_prototype.bat` で `-ExecutionPolicy Bypass` を使用：

```bat
powershell -ExecutionPolicy Bypass -File "...\api-server.ps1" -AutoOpenBrowser
```

→ 管理者権限不要で実行可能

---

## 📊 配布パッケージのサイズ

| コンポーネント | サイズ（概算） |
|--------------|--------------|
| Polarisモジュール | 約 2-3 MB |
| **JavaScriptライブラリ（ui/libs/）** | **約 300 KB** |
| ├ React 18 | 11 KB |
| ├ ReactDOM 18 | 129 KB |
| ├ React Flow 11 JS | 151 KB |
| └ React Flow CSS | 7.5 KB |
| adapter/api-server.ps1 | 約 15 KB |
| ui/index.html | 約 15 KB |
| 既存PowerShell関数 | 約 100 KB |
| ドキュメント | 約 50 KB |
| **合計** | **約 3.5-4.5 MB** |

ZIP圧縮後：**約 1.5-2.5 MB**

---

## ⚠️ 注意事項

### 1. 完全オフライン対応 ✅

このパッケージは**完全オフライン対応**です：

- すべてのJavaScriptライブラリ（React, ReactDOM, React Flow）を `ui/libs/` にローカル同梱
- Polarisモジュールを `Modules/Polaris/` にローカル同梱
- **インターネット接続は一切不要**
- 閉域網・オフライン環境でも動作

`ui/index.html` はローカルライブラリを読み込みます：

```html
<!-- 完全オフライン対応 -->
<link rel="stylesheet" href="libs/reactflow.min.css">
<script src="libs/react.production.min.js"></script>
<script src="libs/react-dom.production.min.js"></script>
<script src="libs/reactflow.min.js"></script>
```

### 2. ポート競合

ポート8080が使用中の場合：

```powershell
.\adapter\api-server.ps1 -Port 8081 -AutoOpenBrowser
```

---

## ✅ 配布前チェックリスト

配布パッケージが正しいか確認：

- [ ] `Modules/Polaris/Polaris.psd1` が存在する
- [ ] `Modules/Polaris/Polaris.psm1` が存在する
- [ ] `adapter/api-server.ps1` が存在する
- [ ] `ui/index.html` が存在する
- [ ] `ui/libs/react.production.min.js` が存在する（11KB）
- [ ] `ui/libs/react-dom.production.min.js` が存在する（129KB）
- [ ] `ui/libs/reactflow.min.js` が存在する（151KB）
- [ ] `ui/libs/reactflow.min.css` が存在する（7.5KB）
- [ ] `実行_prototype.bat` が存在する
- [ ] **オフライン環境**（インターネット切断）で起動テスト済み
- [ ] Install-Moduleが実行されないことを確認
- [ ] ブラウザでUIが表示されることを確認（オフラインで）

---

## 🚀 配布シナリオ例

### シナリオ1: 社内配布

1. 開発者が `配布パッケージ作成.ps1` を実行
2. 生成されたZIPを社内ファイルサーバーに配置
3. 社員がZIPをダウンロード・展開
4. `実行_prototype.bat` をダブルクリック
5. → **インターネット不要、管理者権限不要で動作** ✅

### シナリオ2: USB配布

1. 開発者がUSBメモリに `配布\UIpowershell\` をコピー
2. USBメモリを配布先に渡す
3. 配布先でUSBメモリから直接実行
4. → **インストール不要で動作** ✅

### シナリオ3: ネットワークドライブ

1. 開発者がネットワークドライブに配置
2. ユーザーがネットワークドライブから実行
3. → **共有フォルダから直接実行可能** ✅

---

## 📝 配布用README.txt（自動生成）

配布パッケージ作成時に自動生成される `配布用README.txt` には以下が記載されます：

- 使い方（3ステップ）
- 含まれるもの
- 動作確認済み環境
- トラブルシューティング
- セキュリティ情報
- 配布日時・バージョン情報

---

## 🔐 企業環境での利用

### セキュリティポリシーとの互換性

#### ✅ OK（問題なし）

- PowerShell実行ポリシー：`Bypass`で回避
- ローカルモジュール：Install-Module不要
- ネットワーク：localhost (127.0.0.1) のみ
- ファイル書き込み：ユーザーフォルダ内のみ

#### ⚠️ 確認が必要

- インターネットアクセス：CDNへのHTTPS接続（オフライン版で回避可）
- PowerShell実行：企業によってはPowerShell自体が制限される場合あり

---

## 📞 サポート

配布後に問題が発生した場合：

1. `PROTOTYPE_README.md` のトラブルシューティングを参照
2. PowerShellウィンドウのエラーメッセージを確認
3. ブラウザのコンソール（F12）でエラーを確認

---

**作成者**: UIpowershell開発チーム
**最終更新**: 2025-11-02
**ライセンス**: Polaris (MIT), UIpowershell (プロジェクトライセンス)
