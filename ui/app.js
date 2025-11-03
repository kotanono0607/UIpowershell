// ============================================
// UIpowershell - Phase 4 JavaScript
// ============================================
// Phase 3 API (api-server-v2.ps1) と統合
// すべてのv2関数をREST API経由で呼び出し
// ============================================

const API_BASE = 'http://localhost:8080/api';

// ============================================
// グローバル変数
// ============================================

let currentLayer = 1;
let reactFlowInstance = null;
let nodes = [];
let edges = [];
let sessionInfo = null;

// ============================================
// エッジ自動生成関数
// ============================================

/**
 * ノード配列からエッジ（矢印）を自動生成
 * レガシー版の矢印描画ロジックを再現：Y座標でソートして隣接ノード間に矢印を作成
 *
 * @param {Array} nodeArray - ノード配列
 * @returns {Array} エッジ配列
 */
function generateEdgesFromNodes(nodeArray) {
    if (!nodeArray || nodeArray.length === 0) {
        console.log('[generateEdgesFromNodes] ノードが空のため、エッジを生成しません');
        return [];
    }

    // ノードをY座標でソート（レガシー版の順序ロジックを再現）
    const sortedNodes = [...nodeArray].sort((a, b) => {
        return a.position.y - b.position.y;
    });

    // 隣接ノード間にエッジを生成
    const newEdges = [];
    for (let i = 0; i < sortedNodes.length - 1; i++) {
        const sourceNode = sortedNodes[i];
        const targetNode = sortedNodes[i + 1];

        const edge = {
            id: `e${sourceNode.id}-${targetNode.id}`,
            source: sourceNode.id,
            target: targetNode.id,
            animated: true,  // アニメーション効果
            type: 'smoothstep',  // スムーズなステップライン
            style: {
                stroke: '#007acc',  // 青色の矢印
                strokeWidth: 2
            }
        };

        newEdges.push(edge);
        console.log(`[generateEdgesFromNodes] エッジ生成: ${sourceNode.id} → ${targetNode.id}`);
    }

    console.log(`[generateEdgesFromNodes] 合計 ${newEdges.length} 個のエッジを生成しました`);
    return newEdges;
}

// ============================================
// API通信関数 - 基本
// ============================================

async function testApiConnection() {
    try {
        const response = await fetch(`${API_BASE}/health`);
        const data = await response.json();

        if (data.status === 'ok') {
            updateStatus('api', `API: ${data.version} ✓`, '#4caf50');

            // セッション情報を取得
            const sessionResp = await fetch(`${API_BASE}/session`);
            sessionInfo = await sessionResp.json();
            updateStatus('session', `セッション: ${sessionInfo.sessionId.substring(0, 8)}...`);

            alert('API接続テスト成功！\n' + JSON.stringify(data, null, 2));
            return true;
        }
    } catch (error) {
        updateStatus('api', 'API: 未接続', '#f44336');
        alert('API接続失敗:\n' + error.message + '\n\nadapter/api-server-v2.ps1 を起動してください');
        return false;
    }
}

async function getDebugInfo() {
    const response = await fetch(`${API_BASE}/debug`);
    return await response.json();
}

// ============================================
// API通信関数 - ノード管理
// ============================================

async function syncNodes() {
    // React FlowのノードをAPI側に同期
    const response = await fetch(`${API_BASE}/nodes`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            nodes: nodes.map(node => ({
                id: node.id,
                text: node.data.label,
                color: node.data.color || 'White',
                x: node.position.x,
                y: node.position.y,
                groupId: node.data.groupId
            }))
        })
    });
    return await response.json();
}

async function deleteNodeApi(nodeId) {
    // ノード削除API（セット削除対応）
    const response = await fetch(`${API_BASE}/nodes/${nodeId}`, {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            nodes: nodes.map(node => ({
                id: node.id,
                text: node.data.label,
                color: node.data.color || 'White',
                y: node.position.y,
                groupId: node.data.groupId
            }))
        })
    });
    return await response.json();
}

async function validateDrop(movingNodeId, targetY) {
    // ドロップバリデーション
    const response = await fetch(`${API_BASE}/validate/drop`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            nodes: nodes.map(node => ({
                id: node.id,
                text: node.data.label,
                color: node.data.color || 'White',
                y: node.position.y,
                groupId: node.data.groupId
            })),
            movingNodeId: movingNodeId,
            targetY: targetY
        })
    });
    return await response.json();
}

// ============================================
// API通信関数 - 変数管理
// ============================================

async function getVariables() {
    const response = await fetch(`${API_BASE}/variables`);
    return await response.json();
}

async function addVariableApi(name, value, type) {
    const response = await fetch(`${API_BASE}/variables`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, value, type })
    });
    return await response.json();
}

async function updateVariableApi(name, value) {
    const response = await fetch(`${API_BASE}/variables/${name}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ value })
    });
    return await response.json();
}

async function deleteVariableApi(name) {
    const response = await fetch(`${API_BASE}/variables/${name}`, {
        method: 'DELETE'
    });
    return await response.json();
}

// ============================================
// API通信関数 - フォルダ管理
// ============================================

async function getFolders() {
    const response = await fetch(`${API_BASE}/folders`);
    return await response.json();
}

async function createFolderApi(folderName) {
    const response = await fetch(`${API_BASE}/folders`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ folderName })
    });
    return await response.json();
}

async function switchFolderApi(folderName) {
    const response = await fetch(`${API_BASE}/folders/${folderName}`, {
        method: 'PUT'
    });
    return await response.json();
}

// ============================================
// API通信関数 - コード生成
// ============================================

async function generateCodeApi(outputPath) {
    const response = await fetch(`${API_BASE}/execute/generate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            nodes: nodes.map(node => ({
                id: node.id,
                text: node.data.label,
                color: node.data.color || 'White',
                y: node.position.y
            })),
            outputPath: outputPath || null,
            openFile: false
        })
    });
    return await response.json();
}

// ============================================
// API通信関数 - メニューアクション
// ============================================

async function getMenuStructure() {
    const response = await fetch(`${API_BASE}/menu/structure`);
    return await response.json();
}

async function executeMenuAction(actionId, parameters = {}) {
    const response = await fetch(`${API_BASE}/menu/action/${actionId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ parameters })
    });
    return await response.json();
}

// ============================================
// UI更新関数
// ============================================

function updateStatus(type, text, color = null) {
    const element = document.getElementById(`status-${type}`);
    if (element) {
        element.textContent = text;
        if (color) element.style.color = color;
    }
}

function updateNodeCount() {
    updateStatus('nodes', `ノード数: ${nodes.length}`);

    // プロジェクト情報も更新
    const projectInfo = document.getElementById('project-info');
    if (projectInfo) {
        projectInfo.innerHTML = `
            <p>フォルダ: ${sessionInfo?.currentProject?.FolderName || '未選択'}</p>
            <p>ノード数: ${nodes.length}</p>
        `;
    }
}

// ============================================
// モーダル管理
// ============================================

function showModal(modalId) {
    document.getElementById(modalId).classList.add('active');
}

function closeModal(modalId) {
    document.getElementById(modalId).classList.remove('active');
}

function showAddNodeModal() {
    showModal('modal-add-node');
}

function showVariableModal() {
    showModal('modal-variables');
    loadVariables();
}

function showFolderModal() {
    showModal('modal-folders');
    loadFolders();
}

function showAddVariableForm() {
    closeModal('modal-variables');
    showModal('modal-add-variable');
}

function showCreateFolderForm() {
    closeModal('modal-folders');
    showModal('modal-create-folder');
}

// ============================================
// React Flow初期化
// ============================================

function initReactFlow() {
    const { ReactFlow, Background, Controls, MiniMap, applyNodeChanges, applyEdgeChanges } = ReactFlowRenderer;
    const flowContainer = document.getElementById('flow-container');

    // 初期エッジを生成
    edges = generateEdgesFromNodes(nodes);

    const App = () => {
        const [nodesState, setNodes] = React.useState(nodes);
        const [edgesState, setEdges] = React.useState(edges);

        const onNodesChange = React.useCallback((changes) => {
            const newNodes = applyNodeChanges(changes, nodesState);
            setNodes(newNodes);
            nodes = newNodes;
            updateNodeCount();

            // ノード変更時にエッジを再生成（位置変更を反映）
            const newEdges = generateEdgesFromNodes(newNodes);
            setEdges(newEdges);
            edges = newEdges;

            // API側に同期
            syncNodes();
        }, [nodesState]);

        const onEdgesChange = React.useCallback((changes) => {
            const newEdges = applyEdgeChanges(changes, edgesState);
            setEdges(newEdges);
            edges = newEdges;
        }, [edgesState]);

        const onConnect = React.useCallback((connection) => {
            const newEdge = {
                ...connection,
                id: `e${connection.source}-${connection.target}`,
                animated: true
            };
            const newEdges = [...edgesState, newEdge];
            setEdges(newEdges);
            edges = newEdges;
        }, [edgesState]);

        const onNodeDragStop = React.useCallback(async (event, node) => {
            // ドロップバリデーション
            const result = await validateDrop(node.id, node.position.y);

            if (result.success && result.isProhibited) {
                alert(`ドロップ禁止: ${result.reason}\n違反タイプ: ${result.violationType}`);

                // 元の位置に戻す（簡易実装）
                // 本来はドラッグ前の位置を保存して戻す必要がある
            }
        }, []);

        // React Flowインスタンスを保存
        const onInit = (instance) => {
            reactFlowInstance = instance;
        };

        return React.createElement(
            'div',
            { style: { width: '100%', height: '100%' } },
            React.createElement(ReactFlow, {
                nodes: nodesState,
                edges: edgesState,
                onNodesChange,
                onEdgesChange,
                onConnect,
                onNodeDragStop,
                onInit,
                fitView: true,
                snapToGrid: true,
                snapGrid: [10, 10]
            }, [
                React.createElement(Background, { key: 'bg' }),
                React.createElement(Controls, { key: 'ctrl' }),
                React.createElement(MiniMap, { key: 'map' })
            ])
        );
    };

    ReactDOM.render(React.createElement(App), flowContainer);
    updateNodeCount();
}

// ============================================
// ノード管理
// ============================================

async function addNode(event) {
    event.preventDefault();

    const type = document.getElementById('input-type').value;
    const text = document.getElementById('input-text').value;
    const code = document.getElementById('input-code').value;

    try {
        // 新しいIDを生成
        const idResp = await fetch(`${API_BASE}/id/generate`, { method: 'POST' });
        const idData = await idResp.json();
        const newId = idData.id;

        // ノードの色を決定
        let color = 'White';
        let cssClass = '';
        switch (type) {
            case 'conditional':
                color = 'SpringGreen';
                cssClass = 'node-conditional';
                break;
            case 'loop':
                color = 'LemonChiffon';
                cssClass = 'node-loop';
                break;
            case 'start':
            case 'end':
                color = 'Gray';
                cssClass = 'node-start';
                break;
        }

        // 新しいノードを追加
        const newNode = {
            id: newId.toString(),
            type: 'default',
            className: cssClass,
            data: {
                label: text,
                color: color
            },
            position: {
                x: Math.random() * 400 + 100,
                y: (nodes.length * 60) + 50
            }
        };

        nodes.push(newNode);

        // エッジを再生成
        edges = generateEdgesFromNodes(nodes);

        // APIにエントリを追加
        await fetch(`${API_BASE}/entry/add`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                targetID: newId,
                TypeName: type,
                displayText: text,
                code: code,
                toID: null,
                order: nodes.length
            })
        });

        // API側に同期
        await syncNodes();

        // モーダルを閉じる
        closeModal('modal-add-node');
        document.getElementById('form-add-node').reset();

        // 再描画
        initReactFlow();

        alert(`ノードを追加しました！\nID: ${newId}\nタイプ: ${type}`);
    } catch (error) {
        alert('ノード追加エラー:\n' + error.message);
    }
}

async function deleteSelectedNodes() {
    if (nodes.length === 0) {
        alert('削除するノードがありません');
        return;
    }

    // 選択されたノードを取得（簡易実装：最後のノード）
    const selectedNode = nodes[nodes.length - 1];

    if (!confirm(`ノード「${selectedNode.data.label}」を削除しますか？\n※セット削除が適用される場合があります`)) {
        return;
    }

    try {
        // API経由で削除対象を取得
        const result = await deleteNodeApi(selectedNode.id);

        if (result.success) {
            // 削除対象のノードをすべて削除
            const deleteIds = result.deleteTargets;
            nodes = nodes.filter(node => !deleteIds.includes(node.id));

            // エッジを再生成
            edges = generateEdgesFromNodes(nodes);

            // 再描画
            initReactFlow();

            alert(`${result.deleteCount}個のノードを削除しました\nタイプ: ${result.nodeType}`);
        } else {
            alert(`削除エラー: ${result.error}`);
        }
    } catch (error) {
        alert('削除エラー:\n' + error.message);
    }
}

// ============================================
// 変数管理
// ============================================

async function loadVariables() {
    try {
        const result = await getVariables();

        if (result.success) {
            const container = document.getElementById('variable-list-container');

            if (result.count === 0) {
                container.innerHTML = '<p style="color: #888;">変数がありません</p>';
                return;
            }

            let html = '<table><thead><tr><th>名前</th><th>値</th><th>タイプ</th><th>操作</th></tr></thead><tbody>';

            result.variables.forEach(v => {
                html += `
                    <tr>
                        <td>${v.name}</td>
                        <td>${v.value}</td>
                        <td>${v.type}</td>
                        <td>
                            <button onclick="deleteVariable('${v.name}')" class="danger">削除</button>
                        </td>
                    </tr>
                `;
            });

            html += '</tbody></table>';
            container.innerHTML = html;
        }
    } catch (error) {
        alert('変数読み込みエラー:\n' + error.message);
    }
}

async function addVariable(event) {
    event.preventDefault();

    const name = document.getElementById('var-name').value;
    const value = document.getElementById('var-value').value;
    const type = document.getElementById('var-type').value;

    try {
        const result = await addVariableApi(name, value, type);

        if (result.success) {
            closeModal('modal-add-variable');
            document.getElementById('form-add-variable').reset();

            showVariableModal();
            alert(`変数「${name}」を追加しました`);
        } else {
            alert(`エラー: ${result.error}`);
        }
    } catch (error) {
        alert('変数追加エラー:\n' + error.message);
    }
}

async function deleteVariable(name) {
    if (!confirm(`変数「${name}」を削除しますか？`)) {
        return;
    }

    try {
        const result = await deleteVariableApi(name);

        if (result.success) {
            loadVariables();
            alert(`変数「${name}」を削除しました`);
        } else {
            alert(`エラー: ${result.error}`);
        }
    } catch (error) {
        alert('変数削除エラー:\n' + error.message);
    }
}

// ============================================
// フォルダ管理
// ============================================

async function loadFolders() {
    try {
        const result = await getFolders();

        if (result.success) {
            const container = document.getElementById('folder-list-container');

            if (result.count === 0) {
                container.innerHTML = '<p style="color: #888;">フォルダがありません</p>';
                return;
            }

            let html = '<table><thead><tr><th>フォルダ名</th><th>操作</th></tr></thead><tbody>';

            result.folders.forEach(folder => {
                html += `
                    <tr>
                        <td>${folder}</td>
                        <td>
                            <button onclick="switchFolder('${folder}')">切り替え</button>
                        </td>
                    </tr>
                `;
            });

            html += '</tbody></table>';
            container.innerHTML = html;
        }
    } catch (error) {
        alert('フォルダ読み込みエラー:\n' + error.message);
    }
}

async function createFolder(event) {
    event.preventDefault();

    const folderName = document.getElementById('folder-name').value;

    try {
        const result = await createFolderApi(folderName);

        if (result.success) {
            closeModal('modal-create-folder');
            document.getElementById('form-create-folder').reset();

            showFolderModal();
            alert(`フォルダ「${folderName}」を作成しました\nパス: ${result.folderPath}`);
        } else {
            alert(`エラー: ${result.error}`);
        }
    } catch (error) {
        alert('フォルダ作成エラー:\n' + error.message);
    }
}

async function switchFolder(folderName) {
    try {
        const result = await switchFolderApi(folderName);

        if (result.success) {
            closeModal('modal-folders');

            // セッション情報を更新
            const sessionResp = await fetch(`${API_BASE}/session`);
            sessionInfo = await sessionResp.json();
            updateNodeCount();

            alert(`フォルダ「${folderName}」に切り替えました\nパス: ${result.folderPath}`);
        } else {
            alert(`エラー: ${result.error}`);
        }
    } catch (error) {
        alert('フォルダ切り替えエラー:\n' + error.message);
    }
}

// ============================================
// コード生成
// ============================================

async function generateCode() {
    if (nodes.length === 0) {
        alert('コード生成するノードがありません');
        return;
    }

    showModal('modal-generate');

    // プログレス表示
    document.getElementById('generate-status').textContent = 'コード生成中...';
    document.getElementById('generate-progress').style.width = '30%';
    document.getElementById('generate-result').style.display = 'none';

    try {
        const result = await generateCodeApi();

        document.getElementById('generate-progress').style.width = '100%';

        if (result.success) {
            document.getElementById('generate-status').textContent = '生成完了！';
            document.getElementById('generate-output-path').textContent = `出力先: ${result.outputPath}`;
            document.getElementById('generate-node-count').textContent = `処理ノード数: ${result.nodeCount}`;
            document.getElementById('generate-result').style.display = 'block';
        } else {
            document.getElementById('generate-status').textContent = `エラー: ${result.error}`;
            document.getElementById('generate-status').style.color = '#f44336';
        }
    } catch (error) {
        document.getElementById('generate-status').textContent = `エラー: ${error.message}`;
        document.getElementById('generate-status').style.color = '#f44336';
    }
}

// ============================================
// メニューアクション
// ============================================

async function menuAction(actionId) {
    try {
        const result = await executeMenuAction(actionId);

        if (result.success) {
            alert(`アクション実行: ${actionId}\n結果: ${result.message || 'OK'}`);
        } else {
            alert(`エラー: ${result.error}`);
        }
    } catch (error) {
        alert('メニューアクション実行エラー:\n' + error.message);
    }
}

// ============================================
// レイヤー切り替え
// ============================================

function switchLayer(layer) {
    currentLayer = layer;

    document.querySelectorAll('.layer-item').forEach(item => {
        item.classList.remove('active');
    });

    document.querySelector(`[data-layer="${layer}"]`).classList.add('active');
    updateStatus('layer', `レイヤー: ${layer}`);
}

// ============================================
// 初期化
// ============================================

window.addEventListener('DOMContentLoaded', () => {
    console.log('UIpowershell Phase 4 - 初期化開始');

    // React Flowを初期化
    initReactFlow();

    // API接続テスト
    testApiConnection();
});
