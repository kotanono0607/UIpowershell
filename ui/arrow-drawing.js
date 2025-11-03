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

                // Canvasサイズを親要素に合わせる
                canvas.width = nodeList.scrollWidth;
                canvas.height = nodeList.scrollHeight;

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
        canvas.style.width = '100%';
        canvas.style.height = '100%';
        canvas.style.pointerEvents = 'none';
        canvas.style.zIndex = '10';

        // Canvasサイズを親要素に合わせる
        canvas.width = mainContainer.scrollWidth;
        canvas.height = mainContainer.scrollHeight;

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

    // 線を描画
    ctx.strokeStyle = color;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(startX, startY);
    ctx.lineTo(endX, endY);
    ctx.stroke();

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

    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.imageSmoothingEnabled = true;

    const layerPanel = document.getElementById(layerId);
    if (!layerPanel) {
        console.error(`[デバッグ] レイヤーパネルが見つかりません: ${layerId}`);
        return;
    }

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
            }
        } else {
            const layerPanel = document.getElementById(id);
            if (layerPanel) {
                const nodeList = layerPanel.querySelector('.node-list-container');
                if (nodeList) {
                    canvas.width = nodeList.scrollWidth;
                    canvas.height = nodeList.scrollHeight;
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

// 初期化（DOMContentLoadedで呼び出す）
document.addEventListener('DOMContentLoaded', () => {
    console.log('[矢印] Arrow drawing initialization...');
    initializeArrowCanvas();
    refreshAllArrows();
    window.arrowDrawing.initialized = true;
    console.log('[矢印] Arrow drawing initialized successfully');

    // ウィンドウリサイズ時に再描画
    window.addEventListener('resize', resizeCanvases);
});
