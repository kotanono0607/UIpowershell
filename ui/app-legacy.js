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
        x: 90,                              // X座標（中央寄せ）
        y: getNextAvailableY(currentLayer),
        width: 280,                         // ボタン幅
        height: 40,                         // ボタン高さ
        groupId: null,
        処理番号: setting.処理番号,
        関数名: setting.関数名,
        script: ''                          // スクリプト初期値
    };

    nodes.push(node);
    layerStructure[currentLayer].nodes.push(node);

    renderNodesInLayer(currentLayer);

    // 上詰め再配置
    reorderNodesInLayer(currentLayer);

    // memory.json自動保存
    saveMemoryJson();
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

        // ダブルクリックで詳細設定を開く
        btn.addEventListener('dblclick', () => {
            openNodeSettings(node);
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

// レイヤー化（ノードを別のレイヤーに移動）
function layerizeNode() {
    if (!contextMenuTarget) {
        alert('ノードが選択されていません。');
        return;
    }

    // 移動先レイヤーを入力
    const targetLayerStr = prompt(`「${contextMenuTarget.text}」を移動するレイヤーを選択してください:\n\n0 - レイヤー0（非表示左）\n1 - レイヤー1\n2 - レイヤー2\n3 - レイヤー3（非表示右）\n4 - レイヤー4（非表示右）\n5 - レイヤー5（非表示右）\n6 - レイヤー6（非表示右）\n\n移動先レイヤー番号を入力:`);

    if (targetLayerStr === null) {
        hideContextMenu();
        return; // キャンセル
    }

    const targetLayer = parseInt(targetLayerStr);

    // バリデーション
    if (isNaN(targetLayer) || targetLayer < 0 || targetLayer > 6) {
        alert('無効なレイヤー番号です。0-6の範囲で入力してください。');
        hideContextMenu();
        return;
    }

    const currentLayerNum = contextMenuTarget.layer;

    if (targetLayer === currentLayerNum) {
        alert('同じレイヤーには移動できません。');
        hideContextMenu();
        return;
    }

    // 現在のレイヤーから削除
    const nodeIndex = layerStructure[currentLayerNum].nodes.findIndex(n => n.id === contextMenuTarget.id);
    if (nodeIndex !== -1) {
        layerStructure[currentLayerNum].nodes.splice(nodeIndex, 1);
    }

    // グローバルノード配列からも更新
    const globalNodeIndex = nodes.findIndex(n => n.id === contextMenuTarget.id);
    if (globalNodeIndex !== -1) {
        nodes[globalNodeIndex].layer = targetLayer;
        contextMenuTarget.layer = targetLayer;

        // 移動先レイヤーに追加
        layerStructure[targetLayer].nodes.push(nodes[globalNodeIndex]);
    }

    // 現在のレイヤーを再描画
    renderNodesInLayer(currentLayerNum);

    console.log(`ノード「${contextMenuTarget.text}」をレイヤー${currentLayerNum} → レイヤー${targetLayer}に移動しました`);
    alert(`ノード「${contextMenuTarget.text}」をレイヤー${targetLayer}に移動しました。`);

    // memory.json自動保存
    saveMemoryJson();

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

            // memory.json自動保存
            saveMemoryJson();
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

        // memory.json自動保存
        saveMemoryJson();
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
    targetPanel.classList.add('active');
    targetPanel.style.display = 'flex';

    // ラベル更新
    document.getElementById('current-layer-label').textContent = `レイヤー${currentLayer}`;
    document.getElementById('path-text').textContent = `レイヤー${currentLayer}`;

    // 現在のレイヤーを再描画
    renderNodesInLayer(currentLayer);
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
            closeScriptModal();
            closeNodeSettingsModal();
        }
    });
}
