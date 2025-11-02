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

// ============================================
// 初期化
// ============================================

document.addEventListener('DOMContentLoaded', async () => {
    console.log('UIpowershell Legacy UI initialized');

    // API接続テスト
    await testApiConnection();

    // ボタン設定.jsonを読み込み
    await loadButtonSettings();

    // カテゴリーパネルにノード追加ボタンを生成
    generateAddNodeButtons();

    // 既存のノードを読み込み（memory.jsonから）
    await loadExistingNodes();

    // イベントリスナー設定
    setupEventListeners();

    // 変数を読み込み
    await loadVariables();

    // フォルダ一覧を読み込み
    await loadFolders();
});

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
    const nodeId = `node-${nodeCounter++}`;

    const node = {
        id: nodeId,
        name: setting.ボタン名,
        text: setting.テキスト,
        color: setting.背景色,
        layer: currentLayer,
        y: getNextAvailableY(currentLayer),
        groupId: null,
        処理番号: setting.処理番号,
        関数名: setting.関数名
    };

    nodes.push(node);
    layerStructure[currentLayer].nodes.push(node);

    renderNodesInLayer(currentLayer);

    // 上詰め再配置
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
        btn.textContent = node.text;
        btn.style.backgroundColor = getColorCode(node.color);
        btn.style.top = `${node.y}px`;
        btn.dataset.nodeId = node.id;
        btn.draggable = true;

        // ドラッグイベント
        btn.addEventListener('dragstart', handleDragStart);
        btn.addEventListener('dragend', handleDragEnd);
        btn.addEventListener('dragover', handleDragOver);
        btn.addEventListener('drop', handleDrop);

        // 右クリックメニュー
        btn.addEventListener('contextmenu', (e) => {
            e.preventDefault();
            showContextMenu(e, node);
        });

        // マウスオーバーで説明表示（該当する設定を検索）
        const setting = buttonSettings.find(s => s.処理番号 === node.処理番号);
        if (setting) {
            btn.onmouseenter = () => {
                document.getElementById('description-text').textContent = setting.説明 || '';
            };
        }

        container.appendChild(btn);
    });
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

        // ノード配列内で位置を入れ替え
        swapNodes(currentLayer, draggedNodeId, targetNodeId);

        // 再描画
        renderNodesInLayer(currentLayer);
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

    alert(`スクリプト編集機能（ノード: ${contextMenuTarget.text}）\n\n※この機能は実装予定です。`);
    hideContextMenu();
}

// スクリプト実行
function executeScript() {
    if (!contextMenuTarget) return;

    alert(`スクリプト実行機能（ノード: ${contextMenuTarget.text}）\n\n※この機能は実装予定です。`);
    hideContextMenu();
}

// レイヤー化
function layerizeNode() {
    if (!contextMenuTarget) return;

    alert(`レイヤー化機能（ノード: ${contextMenuTarget.text}）\n\n※この機能は実装予定です。`);
    hideContextMenu();
}

// ノード削除
async function deleteNode() {
    if (!contextMenuTarget) return;

    const confirmed = confirm(`「${contextMenuTarget.text}」を削除しますか？`);
    if (!confirmed) {
        hideContextMenu();
        return;
    }

    // セット削除チェック（条件分岐・ループ）
    try {
        const result = await callApi(`/nodes/${contextMenuTarget.id}`, 'DELETE', {
            nodes: nodes.map(n => ({
                id: n.id,
                text: n.text,
                color: n.color,
                y: n.y,
                groupId: n.groupId
            }))
        });

        if (result.success) {
            // 削除対象のIDリスト
            const deleteTargets = result.deleteTargets || [contextMenuTarget.id];

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
        }
    } catch (error) {
        console.error('削除エラー:', error);
        // フォールバック：単純削除
        const index = nodes.findIndex(n => n.id === contextMenuTarget.id);
        if (index !== -1) {
            nodes.splice(index, 1);
        }

        const layerIndex = layerStructure[currentLayer].nodes.findIndex(n => n.id === contextMenuTarget.id);
        if (layerIndex !== -1) {
            layerStructure[currentLayer].nodes.splice(layerIndex, 1);
        }

        renderNodesInLayer(currentLayer);
        reorderNodesInLayer(currentLayer);
    }

    hideContextMenu();
}

// 全削除
function deleteAllNodes() {
    const confirmed = confirm('すべてのノードを削除しますか？');
    if (!confirmed) return;

    layerStructure[currentLayer].nodes = [];
    nodes = nodes.filter(n => n.layer !== currentLayer);

    renderNodesInLayer(currentLayer);
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
    });

    document.getElementById(`layer-${currentLayer}`).classList.add('active');

    // ラベル更新
    document.getElementById('current-layer-label').textContent = `レイヤー${currentLayer}`;
    document.getElementById('path-text').textContent = `レイヤー${currentLayer}`;
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

function addVariablePrompt() {
    const name = prompt('変数名を入力してください:');
    if (!name || name.trim() === '') return;

    const value = prompt('値を入力してください:');

    variables[name] = {
        value: value || '',
        type: '単一値'
    };

    renderVariableTable();
}

function editVariable(name) {
    const value = prompt(`「${name}」の新しい値を入力してください:`, variables[name].value);
    if (value !== null) {
        variables[name].value = value;
        renderVariableTable();
    }
}

function deleteVariable(name) {
    const confirmed = confirm(`変数「${name}」を削除しますか？`);
    if (confirmed) {
        delete variables[name];
        renderVariableTable();
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
            alert(`コード生成成功！\n\n出力先: ${result.outputPath}\nノード数: ${result.nodeCount}`);
        } else {
            alert(`コード生成失敗: ${result.error}`);
        }
    } catch (error) {
        console.error('コード生成エラー:', error);
        alert(`コード生成中にエラーが発生しました: ${error.message}`);
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
        // memory.jsonからノード配置を読み込み
        // ※この機能は将来実装
        console.log('既存ノード読み込み（memory.json）- 実装予定');
    } catch (error) {
        console.error('既存ノード読み込み失敗:', error);
    }
}

// ============================================
// イベントリスナー設定
// ============================================

function setupEventListeners() {
    // ドキュメント全体のクリックで右クリックメニューを閉じる
    document.addEventListener('click', () => {
        hideContextMenu();
    });

    // ESCキーでモーダルを閉じる
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            closeVariableModal();
            closeFolderModal();
        }
    });
}
