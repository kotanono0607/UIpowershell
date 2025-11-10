// ============================================
// layer-detail.js - レイヤー詳細ポップアップウィンドウ
// ============================================
// 役割: ピンクノードクリック時に開く詳細ウィンドウ
// 親ウィンドウからpostMessageでデータを受信
// ============================================

// グローバル変数
let popupLayerNumber = null;
let popupNodes = [];
let popupParentNode = null;
let popupParentWindow = window.opener;

console.log('[LayerDetail] レイヤー詳細ウィンドウを初期化中...');

// ============================================
// postMessageでデータ受信
// ============================================
window.addEventListener('message', (event) => {
    // セキュリティチェック（同一オリジンのみ許可）
    if (event.origin !== window.location.origin) {
        console.warn('[LayerDetail] 不正なオリジンからのメッセージを無視:', event.origin);
        return;
    }

    console.log('[LayerDetail] メッセージ受信:', event.data);

    if (event.data.type === 'SHOW_LAYER_DETAIL') {
        // レイヤー詳細を表示
        showLayerDetail(event.data);
    } else if (event.data.type === 'REFRESH_DATA') {
        // データ更新
        console.log('[LayerDetail] データ更新リクエストを受信');
        requestRefresh();
    } else if (event.data.type === 'UPDATE_NODES') {
        // ノードデータを直接更新
        console.log('[LayerDetail] ノードデータ更新:', event.data.nodes);
        popupNodes = event.data.nodes || [];
        renderPopupNodes();
    }
});

// ============================================
// レイヤー詳細を表示
// ============================================
function showLayerDetail(data) {
    console.log('[LayerDetail] レイヤー詳細を表示:', data);

    popupLayerNumber = data.layer;
    popupNodes = data.nodes || [];
    popupParentNode = data.parentNode || null;

    // タイトル更新
    const layerTitle = document.getElementById('layer-title');
    if (layerTitle) {
        layerTitle.textContent = `レイヤー${popupLayerNumber} 詳細`;
    }

    // レイヤーラベル更新
    const layerLabel = document.getElementById('popup-layer-label');
    if (layerLabel) {
        layerLabel.textContent = `レイヤー${popupLayerNumber}`;
    }

    // 親ノード情報を表示
    const parentInfo = document.getElementById('parent-node-info');
    if (parentInfo && popupParentNode) {
        parentInfo.textContent = `親: ${popupParentNode.text || popupParentNode.id}`;
        parentInfo.style.display = 'block';
    }

    // ノードをレンダリング
    renderPopupNodes();

    console.log(`[LayerDetail] レイヤー${popupLayerNumber}に${popupNodes.length}個のノードを表示`);
}

// ============================================
// ノードをレンダリング
// ============================================
function renderPopupNodes() {
    const container = document.getElementById('popup-node-container');
    if (!container) {
        console.error('[LayerDetail] popup-node-containerが見つかりません');
        return;
    }

    // 既存のノードをクリア（Canvasは残す）
    const canvas = document.getElementById('popup-arrow-canvas');
    container.innerHTML = '';
    if (canvas) {
        container.appendChild(canvas);
    }

    if (popupNodes.length === 0) {
        const emptyState = document.createElement('div');
        emptyState.className = 'empty-state';
        emptyState.textContent = 'このレイヤーにはノードがありません';
        container.appendChild(emptyState);
        return;
    }

    // ノードを描画
    popupNodes.forEach(node => {
        const nodeEl = createNodeElement(node, true); // isPopup=true
        container.appendChild(nodeEl);
    });

    // Canvas初期化と矢印描画（レイアウト計算後に実行）
    // requestAnimationFrameを2回使用して確実にレンダリングを待つ
    requestAnimationFrame(() => {
        requestAnimationFrame(() => {
            console.log('[LayerDetail] レイアウト完了後に初期化開始');
            initializePopupCanvas();
            drawPopupArrows();
        });
    });
}

// ============================================
// ノード要素を作成（既存のcreateNodeElement関数を再利用）
// ============================================
function createNodeElement(node, isPopup = false) {
    const button = document.createElement('div');
    button.className = 'node-button';
    button.id = isPopup ? `popup-node-${node.id}` : `node-${node.id}`;
    button.textContent = node.text || '';

    // スタイル設定
    button.style.position = 'absolute';
    button.style.left = `${node.x || 90}px`;
    button.style.top = `${node.y || 10}px`;
    button.style.width = `${node.width || 120}px`;
    button.style.height = `${node.height || 40}px`;
    button.style.backgroundColor = node.color || 'white';

    // 色に応じたクラス追加（Auroraエフェクト用）
    if (node.color) {
        button.setAttribute('style', button.getAttribute('style') + `background-color: ${node.color};`);
    }

    // 赤枠表示
    if (node.redBorder) {
        button.style.border = '3px solid red';
    }

    // クリックイベント（ポップアップでは編集不可）
    button.addEventListener('click', (e) => {
        e.preventDefault();
        console.log(`[LayerDetail] ノードクリック（読み取り専用）: ${node.text}`);
        // 必要に応じて親ウィンドウに通知
        if (popupParentWindow && !popupParentWindow.closed) {
            popupParentWindow.postMessage({
                type: 'NODE_CLICKED_IN_POPUP',
                nodeId: node.id,
                layer: popupLayerNumber
            }, window.location.origin);
        }
    });

    return button;
}

// ============================================
// Canvas初期化
// ============================================
function initializePopupCanvas() {
    const canvas = document.getElementById('popup-arrow-canvas');
    const container = document.getElementById('popup-node-container');

    if (!canvas || !container) {
        console.warn('[LayerDetail] CanvasまたはContainerが見つかりません');
        return;
    }

    // デバッグ：containerの実際のサイズを確認
    console.log(`[LayerDetail] Container実サイズ: ${container.clientWidth}x${container.clientHeight}`);
    console.log(`[LayerDetail] Container計算サイズ: ${container.offsetWidth}x${container.offsetHeight}`);

    // Canvasサイズを調整（containerのサイズが0の場合はフォールバック）
    const width = container.clientWidth || container.offsetWidth || 600;
    const height = container.clientHeight || container.offsetHeight || 800;

    canvas.width = width;
    canvas.height = height;

    console.log(`[LayerDetail] Canvas初期化: ${canvas.width}x${canvas.height}`);
}

// ============================================
// 矢印を描画
// ============================================
function drawPopupArrows() {
    const canvas = document.getElementById('popup-arrow-canvas');
    if (!canvas) {
        console.warn('[LayerDetail] Canvasが見つかりません');
        return;
    }

    const ctx = canvas.getContext('2d');
    if (!ctx) {
        console.error('[LayerDetail] Canvas 2Dコンテキストの取得に失敗');
        return;
    }

    // Canvasをクリア
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // ノードをY座標でソート
    const sortedNodes = [...popupNodes].sort((a, b) => (a.y || 0) - (b.y || 0));

    // ノード間に矢印を描画
    for (let i = 0; i < sortedNodes.length - 1; i++) {
        const fromNode = sortedNodes[i];
        const toNode = sortedNodes[i + 1];

        const fromEl = document.getElementById(`popup-node-${fromNode.id}`);
        const toEl = document.getElementById(`popup-node-${toNode.id}`);

        if (fromEl && toEl) {
            const fromX = fromNode.x + (fromNode.width / 2);
            const fromY = fromNode.y + fromNode.height;
            const toX = toNode.x + (toNode.width / 2);
            const toY = toNode.y;

            // Auroraグラデーション矢印
            const gradient = ctx.createLinearGradient(fromX, fromY, toX, toY);
            gradient.addColorStop(0.0, '#667eea');
            gradient.addColorStop(0.25, '#f472b6');
            gradient.addColorStop(0.5, '#06b6d4');
            gradient.addColorStop(0.75, '#10b981');
            gradient.addColorStop(1.0, '#fbbf24');

            ctx.strokeStyle = gradient;
            ctx.lineWidth = 3;
            ctx.setLineDash([]);

            ctx.beginPath();
            ctx.moveTo(fromX, fromY);
            ctx.lineTo(toX, toY);
            ctx.stroke();
        }
    }

    console.log(`[LayerDetail] ${sortedNodes.length - 1}本の矢印を描画`);
}

// ============================================
// 親ウィンドウからデータ更新をリクエスト
// ============================================
function requestRefresh() {
    if (!popupParentWindow || popupParentWindow.closed) {
        console.warn('[LayerDetail] 親ウィンドウが閉じられています');
        return;
    }

    console.log('[LayerDetail] 親ウィンドウにデータ更新をリクエスト');
    popupParentWindow.postMessage({
        type: 'REQUEST_LAYER_DATA',
        layer: popupLayerNumber
    }, window.location.origin);
}

// ============================================
// ウィンドウリサイズ時の処理
// ============================================
let resizeTimeout;
window.addEventListener('resize', () => {
    console.log('[LayerDetail] ウィンドウリサイズ検出');
    clearTimeout(resizeTimeout);
    resizeTimeout = setTimeout(() => {
        initializePopupCanvas();
        drawPopupArrows();
    }, 100);
});

// ============================================
// 初期化完了通知
// ============================================
window.addEventListener('load', () => {
    console.log('[LayerDetail] ウィンドウのロード完了');

    // 親ウィンドウに準備完了を通知
    if (popupParentWindow && !popupParentWindow.closed) {
        popupParentWindow.postMessage({
            type: 'POPUP_READY'
        }, window.location.origin);
    }
});

// ============================================
// ウィンドウクローズ時の処理
// ============================================
window.addEventListener('beforeunload', () => {
    console.log('[LayerDetail] ウィンドウを閉じます');

    // 親ウィンドウに通知
    if (popupParentWindow && !popupParentWindow.closed) {
        popupParentWindow.postMessage({
            type: 'POPUP_CLOSED',
            layer: popupLayerNumber
        }, window.location.origin);
    }
});

console.log('[LayerDetail] スクリプト初期化完了');
