# UIpowershell UI用語集

このドキュメントは、UIpowershellの画面構成要素とノードの種類を整理した用語集です。

## 目次

1. [画面全体構成](#画面全体構成)
2. [パネル詳細](#パネル詳細)
3. [ノードの種類](#ノードの種類)
4. [重要な概念と用語](#重要な概念と用語)
5. [用語対照表](#用語対照表)

---

## 画面全体構成

```
┌─────────────────────────────────────────────────────────────┐
│ ① ヘッダー (Header)                                         │
├──────┬──────────────────────────────────────────────────────┤
│      │ ② パンくずリスト (Breadcrumb)                        │
│      ├──────────────────────────────────────────────────────┤
│  ③  │                                                       │
│ 左   │         ⑤ メインレイヤーパネル                       │
│ パ   │         (Main Layer Panel)                           │
│ ネ   │                                                       │
│ ル   │  ④ 中央コンテナ                                      │
│      │  (Center Container)                                  │
│──────┤                                                       │
│      │                    ⑥ ドリルダウンパネル             │
│  ⑦  │                    (Drilldown Panel)                 │
│ 説明 │                    ※ピンクノード展開時のみ表示       │
│ パネル│                                                      │
├──────┴──────────────────────────────────────────────────────┤
│ ⑧ フッター (Footer / Hierarchy Path)                        │
└─────────────────────────────────────────────────────────────┘

その他の浮動要素:
  ⑨ ホバープレビュー (Hover Preview) - ピンクノードにマウスオーバーで表示
  ⑩ 右クリックメニュー (Context Menu) - ノード右クリックで表示
  ⑪ ESCキーヒント (Esc Hint) - ドリルダウン時に表示
  ⑫ レイヤー詳細モーダル (Layer Detail Modal) - ※現在は使用されていない
```

---

## パネル詳細

### ① ヘッダー (Header)
**HTML ID**: `#header`
**高さ**: 50px
**役割**: アプリケーションのメイン操作メニューとツールバーを提供

**構成要素**:
- **メニューバー** (`#menubar`):
  - UIpowershell（アプリ名とバージョン表示）
  - 実行 (`executeCode()`)
  - 変数 (`openVariableModal()`)
  - フォルダ作成 (`createFolder()`)
  - フォルダ切替 (`switchFolder()`)
  - 全削除 (`deleteAllNodes()`)
  - スナップショット (`createSnapshot()`)
  - 復元 (`restoreSnapshot()`)

- **ツールバー** (`#toolbar`):
  - 現在は空（将来的な拡張用）

---

### ② パンくずリスト (Breadcrumb Bar)
**HTML ID**: `#breadcrumb`
**CSS クラス**: `.breadcrumb-bar`
**位置**: 固定位置（left: 510px, top: 50px）
**役割**: 現在のレイヤー階層を縦展開で表示し、上位レイヤーへの移動を可能にする

**表示内容**:
- 📍 メインフロー（レイヤー1）
- ↓（セパレーター）
- 展開中のサブレイヤー名

**JavaScript変数**: `updateBreadcrumb()` で動的更新

**特徴**:
- 縦方向に展開（上から下へ）
- クリックで該当レイヤーに移動
- 現在のレイヤーは `.current` クラスで強調表示

---

### ③ 左パネル (Left Panel)
**HTML ID**: `#left-panel`
**幅**: 480px
**役割**: ノード追加用のカテゴリーとボタンを提供

**構成要素**:

#### カテゴリーボタン (`#category-buttons`)
10種類のカテゴリー切り替えボタン:
1. 制御構文（グレー）
2. マウス操作（ピンク系）
3. キーボード操作（緑系）
4. UIAutomation（緑系）
5. ファイル操作（黄色系）
6. データ処理（紫系）
7. スクリプト実行（グレー）
8. Excel処理（青系）
9. ウインドウ操作（黄色系）
10. 画像処理（ピンク系）

**JavaScript変数**: `currentCategory` (1-10)

#### ノード追加ボタンコンテナ (`#node-buttons-container`)
選択中のカテゴリーに応じたノード追加ボタンを2列グリッドで表示

**データソース**: `00_フォルダ/ボタン設定.json`

---

### ④ 中央コンテナ (Center Container)
**HTML ID**: `#center-container`
**役割**: メインレイヤーパネルとドリルダウンパネルを横並びで表示

---

### ⑤ メインレイヤーパネル (Main Layer Panel)
**HTML ID**: `#left-layer-panel`
**CSS クラス**: `.main-layer-panel`
**役割**: 現在のレイヤーのノードを表示

**構成**:
- レイヤー0～6の7つのレイヤーパネル（`.layer-panel`）
- 各レイヤーパネルには:
  - **レイヤーラベル** (`.layer-label`): "レイヤーN"
  - **ノードリストコンテナ** (`.node-list-container`): ノードが縦に並ぶ領域

**JavaScript変数**:
- `leftVisibleLayer`: 現在表示中のレイヤー番号（0-6）
- `layerStructure`: レイヤー階層構造データ

**表示制御**:
- 1つのレイヤーのみ `display: block` で表示
- 他のレイヤーは `display: none`

---

### ⑥ ドリルダウンパネル (Drilldown Panel)
**HTML ID**: `#right-layer-panel`
**CSS クラス**: `.drilldown-panel`
**役割**: ピンクノードをクリックした時に、その内部ノードを展開表示

**表示タイミング**:
- ピンクノード（スクリプト化されたノード）をクリック
- `pinkSelectionArray[layer].value = 1` の時に表示

**JavaScript変数**:
- `rightVisibleLayer`: ドリルダウンパネルで表示中のレイヤー番号
- `pinkSelectionArray`: 各レイヤーのピンクノード展開状態を管理
  - `expandedNode`: 展開中のピンクノードID
  - `value`: 1=展開中, 0=折りたたみ中
  - `yCoord`: ピンクノードのY座標
  - `initialY`: 初期Y座標

**特徴**:
- ピンクノードをクリックすると右側に展開
- ESCキーで折りたたみ可能
- `.empty` クラスで非表示状態を制御

**関連する視覚効果**:
- メインレイヤーパネルに `.dimmed` クラスが付与される（半透明化）
- グロー効果でピンクノードと展開先を強調

---

### ⑦ 説明パネル (Description Panel)
**HTML ID**: `#description-panel`
**位置**: 左下固定（左パネルの真下）
**役割**: ノードやUIの説明テキストを表示

**構成**:
- **パネルラベル**: "説明"
- **説明テキスト** (`#description-text`): 動的に更新される説明文

---

### ⑧ フッター (Footer / Hierarchy Path)
**HTML ID**: `#hierarchy-path`
**高さ**: 36px
**役割**: 現在の階層パスを表示

**表示内容**:
```
📍 階層パス: レイヤー1
```

**JavaScript**: `#path-text` の内容が動的に更新される

---

### ⑨ ホバープレビュー (Hover Preview)
**HTML ID**: `#hoverPreview`
**CSS クラス**: `.hover-preview`
**役割**: ピンクノードにマウスオーバーした時に、内部ノードのプレビューを表示

**表示タイミング**:
- ピンクノードに0.8秒以上ホバー
- ピンクノードがアクティブ（`pinkSelectionArray[layer].expandedNode === nodeId`）の場合のみ

**非表示タイミング**:
- マウスリーブ（`mouseleave`）
- ノードクリック

**構成**:
- **ヘッダー** (`.hover-preview-header`): 🔍 プレビュー
- **コンテンツ** (`.hover-preview-content`): 子ノードのリスト

**JavaScript関数**:
- `setupHoverPreview()`: 初期化
- `handlePinkNodeHover()`: ホバー処理
- `showPreview()`: 表示
- `hidePreview()`: 非表示

**重要な仕様**:
- **アクティブ状態チェックあり**: レイヤー編集後の古いピンクノードはプレビュー表示しない（ui/app-legacy.js:6190-6203）

---

### ⑩ 右クリックメニュー (Context Menu)
**HTML ID**: `#context-menu`
**CSS クラス**: `.context-menu`
**役割**: ノードを右クリックした時の操作メニュー

**メニュー項目**:
1. **レイヤー化** (`layerizeNode()`): 複数ノードをピンクノードにまとめる
   - 条件: 赤枠が付いたノードが複数ある場合のみ表示
   - 特別スタイル: ピンク背景、太字
2. **ノード設定** (`openNodeSettingsFromContextMenu()`): ノードのパラメータを編集
3. **名前変更** (`renameNode()`): ノード表示名を変更
4. **スクリプト編集** (`editScript()`): ノードのPowerShellコードを直接編集
5. **スクリプト実行** (`executeScript()`): ノード単体を実行
6. **赤枠トグル** (`toggleRedBorder()`): 赤枠の表示/非表示を切り替え
7. **赤枠グループ適用** (`applyRedBorderToGroup()`): グループ全体に赤枠を適用
8. **削除** (`deleteNode()`): ノードを削除

**表示制御**:
- `.show` クラスで表示
- `contextMenuTarget`: 右クリックされたノードへの参照

---

### ⑪ ESCキーヒント (Esc Hint)
**HTML ID**: `#escHint`
**CSS クラス**: `.esc-hint`
**位置**: 右下固定
**役割**: ドリルダウンパネル表示中にESCキーで戻れることを通知

**表示タイミング**:
- ドリルダウンパネル表示時

---

### ⑫ レイヤー詳細モーダル (Layer Detail Modal)
**HTML ID**: `#layer-detail-modal`
**CSS クラス**: `.modal-overlay`
**役割**: レイヤーの詳細を別ウィンドウで表示（現在はほぼ使用されていない）

**構成**:
- モーダルヘッダー
- モーダルコンテンツ
- ノードコンテナ
- Canvasでノード間矢印を描画

**JavaScript関数**:
- `showLayerDetailModal()`: 表示
- `closeLayerDetailModal()`: 閉じる

---

## ノードの種類

### ノードとは
**HTML要素**: `<div class="node-button">`
**配置**: `.node-list-container` 内に絶対配置 (`position: absolute`)
**サイズ**: 幅120px × 高さ40px（デフォルト）

### ノードの色分類

#### 1. 白ノード (White Node)
**色**: `rgb(255, 255, 255)` / `White`
**用途**: 標準的な処理ノード
**外観**: グレーのボーダー、Neumorphismシャドウ

#### 2. ピンクノード (Pink Node) ⭐重要⭐
**色**: `rgb(252, 160, 158)` / `Pink`
**用途**: **スクリプト化されたノード**（複数ノードをまとめたもの）
**外観**: 青系のボーダー、グローアニメーション効果
**特徴**:
- クリックするとドリルダウンパネルに内部ノードを展開
- ホバーでプレビュー表示（0.8秒後）
- 右横に矢印インジケーター表示（展開時）

**JavaScript**:
- `isPinkColor()`: ピンク色判定
- `pinkSelectionArray`: 展開状態管理

**メタ情報の保存形式**:
```
親ID;色;テキスト;
子ID1;色;テキスト;
子ID2;色;テキスト;
```

#### 3. 緑ノード (SpringGreen Node)
**色**: `rgb(0, 255, 127)` / `SpringGreen`
**用途**: 特定の操作（詳細はボタン設定.jsonによる）

#### 4. 黄色ノード (LemonChiffon Node)
**色**: `rgb(255, 250, 205)` / `LemonChiffon`
**用途**: 特定の操作

#### 5. サーモンノード (Salmon Node)
**色**: `rgb(250, 128, 114)` / `Salmon`
**用途**: 条件分岐の終了マーカー

#### 6. ライトブルーノード (LightBlue Node)
**色**: `rgb(200, 220, 255)` / `LightBlue`
**用途**: ループ終了マーカー

#### 7. グレーノード (Gray Node / Separator)
**色**: `rgb(128, 128, 128)` / `Gray`
**用途**: **区切り線**
**外観**: 高さ1px、ボーダーなし、青色の線
**特徴**: 視覚的な区切りとして機能

### ノードの状態

#### 赤枠 (Red Border)
**CSS クラス**: `.red-border`
**用途**: レイヤー化の対象ノードをマーキング
**設定方法**:
1. ノードを右クリック → "赤枠トグル"
2. ノードを Shift+クリック（範囲選択）
3. "赤枠グループ適用"（条件分岐/ループセット全体）

**レイヤー化の条件**:
- 同じレイヤー内に赤枠ノードが複数ある
- 赤枠ノードが連続している

#### ドラッグ中 (Dragging)
**CSS クラス**: `.dragging`
**外観**: 半透明、やや拡大、回転

#### ドラッグオーバー (Drag Over)
**CSS クラス**: `.drag-over`
**外観**: 上部に青いボーダー

---

## 重要な概念と用語

### レイヤー (Layer)
**定義**: ノードを階層的に管理するための階層レベル
**範囲**: レイヤー0～6（7階層）
**JavaScript変数**: `layerStructure`

**レイヤー構造の例**:
```
レイヤー1（メインフロー）
  └─ ピンクノードA
       └─ レイヤー2（ピンクノードAの内部）
            └─ ピンクノードB
                 └─ レイヤー3（ピンクノードBの内部）
                      └─ ...
```

### レイヤー化 / スクリプト化 (Layerize / Scripting)
**定義**: 複数のノードを1つのピンクノードにまとめる操作
**実行方法**:
1. 複数のノードに赤枠をつける
2. いずれかのノードを右クリック
3. "レイヤー化"を選択

**処理内容**:
1. 赤枠ノードを新しいレイヤー（`leftVisibleLayer + 1`）に移動
2. 元の位置にピンクノードを作成
3. ピンクノードの `script` フィールドにメタ情報を保存
4. `code.json` の `エントリ` にメタ情報を保存

**JavaScript関数**: `layerizeNode()` (ui/app-legacy.js:2789-2821)

### ドリルダウン (Drilldown)
**定義**: ピンクノードをクリックして内部のノードを右パネルに展開表示する操作
**反対操作**: ESCキーで折りたたみ

**JavaScript変数**:
- `pinkSelectionArray[layer].value = 1`: 展開中
- `pinkSelectionArray[layer].expandedNode`: 展開中のピンクノードID

### 展開 / 折りたたみ (Expand / Collapse)
- **展開**: ピンクノードクリック → ドリルダウンパネル表示
- **折りたたみ**: ESCキー → ドリルダウンパネル非表示

### 赤枠 (Red Border)
**定義**: ノードをレイヤー化の対象としてマークする視覚的な枠
**操作**:
- トグル: 右クリック → "赤枠トグル"
- 範囲選択: Shiftキー + ノードクリック
- グループ適用: 条件分岐/ループセット全体に適用

### グロー効果 (Glow Effect)
**定義**: ピンクノードや展開先レイヤーを光らせる視覚効果
**種類**:
1. **ピンクノードのグロー**: 常時アニメーション（`@keyframes pinkGlow`）
2. **ソースグロー**: 展開中のピンクノード（`.glow-source`）
3. **グロー矢印**: ピンクノード右横の矢印インジケーター（`.glow-arrow-indicator`）

**JavaScript**: `glowState`, `applyGlowEffects()`

### 矢印 (Arrows)
**種類**:
1. **ノード間矢印**: 同じパネル内のノード間を結ぶ下向き矢印
2. **パネル間矢印**: ピンクノード展開時の左→右パネルへの矢印
3. **条件分岐矢印**: 赤ノード（開始）→ サーモン（終了）
4. **ループ矢印**: 緑ノード（開始）→ ライトブルー（終了）

**Canvas描画**: 各 `.node-list-container` 内に `<canvas>` 要素

**JavaScript関数**:
- `drawPanelArrows()`: パネル内矢印
- `drawCrossPanelPinkArrows()`: パネル間矢印
- `drawConditionalBranchArrows()`: 条件分岐矢印
- `drawLoopArrows()`: ループ矢印

### 条件分岐セット (Condition Set)
**構成**:
- 開始ノード（赤ノード、SpringGreen系以外）
- 内部ノード（赤ノードまたはGrayノード）
- 終了ノード（サーモンノード）

**JavaScript**: `findConditionGroups()`, `findConditionSet()`

### ループセット (Loop Set)
**構成**:
- 開始ノード（緑ノード、SpringGreen）
- 内部ノード（SpringGreen または Grayノード）
- 終了ノード（ライトブルーノード）

**JavaScript**: `findLoopGroups()`, `findLoopSet()`

---

## 用語対照表

### 日本語 ⇔ 英語 ⇔ HTML/CSS/JS

| 日本語 | 英語 | HTML ID / CSS Class | JavaScript変数 |
|--------|------|---------------------|----------------|
| ヘッダー | Header | `#header` | - |
| メニューバー | Menubar | `#menubar` | - |
| ツールバー | Toolbar | `#toolbar` | - |
| パンくずリスト | Breadcrumb Bar | `#breadcrumb` / `.breadcrumb-bar` | `updateBreadcrumb()` |
| 左パネル | Left Panel | `#left-panel` | - |
| カテゴリーボタン | Category Buttons | `#category-buttons` | `currentCategory` |
| ノード追加ボタンコンテナ | Node Buttons Container | `#node-buttons-container` | - |
| カテゴリーパネル | Category Panel | `.category-panel` | - |
| 中央コンテナ | Center Container | `#center-container` | - |
| メインレイヤーパネル | Main Layer Panel | `#left-layer-panel` / `.main-layer-panel` | `leftVisibleLayer` |
| レイヤーパネル | Layer Panel | `.layer-panel` / `#layer-N` | - |
| レイヤーラベル | Layer Label | `.layer-label` | - |
| ノードリストコンテナ | Node List Container | `.node-list-container` | - |
| ドリルダウンパネル | Drilldown Panel | `#right-layer-panel` / `.drilldown-panel` | `rightVisibleLayer` |
| 説明パネル | Description Panel | `#description-panel` | - |
| フッター | Footer / Hierarchy Path | `#hierarchy-path` | - |
| ホバープレビュー | Hover Preview | `#hoverPreview` / `.hover-preview` | `showPreview()`, `hidePreview()` |
| 右クリックメニュー | Context Menu | `#context-menu` / `.context-menu` | `contextMenuTarget` |
| ESCキーヒント | Esc Hint | `#escHint` / `.esc-hint` | - |
| レイヤー詳細モーダル | Layer Detail Modal | `#layer-detail-modal` / `.modal-overlay` | `layerPopups`, `layerPopupData` |
| ノード | Node | `.node-button` | `nodes[]` |
| 白ノード | White Node | - | `isWhiteColor()` |
| ピンクノード | Pink Node | - | `isPinkColor()`, `pinkSelectionArray` |
| 緑ノード | SpringGreen Node | - | `isSpringGreenColor()` |
| 黄色ノード | LemonChiffon Node | - | `isLemonChiffonColor()` |
| サーモンノード | Salmon Node | - | `isSalmonColor()` |
| ライトブルーノード | LightBlue Node | - | `isBlueColor()` |
| グレーノード（区切り線） | Gray Node (Separator) | - | `isGrayColor()` |
| レイヤー | Layer | - | `layerStructure` |
| レイヤー化 / スクリプト化 | Layerize / Scripting | - | `layerizeNode()` |
| ドリルダウン | Drilldown | - | - |
| 展開 / 折りたたみ | Expand / Collapse | - | `pinkSelectionArray[].value` |
| 赤枠 | Red Border | `.red-border` | `node.redBorder` |
| グロー効果 | Glow Effect | `.glow-source`, `.glow-arrow-indicator` | `glowState`, `applyGlowEffects()` |
| 矢印 | Arrows | `<canvas>` | `drawPanelArrows()` など |
| 条件分岐セット | Condition Set | - | `findConditionGroups()` |
| ループセット | Loop Set | - | `findLoopGroups()` |

---

## よくある混同の防止

### ❌ 混同しやすい用語

1. **ホバープレビュー vs ドリルダウンパネル**
   - **ホバープレビュー**: ピンクノードにマウスを0.8秒ホバーで表示される浮動プレビュー
   - **ドリルダウンパネル**: ピンクノードをクリックで右側に展開される固定パネル

2. **レイヤー化 vs スクリプト化**
   - 同じ意味。ユーザーは「スクリプト化」と呼ぶことが多い
   - コード内では `layerizeNode()` という関数名

3. **メインレイヤーパネル vs 左パネル**
   - **左パネル**: カテゴリーボタンとノード追加ボタンのあるパネル（左端）
   - **メインレイヤーパネル**: ノードが配置されるメインのパネル（中央左側）

4. **右パネル vs ドリルダウンパネル**
   - 旧名称「右パネル（right-layer-panel）」は「ドリルダウンパネル」に改名された
   - コード内では両方の名前が混在している

---

## ファイル参照

- **HTML構造**: `ui/index-legacy.html`
- **CSS スタイル**: `ui/style-legacy.css`
- **JavaScript ロジック**: `ui/app-legacy.js`
- **ノードボタン設定**: `00_フォルダ/ボタン設定.json`
- **コードデータ**: `03_history/{フォルダ名}/コード.json`

---

**作成日**: 2025-11-15
**バージョン**: 1.0.236
