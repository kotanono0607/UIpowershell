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
let nodeTypes = [];  // 動的に読み込むノードタイプ（ボタン設定.jsonから）

// ノードタイプごとのパラメータ定義
const nodeParameters = {
    '99_1': [
        { name: '直接エントリ', type: 'textarea', placeholder: 'Write-Host "Hello"_Write-Host "World"', required: true, rows: 3 }
    ],
    '1_8': [
        { name: '秒数', type: 'number', placeholder: '5', required: true, min: 1 }
    ],
    '1_6': [
        { name: 'メッセージ', type: 'text', placeholder: '処理が完了しました', required: true }
    ],
    '8_1': [
        { name: 'Excelファイルパス', type: 'text', placeholder: 'C:\\data\\file.xlsx', required: true },
        { name: 'シート名', type: 'text', placeholder: 'Sheet1', required: true }
    ],
    '1_4': [
        // パラメータなし
    ]
};

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
// API通信関数 - 動的ノード設定
// ============================================

/**
 * ボタン設定.jsonを読み込む
 */
async function loadButtonSettings() {
    try {
        const response = await fetch('/button-settings.json');
        const settings = await response.json();

        // ノードタイプ配列を作成
        nodeTypes = settings.map(btn => ({
            id: btn.処理番号,
            text: btn.テキスト,
            color: btn.背景色,
            functionName: btn.関数名,
            description: btn.説明
        }));

        console.log(`[ボタン設定読み込み] ${nodeTypes.length}個のノードタイプを読み込みました`);
        return nodeTypes;
    } catch (error) {
        console.error('[ボタン設定読み込みエラー]', error);
        // フォールバック: 基本的なノードタイプのみ
        nodeTypes = [
            { id: '1-2', text: '条件分岐', color: 'SpringGreen', functionName: 'ShowConditionBuilder' },
            { id: '1-3', text: 'ループ', color: 'LemonChiffon', functionName: 'ShowLoopBuilder' }
        ];
        return nodeTypes;
    }
}

/**
 * ノード関数を実行
 */
async function executeNodeFunction(functionName, params = {}) {
    try {
        console.log(`[ノード関数実行] 関数: ${functionName}, パラメータ:`, params);

        const response = await fetch(`${API_BASE}/node/execute/${functionName}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(params)
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const result = await response.json();

        if (result.success) {
            console.log(`[ノード関数実行成功] コード生成完了`);
            return result;
        } else {
            throw new Error(result.error || 'ノード関数実行に失敗しました');
        }
    } catch (error) {
        console.error('[ノード関数実行エラー]', error);
        throw error;
    }
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
    // ノードタイプセレクターを更新
    updateNodeTypeSelector();
    showModal('modal-add-node');
}

/**
 * ノードタイプセレクターを動的に更新
 */
function updateNodeTypeSelector() {
    const select = document.getElementById('input-type');
    if (!select) return;

    // 既存のオプションをクリア
    select.innerHTML = '';

    // デフォルトオプション
    const defaultOption = document.createElement('option');
    defaultOption.value = '';
    defaultOption.textContent = '-- ノードタイプを選択 --';
    select.appendChild(defaultOption);

    // 動的に読み込んだノードタイプを追加
    nodeTypes.forEach(type => {
        const option = document.createElement('option');
        option.value = type.id;
        option.textContent = type.text;
        option.dataset.functionName = type.functionName;
        option.dataset.color = type.color;
        select.appendChild(option);
    });

    console.log(`[ノードタイプセレクター更新] ${nodeTypes.length}個のオプションを追加`);
}

/**
 * ノードタイプ変更時の処理（パラメータフィールド生成）
 */
function onNodeTypeChange() {
    const typeSelect = document.getElementById('input-type');
    const selectedOption = typeSelect.selectedOptions[0];

    if (!selectedOption) return;

    const functionName = selectedOption.dataset.functionName;
    const paramsContainer = document.getElementById('node-params-container');
    const paramsInputs = document.getElementById('node-params-inputs');

    // パラメータ定義を取得
    const params = nodeParameters[functionName] || [];

    if (params.length === 0) {
        // パラメータなし
        paramsContainer.style.display = 'none';
        paramsInputs.innerHTML = '';
        return;
    }

    // パラメータ入力フィールドを生成
    paramsContainer.style.display = 'block';
    paramsInputs.innerHTML = '';

    params.forEach((param, index) => {
        const formGroup = document.createElement('div');
        formGroup.className = 'form-group';

        const label = document.createElement('label');
        label.textContent = param.name;
        formGroup.appendChild(label);

        let input;
        if (param.type === 'textarea') {
            input = document.createElement('textarea');
            input.rows = param.rows || 3;
        } else {
            input = document.createElement('input');
            input.type = param.type;
            if (param.min !== undefined) input.min = param.min;
            if (param.max !== undefined) input.max = param.max;
        }

        input.id = `param-${index}`;
        input.name = param.name;
        input.placeholder = param.placeholder || '';
        if (param.required) input.required = true;

        formGroup.appendChild(input);
        paramsInputs.appendChild(formGroup);
    });

    console.log(`[パラメータフィールド生成] ${params.length}個のパラメータを追加`);
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

    // ボタン設定を読み込み
    loadButtonSettings().then(() => {
        console.log('[初期化] ボタン設定の読み込み完了');
    }).catch(error => {
        console.error('[初期化エラー] ボタン設定の読み込み失敗:', error);
    });
}

// ============================================
// ノード管理
// ============================================

async function addNode(event) {
    event.preventDefault();

    const typeSelect = document.getElementById('input-type');
    const type = typeSelect.value;
    const text = document.getElementById('input-text').value;
    const code = document.getElementById('input-code').value;

    if (!type) {
        alert('ノードタイプを選択してください');
        return;
    }

    try {
        // 新しいIDを生成
        const idResp = await fetch(`${API_BASE}/id/generate`, { method: 'POST' });
        const idData = await idResp.json();
        const newId = idData.id;

        // 選択されたノードタイプ情報を取得
        const selectedOption = typeSelect.selectedOptions[0];
        const color = selectedOption.dataset.color || 'White';
        const functionName = selectedOption.dataset.functionName;

        // パラメータを収集
        const params = {};
        const paramsInputs = document.getElementById('node-params-inputs');
        if (paramsInputs) {
            const inputs = paramsInputs.querySelectorAll('input, textarea');
            inputs.forEach(input => {
                params[input.name] = input.value;
            });
        }

        console.log(`[ノード追加] パラメータ:`, params);

        // ノード関数が定義されている場合は実行
        let generatedCode = code;

        // 条件分岐・ループビルダーの場合は専用ダイアログを表示
        if (functionName === 'ShowConditionBuilder') {
            try {
                console.log(`[ノード追加] 条件分岐ビルダーを表示`);
                const dialogCode = await showConditionBuilderDialog(false);
                if (dialogCode) {
                    generatedCode = dialogCode;
                    console.log(`[ノード追加] 条件分岐コード:`, generatedCode);
                } else {
                    console.log(`[ノード追加] 条件分岐がキャンセルされました`);
                    return; // キャンセル時はノード追加しない
                }
            } catch (error) {
                console.error(`[ノード追加] 条件分岐ビルダーエラー:`, error);
                alert(`条件分岐ビルダーエラー: ${error.message}`);
                return;
            }
        } else if (functionName === 'ShowLoopBuilder') {
            try {
                console.log(`[ノード追加] ループビルダーを表示`);
                const dialogCode = await showLoopBuilderDialog();
                if (dialogCode) {
                    generatedCode = dialogCode;
                    console.log(`[ノード追加] ループコード:`, generatedCode);
                } else {
                    console.log(`[ノード追加] ループがキャンセルされました`);
                    return; // キャンセル時はノード追加しない
                }
            } catch (error) {
                console.error(`[ノード追加] ループビルダーエラー:`, error);
                alert(`ループビルダーエラー: ${error.message}`);
                return;
            }
        } else if (functionName) {
            // 通常のノード関数を実行
            try {
                console.log(`[ノード追加] 関数実行: ${functionName}`);
                const result = await executeNodeFunction(functionName, params);
                if (result.success && result.code) {
                    generatedCode = result.code;
                    console.log(`[ノード追加] 生成されたコード:`, generatedCode);
                }
            } catch (funcError) {
                console.error(`[ノード追加] 関数実行エラー:`, funcError);
                alert(`関数実行エラー: ${funcError.message}\n\nノードは追加されますが、コードは生成されませんでした。`);
                // 関数実行が失敗してもノード追加は続行
            }
        }

        // CSSクラスを色に基づいて決定
        let cssClass = '';
        if (color === 'SpringGreen') {
            cssClass = 'node-conditional';
        } else if (color === 'LemonChiffon') {
            cssClass = 'node-loop';
        } else if (color === 'Gray') {
            cssClass = 'node-start';
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
                code: generatedCode,  // 関数で生成されたコードまたはユーザー入力コード
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
// 条件分岐ビルダー
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

// ============================================
// ループビルダー
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

// ============================================
// ダイアログイベントリスナーの設定
// ============================================

function setupDialogEventListeners() {
    // 条件分岐ダイアログのイベントリスナー
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

            document.getElementById('condition-builder-modal').classList.remove('show');

            if (conditionBuilderResolver) {
                conditionBuilderResolver(code);
                conditionBuilderResolver = null;
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

    // ループダイアログのイベントリスナー
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

            document.getElementById('loop-builder-modal').classList.remove('show');

            if (loopBuilderResolver) {
                loopBuilderResolver(code);
                loopBuilderResolver = null;
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

    // ダイアログイベントリスナーを設定
    setupDialogEventListeners();
});
