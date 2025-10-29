# UIpowershell リファクタリング計画

## プロジェクト規模
- ファイル数: 37個のPowerShellスクリプト
- コード行数: 8,091行
- 推定作業期間: 5-7日（段階的アプローチ）

---

## 段階的リファクタリング計画

### 【フェーズ1】基礎固め（1日目）
**目的: 安全性とデバッグ能力の向上**

#### 1.1 文字エンコーディング統一（1時間）
- [ ] 全.ps1ファイルをUTF-8 BOMで保存し直す
- [ ] 文字化けの確認と修正
- [ ] Git commit: "Fix: UTF-8 BOM encoding for all files"

#### 1.2 ロギング機能追加（2時間）
- [ ] Logger.ps1を作成
- [ ] 主要な処理にログ出力を追加
- [ ] ログファイル保存先の設定
- [ ] Git commit: "Add: Logging infrastructure"

#### 1.3 エラー処理追加（4時間）
- [ ] 01_メインフォーム_メイン.ps1にtry-catch追加
- [ ] JSON読み込み処理にエラー処理追加
- [ ] ファイルI/O処理にエラー処理追加
- [ ] ユーザーへのエラーメッセージ表示
- [ ] Git commit: "Add: Error handling for critical operations"

**成果物:**
- 安定性向上
- 問題発生時にログで原因特定可能
- ユーザーにフレンドリーなエラーメッセージ

---

### 【フェーズ2】設定の外部化（2日目）
**目的: ハードコードされた値の削除**

#### 2.1 設定ファイル作成（2時間）
- [ ] config/settings.json作成
- [ ] パス設定の外部化
- [ ] レイアウト設定の外部化
- [ ] 色設定の外部化
- [ ] Git commit: "Add: Configuration file structure"

#### 2.2 設定読み込み機能（2時間）
- [ ] ConfigManager.ps1作成
- [ ] メイン処理に組み込み
- [ ] デフォルト値の設定
- [ ] Git commit: "Add: Configuration manager"

#### 2.3 ハードコードされた値を置き換え（3時間）
- [ ] パスの置き換え
- [ ] 座標値の置き換え
- [ ] 色定義の置き換え
- [ ] Git commit: "Refactor: Replace hardcoded values with config"

**成果物:**
- 環境に依存しない
- レイアウト変更が容易
- 他のPCでも動作可能

---

### 【フェーズ3】状態管理の改善（3日目）
**目的: グローバル変数の削減**

#### 3.1 ApplicationStateクラス作成（3時間）
- [ ] Core/ApplicationState.ps1作成
- [ ] カウンター類の統合
- [ ] 色定義の統合
- [ ] パネル参照の統合
- [ ] Git commit: "Add: ApplicationState class"

#### 3.2 段階的にグローバル変数を置き換え（4時間）
- [ ] 高頻度使用変数から順に置き換え
  - [ ] $global:ボタンカウンタ
  - [ ] $global:folderPath
  - [ ] $global:JSONPath
  - [ ] $global:レイヤー1-6
- [ ] 動作確認
- [ ] Git commit: "Refactor: Migrate global variables to ApplicationState"

**成果物:**
- 状態管理が整理される
- 変数の追跡が容易になる

---

### 【フェーズ4】巨大ファイルの分割（4-5日目）
**目的: コードの可読性とメンテナンス性向上**

#### 4.1 02_メインフォームUI_foam関数.ps1の分析（1時間）
- [ ] 責任範囲を特定
- [ ] 分割計画の作成

#### 4.2 機能ごとにファイル分割（6時間）
- [ ] UI/Components/ButtonFactory.ps1 (ボタン生成)
- [ ] UI/Events/DragDropHandler.ps1 (D&D処理)
- [ ] UI/Layout/LayoutManager.ps1 (レイアウト)
- [ ] UI/Rendering/ArrowRenderer.ps1 (矢印描画)
- [ ] UI/Validation/PlacementValidator.ps1 (配置検証)
- [ ] 各ファイルに適切な関数を移動
- [ ] 動作確認
- [ ] Git commit: "Refactor: Split large UI file into modules"

#### 4.3 他の大きいファイルの分割（4時間）
- [ ] 15_コードサブ_if文条件式作成.ps1 (939行) を分割
- [ ] 動作確認
- [ ] Git commit: "Refactor: Split condition builder file"

**成果物:**
- ファイルサイズが100-300行に収まる
- 機能が明確に分離される
- 複数人での作業が可能になる

---

### 【フェーズ5】依存関係の整理（6日目）
**目的: テスト可能な構造への変換**

#### 5.1 依存性注入の導入（4時間）
- [ ] サービスクラスの作成
  - [ ] Services/JSONService.ps1
  - [ ] Services/VariableService.ps1
  - [ ] Services/ExecutionService.ps1
- [ ] 依存性注入パターンの適用
- [ ] Git commit: "Refactor: Introduce dependency injection"

#### 5.2 モジュールローダーの改善（2時間）
- [ ] 明示的な依存関係の定義
- [ ] 読み込み順序の制御
- [ ] エラー処理の追加
- [ ] Git commit: "Improve: Module loading with explicit dependencies"

**成果物:**
- 各モジュールが独立して動作可能
- テストが書ける構造
- 再利用可能なコンポーネント

---

### 【フェーズ6】テストとドキュメント（7日目）
**目的: 品質保証と保守性の向上**

#### 6.1 基本的なテスト作成（3時間）
- [ ] Pesterのセットアップ
- [ ] 重要な関数のテスト作成
  - [ ] ApplicationState.Tests.ps1
  - [ ] JSONService.Tests.ps1
  - [ ] ButtonFactory.Tests.ps1
- [ ] Git commit: "Add: Basic unit tests"

#### 6.2 ドキュメント作成（3時間）
- [ ] README.md更新
- [ ] ARCHITECTURE.md作成
- [ ] 各関数にコメントベースヘルプ追加
- [ ] Git commit: "Add: Documentation"

**成果物:**
- テストによる品質保証
- 新しい開発者が参加しやすい
- メンテナンスが容易

---

## 最終的なディレクトリ構造

```
UIpowershell/
├── README.md                          # プロジェクト説明
├── ARCHITECTURE.md                    # アーキテクチャ説明
├── REFACTORING_PLAN.md               # このファイル
│
├── config/
│   └── settings.json                  # 設定ファイル
│
├── src/
│   ├── Core/
│   │   ├── ApplicationState.ps1      # 状態管理
│   │   ├── ConfigManager.ps1         # 設定管理
│   │   └── Logger.ps1                # ロギング
│   │
│   ├── UI/
│   │   ├── MainForm.ps1              # メインフォーム
│   │   ├── Components/
│   │   │   ├── ButtonFactory.ps1    # ボタン生成
│   │   │   ├── PanelManager.ps1     # パネル管理
│   │   │   └── LayerManager.ps1     # レイヤー管理
│   │   ├── Events/
│   │   │   ├── DragDropHandler.ps1  # ドラッグ&ドロップ
│   │   │   └── ClickHandler.ps1     # クリックイベント
│   │   ├── Layout/
│   │   │   └── LayoutManager.ps1    # レイアウト管理
│   │   ├── Rendering/
│   │   │   └── ArrowRenderer.ps1    # 矢印描画
│   │   └── Validation/
│   │       └── PlacementValidator.ps1 # 配置検証
│   │
│   ├── Services/
│   │   ├── JSONService.ps1           # JSON操作
│   │   ├── VariableService.ps1       # 変数管理
│   │   └── ExecutionService.ps1      # 実行管理
│   │
│   └── Actions/
│       ├── MouseActions.ps1          # マウス操作
│       ├── KeyboardActions.ps1       # キーボード操作
│       ├── ExcelActions.ps1          # Excel操作
│       └── ImageActions.ps1          # 画像処理
│
├── tests/
│   ├── Core/
│   │   ├── ApplicationState.Tests.ps1
│   │   └── Logger.Tests.ps1
│   ├── Services/
│   │   └── JSONService.Tests.ps1
│   └── UI/
│       └── ButtonFactory.Tests.ps1
│
└── legacy/                            # 元のファイル（参照用）
    ├── 01_メインフォーム_メイン.ps1
    ├── 02_メインフォームUI_foam関数.ps1
    └── ...

```

---

## リスク管理

### 各フェーズでのバックアップ
```powershell
# フェーズ完了ごとにGitタグを作成
git tag -a "phase1-complete" -m "Phase 1: Foundation complete"
git tag -a "phase2-complete" -m "Phase 2: Configuration externalization complete"
# ...
```

### ロールバック戦略
- 各フェーズは独立して動作する状態でコミット
- 問題が発生したら前のフェーズに戻れる
- 動作するバージョンを常に維持

### 動作確認チェックリスト
各フェーズ後に以下を確認：
- [ ] アプリケーションが起動する
- [ ] ボタンが作成できる
- [ ] ドラッグ&ドロップが動作する
- [ ] 変数管理が動作する
- [ ] コード生成が動作する
- [ ] 実行機能が動作する

---

## 代替案：最小限リファクタリング（2日版）

時間が限られている場合の最小限プラン：

### Day 1 (4時間)
- [x] 文字エンコーディング統一
- [x] ロギング追加
- [x] エラー処理追加
- [x] Git commit

### Day 2 (4時間)
- [x] 設定ファイル作成
- [x] ハードコードされたパスを置き換え
- [x] 基本的なドキュメント作成
- [x] Git commit

**成果:**
- 即座に安定性向上
- 問題の診断が容易に
- 他の環境でも動作可能

---

## 見積もり

| プラン | 期間 | 改善度 | リスク | 推奨度 |
|--------|------|--------|--------|--------|
| **一括リファクタリング** | 2-3日 | 100% | 🔴 高 | ❌ 非推奨 |
| **最小限(2日版)** | 2日 | 30% | 🟢 低 | ⭐⭐⭐ 推奨 |
| **段階的(7日版)** | 7日 | 80% | 🟡 中 | ⭐⭐⭐⭐⭐ 最推奨 |

---

## 次のステップ

どのアプローチで進めますか？

1. **最小限版（2日）**: すぐに効果が出る
2. **段階的版（7日）**: 根本的な改善
3. **カスタム**: 特定の問題だけに焦点を当てる

選択肢を教えていただければ、具体的な実装に入ります。
