# UIサイズ調整ガイド

UIpowershell のUIサイズを調整する際の参照資料です。
各UI要素のサイズ設定箇所をまとめています。

---

## 🏗️ アーキテクチャ概要

このプロジェクトは**段階的な移行**を実施中で、以下の3つのフェーズで構成されています：

```
┌─────────────────────────────────────────────┐
│ Phase 4: HTML/JS Web UI (レガシー)         │
│ - /ui/index-legacy.html                    │
│ - /ui/app-legacy.js (270KB)                │
│ - /ui/style-legacy.css (32KB)              │
└─────────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────────┐
│ Phase 3: Adapter Layer (REST API Bridge)   │
│ - adapter/api-server-v2.ps1 (26エンドポイント)│
│ - Polaris HTTP Server でブラウザ ↔ PowerShell橋渡し│
└─────────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────────┐
│ Phase 2: PowerShell Windows Forms          │
│ - 13_コードサブ汎用関数.ps1 (1498行)      │
│ - モーダル・ダイアログをPowerShell Forms化 │
└─────────────────────────────────────────────┘
```

**最近の移行状況**（2025-11-15）:
- ✅ **コード結果モーダル** → PowerShell Windows Forms化完了
- ✅ **フォルダ管理モーダル** → PowerShell Windows Forms化完了
- ✅ **変数管理モーダル** → PowerShell Windows Forms化完了

---

## 📁 対象ファイル

### レガシーWeb UI（段階的に縮小中）
- **`/ui/style-legacy.css`** - 全てのUIサイズ定義（メイン）
- `/ui/index-legacy.html` - HTML構造（一部インラインスタイル）
- `/ui/app-legacy.js` - JavaScript（動的サイズ計算）

### PowerShell Windows Forms（移行先）
- **`13_コードサブ汎用関数.ps1`** - 全てのダイアログ・モーダル定義（メイン）⭐
- `adapter/api-server-v2.ps1` - REST API エンドポイント
- `07_ツールバー作成_v2.ps1` - ノード追加・フォルダ管理
- `08_メインボタン処理_v2.ps1` - コード生成・実行
- `10_変数機能_変数管理UI_v2.ps1` - 変数管理機能

**注意**:
- レガシーWeb UIは `/ui/style-legacy.css` で管理
- PowerShell Windows Formsは `13_コードサブ汎用関数.ps1` で管理

---

## 🎨 UI要素別サイズ調整一覧

### 1️⃣ ヘッダー（上部メニューバー）

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `#header` | `height` | `50px` | `style-legacy.css` | 88 | ヘッダー全体の高さ |
| `#menubar` | `height` | `50px` | `style-legacy.css` | 126 | メニューバー高さ |
| `#menubar` | `gap` | `8px` | `style-legacy.css` | 128 | メニュー項目間の間隔 |
| `#menubar` | `padding` | `0 10px` | `style-legacy.css` | 129 | 左右の余白 |
| `.menu-item` | `height` | `36px` | `style-legacy.css` | 134 | メニューボタン高さ |
| `.menu-item` | `padding` | `0 18px` | `style-legacy.css` | 133 | メニューボタン左右余白 |
| `.menu-item` | `font-size` | `13px` | `style-legacy.css` | 139 | メニューボタン文字サイズ |
| `.menu-item` | `border-radius` | `12px` | `style-legacy.css` | 140 | メニューボタン角丸 |
| `#toolbar` | `height` | `50px` | `style-legacy.css` | 161 | ツールバー高さ |
| `#toolbar` | `gap` | `10px` | `style-legacy.css` | 158 | ツールバーボタン間隔 |
| `#toolbar button` | `height` | `32px` | `style-legacy.css` | 169 | ツールバーボタン高さ |
| `#toolbar button` | `padding` | `0 16px` | `style-legacy.css` | 165 | ツールバーボタン左右余白 |
| `#toolbar button` | `font-size` | `12px` | `style-legacy.css` | 168 | ツールバーボタン文字サイズ |
| `#current-layer-label` | `font-size` | `13px` | `style-legacy.css` | 202 | レイヤーラベル文字サイズ |
| `#current-layer-label` | `padding` | `6px 16px` | `style-legacy.css` | 205 | レイヤーラベル余白 |

### 2️⃣ パンくずリスト（縦展開・固定配置・透明化）

**🆕 2025-11-14更新**: パンくずリストが縦展開でレイヤー1左側に固定配置されるように変更されました。
**🆕 2025-11-14更新**: パンくずリストパネルを透明化し、複数行表示に対応しました。

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `.breadcrumb-bar` | `position` | `fixed` | `style-legacy.css` | 895 | **固定配置** ⭐重要 |
| `.breadcrumb-bar` | `left` | `640px` | `style-legacy.css` | 896 | **左端位置**（レイヤー1左側の200pxスペース内） |
| `.breadcrumb-bar` | `top` | `50px` | `style-legacy.css` | 897 | 上端位置（ヘッダー直下） |
| `.breadcrumb-bar` | `width` | `180px` | `style-legacy.css` | 898 | パンくずリスト幅 |
| `.breadcrumb-bar` | `max-height` | `calc(100vh - 50px - 36px - 20px)` | `style-legacy.css` | 899 | 最大高さ（上下余白確保） |
| `.breadcrumb-bar` | `background` | `transparent` | `style-legacy.css` | 900 | **背景透明** ⭐視覚的に目立たなくする |
| `.breadcrumb-bar` | `flex-direction` | `column` | `style-legacy.css` | 902 | **縦展開** ⭐重要 |
| `.breadcrumb-bar` | `padding` | `16px 10px` | `style-legacy.css` | 904 | 上下・左右余白 |
| `.breadcrumb-bar` | `gap` | `8px` | `style-legacy.css` | 905 | 項目間の縦間隔 |
| `.breadcrumb-bar` | `border-radius` | `16px` | `style-legacy.css` | 907 | 角丸 |
| `.breadcrumb-bar` | `box-shadow` | `none` | `style-legacy.css` | 908 | **影なし** ⭐視覚的に目立たなくする |
| `.breadcrumb-item` | `width` | `100%` | `style-legacy.css` | 913 | **幅いっぱい** |
| `.breadcrumb-item` | `padding` | `8px 12px` | `style-legacy.css` | 919 | パンくず項目の余白 |
| `.breadcrumb-item` | `font-size` | `12px` | `style-legacy.css` | 926 | パンくず項目の文字サイズ |
| `.breadcrumb-item` | `border-radius` | `8px` | `style-legacy.css` | 920 | パンくず項目の角丸 |
| `.breadcrumb-item` | `white-space` | `normal` | `style-legacy.css` | 927 | **複数行表示** ⭐テキスト折り返し許可 |
| `.breadcrumb-item` | `overflow` | `visible` | `style-legacy.css` | 928 | オーバーフロー表示 |
| `.breadcrumb-item` | `word-break` | `break-word` | `style-legacy.css` | 929 | **長い単語を折り返し** |
| `.breadcrumb-item` | `height` | `auto` | `style-legacy.css` | 930 | **高さ自動調整** |
| `.breadcrumb-item` | `min-height` | `28px` | `style-legacy.css` | 931 | 最小高さ確保 |
| `.breadcrumb-separator` | `width` | `100%` | `style-legacy.css` | 940 | セパレーター幅 |
| `.breadcrumb-separator` | `text-align` | `center` | `style-legacy.css` | 941 | セパレーター中央揃え |
| `.breadcrumb-separator` | `font-size` | `14px` | `style-legacy.css` | 944 | セパレーター文字サイズ（↓） |
| `.breadcrumb-separator` | `margin` | `-4px 0` | `style-legacy.css` | 945 | セパレーター間隔調整 |

**計算式の意味**:
- `left: 640px` = main-container(12px) + left-panel(605px) + gap(12px) + 余白(11px)
- `max-height: calc(100vh - 106px)` = 画面高さ - ヘッダー(50px) - フッター(36px) - 上下余白(20px)

**デザイン意図**:
- パンくずリストパネル自体を透明化（background: transparent, box-shadow: none）して視覚的に目立たなくする
- 個別のパンくず項目（.breadcrumb-item）はニューモーフィズムスタイルを維持して視認性を確保
- 長いテキストは複数行で表示され、省略記号（...）は表示されない

### 3️⃣ メインコンテナ（全体レイアウト）

**🆕 2025-11-14更新**: パンくずリストが固定配置になったため、レイアウト調整が行われました。

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `#main-container` | `height` | `calc(100vh - 78px + 40px)` | `style-legacy.css` | 216 | メインエリア高さ ⭐重要 |
| `#main-container` | `margin-top` | `-40px` | `style-legacy.css` | 221 | **上マージン（パンくずリストの元スペースを埋める）** ⭐重要 |
| `#main-container` | `padding` | `12px` | `style-legacy.css` | 219 | メインエリア内側余白 |
| `#main-container` | `gap` | `12px` | `style-legacy.css` | 220 | 左パネルと中央コンテナの間隔 |

**計算式の意味**:
- `100vh` = ブラウザ画面の高さ100%
- `calc(100vh - 78px + 40px)` = ヘッダー(50px) + 旧パンくずリスト(40px)を考慮し、パンくずリスト分(40px)を戻す
- `margin-top: -40px` = パンくずリストがfixed配置になったため、元の40pxスペースを上に詰める

### 4️⃣ 左パネル（操作パネル）

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `#left-panel` | `width` | `605px` | `style-legacy.css` | 225 | **左パネル全体の幅** ⭐重要 |
| `#left-panel` | `max-height` | `calc(100vh - 78px - 280px)` | `style-legacy.css` | 226 | 左パネル最大高さ |
| `#left-panel` | `padding` | `16px` | `style-legacy.css` | 229 | 左パネル内側余白 |
| `#left-panel` | `gap` | `12px` | `style-legacy.css` | 232 | カテゴリーボタンとノードコンテナの間隔 |
| `#left-panel` | `border-radius` | `20px` | `style-legacy.css` | 228 | 左パネル角丸 |

**計算式の意味**:
- `280px` = 説明パネル用のスペース確保

#### 4-1. カテゴリーボタンエリア

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `#category-buttons` | `width` | `140px` | `style-legacy.css` | 241 | カテゴリーボタン列の幅 |
| `#category-buttons` | `gap` | `8px` | `style-legacy.css` | 244 | ボタン間の縦間隔 |
| `#category-buttons` | `padding-right` | `8px` | `style-legacy.css` | 247 | 右側余白（スクロールバー用） |
| `.category-btn` | `width` | `130px` | `style-legacy.css` | 269 | **カテゴリーボタン1個の幅** |
| `.category-btn` | `height` | `32px` | `style-legacy.css` | 270 | **カテゴリーボタン1個の高さ** |
| `.category-btn` | `font-size` | `11px` | `style-legacy.css` | 273 | ボタン文字サイズ |
| `.category-btn` | `padding-left` | `12px` | `style-legacy.css` | 275 | ボタン左余白 |
| `.category-btn` | `border-radius` | `10px` | `style-legacy.css` | 276 | ボタン角丸 |

#### 4-2. ノードボタンコンテナ（追加用ノード一覧）

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `#node-buttons-container` | `width` | `407px` | `style-legacy.css` | 295 | **ノードコンテナ全体の幅** ⭐重要 |
| `#node-buttons-container` | `padding` | `12px` | `style-legacy.css` | 299 | 内側余白 |
| `#node-buttons-container` | `border-radius` | `12px` | `style-legacy.css` | 300 | 角丸 |
| `.category-panel.active` | `grid-template-columns` | `repeat(2, minmax(0, 1fr))` | `style-legacy.css` | 313 | 2列グリッド表示 |
| `.category-panel.active` | `gap` | `10px` | `style-legacy.css` | 314 | グリッド項目間の間隔 |
| `.add-node-btn` | `height` | `36px` | `style-legacy.css` | 324 | **追加ノードボタン高さ** |
| `.add-node-btn` | `font-size` | `11px` | `style-legacy.css` | 328 | ボタン文字サイズ |
| `.add-node-btn` | `padding-left` | `12px` | `style-legacy.css` | 330 | ボタン左余白 |
| `.add-node-btn` | `border-radius` | `12px` | `style-legacy.css` | 326 | ボタン角丸 |

**幅の関係**:
```
左パネル全体: 605px
  = カテゴリーボタン: 140px
  + ノードコンテナ: 407px
  + 内側余白: 16px × 2 = 32px
  + gap: 12px
  + 誤差調整: 14px
```

### 5️⃣ 中央コンテナ（レイヤーパネル）

**🆕 2025-11-14更新**: レイヤー1パネルを200px右に移動するため、左paddingを調整しました。

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `#center-container` | `flex` | `1` | `style-legacy.css` | 355 | 残りスペース全て使用 |
| `#center-container` | `min-width` | `640px` | `style-legacy.css` | 356 | 最小幅 |
| `#center-container` | `padding` | `16px 16px 16px 216px` | `style-legacy.css` | 365 | **内側余白（左側200px追加）** ⭐重要 |
| `#center-container` | `gap` | `12px` | `style-legacy.css` | 364 | レイヤーパネル間の間隔 |
| `#center-container` | `border-radius` | `20px` | `style-legacy.css` | 363 | 角丸 |

**計算式の意味**:
- `padding: 16px 16px 16px 216px` = 上(16px) 右(16px) 下(16px) 左(216px)
- 左側padding: `216px` = 元の16px + 200px（パンくずリスト配置スペース）

#### 5-1. レイヤーパネル

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `.dual-layer-panel` | `width` | `300px` | `style-legacy.css` | 372 | デュアルレイヤーパネル幅 |
| `.layer-panel` | `width` | `300px` | `style-legacy.css` | 379 | **レイヤーパネル1個の幅** ⭐重要 |
| `.layer-panel` | `border-radius` | `16px` | `style-legacy.css` | 381 | レイヤーパネル角丸 |
| `.layer-label` | `height` | `36px` | `style-legacy.css` | 406 | レイヤーラベル高さ |
| `.layer-label` | `padding` | `10px` | `style-legacy.css` | 401 | レイヤーラベル余白 |
| `.layer-label` | `font-size` | `12px` | `style-legacy.css` | 404 | レイヤーラベル文字サイズ |
| `.layer-label` | `border-radius` | `16px 16px 0 0` | `style-legacy.css` | 410 | レイヤーラベル角丸（上のみ） |
| `.node-list-container` | `min-height` | `700px` | `style-legacy.css` | 419 | **ノードリスト最小高さ** |
| `.node-list-container` | `padding` | `16px` | `style-legacy.css` | 418 | ノードリスト内側余白 |

### 6️⃣ ノードボタン（配置済みノード）

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `.node-button` | `width` | `120px` | `style-legacy.css` | 428 | **ノードボタン幅** ⭐重要 |
| `.node-button` | `height` | `40px` | `style-legacy.css` | 429 | **ノードボタン高さ** ⭐重要 |
| `.node-button` | `font-size` | `11px` | `style-legacy.css` | 434 | ノードボタン文字サイズ |
| `.node-button` | `padding-left` | `12px` | `style-legacy.css` | 436 | ノードボタン左余白 |
| `.node-button` | `border-radius` | `12px` | `style-legacy.css` | 432 | ノードボタン角丸 |
| `.node-button` | `border` | `2px solid transparent` | `style-legacy.css` | 430 | ノードボタンボーダー |

**特殊ノード**:
- グレーノード（区切り線）: `height: 1px !important` (行510)

#### 6-1. グローアロー（ピンクノード用）

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `.glow-arrow-indicator` | `font-size` | `24px` | `style-legacy.css` | 704 | グロー矢印アイコンサイズ |
| `.glow-arrow-indicator` | `z-index` | `200` | `style-legacy.css` | 707 | 表示優先度 |

### 7️⃣ 説明パネル（左下固定）

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `#description-panel` | `width` | `605px` | `style-legacy.css` | 574 | **説明パネル幅**（左パネルと同じ） |
| `#description-panel` | `max-height` | `500px` | `style-legacy.css` | 575 | **説明パネル最大高さ** ⭐重要 |
| `#description-panel` | `padding` | `16px` | `style-legacy.css` | 578 | 内側余白 |
| `#description-panel` | `border-radius` | `16px` | `style-legacy.css` | 577 | 角丸 |
| `#description-panel` | `top` | `calc(100vh - 296px)` | `style-legacy.css` | 572 | **上端位置**（左パネルの真下） ⭐重要 |
| `#description-panel` | `left` | `16px` | `style-legacy.css` | 573 | 左端位置 |
| `#description-text` | `font-size` | `12px` | `style-legacy.css` | 587 | 説明文字サイズ |
| `#description-text` | `line-height` | `1.6` | `style-legacy.css` | 588 | 行間 |

**計算式の意味**:
```
top: calc(100vh - 296px)
  = 画面高さ100% - 296px（ヘッダー50px + パンくずリスト40px + 左パネルmax-height計算分）
```

**幅の関係**:
```
説明パネル幅: 605px = 左パネル幅と同じ
```

### 8️⃣ フッター（階層パス）

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `#hierarchy-path` | `height` | `36px` | `style-legacy.css` | 594 | フッター高さ |
| `#hierarchy-path` | `padding` | `0 16px` | `style-legacy.css` | 596 | 左右余白 |
| `#hierarchy-path` | `font-size` | `12px` | `style-legacy.css` | 599 | 文字サイズ |

### 9️⃣ スクロールバー

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `::-webkit-scrollbar` | `width` | `8px` | `style-legacy.css` | 252 | スクロールバー幅 |
| `::-webkit-scrollbar-track` | `border-radius` | `10px` | `style-legacy.css` | 257 | スクロールバートラック角丸 |
| `::-webkit-scrollbar-thumb` | `border-radius` | `10px` | `style-legacy.css` | 265 | スクロールバーつまみ角丸 |

### 🔟 モーダル（ダイアログ）

#### 10-1. 一般モーダル

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `.modal-content` | `width` | `600px` | `style-legacy.css` | 765 | **モーダル幅** |
| `.modal-content` | `max-height` | `80vh` | `style-legacy.css` | 766 | モーダル最大高さ（画面の80%） |
| `.modal-content` | `padding` | `24px` | `style-legacy.css` | 763 | モーダル内側余白 |
| `.modal-content` | `border-radius` | `20px` | `style-legacy.css` | 764 | モーダル角丸 |
| `.modal-close` | `width` | `32px` | `style-legacy.css` | 781 | 閉じるボタン幅 |
| `.modal-close` | `height` | `32px` | `style-legacy.css` | 782 | 閉じるボタン高さ |
| `.modal-close` | `font-size` | `18px` | `style-legacy.css` | 785 | 閉じるボタン文字サイズ |

#### 10-2. レイヤー詳細モーダル

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `.modal-container` | `width` | `90%` | `style-legacy.css` | 1187 | **レイヤーモーダル幅**（画面の90%） |
| `.modal-container` | `max-width` | `700px` | `style-legacy.css` | 1188 | レイヤーモーダル最大幅 |
| `.modal-container` | `height` | `85vh` | `style-legacy.css` | 1189 | レイヤーモーダル高さ（画面の85%） |
| `.modal-container` | `border-radius` | `20px` | `style-legacy.css` | 1190 | レイヤーモーダル角丸 |
| `.modal-header` | `padding` | `20px 25px` | `style-legacy.css` | 1217 | ヘッダー余白 |
| `.modal-title` | `font-size` | `18px` | `style-legacy.css` | 1226 | タイトル文字サイズ |
| `.modal-title` | `gap` | `12px` | `style-legacy.css` | 1225 | タイトル要素間隔 |
| `.modal-icon` | `font-size` | `24px` | `style-legacy.css` | 1232 | アイコンサイズ |
| `.modal-parent-badge` | `font-size` | `12px` | `style-legacy.css` | 1236 | 親ノードバッジ文字サイズ |
| `.modal-parent-badge` | `padding` | `4px 12px` | `style-legacy.css` | 1237 | 親ノードバッジ余白 |
| `.modal-close-btn` | `width` | `36px` | `style-legacy.css` | 1247 | 閉じるボタン幅 |
| `.modal-close-btn` | `height` | `36px` | `style-legacy.css` | 1248 | 閉じるボタン高さ |
| `.modal-close-btn` | `font-size` | `20px` | `style-legacy.css` | 1250 | 閉じるボタン文字サイズ |
| `.modal-node-container` | `min-height` | `500px` | `style-legacy.css` | 1292 | モーダル内ノードコンテナ最小高さ |
| `.modal-node-container` | `padding` | `10px` | `style-legacy.css` | 1295 | モーダル内ノードコンテナ余白 |

#### 10-3. スクリプト編集モーダル（HTMLインライン）

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `#script-modal .modal-content` | `width` | `80%` | `index-legacy.html` | 213 | スクリプトモーダル幅 |
| `#script-modal .modal-content` | `max-width` | `800px` | `index-legacy.html` | 213 | スクリプトモーダル最大幅 |
| `#script-editor` | `rows` | `20` | `index-legacy.html` | 217 | スクリプトエディタ行数 |
| `#script-editor` | `font-size` | `14px` | `index-legacy.html` | 217 | スクリプトエディタ文字サイズ |

#### 10-4. ノード設定モーダル（HTMLインライン）

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `#node-settings-modal .modal-content` | `width` | `70%` | `index-legacy.html` | 228 | ノード設定モーダル幅 |
| `#node-settings-modal .modal-content` | `max-width` | `700px` | `index-legacy.html` | 228 | ノード設定モーダル最大幅 |
| `#settings-node-script` | `rows` | `10` | `index-legacy.html` | 280 | スクリプトテキストエリア行数 |
| `#settings-node-script` | `font-size` | `12px` | `index-legacy.html` | 280 | スクリプトテキストエリア文字サイズ |

#### 10-5. コード生成結果モーダル（HTMLインライン）

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `#code-result-modal .modal-content` | `width` | `80%` | `index-legacy.html` | 293 | コード結果モーダル幅 |
| `#code-result-modal .modal-content` | `max-width` | `900px` | `index-legacy.html` | 293 | コード結果モーダル最大幅 |
| `#code-result-preview` | `rows` | `20` | `index-legacy.html` | 303 | コードプレビューエリア行数 |
| `#code-result-preview` | `font-size` | `12px` | `index-legacy.html` | 303 | コードプレビューエリア文字サイズ |

#### 10-6. 条件分岐モーダル（HTMLインライン）

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `#condition-builder-modal .modal-content` | `width` | `900px` | `index-legacy.html` | 317 | 条件分岐モーダル幅 |
| `#condition-builder-modal .modal-content` | `max-height` | `80vh` | `index-legacy.html` | 317 | 条件分岐モーダル最大高さ |
| `#condition-preview` | `height` | `120px` | `index-legacy.html` | 328 | 条件プレビューエリア高さ |

#### 10-7. ループモーダル（HTMLインライン）

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `#loop-builder-modal .modal-content` | `width` | `700px` | `index-legacy.html` | 342 | ループモーダル幅 |
| `#loop-builder-modal .modal-content` | `max-height` | `80vh` | `index-legacy.html` | 342 | ループモーダル最大高さ |
| `#loop-preview` | `height` | `120px` | `index-legacy.html` | 360 | ループプレビューエリア高さ |

### 1️⃣1️⃣ 右クリックメニュー

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `.context-menu` | `border-radius` | `12px` | `style-legacy.css` | 631 | 右クリックメニュー角丸 |
| `.context-menu-item` | `padding` | `12px 24px` | `style-legacy.css` | 644 | メニュー項目余白 |
| `.context-menu-item` | `font-size` | `13px` | `style-legacy.css` | 646 | メニュー項目文字サイズ |

### 1️⃣2️⃣ テーブル（変数一覧など）

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `table` | `border-radius` | `12px` | `style-legacy.css` | 799 | テーブル角丸 |
| `th, td` | `padding` | `10px` | `style-legacy.css` | 808 | セル余白 |
| `th, td` | `font-size` | `12px` | `style-legacy.css` | 810 | セル文字サイズ |

### 1️⃣3️⃣ フォーム要素（入力欄）

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `input, textarea, select` | `padding` | `10px` | `style-legacy.css` | 826 | 入力欄余白 |
| `input, textarea, select` | `font-size` | `14px` | `style-legacy.css` | 831 | 入力欄文字サイズ |
| `input, textarea, select` | `border-radius` | `8px` | `style-legacy.css` | 829 | 入力欄角丸 |
| `button, .button` | `padding` | `10px 20px` | `style-legacy.css` | 849 | ボタン余白 |
| `button, .button` | `font-size` | `14px` | `style-legacy.css` | 854 | ボタン文字サイズ |
| `button, .button` | `border-radius` | `10px` | `style-legacy.css` | 852 | ボタン角丸 |

### 1️⃣4️⃣ ホバープレビュー

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `.hover-preview` | `padding` | `15px` | `style-legacy.css` | 1015 | ホバープレビュー余白 |
| `.hover-preview` | `border-radius` | `12px` | `style-legacy.css` | 1014 | ホバープレビュー角丸 |
| `.hover-preview` | `min-width` | `250px` | `style-legacy.css` | 1021 | ホバープレビュー最小幅 |
| `.hover-preview` | `max-width` | `350px` | `style-legacy.css` | 1022 | ホバープレビュー最大幅 |
| `.hover-preview-header` | `font-size` | `13px` | `style-legacy.css` | 1040 | ホバープレビューヘッダー文字サイズ |
| `.hover-preview-header` | `padding-bottom` | `8px` | `style-legacy.css` | 1038 | ホバープレビューヘッダー下余白 |
| `.hover-preview-content` | `font-size` | `12px` | `style-legacy.css` | 1047 | ホバープレビュー本文文字サイズ |
| `.hover-preview-content` | `line-height` | `1.6` | `style-legacy.css` | 1048 | ホバープレビュー本文行間 |

### 1️⃣5️⃣ ESCキーヒント

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `.esc-hint` | `padding` | `10px 20px` | `style-legacy.css` | 1074 | ESCヒント余白 |
| `.esc-hint` | `border-radius` | `20px` | `style-legacy.css` | 1075 | ESCヒント角丸 |
| `.esc-hint` | `font-size` | `12px` | `style-legacy.css` | 1076 | ESCヒント文字サイズ |
| `.esc-hint` | `bottom` | `20px` | `style-legacy.css` | 1072 | 画面下端からの距離 |
| `.esc-hint` | `right` | `20px` | `style-legacy.css` | 1073 | 画面右端からの距離 |

### 1️⃣6️⃣ レイヤーインジケーター

| UI要素 | プロパティ | 現在値 | ファイル | 行番号 | 説明 |
|--------|------------|--------|----------|--------|------|
| `.layer-indicator` | `padding` | `4px 12px` | `style-legacy.css` | 1097 | レイヤーインジケーター余白 |
| `.layer-indicator` | `border-radius` | `12px` | `style-legacy.css` | 1098 | レイヤーインジケーター角丸 |
| `.layer-indicator` | `font-size` | `11px` | `style-legacy.css` | 1099 | レイヤーインジケーター文字サイズ |
| `.layer-indicator` | `top` | `10px` | `style-legacy.css` | 1093 | 上端からの距離 |
| `.layer-indicator` | `right` | `10px` | `style-legacy.css` | 1094 | 右端からの距離 |

---

## 🎯 よくあるサイズ調整パターン

### パターン1: 左パネル全体を拡大（1.2倍）

左パネル関連のサイズを一括で1.2倍にする場合：

| 対象 | 変更前 | 変更後 | 計算 |
|------|--------|--------|------|
| `#left-panel` width | `605px` | `726px` | 605 × 1.2 |
| `#category-buttons` width | `140px` | `168px` | 140 × 1.2 |
| `.category-btn` width | `130px` | `156px` | 130 × 1.2 |
| `.category-btn` height | `32px` | `38px` | 32 × 1.2 |
| `#node-buttons-container` width | `407px` | `488px` | 407 × 1.2 |
| `.add-node-btn` height | `36px` | `43px` | 36 × 1.2 |
| `#description-panel` width | `605px` | `726px` | 605 × 1.2 |

**注意**: 左パネルと説明パネルの幅は常に一致させる必要があります。

### パターン2: ノードボタンを大きく（視認性向上）

配置済みノードボタンを大きくする場合：

| 対象 | 変更前 | 変更後 | 用途 |
|------|--------|--------|------|
| `.node-button` width | `120px` | `180px` | 長いテキストを表示 |
| `.node-button` height | `40px` | `60px` | タッチ操作向け |
| `.node-button` font-size | `11px` | `14px` | 文字を見やすく |

### パターン3: レイヤーパネルを広く（ノード配置スペース確保）

レイヤーパネルの作業スペースを広げる場合：

| 対象 | 変更前 | 変更後 | 用途 |
|------|--------|--------|------|
| `.layer-panel` width | `300px` | `400px` | パネル幅拡大 |
| `.node-list-container` min-height | `700px` | `1000px` | 縦方向拡大 |

### パターン4: 説明パネルの高さ調整

説明パネルの表示領域を変更する場合：

| 対象 | 変更前 | 変更後 | 用途 |
|------|--------|--------|------|
| `#description-panel` max-height | `500px` | `600px` | より多くの説明を表示 |
| `#description-panel` top | `calc(100vh - 296px)` | `calc(100vh - 396px)` | topも調整が必要 |
| `#left-panel` max-height | `calc(100vh - 78px - 280px)` | `calc(100vh - 78px - 380px)` | 左パネルも調整 |

**重要**: 説明パネルのtop位置は、左パネルのmax-heightと連動します。

---

## ⚠️ 重要な注意事項

### 1. 連動して調整が必要な箇所

以下のサイズは**連動**しているため、同時に調整する必要があります：

#### ✅ 左パネルと説明パネルの幅
```css
/* 常に同じ値にする */
#left-panel { width: 605px; }
#description-panel { width: 605px; }
```

#### ✅ 左パネルの高さと説明パネルの位置
```css
/* 左パネル最大高さ */
#left-panel { max-height: calc(100vh - 78px - 280px); }

/* 説明パネル上端位置（左パネルの真下） */
#description-panel { top: calc(100vh - 296px); }
```

**計算式の関係**:
- 説明パネルのtop = `100vh - (左パネルmax-heightの280px + ヘッダー50px + パンくずリスト40px - 余白調整74px)`
- 簡易計算: `top = 100vh - (280 + 16)` = `100vh - 296px`

#### ✅ カテゴリーボタン列とノードコンテナの幅
```css
/* 左パネル全体幅 = カテゴリーボタン + ノードコンテナ + 余白 + gap */
#left-panel { width: 605px; }
#category-buttons { width: 140px; }
#node-buttons-container { width: 407px; }
/* padding: 16px × 2 = 32px, gap: 12px */
/* 合計: 140 + 407 + 32 + 12 + 調整14px = 605px */
```

#### ✅ メインコンテナの高さ
```css
/* ヘッダー(50px) + パンくずリスト(40px) = 90px */
/* 重複部分があるため78pxで計算 */
#main-container { height: calc(100vh - 78px); }
```

### 2. ブラウザキャッシュのクリア

CSSファイルを変更した後は、**必ずブラウザキャッシュをクリア**してください：

- **Chrome**: Ctrl + Shift + R (Windows) / Cmd + Shift + R (Mac)
- **Firefox**: Ctrl + F5 (Windows) / Cmd + Shift + R (Mac)
- **Edge**: Ctrl + F5

または、`style-legacy.css`のバージョンパラメータを更新：
```html
<!-- index-legacy.html 7行目 -->
<link rel="stylesheet" href="style-legacy.css?v=1.0.201">
                                                     ↑ この数値を変更
```

### 3. レスポンシブ対応

現在のUIは**固定幅レイアウト**です。
以下の最小画面サイズを想定しています：

- **最小画面幅**: 約1440px（左パネル605px + 中央コンテナ640px + 余白・gap）
- **最小画面高さ**: 約800px

**それ以下の画面サイズでは**:
- 横スクロールバーが表示される
- レイアウトが崩れる可能性がある

### 4. パフォーマンスへの影響

以下のサイズ変更はパフォーマンスに影響する可能性があります：

#### 🐢 重い操作
- `.node-list-container` の `min-height` を大きくする（矢印描画Canvas増大）
- `.layer-panel` の `width` を大きくする（レンダリング負荷増）
- ノード数が100個以上の場合の `font-size` 拡大

#### ✅ 軽い操作
- ヘッダー、フッターのサイズ変更
- ボタンの `border-radius` 変更
- `padding`, `margin` の微調整

### 5. 既知の制約

以下の制約があります：

1. **左パネルと説明パネルの幅は固定**（flexで可変にしていない）
2. **レイヤーパネルの幅は300px固定**（複数レイヤー表示のため）
3. **ノードボタンの位置は絶対座標**（`position: absolute`）で管理

---

## 📊 全体レイアウト構成図

```
┌──────────────────────────────────────────────────────────────┐
│ #header (50px高さ)                                            │
│ ├─ #menubar (gap: 8px)                                        │
│ │  └─ .menu-item (36px高さ)                                   │
│ └─ #toolbar (gap: 10px)                                       │
│    └─ button (32px高さ)                                       │
├──────────────────────────────────────────────────────────────┤
│ #main-container (margin-top: -40px, padding: 12px, gap: 12px)│
│ ┌────────────────────┬──┬────────────────────────────────────┤
│ │ #left-panel        │🆕│ #center-container (flex: 1)        │
│ │ (605px幅)          │パ│ (padding-left: 216px)              │
│ │ ┌────────┬───────┐ │ン│ ┌──────────┬────────────────────┐ │
│ │ │category│ node  │ │く│ │ layer-1  │ drilldown-panel    │ │
│ │ │buttons │buttons│ │ず│ │ (300px)  │ (動的幅)            │ │
│ │ │(140px) │(407px)│ │ │ │          │                    │ │
│ │ │        │       │ │📍│ │ .node-   │                    │ │
│ │ │        │       │ │メ│ │ button   │                    │ │
│ │ │        │       │ │イ│ │ 120×40px │                    │ │
│ │ │        │       │ │ン│ │          │ ← 200px右に移動   │ │
│ │ │        │       │ │ │ │          │                    │ │
│ │ │        │       │ │↓│ │          │                    │ │
│ │ │        │       │ │階│ │          │                    │ │
│ │ │        │       │ │層│ │          │                    │ │
│ │ └────────┴───────┘ │ 2│ └──────────┴────────────────────┘ │
│ └────────────────────┴──┴────────────────────────────────────┤
│ #description-panel (605px幅, max-height: 500px)               │
│ (left: 16px, top: calc(100vh - 296px))                        │
├──────────────────────────────────────────────────────────────┤
│ #hierarchy-path (36px高さ)                                    │
└──────────────────────────────────────────────────────────────┘

🆕 パンくずリスト (.breadcrumb-bar)
   - position: fixed
   - left: 640px (レイヤー1左側の200pxスペース内)
   - width: 180px
   - 縦展開 (flex-direction: column)
```

---

## 🔧 クイックリファレンス

### 最も頻繁に調整する項目TOP5

| 順位 | UI要素 | プロパティ | 行番号 | 理由 |
|------|--------|------------|--------|------|
| 1 | `.node-button` | `width`, `height` | 428-429 | ノードサイズ調整 |
| 2 | `#left-panel` | `width` | 225 | 左パネル全体幅 |
| 3 | `#description-panel` | `max-height` | 575 | 説明表示領域 |
| 4 | `.layer-panel` | `width` | 379 | レイヤーパネル幅 |
| 5 | `.node-list-container` | `min-height` | 419 | ノード配置スペース |

---

## 🖥️ PowerShell Windows Forms（新規）

### 概要

PowerShell Windows Formsベースのモーダル・ダイアログは、`13_コードサブ汎用関数.ps1` (1498行) に集約されています。
全てのダイアログは `System.Windows.Forms` を使用してネイティブWindowsフォームとして表示されます。

**主要なダイアログ関数**:
- `コード結果を表示` (行1309) - コード生成結果表示
- `フォルダ切替を表示` (行1077) - フォルダ切替・新規作成
- `変数管理を表示` (行666) - 変数一覧・CRUD操作
- `Show-AddVariableDialog` (行876) - 変数追加
- `Show-EditVariableDialog` (行972) - 変数編集
- `リストから項目を選択` (行4) - 汎用リスト選択
- `文字列を入力` (行82) - 汎用文字列入力
- `複数行テキストを編集` (行319) - 汎用テキストエディタ
- `ノード設定を編集` (行389) - ノード詳細設定

---

### 1️⃣7️⃣ コード結果モーダル（PowerShell Forms）⭐ 2025-11-15移行

**ファイル**: `13_コードサブ汎用関数.ps1:1309`
**関数**: `コード結果を表示`

| UI要素 | プロパティ | 現在値 | 行番号 | 説明 |
|--------|------------|--------|--------|------|
| `$フォーム` | `Size` | `900, 700` | 1340 | **フォーム全体サイズ（幅x高さ）** ⭐重要 |
| `$フォーム` | `MinimumSize` | `700, 500` | 1343 | **最小サイズ（リサイズ対応）** ⭐重要 |
| `$フォーム` | `FormBorderStyle` | `Sizable` | 1342 | リサイズ可能 |
| `$フォーム` | `StartPosition` | `CenterScreen` | 1341 | 画面中央に表示 |
| `$パネル_情報` | `Location` | `20, 20` | 1347 | 情報パネル位置 |
| `$パネル_情報` | `Size` | `840, 100` | 1348 | **情報パネルサイズ** |
| `$パネル_情報` | `BackColor` | `RGB(232,245,233)` | 1350 | 淡い緑色背景 |
| `$ラベル_ノード数` | `Location` | `15, 15` | 1356 | ノード数ラベル位置 |
| `$ラベル_ノード数` | `Font` | `メイリオ, 10pt` | 1358 | フォント |
| `$ラベル_出力先` | `Location` | `15, 40` | 1365 | 出力先ラベル位置 |
| `$ラベル_出力先` | `Size` | `800, 20` | 1366 | ラベルサイズ |
| `$ラベル_時刻` | `Location` | `15, 65` | 1374 | 生成時刻ラベル位置 |
| `$ラベル_コード` | `Location` | `20, 135` | 1382 | コードプレビューラベル位置 |
| `$ラベル_コード` | `Font` | `メイリオ, 10pt, Bold` | 1384 | フォント（太字） |
| `$テキスト_コード` | `Location` | `20, 160` | 1389 | **コードプレビュー位置** |
| `$テキスト_コード` | `Size` | `840, 430` | 1390 | **コードプレビューサイズ** ⭐重要 |
| `$テキスト_コード` | `Font` | `Consolas, 10pt` | 1394 | **等幅フォント** |
| `$テキスト_コード` | `BackColor` | `RGB(245,245,245)` | 1395 | 背景色（ライトグレー） |
| `$テキスト_コード` | `ScrollBars` | `Both` | 1393 | 縦横スクロール対応 |
| `$テキスト_コード` | `WordWrap` | `false` | 1397 | ワードラップ無効 |
| `$ボタン_コピー` | `Location` | `20, 600` | 1418 | コピーボタン位置 |
| `$ボタン_コピー` | `Size` | `130, 35` | 1419 | コピーボタンサイズ |
| `$ボタン_ファイル開く` | `Location` | `160, 600` | 1425 | ファイル開くボタン位置 |
| `$ボタン_ファイル開く` | `Size` | `150, 35` | 1426 | ファイル開くボタンサイズ |
| `$ボタン_閉じる` | `Location` | `760, 600` | 1437 | 閉じるボタン位置 |
| `$ボタン_閉じる` | `Size` | `100, 35` | 1438 | 閉じるボタンサイズ |

**リサイズイベント処理**（行1401-1413）:
```powershell
# ウィンドウリサイズ時に以下を動的調整:
- $パネル_情報.Width = $newWidth (フォーム幅 - 40)
- $テキスト_コード.Size = $newWidth x ($newHeight - 70)
- ボタンY座標 = $フォーム高さ - 50
- $ボタン_閉じる.X座標 = $フォーム幅 - 120
```

**機能**:
- ✅ クリップボードコピー（Clipboard.SetText）
- ✅ ファイル開く（Start-Process）
- ✅ リサイズ対応（Add_Resize イベント）

---

### 1️⃣8️⃣ フォルダ切替モーダル（PowerShell Forms）⭐ 2025-11-15移行

**ファイル**: `13_コードサブ汎用関数.ps1:1077`
**関数**: `フォルダ切替を表示`

| UI要素 | プロパティ | 現在値 | 行番号 | 説明 |
|--------|------------|--------|--------|------|
| `$フォーム` | `Size` | `500, 450` | 1114 | **フォーム全体サイズ（幅x高さ）** ⭐重要 |
| `$フォーム` | `FormBorderStyle` | `FixedDialog` | 1116 | 固定サイズ（リサイズ不可） |
| `$フォーム` | `MaximizeBox` | `false` | 1117 | 最大化ボタン無効 |
| `$フォーム` | `StartPosition` | `CenterScreen` | 1115 | 画面中央に表示 |
| `$ラベル_説明` | `Location` | `20, 20` | 1122 | 説明ラベル位置 |
| `$ラベル_現在` | `Location` | `20, 45` | 1130 | 現在フォルダラベル位置 |
| `$ラベル_現在` | `ForeColor` | `Blue` | 1132 | **青色で強調** |
| `$リストボックス` | `Location` | `20, 75` | 1138 | **リストボックス位置** |
| `$リストボックス` | `Size` | `440, 250` | 1139 | **リストボックスサイズ** ⭐重要 |
| `$リストボックス` | `Font` | `Consolas, 10pt` | 1140 | 等幅フォント |
| `$ボタン_選択` | `Location` | `20, 345` | 1162 | 選択ボタン位置 |
| `$ボタン_選択` | `Size` | `100, 35` | 1163 | 選択ボタンサイズ |
| `$ボタン_新規作成` | `Location` | `130, 345` | 1169 | 新規作成ボタン位置 |
| `$ボタン_新規作成` | `Size` | `100, 35` | 1170 | 新規作成ボタンサイズ |
| `$ボタン_キャンセル` | `Location` | `360, 345` | 1176 | キャンセルボタン位置 |
| `$ボタン_キャンセル` | `Size` | `100, 35` | 1177 | キャンセルボタンサイズ |

**新規フォルダ作成サブダイアログ**（行1201-1237）:

| UI要素 | プロパティ | 現在値 | 行番号 | 説明 |
|--------|------------|--------|--------|------|
| `$入力フォーム` | `Size` | `400, 150` | 1203 | サブフォームサイズ |
| `$入力フォーム` | `FormBorderStyle` | `FixedDialog` | 1205 | 固定サイズ |
| `$入力フォーム` | `StartPosition` | `CenterParent` | 1204 | 親フォーム中央 |
| `$ラベル` | `Location` | `20, 20` | 1211 | ラベル位置 |
| `$テキストボックス` | `Location` | `20, 50` | 1216 | テキストボックス位置 |
| `$テキストボックス` | `Size` | `340, 20` | 1217 | テキストボックスサイズ |
| `$ボタン_OK` | `Location` | `200, 80` | 1222 | 作成ボタン位置 |
| `$ボタン_OK` | `Size` | `75, 25` | 1223 | 作成ボタンサイズ |
| `$ボタン_キャンセル2` | `Location` | `285, 80` | 1229 | キャンセルボタン位置 |
| `$ボタン_キャンセル2` | `Size` | `75, 25` | 1230 | キャンセルボタンサイズ |

**機能**:
- ✅ フォルダ一覧表示（ListBox）
- ✅ 現在フォルダを青色でハイライト
- ✅ ダブルクリックで選択（Add_DoubleClick）
- ✅ 新規フォルダ作成（サブダイアログ）
- ✅ 重複チェック・バリデーション

---

### 1️⃣9️⃣ 汎用ダイアログ（PowerShell Forms）

#### 19-1. リスト選択ダイアログ

**ファイル**: `13_コードサブ汎用関数.ps1:4`
**関数**: `リストから項目を選択`

| UI要素 | プロパティ | 現在値 | 行番号 | 説明 |
|--------|------------|--------|--------|------|
| `$フォーム` | `Size` | `400, 200` | 21 | フォームサイズ |
| `$ラベル` | `Location` | `10, 20` | 28 | ラベル位置 |
| `$コンボボックス` | `Location` | `10, 50` | 33 | コンボボックス位置 |
| `$コンボボックス` | `Size` | `360, 20` | 34 | コンボボックスサイズ |
| `$OKボタン` | `Location` | `220, 100` | 45 | OKボタン位置 |
| `$OKボタン` | `Size` | `75, 23` | 44 | OKボタンサイズ |
| `$キャンセルボタン` | `Location` | `300, 100` | 54 | キャンセルボタン位置 |
| `$キャンセルボタン` | `Size` | `75, 23` | 53 | キャンセルボタンサイズ |

#### 19-2. 文字列入力ダイアログ

**ファイル**: `13_コードサブ汎用関数.ps1:82`
**関数**: `文字列を入力`

| UI要素 | プロパティ | 現在値 | 行番号 | 説明 |
|--------|------------|--------|--------|------|
| `$フォーム` | `Size` | `400, 250` | 96 | フォームサイズ（変数ボタン対応のため高め） |
| `$ラベル` | `Location` | `10, 20` | - | ラベル位置 |
| `$テキストボックス` | `Location` | `10, 50` | - | テキストボックス位置 |
| `$テキストボックス` | `Size` | `360, 20` | - | テキストボックスサイズ |

**特徴**: 「変数を使用」ボタンで変数挿入可能

---

### 🔧 PowerShell Formsのサイズ調整方法

#### 基本パターン

```powershell
# 1. フォームサイズ変更
$フォーム.Size = New-Object System.Drawing.Size(幅, 高さ)

# 2. コントロール位置変更
$コントロール.Location = New-Object System.Drawing.Point(X座標, Y座標)

# 3. コントロールサイズ変更
$コントロール.Size = New-Object System.Drawing.Size(幅, 高さ)

# 4. フォント変更
$コントロール.Font = New-Object System.Drawing.Font("フォント名", サイズ, [スタイル])
```

#### リサイズ対応の実装

```powershell
# フォーム設定
$フォーム.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
$フォーム.MinimumSize = New-Object System.Drawing.Size(最小幅, 最小高さ)

# リサイズイベント
$フォーム.Add_Resize({
    $newWidth = $フォーム.ClientSize.Width - マージン
    $newHeight = $フォーム.ClientSize.Height - マージン
    # コントロールサイズ・位置を動的調整
})
```

#### よくある調整パターン

| 調整内容 | 変更箇所 | 例 |
|---------|---------|-----|
| モーダル全体を拡大 | `$フォーム.Size` | `(900, 700)` → `(1200, 900)` |
| 最小サイズ変更 | `$フォーム.MinimumSize` | `(700, 500)` → `(800, 600)` |
| テキストボックス拡大 | `$テキスト.Size` | `(840, 430)` → `(1000, 600)` |
| フォントサイズ変更 | `Font` | `Consolas, 10pt` → `Consolas, 12pt` |
| ボタン位置調整 | `Location` | `(20, 600)` → `(20, 800)` |

**重要な注意事項**:
- PowerShell Formsは絶対座標（Point）でレイアウト管理
- リサイズ対応する場合は `Add_Resize` イベントを実装
- `StartPosition = "CenterScreen"` で画面中央配置
- `FormBorderStyle::FixedDialog` で固定サイズ、`Sizable` でリサイズ可能

---

## 📝 変更履歴

| 日付 | 変更内容 | 理由 |
|------|----------|------|
| 2025-11-15 | **PowerShell Windows Formsセクション追加** | コード結果・フォルダ管理モーダルの移行完了に伴い、ガイド更新 |
| 2025-11-15 | **アーキテクチャ概要セクション追加** | 段階的移行の全体像を説明 |
| 2025-11-15 | コード結果モーダルをPowerShell Windows Formsに移行 | リサイズ対応・UX改善 |
| 2025-11-15 | フォルダ管理モーダルをPowerShell Windows Formsに移行 | ネイティブUIでの操作性向上 |
| 2025-11-15 | 変数管理モーダルをPowerShell Windows Formsに移行 | CRUD操作の一貫性向上 |
| 2025-11-14 | **パンくずリストパネルを透明化、複数行表示対応** | 視覚的に目立たなくしつつ、長いテキストを表示可能に |
| 2025-11-14 | `.breadcrumb-bar` を background: transparent、box-shadow: none に変更 | パンくずリストパネルを視覚的に隠す |
| 2025-11-14 | `.breadcrumb-item` を white-space: normal、height: auto に変更 | 複数行表示対応、省略記号（...）を排除 |
| 2025-11-14 | **パンくずリストを縦展開で固定配置に変更** | レイヤー1左側の200pxスペースに配置、視認性向上 |
| 2025-11-14 | **レイヤー1パネルを200px右に移動** | パンくずリスト配置スペース確保 |
| 2025-11-14 | `#center-container` padding-leftを216pxに変更 | レイヤー1パネル移動に伴う調整 |
| 2025-11-14 | `#main-container` margin-topを-40pxに設定 | パンくずリスト固定配置に伴うスペース調整 |
| 2025-11-09 | 左パネル幅を550px→605pxに変更（1.1倍） | UI拡大対応 |
| 2025-11-09 | ノードボタン幅を280px→120pxに変更 | コンパクト化 |
| 2025-11-09 | 説明パネルmax-heightを600px→500pxに変更 | レイアウト最適化 |

---

## 💡 補足資料

### CSS変数（カラーパレット）

サイズ調整には直接関係ありませんが、デザイン統一のためにCSS変数が定義されています：

```css
:root {
    /* Neumorphism Base Colors */
    --bg-color: #e0e5ec;
    --shadow-light: #ffffff;
    --shadow-dark: #a3b1c6;

    /* Aurora Gradient Colors */
    --aurora-purple: #667eea;
    --aurora-pink: #f472b6;
    /* ... 他8色 */
}
```

これらはサイズ調整時に**変更不要**です。

---

**作成日**: 2025-11-14
**対象バージョン**: UIpowershell v1.0.235
**最終更新**: 2025-11-15

**主要変更** (2025-11-15):
- PowerShell Windows Formsセクション追加（セクション17-19）
- アーキテクチャ概要セクション追加
- コード結果モーダル、フォルダ管理モーダルのサイズ設定ガイド追加
- 段階的移行の全体像を文書化
