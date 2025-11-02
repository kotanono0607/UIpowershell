# Polarisモジュール インストール手順

## 概要
このディレクトリにPolarisモジュールを配置することで、ゼロインストール配布が可能になります。

## 開発者向け：初回セットアップ手順

### 1. Polarisモジュールのインストール
```powershell
# PowerShell Galleryからインストール
Install-Module -Name Polaris -Scope CurrentUser -Force

# インストール確認
Get-Module -ListAvailable -Name Polaris
```

### 2. このディレクトリへのコピー
```powershell
# Polarisモジュールの場所を取得
$polarisPath = (Get-Module Polaris -ListAvailable | Select-Object -First 1).ModuleBase

# プロジェクトのModulesディレクトリにコピー
Copy-Item -Path $polarisPath -Destination ".\Modules\Polaris" -Recurse -Force

Write-Host "Polarisモジュールをコピーしました: .\Modules\Polaris"
```

### 3. 配布時の扱い
- `Modules/Polaris/` ディレクトリ全体をZIP配布に含める
- ユーザー側ではインストール不要
- `実行.bat` が自動的にこのモジュールを読み込む

## エンドユーザー向け：利用方法

**インストール不要です！**

`実行.bat` をダブルクリックするだけで、自動的にPolarisモジュールが読み込まれます。

## 配布元情報

- **公式リポジトリ**: https://github.com/PowerShell/Polaris
- **PowerShell Gallery**: https://www.powershellgallery.com/packages/Polaris
- **開発元**: Microsoft PowerShell Team
- **ライセンス**: MIT License（商用利用・再配布可能）
- **バージョン**: 0.2.0

## トラブルシューティング

### Polarisモジュールが見つからない場合
```powershell
# モジュールパスの確認
$env:PSModulePath -split ';'

# 手動でモジュールパスを追加（実行.batで自動実行）
$env:PSModulePath = "$PSScriptRoot\Modules;$env:PSModulePath"
Import-Module Polaris -Force
```

### ポートが使用中の場合
```powershell
# ポート8080が使用中か確認
Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue

# adapter/api-server.ps1 の $Port 変数を変更（例：8081）
```
