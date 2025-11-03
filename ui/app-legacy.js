// ============================================
// UIpowershell - Legacy UI JavaScript
// 既存Windows Forms版の完全再現
// ============================================

const API_BASE = 'http://localhost:8080/api';

// ============================================
// グローバル状態
// ============================================

let currentLayer = 1;           // 現在の左パネルレイヤー (0-6)
let leftVisibleLayer = 1;       // 左パネルに表示中のレイヤー
let rightVisibleLayer = 2;      // 右パネルに表示中のレイヤー
let currentCategory = 1;        // 現在選択中のカテゴリー (1-10)
let nodes = [];                 // 全ノード配列（全レイヤー）
let buttonSettings = [];        // ボタン設定.jsonのデータ
let variables = {};             // 変数データ
let folders = [];               // フォルダ一覧
let currentFolder = null;       // 現在のフォルダ
let contextMenuTarget = null;   // 右クリックメニューの対象ノード
let draggedNode = null;         // ドラッグ中のノード
let layerStructure = {          // レイヤー構造
    0: { visible: false, nodes: [] },
    1: { visible: true, nodes: [] },
    2: { visible: false, nodes: [] },
    3: { visible: false, nodes: [] },
    4: { visible: false, nodes: [] },
    5: { visible: false, nodes: [] },
    6: { visible: false, nodes: [] }
};

// ノードカウンター（ID生成用）
let nodeCounter = 1;

// GroupIDカウンター（オリジナルPowerShellと同じ仕様）
let loopGroupCounter = 1000;      // ループ用（1000番台）
let conditionGroupCounter = 2000; // 条件分岐用（2000番台）

// 右ペイン状態
let rightPanelCollapsed = false;

// Pink選択配列（スクリプト展開状態管理）- PowerShell互換
// レイヤー0-6までの展開状態を管理
let pinkSelectionArray = [];
for (let i = 0; i <= 6; i++) {
    pinkSelectionArray.push({
        layer: i,
        yCoord: 0,          // ピンクノードのY座標
        value: 0,           // 1=展開中, 0=折りたたみ中
        initialY: 0,        // 初期Y座標
        expandedNode: null  // 展開中のピンクノードID
    });
}

// コード.json管理（スクリプト内容）
let codeData = {
    "エントリ": {},
    "最後のID": 0
};

// ================================================================
// arrow-drawing.js
// 矢印描画機能（PS1からの移植）
// ================================================================

// グローバル変数
const arrowState = {
    pinkSelected: false,
    selectedPinkButton: null,
    canvasMap: new Map() // layerId -> canvas element
};

// Canvas要素を各レイヤーパネルに追加
function initializeArrowCanvas() {
    console.log('[矢印] initializeArrowCanvas() 開始');
    let createdCanvasCount = 0;

    // 左パネルの各レイヤーにcanvas要素を追加
    for (let i = 0; i <= 6; i++) {
        const layerPanel = document.getElementById(`layer-${i}`);
        if (layerPanel) {
            const nodeList = layerPanel.querySelector('.node-list-container');
            if (nodeList) {
                // Canvas要素を作成
                const canvas = document.createElement('canvas');
                canvas.className = 'arrow-canvas';
                canvas.style.position = 'absolute';
                canvas.style.top = '0';
                canvas.style.left = '0';
                canvas.style.pointerEvents = 'none'; // クリックイベントを透過
                canvas.style.zIndex = '1'; // ノードの上に表示

                // node-list-containerを相対配置に（Canvasを追加する前に設定）
                nodeList.style.position = 'relative';

                console.log(`[初期化] layer-${i} Canvas作成前の親要素:`, {
                    scrollWidth: nodeList.scrollWidth,
                    scrollHeight: nodeList.scrollHeight,
                    clientWidth: nodeList.clientWidth,
                    clientHeight: nodeList.clientHeight,
                    offsetWidth: nodeList.offsetWidth,
                    offsetHeight: nodeList.offsetHeight
                });

                // Canvasサイズを親要素に合わせる（内部描画サイズのみ設定、CSSで表示サイズは100%）
                // 親要素のサイズが0の場合はデフォルト値を使用
                const parentWidth = nodeList.clientWidth || nodeList.offsetWidth || 299;
                const parentHeight = nodeList.clientHeight || nodeList.offsetHeight || 700;
                canvas.width = parentWidth;
                canvas.height = parentHeight;

                // 🔥 修正: CSS表示サイズを明示的に設定（矢印表示に必須）
                canvas.style.width = parentWidth + 'px';
                canvas.style.height = parentHeight + 'px';

                nodeList.appendChild(canvas);

                console.log(`[初期化] layer-${i} Canvas作成後:`, {
                    canvasWidth: canvas.width,
                    canvasHeight: canvas.height,
                    canvasStyleWidth: canvas.style.width,
                    canvasStyleHeight: canvas.style.height,
                    canvasOffsetWidth: canvas.offsetWidth,
                    canvasOffsetHeight: canvas.offsetHeight,
                    canvasParent: canvas.parentElement,
                    canvasInDOM: document.body.contains(canvas)
                });

                arrowState.canvasMap.set(`layer-${i}`, canvas);
                createdCanvasCount++;
                console.log(`[矢印] Canvas作成: layer-${i} (${canvas.width}x${canvas.height})`);
            } else {
                console.warn(`[矢印] .node-list-containerが見つかりません: layer-${i}`);
            }
        } else {
            console.warn(`[矢印] レイヤーパネルが見つかりません: layer-${i}`);
        }
    }

    // 右パネルの各レイヤーにcanvas要素を追加
    for (let i = 0; i <= 6; i++) {
        const layerPanel = document.getElementById(`layer-${i}-right`);
        if (layerPanel) {
            const nodeList = layerPanel.querySelector('.node-list-container');
            if (nodeList) {
                // Canvas要素を作成
                const canvas = document.createElement('canvas');
                canvas.className = 'arrow-canvas';
                canvas.style.position = 'absolute';
                canvas.style.top = '0';
                canvas.style.left = '0';
                canvas.style.pointerEvents = 'none';
                canvas.style.zIndex = '1';

                nodeList.style.position = 'relative';

                const parentWidth = nodeList.clientWidth || nodeList.offsetWidth || 299;
                const parentHeight = nodeList.clientHeight || nodeList.offsetHeight || 700;
                canvas.width = parentWidth;
                canvas.height = parentHeight;
                canvas.style.width = parentWidth + 'px';
                canvas.style.height = parentHeight + 'px';

                nodeList.appendChild(canvas);

                arrowState.canvasMap.set(`layer-${i}-right`, canvas);
                createdCanvasCount++;
                console.log(`[矢印] Canvas作成: layer-${i}-right (${canvas.width}x${canvas.height})`);
            } else {
                console.warn(`[矢印] .node-list-containerが見つかりません: layer-${i}-right`);
            }
        } else {
            console.warn(`[矢印] レイヤーパネルが見つかりません: layer-${i}-right`);
        }
    }

    // メインコンテナにもcanvas追加（パネル間矢印用）
    const mainContainer = document.getElementById('main-container');
    if (mainContainer) {
        const canvas = document.createElement('canvas');
        canvas.id = 'main-arrow-canvas';
        canvas.style.position = 'absolute';
        canvas.style.top = '0';
        canvas.style.left = '0';
        canvas.style.pointerEvents = 'none';
        canvas.style.zIndex = '10';

        mainContainer.style.position = 'relative';

        // Canvasサイズを親要素に合わせる（内部描画サイズのみ設定、CSSで表示サイズは100%）
        const parentWidth = Math.max(mainContainer.clientWidth, mainContainer.scrollWidth, 1440);
        const parentHeight = Math.max(mainContainer.clientHeight, mainContainer.scrollHeight, 1200);
        canvas.width = parentWidth;
        canvas.height = parentHeight;

        // 🔥 修正: CSS表示サイズを明示的に設定（矢印表示に必須）
        canvas.style.width = parentWidth + 'px';
        canvas.style.height = parentHeight + 'px';

        mainContainer.appendChild(canvas);

        arrowState.canvasMap.set('main', canvas);
        createdCanvasCount++;
        console.log(`[矢印] Canvas作成: main (${canvas.width}x${canvas.height})`);
    } else {
        console.warn(`[矢印] main-containerが見つかりません`);
    }

    console.log(`[矢印] initializeArrowCanvas() 完了: ${createdCanvasCount}個のCanvasを作成`);
}

// 矢印ヘッドを描画するヘルパー関数
function drawArrowHead(ctx, fromX, fromY, toX, toY, arrowSize = 7, arrowAngle = 45) {
    const dx = toX - fromX;
    const dy = toY - fromY;
    const length = Math.sqrt(dx * dx + dy * dy);

    if (length === 0) return;

    // 単位ベクトル
    const ux = dx / length;
    const uy = dy / length;

    // 矢印ヘッドの角度をラジアンに変換
    const angleRad = Math.PI * arrowAngle / 180.0;

    // 矢印ヘッドの2つのポイント
    const sin = Math.sin(angleRad);
    const cos = Math.cos(angleRad);

    const point1X = Math.round(toX - arrowSize * (cos * ux + sin * uy));
    const point1Y = Math.round(toY - arrowSize * (cos * uy - sin * ux));
    const point2X = Math.round(toX - arrowSize * (cos * ux - sin * uy));
    const point2Y = Math.round(toY - arrowSize * (cos * uy + sin * ux));

    // 矢印ヘッドを描画
    ctx.beginPath();
    ctx.moveTo(toX, toY);
    ctx.lineTo(point1X, point1Y);
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(toX, toY);
    ctx.lineTo(point2X, point2Y);
    ctx.stroke();
}

// 基本的な下向き矢印を描画（白→白のノード間）
function drawDownArrow(ctx, fromNode, toNode, color = '#000000') {
    const fromRect = fromNode.getBoundingClientRect();
    const toRect = toNode.getBoundingClientRect();
    const containerRect = fromNode.closest('.node-list-container').getBoundingClientRect();

    // 相対座標に変換
    const startX = fromRect.left + fromRect.width / 2 - containerRect.left;
    const startY = fromRect.bottom - containerRect.top;
    const endX = toRect.left + toRect.width / 2 - containerRect.left;
    const endY = toRect.top - containerRect.top;

    // 詳細デバッグログ
    console.log(`[座標デバッグ] fromRect:`, {
        left: fromRect.left,
        right: fromRect.right,
        top: fromRect.top,
        bottom: fromRect.bottom,
        width: fromRect.width,
        height: fromRect.height
    });
    console.log(`[座標デバッグ] toRect:`, {
        left: toRect.left,
        right: toRect.right,
        top: toRect.top,
        bottom: toRect.bottom,
        width: toRect.width,
        height: toRect.height
    });
    console.log(`[座標デバッグ] containerRect:`, {
        left: containerRect.left,
        top: containerRect.top,
        width: containerRect.width,
        height: containerRect.height
    });
    console.log(`[座標デバッグ] 計算された矢印座標: (${startX}, ${startY}) → (${endX}, ${endY}), color=${color}`);
    console.log(`[座標デバッグ] Canvas dimensions: ${ctx.canvas.width} x ${ctx.canvas.height}`);

    // 線を描画
    ctx.strokeStyle = color;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(startX, startY);
    ctx.lineTo(endX, endY);
    ctx.stroke();

    console.log(`[座標デバッグ] stroke() 実行完了`);

    // Canvas画像データを確認（実際に描画されたか検証）
    try {
        const imageData = ctx.getImageData(Math.floor(startX), Math.floor(startY), 1, 1);
        const pixel = imageData.data;
        console.log(`[描画検証] startX位置のピクセル: rgba(${pixel[0]}, ${pixel[1]}, ${pixel[2]}, ${pixel[3]})`);
    } catch (e) {
        console.error(`[描画検証] getImageData失敗:`, e);
    }

    // 矢印ヘッドを描画
    drawArrowHead(ctx, startX, startY, endX, endY);
}

// パネル内のノード間矢印を描画
// パネル間矢印を描画（ピンクノード展開時）
function drawCrossPanelPinkArrows() {
    if (!arrowState.pinkSelected) {
        return; // ピンク選択中でない場合は何もしない
    }

    console.log('[パネル間矢印] ピンク選択中のため、パネル間矢印を描画します');

    // 左パネルのcanvasを取得
    const leftCanvas = arrowState.canvasMap.get(`layer-${leftVisibleLayer}`);
    if (!leftCanvas) {
        console.warn(`[パネル間矢印] 左パネルのcanvasが見つかりません: layer-${leftVisibleLayer}`);
        return;
    }

    // 左パネルのコンテナを取得
    const leftContainer = document.querySelector(`#layer-${leftVisibleLayer} .node-list-container`);
    if (!leftContainer) {
        console.warn(`[パネル間矢印] 左パネルのコンテナが見つかりません`);
        return;
    }

    // 左パネルのピンクノードを検索
    const leftNodes = leftContainer.querySelectorAll('.node-button');
    const pinkNode = Array.from(leftNodes).find(node => {
        const bgColor = window.getComputedStyle(node).backgroundColor;
        return isPinkColor(bgColor);
    });

    if (!pinkNode) {
        console.warn('[パネル間矢印] 左パネルにピンクノードが見つかりません');
        return;
    }

    const ctx = leftCanvas.getContext('2d');
    const containerRect = leftContainer.getBoundingClientRect();
    const pinkRect = pinkNode.getBoundingClientRect();

    // ピンクノードの右端中央 → パネル右端
    const startX = pinkRect.right - containerRect.left;
    const startY = pinkRect.top + pinkRect.height / 2 - containerRect.top;
    const endX = leftContainer.offsetWidth;
    const endY = startY;

    ctx.strokeStyle = 'rgb(255, 105, 180)'; // HotPink
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(startX, startY);
    ctx.lineTo(endX, endY);
    ctx.stroke();

    console.log(`[パネル間矢印] 左パネル矢印描画完了: (${startX}, ${startY}) → (${endX}, ${endY})`);

    // 右パネルの矢印を描画
    drawRightPanelPinkArrows();
}

// 右パネル内のピンク矢印を描画
function drawRightPanelPinkArrows() {
    const rightCanvas = arrowState.canvasMap.get(`layer-${rightVisibleLayer}-right`);
    if (!rightCanvas) {
        console.warn(`[パネル間矢印] 右パネルのcanvasが見つかりません: layer-${rightVisibleLayer}-right`);
        return;
    }

    const rightContainer = document.querySelector(`#layer-${rightVisibleLayer}-right .node-list-container`);
    if (!rightContainer) {
        console.warn(`[パネル間矢印] 右パネルのコンテナが見つかりません`);
        return;
    }

    const rightNodes = Array.from(rightContainer.querySelectorAll('.node-button'));
    if (rightNodes.length === 0) {
        console.log('[パネル間矢印] 右パネルにノードがないため、矢印をスキップ');
        return;
    }

    const ctx = rightCanvas.getContext('2d');
    const containerRect = rightContainer.getBoundingClientRect();

    // 最初のノード
    const firstNode = rightNodes[0];
    const firstRect = firstNode.getBoundingClientRect();

    // パネル左端 → 最初のノードの右端
    const startX = 0;
    const startY = firstRect.top + firstRect.height / 2 - containerRect.top;
    const endX = firstRect.right - containerRect.left;
    const endY = startY;

    ctx.strokeStyle = 'rgb(255, 105, 180)'; // HotPink
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(startX, startY);
    ctx.lineTo(endX, endY);
    ctx.stroke();

    // 矢印ヘッド（右向き）
    const arrowSize = 10;
    ctx.fillStyle = 'rgb(255, 105, 180)';
    ctx.beginPath();
    ctx.moveTo(endX, endY);
    ctx.lineTo(endX - arrowSize, endY - arrowSize / 2);
    ctx.lineTo(endX - arrowSize, endY + arrowSize / 2);
    ctx.closePath();
    ctx.fill();

    console.log(`[パネル間矢印] 右パネル入口矢印描画完了`);

    // 最後のノードからの戻り矢印
    if (rightNodes.length > 1) {
        const lastNode = rightNodes[rightNodes.length - 1];
        const lastRect = lastNode.getBoundingClientRect();

        // 最後のノードの左端 → パネル左端（横線）
        const returnStartX = lastRect.left - containerRect.left;
        const returnStartY = lastRect.top + lastRect.height / 2 - containerRect.top;
        const returnEndX = 0;
        const returnEndY = returnStartY;

        ctx.beginPath();
        ctx.moveTo(returnStartX, returnStartY);
        ctx.lineTo(returnEndX, returnEndY);
        ctx.stroke();

        // パネル左端で縦線（最後のノード → 最初のノード）
        ctx.beginPath();
        ctx.moveTo(0, returnEndY);
        ctx.lineTo(0, startY);
        ctx.stroke();

        console.log(`[パネル間矢印] 右パネル戻り矢印描画完了`);
    }
}

function drawPanelArrows(layerId) {
    console.log(`[デバッグ] drawPanelArrows() 呼び出し: layerId=${layerId}`);

    const canvas = arrowState.canvasMap.get(layerId);
    if (!canvas) {
        console.error(`[デバッグ] Canvas が見つかりません: ${layerId}`);
        return;
    }

    const layerPanel = document.getElementById(layerId);
    if (!layerPanel) {
        console.error(`[デバッグ] レイヤーパネルが見つかりません: ${layerId}`);
        return;
    }

    // ★重要: Canvasサイズをコンテナに合わせて調整
    const nodeListContainer = layerPanel.querySelector('.node-list-container');
    if (nodeListContainer) {
        const oldWidth = canvas.width;
        const oldHeight = canvas.height;

        // 親要素の実際のサイズを取得（clientWidth/offsetWidthを優先）
        const parentWidth = Math.max(nodeListContainer.clientWidth, nodeListContainer.offsetWidth, nodeListContainer.scrollWidth, 299);
        const parentHeight = Math.max(nodeListContainer.clientHeight, nodeListContainer.offsetHeight, nodeListContainer.scrollHeight, 700);

        // Canvasの内部描画サイズのみ更新（CSS で表示サイズは 100% に設定済み）
        canvas.width = parentWidth;
        canvas.height = parentHeight;

        if (canvas.width !== oldWidth || canvas.height !== oldHeight) {
            console.log(`[Canvas デバッグ] Canvas サイズ調整: ${oldWidth}x${oldHeight} → ${canvas.width}x${canvas.height}`);
        }
    }

    console.log(`[Canvas デバッグ] Canvas element:`, canvas);
    console.log(`[Canvas デバッグ] Canvas visible:`, canvas.offsetWidth > 0 && canvas.offsetHeight > 0);
    console.log(`[Canvas デバッグ] Canvas style.display:`, canvas.style.display);
    console.log(`[Canvas デバッグ] Canvas style.visibility:`, canvas.style.visibility);
    console.log(`[Canvas デバッグ] Canvas style.opacity:`, canvas.style.opacity);
    console.log(`[Canvas デバッグ] Canvas dimensions: ${canvas.width}x${canvas.height}, offset: ${canvas.offsetWidth}x${canvas.offsetHeight}`);

    const ctx = canvas.getContext('2d');
    console.log(`[Canvas デバッグ] Context:`, ctx);
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    console.log(`[Canvas デバッグ] clearRect完了: (0, 0, ${canvas.width}, ${canvas.height})`);
    ctx.imageSmoothingEnabled = true;

    const nodes = Array.from(layerPanel.querySelectorAll('.node-button'));
    console.log(`[デバッグ] 取得したノード数: ${nodes.length}`);

    // ノードをY座標でソート
    nodes.sort((a, b) => {
        const aRect = a.getBoundingClientRect();
        const bRect = b.getBoundingClientRect();
        return aRect.top - bRect.top;
    });

    // 条件分岐グループを特定
    const conditionGroups = findConditionGroups(nodes);
    console.log(`[デバッグ] 条件分岐グループ数: ${conditionGroups.length}`);

    // 隣接ノード間に矢印を描画
    let arrowCount = 0;
    for (let i = 0; i < nodes.length - 1; i++) {
        const currentNode = nodes[i];
        const nextNode = nodes[i + 1];

        // ノードの背景色を取得
        const currentColor = window.getComputedStyle(currentNode).backgroundColor;
        const nextColor = window.getComputedStyle(nextNode).backgroundColor;

        // 白→白の場合は黒の矢印を描画
        if (isWhiteColor(currentColor) && isWhiteColor(nextColor)) {
            console.log(`[デバッグ] 白→白の矢印を描画: ${i} → ${i+1}`);
            drawDownArrow(ctx, currentNode, nextNode, '#000000');
            arrowCount++;
        }
        // 白→緑（条件分岐開始前）
        else if (isWhiteColor(currentColor) && isSpringGreenColor(nextColor)) {
            drawDownArrow(ctx, currentNode, nextNode, '#000000');
        }
        // 緑→白（条件分岐終了後）
        else if (isSpringGreenColor(currentColor) && isWhiteColor(nextColor)) {
            drawDownArrow(ctx, currentNode, nextNode, '#000000');
        }
        // 白→黄（ループ開始前）
        else if (isWhiteColor(currentColor) && isLemonChiffonColor(nextColor)) {
            drawDownArrow(ctx, currentNode, nextNode, '#000000');
        }
        // 黄→白（ループ終了後）
        else if (isLemonChiffonColor(currentColor) && isWhiteColor(nextColor)) {
            drawDownArrow(ctx, currentNode, nextNode, '#000000');
        }
        // 赤→赤（条件分岐内の赤ブロック）
        else if (isSalmonColor(currentColor) && isSalmonColor(nextColor)) {
            drawDownArrow(ctx, currentNode, nextNode, 'rgb(250, 128, 114)');
        }
        // 青→青（条件分岐内の青ブロック）
        else if (isBlueColor(currentColor) && isBlueColor(nextColor)) {
            drawDownArrow(ctx, currentNode, nextNode, 'rgb(200, 220, 255)');
        }
    }
    console.log(`[デバッグ] 描画した通常矢印数: ${arrowCount}`);

    // コンテナの矩形を取得（条件分岐とループで共通使用）
    const containerRect = nodeListContainer.getBoundingClientRect();

    // 条件分岐の特別な矢印を描画
    conditionGroups.forEach(group => {
        drawConditionalBranchArrows(ctx, group.startNode, group.endNode, group.innerNodes, containerRect);
    });

    // ループの矢印を描画
    const loopGroups = findLoopGroups(nodes);
    console.log(`[デバッグ] ループグループ数: ${loopGroups.length}`);
    loopGroups.forEach(group => {
        drawLoopArrows(ctx, group.startNode, group.endNode, containerRect);
    });

    console.log(`[デバッグ] drawPanelArrows() 完了: ${layerId}`);

    // 描画完了後のCanvas最終状態を確認
    console.log(`[描画完了] Canvas最終状態:`, {
        layerId: layerId,
        canvasWidth: canvas.width,
        canvasHeight: canvas.height,
        canvasStyleWidth: canvas.style.width,
        canvasStyleHeight: canvas.style.height,
        canvasOffsetWidth: canvas.offsetWidth,
        canvasOffsetHeight: canvas.offsetHeight,
        canvasVisible: canvas.offsetWidth > 0 && canvas.offsetHeight > 0,
        canvasDisplay: window.getComputedStyle(canvas).display,
        canvasVisibility: window.getComputedStyle(canvas).visibility,
        canvasOpacity: window.getComputedStyle(canvas).opacity,
        canvasZIndex: window.getComputedStyle(canvas).zIndex,
        canvasPosition: window.getComputedStyle(canvas).position,
        parentElement: canvas.parentElement?.className,
        inDOM: document.body.contains(canvas)
    });

    // デバッグ用：ブラウザ開発者ツールで確認できるようにグローバル変数に保存
    window.DEBUG_CANVAS = canvas;
    console.log(`[デバッグ] Canvas要素をwindow.DEBUG_CANVASに保存しました。ブラウザコンソールで確認できます。`);
}

// 条件分岐グループを見つける
function findConditionGroups(nodes) {
    const groups = [];
    let insideConditional = false;
    let currentGroup = [];

    // PowerShellの仕様: 緑色ボタンがペアで条件分岐を表す
    for (let i = 0; i < nodes.length; i++) {
        const node = nodes[i];
        const color = window.getComputedStyle(node).backgroundColor;

        if (isSpringGreenColor(color)) {
            if (!insideConditional) {
                // 条件分岐開始
                insideConditional = true;
                currentGroup = [node]; // 開始ノード
            } else {
                // 条件分岐終了
                currentGroup.push(node); // 終了ノード

                if (currentGroup.length >= 2) {
                    groups.push({
                        startNode: currentGroup[0],
                        endNode: currentGroup[currentGroup.length - 1],
                        innerNodes: currentGroup.slice(1, -1) // 開始と終了の間のノード
                    });
                }

                insideConditional = false;
                currentGroup = [];
            }
        } else if (insideConditional) {
            // 条件分岐内のノード（赤または青）
            currentGroup.push(node);
        }
    }

    return groups;
}

// 条件分岐の複雑な矢印を描画
function drawConditionalBranchArrows(ctx, startNode, endNode, innerNodes, containerRect) {
    const startRect = startNode.getBoundingClientRect();
    const endRect = endNode.getBoundingClientRect();

    // 内部ノードを赤と青に分類
    console.log(`[条件分岐デバッグ] innerNodes数: ${innerNodes.length}`);
    innerNodes.forEach((node, index) => {
        const computedColor = window.getComputedStyle(node).backgroundColor;
        console.log(`  [${index}] text="${node.textContent}", color="${computedColor}"`);
    });

    const redNodes = innerNodes.filter(node => isSalmonColor(window.getComputedStyle(node).backgroundColor));
    const blueNodes = innerNodes.filter(node => isBlueColor(window.getComputedStyle(node).backgroundColor));

    console.log(`[条件分岐] 赤ノード数: ${redNodes.length}, 青ノード数: ${blueNodes.length}`);

    // 1. 緑（開始）→ 赤（False分岐）への下向き矢印
    if (redNodes.length > 0) {
        const firstRed = redNodes[0];
        drawDownArrow(ctx, startNode, firstRed, 'rgb(250, 128, 114)');
    }

    // 2. 緑（開始）→ 青（True分岐）への複雑な矢印（右→下）
    if (blueNodes.length > 0) {
        const firstBlue = blueNodes[0];
        const firstBlueRect = firstBlue.getBoundingClientRect();

        const startX = startRect.right - containerRect.left;
        const startY = startRect.top + startRect.height / 2 - containerRect.top;
        const horizontalEndX = startX + 20;
        const blueY = firstBlueRect.top + firstBlueRect.height / 2 - containerRect.top;

        ctx.strokeStyle = 'rgb(0, 0, 255)';
        ctx.lineWidth = 2;

        // 右への横線
        ctx.beginPath();
        ctx.moveTo(startX, startY);
        ctx.lineTo(horizontalEndX, startY);
        ctx.stroke();

        // 下への縦線
        ctx.beginPath();
        ctx.moveTo(horizontalEndX, startY);
        ctx.lineTo(horizontalEndX, blueY);
        ctx.stroke();

        // 青ボタンへの横線
        const blueRightX = firstBlueRect.right - containerRect.left;
        ctx.beginPath();
        ctx.moveTo(horizontalEndX, blueY);
        ctx.lineTo(blueRightX, blueY);
        ctx.stroke();
    }

    // 3. 赤（False分岐）→ 緑（終了）への複雑な矢印（左→下→右）
    if (redNodes.length > 0) {
        const lastRed = redNodes[redNodes.length - 1];
        const lastRedRect = lastRed.getBoundingClientRect();

        const startX = lastRedRect.left - containerRect.left;
        const startY = lastRedRect.top + lastRedRect.height / 2 - containerRect.top;
        const horizontalEndX = Math.max(startX - 20, 0);
        const endY = endRect.top + endRect.height / 2 - containerRect.top;

        ctx.strokeStyle = 'rgb(250, 128, 114)';
        ctx.lineWidth = 2;

        // 左への横線
        ctx.beginPath();
        ctx.moveTo(startX, startY);
        ctx.lineTo(horizontalEndX, startY);
        ctx.stroke();

        // 下への縦線
        ctx.beginPath();
        ctx.moveTo(horizontalEndX, startY);
        ctx.lineTo(horizontalEndX, endY);
        ctx.stroke();

        // 終了ノードへの横線と矢印
        const endLeftX = endRect.left - containerRect.left;
        ctx.beginPath();
        ctx.moveTo(horizontalEndX, endY);
        ctx.lineTo(endLeftX, endY);
        ctx.stroke();

        // 矢印ヘッド
        drawArrowHead(ctx, horizontalEndX, endY, endLeftX, endY);
    }

    // 4. 青（True分岐）→ 緑（終了）への下向き矢印
    if (blueNodes.length > 0) {
        const lastBlue = blueNodes[blueNodes.length - 1];
        drawDownArrow(ctx, lastBlue, endNode, 'rgb(0, 0, 255)');
    }
}

// ループグループを見つける
function findLoopGroups(nodes) {
    const groups = [];
    const groupMap = new Map();

    // GroupIDでグループ化
    nodes.forEach(node => {
        const color = window.getComputedStyle(node).backgroundColor;
        const text = node.textContent.trim();
        const groupId = node.dataset.groupId;

        if (isLemonChiffonColor(color) && groupId) {
            if (!groupMap.has(groupId)) {
                groupMap.set(groupId, []);
            }
            groupMap.get(groupId).push(node);
        }
    });

    // 各グループで開始と終了を特定
    groupMap.forEach((groupNodes, groupId) => {
        if (groupNodes.length === 2) {
            const sorted = groupNodes.sort((a, b) => {
                const aRect = a.getBoundingClientRect();
                const bRect = b.getBoundingClientRect();
                return aRect.top - bRect.top;
            });

            groups.push({ startNode: sorted[0], endNode: sorted[1] });
        }
    });

    return groups;
}

// ループの矢印を描画
function drawLoopArrows(ctx, startNode, endNode, containerRect) {
    const startRect = startNode.getBoundingClientRect();
    const endRect = endNode.getBoundingClientRect();

    // 開始ノードの左端から左に出る
    const startX = startRect.left - containerRect.left;
    const startY = startRect.top + startRect.height / 2 - containerRect.top;
    const horizontalEndX = startX - 30;

    // 終了ノードの高さ
    const endY = endRect.top + endRect.height / 2 - containerRect.top;

    ctx.strokeStyle = 'rgb(255, 165, 0)'; // オレンジ色
    ctx.lineWidth = 2;

    // 1. 右向き矢印（開始ノードの左から）
    ctx.beginPath();
    ctx.moveTo(horizontalEndX, startY);
    ctx.lineTo(startX, startY);
    ctx.stroke();

    // 矢印ヘッド（右向き）
    drawArrowHead(ctx, horizontalEndX, startY, startX, startY);

    // 2. 左への横線（終了ノードから）
    const endStartX = endRect.left - containerRect.left;
    ctx.beginPath();
    ctx.moveTo(endStartX, endY);
    ctx.lineTo(horizontalEndX, endY);
    ctx.stroke();

    // 3. 縦線（上から下へ）
    ctx.beginPath();
    ctx.moveTo(horizontalEndX, startY);
    ctx.lineTo(horizontalEndX, endY);
    ctx.stroke();
}

// 色が白かどうかを判定
function isWhiteColor(colorString) {
    // rgb() と rgba() の両方に対応
    const match = colorString.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
    if (match) {
        const r = parseInt(match[1]);
        const g = parseInt(match[2]);
        const b = parseInt(match[3]);
        return r === 255 && g === 255 && b === 255;
    }
    return false;
}

// 色がSpringGreen（条件分岐）かどうかを判定
function isSpringGreenColor(colorString) {
    // rgb() と rgba() の両方に対応
    const match = colorString.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
    if (match) {
        const r = parseInt(match[1]);
        const g = parseInt(match[2]);
        const b = parseInt(match[3]);
        return r === 0 && g === 255 && b === 127;
    }
    return false;
}

// 色がLemonChiffon（ループ）かどうかを判定
function isLemonChiffonColor(colorString) {
    // rgb() と rgba() の両方に対応
    const match = colorString.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
    if (match) {
        const r = parseInt(match[1]);
        const g = parseInt(match[2]);
        const b = parseInt(match[3]);
        return r === 255 && g === 250 && b === 205;
    }
    return false;
}

// 色がSalmon（条件分岐内の赤ブロック）かどうかを判定
function isSalmonColor(colorString) {
    // rgb() と rgba() の両方に対応
    const match = colorString.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
    if (match) {
        const r = parseInt(match[1]);
        const g = parseInt(match[2]);
        const b = parseInt(match[3]);
        return r === 250 && g === 128 && b === 114;
    }
    return false;
}

// 色がBlue系（条件分岐内の青ブロック）かどうかを判定
function isBlueColor(colorString) {
    // rgb() と rgba() の両方に対応
    const match = colorString.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
    if (match) {
        const r = parseInt(match[1]);
        const g = parseInt(match[2]);
        const b = parseInt(match[3]);
        // FromArgb(200, 220, 255)
        const isMatch = r === 200 && g === 220 && b === 255;
        console.log(`[isBlueColor] 検証: r=${r}, g=${g}, b=${b}, match=${isMatch}, input="${colorString}"`);
        return isMatch;
    }
    console.log(`[isBlueColor] パターンマッチ失敗: "${colorString}"`);
    return false;
}

// 色がPink（スクリプト展開ノード）かどうかを判定
function isPinkColor(colorString) {
    // rgb() と rgba() の両方に対応
    const match = colorString.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
    if (match) {
        const r = parseInt(match[1]);
        const g = parseInt(match[2]);
        const b = parseInt(match[3]);
        // Pink, ピンク青色 (227, 206, 229), ピンク赤色 (252, 160, 158)
        return (r === 255 && g === 192 && b === 203) || // Standard Pink
               (r === 227 && g === 206 && b === 229) || // ピンク青色
               (r === 252 && g === 160 && b === 158);   // ピンク赤色
    }
    return false;
}

// パネル間矢印を描画（ピンクノードのスクリプト展開用）
function drawCrossPanelArrows() {
    const mainCanvas = arrowState.canvasMap.get('main');
    if (!mainCanvas) return;

    const ctx = mainCanvas.getContext('2d');
    ctx.clearRect(0, 0, mainCanvas.width, mainCanvas.height);

    // ピンク選択中でない場合は何も描画しない
    if (!arrowState.pinkSelected) {
        return;
    }

    // 左パネル（レイヤー1が基準）のピンクノードを探す
    const leftLayerPanel = document.getElementById('layer-1');
    if (!leftLayerPanel || !leftLayerPanel.classList.contains('active')) {
        return;
    }

    const leftNodes = Array.from(leftLayerPanel.querySelectorAll('.node-button'))
        .sort((a, b) => a.offsetTop - b.offsetTop);

    const pinkNode = leftNodes.find(node => {
        const bgColor = window.getComputedStyle(node).backgroundColor;
        return isPinkColor(bgColor);
    });

    if (!pinkNode) {
        return;
    }

    // スクリプト展開先のパネルを探す（レイヤー3以降で可視でノードがあるもの）
    let scriptPanel = null;
    let scriptPanelFirstNode = null;

    for (let i = 3; i <= 6; i++) {
        const panel = document.getElementById(`layer-${i}`);
        if (panel && panel.classList.contains('active')) {
            const nodes = panel.querySelectorAll('.node-button');
            if (nodes.length > 0) {
                scriptPanel = panel;
                scriptPanelFirstNode = Array.from(nodes).sort((a, b) => a.offsetTop - b.offsetTop)[0];
                break;
            }
        }
    }

    // ピンクノードの位置（フォーム座標系）
    const leftPanelRect = leftLayerPanel.getBoundingClientRect();
    const mainContainerRect = document.getElementById('main-container').getBoundingClientRect();
    const pinkNodeRect = pinkNode.getBoundingClientRect();

    const leftPanelRightX = leftPanelRect.right - mainContainerRect.left;
    const leftButtonCenterY = pinkNodeRect.top + pinkNodeRect.height / 2 - mainContainerRect.top;

    // 鮮やかなピンク色の線
    ctx.strokeStyle = 'rgb(255, 105, 180)'; // HotPink
    ctx.lineWidth = 3;

    if (scriptPanel && scriptPanelFirstNode) {
        // スクリプト展開先がある場合
        const scriptPanelRect = scriptPanel.getBoundingClientRect();
        const scriptNodeRect = scriptPanelFirstNode.getBoundingClientRect();

        const scriptPanelLeftX = scriptPanelRect.left - mainContainerRect.left;
        const scriptButtonCenterY = scriptNodeRect.top + scriptNodeRect.height / 2 - mainContainerRect.top;

        // レイヤー2（可視右パネル）の右端を取得
        const layer2 = document.getElementById('layer-2');
        const layer2Rect = layer2 ? layer2.getBoundingClientRect() : null;
        const mainPanelRightX = layer2Rect ? (layer2Rect.right - mainContainerRect.left) : leftPanelRightX + 300;

        // 前進矢印：左パネル → メインパネル → スクリプトパネル
        ctx.beginPath();
        ctx.moveTo(leftPanelRightX, leftButtonCenterY);
        ctx.lineTo(mainPanelRightX, leftButtonCenterY);
        ctx.stroke();

        ctx.beginPath();
        ctx.moveTo(mainPanelRightX, leftButtonCenterY);
        ctx.lineTo(scriptPanelLeftX, scriptButtonCenterY);
        ctx.stroke();

        // 戻り矢印（ループ形状）
        const scriptNodes = Array.from(scriptPanel.querySelectorAll('.node-button'))
            .sort((a, b) => a.offsetTop - b.offsetTop);
        const scriptPanelLastNode = scriptNodes[scriptNodes.length - 1];

        if (scriptPanelLastNode) {
            const lastNodeRect = scriptPanelLastNode.getBoundingClientRect();
            const scriptLastButtonCenterY = lastNodeRect.top + lastNodeRect.height / 2 - mainContainerRect.top;

            // 左パネルの戻り先を決定（ピンクノードの次のボタン）
            const pinkIndex = leftNodes.indexOf(pinkNode);
            const leftPanelNextNode = leftNodes[pinkIndex + 1];

            let leftReturnY;
            if (leftPanelNextNode) {
                const nextNodeRect = leftPanelNextNode.getBoundingClientRect();
                leftReturnY = nextNodeRect.top + nextNodeRect.height / 2 - mainContainerRect.top;
            } else {
                // 次のボタンがない場合：ピンクノードの下50px
                leftReturnY = pinkNodeRect.bottom + 50 - mainContainerRect.top;
            }

            const loopTopY = leftButtonCenterY;
            const returnGapExtendX = scriptPanelLeftX - 10;

            // 1. スクリプトパネル左端から左に延長
            ctx.beginPath();
            ctx.moveTo(scriptPanelLeftX, scriptLastButtonCenterY);
            ctx.lineTo(returnGapExtendX, scriptLastButtonCenterY);
            ctx.stroke();

            // 2. 上に移動してループのトップまで
            ctx.beginPath();
            ctx.moveTo(returnGapExtendX, scriptLastButtonCenterY);
            ctx.lineTo(returnGapExtendX, loopTopY);
            ctx.stroke();

            // 3. メインパネル右端まで横移動
            ctx.beginPath();
            ctx.moveTo(returnGapExtendX, loopTopY);
            ctx.lineTo(mainPanelRightX, loopTopY);
            ctx.stroke();

            // 4. 左パネル右端まで横移動
            ctx.beginPath();
            ctx.moveTo(mainPanelRightX, loopTopY);
            ctx.lineTo(leftPanelRightX, loopTopY);
            ctx.stroke();

            // 5. 下に移動して戻り先まで
            ctx.beginPath();
            ctx.moveTo(leftPanelRightX, loopTopY);
            ctx.lineTo(leftPanelRightX, leftReturnY);
            ctx.stroke();
        }
    } else {
        // スクリプト展開先がない場合：左パネル → メインパネルまで一本線
        const layer2 = document.getElementById('layer-2');
        const layer2Rect = layer2 ? layer2.getBoundingClientRect() : null;
        const mainPanelRightX = layer2Rect ? (layer2Rect.right - mainContainerRect.left) : leftPanelRightX + 300;

        ctx.beginPath();
        ctx.moveTo(leftPanelRightX, leftButtonCenterY);
        ctx.lineTo(mainPanelRightX, leftButtonCenterY);
        ctx.stroke();
    }
}

// すべての矢印を再描画
function refreshAllArrows() {
    // 各レイヤーの矢印を再描画（左パネル）
    for (let i = 0; i <= 6; i++) {
        drawPanelArrows(`layer-${i}`);
    }

    // 右パネルの矢印も再描画
    for (let i = 0; i <= 6; i++) {
        drawPanelArrows(`layer-${i}-right`);
    }

    // パネル間矢印も再描画（ピンクノード展開時）
    drawCrossPanelPinkArrows();
}

// リサイズ時にCanvasサイズを調整
function resizeCanvases() {
    arrowState.canvasMap.forEach((canvas, id) => {
        if (id === 'main') {
            const mainContainer = document.getElementById('main-container');
            if (mainContainer) {
                // Canvasの内部描画サイズのみ更新（CSSで表示サイズは100%に設定済み）
                const width = Math.max(mainContainer.clientWidth, mainContainer.scrollWidth, 1440);
                const height = Math.max(mainContainer.clientHeight, mainContainer.scrollHeight, 1200);
                canvas.width = width;
                canvas.height = height;
            }
        } else {
            const layerPanel = document.getElementById(id);
            if (layerPanel) {
                const nodeList = layerPanel.querySelector('.node-list-container');
                if (nodeList) {
                    // Canvasの内部描画サイズのみ更新（CSSで表示サイズは100%に設定済み）
                    const width = Math.max(nodeList.clientWidth, nodeList.offsetWidth, nodeList.scrollWidth, 299);
                    const height = Math.max(nodeList.clientHeight, nodeList.offsetHeight, nodeList.scrollHeight, 700);
                    canvas.width = width;
                    canvas.height = height;
                }
            }
        }
    });

    refreshAllArrows();
}

// ピンク選択モードを有効化
function setPinkSelected(selected = true) {
    arrowState.pinkSelected = selected;
    refreshAllArrows();
}

// ピンク選択モードを無効化
function clearPinkSelected() {
    arrowState.pinkSelected = false;
    arrowState.selectedPinkButton = null;
    refreshAllArrows();
}

// デバッグヘルパー関数
function debugCanvasInfo(layerId = 'layer-1') {
    const canvas = arrowState.canvasMap.get(layerId);
    if (!canvas) {
        console.error(`Canvas not found for ${layerId}`);
        return;
    }

    console.log(`=== Canvas Debug Info for ${layerId} ===`);
    console.log('Canvas element:', canvas);
    console.log('Canvas.width (内部):', canvas.width);
    console.log('Canvas.height (内部):', canvas.height);
    console.log('Canvas.style.width (CSS):', canvas.style.width);
    console.log('Canvas.style.height (CSS):', canvas.style.height);
    console.log('Canvas.offsetWidth:', canvas.offsetWidth);
    console.log('Canvas.offsetHeight:', canvas.offsetHeight);
    console.log('Canvas.parentElement:', canvas.parentElement);
    console.log('Computed styles:', window.getComputedStyle(canvas));
    console.log('In DOM:', document.body.contains(canvas));

    // テスト描画
    const ctx = canvas.getContext('2d');
    ctx.strokeStyle = 'red';
    ctx.lineWidth = 5;
    ctx.beginPath();
    ctx.moveTo(10, 10);
    ctx.lineTo(100, 100);
    ctx.stroke();
    console.log('テスト描画完了: 赤い線を (10,10) から (100,100) に描画しました');

    return canvas;
}

// グローバルに公開（即座に利用可能にする）
window.arrowDrawing = {
    refreshAllArrows,
    drawPanelArrows,
    drawCrossPanelArrows,
    resizeCanvases,
    setPinkSelected,
    clearPinkSelected,
    initializeArrowCanvas,  // 初期化関数も公開
    debugCanvasInfo,        // デバッグヘルパー
    state: arrowState,
    initialized: false  // 初期化フラグ
};

// 矢印描画の初期化はapp-legacy.jsのDOMContentLoadedで行われます
// ============================================
// 右ペイン折りたたみ
// ============================================

function toggleRightPanel() {
    const rightPanel = document.getElementById('right-panel');
    const toggleBtn = document.getElementById('right-panel-toggle');

    rightPanelCollapsed = !rightPanelCollapsed;

    if (rightPanelCollapsed) {
        rightPanel.classList.add('collapsed');
        toggleBtn.textContent = '▶';
    } else {
        rightPanel.classList.remove('collapsed');
        toggleBtn.textContent = '◀';
    }
}

// 画面幅チェック（1600px未満で自動折りたたみ）
function checkScreenWidth() {
    const rightPanel = document.getElementById('right-panel');
    const toggleBtn = document.getElementById('right-panel-toggle');

    if (window.innerWidth < 1600) {
        if (!rightPanelCollapsed) {
            rightPanel.classList.add('collapsed');
            toggleBtn.textContent = '▶';
            rightPanelCollapsed = true;
        }
    } else {
        if (rightPanelCollapsed) {
            rightPanel.classList.remove('collapsed');
            toggleBtn.textContent = '◀';
            rightPanelCollapsed = false;
        }
    }
}

// ============================================
// 初期化
// ============================================

document.addEventListener('DOMContentLoaded', async () => {
    console.log('UIpowershell Legacy UI initialized');

    // 矢印描画機能を初期化（arrow-drawing.jsの内容が統合されているため即座に利用可能）
    console.log('[矢印] Arrow drawing initialization...');
    initializeArrowCanvas();
    refreshAllArrows();
    window.arrowDrawing.initialized = true;
    console.log('[矢印] Arrow drawing initialized successfully');
    console.log(`[デバッグ] Canvas数: ${window.arrowDrawing.state.canvasMap.size}`);

    // ウィンドウリサイズ時に矢印を再描画
    window.addEventListener('resize', resizeCanvases);

    // 画面幅チェック
    checkScreenWidth();

    // API接続テスト
    await testApiConnection();

    // 左右パネル表示を初期化
    updateDualPanelDisplay();

    // ボタン設定.jsonを読み込み
    await loadButtonSettings();

    // カテゴリーパネルにノード追加ボタンを生成
    generateAddNodeButtons();

    // イベントリスナー設定
    setupEventListeners();

    // ダイアログのイベントリスナー設定（DOM ready後）
    setupDialogEventListeners();

    // 変数を読み込み
    await loadVariables();

    // フォルダ一覧を読み込み（デフォルトフォルダ自動選択）
    await loadFolders();

    // 既存のノードを読み込み（memory.jsonから）
    // ※loadFolders()の後に実行（currentFolderが設定された後）
    await loadExistingNodes();
});

// リサイズ時のチェック
window.addEventListener('resize', checkScreenWidth);

// ============================================
// API通信
// ============================================

async function testApiConnection() {
    try {
        const response = await fetch(`${API_BASE}/health`);
        const data = await response.json();
        console.log('API接続成功:', data);
        return true;
    } catch (error) {
        console.error('API接続失敗:', error);
        alert('APIサーバーに接続できません。\nadapter/api-server-v2.ps1 を起動してください。');
        return false;
    }
}

async function callApi(endpoint, method = 'GET', body = null) {
    const options = {
        method: method,
        headers: { 'Content-Type': 'application/json' }
    };

    if (body) {
        options.body = JSON.stringify(body);
    }

    const response = await fetch(`${API_BASE}${endpoint}`, options);
    return await response.json();
}

// ============================================
// ボタン設定.json読み込み
// ============================================

async function loadButtonSettings() {
    try {
        console.log('[ボタン設定] ロード開始...');
        // APIサーバー経由でボタン設定.jsonを読み込み
        // 注: 日本語URLのエンコード問題を避けるため、英語エイリアスを使用
        const response = await fetch('/button-settings.json');

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        buttonSettings = await response.json();
        console.log('[ボタン設定] ✅ ロード完了:', buttonSettings.length, '個');
        console.log('[ボタン設定] 最初の3つ:', buttonSettings.slice(0, 3));
    } catch (error) {
        console.error('[ボタン設定] ❌ ロード失敗:', error);
        console.error('[ボタン設定] エラー詳細:', error.message);
        console.error('[ボタン設定] スタックトレース:', error.stack);
        buttonSettings = [];
    }
}

// ============================================
// カテゴリーパネルにノード追加ボタンを生成
// ============================================

function generateAddNodeButtons() {
    console.log('[ボタン生成] 開始 - buttonSettings:', buttonSettings.length, '個');

    // 操作フレームパネル1-10の対応
    const panelMapping = {
        1: 'category-panel-1',
        2: 'category-panel-2',
        3: 'category-panel-3',
        4: 'category-panel-4',
        5: 'category-panel-5',
        6: 'category-panel-6',
        7: 'category-panel-7',
        8: 'category-panel-8',
        9: 'category-panel-9',
        10: 'category-panel-10'
    };

    let generatedCount = 0;

    buttonSettings.forEach((setting, index) => {
        // コンテナ名から数字を抽出（例：操作フレームパネル1 → 1）
        const containerNum = setting.コンテナ.match(/\d+/);
        if (!containerNum) {
            console.warn(`[ボタン生成] コンテナ番号が見つかりません:`, setting.コンテナ);
            return;
        }

        const panelNum = parseInt(containerNum[0]);
        const panelId = panelMapping[panelNum];
        const panel = document.getElementById(panelId);

        if (!panel) {
            console.warn(`[ボタン生成] パネルが見つかりません: ${panelId}`);
            return;
        }

        // ボタンを作成
        const btn = document.createElement('button');
        btn.className = 'add-node-btn';
        btn.textContent = setting.テキスト;
        btn.style.backgroundColor = getColorCode(setting.背景色);
        btn.dataset.setting = JSON.stringify(setting);

        btn.onclick = async () => {
            console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            console.log('[ボタンクリック] ✅ ボタンがクリックされました');
            console.log('[ボタンクリック] テキスト:', setting.テキスト);
            console.log('[ボタンクリック] 処理番号:', setting.処理番号);
            console.log('[ボタンクリック] 関数名:', setting.関数名);
            console.log('[ボタンクリック] 背景色:', setting.背景色);
            console.log('[ボタンクリック] setting全体:', setting);
            console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

            try {
                await addNodeToLayer(setting);
            } catch (error) {
                console.error('[ボタンクリック] ❌ エラーが発生しました:', error);
                console.error('[ボタンクリック] スタックトレース:', error.stack);
            }
        };

        // マウスオーバーで説明を表示
        btn.onmouseenter = () => {
            document.getElementById('description-text').textContent = setting.説明 || 'ここに説明が表示されます。';
        };

        panel.appendChild(btn);
        generatedCount++;

        if (index < 3) {
            console.log(`[ボタン生成] ${index + 1}/${buttonSettings.length}: ${setting.テキスト} (${setting.処理番号}) → ${panelId}`);
        }
    });

    console.log(`[ボタン生成] ✅ 完了 - ${generatedCount}/${buttonSettings.length} 個のボタンを生成しました`);
}

// 色名→CSSカラーコード変換
function getColorCode(colorName) {
    const colorMap = {
        'White': '#FFFFFF',
        'SpringGreen': 'rgb(0, 255, 127)',
        'LemonChiffon': 'rgb(255, 250, 205)',
        'Pink': 'rgb(252, 160, 158)',
        'Salmon': 'rgb(250, 128, 114)',          // 条件分岐 False分岐（赤）
        'LightBlue': 'rgb(200, 220, 255)',       // 条件分岐 True分岐（青）PowerShellの$global:青色に対応
        'Gray': 'rgb(128, 128, 128)'             // 条件分岐 中間ライン
    };
    return colorMap[colorName] || colorName;
}

// ============================================
// カテゴリー切り替え
// ============================================

function switchCategory(categoryNum) {
    currentCategory = categoryNum;

    // すべてのパネルを非表示
    document.querySelectorAll('.category-panel').forEach(panel => {
        panel.classList.remove('active');
    });

    // 選択したパネルを表示
    document.getElementById(`category-panel-${categoryNum}`).classList.add('active');
}

// ============================================
// ノード追加
// ============================================

async function addNodeToLayer(setting) {
    console.log('┌────────────────────────────────────────');
    console.log('│ [addNodeToLayer] 開始');
    console.log('├────────────────────────────────────────');
    console.log('│ 処理番号:', setting.処理番号);
    console.log('│ テキスト:', setting.テキスト);
    console.log('│ 関数名:', setting.関数名);
    console.log('│ 背景色:', setting.背景色);
    console.log('│ 現在のレイヤー:', currentLayer);
    console.log('└────────────────────────────────────────');

    // 処理番号で判定してセット作成
    if (setting.処理番号 === '1-2') {
        // 条件分岐：3個セット（開始・中間・終了）
        console.log('[addNodeToLayer] 条件分岐セット追加を開始');
        await addConditionSet(setting);
        console.log('[addNodeToLayer] 条件分岐セット追加が完了');
    } else if (setting.処理番号 === '1-3') {
        // ループ：2個セット（開始・終了）
        console.log('[addNodeToLayer] ループセット追加を開始');
        await addLoopSet(setting);
        console.log('[addNodeToLayer] ループセット追加が完了');
    } else {
        // 通常ノード：1個
        console.log('[addNodeToLayer] 通常ノード追加を開始');
        const node = addSingleNode(setting);
        console.log('[addNodeToLayer] ノードを作成しました - ID:', node.id, 'name:', node.name);

        // コード生成
        console.log('[addNodeToLayer] generateCode() を呼び出します');
        console.log('[addNodeToLayer]   - 処理番号:', setting.処理番号);
        console.log('[addNodeToLayer]   - ボタン名:', node.name);
        console.log('[addNodeToLayer]   - 関数名:', setting.関数名);
        try {
            const generatedCode = await generateCode(setting.処理番号, node.name);
            if (generatedCode) {
                console.log('[addNodeToLayer] ✅ コード生成成功');
                console.log('[addNodeToLayer] 生成されたコード:', generatedCode.substring(0, 100) + '...');
            } else {
                console.warn('[addNodeToLayer] ⚠ コード生成が null を返しました');
            }
        } catch (error) {
            console.error('[addNodeToLayer] ❌ generateCode() でエラーが発生しました:', error);
            console.error('[addNodeToLayer] スタックトレース:', error.stack);
        }

        // ★修正：画面を再描画（矢印も更新される）
        console.log('[addNodeToLayer] renderNodesInLayer() を呼び出します');
        renderNodesInLayer(currentLayer);
        reorderNodesInLayer(currentLayer);
        console.log('[addNodeToLayer] 通常ノード追加が完了');
    }

    // memory.json自動保存
    console.log('[addNodeToLayer] memory.json自動保存を実行');
    saveMemoryJson();
    console.log('[addNodeToLayer] 完了');
}

// 単一ノードを追加
function addSingleNode(setting, customText = null, customY = null, customGroupId = null, customHeight = 40) {
    const nodeId = `${nodeCounter}-1`;
    nodeCounter++;

    const node = {
        id: nodeId,
        name: setting.ボタン名,
        text: customText || setting.テキスト,
        color: setting.背景色,
        layer: currentLayer,
        x: 90,                              // X座標（中央寄せ）
        y: customY || getNextAvailableY(currentLayer),
        width: 280,                         // ボタン幅
        height: customHeight,               // ボタン高さ（中間ラインは1px）
        groupId: customGroupId,
        処理番号: setting.処理番号,
        関数名: setting.関数名,
        script: ''                          // スクリプト初期値
    };

    nodes.push(node);
    layerStructure[currentLayer].nodes.push(node);

    return node;
}

// ループセット（2個）を追加
async function addLoopSet(setting) {
    const groupId = loopGroupCounter++;
    const baseY = getNextAvailableY(currentLayer);

    console.log(`[ループ作成] GroupID=${groupId} を割り当て`);

    // 1. 開始ボタン
    const startNode = addSingleNode(
        { ...setting, テキスト: 'ループ 開始', ボタン名: `${nodeCounter}-1` },
        'ループ 開始',
        baseY,
        groupId,
        40
    );

    // コード生成（ループ構文）
    await generateCode(setting.処理番号, startNode.name);

    // 2. 終了ボタン
    const endNode = addSingleNode(
        { ...setting, テキスト: 'ループ 終了', ボタン名: `${nodeCounter}-2` },
        'ループ 終了',
        baseY + 45,
        groupId,
        40
    );

    console.log(`[ループ作成完了] ${startNode.name}, ${endNode.name} (GroupID=${groupId})`);

    renderNodesInLayer(currentLayer);
    reorderNodesInLayer(currentLayer);
}

// 条件分岐セット（3個）を追加
async function addConditionSet(setting) {
    const groupId = conditionGroupCounter++;
    const baseY = getNextAvailableY(currentLayer);

    console.log(`[条件分岐作成] GroupID=${groupId} を割り当て`);

    // 1. 開始ボタン（緑）
    const startNode = addSingleNode(
        { ...setting, テキスト: '条件分岐 開始', ボタン名: `${nodeCounter}-1` },
        '条件分岐 開始',
        baseY,
        groupId,
        40
    );

    // コード生成（条件式）
    await generateCode(setting.処理番号, startNode.name);

    // 2. 中間ライン（グレー、高さ1px）
    const middleNode = addSingleNode(
        { ...setting, テキスト: '条件分岐 中間', 背景色: 'Gray', ボタン名: `${nodeCounter}-2` },
        '条件分岐 中間',
        baseY + 45 - 5,  // 5px上に調整
        groupId,
        1  // 高さ1px
    );

    // 3. 終了ボタン（緑）
    const endNode = addSingleNode(
        { ...setting, テキスト: '条件分岐 終了', ボタン名: `${nodeCounter}-3` },
        '条件分岐 終了',
        baseY + 45,
        groupId,
        40
    );

    console.log(`[条件分岐作成完了] 開始, 中間, 終了 (GroupID=${groupId})`);

    renderNodesInLayer(currentLayer);
    reorderNodesInLayer(currentLayer);
}

// 次の利用可能なY座標を取得
function getNextAvailableY(layer) {
    const layerNodes = layerStructure[layer].nodes;
    if (layerNodes.length === 0) return 10;

    const maxY = Math.max(...layerNodes.map(n => n.y));
    return maxY + 45; // ボタン高さ40px + マージン5px
}

// ============================================
// 左右パネル表示管理（PowerShell互換）
// ============================================

// 左右パネルの表示を更新
function updateDualPanelDisplay() {
    console.log(`[デュアルパネル] 左パネル: レイヤー${leftVisibleLayer}, 右パネル: レイヤー${rightVisibleLayer}`);

    // 左パネルのすべてのレイヤーを非表示
    for (let i = 0; i <= 6; i++) {
        const leftPanel = document.getElementById(`layer-${i}`);
        if (leftPanel) {
            leftPanel.style.display = 'none';
        }
    }

    // 右パネルのすべてのレイヤーを非表示
    for (let i = 0; i <= 6; i++) {
        const rightPanel = document.getElementById(`layer-${i}-right`);
        if (rightPanel) {
            rightPanel.style.display = 'none';
        }
    }

    // 左パネルの指定レイヤーを表示
    const leftPanel = document.getElementById(`layer-${leftVisibleLayer}`);
    if (leftPanel) {
        leftPanel.style.display = 'block';
    }

    // 右パネルの指定レイヤーを表示
    const rightPanel = document.getElementById(`layer-${rightVisibleLayer}-right`);
    if (rightPanel) {
        rightPanel.style.display = 'block';
    }

    // レイヤーラベルを更新
    document.getElementById('current-layer-label').textContent = `レイヤー${leftVisibleLayer} / レイヤー${rightVisibleLayer}`;

    // ナビゲーションボタンの状態を更新
    updateNavigationButtons();
}

// ============================================
// レイヤー内のノードを描画
// ============================================

function renderNodesInLayer(layer, panelSide = 'left') {
    // 左右パネル対応: panelSideに応じてコンテナを取得
    const layerId = panelSide === 'right' ? `layer-${layer}-right` : `layer-${layer}`;
    const container = document.querySelector(`#${layerId} .node-list-container`);
    if (!container) {
        console.warn(`[レンダリング] コンテナが見つかりません: ${layerId}`);
        return;
    }

    // Canvas要素を保持しながら、ノードボタンのみを削除
    Array.from(container.children).forEach(child => {
        if (!child.classList.contains('arrow-canvas')) {
            child.remove();
        }
    });
    console.log(`[デバッグ] renderNodesInLayer(${layer}): Canvas要素を保持してノードをクリア`);

    // Y座標でソート
    const layerNodes = layerStructure[layer].nodes.sort((a, b) => a.y - b.y);

    layerNodes.forEach(node => {
        const btn = document.createElement('div');
        btn.className = 'node-button';

        // テキストの省略表示（20文字以上は省略）
        const displayText = node.text.length > 20 ? node.text.substring(0, 20) + '...' : node.text;
        btn.textContent = displayText;

        // ツールチップ（title属性）で完全なテキストを表示
        btn.title = node.text;

        btn.style.backgroundColor = getColorCode(node.color);
        btn.style.position = 'absolute';
        btn.style.left = `${node.x || 90}px`;  // X座標を設定（デフォルト90px）
        btn.style.top = `${node.y}px`;
        btn.dataset.nodeId = node.id;

        // GroupIDを設定（ループと条件分岐で使用）
        if (node.groupId !== null && node.groupId !== undefined) {
            btn.dataset.groupId = node.groupId;
        }

        console.log(`[デバッグ] ノード配置: x=${node.x || 90}px, y=${node.y}px, text="${node.text}", groupId=${node.groupId || 'なし'}`);

        // 赤枠スタイルを適用
        if (node.redBorder) {
            btn.classList.add('red-border');
        }

        // 高さを設定（中間ラインは1px、通常は40px）
        if (node.height && node.height === 1) {
            btn.style.height = '1px';
            btn.style.minHeight = '1px';
            btn.style.fontSize = '0';  // テキスト非表示
            btn.draggable = false;     // ドラッグ不可
        } else {
            btn.draggable = true;

            // ドラッグイベント
            btn.addEventListener('dragstart', handleDragStart);
            btn.addEventListener('dragend', handleDragEnd);
            btn.addEventListener('dragover', handleDragOver);
            btn.addEventListener('drop', handleDrop);

            // クリックイベント（Shift+クリックで赤枠トグル、通常クリックでピンクノード展開）
            btn.addEventListener('click', (e) => {
                if (e.shiftKey) {
                    // Shift+クリック: 赤枠トグル
                    e.preventDefault();
                    e.stopPropagation();
                    handleShiftClick(node);
                } else {
                    // 通常クリック: ピンクノードの場合は展開処理
                    if (node.color === 'Pink') {
                        e.preventDefault();
                        e.stopPropagation();
                        handlePinkNodeClick(node);
                    }
                }
            });

            // ダブルクリックで詳細設定を開く
            btn.addEventListener('dblclick', () => {
                openNodeSettings(node);
            });

            // マウスオーバーで説明表示（該当する設定を検索）
            const setting = buttonSettings.find(s => s.処理番号 === node.処理番号);
            if (setting) {
                btn.onmouseenter = () => {
                    const description = setting.説明 || '';
                    const fullText = `${node.text}\n\n${description}`;
                    document.getElementById('description-text').textContent = fullText;
                };
            }
        }

        // 右クリックメニュー
        btn.addEventListener('contextmenu', (e) => {
            e.preventDefault();
            showContextMenu(e, node);
        });

        container.appendChild(btn);
    });

    // 矢印を再描画
    console.log(`[デバッグ] renderNodesInLayer(${layer}): 矢印を再描画します`);
    if (window.arrowDrawing) {
        setTimeout(() => {
            console.log(`[デバッグ] setTimeout実行: drawPanelArrows('layer-${layer}') を呼び出し`);
            window.arrowDrawing.drawPanelArrows(`layer-${layer}`);
        }, 10);
    } else {
        console.error('[デバッグ] window.arrowDrawing が存在しません！');
    }
}

// ============================================
// ドラッグ&ドロップ（Y座標並び替え）
// ============================================

function handleDragStart(e) {
    draggedNode = e.target;
    e.target.classList.add('dragging');
    e.dataTransfer.effectAllowed = 'move';
}

function handleDragEnd(e) {
    e.target.classList.remove('dragging');
    draggedNode = null;

    // すべての drag-over クラスを削除
    document.querySelectorAll('.drag-over').forEach(el => {
        el.classList.remove('drag-over');
    });
}

function handleDragOver(e) {
    if (e.preventDefault) {
        e.preventDefault();
    }

    e.dataTransfer.dropEffect = 'move';

    const target = e.target;
    if (target.classList.contains('node-button') && target !== draggedNode) {
        target.classList.add('drag-over');
    } else if (target.classList.contains('node-list-container')) {
        // レイヤーパネルへのドロップも許可
        target.classList.add('drag-over-container');
    }

    return false;
}

function handleDrop(e) {
    if (e.stopPropagation) {
        e.stopPropagation();
    }

    const target = e.target;
    target.classList.remove('drag-over');
    target.classList.remove('drag-over-container');

    if (!draggedNode) {
        return false;
    }

    const draggedNodeId = draggedNode.dataset.nodeId;
    const draggedNodeData = layerStructure[currentLayer].nodes.find(n => n.id === draggedNodeId);

    if (!draggedNodeData) {
        return false;
    }

    let newY;

    // ケース1: ノードボタンへのドロップ（位置を入れ替え）
    if (target.classList.contains('node-button') && target !== draggedNode) {
        const targetNodeId = target.dataset.nodeId;
        const targetNodeData = layerStructure[currentLayer].nodes.find(n => n.id === targetNodeId);

        if (!targetNodeData) {
            return false;
        }

        newY = targetNodeData.y;
    }
    // ケース2: レイヤーパネルの空きスペースへのドロップ
    else if (target.classList.contains('node-list-container')) {
        // ドロップ位置のY座標を計算（PowerShellの実装に準拠）
        const rect = target.getBoundingClientRect();
        const dropY = e.clientY - rect.top;  // コンテナ内の相対Y座標

        // ボタンの中心が来るように調整
        const buttonHeight = draggedNodeData.height || 40;
        newY = dropY - (buttonHeight / 2) + 10;

        // 最小値チェック
        if (newY < 10) {
            newY = 10;
        }
    } else {
        return false;
    }

    const currentY = draggedNodeData.y;

    // ============================
    // Phase 3: 整合性チェック
    // ============================

    // 1. 同色ブロック衝突チェック
    const sameColorCollision = checkSameColorCollision(
        draggedNodeData.color,
        currentY,
        newY,
        draggedNodeData.id
    );

    if (sameColorCollision) {
        alert('この位置には配置できません。\n同色のノードブロックと衝突します。');
        return false;
    }

    // 2. ネスト禁止チェック
    const nestingValidation = validateNesting(
        draggedNodeData,
        newY
    );

    if (nestingValidation.isProhibited) {
        alert(`この位置には配置できません。\n${nestingValidation.reason}`);
        return false;
    }

    // ============================
    // バリデーション通過 → 移動実行
    // ============================

    // Y座標を更新
    draggedNodeData.y = newY;

    // 上詰め再配置
    reorderNodesInLayer(currentLayer);

    // 再描画
    renderNodesInLayer(currentLayer);

    // memory.json自動保存
    saveMemoryJson();

    return false;
}

// ノードの位置を入れ替え
function swapNodes(layer, nodeId1, nodeId2) {
    const layerNodes = layerStructure[layer].nodes;
    const index1 = layerNodes.findIndex(n => n.id === nodeId1);
    const index2 = layerNodes.findIndex(n => n.id === nodeId2);

    if (index1 === -1 || index2 === -1) return;

    // Y座標を入れ替え
    const tempY = layerNodes[index1].y;
    layerNodes[index1].y = layerNodes[index2].y;
    layerNodes[index2].y = tempY;

    // 上詰め再配置
    reorderNodesInLayer(layer);
}

// 上詰め再配置
function reorderNodesInLayer(layer) {
    const layerNodes = layerStructure[layer].nodes.sort((a, b) => a.y - b.y);

    // "条件分岐 開始"、"条件分岐 中間"、"条件分岐 終了"の位置を特定
    let startIndex = -1;
    let middleIndex = -1;
    let endIndex = -1;

    for (let i = 0; i < layerNodes.length; i++) {
        if (layerNodes[i].text === '条件分岐 開始') {
            startIndex = i;
        }
        if (layerNodes[i].text === '条件分岐 中間') {
            middleIndex = i;
        }
        if (layerNodes[i].text === '条件分岐 終了') {
            endIndex = i;
        }
    }

    let currentY = 10;

    layerNodes.forEach((node, index) => {
        const buttonText = node.text;

        // ボタンの色を設定する条件分岐（PowerShellの実装に準拠）
        if (startIndex !== -1 && middleIndex !== -1 && index > startIndex && index < middleIndex) {
            // 開始〜中間の間: Salmon（False分岐）
            // スクリプト化ノードは除外（Pinkのまま）
            if (node.color !== 'Pink') {
                node.color = 'Salmon';
            }
        } else if (middleIndex !== -1 && endIndex !== -1 && index > middleIndex && index < endIndex) {
            // 中間〜終了の間: LightBlue（True分岐）
            // スクリプト化ノードは除外（Pinkのまま）
            if (node.color !== 'Pink') {
                node.color = 'LightBlue';
            }
        } else {
            // 条件分岐の外側：SalmonまたはLightBlueの場合はWhiteに戻す
            if (node.color === 'Salmon' || node.color === 'LightBlue') {
                node.color = 'White';
            }
            // スクリプト化ノードはPinkのまま
        }

        // ボタン間隔と高さの調整（"条件分岐 中間"の場合は特殊）
        let interval, height;
        if (buttonText === '条件分岐 中間') {
            interval = 10;  // 通常20のところ10
            height = 0;     // 通常40のところ0
        } else {
            interval = 20;
            height = 40;
        }

        // Y座標を設定
        node.y = currentY + interval;
        currentY = node.y + height;
    });

    renderNodesInLayer(layer);
}

// ============================================
// 右クリックメニュー
// ============================================

function showContextMenu(e, node) {
    const menu = document.getElementById('context-menu');
    menu.style.left = `${e.pageX}px`;
    menu.style.top = `${e.pageY}px`;
    menu.classList.add('show');

    contextMenuTarget = node;

    // メニュー外クリックで閉じる
    setTimeout(() => {
        document.addEventListener('click', hideContextMenu);
    }, 100);
}

function hideContextMenu() {
    document.getElementById('context-menu').classList.remove('show');
    document.removeEventListener('click', hideContextMenu);
}

// 名前変更
function renameNode() {
    if (!contextMenuTarget) return;

    const newName = prompt('新しい名前を入力してください:', contextMenuTarget.text);
    if (newName && newName.trim() !== '') {
        contextMenuTarget.text = newName.trim();
        renderNodesInLayer(currentLayer);
    }

    hideContextMenu();
}

// スクリプト編集
function editScript() {
    if (!contextMenuTarget) return;

    // モーダルを表示
    document.getElementById('script-modal').classList.add('show');
    document.getElementById('script-node-name').textContent = contextMenuTarget.text;
    document.getElementById('script-editor').value = contextMenuTarget.script || '';

    hideContextMenu();
}

// スクリプトモーダルを閉じる
function closeScriptModal() {
    document.getElementById('script-modal').classList.remove('show');
}

// スクリプトを保存
function saveScript() {
    if (!contextMenuTarget) return;

    const newScript = document.getElementById('script-editor').value;
    contextMenuTarget.script = newScript;

    // グローバルノード配列も更新
    const globalNodeIndex = nodes.findIndex(n => n.id === contextMenuTarget.id);
    if (globalNodeIndex !== -1) {
        nodes[globalNodeIndex].script = newScript;
    }

    console.log(`ノード「${contextMenuTarget.text}」のスクリプトを更新しました`);
    alert(`スクリプトを保存しました。`);

    closeScriptModal();
}

// スクリプト実行（選択したノード単体を実行）
async function executeScript() {
    if (!contextMenuTarget) return;

    const script = contextMenuTarget.script || '';

    if (!script || script.trim() === '') {
        alert('実行するスクリプトが設定されていません。\n「スクリプト編集」でスクリプトを設定してください。');
        hideContextMenu();
        return;
    }

    const confirmed = confirm(`ノード「${contextMenuTarget.text}」のスクリプトを実行しますか？\n\nスクリプト内容:\n${script.substring(0, 200)}${script.length > 200 ? '...' : ''}`);
    if (!confirmed) {
        hideContextMenu();
        return;
    }

    try {
        // スクリプト実行APIエンドポイントを呼び出し
        const result = await callApi('/execute/script', 'POST', {
            script: script,
            nodeName: contextMenuTarget.text
        });

        if (result.success) {
            alert(`スクリプト実行完了！\n\n出力:\n${result.output || '(出力なし)'}`);
        } else {
            alert(`スクリプト実行失敗:\n${result.error}`);
        }
    } catch (error) {
        console.error('スクリプト実行エラー:', error);
        alert(`スクリプト実行中にエラーが発生しました:\n${error.message}`);
    }

    hideContextMenu();
}

// レイヤー化（赤枠ノードをまとめて1つのピンクノードにする）
function layerizeNode() {
    if (!contextMenuTarget) {
        alert('ノードが選択されていません。');
        return;
    }

    const layerNodes = layerStructure[currentLayer].nodes;

    // 赤枠ノードを収集
    let redBorderNodes = layerNodes.filter(n => n.redBorder);

    if (redBorderNodes.length === 0) {
        alert('レイヤー化するには、まず赤枠でノードを選択してください。');
        hideContextMenu();
        return;
    }

    // 赤枠に挟まれたノードも赤枠にする（PowerShell互換）
    if (redBorderNodes.length >= 2) {
        // Y座標でソート
        const sortedNodes = [...layerNodes].sort((a, b) => a.y - b.y);
        const redBorderIndices = redBorderNodes.map(node => sortedNodes.findIndex(n => n.id === node.id));

        const startIndex = Math.min(...redBorderIndices);
        const endIndex = Math.max(...redBorderIndices);

        console.log(`[レイヤー化] 赤枠で囲まれた範囲: インデックス${startIndex}～${endIndex}`);

        // 挟まれたノードを赤枠にする
        for (let i = startIndex + 1; i < endIndex; i++) {
            const enclosedNode = sortedNodes[i];
            if (!enclosedNode.redBorder) {
                enclosedNode.redBorder = true;
                console.log(`  [囲み処理] ノード「${enclosedNode.text}」を赤枠に追加`);

                // グローバル配列も更新
                const globalNode = nodes.find(n => n.id === enclosedNode.id);
                if (globalNode) {
                    globalNode.redBorder = true;
                }
            }
        }

        // 赤枠ノードを再収集
        redBorderNodes = layerNodes.filter(n => n.redBorder);
    }

    // Y座標でソート
    const sortedRedNodes = [...redBorderNodes].sort((a, b) => a.y - b.y);

    // 最小Y位置を取得
    const minY = sortedRedNodes[0].y;

    // 削除したノード情報を配列に追加（名前;色;テキスト;スクリプト）
    const deletedNodeInfo = sortedRedNodes.map(node => {
        return `${node.id};${node.color};${node.text};${node.script || ''}`;
    });

    const entryString = deletedNodeInfo.join('_');

    // 赤枠ノードをグローバル配列とレイヤーから削除
    sortedRedNodes.forEach(node => {
        const globalIndex = nodes.findIndex(n => n.id === node.id);
        if (globalIndex !== -1) {
            nodes.splice(globalIndex, 1);
        }

        const layerIndex = layerNodes.findIndex(n => n.id === node.id);
        if (layerIndex !== -1) {
            layerNodes.splice(layerIndex, 1);
        }
    });

    // 新しいピンクノードを作成
    const newNodeId = nodeCounter++;
    const newNode = {
        id: newNodeId,
        text: 'スクリプト',
        color: 'Pink',
        処理番号: '99-1',
        layer: currentLayer,
        y: minY,
        x: 90,
        width: 280,
        height: 40,
        script: entryString,  // 削除したノードの情報を保存
        redBorder: false
    };

    // グローバル配列とレイヤーに追加
    nodes.push(newNode);
    layerNodes.push(newNode);

    // Pink選択配列を更新（PowerShell互換）
    pinkSelectionArray[currentLayer].initialY = minY;
    pinkSelectionArray[currentLayer].value = 1;

    // 左右パネルの表示を更新
    updateDualPanelDisplay();

    // 画面を再描画（左右両パネル）
    renderNodesInLayer(leftVisibleLayer, 'left');
    renderNodesInLayer(rightVisibleLayer, 'right');

    // memory.json自動保存
    saveMemoryJson();

    // 矢印を再描画
    refreshAllArrows();

    console.log(`[レイヤー化] レイヤー${currentLayer}: ${sortedRedNodes.length}個 → ノード${newNodeId} (スクリプト)`);

    hideContextMenu();
}

// ノード削除
async function deleteNode() {
    if (!contextMenuTarget) return;

    // セット削除チェック（条件分岐・ループ）
    const deleteTargets = getDeleteTargets(contextMenuTarget);

    const confirmMessage = deleteTargets.length > 1
        ? `「${contextMenuTarget.text}」を含む${deleteTargets.length}個のセットを削除しますか？`
        : `「${contextMenuTarget.text}」を削除しますか？`;

    const confirmed = confirm(confirmMessage);
    if (!confirmed) {
        hideContextMenu();
        return;
    }

    // ノード配列から削除
    deleteTargets.forEach(id => {
        const index = nodes.findIndex(n => n.id === id);
        if (index !== -1) {
            nodes.splice(index, 1);
        }

        const layerIndex = layerStructure[currentLayer].nodes.findIndex(n => n.id === id);
        if (layerIndex !== -1) {
            layerStructure[currentLayer].nodes.splice(layerIndex, 1);
        }
    });

    renderNodesInLayer(currentLayer);
    reorderNodesInLayer(currentLayer);

    // memory.json自動保存
    saveMemoryJson();

    console.log(`[削除完了] ${deleteTargets.length}個のノードを削除しました`);

    hideContextMenu();
}

// 赤枠トグル（ノードに赤枠を付けたり外したりする）
function toggleRedBorder() {
    if (!contextMenuTarget) return;

    const layerNodes = layerStructure[currentLayer].nodes;
    const targetNode = layerNodes.find(n => n.id === contextMenuTarget.id);

    if (!targetNode) {
        hideContextMenu();
        return;
    }

    // redBorderフラグをトグル
    targetNode.redBorder = !targetNode.redBorder;

    // 画面を再描画
    renderNodesInLayer(currentLayer);

    // memory.json自動保存
    saveMemoryJson();

    console.log(`[赤枠トグル] ノード「${targetNode.text}」の赤枠を${targetNode.redBorder ? '追加' : '削除'}しました`);

    hideContextMenu();
}

// Shift+クリックで赤枠トグル（PowerShell互換）
function handleShiftClick(node) {
    const layerNodes = layerStructure[currentLayer].nodes;
    const targetNode = layerNodes.find(n => n.id === node.id);

    if (!targetNode) return;

    // 赤枠をトグル
    targetNode.redBorder = !targetNode.redBorder;

    // グローバル配列も更新
    const globalNode = nodes.find(n => n.id === targetNode.id);
    if (globalNode) {
        globalNode.redBorder = targetNode.redBorder;
    }

    renderNodesInLayer(currentLayer);

    // memory.json自動保存
    saveMemoryJson();

    console.log(`[Shift+クリック] ノード「${targetNode.text}」の赤枠を${targetNode.redBorder ? '追加' : '削除'}しました`);
}

// ピンクノードクリックで展開処理（PowerShell互換）
function handlePinkNodeClick(node) {
    console.log(`[ピンクノードクリック] ノード「${node.text}」(ID: ${node.id}) がクリックされました`);

    // 親レイヤー番号を取得
    const parentLayer = node.layer;
    console.log(`[展開処理] 親レイヤー: ${parentLayer}`);

    // 次レイヤー番号を計算
    const nextLayer = parentLayer + 1;

    // レイヤー上限チェック
    if (nextLayer > 6) {
        alert('これ以上レイヤーを展開できません（最大レイヤー6）。');
        return;
    }

    console.log(`[展開処理] 次レイヤー: ${nextLayer}`);

    // Pink選択配列に展開状態を記録
    pinkSelectionArray[parentLayer].yCoord = node.y + 15;
    pinkSelectionArray[parentLayer].value = 1;
    pinkSelectionArray[parentLayer].expandedNode = node.id;

    console.log(`[展開処理] Pink選択配列[${parentLayer}] を更新:`, pinkSelectionArray[parentLayer]);

    // arrowStateも更新
    arrowState.pinkSelected = true;
    arrowState.selectedPinkButton = node;

    // 次レイヤーをクリア
    console.log(`[展開処理] レイヤー${nextLayer}をクリア中...`);
    layerStructure[nextLayer].nodes = [];

    // scriptプロパティを解析してノードを展開
    if (!node.script || node.script.trim() === '') {
        console.warn(`[展開処理] ピンクノード「${node.text}」にscriptデータがありません`);
        alert('このスクリプト化ノードは空です。展開するノードがありません。');
        return;
    }

    console.log(`[展開処理] scriptデータ: ${node.script}`);

    // scriptデータを解析（形式: ID;色;テキスト;スクリプト）
    const entries = node.script.split('_').filter(e => e.trim() !== '');
    console.log(`[展開処理] ${entries.length}個のノードを展開します`);

    let baseY = 10; // 初期Y座標

    entries.forEach((entry, index) => {
        const parts = entry.split(';');
        if (parts.length < 3) {
            console.warn(`[展開処理] エントリ${index}のフォーマットが不正: ${entry}`);
            return;
        }

        const originalId = parts[0];
        const color = parts[1];
        const text = parts[2];
        const script = parts[3] || '';

        // 新しいノードを作成
        const newNodeId = nodeCounter++;
        const newNode = {
            id: newNodeId,
            text: text,
            color: color,
            処理番号: '99-1', // スクリプト化ノードの処理番号
            layer: nextLayer,
            y: baseY,
            x: 90,
            width: 280,
            height: 40,
            script: script,
            redBorder: false
        };

        console.log(`[展開処理] ノード${index + 1}/${entries.length}: ${text} (色: ${color})`);

        // グローバル配列とレイヤーに追加
        nodes.push(newNode);
        layerStructure[nextLayer].nodes.push(newNode);

        baseY += 60; // 次のノードのY座標（間隔20px + 高さ40px）
    });

    // 左右パネルの表示を更新（現在のレイヤーに留まる）
    updateDualPanelDisplay();

    // 画面を再描画（左パネルと右パネル）
    renderNodesInLayer(leftVisibleLayer, 'left');
    renderNodesInLayer(rightVisibleLayer, 'right');

    // memory.json自動保存
    saveMemoryJson();

    // 矢印を再描画
    refreshAllArrows();

    console.log(`[展開完了] レイヤー${parentLayer} → レイヤー${nextLayer}: ${node.text} (${entries.length}個のノード展開、レイヤー移動なし)`);
    console.log(`[パネル表示] 左: レイヤー${leftVisibleLayer}, 右: レイヤー${rightVisibleLayer}`);
}

// 赤枠に挟まれたボタンスタイルを適用
function applyRedBorderToGroup() {
    if (!contextMenuTarget) return;

    const layerNodes = layerStructure[currentLayer].nodes;

    // Y座標でソート
    const sortedNodes = [...layerNodes].sort((a, b) => a.y - b.y);

    // 赤枠ノードのインデックスを収集
    const redBorderIndices = [];
    sortedNodes.forEach((node, index) => {
        if (node.redBorder) {
            redBorderIndices.push(index);
        }
    });

    // 赤枠ノードが2つ以上ある場合のみ処理
    if (redBorderIndices.length < 2) {
        alert('赤枠ノードが2つ以上必要です。');
        hideContextMenu();
        return;
    }

    const startIndex = redBorderIndices[0];
    const endIndex = redBorderIndices[redBorderIndices.length - 1];

    // 赤枠に挟まれたノードに赤枠を適用
    let appliedCount = 0;
    for (let i = startIndex + 1; i < endIndex; i++) {
        if (!sortedNodes[i].redBorder) {
            sortedNodes[i].redBorder = true;
            appliedCount++;
        }
    }

    // 画面を再描画
    renderNodesInLayer(currentLayer);

    // memory.json自動保存
    saveMemoryJson();

    console.log(`[赤枠グループ適用] ${appliedCount}個のノードに赤枠を適用しました`);
    alert(`${appliedCount}個のノードに赤枠を適用しました。`);

    hideContextMenu();
}

// 削除対象ノードIDリストを取得
function getDeleteTargets(targetNode) {
    const layerNodes = layerStructure[currentLayer].nodes;

    // 条件分岐（SpringGreen）のチェック
    if (targetNode.color === 'SpringGreen') {
        const result = findConditionSet(layerNodes, targetNode);
        if (result.success) {
            console.log(`[条件分岐削除] ${result.deleteTargets.length}個のノードを削除対象としました`);
            return result.deleteTargets;
        }
    }

    // ループ（LemonChiffon）のチェック
    if (targetNode.color === 'LemonChiffon') {
        const result = findLoopSet(layerNodes, targetNode);
        if (result.success) {
            console.log(`[ループ削除] ${result.deleteTargets.length}個のノードを削除対象としました (GroupID=${targetNode.groupId})`);
            return result.deleteTargets;
        }
    }

    // 通常削除（単一ノード）
    return [targetNode.id];
}

// 条件分岐セット（3個）を特定
function findConditionSet(layerNodes, targetNode) {
    const myY = targetNode.y;
    const myText = targetNode.text.trim();

    // 探索方向と探索対象を決定
    let direction, searchTexts;
    if (myText === '条件分岐 開始') {
        direction = 'down';
        searchTexts = ['条件分岐 中間', '条件分岐 終了'];
    } else if (myText === '条件分岐 終了') {
        direction = 'up';
        searchTexts = ['条件分岐 中間', '条件分岐 開始'];
    } else {
        return { success: false, error: 'SpringGreenだが対象外テキスト' };
    }

    // 候補ノードを抽出
    const candidates = {};

    layerNodes.forEach(node => {
        const txt = node.text.trim();
        if (!searchTexts.includes(txt)) return;
        if (node.color !== 'SpringGreen') return;

        const delta = node.y - myY;
        if ((direction === 'down' && delta <= 0) || (direction === 'up' && delta >= 0)) return;

        const distance = Math.abs(delta);

        // まだ登録されていない or もっと近いノードなら採用
        if (!candidates[txt] || distance < candidates[txt].distance) {
            candidates[txt] = { node, distance };
        }
    });

    // 3つ揃っているか判定
    const deleteTargets = [targetNode.id];
    searchTexts.forEach(txt => {
        if (candidates[txt]) {
            deleteTargets.push(candidates[txt].node.id);
        }
    });

    if (deleteTargets.length < 3) {
        return {
            success: false,
            error: `セットが揃わないため削除できません（見つかったノード: ${deleteTargets.length}/3）`
        };
    }

    return {
        success: true,
        message: '条件分岐セット（3個）の削除対象を特定しました',
        deleteTargets,
        nodeType: '条件分岐'
    };
}

// ループセット（2個）を特定
function findLoopSet(layerNodes, targetNode) {
    const targetGroupID = targetNode.groupId;

    if (!targetGroupID) {
        return { success: false, error: 'ターゲットノードにGroupIDが設定されていません' };
    }

    // 同じGroupIDを持つLemonChiffonノードを収集
    const deleteTargets = [];

    layerNodes.forEach(node => {
        if (node.color !== 'LemonChiffon') return;
        if (node.groupId === targetGroupID) {
            deleteTargets.push(node.id);
        }
    });

    // 2つ揃っているかチェック
    if (deleteTargets.length < 2) {
        return {
            success: false,
            error: `ループ開始/終了のセットが揃わないため削除できません（見つかったノード: ${deleteTargets.length}/2）`
        };
    }

    return {
        success: true,
        message: 'ループセット（2個）の削除対象を特定しました',
        deleteTargets,
        nodeType: 'ループ',
        groupId: targetGroupID
    };
}

// 全削除
function deleteAllNodes() {
    const confirmed = confirm('すべてのノードを削除しますか？');
    if (!confirmed) return;

    layerStructure[currentLayer].nodes = [];
    nodes = nodes.filter(n => n.layer !== currentLayer);

    renderNodesInLayer(currentLayer);

    // memory.json自動保存
    saveMemoryJson();
}

// ============================================
// レイヤーナビゲーション
// ============================================

function navigateLayer(direction) {
    if (direction === 'right') {
        // 右矢印: レイヤーを進む（PowerShellの「左矢印」= 画面が左にスライド）

        // スクリプト展開チェック（レイヤー1以降）
        if (leftVisibleLayer >= 1) {
            if (pinkSelectionArray[leftVisibleLayer].value !== 1) {
                alert(`レイヤー${leftVisibleLayer + 1} に進むには、\nレイヤー${leftVisibleLayer} でスクリプト化ノードを展開してください。\n\n操作手順:\n1. Shift を押しながら複数のノードをクリック（赤枠が付きます）\n2. 「レイヤー化」ボタンをクリック\n3. 作成されたスクリプト化ノード（ピンク色）をクリック\n4. 次のレイヤーに展開されます`);
                console.log(`[❌ 右矢印] レイヤー${leftVisibleLayer} でスクリプト展開中ではないため、進めません`);
                return;
            }
            console.log(`[✅ 右矢印] レイヤー${leftVisibleLayer} でスクリプト展開中を確認。レイヤー${leftVisibleLayer + 1} に進みます`);
        }

        // レイヤー範囲チェック（左パネルは最大5、右パネルは最大6）
        if (leftVisibleLayer < 5) {
            leftVisibleLayer++;
            rightVisibleLayer++;

            console.log(`[レイヤー進む] 左パネル: レイヤー${leftVisibleLayer}, 右パネル: レイヤー${rightVisibleLayer}`);

            // 現在のレイヤーより深いレイヤーをクリア
            clearDeeperLayers(leftVisibleLayer);
        }
    } else if (direction === 'left') {
        // 左矢印: レイヤーを戻る（PowerShellの「右矢印」= 画面が右にスライド）

        // レイヤー2以上の場合のみ戻れる（leftVisibleLayer > 1）
        if (leftVisibleLayer > 1) {
            leftVisibleLayer--;
            rightVisibleLayer--;

            console.log(`[レイヤー戻る] 左パネル: レイヤー${leftVisibleLayer}, 右パネル: レイヤー${rightVisibleLayer}`);

            // 現在のレイヤーより深いレイヤーをクリア
            clearDeeperLayers(leftVisibleLayer);
        }
    }

    // デュアルパネル表示を更新
    updateDualPanelDisplay();

    // 両パネルを再描画
    renderNodesInLayer(leftVisibleLayer, 'left');
    renderNodesInLayer(rightVisibleLayer, 'right');

    // memory.jsonを保存
    saveMemoryJson();

    // 矢印を再描画
    refreshAllArrows();
}

// 現在のレイヤーより深いレイヤーをクリアする関数
function clearDeeperLayers(currentLayer) {
    console.log(`[クリア] レイヤー${currentLayer}より深いレイヤーをクリアします`);
    for (let i = currentLayer + 1; i <= 6; i++) {
        // レイヤー構造からノードを削除
        const clearedCount = layerStructure[i].nodes.length;
        layerStructure[i].nodes = [];

        // グローバルnodesからも削除
        nodes = nodes.filter(n => n.layer !== i);

        // Pink選択配列をリセット
        if (i >= 0 && i <= 6) {
            pinkSelectionArray[i].value = 0;
            pinkSelectionArray[i].expandedNode = null;
            pinkSelectionArray[i].yCoord = 0;
            pinkSelectionArray[i].initialY = 0;
        }

        if (clearedCount > 0) {
            console.log(`  レイヤー${i}: ${clearedCount}個のノードをクリア`);
        }
    }
}

// ナビゲーションボタンの状態を更新
function updateNavigationButtons() {
    const leftBtn = document.querySelector('[onclick*="navigateLayer(\'left\')"]');
    const rightBtn = document.querySelector('[onclick*="navigateLayer(\'right\')"]');

    if (leftBtn) {
        // 左矢印: レイヤー1以下では戻れない
        leftBtn.disabled = (leftVisibleLayer <= 1);
        leftBtn.style.opacity = (leftVisibleLayer <= 1) ? '0.5' : '1';
    }

    if (rightBtn) {
        // 右矢印: 左パネルがレイヤー5以上では進めない
        rightBtn.disabled = (leftVisibleLayer >= 5);
        rightBtn.style.opacity = (leftVisibleLayer >= 5) ? '0.5' : '1';
    }
}

// ============================================
// 変数管理
// ============================================

async function loadVariables() {
    try {
        const result = await callApi('/variables');
        if (result.success) {
            variables = result.variables || {};
            console.log('変数読み込み完了:', Object.keys(variables).length, '個');
        }
    } catch (error) {
        console.error('変数読み込み失敗:', error);
    }
}

function openVariableModal() {
    document.getElementById('variable-modal').classList.add('show');
    renderVariableTable();
}

function closeVariableModal() {
    document.getElementById('variable-modal').classList.remove('show');
}

function renderVariableTable() {
    const tbody = document.getElementById('variable-list');
    tbody.innerHTML = '';

    Object.entries(variables).forEach(([name, data]) => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td>${name}</td>
            <td>${data.value || ''}</td>
            <td>${data.type || '単一値'}</td>
            <td>
                <button onclick="editVariable('${name}')">編集</button>
                <button onclick="deleteVariable('${name}')">削除</button>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

async function addVariablePrompt() {
    const name = prompt('変数名を入力してください:');
    if (!name || name.trim() === '') return;

    const value = prompt('値を入力してください:');

    try {
        // API経由で変数を追加
        const result = await callApi('/variables', 'POST', {
            name: name.trim(),
            value: value || '',
            type: '単一値'
        });

        if (result.success) {
            // ローカル変数にも追加
            variables[name.trim()] = {
                value: value || '',
                type: '単一値'
            };
            renderVariableTable();
            console.log(`変数「${name}」を追加しました（API永続化済み）`);
        } else {
            alert(`変数追加に失敗しました: ${result.error}`);
        }
    } catch (error) {
        console.error('変数追加エラー:', error);
        alert(`変数追加中にエラーが発生しました: ${error.message}`);
    }
}

async function editVariable(name) {
    const value = prompt(`「${name}」の新しい値を入力してください:`, variables[name].value);
    if (value === null) return; // キャンセル時

    try {
        // API経由で変数を更新
        const result = await callApi(`/variables/${name}`, 'PUT', {
            value: value
        });

        if (result.success) {
            // ローカル変数も更新
            variables[name].value = value;
            renderVariableTable();
            console.log(`変数「${name}」を更新しました（API永続化済み）`);
        } else {
            alert(`変数更新に失敗しました: ${result.error}`);
        }
    } catch (error) {
        console.error('変数更新エラー:', error);
        alert(`変数更新中にエラーが発生しました: ${error.message}`);
    }
}

async function deleteVariable(name) {
    const confirmed = confirm(`変数「${name}」を削除しますか？`);
    if (!confirmed) return;

    try {
        // API経由で変数を削除
        const result = await callApi(`/variables/${name}`, 'DELETE');

        if (result.success) {
            // ローカル変数からも削除
            delete variables[name];
            renderVariableTable();
            console.log(`変数「${name}」を削除しました（API永続化済み）`);
        } else {
            alert(`変数削除に失敗しました: ${result.error}`);
        }
    } catch (error) {
        console.error('変数削除エラー:', error);
        alert(`変数削除中にエラーが発生しました: ${error.message}`);
    }
}

// ============================================
// フォルダ管理
// ============================================

async function loadFolders() {
    try {
        console.log('┌─ [フォルダ初期化] 開始 ─────────────');

        // 1. メイン.jsonから現在のフォルダを読み込む（PowerShell互換）
        console.log('│ Step 1: メイン.jsonから現在のフォルダを読み込み');
        try {
            const mainJsonResult = await callApi('/main-json');
            if (mainJsonResult.success) {
                currentFolder = mainJsonResult.folderName;
                console.log(`│ ✅ メイン.jsonから読み込み成功: ${currentFolder}`);
                console.log(`│    フルパス: ${mainJsonResult.folderPath}`);
            } else {
                console.warn(`│ ⚠ メイン.jsonが存在しません: ${mainJsonResult.error}`);
                currentFolder = null;
            }
        } catch (error) {
            console.error('│ ❌ メイン.json読み込みエラー:', error);
            currentFolder = null;
        }

        // 2. フォルダ一覧を取得
        console.log('│ Step 2: フォルダ一覧を取得');
        const result = await callApi('/folders');
        if (result.success) {
            folders = result.folders || [];
            console.log(`│ ✅ フォルダ一覧取得成功: ${folders.length}個`);
            console.log(`│    フォルダ: [${folders.join(', ')}]`);
        } else {
            console.error('│ ❌ フォルダ一覧取得失敗');
            folders = [];
        }

        // 3. currentFolderが未設定またはフォルダ一覧に無い場合
        if (!currentFolder || !folders.includes(currentFolder)) {
            if (folders.length > 0) {
                currentFolder = folders[0];
                console.warn(`│ ⚠ currentFolderを最初のフォルダに設定: ${currentFolder}`);
            } else {
                // フォルダが1つも無い場合は作成を促す
                console.error('│ ❌ フォルダが1つも存在しません');
                console.error('│    「フォルダ作成」ボタンから新しいフォルダを作成してください');
                console.log('└──────────────────────────────────────');
                return;
            }
        }

        console.log('│ Step 3: 現在のフォルダ:', currentFolder);

        // 4. JSON読み込み
        if (currentFolder) {
            console.log('│ Step 4: JSONファイルを読み込み');

            // コード.jsonとvariables.jsonを読み込む
            await loadCodeJson();
            await loadVariablesJson();

            // 既にノードがある場合は上書きしない（ユーザーが追加したノードを保護）
            if (nodes.length === 0) {
                console.log('│    memory.jsonからノードを読み込み');
                await loadExistingNodes();
            } else {
                console.log('│    既存ノードを保護（memory.json読み込みスキップ）');
            }

            console.log('│ ✅ 初期化完了');
        }

        console.log('└──────────────────────────────────────');
    } catch (error) {
        console.error('┌─ [フォルダ初期化] エラー ────────────');
        console.error('│', error);
        console.error('│ スタックトレース:', error.stack);
        console.error('└──────────────────────────────────────');
    }
}

function createFolder() {
    const folderName = prompt('新しいフォルダ名を入力してください:');
    if (!folderName || folderName.trim() === '') return;

    callApi('/folders', 'POST', { name: folderName.trim() })
        .then(result => {
            if (result.success) {
                alert(`フォルダ「${folderName}」を作成しました。`);
                loadFolders();
            } else {
                alert(`フォルダ作成に失敗しました: ${result.error}`);
            }
        });
}

function switchFolder() {
    document.getElementById('folder-modal').classList.add('show');

    // フォルダ一覧を表示
    const select = document.getElementById('folder-select');
    select.innerHTML = '';

    folders.forEach(folder => {
        const option = document.createElement('option');
        option.value = folder;
        option.textContent = folder;
        select.appendChild(option);
    });
}

function closeFolderModal() {
    document.getElementById('folder-modal').classList.remove('show');
}

async function selectFolder() {
    const select = document.getElementById('folder-select');
    const folderName = select.value;

    if (!folderName) return;

    try {
        const result = await callApi(`/folders/${folderName}`, 'PUT');
        if (result.success) {
            currentFolder = folderName;
            alert(`フォルダ「${folderName}」に切り替えました。`);
            closeFolderModal();

            // コード.json、variables.json、memory.jsonを読み込む
            await loadCodeJson();
            await loadVariablesJson();
            await loadExistingNodes();
        } else {
            alert(`フォルダ切り替えに失敗しました: ${result.error}`);
        }
    } catch (error) {
        console.error('フォルダ切り替えエラー:', error);
        alert(`フォルダ切り替えエラー: ${error.message}`);
    }
}

// ============================================
// コード生成
// ============================================

async function executeCode() {
    const confirmed = confirm('PowerShellコードを生成しますか？');
    if (!confirmed) return;

    try {
        // 現在のレイヤーのノードを送信
        const result = await callApi('/execute/generate', 'POST', {
            nodes: layerStructure[currentLayer].nodes.map(n => ({
                id: n.id,
                text: n.text,
                color: n.color,
                y: n.y,
                処理番号: n.処理番号
            })),
            outputPath: null,
            openFile: false
        });

        if (result.success) {
            // 結果モーダルに情報を表示
            const infoDiv = document.getElementById('code-result-info');
            infoDiv.innerHTML = `
                <div style="background: #e8f5e9; padding: 15px; border-radius: 5px; border: 1px solid #4caf50;">
                    <p style="margin-bottom: 8px;"><strong>📊 ノード数:</strong> ${result.nodeCount}個</p>
                    <p style="margin-bottom: 8px;"><strong>📁 出力先:</strong> ${result.outputPath || '（メモリ内のみ）'}</p>
                    <p style="margin-bottom: 0;"><strong>⏱️ 生成時刻:</strong> ${new Date().toLocaleString('ja-JP')}</p>
                </div>
            `;

            // 生成されたコードをプレビューに表示
            const codePreview = document.getElementById('code-result-preview');
            codePreview.value = result.generatedCode || '（コードプレビューは利用できません）';

            // グローバル変数に保存（コピー/ファイルオープン用）
            window.lastGeneratedCode = {
                code: result.generatedCode,
                path: result.outputPath
            };

            // モーダルを表示
            document.getElementById('code-result-modal').classList.add('show');
        } else {
            alert(`コード生成失敗: ${result.error}`);
        }
    } catch (error) {
        console.error('コード生成エラー:', error);
        alert(`コード生成中にエラーが発生しました: ${error.message}`);
    }
}

function closeCodeResultModal() {
    document.getElementById('code-result-modal').classList.remove('show');
}

function copyGeneratedCode() {
    const codePreview = document.getElementById('code-result-preview');
    codePreview.select();
    document.execCommand('copy');
    alert('✅ 生成されたコードをクリップボードにコピーしました！');
}

function openGeneratedFile() {
    if (window.lastGeneratedCode && window.lastGeneratedCode.path) {
        // PowerShellでファイルを開く（Windows環境）
        alert(`ファイルを開きます: ${window.lastGeneratedCode.path}\n\n（この機能はブラウザ制限により未実装です）`);
    } else {
        alert('出力ファイルのパスが見つかりません。');
    }
}

// ============================================
// スナップショット機能
// ============================================

function createSnapshot() {
    const snapshotName = prompt('スナップショット名を入力してください:');
    if (!snapshotName || snapshotName.trim() === '') return;

    const snapshot = {
        name: snapshotName.trim(),
        timestamp: new Date().toISOString(),
        nodes: JSON.parse(JSON.stringify(nodes)),
        layerStructure: JSON.parse(JSON.stringify(layerStructure)),
        variables: JSON.parse(JSON.stringify(variables))
    };

    // localStorageに保存
    const snapshots = JSON.parse(localStorage.getItem('snapshots') || '[]');
    snapshots.push(snapshot);
    localStorage.setItem('snapshots', JSON.stringify(snapshots));

    alert(`スナップショット「${snapshotName}」を作成しました。`);
}

function restoreSnapshot() {
    const snapshots = JSON.parse(localStorage.getItem('snapshots') || '[]');

    if (snapshots.length === 0) {
        alert('スナップショットがありません。');
        return;
    }

    const snapshotList = snapshots.map((s, i) => `${i + 1}. ${s.name} (${new Date(s.timestamp).toLocaleString()})`).join('\n');
    const choice = prompt(`復元するスナップショットを選択してください:\n\n${snapshotList}\n\n番号を入力:`);

    if (!choice) return;

    const index = parseInt(choice) - 1;
    if (index < 0 || index >= snapshots.length) {
        alert('無効な番号です。');
        return;
    }

    const snapshot = snapshots[index];

    nodes = JSON.parse(JSON.stringify(snapshot.nodes));
    layerStructure = JSON.parse(JSON.stringify(snapshot.layerStructure));
    variables = JSON.parse(JSON.stringify(snapshot.variables));

    renderNodesInLayer(currentLayer);
    alert(`スナップショット「${snapshot.name}」を復元しました。`);
}

// ============================================
// 既存ノードの読み込み（memory.json）
// ============================================

async function loadExistingNodes() {
    try {
        // 現在のフォルダが設定されていない場合は何もしない
        if (!currentFolder) {
            console.log('フォルダが選択されていないため、ノード読み込みをスキップします');
            return;
        }

        // memory.jsonからノード配置を読み込み
        const response = await fetch(`${API_BASE}/folders/${currentFolder}/memory`);
        const result = await response.json();

        if (!result.success) {
            console.error('memory.json読み込み失敗:', result.error);
            return;
        }

        const memoryData = result.data;
        console.log('memory.json読み込み成功:', memoryData);

        // 全レイヤーをクリア
        nodes = [];
        for (let i = 0; i <= 6; i++) {
            layerStructure[i].nodes = [];
        }

        // memory.jsonからノードを復元
        for (let layerNum = 1; layerNum <= 6; layerNum++) {
            const layerData = memoryData[layerNum.toString()];
            if (!layerData || !layerData.構成) continue;

            layerData.構成.forEach(nodeData => {
                const node = {
                    id: `node-${nodeCounter++}`,
                    name: nodeData.ボタン名 || '',
                    text: nodeData.テキスト || '',
                    color: nodeData.ボタン色 || 'White',
                    layer: layerNum,
                    y: nodeData.Y座標 || 10,
                    x: nodeData.X座標 || 10,
                    width: nodeData.幅 || 280,
                    height: nodeData.高さ || 40,
                    groupId: nodeData.GroupID || null,
                    処理番号: nodeData.処理番号 || '',
                    script: nodeData.script || '',
                    関数名: nodeData.関数名 || ''
                };

                nodes.push(node);
                layerStructure[layerNum].nodes.push(node);
            });
        }

        // 左右両方のパネルを再描画
        renderNodesInLayer(leftVisibleLayer, 'left');
        renderNodesInLayer(rightVisibleLayer, 'right');
        console.log(`memory.jsonから${nodes.length}個のノードを復元しました`);
        console.log(`[表示] 左パネル: レイヤー${leftVisibleLayer}, 右パネル: レイヤー${rightVisibleLayer}`);
    } catch (error) {
        console.error('既存ノード読み込み失敗:', error);
    }
}

// memory.jsonを保存
async function saveMemoryJson() {
    if (!currentFolder) {
        console.warn('フォルダが選択されていないため、memory.json保存をスキップします');
        return;
    }

    try {
        // オリジナルPowerShell形式に合わせてデータを整形
        // 各レイヤーのノードに順番を付ける
        const formattedLayerStructure = {};

        for (let i = 0; i <= 6; i++) {
            const layerNodes = layerStructure[i].nodes || [];
            // Y座標でソート
            const sortedNodes = [...layerNodes].sort((a, b) => a.y - b.y);

            // 順番フィールドを追加
            const nodesWithIndex = sortedNodes.map((node, index) => ({
                ...node,
                順番: index + 1  // 1から始まる順番
            }));

            formattedLayerStructure[i] = {
                visible: layerStructure[i].visible,
                nodes: nodesWithIndex
            };
        }

        const response = await fetch(`${API_BASE}/folders/${currentFolder}/memory`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ layerStructure: formattedLayerStructure })
        });

        const result = await response.json();

        if (result.success) {
            console.log('memory.json保存成功:', result.message);
        } else {
            console.error('memory.json保存失敗:', result.error);
        }
    } catch (error) {
        console.error('memory.json保存エラー:', error);
    }
}

// ============================================
// コード.json管理（スクリプト内容）
// ============================================

// コード.jsonを読み込む
async function loadCodeJson() {
    if (!currentFolder) {
        console.warn('フォルダが選択されていないため、コード.json読み込みをスキップします');
        return;
    }

    try {
        const response = await fetch(`${API_BASE}/folders/${currentFolder}/code`);
        const result = await response.json();

        if (result.success) {
            codeData = result.data;
            // 🔧 修正: "エントリ"プロパティが存在しない場合は初期化
            if (!codeData["エントリ"]) {
                codeData["エントリ"] = {};
            }
            if (typeof codeData["最後のID"] !== 'number') {
                codeData["最後のID"] = 0;
            }
            console.log('コード.json読み込み成功:', codeData);
        } else {
            console.error('コード.json読み込み失敗:', result.error);
            // 空のデータで初期化
            codeData = {
                "エントリ": {},
                "最後のID": 0
            };
        }
    } catch (error) {
        console.error('コード.json読み込みエラー:', error);
        // 空のデータで初期化
        codeData = {
            "エントリ": {},
            "最後のID": 0
        };
    }
}

// コード.jsonを保存する
async function saveCodeJson() {
    console.log('┌─ [コード.json保存] 開始 ─────────────');
    console.log('│ currentFolder:', currentFolder);
    console.log('│ エントリ数:', Object.keys(codeData["エントリ"] || {}).length);

    if (!currentFolder) {
        console.error('│ ❌ エラー: フォルダが選択されていません！');
        console.error('│ コード.json保存をスキップします');
        console.log('└──────────────────────────────────────');
        return;
    }

    try {
        console.log('│ → API呼び出し: POST /folders/' + currentFolder + '/code');
        const response = await fetch(`${API_BASE}/folders/${currentFolder}/code`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ codeData: codeData })
        });

        const result = await response.json();

        if (result.success) {
            console.log('│ ✅ 成功:', result.message);
            console.log('│ 保存先: 03_history/' + currentFolder + '/コード.json');
        } else {
            console.error('│ ❌ 失敗:', result.error);
        }
    } catch (error) {
        console.error('│ ❌ エラー:', error);
        console.error('│ スタックトレース:', error.stack);
    }

    console.log('└──────────────────────────────────────');
}

// 処理番号でスクリプト内容を取得
function getCodeEntry(処理番号) {
    if (!処理番号) return '';

    const entry = codeData["エントリ"][処理番号];
    return entry || '';
}

// 処理番号でスクリプト内容を設定
// PowerShell互換: "---" で分割してサブIDを自動生成
async function setCodeEntry(id, content) {
    console.log('┌─ [setCodeEntry] 開始 ────────────────');
    console.log('│ ID:', id);
    console.log('│ content長:', content ? content.length : 0);

    if (!id) {
        console.error('│ ❌ エラー: IDが指定されていません');
        console.log('└──────────────────────────────────────');
        return;
    }

    if (!content || content.trim() === '') {
        console.error('│ ❌ エラー: コンテンツが空です');
        console.log('└──────────────────────────────────────');
        return;
    }

    // 🔧 修正: codeDataの初期化確認
    if (!codeData["エントリ"]) {
        codeData["エントリ"] = {};
        console.log('│ codeData["エントリ"]を初期化しました');
    }

    // "---" で文字列を分割
    const separator = '---';
    const parts = content.split(separator);

    console.log(`│ 分割数: ${parts.length}`);

    // 各部分にサブIDを割り当てて追加
    for (let i = 0; i < parts.length; i++) {
        const subId = `${id}-${i + 1}`;
        const trimmedContent = parts[i].trim();
        codeData["エントリ"][subId] = trimmedContent;
        console.log(`│   [${subId}] ${trimmedContent.substring(0, 50)}${trimmedContent.length > 50 ? '...' : ''}`);
    }

    // 最後のIDを更新
    const numericId = parseInt(id);
    if (!isNaN(numericId) && numericId > codeData["最後のID"]) {
        codeData["最後のID"] = numericId;
        console.log(`│ 最後のIDを更新: ${numericId}`);
    }

    console.log('│ メモリ上のcodeDataに保存完了');
    console.log('│ 現在のエントリ数:', Object.keys(codeData["エントリ"]).length);
    console.log('│');
    console.log('│ saveCodeJson()を呼び出します...');
    console.log('└──────────────────────────────────────');

    // コード.jsonを保存
    await saveCodeJson();
}

// ============================================
// ノード詳細設定
// ============================================

let currentSettingsNode = null;

function openNodeSettings(node) {
    currentSettingsNode = node;

    // モーダルを表示
    document.getElementById('node-settings-modal').classList.add('show');
    document.getElementById('settings-node-name').textContent = node.text;
    document.getElementById('settings-node-text').value = node.text;
    document.getElementById('settings-node-script').value = node.script || '';

    // カスタムフィールドをクリア
    const customFields = document.getElementById('settings-custom-fields');
    customFields.innerHTML = '';

    // 処理番号に応じたカスタムフィールドを追加
    if (node.処理番号 === '1-2') {
        // 条件分岐
        customFields.innerHTML = `
            <div style="margin-bottom: 15px;">
                <label>条件式:</label>
                <input type="text" id="condition-expression" value="${node.conditionExpression || ''}" style="width: 100%; padding: 5px;" placeholder="例: $変数 -eq '値'" />
            </div>
        `;
    } else if (node.処理番号 === '1-3') {
        // ループ
        customFields.innerHTML = `
            <div style="margin-bottom: 15px;">
                <label>ループ回数:</label>
                <input type="number" id="loop-count" value="${node.loopCount || 1}" style="width: 200px; padding: 5px;" />
            </div>
            <div style="margin-bottom: 15px;">
                <label>ループ変数名:</label>
                <input type="text" id="loop-variable" value="${node.loopVariable || 'i'}" style="width: 200px; padding: 5px;" />
            </div>
        `;
    }
}

function closeNodeSettingsModal() {
    document.getElementById('node-settings-modal').classList.remove('show');
    currentSettingsNode = null;
}

function saveNodeSettings() {
    if (!currentSettingsNode) return;

    // 基本設定を更新
    const newText = document.getElementById('settings-node-text').value;
    const newScript = document.getElementById('settings-node-script').value;

    currentSettingsNode.text = newText;
    currentSettingsNode.script = newScript;

    // カスタムフィールドを保存
    if (currentSettingsNode.処理番号 === '1-2') {
        const conditionExpression = document.getElementById('condition-expression');
        if (conditionExpression) {
            currentSettingsNode.conditionExpression = conditionExpression.value;
        }
    } else if (currentSettingsNode.処理番号 === '1-3') {
        const loopCount = document.getElementById('loop-count');
        const loopVariable = document.getElementById('loop-variable');
        if (loopCount) currentSettingsNode.loopCount = parseInt(loopCount.value);
        if (loopVariable) currentSettingsNode.loopVariable = loopVariable.value;
    }

    // グローバルノード配列も更新
    const globalNodeIndex = nodes.findIndex(n => n.id === currentSettingsNode.id);
    if (globalNodeIndex !== -1) {
        nodes[globalNodeIndex] = Object.assign({}, currentSettingsNode);
    }

    // 再描画
    renderNodesInLayer(currentLayer);

    // memory.json自動保存
    saveMemoryJson();

    console.log(`ノード「${currentSettingsNode.text}」の設定を更新しました`);
    alert('設定を保存しました。');

    closeNodeSettingsModal();
}

// ============================================
// Phase 3: 整合性チェック（バリデーション）
// ============================================

/**
 * 同色ブロック衝突チェック
 * オリジナル: archive/02-4_ボタン操作配置.ps1:16-71 (10_ボタンの一覧取得)
 */
function checkSameColorCollision(nodeColor, currentY, newY, movingNodeId) {
    // SpringGreenまたはLemonChiffonのみチェック対象
    if (nodeColor !== 'SpringGreen' && nodeColor !== 'LemonChiffon') {
        return false;
    }

    const layerNodes = layerStructure[currentLayer].nodes;
    const minY = Math.min(currentY, newY);
    const maxY = Math.max(currentY, newY);

    // 移動範囲内に同色のノードが存在するかチェック
    for (const node of layerNodes) {
        const nodeY = node.y;
        const nodeColorNormalized = node.color;

        // 自分自身は除外
        if (node.id === movingNodeId) continue;

        // 移動範囲内にあるかチェック
        if (nodeY >= minY && nodeY <= maxY) {
            // 同色かチェック
            if (nodeColor === 'SpringGreen' && nodeColorNormalized === 'SpringGreen') {
                console.log(`[同色衝突] SpringGreenノード "${node.text}" と衝突`);
                return true;
            }
            if (nodeColor === 'LemonChiffon' && nodeColorNormalized === 'LemonChiffon') {
                console.log(`[同色衝突] LemonChiffonノード "${node.text}" と衝突`);
                return true;
            }
        }
    }

    return false;
}

/**
 * ネスト禁止チェック
 * オリジナル: 02-2_ネスト規制バリデーション_v2.ps1:280-488 (ドロップ禁止チェック_ネスト規制_v2)
 */
function validateNesting(movingNode, newY) {
    const layerNodes = layerStructure[currentLayer].nodes;
    const nodeColor = movingNode.color;

    // 色の正規化
    const isGreen = (nodeColor === 'SpringGreen' || nodeColor === 'Green');
    const isYellow = (nodeColor === 'LemonChiffon' || nodeColor === 'Yellow');

    // 全条件分岐ブロック範囲と全ループブロック範囲を取得
    const allCondRanges = getAllGroupRanges(layerNodes, 'SpringGreen');
    const allLoopRanges = getAllGroupRanges(layerNodes, 'LemonChiffon');

    // ============================
    // 1. 単体ノードが腹に落ちるケースの即時チェック
    // ============================

    if (isYellow) {
        // ループノードを条件分岐の腹の中に入れるのは禁止
        for (const cr of allCondRanges) {
            if (newY >= cr.topY && newY <= cr.bottomY) {
                return {
                    isProhibited: true,
                    reason: 'ループノードを条件分岐の内部に配置することはできません',
                    violationType: 'loop_in_conditional',
                    conflictGroupId: cr.groupId
                };
            }
        }
    } else if (isGreen) {
        // 条件分岐ノードをループの腹に刺すのは禁止
        for (const lr of allLoopRanges) {
            if (newY >= lr.topY && newY <= lr.bottomY) {
                return {
                    isProhibited: true,
                    reason: '条件分岐ノードをループの内部に配置することはできません',
                    violationType: 'conditional_in_loop',
                    conflictGroupId: lr.groupId
                };
            }
        }
    }

    // ============================
    // 2. グループ分断チェック
    // ============================

    if (isGreen) {
        // 条件分岐グループがループの境界をまたぐかチェック
        const isFragmented = checkGroupFragmentation(
            layerNodes,
            movingNode.id,
            newY,
            'SpringGreen',
            'LemonChiffon'
        );

        if (isFragmented) {
            return {
                isProhibited: true,
                reason: '条件分岐グループがループの境界をまたぐことはできません（グループ分断）',
                violationType: 'group_fragmentation',
                groupType: 'conditional'
            };
        }
    }

    if (isYellow) {
        // ループグループが条件分岐の境界をまたぐかチェック
        const isFragmented = checkGroupFragmentation(
            layerNodes,
            movingNode.id,
            newY,
            'LemonChiffon',
            'SpringGreen'
        );

        if (isFragmented) {
            return {
                isProhibited: true,
                reason: 'ループグループが条件分岐の境界をまたぐことはできません（グループ分断）',
                violationType: 'group_fragmentation',
                groupType: 'loop'
            };
        }
    }

    // ============================
    // 3. グループ全体としての整合性チェック
    // ============================

    if (isGreen) {
        // この条件分岐グループが移動後どういう縦範囲になるか
        const movedCondRange = getGroupRangeAfterMove(layerNodes, movingNode.id, newY);

        if (movedCondRange) {
            for (const lr of allLoopRanges) {
                const isPairIllegal = isIllegalPair(movedCondRange, lr);
                if (isPairIllegal) {
                    return {
                        isProhibited: true,
                        reason: '条件分岐とループの配置が不正です（交差または包含関係の違反）',
                        violationType: 'illegal_nesting',
                        conflictGroupId: lr.groupId
                    };
                }
            }
        }
    }

    if (isYellow) {
        // このループグループが移動後どういう縦範囲になるか
        const movedLoopRange = getGroupRangeAfterMove(layerNodes, movingNode.id, newY);

        if (movedLoopRange) {
            for (const cr of allCondRanges) {
                const isPairIllegal = isIllegalPair(cr, movedLoopRange);
                if (isPairIllegal) {
                    return {
                        isProhibited: true,
                        reason: 'ループと条件分岐の配置が不正です（交差または包含関係の違反）',
                        violationType: 'illegal_nesting',
                        conflictGroupId: cr.groupId
                    };
                }
            }
        }
    }

    // ドロップ可能
    return {
        isProhibited: false,
        message: 'ドロップ可能です'
    };
}

/**
 * 移動後のグループ範囲を計算
 * オリジナル: 02-2_ネスト規制バリデーション_v2.ps1:23-84
 */
function getGroupRangeAfterMove(layerNodes, movingNodeId, newY) {
    const movingNode = layerNodes.find(n => n.id === movingNodeId);
    if (!movingNode || !movingNode.groupId) return null;

    const gid = movingNode.groupId;

    // 同じGroupIDの全ノードを集める（色に関係なく）
    const sameGroupNodes = layerNodes.filter(n =>
        n.groupId !== null && n.groupId.toString() === gid.toString()
    );

    if (sameGroupNodes.length < 2) return null;

    // 各ノードのY座標を取得（移動中のノードは新しいY座標を使用）
    const yList = sameGroupNodes.map(node =>
        node.id === movingNodeId ? newY : node.y
    );

    const topY = Math.min(...yList);
    const bottomY = Math.max(...yList);

    return {
        groupId: gid,
        topY: topY,
        bottomY: bottomY
    };
}

/**
 * 指定色のすべてのグループ範囲を取得
 * オリジナル: 02-2_ネスト規制バリデーション_v2.ps1:87-146
 */
function getAllGroupRanges(layerNodes, targetColor) {
    // 色でフィルタ
    const colorNodes = layerNodes.filter(n =>
        n.color !== null && n.color === targetColor
    );

    // GroupIDでグループ化
    const groupedByGroupId = {};
    colorNodes.forEach(node => {
        const gid = node.groupId;
        if (gid !== null) {
            if (!groupedByGroupId[gid]) {
                groupedByGroupId[gid] = [];
            }
            groupedByGroupId[gid].push(node);
        }
    });

    const ranges = [];

    for (const gid in groupedByGroupId) {
        const group = groupedByGroupId[gid];
        if (group.length < 1) continue;

        // そのGroupIDの全ノード（色に関係なく）を取得
        // 条件分岐の中間ノード(Gray)も含めるため
        const allNodesInGroup = layerNodes.filter(n =>
            n.groupId !== null && n.groupId.toString() === gid.toString()
        );

        if (allNodesInGroup.length < 2) continue;

        const sorted = allNodesInGroup.sort((a, b) => a.y - b.y);
        const topY = sorted[0].y;
        const bottomY = sorted[sorted.length - 1].y;

        ranges.push({
            groupId: gid,
            topY: topY,
            bottomY: bottomY
        });
    }

    return ranges;
}

/**
 * 2つの範囲の違法性を判定
 * オリジナル: 02-2_ネスト規制バリデーション_v2.ps1:149-198
 */
function isIllegalPair(condRange, loopRange) {
    if (!condRange || !loopRange) return false;

    const cTop = condRange.topY;
    const cBot = condRange.bottomY;
    const lTop = loopRange.topY;
    const lBot = loopRange.bottomY;

    // まず重なってるかどうか
    const overlap = (cBot > lTop) && (cTop < lBot);
    if (!overlap) {
        // 完全に上下に離れてる → OK
        return false;
    }

    // 条件分岐がループの完全内側ならOK
    const condInsideLoop = (cTop >= lTop) && (cBot <= lBot);
    if (condInsideLoop) {
        // OK (ループが外側、条件分岐が内側) は合法
        return false;
    }

    // それ以外の重なりはダメ
    // - 交差 (片足だけ突っ込んでる)
    // - ループが条件分岐の内側に丸ごと入る
    return true;
}

/**
 * グループ分断をチェック
 * オリジナル: 02-2_ネスト規制バリデーション_v2.ps1:201-277
 */
function checkGroupFragmentation(layerNodes, movingNodeId, newY, groupColor, boundaryColor) {
    const movingNode = layerNodes.find(n => n.id === movingNodeId);
    if (!movingNode || !movingNode.groupId) return false;

    const gid = movingNode.groupId;

    // 同じGroupIDの全ノードを取得（色に関係なく）
    const sameGroupNodes = layerNodes.filter(n =>
        n.groupId !== null && n.groupId.toString() === gid.toString()
    );

    if (sameGroupNodes.length < 2) return false;

    // 境界色のグループ範囲を全て取得
    const boundaryRanges = getAllGroupRanges(layerNodes, boundaryColor);

    for (const br of boundaryRanges) {
        let insideCount = 0;
        let outsideCount = 0;

        // グループ内の各ノードが境界の内側か外側かチェック
        for (const node of sameGroupNodes) {
            const nodeY = (node.id === movingNodeId) ? newY : node.y;

            if (nodeY >= br.topY && nodeY <= br.bottomY) {
                insideCount++;
            } else {
                outsideCount++;
            }
        }

        // 一部が内側、一部が外側 = グループ分断 = 禁止
        if (insideCount > 0 && outsideCount > 0) {
            return true;
        }
    }

    return false;
}

// ============================================
// イベントリスナー設定
// ============================================

function setupEventListeners() {
    // ドキュメント全体のクリックで右クリックメニューを閉じる
    document.addEventListener('click', () => {
        hideContextMenu();
    });

    // キーボードショートカット
    document.addEventListener('keydown', (e) => {
        // ESCキーでモーダルを閉じる
        if (e.key === 'Escape') {
            closeVariableModal();
            closeFolderModal();
            closeScriptModal();
            closeNodeSettingsModal();
            closeCodeResultModal();
            hideContextMenu();
            return;
        }

        // モーダルが開いている場合は他のショートカットを無効化
        const anyModalOpen = document.querySelector('.modal.show');
        if (anyModalOpen) return;

        // 左右矢印キーでレイヤーナビゲーション
        if (e.key === 'ArrowLeft' && !e.ctrlKey && !e.shiftKey && !e.altKey) {
            navigateLayer('left');
            e.preventDefault();
            return;
        }
        if (e.key === 'ArrowRight' && !e.ctrlKey && !e.shiftKey && !e.altKey) {
            navigateLayer('right');
            e.preventDefault();
            return;
        }

        // Ctrl+S: 保存（memory.json自動保存）
        if (e.key === 's' && e.ctrlKey && !e.shiftKey && !e.altKey) {
            e.preventDefault();
            saveMemoryJson();
            alert('💾 memory.json を保存しました');
            return;
        }

        // Ctrl+E: コード生成実行
        if (e.key === 'e' && e.ctrlKey && !e.shiftKey && !e.altKey) {
            e.preventDefault();
            executeCode();
            return;
        }

        // Ctrl+Shift+V: 変数管理を開く
        if (e.key === 'V' && e.ctrlKey && e.shiftKey && !e.altKey) {
            e.preventDefault();
            openVariableModal();
            return;
        }

        // Delete: 選択中のノードを削除（コンテキストメニューが表示されている場合）
        if (e.key === 'Delete' && contextMenuTarget) {
            e.preventDefault();
            deleteNode();
            return;
        }

        // Ctrl+Z: Undo（将来機能）
        if (e.key === 'z' && e.ctrlKey && !e.shiftKey && !e.altKey) {
            e.preventDefault();
            alert('⚠️ Undo機能は将来実装予定です');
            return;
        }

        // Ctrl+Y: Redo（将来機能）
        if (e.key === 'y' && e.ctrlKey && !e.shiftKey && !e.altKey) {
            e.preventDefault();
            alert('⚠️ Redo機能は将来実装予定です');
            return;
        }
    });

    // レイヤーパネルへのドラッグ&ドロップイベント設定
    document.querySelectorAll('.node-list-container').forEach(container => {
        container.addEventListener('dragover', handleDragOver);
        container.addEventListener('drop', handleDrop);
    });

    console.log('📌 キーボードショートカット有効化:');
    console.log('  ← / →: レイヤー移動');
    console.log('  Ctrl+S: 保存');
    console.log('  Ctrl+E: コード生成');
    console.log('  Ctrl+Shift+V: 変数管理');
    console.log('  Delete: ノード削除');
    console.log('  Esc: モーダルを閉じる');
}

// ============================================
// ダイアログのイベントリスナー設定（DOM ready後に呼び出し）
// ============================================
function setupDialogEventListeners() {
    // ============================================
    // 条件分岐ダイアログのイベントリスナー
    // ============================================

    const btnAddCondition = document.getElementById('btn-add-condition');
    if (btnAddCondition) {
        btnAddCondition.addEventListener('click', addConditionRow);
    }

    const btnConditionSave = document.getElementById('btn-condition-save');
    if (btnConditionSave) {
        btnConditionSave.addEventListener('click', () => {
            console.log('[条件分岐ダイアログ] 保存ボタンがクリックされました');
            let code = document.getElementById('condition-preview').value;

            if (!code || code.trim() === '') {
                console.warn('[条件分岐ダイアログ] 条件式が空です');
                alert('条件式が設定されていません。');
                return;
            }

            // コメント行を "---" に置換（PowerShell互換）
            const lines = code.split('\n');
            const processedLines = lines.map(line => {
                if (line.trim().startsWith('#')) {
                    return '---';
                }
                return line;
            });
            code = processedLines.join('\n');

            console.log('[条件分岐ダイアログ] 保存するコード:', code);
            console.log('[条件分岐ダイアログ] conditionBuilderResolver:', conditionBuilderResolver ? '存在' : 'null');

            document.getElementById('condition-builder-modal').classList.remove('show');

            if (conditionBuilderResolver) {
                console.log('[条件分岐ダイアログ] resolverを呼び出します');
                conditionBuilderResolver(code);
                conditionBuilderResolver = null;
            } else {
                console.error('[条件分岐ダイアログ] エラー: conditionBuilderResolverがnullです');
            }
        });
    }

    const btnConditionCancel = document.getElementById('btn-condition-cancel');
    if (btnConditionCancel) {
        btnConditionCancel.addEventListener('click', () => {
            console.log('[条件分岐ダイアログ] キャンセル');

            document.getElementById('condition-builder-modal').classList.remove('show');

            if (conditionBuilderResolver) {
                conditionBuilderResolver(null);
                conditionBuilderResolver = null;
            }
        });
    }

    // ============================================
    // ループダイアログのイベントリスナー
    // ============================================

    const loopTypeSelect = document.getElementById('loop-type-select');
    if (loopTypeSelect) {
        loopTypeSelect.addEventListener('change', updateLoopSettings);
    }

    const btnLoopSave = document.getElementById('btn-loop-save');
    if (btnLoopSave) {
        btnLoopSave.addEventListener('click', () => {
            console.log('[ループダイアログ] 保存ボタンがクリックされました');
            let code = document.getElementById('loop-preview').value;

            if (!code || code.trim() === '') {
                console.warn('[ループダイアログ] ループ構文が空です');
                alert('ループ構文が設定されていません。');
                return;
            }

            // コメント行を "---" に置換（PowerShell互換）
            const lines = code.split('\n');
            const processedLines = lines.map(line => {
                if (line.trim().startsWith('#')) {
                    return '---';
                }
                return line;
            });
            code = processedLines.join('\n');

            console.log('[ループダイアログ] 保存するコード:', code);
            console.log('[ループダイアログ] loopBuilderResolver:', loopBuilderResolver ? '存在' : 'null');

            document.getElementById('loop-builder-modal').classList.remove('show');

            if (loopBuilderResolver) {
                console.log('[ループダイアログ] resolverを呼び出します');
                loopBuilderResolver(code);
                loopBuilderResolver = null;
            } else {
                console.error('[ループダイアログ] エラー: loopBuilderResolverがnullです');
            }
        });
    }

    const btnLoopCancel = document.getElementById('btn-loop-cancel');
    if (btnLoopCancel) {
        btnLoopCancel.addEventListener('click', () => {
            console.log('[ループダイアログ] キャンセル');

            document.getElementById('loop-builder-modal').classList.remove('show');

            if (loopBuilderResolver) {
                loopBuilderResolver(null);
                loopBuilderResolver = null;
            }
        });
    }

    console.log('📌 ダイアログイベントリスナー設定完了');
}

// ============================================
// 変数管理機能（variables.json）
// ============================================

let variablesData = {};

// variables.jsonを読み込む
async function loadVariablesJson() {
    if (!currentFolder) {
        console.warn('フォルダが選択されていないため、variables.json読み込みをスキップします');
        return;
    }

    try {
        const response = await fetch(`${API_BASE}/folders/${currentFolder}/variables`);
        const result = await response.json();

        if (result.success) {
            variablesData = result.data || {};
            console.log('variables.json読み込み成功:', variablesData);
        } else {
            variablesData = {};
        }
    } catch (error) {
        console.error('variables.json読み込みエラー:', error);
        variablesData = {};
    }
}

// 単一値変数のリストを取得
function getSingleValueVariables() {
    const singleValueVars = [];

    for (const key in variablesData) {
        const value = variablesData[key];
        // 配列でない場合は単一値変数
        if (!Array.isArray(value)) {
            singleValueVars.push('$' + key);
        }
    }

    return singleValueVars;
}

// 配列変数のリストを取得
function getArrayVariables() {
    const arrayVars = [];

    for (const key in variablesData) {
        const value = variablesData[key];
        // 配列の場合
        if (Array.isArray(value)) {
            arrayVars.push('$' + key);
        }
    }

    return arrayVars;
}

// ============================================
// コード生成関数（PowerShell互換）
// ============================================

// 1_1: 順次処理
function generate_1_1() {
    return 'Write-Host "OK"';
}

// 1_6: メッセージボックス表示
function generate_1_6() {
    return `Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show("これはメッセージボックスです。", "タイトル", "OK", "Information")`;
}

// 99_1: カスタム処理（AAAA_プレフィックス）
function generate_99_1(直接エントリ) {
    if (!直接エントリ) {
        return 'Write-Host "カスタム処理"';
    }

    const entryWithPrefix = "AAAA_" + 直接エントリ;
    // アンダースコアを改行に置換
    const processedEntry = entryWithPrefix.replace(/_/g, '\r\n');

    return processedEntry;
}

// ============================================
// コード生成エンジン本体
// ============================================

// 処理番号から関数名を取得
function getFunctionNameFromProcessingNumber(処理番号) {
    const setting = buttonSettings.find(s => s.処理番号 === 処理番号);
    return setting ? setting.関数名 : null;
}

// コード生成関数のマッピング
const codeGeneratorFunctions = {
    'ShowConditionBuilder': showConditionBuilderDialog,
    'ShowLoopBuilder': showLoopBuilderDialog,
    '1_1': generate_1_1,
    '1_6': generate_1_6,
    '99_1': generate_99_1
};

// コード生成のメイン関数
async function generateCode(処理番号, ボタン名, 直接エントリ = null) {
    try {
        console.log(`[コード生成] 開始 - 処理番号: ${処理番号}, ボタン名: ${ボタン名}`);
        console.log(`[コード生成] buttonSettings数: ${buttonSettings.length}`);

        // 処理番号から関数名を取得
        const 関数名 = getFunctionNameFromProcessingNumber(処理番号);

        if (!関数名) {
            console.error(`[コード生成] エラー: 処理番号 ${処理番号} に対応する関数名が見つかりません`);
            console.error(`[コード生成] buttonSettings:`, buttonSettings);
            return null;
        }

        console.log(`[コード生成] 関数名: ${関数名}`);

        // 関数を実行
        const generatorFunc = codeGeneratorFunctions[関数名];

        if (!generatorFunc) {
            console.warn(`[コード生成] 警告: 関数 ${関数名} は未実装です`);
            console.warn(`[コード生成] 利用可能な関数:`, Object.keys(codeGeneratorFunctions));
            return null;
        }

        console.log(`[コード生成] 関数を実行します: ${関数名}`);

        let entryString = null;

        // 特殊処理: 99-1の場合は直接エントリを渡す
        if (処理番号 === '99-1') {
            entryString = generatorFunc(直接エントリ);
        } else {
            // ダイアログを表示する場合は await
            if (関数名 === 'ShowConditionBuilder' || 関数名 === 'ShowLoopBuilder') {
                console.log(`[コード生成] ダイアログを表示します`);
                entryString = await generatorFunc();
            } else {
                entryString = generatorFunc();
            }
        }

        console.log(`[コード生成] 生成されたコード:`, entryString);

        // ユーザーがキャンセルした場合
        if (entryString === null || entryString === undefined) {
            console.log('[コード生成] ユーザーがキャンセルしました');
            return null;
        }

        // 空文字列チェック
        if (entryString.trim() === '') {
            console.error('[コード生成] エラー: 生成されたコードが空です');
            return null;
        }

        // コード.jsonに保存
        console.log(`[コード生成] コード.jsonに保存します - ID: ${ボタン名}`);
        await setCodeEntry(ボタン名, entryString);

        console.log(`[コード生成] 成功: ID ${ボタン名} に保存しました`);
        return entryString;
    } catch (error) {
        console.error('[コード生成] エラーが発生しました:', error);
        console.error('[コード生成] スタックトレース:', error.stack);
        return null;
    }
}

// ============================================
// ShowConditionBuilder ダイアログ
// ============================================

let conditionBuilderResolver = null;
let conditionBuilderIsFromLoop = false;
let conditionControls = [];

// 条件分岐ダイアログを表示
function showConditionBuilderDialog(isFromLoopBuilder = false) {
    return new Promise((resolve) => {
        conditionBuilderResolver = resolve;
        conditionBuilderIsFromLoop = isFromLoopBuilder;
        conditionControls = [];

        // モーダルを表示
        const modal = document.getElementById('condition-builder-modal');
        modal.classList.add('show');

        // コンテナをクリア
        const container = document.getElementById('condition-items-container');
        container.innerHTML = '';

        // プレビューをクリア
        document.getElementById('condition-preview').value = '';

        // 最初の条件を追加
        addConditionRow();

        console.log('[条件分岐ダイアログ] 表示しました');
    });
}

// 条件行を追加
function addConditionRow() {
    const container = document.getElementById('condition-items-container');
    const index = conditionControls.length;

    const row = document.createElement('div');
    row.className = 'condition-row';
    row.style.cssText = 'margin-bottom: 20px; padding: 15px; border: 1px solid #ddd; border-radius: 4px; background-color: #fafafa;';

    // 論理演算子（2行目以降）
    let logicalOperatorHtml = '';
    if (index > 0) {
        logicalOperatorHtml = `
            <div style="margin-bottom: 10px;">
                <select class="logical-operator" style="padding: 5px;">
                    <option value="-and">-and</option>
                    <option value="-or">-or</option>
                </select>
            </div>
        `;
    }

    row.innerHTML = `
        ${logicalOperatorHtml}
        <div style="display: flex; gap: 10px; align-items: center; margin-bottom: 10px;">
            <div style="flex: 1;">
                <label style="display: block; margin-bottom: 5px; font-weight: bold;">左辺</label>
                <div>
                    <label style="display: block; margin-bottom: 5px;">
                        <input type="checkbox" class="left-use-variable"> 変数を使用
                    </label>
                    <input type="text" class="left-value" placeholder="値を入力" style="width: 100%; padding: 5px; display: block;">
                    <select class="left-variable" style="width: 100%; padding: 5px; display: none;"></select>
                </div>
            </div>

            <div style="width: 100px;">
                <label style="display: block; margin-bottom: 5px; font-weight: bold;">演算子</label>
                <select class="operator" style="width: 100%; padding: 5px;">
                    <option value="-eq">-eq</option>
                    <option value="-ne">-ne</option>
                    <option value="-lt">-lt</option>
                    <option value="-gt">-gt</option>
                    <option value="-like">-like</option>
                    <option value="-notlike">-notlike</option>
                </select>
            </div>

            <div style="flex: 1;">
                <label style="display: block; margin-bottom: 5px; font-weight: bold;">右辺</label>
                <div>
                    <label style="display: block; margin-bottom: 5px;">
                        <input type="checkbox" class="right-use-variable"> 変数を使用
                    </label>
                    <input type="text" class="right-value" placeholder="値を入力" style="width: 100%; padding: 5px; display: block;">
                    <select class="right-variable" style="width: 100%; padding: 5px; display: none;"></select>
                </div>
            </div>

            ${index > 0 ? '<button class="btn-delete-condition button" style="align-self: flex-end; background-color: #dc3545;">削除</button>' : ''}
        </div>
    `;

    container.appendChild(row);

    // 変数リストを設定
    const leftVarSelect = row.querySelector('.left-variable');
    const rightVarSelect = row.querySelector('.right-variable');
    const variables = getSingleValueVariables();

    variables.forEach(v => {
        const option1 = document.createElement('option');
        option1.value = v;
        option1.textContent = v;
        leftVarSelect.appendChild(option1);

        const option2 = document.createElement('option');
        option2.value = v;
        option2.textContent = v;
        rightVarSelect.appendChild(option2);
    });

    // イベントリスナーを設定
    const leftUseVar = row.querySelector('.left-use-variable');
    const leftValue = row.querySelector('.left-value');
    const leftVariable = row.querySelector('.left-variable');

    leftUseVar.addEventListener('change', () => {
        if (leftUseVar.checked) {
            leftValue.style.display = 'none';
            leftVariable.style.display = 'block';
        } else {
            leftValue.style.display = 'block';
            leftVariable.style.display = 'none';
        }
        updateConditionPreview();
    });

    const rightUseVar = row.querySelector('.right-use-variable');
    const rightValue = row.querySelector('.right-value');
    const rightVariable = row.querySelector('.right-variable');

    rightUseVar.addEventListener('change', () => {
        if (rightUseVar.checked) {
            rightValue.style.display = 'none';
            rightVariable.style.display = 'block';
        } else {
            rightValue.style.display = 'block';
            rightVariable.style.display = 'none';
        }
        updateConditionPreview();
    });

    // プレビュー更新
    row.querySelectorAll('input, select').forEach(el => {
        el.addEventListener('input', updateConditionPreview);
        el.addEventListener('change', updateConditionPreview);
    });

    // 削除ボタン
    const deleteBtn = row.querySelector('.btn-delete-condition');
    if (deleteBtn) {
        deleteBtn.addEventListener('click', () => {
            if (conditionControls.length <= 1) {
                alert('最低一つの条件が必要です。');
                return;
            }
            row.remove();
            conditionControls = Array.from(container.querySelectorAll('.condition-row'));
            updateConditionPreview();
        });
    }

    conditionControls.push(row);
}

// 条件式プレビューを更新
function updateConditionPreview() {
    const container = document.getElementById('condition-items-container');
    const rows = container.querySelectorAll('.condition-row');

    let fullCondition = '';

    rows.forEach((row, index) => {
        const leftUseVar = row.querySelector('.left-use-variable').checked;
        const leftValue = row.querySelector('.left-value').value.trim();
        const leftVariable = row.querySelector('.left-variable').value;

        const operator = row.querySelector('.operator').value;

        const rightUseVar = row.querySelector('.right-use-variable').checked;
        const rightValue = row.querySelector('.right-value').value.trim();
        const rightVariable = row.querySelector('.right-variable').value;

        // 左辺
        const leftOperand = leftUseVar ? leftVariable : (leftValue ? `"${leftValue}"` : '');

        // 右辺
        const rightOperand = rightUseVar ? rightVariable : (rightValue ? `"${rightValue}"` : '');

        if (!leftOperand || !operator || !rightOperand) {
            return;
        }

        const condition = `${leftOperand} ${operator} ${rightOperand}`;

        if (index === 0) {
            fullCondition = condition;
        } else {
            const logicalOperator = row.querySelector('.logical-operator').value;
            fullCondition = `(${fullCondition}) ${logicalOperator} (${condition})`;
        }
    });

    // プレビュー表示
    const preview = document.getElementById('condition-preview');

    if (conditionBuilderIsFromLoop) {
        // ループビルダーからの呼び出し: 条件式のみ
        preview.value = fullCondition;
    } else {
        // 通常: if-else 構文
        preview.value = `if (${fullCondition}) {\n    # Trueの処理内容\n} else {\n    # Falseの処理内容\n}`;
    }
}

// 🔧 修正: イベントリスナーは setupDialogEventListeners() で設定される（DOM ready後）

// ============================================
// ShowLoopBuilder ダイアログ
// ============================================

let loopBuilderResolver = null;
let loopConditionExpression = '';

// ループダイアログを表示
function showLoopBuilderDialog() {
    return new Promise((resolve) => {
        loopBuilderResolver = resolve;
        loopConditionExpression = '';

        // モーダルを表示
        const modal = document.getElementById('loop-builder-modal');
        modal.classList.add('show');

        // 初期表示
        const loopTypeSelect = document.getElementById('loop-type-select');
        loopTypeSelect.value = 'for';
        updateLoopSettings();

        console.log('[ループダイアログ] 表示しました');
    });
}

// ループタイプに応じた設定フィールドを更新
function updateLoopSettings() {
    const loopType = document.getElementById('loop-type-select').value;
    const container = document.getElementById('loop-settings-container');

    container.innerHTML = '';

    if (loopType === 'for') {
        // 固定回数ループ
        container.innerHTML = `
            <div style="margin-bottom: 10px;">
                <label>カウンタ変数名:</label>
                <input type="text" id="loop-counter-var" value="$i" style="width: 100%; padding: 5px; margin-top: 5px;">
            </div>
            <div style="margin-bottom: 10px;">
                <label>開始値:</label>
                <div style="display: flex; gap: 10px; align-items: center; margin-top: 5px;">
                    <input type="text" id="loop-start-value" value="0" style="flex: 1; padding: 5px;">
                    <label><input type="checkbox" id="loop-start-use-var"> 変数を使用</label>
                </div>
                <select id="loop-start-var" style="width: 100%; padding: 5px; margin-top: 5px; display: none;"></select>
            </div>
            <div style="margin-bottom: 10px;">
                <label>終了値:</label>
                <div style="display: flex; gap: 10px; align-items: center; margin-top: 5px;">
                    <input type="text" id="loop-end-value" value="10" style="flex: 1; padding: 5px;">
                    <label><input type="checkbox" id="loop-end-use-var"> 変数を使用</label>
                </div>
                <select id="loop-end-var" style="width: 100%; padding: 5px; margin-top: 5px; display: none;"></select>
            </div>
            <div style="margin-bottom: 10px;">
                <label>増分値:</label>
                <input type="text" id="loop-increment" value="1" style="width: 100%; padding: 5px; margin-top: 5px;">
            </div>
        `;

        // 変数リストを設定
        const variables = getSingleValueVariables();
        const startVarSelect = document.getElementById('loop-start-var');
        const endVarSelect = document.getElementById('loop-end-var');

        variables.forEach(v => {
            const option1 = document.createElement('option');
            option1.value = v;
            option1.textContent = v;
            startVarSelect.appendChild(option1);

            const option2 = document.createElement('option');
            option2.value = v;
            option2.textContent = v;
            endVarSelect.appendChild(option2);
        });

        // イベントリスナー
        document.getElementById('loop-start-use-var').addEventListener('change', (e) => {
            document.getElementById('loop-start-value').style.display = e.target.checked ? 'none' : 'block';
            document.getElementById('loop-start-var').style.display = e.target.checked ? 'block' : 'none';
            updateLoopPreview();
        });

        document.getElementById('loop-end-use-var').addEventListener('change', (e) => {
            document.getElementById('loop-end-value').style.display = e.target.checked ? 'none' : 'block';
            document.getElementById('loop-end-var').style.display = e.target.checked ? 'block' : 'none';
            updateLoopPreview();
        });

        container.querySelectorAll('input, select').forEach(el => {
            el.addEventListener('input', updateLoopPreview);
            el.addEventListener('change', updateLoopPreview);
        });

    } else if (loopType === 'foreach') {
        // コレクションのループ
        container.innerHTML = `
            <div style="margin-bottom: 10px;">
                <label>要素変数名:</label>
                <input type="text" id="loop-element-var" value="$item" style="width: 100%; padding: 5px; margin-top: 5px;">
            </div>
            <div style="margin-bottom: 10px;">
                <label>コレクション変数:</label>
                <select id="loop-collection-var" style="width: 100%; padding: 5px; margin-top: 5px;"></select>
            </div>
        `;

        // 配列変数リストを設定
        const arrayVars = getArrayVariables();
        const collectionSelect = document.getElementById('loop-collection-var');

        arrayVars.forEach(v => {
            const option = document.createElement('option');
            option.value = v;
            option.textContent = v;
            collectionSelect.appendChild(option);
        });

        container.querySelectorAll('input, select').forEach(el => {
            el.addEventListener('input', updateLoopPreview);
            el.addEventListener('change', updateLoopPreview);
        });

    } else if (loopType === 'while') {
        // 条件付きループ
        container.innerHTML = `
            <div style="margin-bottom: 10px;">
                <label>ループの種類:</label>
                <select id="loop-condition-type" style="width: 100%; padding: 5px; margin-top: 5px;">
                    <option value="while">while</option>
                    <option value="do-while">do-while</option>
                </select>
            </div>
            <div style="margin-bottom: 10px;">
                <button id="btn-set-loop-condition" class="button">条件式を設定</button>
                <div id="loop-condition-display" style="margin-top: 5px; padding: 10px; background-color: #f5f5f5; border: 1px solid #ddd; border-radius: 4px; min-height: 30px;">
                    条件式: （未設定）
                </div>
            </div>
        `;

        document.getElementById('btn-set-loop-condition').addEventListener('click', async () => {
            const condition = await showConditionBuilderDialog(true);
            if (condition) {
                loopConditionExpression = condition;
                document.getElementById('loop-condition-display').textContent = `条件式: ${condition}`;
                updateLoopPreview();
            }
        });

        document.getElementById('loop-condition-type').addEventListener('change', updateLoopPreview);
    }

    updateLoopPreview();
}

// ループ構文プレビューを更新
function updateLoopPreview() {
    const loopType = document.getElementById('loop-type-select').value;
    const preview = document.getElementById('loop-preview');

    let code = '';

    if (loopType === 'for') {
        const counterVar = document.getElementById('loop-counter-var')?.value || '$i';
        const startUseVar = document.getElementById('loop-start-use-var')?.checked;
        const startValue = startUseVar
            ? document.getElementById('loop-start-var')?.value
            : document.getElementById('loop-start-value')?.value || '0';
        const endUseVar = document.getElementById('loop-end-use-var')?.checked;
        const endValue = endUseVar
            ? document.getElementById('loop-end-var')?.value
            : document.getElementById('loop-end-value')?.value || '10';
        const increment = document.getElementById('loop-increment')?.value || '1';

        if (counterVar && startValue && endValue && increment) {
            code = `for (${counterVar} = ${startValue}; ${counterVar} -lt ${endValue}; ${counterVar} += ${increment}) {\n    # 処理内容\n}`;
        }

    } else if (loopType === 'foreach') {
        const elementVar = document.getElementById('loop-element-var')?.value || '$item';
        const collectionVar = document.getElementById('loop-collection-var')?.value;

        if (elementVar && collectionVar) {
            code = `foreach (${elementVar} in ${collectionVar}) {\n    # 処理内容\n}`;
        }

    } else if (loopType === 'while') {
        const conditionType = document.getElementById('loop-condition-type')?.value || 'while';
        const condition = loopConditionExpression;

        if (condition) {
            if (conditionType === 'while') {
                code = `while (${condition}) {\n    # 処理内容\n}`;
            } else if (conditionType === 'do-while') {
                code = `do {\n    # 処理内容\n} while (${condition})`;
            }
        }
    }

    preview.value = code;
}

// 🔧 修正: イベントリスナーは setupDialogEventListeners() で設定される（DOM ready後）
