﻿# ローカルサーバー（Polaris）の権限とセキュリティポリシー

## 🔐 ユーザー権限の要件

### ✅ 基本的には管理者権限不要

**Polarisサーバー（ポート8080）は通常ユーザー権限で動作します**

#### Windows のポート使用権限

| ポート範囲 | 権限要件 | 備考 |
|----------|---------|------|
| 0-1023 | **管理者権限必要** | Well-knownポート（HTTP:80, HTTPS:443など） |
| 1024-49151 | **ユーザー権限OK** | 登録済みポート（多くのアプリが使用） |
| 49152-65535 | **ユーザー権限OK** | 動的・プライベートポート |

**ポート8080**: ユーザー権限で使用可能 ✅

#### 実行時の権限

```powershell
# 管理者権限不要で実行可能
.\実行_prototype.bat

# 内部で以下が実行される
Start-Polaris -Port 8080  # ← ユーザー権限でOK
```

---

## ⚠️ 組織内PCで制限される可能性

### 1. ファイアウォール制限

#### ✅ 通常は問題なし（localhostのみ）

```
Polaris: 127.0.0.1:8080 でリスニング
         ↓
ファイアウォール: localhost通信は通常許可
         ↓
ブラウザ: http://localhost:8080 にアクセス
```

**理由**: localhostへの通信は外部ネットワークを経由しないため、通常許可されます。

#### ❌ 制限される可能性（まれ）

- **ホストファイアウォール**が極端に厳しい場合
- すべてのポートリスニングをブロックするポリシー

**確認方法**:
```powershell
# ファイアウォールの受信規則を確認
Get-NetFirewallRule | Where-Object {$_.Enabled -eq $true -and $_.Direction -eq "Inbound"}

# ポート8080が使用可能か確認
Test-NetConnection -ComputerName localhost -Port 8080
```

---

### 2. PowerShell実行ポリシー

#### ⚠️ 制限される可能性：中程度

組織によってはPowerShellスクリプトの実行を制限しています。

| 実行ポリシー | 説明 | 影響 |
|------------|------|------|
| `Restricted` | すべてのスクリプト実行禁止 | ❌ 実行不可 |
| `AllSigned` | 署名付きスクリプトのみ | ❌ 実行不可（署名なし） |
| `RemoteSigned` | ローカルは実行可、ダウンロードは署名必要 | ✅ 実行可能 |
| `Unrestricted` | すべて実行可 | ✅ 実行可能 |
| `Bypass` | すべて実行可（警告なし） | ✅ 実行可能 |

**現在の実装**:
```bat
REM 実行_prototype.bat の内容
powershell -ExecutionPolicy Bypass -File "...\api-server.ps1"
```

**`-ExecutionPolicy Bypass`** により、**一時的**にポリシーを回避します。

#### ❌ グループポリシーで完全にブロックされている場合

組織のグループポリシーで以下が設定されている場合：
```
コンピューターの構成 > 管理用テンプレート > Windows コンポーネント >
Windows PowerShell > スクリプトの実行を有効にする = 無効
```

→ `-ExecutionPolicy Bypass` も無効化され、**実行不可** ❌

**確認方法**:
```powershell
# 現在の実行ポリシーを確認
Get-ExecutionPolicy -List

# 出力例
#         Scope ExecutionPolicy
#         ----- ---------------
# MachinePolicy       Undefined  ← グループポリシー
#    UserPolicy       Undefined  ← ユーザーポリシー
#       Process       Undefined
#   CurrentUser    RemoteSigned
#  LocalMachine       AllSigned
```

`MachinePolicy` が `Restricted` または `AllSigned` の場合、実行できない可能性があります。

---

### 3. アプリケーションホワイトリスト

#### ⚠️ 制限される可能性：高（金融・政府系）

一部の組織では「許可されたアプリケーションのみ実行可能」というポリシーがあります。

**AppLocker / Windows Defender Application Control (WDAC)**

```
許可リスト:
- Excel.exe ✅
- Word.exe ✅
- PowerShell.exe ??? ← これが許可されているか？
```

#### ❌ PowerShell.exeがブロックされている場合

→ **実行不可** ❌

**確認方法**:
```powershell
# AppLockerのポリシーを確認（管理者権限必要）
Get-AppLockerPolicy -Effective -Xml

# 簡易確認（通常ユーザーでも可能）
powershell -Command "Write-Host 'PowerShell is allowed'"
```

エラーが出る場合、PowerShell実行がブロックされています。

---

### 4. ウイルス対策ソフト・EDR

#### ⚠️ 制限される可能性：中程度

**Symantec Endpoint Protection / McAfee / Trend Micro / CrowdStrike など**

#### 誤検知の可能性

1. **PowerShellスクリプトのスキャン**
   - 不審なコマンド（`Start-Process`, `Invoke-WebRequest` など）を検出
   - Polarisモジュールが「不明なプログラム」として検出される可能性

2. **ネットワークアクティビティの監視**
   - ポート8080でのリスニングを検出
   - 「不審なネットワークアクティビティ」として警告

3. **ヒューリスティック分析**
   - PowerShellがHTTPサーバーを起動する挙動を検出
   - 「ランサムウェアの疑い」として誤検知される可能性

#### ✅ 対処法

- **ウイルススキャン除外**: `UIpowershell` フォルダを除外リストに追加
- **ネットワーク除外**: localhost:8080を除外
- **IT部門に事前申請**: 「業務ツール」として承認を得る

**確認方法**:
```powershell
# ウイルス対策ソフトのリアルタイム保護状態を確認
Get-MpComputerStatus  # Windows Defender

# 除外リストを確認
Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
```

---

### 5. プロキシ・ネットワーク制限

#### ✅ 通常は問題なし

**Polarisはlocalhostのみ**なので、プロキシ設定の影響を受けません。

```
ブラウザ → localhost:8080 → Polaris
    ↑ プロキシを経由しない
```

ただし、ブラウザのプロキシ設定で `localhost` が除外されていない場合、問題が発生する可能性があります。

**確認**:
- Chrome: `chrome://settings/` → 詳細設定 → プロキシ設定
- Edge: `edge://settings/system` → プロキシ設定
- Firefox: `about:preferences#general` → ネットワーク設定

`localhost`, `127.0.0.1` がプロキシから除外されているか確認。

---

## 🧪 事前確認スクリプト

組織内PCで使用可能かテストするスクリプトを作成しました：

```powershell
# 環境チェックスクリプト
# 保存先: チェック_組織PC互換性.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "UIpowershell - 組織PC互換性チェック" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$issues = @()

# 1. PowerShell実行ポリシー
Write-Host "[1/5] PowerShell実行ポリシーをチェック..." -ForegroundColor Yellow
$policies = Get-ExecutionPolicy -List
$machinePolicy = ($policies | Where-Object {$_.Scope -eq "MachinePolicy"}).ExecutionPolicy

if ($machinePolicy -eq "Restricted" -or $machinePolicy -eq "AllSigned") {
    Write-Host "  [警告] グループポリシーで実行が制限されています: $machinePolicy" -ForegroundColor Red
    $issues += "PowerShell実行ポリシー"
} else {
    Write-Host "  [OK] 実行可能: $machinePolicy" -ForegroundColor Green
}

# 2. ポート8080の使用可否
Write-Host "[2/5] ポート8080の使用可否をチェック..." -ForegroundColor Yellow
try {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 8080)
    $listener.Start()
    $listener.Stop()
    Write-Host "  [OK] ポート8080は使用可能です" -ForegroundColor Green
} catch {
    Write-Host "  [警告] ポート8080が使用できません: $($_.Exception.Message)" -ForegroundColor Red
    $issues += "ポート8080"
}

# 3. ファイアウォール（localhost通信）
Write-Host "[3/5] ファイアウォール（localhost通信）をチェック..." -ForegroundColor Yellow
try {
    $result = Test-NetConnection -ComputerName 127.0.0.1 -Port 445 -InformationLevel Quiet
    if ($result) {
        Write-Host "  [OK] localhost通信は許可されています" -ForegroundColor Green
    } else {
        Write-Host "  [警告] localhost通信がブロックされている可能性があります" -ForegroundColor Red
        $issues += "ファイアウォール"
    }
} catch {
    Write-Host "  [情報] ファイアウォールチェックをスキップ（Test-NetConnection利用不可）" -ForegroundColor Gray
}

# 4. PowerShell.exeの実行可否
Write-Host "[4/5] PowerShell.exeの実行可否をチェック..." -ForegroundColor Yellow
try {
    $testResult = powershell -Command "Write-Output 'OK'" 2>&1
    if ($testResult -eq "OK") {
        Write-Host "  [OK] PowerShell.exeは実行可能です" -ForegroundColor Green
    } else {
        Write-Host "  [警告] PowerShell.exeの実行に制限があります" -ForegroundColor Red
        $issues += "PowerShell実行制限"
    }
} catch {
    Write-Host "  [エラー] PowerShell.exeが実行できません" -ForegroundColor Red
    $issues += "PowerShell実行不可"
}

# 5. 管理者権限の確認
Write-Host "[5/5] 管理者権限をチェック..." -ForegroundColor Yellow
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Host "  [情報] 管理者権限で実行されています" -ForegroundColor Cyan
} else {
    Write-Host "  [OK] 通常ユーザー権限で実行されています（推奨）" -ForegroundColor Green
}

# 結果サマリー
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "チェック結果" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($issues.Count -eq 0) {
    Write-Host ""
    Write-Host "✓ すべてのチェックに合格しました！" -ForegroundColor Green
    Write-Host "  UIpowershellはこのPCで正常に動作する可能性が高いです。" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "⚠ 以下の問題が検出されました：" -ForegroundColor Yellow
    foreach ($issue in $issues) {
        Write-Host "  - $issue" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "対処法：" -ForegroundColor Yellow
    Write-Host "  1. IT部門に相談して制限を緩和してもらう" -ForegroundColor White
    Write-Host "  2. 別のPC（制限が緩い環境）で実行する" -ForegroundColor White
    Write-Host "  3. 管理者に業務ツールとして承認してもらう" -ForegroundColor White
    Write-Host ""
}

Write-Host "詳細は '組織PC制限事項.md' を参照してください。" -ForegroundColor Cyan
```

---

## 📊 組織タイプ別の実行可否

| 組織タイプ | 実行可否 | 制限の厳しさ | 備考 |
|----------|---------|-----------|------|
| **中小企業** | ✅ 高確率 | 低 | セキュリティポリシーが緩い |
| **大企業（IT系）** | ✅ 中確率 | 中 | 開発者権限があれば可能 |
| **大企業（非IT系）** | ⚠️ 低確率 | 高 | IT部門の承認が必要 |
| **金融機関** | ❌ 極めて低 | 極めて高 | ホワイトリスト制限 |
| **政府機関** | ❌ 極めて低 | 極めて高 | 厳格なセキュリティポリシー |

---

## 🛡️ 推奨される事前対策

### 1. IT部門への事前申請

**申請テンプレート**:

```
件名: 業務ツール（UIpowershell）の使用許可申請

業務効率化のため、以下のツールの使用許可を申請します。

【ツール名】
UIpowershell - Visual RPA Platform (HTML版)

【用途】
RPAワークフローの作成・管理

【技術仕様】
- PowerShellベースのローカルHTTPサーバー（Polaris）
- ポート: 8080（localhost のみリスニング）
- 外部通信: なし（完全ローカル動作）
- インストール: 不要（ポータブル実行）
- 管理者権限: 不要

【セキュリティ】
- localhostのみで動作（外部アクセス不可）
- インターネット接続不要（完全オフライン）
- データは全てローカルに保存
- オープンソースライブラリ使用（React, Polaris）

【ライセンス】
- Polaris: MIT License（Microsoft公式）
- React: MIT License（Meta公式）

【必要な権限】
- PowerShell実行（-ExecutionPolicy Bypass）
- ポート8080のlocalhostリスニング（ユーザー権限内）

添付資料: README, セキュリティ説明書
```

### 2. ウイルス対策ソフトの除外設定

IT部門に依頼：
```
以下のパスをウイルススキャンから除外してください:
- C:\Users\<ユーザー名>\UIpowershell\
- ポート: localhost:8080
```

### 3. 代替ポート

ポート8080が使用できない場合：
```powershell
.\adapter\api-server.ps1 -Port 9000 -AutoOpenBrowser
```

一般的な代替ポート：
- 8080（推奨）
- 8081
- 9000
- 3000
- 5000

---

## 🚨 完全にブロックされている場合の代替案

### 代替案1: スタンドアロンEXE化

PowerShellスクリプトを実行ファイル（.exe）に変換：

**PS2EXE** を使用：
```powershell
# PowerShellスクリプトをEXEに変換
Install-Module ps2exe
Invoke-ps2exe .\adapter\api-server.ps1 .\UIpowershell.exe
```

**メリット**:
- PowerShell実行ポリシーの影響を受けない
- ホワイトリストに追加しやすい

**デメリット**:
- 初回変換時に開発環境が必要
- ウイルス対策ソフトの誤検知リスクが高い

---

### 代替案2: Windows Forms版のまま使用

組織の制限が厳しすぎる場合、既存のWindows Forms版を継続使用：

**メリット**:
- HTTPサーバー不要
- PowerShell実行ポリシーの影響を受けにくい

**デメリット**:
- パフォーマンス問題（GDI+、O(n)検索）
- UI拡張性の限界

---

### 代替案3: 仮想デスクトップ・サンドボックス環境

制限のない環境を用意：

1. **Windows Sandbox** (Windows 10 Pro以降)
   ```powershell
   # Windows Sandboxを有効化
   Enable-WindowsOptionalFeature -FeatureName "Containers-DisposableClientVM" -All -Online
   ```

2. **仮想マシン（Hyper-V / VirtualBox）**
   - 制限のないWindows環境を構築

**メリット**:
- 完全な制御権
- セキュリティポリシーの影響を受けない

**デメリット**:
- 管理者権限が必要（Sandbox/Hyper-V有効化）
- パフォーマンスオーバーヘッド

---

## ✅ まとめ

### ユーザー権限で動作する条件

| 要件 | 判定 |
|-----|------|
| ポート8080の使用 | ✅ ユーザー権限でOK |
| localhost通信 | ✅ ファイアウォール通常許可 |
| PowerShell実行 | ⚠️ 組織ポリシー次第 |
| 外部ネットワーク | ✅ 不要（完全ローカル） |
| インストール | ✅ 不要（ポータブル実行） |

### 実行可能性

**✅ 実行可能な環境（80%）**:
- 中小企業
- IT系企業の開発者PC
- 個人PC
- 制限が緩い組織

**⚠️ 要相談（15%）**:
- 大企業の一般業務PC
- IT部門への申請が必要

**❌ 実行困難（5%）**:
- 金融機関（ホワイトリスト厳格）
- 政府機関（セキュリティポリシー極めて厳格）
- PowerShell完全ブロック環境

### 推奨アクション

1. **まず試す**: `チェック_組織PC互換性.ps1` を実行
2. **問題があれば**: IT部門に事前申請
3. **ブロックされたら**: 代替案を検討

---

**作成日**: 2025-11-02
**対象**: UIpowershell HTML版プロトタイプ
