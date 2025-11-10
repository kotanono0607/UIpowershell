
// ============================================
// レイヤー詳細モーダル（window.open の代替）
// ============================================

let modalCurrentLayer = null;
let modalCurrentNodes = [];

function showLayerDetailModal(layer, nodes, parentNode) {
    console.log(`[モーダル] === showLayerDetailModal 呼び出し ===`);
    console.log(`[モーダル] レイヤー: ${layer}, ノード数: ${nodes.length}`);
    console.log(`[モーダル] ノードデータ:`, nodes);

    modalCurrentLayer = layer;
    modalCurrentNodes = nodes;

    // モーダル要素を取得
    const modal = document.getElementById('layer-detail-modal');
    const layerTitle = document.getElementById('modal-layer-title');
    const layerLabel = document.getElementById('modal-layer-label');
    const parentInfo = document.getElementById('modal-parent-info');
    const container = document.getElementById('modal-node-container');

    console.log(`[モーダル] DOM要素チェック:`);
    console.log(`[モーダル]   - modal: ${modal ? '✓' : '✗'}`);
    console.log(`[モーダル]   - layerTitle: ${layerTitle ? '✓' : '✗'}`);
    console.log(`[モーダル]   - container: ${container ? '✓' : '✗'}`);

    // タイトル設定
    if (layerTitle) {
        layerTitle.textContent = `レイヤー${layer} 詳細`;
    }

    if (layerLabel) {
        layerLabel.textContent = `レイヤー${layer}`;
    }

    // 親ノード情報
    if (parentInfo && parentNode) {
        parentInfo.textContent = `親: ${parentNode.text || parentNode.id}`;
        parentInfo.style.display = 'inline-block';
    } else if (parentInfo) {
        parentInfo.style.display = 'none';
    }

    // コンテナをクリア（Canvasは残す）
    if (container) {
        console.log(`[モーダル] コンテナをクリアしてノードを描画開始`);
        const canvas = document.getElementById('modal-arrow-canvas');
        container.innerHTML = '';
        if (canvas) {
            container.appendChild(canvas);
        }

        // ノードを描画
        console.log(`[モーダル] ${nodes.length}個のノードを描画中...`);
        nodes.forEach((node, index) => {
            console.log(`[モーダル] ノード${index + 1}: text="${node.text}", x=${node.x}, y=${node.y}, color=${node.color}`);
            const btn = document.createElement('div');
            btn.className = 'node-button';

            // テキストの省略表示（20文字以上は省略）
            const displayText = node.text.length > 20 ? node.text.substring(0, 20) + '...' : node.text;
            btn.textContent = displayText;

            // 位置とサイズ設定
            btn.style.position = 'absolute';
            btn.style.left = `${node.x || 90}px`;
            btn.style.top = `${node.y || 10}px`;
            btn.style.width = `${node.width || 120}px`;
            btn.style.height = `${node.height || 40}px`;
            btn.style.backgroundColor = node.color || 'white';

            // 赤枠
            if (node.redBorder) {
                btn.style.border = '3px solid red';
            }

            // モーダル内のノードはクリック不可にする
            btn.style.cursor = 'default';
            btn.onclick = (e) => {
                e.preventDefault();
                e.stopPropagation();
                console.log(`[モーダル] ノードクリック（読み取り専用）: ${node.text}`);
            };

            container.appendChild(btn);
            console.log(`[モーダル] ノード${index + 1}をコンテナに追加: ${btn.textContent}`);
        });

        console.log(`[モーダル] コンテナの子要素数: ${container.children.length}`);

        // Canvas初期化と矢印描画
        setTimeout(() => {
            console.log(`[モーダル] Canvas初期化と矢印描画を開始`);
            initializeModalCanvas();
            drawModalArrows(nodes);
        }, 100);
    } else {
        console.error(`[モーダル] エラー: containerが見つかりません！`);
    }

    // モーダル表示
    if (modal) {
        modal.style.display = 'flex';
        document.body.style.overflow = 'hidden'; // 背景スクロール防止
    }

    console.log(`[モーダル] レイヤー${layer}に${nodes.length}個のノード表示完了`);
}

function closeLayerDetailModal() {
    console.log('[モーダル] モーダルを閉じます');

    const modal = document.getElementById('layer-detail-modal');
    if (modal) {
        modal.style.display = 'none';
        document.body.style.overflow = ''; // 背景スクロール復元
    }

    modalCurrentLayer = null;
    modalCurrentNodes = [];
}

function initializeModalCanvas() {
    const canvas = document.getElementById('modal-arrow-canvas');
    const container = document.getElementById('modal-node-container');

    if (!canvas || !container) {
        console.warn('[モーダル] CanvasまたはContainerが見つかりません');
        return;
    }

    canvas.width = container.clientWidth;
    canvas.height = container.clientHeight;

    console.log(`[モーダル] Canvas初期化: ${canvas.width}x${canvas.height}`);
}

function drawModalArrows(nodes) {
    const canvas = document.getElementById('modal-arrow-canvas');
    if (!canvas) {
        console.warn('[モーダル] Canvasが見つかりません');
        return;
    }

    const ctx = canvas.getContext('2d');
    if (!ctx) {
        console.error('[モーダル] Canvas 2Dコンテキストの取得に失敗');
        return;
    }

    // Canvasをクリア
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // ノードをY座標でソート
    const sortedNodes = [...nodes].sort((a, b) => (a.y || 0) - (b.y || 0));

    // ノード間に矢印を描画
    for (let i = 0; i < sortedNodes.length - 1; i++) {
        const fromNode = sortedNodes[i];
        const toNode = sortedNodes[i + 1];

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

    console.log(`[モーダル] ${sortedNodes.length - 1}本の矢印を描画`);
}

// オーバーレイクリックで閉じる
document.addEventListener('click', (e) => {
    const modal = document.getElementById('layer-detail-modal');
    if (modal && e.target === modal) {
        closeLayerDetailModal();
    }
});

// Escapeキーで閉じる
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        const modal = document.getElementById('layer-detail-modal');
        if (modal && modal.style.display === 'flex') {
            closeLayerDetailModal();
        }
    }
});
