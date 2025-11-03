// ============================================
// UIpowershell - Legacy UI JavaScript
// 既存Windows Forms版の完全再現
// ============================================

const API_BASE = 'http://localhost:8080/api';

// ============================================
// グローバル状態
// ============================================

let currentLayer = 1;           // 現在表示中のレイヤー (1-6)
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

    // 各レイヤーパネルにcanvas要素を追加
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

                // Canvasサイズを親要素に合わせる（内部サイズと表示サイズの両方を設定）
                canvas.width = nodeList.scrollWidth;
                canvas.height = nodeList.scrollHeight;
                canvas.style.width = `${nodeList.scrollWidth}px`;  // ★追加：CSS表示サイズ
                canvas.style.height = `${nodeList.scrollHeight}px`; // ★追加：CSS表示サイズ

                // node-list-containerを相対配置に
                nodeList.style.position = 'relative';
                nodeList.appendChild(canvas);

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

        // Canvasサイズを親要素に合わせる（内部サイズと表示サイズの両方を設定）
        canvas.width = mainContainer.scrollWidth;
        canvas.height = mainContainer.scrollHeight;
        canvas.style.width = `${mainContainer.scrollWidth}px`;  // ★追加：CSS表示サイズ
        canvas.style.height = `${mainContainer.scrollHeight}px`; // ★追加：CSS表示サイズ

        mainContainer.style.position = 'relative';
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

    // 矢印ヘッドを描画
    drawArrowHead(ctx, startX, startY, endX, endY);
}

// パネル内のノード間矢印を描画
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

        // scrollWidth/Heightを使用してコンテンツ全体をカバー
        canvas.width = Math.max(nodeListContainer.scrollWidth, nodeListContainer.clientWidth);
        canvas.height = Math.max(nodeListContainer.scrollHeight, nodeListContainer.clientHeight, 700); // 最小高さ700px

        // ★重要：CSS表示サイズも更新
        canvas.style.width = `${canvas.width}px`;
        canvas.style.height = `${canvas.height}px`;

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

    // 条件分岐の特別な矢印を描画
    conditionGroups.forEach(group => {
        drawConditionalBranchArrows(ctx, group.startNode, group.middleNode, group.endNode, nodes);
    });

    // ループの矢印を描画
    const loopGroups = findLoopGroups(nodes);
    console.log(`[デバッグ] ループグループ数: ${loopGroups.length}`);
    const containerRect = layerPanel.querySelector('.node-list-container').getBoundingClientRect();
    loopGroups.forEach(group => {
        drawLoopArrows(ctx, group.startNode, group.endNode, containerRect);
    });

    console.log(`[デバッグ] drawPanelArrows() 完了: ${layerId}`);
}

// 条件分岐グループを見つける
function findConditionGroups(nodes) {
    const groups = [];

    for (let i = 0; i < nodes.length; i++) {
        const node = nodes[i];
        const color = window.getComputedStyle(node).backgroundColor;
        const text = node.textContent.trim();

        if (isSpringGreenColor(color) && text.includes('条件分岐 開始')) {
            // 中間と終了を探す
            let middleNode = null;
            let endNode = null;

            for (let j = i + 1; j < nodes.length; j++) {
                const nextNode = nodes[j];
                const nextColor = window.getComputedStyle(nextNode).backgroundColor;
                const nextText = nextNode.textContent.trim();

                if (isSpringGreenColor(nextColor) || nextColor === 'rgb(128, 128, 128)') {
                    if (nextText.includes('条件分岐 中間')) {
                        middleNode = nextNode;
                    } else if (nextText.includes('条件分岐 終了')) {
                        endNode = nextNode;
                        break;
                    }
                }
            }

            if (middleNode && endNode) {
                groups.push({ startNode: node, middleNode, endNode });
            }
        }
    }

    return groups;
}

// 条件分岐の複雑な矢印を描画
function drawConditionalBranchArrows(ctx, startNode, middleNode, endNode, allNodes) {
    const containerRect = startNode.closest('.node-list-container').getBoundingClientRect();

    const startRect = startNode.getBoundingClientRect();
    const middleRect = middleNode.getBoundingClientRect();
    const endRect = endNode.getBoundingClientRect();

    // 開始ノードと終了ノードのインデックスを取得
    const startIndex = allNodes.indexOf(startNode);
    const middleIndex = allNodes.indexOf(middleNode);
    const endIndex = allNodes.indexOf(endNode);

    if (startIndex === -1 || middleIndex === -1 || endIndex === -1) return;

    // 開始と中間の間のノード（赤ブロック）
    const redNodes = [];
    for (let i = startIndex + 1; i < middleIndex; i++) {
        const node = allNodes[i];
        const color = window.getComputedStyle(node).backgroundColor;
        if (isSalmonColor(color)) {
            redNodes.push(node);
        }
    }

    // 中間と終了の間のノード（青ブロック）
    const blueNodes = [];
    for (let i = middleIndex + 1; i < endIndex; i++) {
        const node = allNodes[i];
        const color = window.getComputedStyle(node).backgroundColor;
        if (isBlueColor(color)) {
            blueNodes.push(node);
        }
    }

    // 緑→青の矢印（開始から右に出て青ブロックへ）
    if (blueNodes.length > 0) {
        const firstBlue = blueNodes[0];
        const firstBlueRect = firstBlue.getBoundingClientRect();

        const startX = startRect.right - containerRect.left;
        const startY = startRect.top + startRect.height / 2 - containerRect.top;
        const horizontalEndX = startX + 20;
        const blueY = firstBlueRect.top + firstBlueRect.height / 2 - containerRect.top;

        // 右への横線
        ctx.strokeStyle = 'rgb(0, 0, 255)';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(startX, startY);
        ctx.lineTo(horizontalEndX, startY);
        ctx.stroke();

        // 下への縦線
        ctx.beginPath();
        ctx.moveTo(horizontalEndX, startY);
        ctx.lineTo(horizontalEndX, blueY);
        ctx.stroke();

        // 青ブロックへの横線
        const blueRightX = firstBlueRect.right - containerRect.left;
        ctx.beginPath();
        ctx.moveTo(horizontalEndX, blueY);
        ctx.lineTo(blueRightX, blueY);
        ctx.stroke();
    }

    // 赤→緑の矢印（赤ブロックから左に出て終了ノードへ）
    if (redNodes.length > 0) {
        const lastRed = redNodes[redNodes.length - 1];
        const lastRedRect = lastRed.getBoundingClientRect();

        const startX = lastRedRect.left - containerRect.left;
        const startY = lastRedRect.top + lastRedRect.height / 2 - containerRect.top;
        const horizontalEndX = startX - 20;
        const endY = endRect.top + endRect.height / 2 - containerRect.top;

        // 左への横線
        ctx.strokeStyle = 'rgb(250, 128, 114)';
        ctx.lineWidth = 2;
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
    // rgb(255, 255, 255) 形式の文字列を解析
    const match = colorString.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/);
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
    const match = colorString.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/);
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
    const match = colorString.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/);
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
    const match = colorString.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/);
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
    const match = colorString.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/);
    if (match) {
        const r = parseInt(match[1]);
        const g = parseInt(match[2]);
        const b = parseInt(match[3]);
        // FromArgb(200, 220, 255)
        return r === 200 && g === 220 && b === 255;
    }
    return false;
}

// 色がPink（スクリプト展開ノード）かどうかを判定
function isPinkColor(colorString) {
    const match = colorString.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/);
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
    // 各レイヤーの矢印を再描画
    for (let i = 0; i <= 6; i++) {
        drawPanelArrows(`layer-${i}`);
    }

    // パネル間矢印も再描画
    drawCrossPanelArrows();
}

// リサイズ時にCanvasサイズを調整
function resizeCanvases() {
    arrowState.canvasMap.forEach((canvas, id) => {
        if (id === 'main') {
            const mainContainer = document.getElementById('main-container');
            if (mainContainer) {
                canvas.width = mainContainer.scrollWidth;
                canvas.height = mainContainer.scrollHeight;
                canvas.style.width = `${mainContainer.scrollWidth}px`;  // ★追加：CSS表示サイズ
                canvas.style.height = `${mainContainer.scrollHeight}px`; // ★追加：CSS表示サイズ
            }
        } else {
            const layerPanel = document.getElementById(id);
            if (layerPanel) {
                const nodeList = layerPanel.querySelector('.node-list-container');
                if (nodeList) {
                    canvas.width = nodeList.scrollWidth;
                    canvas.height = nodeList.scrollHeight;
                    canvas.style.width = `${nodeList.scrollWidth}px`;  // ★追加：CSS表示サイズ
                    canvas.style.height = `${nodeList.scrollHeight}px`; // ★追加：CSS表示サイズ
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

// グローバルに公開（即座に利用可能にする）
window.arrowDrawing = {
    refreshAllArrows,
    drawPanelArrows,
    drawCrossPanelArrows,
    resizeCanvases,
    setPinkSelected,
    clearPinkSelected,
    initializeArrowCanvas,  // 初期化関数も公開
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

    // ボタン設定.jsonを読み込み
    await loadButtonSettings();

    // カテゴリーパネルにノード追加ボタンを生成
    generateAddNodeButtons();

    // イベントリスナー設定
    setupEventListeners();

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
        // APIサーバー経由でボタン設定.jsonを読み込み
        // 注: 日本語URLのエンコード問題を避けるため、英語エイリアスを使用
        const response = await fetch('/button-settings.json');
        buttonSettings = await response.json();
        console.log('ボタン設定読み込み完了:', buttonSettings.length, '個');
    } catch (error) {
        console.error('ボタン設定読み込み失敗:', error);
        buttonSettings = [];
    }
}

// ============================================
// カテゴリーパネルにノード追加ボタンを生成
// ============================================

function generateAddNodeButtons() {
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

    buttonSettings.forEach(setting => {
        // コンテナ名から数字を抽出（例：操作フレームパネル1 → 1）
        const containerNum = setting.コンテナ.match(/\d+/);
        if (!containerNum) return;

        const panelNum = parseInt(containerNum[0]);
        const panelId = panelMapping[panelNum];
        const panel = document.getElementById(panelId);

        if (!panel) return;

        // ボタンを作成
        const btn = document.createElement('button');
        btn.className = 'add-node-btn';
        btn.textContent = setting.テキスト;
        btn.style.backgroundColor = getColorCode(setting.背景色);
        btn.dataset.setting = JSON.stringify(setting);

        btn.onclick = () => addNodeToLayer(setting);

        // マウスオーバーで説明を表示
        btn.onmouseenter = () => {
            document.getElementById('description-text').textContent = setting.説明 || 'ここに説明が表示されます。';
        };

        panel.appendChild(btn);
    });
}

// 色名→CSSカラーコード変換
function getColorCode(colorName) {
    const colorMap = {
        'White': '#FFFFFF',
        'SpringGreen': 'rgb(0, 255, 127)',
        'LemonChiffon': 'rgb(255, 250, 205)',
        'Pink': 'rgb(252, 160, 158)'
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

function addNodeToLayer(setting) {
    console.log('[デバッグ] addNodeToLayer() 呼び出し:', setting.処理番号, setting.テキスト);

    // 処理番号で判定してセット作成
    if (setting.処理番号 === '1-2') {
        // 条件分岐：3個セット（開始・中間・終了）
        console.log('[デバッグ] 条件分岐セット追加');
        addConditionSet(setting);
    } else if (setting.処理番号 === '1-3') {
        // ループ：2個セット（開始・終了）
        console.log('[デバッグ] ループセット追加');
        addLoopSet(setting);
    } else {
        // 通常ノード：1個
        console.log('[デバッグ] 通常ノード追加');
        addSingleNode(setting);

        // ★修正：画面を再描画（矢印も更新される）
        console.log('[デバッグ] renderNodesInLayer() を呼び出します');
        renderNodesInLayer(currentLayer);
        reorderNodesInLayer(currentLayer);
    }

    // memory.json自動保存
    saveMemoryJson();
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
function addLoopSet(setting) {
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
function addConditionSet(setting) {
    const groupId = conditionGroupCounter++;
    const baseY = getNextAvailableY(currentLayer);

    console.log(`[条件分岐作成] GroupID=${groupId} を割り当て`);

    // 1. 開始ボタン
    const startNode = addSingleNode(
        { ...setting, テキスト: '条件分岐 開始', ボタン名: `${nodeCounter}-1` },
        '条件分岐 開始',
        baseY,
        groupId,
        40
    );

    // 2. 中間ライン（グレー、高さ1px、ドラッグ不可）
    const middleNode = addSingleNode(
        { ...setting, テキスト: '条件分岐 中間', 背景色: 'Gray', ボタン名: `${nodeCounter}-2` },
        '条件分岐 中間',
        baseY + 40,
        groupId,
        1  // 高さ1pxのライン
    );

    // 3. 終了ボタン
    const endNode = addSingleNode(
        { ...setting, テキスト: '条件分岐 終了', ボタン名: `${nodeCounter}-3` },
        '条件分岐 終了',
        baseY + 45,
        groupId,
        40
    );

    console.log(`[条件分岐作成完了] ${startNode.name}, ${middleNode.name}, ${endNode.name} (GroupID=${groupId})`);

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
// レイヤー内のノードを描画
// ============================================

function renderNodesInLayer(layer) {
    const container = document.querySelector(`#layer-${layer} .node-list-container`);
    if (!container) return;

    container.innerHTML = '';

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

        console.log(`[デバッグ] ノード配置: x=${node.x || 90}px, y=${node.y}px, text="${node.text}"`);

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
    }

    return false;
}

function handleDrop(e) {
    if (e.stopPropagation) {
        e.stopPropagation();
    }

    const target = e.target;
    target.classList.remove('drag-over');

    if (target.classList.contains('node-button') && target !== draggedNode) {
        // ドロップ位置のノードを取得
        const targetNodeId = target.dataset.nodeId;
        const draggedNodeId = draggedNode.dataset.nodeId;

        const draggedNodeData = layerStructure[currentLayer].nodes.find(n => n.id === draggedNodeId);
        const targetNodeData = layerStructure[currentLayer].nodes.find(n => n.id === targetNodeId);

        if (!draggedNodeData || !targetNodeData) {
            return false;
        }

        const currentY = draggedNodeData.y;
        const newY = targetNodeData.y;

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

        // ノード配列内で位置を入れ替え
        swapNodes(currentLayer, draggedNodeId, targetNodeId);

        // 再描画
        renderNodesInLayer(currentLayer);

        // memory.json自動保存
        saveMemoryJson();
    }

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

    let currentY = 10;
    layerNodes.forEach(node => {
        node.y = currentY;
        currentY += 45;
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
    const redBorderNodes = layerNodes.filter(n => n.redBorder);

    if (redBorderNodes.length === 0) {
        alert('レイヤー化するには、まず赤枠でノードを選択してください。');
        hideContextMenu();
        return;
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
    const newNodeId = nextNodeId++;
    const newNode = {
        id: newNodeId,
        text: 'スクリプト',
        color: 'Pink',
        処理番号: '99-1',
        layer: currentLayer,
        y: minY,
        x: 0,
        width: 134,
        height: 28,
        script: entryString,  // 削除したノードの情報を保存
        redBorder: false
    };

    // グローバル配列とレイヤーに追加
    nodes.push(newNode);
    layerNodes.push(newNode);

    // 画面を再描画
    renderNodesInLayer(currentLayer);
    reorderNodesInLayer(currentLayer);

    // memory.json自動保存
    saveMemoryJson();

    console.log(`[レイヤー化] レイヤー${currentLayer}: ${sortedRedNodes.length}個 → ノード${newNodeId} (スクリプト)`);
    alert(`${sortedRedNodes.length}個のノードをレイヤー化しました。`);

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
    if (direction === 'left') {
        if (currentLayer > 0) {
            currentLayer--;
        }
    } else if (direction === 'right') {
        if (currentLayer < 6) {
            currentLayer++;
        }
    }

    // レイヤー表示を更新
    document.querySelectorAll('.layer-panel').forEach(panel => {
        panel.classList.remove('active');
        panel.style.display = 'none';
    });

    const targetPanel = document.getElementById(`layer-${currentLayer}`);
    if (targetPanel) {
        targetPanel.classList.add('active');
        targetPanel.style.display = 'flex';
    }

    // ラベル更新
    const layerLabel = currentLayer === 0 ? 'レイヤー0（非表示左）' : `レイヤー${currentLayer}`;
    document.getElementById('current-layer-label').textContent = layerLabel;
    document.getElementById('path-text').textContent = layerLabel;

    // レイヤー0の場合は特別な表示
    if (currentLayer === 0) {
        console.log('[レイヤー0表示] 非表示左パネルを表示中');
        layerStructure[0].visible = true;
    }

    // 現在のレイヤーを再描画
    renderNodesInLayer(currentLayer);

    // 左右ボタンの有効/無効を更新
    updateNavigationButtons();
}

// ナビゲーションボタンの状態を更新
function updateNavigationButtons() {
    const leftBtn = document.querySelector('[onclick*="navigateLayer(\'left\')"]');
    const rightBtn = document.querySelector('[onclick*="navigateLayer(\'right\')"]');

    if (leftBtn) {
        leftBtn.disabled = (currentLayer === 0);
        leftBtn.style.opacity = (currentLayer === 0) ? '0.5' : '1';
    }

    if (rightBtn) {
        rightBtn.disabled = (currentLayer === 6);
        rightBtn.style.opacity = (currentLayer === 6) ? '0.5' : '1';
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
        const result = await callApi('/folders');
        if (result.success) {
            folders = result.folders || [];
            console.log('フォルダ一覧読み込み完了:', folders.length, '個');

            // 初回起動時、フォルダがある場合は最初のフォルダを選択
            if (folders.length > 0 && !currentFolder) {
                currentFolder = folders[0];
                console.log(`デフォルトフォルダ「${currentFolder}」を選択しました`);
                // memory.jsonから既存ノードを読み込み
                await loadExistingNodes();
            }
        }
    } catch (error) {
        console.error('フォルダ一覧読み込み失敗:', error);
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

function selectFolder() {
    const select = document.getElementById('folder-select');
    const folderName = select.value;

    if (!folderName) return;

    callApi(`/folders/${folderName}`, 'PUT')
        .then(result => {
            if (result.success) {
                currentFolder = folderName;
                alert(`フォルダ「${folderName}」に切り替えました。`);
                closeFolderModal();
                loadExistingNodes();
            } else {
                alert(`フォルダ切り替えに失敗しました: ${result.error}`);
            }
        });
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

        // 現在のレイヤーを再描画
        renderNodesInLayer(currentLayer);
        console.log(`memory.jsonから${nodes.length}個のノードを復元しました`);
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

    console.log('📌 キーボードショートカット有効化:');
    console.log('  ← / →: レイヤー移動');
    console.log('  Ctrl+S: 保存');
    console.log('  Ctrl+E: コード生成');
    console.log('  Ctrl+Shift+V: 変数管理');
    console.log('  Delete: ノード削除');
    console.log('  Esc: モーダルを閉じる');
}
