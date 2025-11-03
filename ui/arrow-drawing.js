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
            }
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
    }
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
    const canvas = arrowState.canvasMap.get(layerId);
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.imageSmoothingEnabled = true;

    const layerPanel = document.getElementById(layerId);
    if (!layerPanel) return;

    const nodes = Array.from(layerPanel.querySelectorAll('.node-button'));

    // ノードをY座標でソート
    nodes.sort((a, b) => {
        const aRect = a.getBoundingClientRect();
        const bRect = b.getBoundingClientRect();
        return aRect.top - bRect.top;
    });

    // 隣接ノード間に矢印を描画
    for (let i = 0; i < nodes.length - 1; i++) {
        const currentNode = nodes[i];
        const nextNode = nodes[i + 1];

        // ノードの背景色を取得
        const currentColor = window.getComputedStyle(currentNode).backgroundColor;
        const nextColor = window.getComputedStyle(nextNode).backgroundColor;

        // 白→白の場合は黒の矢印を描画
        if (isWhiteColor(currentColor) && isWhiteColor(nextColor)) {
            drawDownArrow(ctx, currentNode, nextNode, '#000000');
        }
    }
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

// すべての矢印を再描画
function refreshAllArrows() {
    // 各レイヤーの矢印を再描画
    for (let i = 0; i <= 6; i++) {
        drawPanelArrows(`layer-${i}`);
    }

    // パネル間矢印も再描画（将来実装）
    // drawCrossPanelArrows();
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

// 初期化（DOMContentLoadedで呼び出す）
document.addEventListener('DOMContentLoaded', () => {
    console.log('Arrow drawing initialization...');
    initializeArrowCanvas();
    refreshAllArrows();

    // ウィンドウリサイズ時に再描画
    window.addEventListener('resize', resizeCanvases);
});

// グローバルに公開
window.arrowDrawing = {
    refreshAllArrows,
    drawPanelArrows,
    resizeCanvases,
    state: arrowState
};
