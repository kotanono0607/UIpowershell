// ============================================
// UIpowershell - Legacy UI JavaScript
// 既存Windows Forms版の完全再現
// ============================================

const APP_VERSION = '1.0.206';  // アプリバージョン
const API_BASE = 'http://localhost:8080/api';

// ============================================
// デバッグ設定
// ============================================

// ログフィルター設定（true = 表示, false = 非表示）
const DEBUG_FLAGS = {
    layerize: false,         // レイヤー化処理のログ
    parentPinkNode: false,   // 親ピンクノード更新のログ
    nodeOperation: false,    // ノード操作のログ（追加・削除など）
    arrow: false,            // 矢印描画のログ
    rendering: false,        // レンダリング処理のログ
    memory: false,           // memory.json保存のログ
    other: false             // その他のログ
};

// レイヤーナビゲーション用ログ設定
const LOG_CONFIG = {
    breadcrumb: false,       // パンくずリストのログ
    pink: true,              // ピンクノード処理のログ（デバッグ用に有効化）
    initialization: false    // 初期化処理のログ
};

// フィルター付きログ関数
function debugLog(category, ...args) {
    if (DEBUG_FLAGS[category]) {
        console.log(...args);
    }
}

// ============================================
// ブラウザコンソールログキャプチャ
// ============================================

// オリジナルのconsoleメソッドを保存
const originalConsole = {
    log: console.log,
    error: console.error,
    warn: console.warn,
    info: console.info,
    debug: console.debug
};

// ログバッファ
let consoleLogBuffer = [];

// ログをサーバーに送信
async function sendLogsToServer(logs) {
    if (logs.length === 0) return;

    try {
        await fetch(`${API_BASE}/browser-logs`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                logs: logs,
                timestamp: new Date().toISOString(),
                userAgent: navigator.userAgent
            })
        });
    } catch (err) {
        // サーバー送信失敗時はオリジナルconsoleに出力のみ
        originalConsole.error('[ログ送信エラー]', err);
    }
}

// コンソールメソッドをラップ（ログフィルター付き）
function wrapConsoleMethod(method, level) {
    console[method] = function(...args) {
        // console.logのみフィルターを適用
        if (method === 'log') {
            // ログメッセージを文字列化
            const message = args.map(arg => String(arg)).join(' ');

            // 重要なログのみを通過させる
            const importantPrefixes = [
                '❌', '✅', '⚠'  // エラー・成功・警告マーカーのみ
            ];

            // 重要なログ以外は抑制
            if (!importantPrefixes.some(prefix => message.includes(prefix))) {
                // サーバーにはログを送るが、ブラウザコンソールには表示しない
                const logEntry = {
                    level: level,
                    timestamp: new Date().toISOString(),
                    message: message
                };
                consoleLogBuffer.push(logEntry);
                return; // ブラウザコンソールへの出力をスキップ
            }
        }

        // オリジナルのconsoleを実行（重要なログとerror/warn/info/debugは全て表示）
        originalConsole[method].apply(console, args);

        // ログをバッファに追加
        const logEntry = {
            level: level,
            timestamp: new Date().toISOString(),
            message: args.map(arg => {
                if (typeof arg === 'object') {
                    try {
                        return JSON.stringify(arg);
                    } catch (e) {
                        return String(arg);
                    }
                }
                return String(arg);
            }).join(' ')
        };

        consoleLogBuffer.push(logEntry);

        // エラーは即座に送信
        if (level === 'error') {
            sendLogsToServer([logEntry]);
            consoleLogBuffer = consoleLogBuffer.filter(log => log !== logEntry);
        }
    };
}

// console.log, error, warn, info, debugをラップ
wrapConsoleMethod('log', 'log');
wrapConsoleMethod('error', 'error');
wrapConsoleMethod('warn', 'warn');
wrapConsoleMethod('info', 'info');
wrapConsoleMethod('debug', 'debug');

// 定期的にバッファをサーバーに送信（5秒ごと）
setInterval(() => {
    if (consoleLogBuffer.length > 0) {
        const logsToSend = [...consoleLogBuffer];
        consoleLogBuffer = [];
        sendLogsToServer(logsToSend);
    }
}, 5000);

// ページアンロード時に残りのログを送信
window.addEventListener('beforeunload', () => {
    if (consoleLogBuffer.length > 0) {
        const logsToSend = [...consoleLogBuffer];
        // sendBeacon APIを使用（非同期で確実に送信）
        const data = JSON.stringify({
            logs: logsToSend,
            timestamp: new Date().toISOString(),
            userAgent: navigator.userAgent
        });
        navigator.sendBeacon(`${API_BASE}/browser-logs`, new Blob([data], { type: 'application/json' }));
    }
});

console.log('[ブラウザログ] コンソールログキャプチャ機能を初期化しました');

// ============================================
// グローバル状態
// ============================================

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

// グローエフェクト状態管理
const glowState = {
    sourceNode: null,      // グロー元のピンクノード
    sourceLayer: null,     // グロー元のレイヤー
    targetLayer: null      // グローターゲットのレイヤー（展開先）
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

    // 右パネルはドリルダウンパネルに変更されたため、Canvas初期化は不要
    // ドリルダウンパネルのCanvasは動的に生成される

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

    const ctx = leftCanvas.getContext('2d', { willReadFrequently: true });
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
// 注: 右パネルがドリルダウンパネルに変更されたため、この関数は無効化
function drawRightPanelPinkArrows() {
    // ドリルダウンパネルでは矢印は描画しない
    return;
}

function drawPanelArrows(layerId) {
    // 右パネル（*-right）はスキップ
    if (layerId.includes('-right')) {
        return;
    }

    // console.log(`[デバッグ] drawPanelArrows() 呼び出し: layerId=${layerId}`);

    const canvas = arrowState.canvasMap.get(layerId);
    if (!canvas) {
        // 右パネルのCanvasが見つからない場合は警告を出さない
        if (!layerId.includes('-right')) {
            console.error(`[デバッグ] Canvas が見つかりません: ${layerId}`);
        }
        return;
    }

    const layerPanel = document.getElementById(layerId);
    if (!layerPanel) {
        if (!layerId.includes('-right')) {
            console.error(`[デバッグ] レイヤーパネルが見つかりません: ${layerId}`);
        }
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

    const ctx = canvas.getContext('2d', { willReadFrequently: true });
    console.log(`[Canvas デバッグ] Context:`, ctx);
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    console.log(`[Canvas デバッグ] clearRect完了: (0, 0, ${canvas.width}, ${canvas.height})`);
    ctx.imageSmoothingEnabled = true;

    const nodes = Array.from(layerPanel.querySelectorAll('.node-button'));
    // console.log(`[デバッグ] 取得したノード数: ${nodes.length}`);

    // ノードをY座標でソート
    nodes.sort((a, b) => {
        const aRect = a.getBoundingClientRect();
        const bRect = b.getBoundingClientRect();
        return aRect.top - bRect.top;
    });

    // 条件分岐グループを特定
    const conditionGroups = findConditionGroups(nodes);
    // console.log(`[デバッグ] 条件分岐グループ数: ${conditionGroups.length}`);

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
        // 注: 赤→赤と青→青はdrawConditionalBranchArrows内で処理されるため、ここでは削除
    }
    // console.log(`[デバッグ] 描画した通常矢印数: ${arrowCount}`);

    // コンテナの矩形を取得（条件分岐とループで共通使用）
    const containerRect = nodeListContainer.getBoundingClientRect();

    // 条件分岐の特別な矢印を描画
    conditionGroups.forEach(group => {
        drawConditionalBranchArrows(ctx, group.startNode, group.endNode, group.innerNodes, containerRect);
    });

    // ループの矢印を描画
    const loopGroups = findLoopGroups(nodes);
    // console.log(`[デバッグ] ループグループ数: ${loopGroups.length}`);
    loopGroups.forEach(group => {
        drawLoopArrows(ctx, group.startNode, group.endNode, containerRect);
    });

    // console.log(`[デバッグ] drawPanelArrows() 完了: ${layerId}`);

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

    // 内部ノードを赤、Gray、青に分類
    console.log(`[条件分岐デバッグ] innerNodes数: ${innerNodes.length}`);
    innerNodes.forEach((node, index) => {
        const computedColor = window.getComputedStyle(node).backgroundColor;
        console.log(`  [${index}] text="${node.textContent}", color="${computedColor}"`);
    });

    const redNodes = innerNodes.filter(node => isSalmonColor(window.getComputedStyle(node).backgroundColor));
    const grayNodes = innerNodes.filter(node => isGrayColor(window.getComputedStyle(node).backgroundColor));
    const blueNodes = innerNodes.filter(node => isBlueColor(window.getComputedStyle(node).backgroundColor));

    console.log(`[条件分岐] 赤ノード数: ${redNodes.length}, Grayノード数: ${grayNodes.length}, 青ノード数: ${blueNodes.length}`);

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

        ctx.strokeStyle = 'rgb(200, 220, 255)';  // v1.0.187の仕様：薄い青
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
    // v1.0.187の仕様：青ノードの有無に関係なく常に描画
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

    // 4. innerNodes間の矢印を描画（赤ノード間、Gray含む、青ノード間）
    for (let i = 0; i < innerNodes.length - 1; i++) {
        const currentNode = innerNodes[i];
        const nextNode = innerNodes[i + 1];
        const currentColor = window.getComputedStyle(currentNode).backgroundColor;
        const nextColor = window.getComputedStyle(nextNode).backgroundColor;

        // 矢印の色を決定（現在と次のノードの色に基づく）
        let arrowColor = '#000000'; // デフォルト

        // 青→青の場合
        if (isBlueColor(currentColor) && isBlueColor(nextColor)) {
            arrowColor = 'rgb(200, 220, 255)'; // v1.0.187の仕様：薄い青
        }
        // 赤→赤またはGray関連の場合
        else if ((isSalmonColor(currentColor) || isGrayColor(currentColor)) &&
                 (isSalmonColor(nextColor) || isGrayColor(nextColor))) {
            arrowColor = 'rgb(250, 128, 114)'; // 赤色
        }

        // 下向き矢印を描画
        drawDownArrow(ctx, currentNode, nextNode, arrowColor);
        console.log(`[条件分岐] innerNodes間矢印: ${currentNode.textContent} → ${nextNode.textContent} (色: ${arrowColor})`);
    }

    // 5. 青（True分岐）→ 緑（終了）への下向き矢印
    if (blueNodes.length > 0) {
        const lastBlue = blueNodes[blueNodes.length - 1];
        drawDownArrow(ctx, lastBlue, endNode, 'rgb(200, 220, 255)');  // v1.0.187の仕様：薄い青
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

// 色がGray（条件分岐の中間ノード）かどうかを判定
function isGrayColor(colorString) {
    // rgb() と rgba() の両方に対応
    const match = colorString.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
    if (match) {
        const r = parseInt(match[1]);
        const g = parseInt(match[2]);
        const b = parseInt(match[3]);
        return r === 128 && g === 128 && b === 128;
    }
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
        const isPink = (r === 255 && g === 192 && b === 203) || // Standard Pink
               (r === 227 && g === 206 && b === 229) || // ピンク青色
               (r === 252 && g === 160 && b === 158);   // ピンク赤色

        if (LOG_CONFIG.pink) {
            console.log(`[ピンク検出] 色: ${colorString}, RGB: (${r},${g},${b}), ピンク判定: ${isPink}`);
        }
        return isPink;
    }
    return false;
}

// パネル間矢印を描画（ピンクノードのスクリプト展開用）
function drawCrossPanelArrows() {
    const mainCanvas = arrowState.canvasMap.get('main');
    if (!mainCanvas) return;

    const ctx = mainCanvas.getContext('2d', { willReadFrequently: true });
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

    // パネル間矢印は不要（グローエフェクトで表現）
    // drawCrossPanelPinkArrows();
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
    const ctx = canvas.getContext('2d', { willReadFrequently: true });
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

    // 右パネルが存在しない場合は処理をスキップ（右パネルは削除済み）
    if (!rightPanel || !toggleBtn) {
        return;
    }

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
    console.log('═══════════════════════════════════════════════');
    console.log('UIpowershell Legacy UI v1.0.171 - 起動開始');
    console.log('═══════════════════════════════════════════════');

    // 矢印描画機能を初期化（arrow-drawing.jsの内容が統合されているため即座に利用可能）
    console.log('[矢印] Arrow drawing initialization...');
    initializeArrowCanvas();
    refreshAllArrows();
    window.arrowDrawing.initialized = true;
    console.log('[矢印] Arrow drawing initialized successfully');
    // console.log(`[デバッグ] Canvas数: ${window.arrowDrawing.state.canvasMap.size}`);

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

    // カテゴリーパネルにノード追加ボタンを生成（初期は無効化）
    generateAddNodeButtons();

    // イベントリスナー設定
    setupEventListeners();

    // ダイアログのイベントリスナー設定（DOM ready後）
    setupDialogEventListeners();

    // 変数を読み込み
    await loadVariables();

    // フォルダ一覧を読み込み（デフォルトフォルダ自動選択）
    console.log('[初期化] フォルダ初期化を開始...');
    await loadFolders();
    console.log('[初期化] ✅ フォルダ初期化完了 - currentFolder:', currentFolder);

    // ボタンを有効化
    enableAddNodeButtons();

    // 既存のノードを読み込み（memory.jsonから）
    // ※loadFolders()の後に実行（currentFolderが設定された後）
    await loadExistingNodes();

    console.log('═══════════════════════════════════════════════');
    console.log(`✅ UIpowershell 初期化完了 [Version: ${APP_VERSION}]`);
    console.log('═══════════════════════════════════════════════');

    // 横スクロールバー問題のデバッグ
    setTimeout(() => {
        const leftPanel = document.getElementById('left-panel');
        const categoryButtons = document.getElementById('category-buttons');
        const nodeContainer = document.getElementById('node-buttons-container');

        if (leftPanel && categoryButtons && nodeContainer) {
            const leftPanelWidth = leftPanel.offsetWidth;
            const leftPanelPadding = parseInt(getComputedStyle(leftPanel).paddingLeft) + parseInt(getComputedStyle(leftPanel).paddingRight);
            const leftPanelGap = parseInt(getComputedStyle(leftPanel).gap);
            const availableWidth = leftPanelWidth - leftPanelPadding;

            const categoryWidth = categoryButtons.offsetWidth;
            const containerWidth = nodeContainer.offsetWidth;
            const totalChildWidth = categoryWidth + leftPanelGap + containerWidth;

            const overflow = totalChildWidth - availableWidth;

            if (overflow > 0) {
                console.warn(`[横スクロール] はみ出し +${overflow}px（推奨: コンテナ ${containerWidth - overflow - 5}px以下）`);
            }
        }
    }, 500);
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
        btn.disabled = true;  // 初期化完了まで無効化

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
                // 条件分岐ビルダーの場合はダイアログを表示
                if (setting.関数名 === 'ShowConditionBuilder') {
                    console.log('[ボタンクリック] 条件分岐ビルダーダイアログを表示します');
                    const dialogCode = await showConditionBuilderDialog(false);
                    if (dialogCode) {
                        console.log('[ボタンクリック] 条件分岐コードを取得しました');
                        await addNodeToLayer(setting);
                    } else {
                        console.log('[ボタンクリック] 条件分岐がキャンセルされました');
                        return; // キャンセル時は何もしない
                    }
                }
                // ループビルダーの場合はダイアログを表示
                else if (setting.関数名 === 'ShowLoopBuilder') {
                    console.log('[ボタンクリック] ループビルダーダイアログを表示します');
                    const dialogCode = await showLoopBuilderDialog();
                    if (dialogCode) {
                        console.log('[ボタンクリック] ループコードを取得しました');
                        await addNodeToLayer(setting);
                    } else {
                        console.log('[ボタンクリック] ループがキャンセルされました');
                        return; // キャンセル時は何もしない
                    }
                }
                // その他のボタンは直接ノード追加
                else {
                    await addNodeToLayer(setting);
                }
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
    console.log(`[ボタン生成] ℹ️  ボタンは初期化完了まで無効化されています`);
}

// ノード追加ボタンを有効化
function enableAddNodeButtons() {
    console.log('[ボタン有効化] 開始...');
    const buttons = document.querySelectorAll('.add-node-btn');
    let count = 0;
    buttons.forEach(btn => {
        btn.disabled = false;
        count++;
    });
    console.log(`[ボタン有効化] ✅ ${count}個のボタンを有効化しました`);
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

// 親ピンクノードのスクリプトを更新する関数
async function updateParentPinkNode(addedNodes, deletedNodes = []) {
    console.log('[親ピンクノード更新] 開始');
    console.log('[親ピンクノード更新] 現在のレイヤー:', leftVisibleLayer);
    console.log('[親ピンクノード更新] 追加ノード数:', addedNodes.length);
    console.log('[親ピンクノード更新] 削除ノード数:', deletedNodes.length);

    // レイヤー1の場合は親がいないのでスキップ
    if (leftVisibleLayer < 2) {
        console.log('[親ピンクノード更新] レイヤー1なので親ピンクノードなし');
        return;
    }

    const parentLayer = leftVisibleLayer - 1;
    const parentPinkNodeId = pinkSelectionArray[parentLayer].expandedNode;

    console.log('[親ピンクノード更新] 親レイヤー:', parentLayer);
    console.log('[親ピンクノード更新] 親ピンクノードID:', parentPinkNodeId);

    if (!parentPinkNodeId) {
        console.warn('[親ピンクノード更新] 親ピンクノードIDが見つかりません');
        return;
    }

    // 親ピンクノードを取得
    const parentPinkNode = layerStructure[parentLayer].nodes.find(n => n.id === parentPinkNodeId);

    if (!parentPinkNode) {
        console.error('[親ピンクノード更新] 親ピンクノードが見つかりません:', parentPinkNodeId);
        return;
    }

    console.log('[親ピンクノード更新] 親ピンクノード取得成功:', parentPinkNode);

    // ★★★ 追加: 削除されたノードを親ピンクノードのscriptから除去 ★★★
    let insertionIndex = -1;  // 新しいノードを挿入する位置
    if (deletedNodes.length > 0) {
        console.log('[親ピンクノード更新] 削除ノードを親scriptから除去します');

        // 削除対象のノードIDセット
        const deletedNodeIds = new Set(deletedNodes.map(n => n.id));

        // 削除されたノードの中で最小Y座標のノードを取得（挿入位置の基準）
        const sortedDeletedNodes = [...deletedNodes].sort((a, b) => a.y - b.y);
        const firstDeletedNodeId = sortedDeletedNodes[0].id;
        console.log(`[親ピンクノード更新] 最初の削除ノードID: ${firstDeletedNodeId}`);

        // 親ピンクノードのscriptをエントリごとに分割
        const entries = parentPinkNode.script ? parentPinkNode.script.split('_').filter(e => e.trim() !== '') : [];
        console.log(`[親ピンクノード更新] 元のエントリ数: ${entries.length}`);

        // 削除されていないエントリのみ保持し、挿入位置を記録
        const remainingEntries = [];
        entries.forEach((entry, index) => {
            const parts = entry.split(';');
            const nodeId = parseInt(parts[0]);
            const isDeleted = deletedNodeIds.has(nodeId);

            if (isDeleted) {
                // 最初に削除されるエントリの位置を記録
                if (insertionIndex === -1 && nodeId === firstDeletedNodeId) {
                    insertionIndex = remainingEntries.length;
                    console.log(`[親ピンクノード更新] 挿入位置を記録: インデックス=${insertionIndex}`);
                }
                console.log(`[親ピンクノード更新] エントリ削除: ID=${nodeId}, entry="${entry}"`);
            } else {
                remainingEntries.push(entry);
            }
        });

        console.log(`[親ピンクノード更新] 残りのエントリ数: ${remainingEntries.length}`);
        console.log(`[親ピンクノード更新] 挿入位置: ${insertionIndex}`);
        parentPinkNode.script = remainingEntries.join('_');
    }

    // 追加されたノードの情報を生成（形式: "ノードID;色;テキスト"）
    // 注意: Pinkノードのscriptは含めない（子ノードの情報が重複してしまうため）
    const newEntries = addedNodes.map(node =>
        `${node.id};${node.color};${node.text};`
    ).join('_');

    console.log('[親ピンクノード更新] 新しいエントリ:', newEntries);

    // 親ピンクノードのscriptに追加（削除された位置に挿入）
    if (parentPinkNode.script && parentPinkNode.script.trim() !== '') {
        const entries = parentPinkNode.script.split('_').filter(e => e.trim() !== '');

        // 挿入位置が有効な場合、その位置に挿入
        if (insertionIndex >= 0 && insertionIndex <= entries.length) {
            entries.splice(insertionIndex, 0, ...newEntries.split('_').filter(e => e.trim() !== ''));
            parentPinkNode.script = entries.join('_');
            console.log(`[親ピンクノード更新] インデックス${insertionIndex}に挿入しました`);
        } else {
            // 挿入位置が無効な場合、最後に追加（フォールバック）
            parentPinkNode.script = parentPinkNode.script + '_' + newEntries;
            console.log('[親ピンクノード更新] 最後に追加しました（フォールバック）');
        }
    } else {
        parentPinkNode.script = newEntries;
        console.log('[親ピンクノード更新] 新規作成しました');
    }

    console.log('[親ピンクノード更新] 更新後のscript:', parentPinkNode.script);

    // グローバルnodesも更新
    const globalNode = nodes.find(n => n.id === parentPinkNodeId);
    if (globalNode) {
        globalNode.script = parentPinkNode.script;
    }

    // コード.jsonに保存（"AAAA\n"プレフィックス付き、改行区切り）
    const formattedEntryString = 'AAAA\n' + parentPinkNode.script.replace(/_/g, '\n');
    console.log('[親ピンクノード更新] フォーマット後のエントリ:', formattedEntryString.substring(0, 100) + '...');

    try {
        await setCodeEntry(parentPinkNodeId, formattedEntryString);
        console.log('[親ピンクノード更新] ✅ コード.json保存成功 - ノードID:', parentPinkNodeId);
    } catch (error) {
        console.error('[親ピンクノード更新] ❌ コード.json保存エラー:', error);
        alert('親ピンクノードの更新に失敗しました。コンソールを確認してください。');
    }
}

async function addNodeToLayer(setting) {
    console.log('┌────────────────────────────────────────');
    console.log('│ [addNodeToLayer] 開始');
    console.log('├────────────────────────────────────────');
    console.log('│ 処理番号:', setting.処理番号);
    console.log('│ テキスト:', setting.テキスト);
    console.log('│ 関数名:', setting.関数名);
    console.log('│ 背景色:', setting.背景色);
    console.log('│ 現在のレイヤー:', leftVisibleLayer);
    console.log('└────────────────────────────────────────');

    let addedNodes = [];

    // 処理番号で判定してセット作成
    if (setting.処理番号 === '1-2') {
        // 条件分岐：3個セット（開始・中間・終了）
        console.log('[addNodeToLayer] 条件分岐セット追加を開始');
        addedNodes = await addConditionSet(setting);
        console.log('[addNodeToLayer] 条件分岐セット追加が完了');
    } else if (setting.処理番号 === '1-3') {
        // ループ：2個セット（開始・終了）
        console.log('[addNodeToLayer] ループセット追加を開始');
        addedNodes = await addLoopSet(setting);
        console.log('[addNodeToLayer] ループセット追加が完了');
    } else {
        // 通常ノード：1個
        console.log('[addNodeToLayer] 通常ノード追加を開始');
        const node = addSingleNode(setting);
        addedNodes = [node];
        console.log('[addNodeToLayer] ノードを作成しました - ID:', node.id, 'name:', node.name);

        // コード生成
        console.log('[addNodeToLayer] generateCode() を呼び出します');
        console.log('[addNodeToLayer]   - 処理番号:', setting.処理番号);
        console.log('[addNodeToLayer]   - ノードID:', node.id);
        console.log('[addNodeToLayer]   - ノード名:', node.name);
        console.log('[addNodeToLayer]   - 関数名:', setting.関数名);

        // ベースIDを抽出 (PowerShell互換: "1-1" → "1")
        const baseId = node.id.split('-')[0];
        console.log('[addNodeToLayer]   - ベースID:', baseId);

        try {
            const generatedCode = await generateCode(setting.処理番号, baseId);
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
        renderNodesInLayer(leftVisibleLayer);
        reorderNodesInLayer(leftVisibleLayer);
        console.log('[addNodeToLayer] 通常ノード追加が完了');
    }

    // ★ レイヤー2以降の場合、親ピンクノードに反映
    console.log('[addNodeToLayer] 追加されたノード数:', addedNodes.length);
    if (leftVisibleLayer >= 2 && addedNodes.length > 0) {
        console.log('[addNodeToLayer] 親ピンクノードに反映します');
        await updateParentPinkNode(addedNodes);
    }

    // memory.json自動保存
    console.log('[addNodeToLayer] memory.json自動保存を実行');
    saveMemoryJson();
    console.log('[addNodeToLayer] 完了');
}

// 単一ノードを追加
function addSingleNode(setting, customText = null, customY = null, customGroupId = null, customHeight = 40, customNodeId = null) {
    // カスタムIDが指定されていない場合は自動生成
    const nodeId = customNodeId || `${nodeCounter}-1`;

    // カスタムIDが指定されていない場合のみカウンタをインクリメント
    if (!customNodeId) {
        nodeCounter++;
    }

    // 中間ノード（Gray色）の場合は幅を20pxに設定
    const nodeWidth = (setting.背景色 === 'Gray') ? 20 : 120;

    const node = {
        id: nodeId,
        name: setting.ボタン名,
        text: customText || setting.テキスト,
        color: setting.背景色,
        layer: leftVisibleLayer,
        x: 90,                              // X座標（中央寄せ）
        y: customY || getNextAvailableY(leftVisibleLayer),
        width: nodeWidth,                   // ボタン幅（通常200px、中間ノード20px）
        height: customHeight,               // ボタン高さ（中間ラインは1px）
        groupId: customGroupId,
        処理番号: setting.処理番号,
        関数名: setting.関数名,
        script: ''                          // スクリプト初期値
    };

    nodes.push(node);
    layerStructure[leftVisibleLayer].nodes.push(node);

    return node;
}

// ループセット（2個）を追加
async function addLoopSet(setting) {
    const groupId = loopGroupCounter++;
    const baseY = getNextAvailableY(leftVisibleLayer);

    // ベースIDを取得してカウンタをインクリメント
    const baseId = nodeCounter;
    nodeCounter++;

    console.log(`[ループ作成] GroupID=${groupId}, ベースID=${baseId} を割り当て`);

    // 1. 開始ボタン
    const startNode = addSingleNode(
        { ...setting, テキスト: 'ループ 開始', ボタン名: `${baseId}-1` },
        'ループ 開始',
        baseY,
        groupId,
        40,
        `${baseId}-1`  // カスタムID指定
    );

    // コード生成（ループ構文） - ベースIDを渡す
    console.log(`[ループ作成] コード生成 - ベースID: ${baseId}`);
    await generateCode(setting.処理番号, `${baseId}`);

    // 2. 終了ボタン
    const endNode = addSingleNode(
        { ...setting, テキスト: 'ループ 終了', ボタン名: `${baseId}-2` },
        'ループ 終了',
        baseY + 45,
        groupId,
        40,
        `${baseId}-2`  // カスタムID指定
    );

    console.log(`[ループ作成完了] startNode.id: ${startNode.id}, endNode.id: ${endNode.id} (GroupID=${groupId}, ベースID=${baseId})`);

    renderNodesInLayer(leftVisibleLayer);
    reorderNodesInLayer(leftVisibleLayer);

    // 追加されたノードを返す
    return [startNode, endNode];
}

// 条件分岐セット（3個）を追加
async function addConditionSet(setting) {
    const groupId = conditionGroupCounter++;
    const baseY = getNextAvailableY(leftVisibleLayer);

    // ベースIDを取得してカウンタをインクリメント
    const baseId = nodeCounter;
    nodeCounter++;

    console.log(`[条件分岐作成] GroupID=${groupId}, ベースID=${baseId} を割り当て`);

    // 1. 開始ボタン（緑）
    const startNode = addSingleNode(
        { ...setting, テキスト: '条件分岐 開始', ボタン名: `${baseId}-1` },
        '条件分岐 開始',
        baseY,
        groupId,
        40,
        `${baseId}-1`  // カスタムID指定
    );

    // コード生成（条件式） - デフォルト値を設定
    console.log(`[条件分岐作成] デフォルト条件式を設定 - ベースID: ${baseId}`);
    const defaultConditionCode = `if ("1" -eq "1") {\n---\n} else {\n---\n}`;
    await setCodeEntry(`${baseId}`, defaultConditionCode);

    // 2. 中間ライン（グレー、高さ1px）
    const middleNode = addSingleNode(
        { ...setting, テキスト: '条件分岐 中間', 背景色: 'Gray', ボタン名: `${baseId}-2` },
        '条件分岐 中間',
        baseY + 45 - 5,  // 5px上に調整
        groupId,
        1,  // 高さ1px
        `${baseId}-2`  // カスタムID指定
    );

    // 3. 終了ボタン（緑）
    const endNode = addSingleNode(
        { ...setting, テキスト: '条件分岐 終了', ボタン名: `${baseId}-3` },
        '条件分岐 終了',
        baseY + 45,
        groupId,
        40,
        `${baseId}-3`  // カスタムID指定
    );

    console.log(`[条件分岐作成完了] 開始:${startNode.id}, 中間:${middleNode.id}, 終了:${endNode.id} (GroupID=${groupId}, ベースID=${baseId})`);

    renderNodesInLayer(leftVisibleLayer);
    reorderNodesInLayer(leftVisibleLayer);

    // 追加されたノードを返す
    return [startNode, middleNode, endNode];
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
    // 右パネルはドリルダウンパネルに変更されたため、スキップ
    if (panelSide === 'right') {
        // ドリルダウンパネルは別の関数で管理
        return;
    }

    // 左パネル対応: コンテナを取得
    const layerId = `layer-${layer}`;
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

        // グローエフェクトはapplyGlowEffects()で一括適用

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

    // グローエフェクトはapplyGlowEffects()で一括適用

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
// グローエフェクトを適用
// ============================================
function applyGlowEffects() {
    console.log('[グロー矢印] applyGlowEffects() 開始');

    if (!glowState.sourceNode || glowState.targetLayer === null) {
        console.log('[グロー矢印] ⚠️ グローステート無効 - スキップ');
        return;
    }

    console.log(`[グロー矢印] ソース: L${glowState.sourceLayer} ノードID="${glowState.sourceNode.id}" テキスト="${glowState.sourceNode.text}"`);

    // 1. すべてのノードからglow-sourceクラスとインラインスタイルを削除
    const existingGlowSources = document.querySelectorAll('.node-button.glow-source');
    existingGlowSources.forEach(el => {
        el.classList.remove('glow-source');
        el.style.border = '';
        el.style.borderRadius = '';
        el.style.transform = '';
        el.style.transformOrigin = '';
        el.style.zIndex = '';
        el.style.transition = '';
        el.style.boxShadow = '';
        el.style.animation = '';
        el.style.outline = '';
        el.style.outlineOffset = '';
    });

    // 2. グローソースノード（ピンクノード）を探してglow-sourceを適用
    let foundSourceNode = false;
    const allNodeButtons = document.querySelectorAll('.node-button');

    allNodeButtons.forEach(btn => {
        const nodeId = btn.dataset.nodeId;
        if (nodeId === String(glowState.sourceNode.id)) {
            btn.classList.add('glow-source');
            btn.style.zIndex = '100';
            btn.style.transition = 'all 0.3s ease';
            btn.style.outline = '3px solid rgba(255, 20, 147, 0.8)';
            btn.style.outlineOffset = '-3px';
            btn.style.boxShadow = `
                0 0 20px rgba(255, 20, 147, 0.6),
                0 0 40px rgba(255, 105, 180, 0.4),
                0 0 60px rgba(255, 182, 193, 0.3),
                0 4px 12px rgba(0, 0, 0, 0.2)
            `;
            btn.style.animation = 'glowPulse 2s ease-in-out infinite';
            foundSourceNode = true;
        }
    });

    if (!foundSourceNode) {
        console.warn(`[グロー矢印] ❌ ソースノード未発見 ID="${glowState.sourceNode.id}"`);
        return;
    }

    // 3. すべての既存のグロー矢印を削除
    const existingArrows = document.querySelectorAll('.glow-arrow-indicator');
    existingArrows.forEach(el => el.remove());

    // 4. ソースノードの位置を取得して、親コンテナに矢印を配置
    const sourceNodeElement = document.querySelector(`.node-button[data-node-id="${glowState.sourceNode.id}"]`);

    console.log(`[グロー矢印] sourceNodeElement検索結果:`, sourceNodeElement ? '✅ 発見' : '❌ 未発見');

    if (sourceNodeElement) {
        // ノードの親コンテナ（.node-list-container）を取得
        const container = sourceNodeElement.closest('.node-list-container');
        if (!container) {
            console.error(`[グロー矢印] ❌ 親コンテナが見つかりません`);
            return;
        }

        // ノードの位置を取得（親コンテナからの相対位置）
        const containerRect = container.getBoundingClientRect();
        const nodeRect = sourceNodeElement.getBoundingClientRect();

        // コンテナ内での相対位置を計算
        const relativeTop = nodeRect.top - containerRect.top + container.scrollTop;
        const relativeLeft = nodeRect.left - containerRect.left + container.scrollLeft;

        console.log(`[グロー矢印] ノード位置 top=${relativeTop.toFixed(0)}px left=${relativeLeft.toFixed(0)}px w=${nodeRect.width.toFixed(0)}px h=${nodeRect.height.toFixed(0)}px`);

        // グロー矢印要素を作成
        const arrowIndicator = document.createElement('div');
        arrowIndicator.className = 'glow-arrow-indicator';
        arrowIndicator.textContent = '▶';

        // 矢印を絶対配置（ノードの右端 + 5px、縦中央）
        // 矢印の高さは約24px（font-size）なので、その半分の12pxを引いて中央配置
        arrowIndicator.style.position = 'absolute';
        arrowIndicator.style.left = `${relativeLeft + nodeRect.width + 5}px`;
        arrowIndicator.style.top = `${relativeTop + nodeRect.height / 2 - 12}px`;

        // コンテナに追加（ノードではなくコンテナに追加）
        container.appendChild(arrowIndicator);

        console.log(`[グロー矢印] ✅ 矢印追加完了 left=${relativeLeft + nodeRect.width + 5}px top=${relativeTop + nodeRect.height / 2}px`);

        // 矢印が実際に表示されているか確認
        setTimeout(() => {
            const arrowRect = arrowIndicator.getBoundingClientRect();
            console.log(`[グロー矢印検証] 矢印位置 x=${arrowRect.left.toFixed(0)} y=${arrowRect.top.toFixed(0)} w=${arrowRect.width.toFixed(0)} h=${arrowRect.height.toFixed(0)}`);
            console.log(`[グロー矢印検証] 矢印は${arrowRect.width > 0 && arrowRect.height > 0 ? '✅ 表示中' : '❌ 非表示'}`);
        }, 100);
    } else {
        console.error(`[グロー矢印] ❌ ノード要素が見つかりません ID="${glowState.sourceNode.id}"`);
    }

    console.log('[グロー矢印] applyGlowEffects() 完了');
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
    const draggedNodeData = layerStructure[leftVisibleLayer].nodes.find(n => n.id === draggedNodeId);

    if (!draggedNodeData) {
        return false;
    }

    let newY;

    // ケース1: ノードボタンへのドロップ（位置を入れ替え）
    if (target.classList.contains('node-button') && target !== draggedNode) {
        const targetNodeId = target.dataset.nodeId;
        const targetNodeData = layerStructure[leftVisibleLayer].nodes.find(n => n.id === targetNodeId);

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
    reorderNodesInLayer(leftVisibleLayer);

    // 再描画
    renderNodesInLayer(leftVisibleLayer);

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

    console.log(`[色変更] reorderNodesInLayer レイヤー${layer}: ${layerNodes.length}個のノード`);

    // "条件分岐 開始"、"条件分岐 中間"、"条件分岐 終了"の位置を特定
    let startIndex = -1;
    let middleIndex = -1;
    let endIndex = -1;

    for (let i = 0; i < layerNodes.length; i++) {
        if (layerNodes[i].text === '条件分岐 開始') {
            startIndex = i;
            console.log(`[色変更] 条件分岐 開始 見つかった: index=${i}`);
        }
        if (layerNodes[i].text === '条件分岐 中間') {
            middleIndex = i;
            console.log(`[色変更] 条件分岐 中間 見つかった: index=${i}`);
        }
        if (layerNodes[i].text === '条件分岐 終了') {
            endIndex = i;
            console.log(`[色変更] 条件分岐 終了 見つかった: index=${i}`);
        }
    }

    console.log(`[色変更] インデックス: 開始=${startIndex}, 中間=${middleIndex}, 終了=${endIndex}`);

    // 条件分岐が存在するかチェック
    const hasConditionBranch = (startIndex !== -1 && middleIndex !== -1 && endIndex !== -1);
    console.log(`[色変更] 条件分岐の存在: ${hasConditionBranch}`);

    let currentY = 10;

    layerNodes.forEach((node, index) => {
        const buttonText = node.text;
        const beforeColor = node.color;

        // 条件分岐が存在する場合のみ色変更を行う
        if (hasConditionBranch) {
            // ボタンの色を設定する条件分岐（PowerShellの実装に準拠）
            if (index > startIndex && index < middleIndex) {
                // 開始〜中間の間: Salmon（False分岐）
                // スクリプト化ノードは除外（Pinkのまま）
                if (node.color !== 'Pink') {
                    node.color = 'Salmon';
                    console.log(`[色変更] index=${index} "${node.text}": ${beforeColor} → Salmon (False分岐)`);
                }
            } else if (index > middleIndex && index < endIndex) {
                // 中間〜終了の間: LightBlue（True分岐）
                // スクリプト化ノードは除外（Pinkのまま）
                if (node.color !== 'Pink') {
                    node.color = 'LightBlue';
                    console.log(`[色変更] index=${index} "${node.text}": ${beforeColor} → LightBlue (True分岐)`);
                }
            } else {
                // 条件分岐の外側：SalmonまたはLightBlueの場合はWhiteに戻す
                if (node.color === 'Salmon' || node.color === 'LightBlue') {
                    node.color = 'White';
                    console.log(`[色変更] index=${index} "${node.text}": ${beforeColor} → White (外側)`);
                }
                // スクリプト化ノードはPinkのまま
            }
        } else {
            // 条件分岐が存在しない場合は、色を保持（変更しない）
            console.log(`[色変更] index=${index} "${node.text}": ${beforeColor} のまま（条件分岐なし）`);
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

    // レイヤー化ボタンの表示/非表示を制御
    const layerizeMenuItem = document.getElementById('layerize-menu-item');
    const currentLayerNodes = layerStructure[leftVisibleLayer]?.nodes || [];
    const redBorderNodes = currentLayerNodes.filter(n => n.redBorder);

    // 赤枠ノードが2個以上ある場合のみレイヤー化ボタンを表示
    if (redBorderNodes.length >= 2) {
        layerizeMenuItem.style.display = 'block';
    } else {
        layerizeMenuItem.style.display = 'none';
    }

    // メニュー外クリックで閉じる
    setTimeout(() => {
        document.addEventListener('click', hideContextMenu);
    }, 100);
}

function hideContextMenu() {
    document.getElementById('context-menu').classList.remove('show');
    document.removeEventListener('click', hideContextMenu);
}

// ノード設定（右クリックメニューから）
function openNodeSettingsFromContextMenu() {
    if (!contextMenuTarget) return;

    console.log('[右クリック] ノード設定を開く:', contextMenuTarget.text, 'ID:', contextMenuTarget.id);
    openNodeSettings(contextMenuTarget);
    hideContextMenu();
}

// 名前変更
function renameNode() {
    if (!contextMenuTarget) return;

    const newName = prompt('新しい名前を入力してください:', contextMenuTarget.text);
    if (newName && newName.trim() !== '') {
        contextMenuTarget.text = newName.trim();
        renderNodesInLayer(leftVisibleLayer);
    }

    hideContextMenu();
}

// スクリプト編集
function editScript() {
    if (!contextMenuTarget) return;

    console.log('[editScript] ノード編集開始:', contextMenuTarget.text, 'ID:', contextMenuTarget.id);

    // コード.json からコード内容を取得
    const code = getCodeEntry(contextMenuTarget.id);
    console.log('[editScript] 取得したコード長:', code ? code.length : 0);

    // モーダルを表示
    document.getElementById('script-modal').classList.add('show');
    document.getElementById('script-node-name').textContent = contextMenuTarget.text;
    document.getElementById('script-editor').value = code || '';

    hideContextMenu();
}

// スクリプトモーダルを閉じる
function closeScriptModal() {
    document.getElementById('script-modal').classList.remove('show');
}

// スクリプトを保存
async function saveScript() {
    if (!contextMenuTarget) return;

    console.log('[saveScript] スクリプト保存開始:', contextMenuTarget.text, 'ID:', contextMenuTarget.id);

    const newScript = document.getElementById('script-editor').value;

    // コード.json に保存（setCodeEntry は内部で saveCodeJson を呼び出す）
    await setCodeEntry(contextMenuTarget.id, newScript);

    console.log(`[saveScript] ✅ ノード「${contextMenuTarget.text}」のスクリプトを更新しました`);
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
async function layerizeNode() {
    if (!contextMenuTarget) {
        alert('ノードが選択されていません。');
        return;
    }

    const layerNodes = layerStructure[leftVisibleLayer].nodes;

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

    // 削除したノード情報を配列に追加（ID;色;テキスト）
    // 注意: scriptフィールドは含めない（Pink→Pinkのネスト時に子ノード情報が重複するため）
    const deletedNodeInfo = sortedRedNodes.map(node => {
        return `${node.id};${node.color};${node.text};`;
    });

    const entryString = deletedNodeInfo.join('_');

    // 赤枠ノードをグローバル配列とレイヤーから削除
    console.log(`[レイヤー化] ========== 削除処理開始 ==========`);
    console.log(`[レイヤー化] 対象レイヤー: ${leftVisibleLayer}`);
    console.log(`[レイヤー化] layerNodes === layerStructure[${leftVisibleLayer}].nodes: ${layerNodes === layerStructure[leftVisibleLayer].nodes}`);
    console.log(`[レイヤー化] 削除前: layerNodes.length = ${layerNodes.length}`);
    console.log(`[レイヤー化] 削除前: layerStructure[${leftVisibleLayer}].nodes.length = ${layerStructure[leftVisibleLayer].nodes.length}`);
    console.log(`[レイヤー化] 削除前のグローバルノード数: ${nodes.length}`);
    console.log(`[レイヤー化] 削除予定ノード数: ${sortedRedNodes.length}`);

    sortedRedNodes.forEach((node, index) => {
        console.log(`[レイヤー化] [${index + 1}/${sortedRedNodes.length}] ノード削除中: ID=${node.id}, text="${node.text}"`);

        const globalIndex = nodes.findIndex(n => n.id === node.id);
        if (globalIndex !== -1) {
            nodes.splice(globalIndex, 1);
            console.log(`  ✓ グローバル配列から削除 (インデックス: ${globalIndex})`);
        } else {
            console.warn(`  ⚠ グローバル配列に見つかりません`);
        }

        const layerIndex = layerNodes.findIndex(n => n.id === node.id);
        if (layerIndex !== -1) {
            layerNodes.splice(layerIndex, 1);
            console.log(`  ✓ レイヤー配列から削除 (インデックス: ${layerIndex})`);
            console.log(`  → layerNodes.length = ${layerNodes.length}, layerStructure[${leftVisibleLayer}].nodes.length = ${layerStructure[leftVisibleLayer].nodes.length}`);
        } else {
            console.warn(`  ⚠ レイヤー配列に見つかりません`);
            console.log(`  → 現在のlayerNodes内のノードID: [${layerNodes.map(n => n.id).join(', ')}]`);
        }
    });

    console.log(`[レイヤー化] ========== 削除処理完了 ==========`);
    console.log(`[レイヤー化] 削除後: layerNodes.length = ${layerNodes.length}`);
    console.log(`[レイヤー化] 削除後: layerStructure[${leftVisibleLayer}].nodes.length = ${layerStructure[leftVisibleLayer].nodes.length}`);
    console.log(`[レイヤー化] 削除後のグローバルノード数: ${nodes.length}`);

    // 新しいピンクノードを作成
    const newNodeId = nodeCounter++;
    const newNode = {
        id: newNodeId,
        text: 'スクリプト',
        color: 'Pink',
        処理番号: '99-1',
        layer: leftVisibleLayer,
        y: minY,
        x: 90,
        width: 120,  // 280 → 200 → 120 に変更
        height: 40,
        script: entryString,  // 削除したノードの情報を保存
        redBorder: false
    };

    // グローバル配列とレイヤーに追加
    nodes.push(newNode);
    layerNodes.push(newNode);
    console.log(`[レイヤー化] ピンクノード追加後: layerNodes.length = ${layerNodes.length}, layerStructure[${leftVisibleLayer}].nodes.length = ${layerStructure[leftVisibleLayer].nodes.length}`);

    // Pink選択配列を更新（PowerShell互換）
    pinkSelectionArray[leftVisibleLayer].initialY = minY;
    pinkSelectionArray[leftVisibleLayer].value = 1;

    // ★★★ 追加: コード.jsonにピンクノードの内容を保存 ★★★
    console.log(`[レイヤー化] コード.jsonに保存します - ノードID: ${newNodeId}`);
    console.log(`[レイヤー化] entryString: ${entryString}`);

    // entryStringを "AAAA" プレフィックス付き、改行区切りに変換
    // 現在: "30-1;Pink;スクリプト;_31-1;White;処理A;_32-1;White;処理B;"
    // 変換後: "AAAA\n30-1;Pink;スクリプト;\n31-1;White;処理A;\n32-1;White;処理B;"
    const formattedEntryString = 'AAAA\n' + entryString.replace(/_/g, '\n');
    console.log(`[レイヤー化] フォーマット後: ${formattedEntryString}`);

    // コード.jsonに保存（setCodeEntry関数を使用）
    try {
        await setCodeEntry(newNodeId, formattedEntryString);
        console.log(`[レイヤー化] ✅ コード.json保存成功 - ノードID: ${newNodeId}`);
    } catch (error) {
        console.error(`[レイヤー化] ❌ コード.json保存エラー:`, error);
        alert('ピンクノードの保存に失敗しました。コンソールを確認してください。');
    }

    // ★★★ 追加: レイヤー2以降の場合、親ピンクノードに反映 ★★★
    if (leftVisibleLayer >= 2) {
        console.log(`[レイヤー化] レイヤー${leftVisibleLayer}なので親ピンクノードに反映します`);
        console.log(`[レイヤー化] 削除されたノード: ${sortedRedNodes.map(n => `ID=${n.id}(${n.text})`).join(', ')}`);
        console.log(`[レイヤー化] 追加するノード: ID=${newNode.id}(${newNode.text})`);
        console.log(`[レイヤー化] updateParentPinkNode前: layerStructure[${leftVisibleLayer}].nodes.length = ${layerStructure[leftVisibleLayer].nodes.length}`);
        await updateParentPinkNode([newNode], sortedRedNodes);
        console.log(`[レイヤー化] updateParentPinkNode後: layerStructure[${leftVisibleLayer}].nodes.length = ${layerStructure[leftVisibleLayer].nodes.length}`);
    }

    // 左右パネルの表示を更新
    updateDualPanelDisplay();

    // 画面を再描画（左右両パネル）
    console.log(`[レイヤー化] renderNodesInLayer前: layerStructure[${leftVisibleLayer}].nodes.length = ${layerStructure[leftVisibleLayer].nodes.length}`);
    console.log(`[レイヤー化] renderNodesInLayer前のノードID一覧: [${layerStructure[leftVisibleLayer].nodes.map(n => `${n.id}(${n.text})`).join(', ')}]`);
    renderNodesInLayer(leftVisibleLayer, 'left');
    renderNodesInLayer(rightVisibleLayer, 'right');

    // memory.json自動保存
    console.log(`[レイヤー化] saveMemoryJson前: layerStructure[${leftVisibleLayer}].nodes.length = ${layerStructure[leftVisibleLayer].nodes.length}`);
    saveMemoryJson();
    console.log(`[レイヤー化] saveMemoryJson後: layerStructure[${leftVisibleLayer}].nodes.length = ${layerStructure[leftVisibleLayer].nodes.length}`);

    // 矢印を再描画
    refreshAllArrows();

    console.log(`[レイヤー化] レイヤー${leftVisibleLayer}: ${sortedRedNodes.length}個 → ノード${newNodeId} (スクリプト)`);

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

        const layerIndex = layerStructure[leftVisibleLayer].nodes.findIndex(n => n.id === id);
        if (layerIndex !== -1) {
            layerStructure[leftVisibleLayer].nodes.splice(layerIndex, 1);
        }
    });

    renderNodesInLayer(leftVisibleLayer);
    reorderNodesInLayer(leftVisibleLayer);

    // memory.json自動保存
    saveMemoryJson();

    console.log(`[削除完了] ${deleteTargets.length}個のノードを削除しました`);

    hideContextMenu();
}

// 赤枠トグル（ノードに赤枠を付けたり外したりする）
function toggleRedBorder() {
    if (!contextMenuTarget) return;

    const layerNodes = layerStructure[leftVisibleLayer].nodes;
    const targetNode = layerNodes.find(n => n.id === contextMenuTarget.id);

    if (!targetNode) {
        hideContextMenu();
        return;
    }

    // redBorderフラグをトグル
    targetNode.redBorder = !targetNode.redBorder;

    // 画面を再描画
    renderNodesInLayer(leftVisibleLayer);

    // memory.json自動保存
    saveMemoryJson();

    console.log(`[赤枠トグル] ノード「${targetNode.text}」の赤枠を${targetNode.redBorder ? '追加' : '削除'}しました`);

    hideContextMenu();
}

// Shift+クリックで赤枠トグル（PowerShell互換）
function handleShiftClick(node) {
    const layerNodes = layerStructure[leftVisibleLayer].nodes;
    const targetNode = layerNodes.find(n => n.id === node.id);

    if (!targetNode) return;

    // 赤枠をトグル
    targetNode.redBorder = !targetNode.redBorder;

    // 🔧 修正: グローバル配列の参照を確認・修正（参照が切れている場合のみ）
    const globalNodeIndex = nodes.findIndex(n => n.id === targetNode.id);
    if (globalNodeIndex !== -1 && nodes[globalNodeIndex] !== targetNode) {
        // 参照が切れている場合は修正
        console.warn('[Shift+クリック] 参照が切れていたため修正します');
        nodes[globalNodeIndex] = targetNode;
    }
    // 同じ参照の場合は何もしない（既に targetNode の更新が反映されている）

    // 赤枠に挟まれたノードも赤枠にする（PowerShell互換 - リアルタイム適用）
    const allRedBorderNodes = layerNodes.filter(n => n.redBorder);
    if (allRedBorderNodes.length >= 2) {
        // Y座標でソート
        const sortedNodes = [...layerNodes].sort((a, b) => a.y - b.y);
        const redBorderIndices = allRedBorderNodes.map(node => sortedNodes.findIndex(n => n.id === node.id));

        const startIndex = Math.min(...redBorderIndices);
        const endIndex = Math.max(...redBorderIndices);

        console.log(`[Shift+クリック] 赤枠で囲まれた範囲: インデックス${startIndex}～${endIndex}`);

        // 挟まれたノードを赤枠にする
        for (let i = startIndex + 1; i < endIndex; i++) {
            const enclosedNode = sortedNodes[i];
            if (!enclosedNode.redBorder) {
                enclosedNode.redBorder = true;
                console.log(`  [自動範囲拡張] ノード「${enclosedNode.text}」を赤枠に追加`);

                // グローバル配列も更新
                const globalNode = nodes.find(n => n.id === enclosedNode.id);
                if (globalNode) {
                    globalNode.redBorder = true;
                }
            }
        }
    }

    renderNodesInLayer(leftVisibleLayer);

    // memory.json自動保存
    saveMemoryJson();

    console.log(`[Shift+クリック] ノード「${targetNode.text}」の赤枠を${targetNode.redBorder ? '追加' : '削除'}しました`);
}

// ピンクノードクリックで展開処理（PowerShell互換）
async function handlePinkNodeClick(node) {
    console.log(`[ピンク展開] 「${node.text}」(ID:${node.id}) L${node.layer}→L${node.layer + 1}`);

    const parentLayer = node.layer;
    const nextLayer = parentLayer + 1;

    // レイヤー上限チェック
    if (nextLayer > 6) {
        alert('これ以上レイヤーを展開できません（最大レイヤー6）。');
        return;
    }

    // Pink選択配列に展開状態を記録
    pinkSelectionArray[parentLayer].yCoord = node.y + 15;
    pinkSelectionArray[parentLayer].value = 1;
    pinkSelectionArray[parentLayer].expandedNode = node.id;

    // arrowStateも更新
    arrowState.pinkSelected = true;
    arrowState.selectedPinkButton = node;

    // グローエフェクトの設定
    glowState.sourceNode = node;
    glowState.sourceLayer = parentLayer;
    glowState.targetLayer = nextLayer;

    // 次レイヤーをクリア
    layerStructure[nextLayer].nodes = [];

    // scriptプロパティを解析してノードを展開
    if (!node.script || node.script.trim() === '') {
        console.warn(`[ピンク展開] scriptデータなし`);
        alert('このスクリプト化ノードは空です。展開するノードがありません。');
        return;
    }

    // scriptデータを解析（形式: ID;色;テキスト;スクリプト）
    const entries = node.script.split('_').filter(e => e.trim() !== '');
    console.log(`[ピンク展開] ${entries.length}個のノードを展開`);

    let baseY = 10; // 初期Y座標
    const idMapping = []; // 元のID -> 新しいIDのマッピング

    entries.forEach((entry, index) => {
        const parts = entry.split(';');
        if (parts.length < 3) {
            console.warn(`[展開処理] エントリ${index}のフォーマットが不正: ${entry}`);
            return;
        }

        const originalId = parts[0];
        const color = parts[1];
        const text = parts[2];
        let script = parts[3] || '';
        let savedScriptForCodeJson = null;  // コード.jsonに保存する用（元のフォーマット）

        // ピンクノードの場合、コード.jsonからscriptデータを復元
        if (color === 'Pink' && !script) {
            const savedScript = getCodeEntry(originalId);
            if (savedScript) {
                savedScriptForCodeJson = savedScript;
                script = savedScript
                    .replace(/^AAAA\n/, '')
                    .replace(/\n---\n/g, '_')
                    .replace(/\n/g, '_')
                    .replace(/_+/g, '_')
                    .trim();
            }
        }

        // 条件分岐の中間ノードは高さ1px、幅20px、座標計算も特殊
        const isMiddleNode = (text === '条件分岐 中間' || color === 'Gray');
        const nodeHeight = isMiddleNode ? 1 : 40;
        const nodeWidth = isMiddleNode ? 20 : 120;

        // ボタン間隔と高さの調整（"条件分岐 中間"の場合は特殊）
        const interval = isMiddleNode ? 10 : 20;  // 通常20のところ10
        const heightForNext = isMiddleNode ? 0 : 40;  // 通常40のところ0

        // Y座標を設定
        const nodeY = baseY + interval;

        // 新しいノードを作成
        const newNodeId = nodeCounter++;
        const newNode = {
            id: newNodeId,
            text: text,
            color: color,
            処理番号: '99-1', // スクリプト化ノードの処理番号
            layer: nextLayer,
            y: nodeY,
            x: 90,
            width: nodeWidth,  // 通常200px、中間ノード20px
            height: nodeHeight,
            script: script,
            redBorder: false
        };

        console.log(`[展開処理] ノード作成: ID=${newNodeId}, テキスト=${text}, 色=${color}, Y=${nodeY}`);

        // ノードのエントリを新しいIDでコード.jsonに保存
        if (color === 'Pink' && savedScriptForCodeJson) {
            // Pinkノードの場合、savedScriptForCodeJsonを使用
            console.log(`[展開処理] ピンクノードを新しいID(${newNodeId})でコード.jsonに保存します`);
            setCodeEntry(newNodeId, savedScriptForCodeJson).then(() => {
                console.log(`[展開処理] ✅ コード.json保存成功 - 新しいID: ${newNodeId}`);
            }).catch(error => {
                console.error(`[展開処理] ❌ コード.json保存エラー:`, error);
            });
        } else {
            // その他のノード（White, LemonChiffon, SpringGreen, Salmonなど）の場合、
            // 元のIDのエントリを新しいIDでコピー
            const originalEntry = getCodeEntry(originalId);
            if (originalEntry) {
                console.log(`[展開処理] ノード(${color})を元のID(${originalId})から新しいID(${newNodeId})にコピーします`);
                setCodeEntry(newNodeId, originalEntry).then(() => {
                    console.log(`[展開処理] ✅ コード.json保存成功 - 新しいID: ${newNodeId}`);
                }).catch(error => {
                    console.error(`[展開処理] ❌ コード.json保存エラー:`, error);
                });
            } else {
                console.warn(`[展開処理] ⚠ 元のID(${originalId})のエントリが見つかりません`);
            }
        }

        // IDマッピングを記録
        idMapping.push({ originalId, newNodeId });

        // グローバル配列とレイヤーに追加
        nodes.push(newNode);
        layerStructure[nextLayer].nodes.push(newNode);

        // 次のノードのbaseY計算（中間ノードは特殊）
        baseY = nodeY + heightForNext;
    });

    // ★★★ 追加: 親ピンクノードのscriptを新しいIDで更新 ★★★
    console.log(`[展開処理] 親ピンクノードのscriptを新しいIDで更新します`);
    console.log(`[展開処理] IDマッピング: ${idMapping.map(m => `${m.originalId}->${m.newNodeId}`).join(', ')}`);

    let updatedScript = node.script;
    idMapping.forEach(mapping => {
        // 正規表現を使って、セミコロンやアンダースコアで区切られた位置のIDのみを置換
        const regex = new RegExp(`(^|_)${mapping.originalId}(;|$)`, 'g');
        updatedScript = updatedScript.replace(regex, `$1${mapping.newNodeId}$2`);
    });

    console.log(`[展開処理] 更新前のscript: ${node.script}`);
    console.log(`[展開処理] 更新後のscript: ${updatedScript}`);

    // 親ピンクノードを更新
    node.script = updatedScript;
    const globalNode = nodes.find(n => n.id === node.id);
    if (globalNode) {
        globalNode.script = updatedScript;
    }

    // コード.jsonに保存
    const formattedEntryString = 'AAAA\n' + updatedScript.replace(/_/g, '\n');
    try {
        await setCodeEntry(node.id, formattedEntryString);
        console.log(`[展開処理] ✅ コード.json保存成功 - ノードID: ${node.id}`);
    } catch (error) {
        console.error(`[展開処理] ❌ コード.json保存エラー:`, error);
    }

    // 条件分岐の色変え（赤・青）を適用するため、reorderNodesInLayerを呼ぶ
    // （これにより座標も正しく再計算され、色も正しく設定される）
    reorderNodesInLayer(nextLayer);

    // 左右パネルの表示を更新（現在のレイヤーに留まる）
    updateDualPanelDisplay();

    // 画面を再描画（左パネルと右パネル）
    renderNodesInLayer(leftVisibleLayer, 'left');
    renderNodesInLayer(rightVisibleLayer, 'right');

    // グローエフェクトを再適用（レンダリング後に実行）
    setTimeout(() => {
        applyGlowEffects();
    }, 50);

    // memory.json自動保存
    saveMemoryJson();

    // 矢印を再描画
    refreshAllArrows();

    console.log(`[展開完了] レイヤー${parentLayer} → レイヤー${nextLayer}: ${node.text} (${entries.length}個のノード展開、レイヤー移動なし)`);
    console.log(`[パネル表示] 左: レイヤー${leftVisibleLayer}, 右: レイヤー${rightVisibleLayer}`);

    // レイヤー1の場合、ドリルダウンパネルも更新
    if (parentLayer === 1 && leftVisibleLayer === 1) {
        setTimeout(() => {
            const leftPanel = document.getElementById('left-layer-panel');
            if (leftPanel) {
                leftPanel.classList.add('dimmed');
            }

            showLayerInDrilldownPanel(node);

            const layerName = node.text || `スクリプト${node.layer}`;
            breadcrumbStack.push({ name: layerName, layer: nextLayer });
            renderBreadcrumb();

            const escHint = document.getElementById('escHint');
            if (escHint) {
                escHint.classList.add('show');
            }

            drilldownState.active = true;
            drilldownState.currentPinkNode = node;
            drilldownState.targetLayer = nextLayer;
        }, 100);
    }
}

// 赤枠に挟まれたボタンスタイルを適用
function applyRedBorderToGroup() {
    if (!contextMenuTarget) return;

    const layerNodes = layerStructure[leftVisibleLayer].nodes;

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
    renderNodesInLayer(leftVisibleLayer);

    // memory.json自動保存
    saveMemoryJson();

    console.log(`[赤枠グループ適用] ${appliedCount}個のノードに赤枠を適用しました`);
    alert(`${appliedCount}個のノードに赤枠を適用しました。`);

    hideContextMenu();
}

// 削除対象ノードIDリストを取得
function getDeleteTargets(targetNode) {
    const layerNodes = layerStructure[leftVisibleLayer].nodes;

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

// 全削除（現在のレイヤーのノードをすべて削除）
async function deleteAllNodes() {
    console.log('[全削除] 開始');

    // 全レイヤーのノード数を計算
    let totalNodeCount = 0;
    const layerCounts = {};
    for (let i = 1; i <= 6; i++) {
        const count = layerStructure[i].nodes.length;
        layerCounts[i] = count;
        totalNodeCount += count;
        console.log(`[全削除] レイヤー${i}: ${count}個のノード`);
    }

    if (totalNodeCount === 0) {
        alert('削除するノードがありません。');
        return;
    }

    // 確認ダイアログ（全レイヤーの合計ノード数を表示）
    const confirmed = confirm(
        `⚠️ すべてのレイヤーのノード（合計${totalNodeCount}個）とコード.jsonを削除します。\n\n` +
        `この操作は取り消せません。本当に削除しますか？\n\n` +
        `削除されるノード:\n` +
        Object.keys(layerCounts)
            .filter(layer => layerCounts[layer] > 0)
            .map(layer => `  レイヤー${layer}: ${layerCounts[layer]}個`)
            .join('\n')
    );
    if (!confirmed) {
        console.log('[全削除] ユーザーがキャンセルしました');
        return;
    }

    try {
        console.log('[全削除] 全レイヤーのノードを収集します...');

        // 全レイヤーのノードを収集
        const allNodes = [];
        for (let i = 1; i <= 6; i++) {
            allNodes.push(...layerStructure[i].nodes);
        }

        console.log('[全削除] 🔍 送信するノード総数:', allNodes.length);
        if (allNodes.length > 0) {
            console.log('[全削除] 🔍 最初のノードの構造:', allNodes[0]);
            console.log('[全削除] 🔍 最初のノードのid:', allNodes[0].id);
        }
        const requestBody = { nodes: allNodes };
        console.log('[全削除] 🔍 送信するJSON (最初の500文字):', JSON.stringify(requestBody).substring(0, 500));
        console.log('[全削除] 🔍 送信先URL:', `${API_BASE}/nodes/all`);

        // ステップ1: ノードの削除
        console.log('[全削除] ステップ1: ノード削除APIを呼び出します...');
        const response = await fetch(`${API_BASE}/nodes/all`, {
            method: 'DELETE',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(requestBody)
        });

        console.log('[全削除] 🔍 レスポンスステータス:', response.status);
        console.log('[全削除] 🔍 レスポンスOK:', response.ok);

        const result = await response.json();

        if (!result.success) {
            console.error('[全削除] ノード削除API失敗:', result.error);
            alert(`ノード削除に失敗しました: ${result.error}`);
            return;
        }

        console.log('[全削除] ✅ ノード削除成功:', result.message);
        console.log('[全削除] 削除されたノード数:', result.deleteCount);

        // ステップ2: コード.jsonの初期化
        console.log('[全削除] ステップ2: コード.json初期化APIを呼び出します...');
        const emptyCodeData = {
            "エントリ": {},
            "最後のID": 0
        };

        const codeResponse = await fetch(`${API_BASE}/folders/${currentFolder}/code`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ codeData: emptyCodeData })
        });

        const codeResult = await codeResponse.json();

        if (!codeResult.success) {
            console.error('[全削除] コード.json初期化失敗:', codeResult.error);
            alert(`コード.json初期化に失敗しました: ${codeResult.error}`);
            return;
        }

        console.log('[全削除] ✅ コード.json初期化成功');

        // ステップ3: ローカルのノード配列を更新（全レイヤー）
        console.log('[全削除] ステップ3: ローカルデータを更新します...');
        for (let i = 1; i <= 6; i++) {
            layerStructure[i].nodes = [];
            console.log(`[全削除]   レイヤー${i}をクリア`);
        }
        nodes = [];  // グローバルnodesも空に
        codeData = emptyCodeData;  // codeDataも空に

        // ステップ4: 画面を再描画
        console.log('[全削除] ステップ4: 画面を再描画します...');
        renderNodesInLayer(leftVisibleLayer, 'left');
        renderNodesInLayer(rightVisibleLayer, 'right');

        // ステップ5: memory.json自動保存
        console.log('[全削除] ステップ5: memory.jsonを保存します...');
        await saveMemoryJson();

        console.log('[全削除] ✅ すべての処理が完了しました');
        alert(`✅ ${totalNodeCount}個のノードとコード.jsonを削除しました。`);
    } catch (error) {
        console.error('[全削除] ❌ エラー:', error);
        console.error('[全削除] スタックトレース:', error.stack);
        alert(`削除中にエラーが発生しました: ${error.message}`);
    }
}

// ============================================
// レイヤーナビゲーション
// ============================================

function navigateLayer(direction) {
    // ドリルダウンパネルがアクティブな場合はクリア
    if (drilldownState && drilldownState.active) {
        closeDrilldownPanel();
    }

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

    // グローエフェクトを再適用
    setTimeout(() => {
        applyGlowEffects();
    }, 50);

    // memory.jsonを保存
    saveMemoryJson();

    // 矢印を再描画
    refreshAllArrows();
}

// 現在のレイヤーより深いレイヤーをクリアする関数
function clearDeeperLayers(leftVisibleLayer) {
    console.log(`[クリア] レイヤー${leftVisibleLayer}より深いレイヤーをクリアします`);
    for (let i = leftVisibleLayer + 1; i <= 6; i++) {
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

    const startTime = performance.now();
    console.log(`[実行] レイヤー${leftVisibleLayer} のコード生成を開始...`);

    try {
        // 現在のレイヤーのノードを取得
        const currentLayerNodes = layerStructure[leftVisibleLayer]?.nodes || [];

        // ノードが存在しない場合の検証
        if (currentLayerNodes.length === 0) {
            console.log('❌ [実行] ノードがありません');
            alert('現在のレイヤーにノードがありません。ノードを追加してから実行してください。');
            return;
        }

        console.log(`[実行] ノード数: ${currentLayerNodes.length}個`);

        // 送信データを準備
        const requestData = {
            nodes: currentLayerNodes.map(n => ({
                id: n.id,
                text: n.text,
                color: n.color,
                y: n.y,
                処理番号: n.処理番号
            })),
            outputPath: null,
            openFile: false
        };

        // console.log('[実行] API送信:', requestData);

        // 現在のレイヤーのノードを送信
        const apiStartTime = performance.now();
        const result = await callApi('/execute/generate', 'POST', requestData);
        if (result.success) {
            console.log(`✅ [実行] 成功 - ノード数: ${result.nodeCount}個, コード長: ${result.code?.length || 0}文字`);

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
            if (result.code) {
                codePreview.value = result.code;
            } else {
                codePreview.value = '（コードプレビューは利用できません）';
                console.warn('⚠ [実行] result.code が空です');
            }

            // グローバル変数に保存（コピー/ファイルオープン用）
            window.lastGeneratedCode = {
                code: result.code,
                path: result.outputPath
            };

            // モーダルを表示
            document.getElementById('code-result-modal').classList.add('show');
        } else {
            console.error(`❌ [実行] 失敗: ${result.error}`);
            alert(`コード生成失敗: ${result.error}`);
        }
    } catch (error) {
        const endTime = performance.now();
        const totalDuration = (endTime - startTime).toFixed(2);
        console.error('❌ [実行] コード生成エラー (所要時間: ' + totalDuration + 'ms)');
        console.error('❌ [実行] エラーメッセージ:', error.message);
        console.error('❌ [実行] スタックトレース:', error.stack);
        console.log('═══════════════════════════════════════════════');
        console.log('');
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

async function createSnapshot() {
    console.log('[スナップショット] 作成開始');

    if (!currentFolder) {
        alert('フォルダが選択されていません。\n先にフォルダを選択または作成してください。');
        return;
    }

    try {
        const timestamp = new Date().toISOString();
        const timestampJP = new Date().toLocaleString('ja-JP', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        });

        console.log(`[スナップショット] 作成日時: ${timestampJP}`);
        console.log(`[スナップショット] フォルダ: ${currentFolder}`);

        // スナップショット情報
        const snapshotInfo = {
            作成日時: timestampJP,
            timestamp: timestamp,
            説明: 'スナップショット',
            タイプ: '手動',
            フォルダ: currentFolder
        };

        // スナップショットデータ（PowerShell版に合わせて全データを保存）
        const snapshot = {
            フォルダ: currentFolder,
            timestamp: timestamp,
            作成日時: timestampJP,
            nodes: JSON.parse(JSON.stringify(nodes)),
            layerStructure: JSON.parse(JSON.stringify(layerStructure)),
            codeData: JSON.parse(JSON.stringify(codeData)),
            variables: JSON.parse(JSON.stringify(variables))
        };

        // フォルダごとにスナップショットを管理（PowerShell版のmemory_snapshot.json相当）
        const storageKey = `snapshot_${currentFolder}`;
        const infoKey = `snapshot_info_${currentFolder}`;

        console.log(`[スナップショット] localStorage保存: ${storageKey}`);
        localStorage.setItem(storageKey, JSON.stringify(snapshot));
        localStorage.setItem(infoKey, JSON.stringify(snapshotInfo));

        console.log('[スナップショット] ✅ 保存完了');

        alert(`📸 スナップショット作成完了\n\n作成日時: ${timestampJP}\nフォルダ: ${currentFolder}\n\n「↩️ 復元」ボタンでこの状態に戻すことができます。`);

    } catch (error) {
        console.error('[スナップショット] ❌ エラー:', error);
        alert(`スナップショット作成中にエラーが発生しました:\n${error.message}`);
    }
}

async function restoreSnapshot() {
    console.log('[スナップショット復元] 開始');

    if (!currentFolder) {
        alert('フォルダが選択されていません。\n先にフォルダを選択してください。');
        return;
    }

    try {
        const storageKey = `snapshot_${currentFolder}`;
        const infoKey = `snapshot_info_${currentFolder}`;

        // スナップショット存在確認
        const snapshotData = localStorage.getItem(storageKey);
        if (!snapshotData) {
            alert('スナップショットが存在しません。\n\n先に「📸 スナップショット」ボタンで現在の状態を保存してください。');
            console.log('[スナップショット復元] スナップショット未保存');
            return;
        }

        // スナップショット情報を取得
        const snapshotInfoData = localStorage.getItem(infoKey);
        const snapshotInfo = snapshotInfoData ? JSON.parse(snapshotInfoData) : null;
        const snapshotDate = snapshotInfo ? snapshotInfo.作成日時 : '不明';

        console.log(`[スナップショット復元] スナップショット作成日時: ${snapshotDate}`);

        // 確認ダイアログ（PowerShell版と同じ）
        const confirmed = confirm(
            `スナップショットの状態に復元します。\n\n` +
            `スナップショット作成日時: ${snapshotDate}\n` +
            `フォルダ: ${currentFolder}\n\n` +
            `現在の変更は失われますがよろしいですか？`
        );

        if (!confirmed) {
            console.log('[スナップショット復元] ユーザーがキャンセル');
            return;
        }

        // スナップショットを復元
        const snapshot = JSON.parse(snapshotData);

        console.log('[スナップショット復元] データ復元中...');

        // すべてのデータを復元
        nodes = JSON.parse(JSON.stringify(snapshot.nodes));
        layerStructure = JSON.parse(JSON.stringify(snapshot.layerStructure));
        codeData = JSON.parse(JSON.stringify(snapshot.codeData || {}));
        variables = JSON.parse(JSON.stringify(snapshot.variables));

        console.log('[スナップショット復元] ノード数:', nodes.length);
        console.log('[スナップショット復元] コードエントリ数:', Object.keys(codeData).length);

        // UIをリロード（現在のレイヤーを再描画）
        renderNodesInLayer(leftVisibleLayer);

        // memory.json と コード.json を保存（PowerShell版と同期）
        await saveMemoryJson();
        await saveCodeJson();

        console.log('[スナップショット復元] ✅ 復元完了');

        alert(`✅ 復元完了\n\nスナップショットから復元しました。\n\n復元日時: ${snapshotDate}`);

    } catch (error) {
        console.error('[スナップショット復元] ❌ エラー:', error);
        alert(`スナップショット復元中にエラーが発生しました:\n${error.message}`);
    }
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
                // IDが保存されていればそれを使用、なければ新規生成（後方互換性）
                let nodeId;
                if (nodeData.ID) {
                    nodeId = nodeData.ID;
                    console.log(`[memory.json読み込み] ノードID復元: ${nodeId}`);
                } else {
                    nodeId = `node-${nodeCounter++}`;
                    console.warn(`[memory.json読み込み] ノードIDが保存されていないため新規生成: ${nodeId}`);
                }

                const node = {
                    id: nodeId,
                    name: nodeData.ボタン名 || '',
                    text: nodeData.テキスト || '',
                    color: nodeData.ボタン色 || 'White',
                    layer: layerNum,
                    y: nodeData.Y座標 || 10,
                    x: nodeData.X座標 || 10,
                    width: nodeData.幅 || 120,  // 280 → 200 → 120 に変更
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

        // nodeCounter を更新（既存ノードの最大ID + 1）
        nodes.forEach(node => {
            const match = node.id.match(/^(\d+)-/);
            if (match) {
                const idNum = parseInt(match[1]);
                if (idNum >= nodeCounter) {
                    nodeCounter = idNum + 1;
                }
            }
        });
        console.log(`[memory.json読み込み] nodeCounter を ${nodeCounter} に更新しました`);

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
        console.log('│ → URL:', `${API_BASE}/folders/${currentFolder}/code`);
        console.log('│ → codeData:', JSON.stringify(codeData).substring(0, 200) + '...');

        const response = await fetch(`${API_BASE}/folders/${currentFolder}/code`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ codeData: codeData })
        });

        console.log('│ ← レスポンス受信');
        console.log('│ ← ステータス:', response.status, response.statusText);
        console.log('│ ← Content-Type:', response.headers.get('Content-Type'));

        const result = await response.json();
        console.log('│ ← JSONパース完了:', result);

        if (result.success) {
            console.log('│ ✅ 成功:', result.message);
            console.log('│ 保存先: 03_history/' + currentFolder + '/コード.json');
        } else {
            console.error('│ ❌ 失敗:', result.error);
        }
    } catch (error) {
        console.error('│ ❌ エラー:', error);
        console.error('│ エラーメッセージ:', error.message);
        console.error('│ スタックトレース:', error.stack);
    }

    console.log('└──────────────────────────────────────');
}

// 処理番号でスクリプト内容を取得
// setCodeEntryは "id-1", "id-2", "id-3" の形式でサブIDを生成するため、
// それに対応した検索を行う
function getCodeEntry(処理番号) {
    if (!処理番号) return '';

    console.log('[getCodeEntry] ID:', 処理番号);

    // 1. まず、そのままのIDで検索（既存の動作）
    if (codeData["エントリ"][処理番号]) {
        console.log('[getCodeEntry] ✅ 直接ヒット:', 処理番号);
        return codeData["エントリ"][処理番号];
    }

    // 2. サブID形式 (id-1, id-2, ...) で検索してすべて結合
    const entries = Object.keys(codeData["エントリ"])
        .filter(key => key.startsWith(処理番号 + '-'))
        .sort()  // "1-1-1", "1-1-2", "1-1-3" の順にソート
        .map(key => codeData["エントリ"][key]);

    if (entries.length > 0) {
        console.log(`[getCodeEntry] ✅ サブID検索ヒット: ${entries.length}個のエントリを結合`);
        // "---"で結合して返す（PowerShell互換）
        return entries.join('\n---\n');
    }

    console.log('[getCodeEntry] ❌ エントリが見つかりません:', 処理番号);
    return '';
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
    console.log('[ノード設定] モーダルを開く:', node.text, 'ID:', node.id);
    console.log('[ノード設定] 渡されたノードオブジェクト:', JSON.stringify(node, null, 2));

    // ノードIDで最新の情報を取得（layerStructureから）
    let actualNode = null;
    for (let layer = 1; layer <= 6; layer++) {
        const found = layerStructure[layer].nodes.find(n => n.id === node.id);
        if (found) {
            actualNode = found;
            console.log('[ノード設定] ✅ レイヤー', layer, 'から最新ノード情報を取得しました');
            break;
        }
    }

    if (!actualNode) {
        console.error('[ノード設定] ❌ ノードIDが見つかりません:', node.id);
        alert('ノード情報が見つかりませんでした。');
        return;
    }

    currentSettingsNode = actualNode;

    console.log('[ノード設定] 最新ノードオブジェクト:', JSON.stringify(actualNode, null, 2));

    // モーダルを表示
    document.getElementById('node-settings-modal').classList.add('show');
    document.getElementById('settings-node-name').textContent = actualNode.text;
    document.getElementById('settings-node-text').value = actualNode.text;

    // スクリプトをcode.jsonから取得（node.scriptは使用しない）
    const scriptContent = getCodeEntry(actualNode.id);
    console.log('[ノード設定] code.jsonからスクリプトを取得しました。ID:', actualNode.id, '長さ:', scriptContent ? scriptContent.length : 0);
    document.getElementById('settings-node-script').value = scriptContent || '';

    // 外観設定を設定
    document.getElementById('settings-node-color').value = actualNode.color || 'White';
    document.getElementById('settings-node-width').value = actualNode.width || 120;  // 280 → 200 → 120 に変更
    document.getElementById('settings-node-height').value = actualNode.height || 40;
    document.getElementById('settings-node-x').value = actualNode.x || 10;
    document.getElementById('settings-node-y').value = actualNode.y || 10;

    console.log('[ノード設定] 入力フィールドに設定した値:', {
        color: actualNode.color,
        width: actualNode.width,
        height: actualNode.height,
        x: actualNode.x,
        y: actualNode.y
    });

    // カスタムフィールドをクリア
    const customFields = document.getElementById('settings-custom-fields');
    customFields.innerHTML = '';

    // 処理番号に応じたカスタムフィールドを追加
    if (actualNode.処理番号 === '1-2') {
        // 条件分岐
        customFields.innerHTML = `
            <div style="margin-bottom: 15px; padding: 10px; background: #fff3cd; border-radius: 5px;">
                <label><strong>条件分岐設定:</strong></label>
                <div style="margin-top: 8px;">
                    <label>条件式:</label>
                    <input type="text" id="condition-expression" value="${actualNode.conditionExpression || ''}" style="width: 100%; padding: 5px;" placeholder="例: $変数 -eq '値'" />
                </div>
            </div>
        `;
    } else if (actualNode.処理番号 === '1-3') {
        // ループ
        customFields.innerHTML = `
            <div style="margin-bottom: 15px; padding: 10px; background: #d1ecf1; border-radius: 5px;">
                <label><strong>ループ設定:</strong></label>
                <div style="margin-top: 8px;">
                    <label>ループ回数:</label>
                    <input type="number" id="loop-count" value="${actualNode.loopCount || 1}" style="width: 100%; padding: 5px;" />
                </div>
                <div style="margin-top: 8px;">
                    <label>ループ変数名:</label>
                    <input type="text" id="loop-variable" value="${actualNode.loopVariable || 'i'}" style="width: 100%; padding: 5px;" />
                </div>
            </div>
        `;
    }
}

function closeNodeSettingsModal() {
    document.getElementById('node-settings-modal').classList.remove('show');
    currentSettingsNode = null;
}

async function saveNodeSettings() {
    if (!currentSettingsNode) return;

    console.log('[ノード設定] 保存開始:', currentSettingsNode.text, 'ID:', currentSettingsNode.id);

    // 基本設定を更新
    const newText = document.getElementById('settings-node-text').value;
    const newScript = document.getElementById('settings-node-script').value;

    // 外観設定を更新
    const newColor = document.getElementById('settings-node-color').value;
    const newWidth = parseInt(document.getElementById('settings-node-width').value);
    const newHeight = parseInt(document.getElementById('settings-node-height').value);
    const newX = parseInt(document.getElementById('settings-node-x').value);
    const newY = parseInt(document.getElementById('settings-node-y').value);

    console.log('[ノード設定] 新しい設定:', {
        text: newText,
        color: newColor,
        width: newWidth,
        height: newHeight,
        x: newX,
        y: newY
    });

    currentSettingsNode.text = newText;
    currentSettingsNode.script = newScript;
    currentSettingsNode.color = newColor;
    currentSettingsNode.width = newWidth;
    currentSettingsNode.height = newHeight;
    currentSettingsNode.x = newX;
    currentSettingsNode.y = newY;

    // カスタムフィールドを保存
    if (currentSettingsNode.処理番号 === '1-2') {
        const conditionExpression = document.getElementById('condition-expression');
        if (conditionExpression) {
            currentSettingsNode.conditionExpression = conditionExpression.value;
            console.log('[ノード設定] 条件式を保存:', conditionExpression.value);
        }
    } else if (currentSettingsNode.処理番号 === '1-3') {
        const loopCount = document.getElementById('loop-count');
        const loopVariable = document.getElementById('loop-variable');
        if (loopCount) {
            currentSettingsNode.loopCount = parseInt(loopCount.value);
            console.log('[ノード設定] ループ回数を保存:', loopCount.value);
        }
        if (loopVariable) {
            currentSettingsNode.loopVariable = loopVariable.value;
            console.log('[ノード設定] ループ変数名を保存:', loopVariable.value);
        }
    }

    // グローバルノード配列の参照を修正（参照が切れている場合のみ）
    const globalNodeIndex = nodes.findIndex(n => n.id === currentSettingsNode.id);
    if (globalNodeIndex !== -1) {
        if (nodes[globalNodeIndex] !== currentSettingsNode) {
            // 🔧 修正: Object.assignで新しいオブジェクトを作成するのではなく、
            // 参照が切れている場合のみ正しい参照に置き換える
            console.warn('[ノード設定] ⚠️ 参照が切れていたため修正します');
            nodes[globalNodeIndex] = currentSettingsNode;
            console.log('[ノード設定] グローバルノード配列の参照を修正しました:', globalNodeIndex);
        } else {
            console.log('[ノード設定] ✅ グローバルノード配列は既に正しい参照を持っています:', globalNodeIndex);
        }
    } else {
        console.warn('[ノード設定] ⚠️ グローバルノード配列でノードが見つかりません:', currentSettingsNode.id);
    }

    // 再描画（ノードが属するレイヤーを再描画）
    console.log('[ノード設定] レイヤー', currentSettingsNode.layer, 'を再描画します');
    renderNodesInLayer(currentSettingsNode.layer);

    // memory.json自動保存
    await saveMemoryJson();

    console.log('[ノード設定] ✅ 保存完了: ノード「' + currentSettingsNode.text + '」');
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

    const layerNodes = layerStructure[leftVisibleLayer].nodes;
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
    const layerNodes = layerStructure[leftVisibleLayer].nodes;
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

// ============================================
// 汎用ノード関数実行（00_code/*.ps1を参照）
// ============================================

/**
 * APIを通じて00_code/*.ps1の関数を実行
 * @param {string} functionName - 関数名（例: "1_6"）
 * @param {object} params - パラメータ（省略可）
 * @returns {Promise<string>} - 生成されたコード
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
            throw new Error(`API Error: ${response.status} ${response.statusText}`);
        }

        const result = await response.json();

        if (result.success && result.code) {
            console.log(`[ノード関数実行] 成功 - コード長: ${result.code.length}文字`);
            return result.code;
        } else {
            throw new Error(result.error || '不明なエラー');
        }
    } catch (error) {
        console.error(`[ノード関数実行] エラー:`, error);
        throw error;
    }
}

// ============================================
// 個別のgenerate関数（フォールバック用）
// ============================================

// 1_1: 順次処理
async function generate_1_1() {
    try {
        return await executeNodeFunction('1_1');
    } catch (error) {
        console.warn('[generate_1_1] API呼び出し失敗、フォールバックを使用', error);
        return 'Write-Host "OK"';
    }
}

// 1_6: メッセージボックス表示
async function generate_1_6() {
    try {
        return await executeNodeFunction('1_6');
    } catch (error) {
        console.warn('[generate_1_6] API呼び出し失敗、フォールバックを使用', error);
        return `Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show("これはメッセージボックスです。", "タイトル", "OK", "Information")`;
    }
}

// 99_1: カスタム処理（AAAA_プレフィックス）
async function generate_99_1(直接エントリ) {
    try {
        // 直接エントリがない場合はデフォルト
        if (!直接エントリ) {
            return await executeNodeFunction('99_1', { '直接エントリ': '' });
        }

        const entryWithPrefix = "AAAA_" + 直接エントリ;
        // アンダースコアを改行に置換
        const processedEntry = entryWithPrefix.replace(/_/g, '\r\n');

        return await executeNodeFunction('99_1', { '直接エントリ': processedEntry });
    } catch (error) {
        console.warn('[generate_99_1] API呼び出し失敗、フォールバックを使用', error);

        if (!直接エントリ) {
            return 'Write-Host "カスタム処理"';
        }

        const entryWithPrefix = "AAAA_" + 直接エントリ;
        const processedEntry = entryWithPrefix.replace(/_/g, '\r\n');
        return processedEntry;
    }
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
async function generateCode(処理番号, ノードID, 直接エントリ = null) {
    try {
        console.log(`[コード生成] 開始 - 処理番号: ${処理番号}, ノードID: ${ノードID}`);
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
        let entryString = null;

        if (generatorFunc) {
            // codeGeneratorFunctionsに登録されている場合
            console.log(`[コード生成] 登録済み関数を実行します: ${関数名}`);

            // 特殊処理: 99-1の場合は直接エントリを渡す
            if (処理番号 === '99-1') {
                entryString = await generatorFunc(直接エントリ);
            } else {
                // ダイアログを表示する場合は await
                if (関数名 === 'ShowConditionBuilder' || 関数名 === 'ShowLoopBuilder') {
                    console.log(`[コード生成] ダイアログを表示します`);
                    entryString = await generatorFunc();
                } else {
                    entryString = await generatorFunc();
                }
            }
        } else {
            // 未実装の場合は、API経由で00_code/*.ps1を呼び出す
            console.log(`[コード生成] 未実装関数 - API経由で00_code/*.ps1を呼び出します: ${関数名}`);
            try {
                entryString = await executeNodeFunction(関数名, {});
            } catch (error) {
                console.error(`[コード生成] API呼び出しエラー:`, error);
                console.error(`[コード生成] 関数 ${関数名} の実行に失敗しました`);
                return null;
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
        console.log(`[コード生成] コード.jsonに保存します - ノードID: ${ノードID}`);
        await setCodeEntry(ノードID, entryString);

        console.log(`[コード生成] 成功: ノードID ${ノードID} に保存しました`);
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

// ============================================
// ダークモード切り替え機能
// ============================================

// ダークモード切り替え
function toggleDarkMode() {
    const body = document.body;
    const icon = document.getElementById('dark-mode-icon');
    const text = document.getElementById('dark-mode-text');

    if (body.classList.contains('dark-mode')) {
        // ライトモードに切り替え
        body.classList.remove('dark-mode');
        icon.textContent = '🌙';
        text.textContent = 'ダーク';
        localStorage.setItem('darkMode', 'false');
        console.log('[ダークモード] ライトモードに切り替え');
    } else {
        // ダークモードに切り替え
        body.classList.add('dark-mode');
        icon.textContent = '☀️';
        text.textContent = 'ライト';
        localStorage.setItem('darkMode', 'true');
        console.log('[ダークモード] ダークモードに切り替え');
    }
}

// ページ読み込み時にダークモード設定を復元
function initDarkMode() {
    const darkMode = localStorage.getItem('darkMode');
    const body = document.body;
    const icon = document.getElementById('dark-mode-icon');
    const text = document.getElementById('dark-mode-text');

    if (darkMode === 'true') {
        body.classList.add('dark-mode');
        if (icon) icon.textContent = '☀️';
        if (text) text.textContent = 'ライト';
        console.log('[ダークモード] ダークモードで起動');
    } else {
        console.log('[ダークモード] ライトモードで起動');
    }
}

// DOM読み込み完了時にダークモード設定を初期化
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initDarkMode);
} else {
    initDarkMode();
}

// ============================================
// レイヤーナビゲーション機能 (layer-navigation-test.html統合)
// ============================================

// パンくずリスト状態管理
let breadcrumbStack = [
    { name: 'メインフロー', layer: 1 }
];

// ホバープレビュー用タイマー
let hoverTimer = null;

// ドリルダウン状態
let drilldownState = {
    active: false,
    currentPinkNode: null,
    targetLayer: null
};

// 編集モード状態
let editModeState = {
    active: false,
    currentLayer: 1
};

// パンくずリストを描画
function renderBreadcrumb() {
    const breadcrumb = document.getElementById('breadcrumb');
    if (!breadcrumb) return;

    breadcrumb.innerHTML = '';

    breadcrumbStack.forEach((item, index) => {
        const breadcrumbItem = document.createElement('div');
        breadcrumbItem.className = 'breadcrumb-item';
        breadcrumbItem.dataset.layer = item.layer;

        // テキスト部分を作成
        const textSpan = document.createElement('span');
        textSpan.className = 'breadcrumb-text';
        textSpan.textContent = index === 0 ? '📍 ' + item.name : item.name;
        breadcrumbItem.appendChild(textSpan);

        // 編集アイコンを追加（メインフロー以外）
        if (item.layer > 1) {
            const editIcon = document.createElement('span');
            editIcon.className = 'breadcrumb-edit-icon';
            editIcon.textContent = '✏️';
            editIcon.title = 'このレイヤーを編集';

            // 編集アイコンのクリックイベント
            editIcon.addEventListener('click', (e) => {
                e.stopPropagation(); // パンくずアイテムのクリックイベントを防ぐ
                enterEditMode(item.layer);
            });

            breadcrumbItem.appendChild(editIcon);
        }

        if (index === breadcrumbStack.length - 1) {
            breadcrumbItem.classList.add('current');
        }

        // クリックイベント（パンくずテキスト部分）
        if (index < breadcrumbStack.length - 1) {
            textSpan.style.cursor = 'pointer';
            textSpan.addEventListener('click', () => {
                navigateToBreadcrumbLayer(item.layer, index);
            });
        }

        breadcrumb.appendChild(breadcrumbItem);

        // セパレータ追加
        if (index < breadcrumbStack.length - 1) {
            const separator = document.createElement('span');
            separator.className = 'breadcrumb-separator';
            separator.textContent = '→';
            breadcrumb.appendChild(separator);
        }
    });

    if (LOG_CONFIG.breadcrumb) {
        console.log('[パンくずリスト] 描画完了:', breadcrumbStack.map(b => b.name).join(' → '));
    }
}

// パンくずリストからレイヤーに移動
function navigateToBreadcrumbLayer(targetLayer, targetIndex) {
    if (LOG_CONFIG.breadcrumb) {
        console.log(`[パンくずナビゲーション] レイヤー${targetLayer}に移動、インデックス${targetIndex}`);
    }

    // メインフローに戻る場合
    if (targetLayer === 1) {
        // 編集モード中の場合は編集モードを終了
        if (editModeState.active) {
            if (LOG_CONFIG.breadcrumb) {
                console.log('[パンくずナビゲーション] 編集モード中のため、exitEditMode()を呼び出します');
            }
            exitEditMode();
        } else {
            // ドリルダウンパネルを閉じる
            closeDrilldownPanel();
        }
        return;
    }

    // 中間レイヤーの場合は、そのレイヤーを再表示
    // スタックを切り詰め
    breadcrumbStack = breadcrumbStack.slice(0, targetIndex + 1);
    renderBreadcrumb();

    // TODO: 中間レイヤーへの復元機能は今後実装
    // 現在は、ESCまたはメインフローのみサポート
    if (LOG_CONFIG.breadcrumb) {
        console.log('[パンくずナビゲーション] 中間レイヤー復元は未実装');
    }
}

// ホバープレビューのセットアップ
function setupHoverPreview() {
    if (LOG_CONFIG.pink) {
        console.log('[ホバープレビュー] setupHoverPreview初期化開始');
    }

    // 全てのピンクノードにホバーイベントを設定
    document.addEventListener('mouseenter', (e) => {
        if (e.target.classList.contains('node-button')) {
            const bgColor = window.getComputedStyle(e.target).backgroundColor;
            if (LOG_CONFIG.pink) {
                console.log(`[ホバープレビュー] ノードにマウスエンター: ${e.target.dataset.nodeId}, 色: ${bgColor}`);
            }
            if (isPinkColor(bgColor)) {
                handlePinkNodeHover(e.target, e);
            }
        }
    }, true);

    document.addEventListener('mouseleave', (e) => {
        if (e.target.classList.contains('node-button')) {
            if (LOG_CONFIG.pink) {
                console.log(`[ホバープレビュー] ノードからマウスリーブ: ${e.target.dataset.nodeId}`);
            }
            clearTimeout(hoverTimer);
            hidePreview();
        }
    }, true);

    if (LOG_CONFIG.pink) {
        console.log('[ホバープレビュー] setupHoverPreview初期化完了');
    }
}

// ピンクノードのホバー処理
function handlePinkNodeHover(node, event) {
    const nodeData = getNodeDataFromElement(node);
    if (LOG_CONFIG.pink) {
        console.log(`[ホバープレビュー] handlePinkNodeHover呼び出し - ノードID: ${node.dataset.nodeId}, nodeData: ${nodeData ? 'あり' : 'なし'}`);
        if (nodeData) {
            console.log(`[ホバープレビュー] ノードデータ - text: ${nodeData.text}, layer: ${nodeData.layer}`);
        }
    }
    if (!nodeData) return;

    // 0.8秒後にプレビュー表示
    hoverTimer = setTimeout(() => {
        if (LOG_CONFIG.pink) {
            console.log(`[ホバープレビュー] 0.8秒経過、showPreview呼び出し`);
        }
        showPreview(event, nodeData);
    }, 800);
}

// プレビュー表示
function showPreview(event, nodeData) {
    if (LOG_CONFIG.pink) {
        console.log(`[ホバープレビュー] showPreview開始 - nodeData.text: ${nodeData.text}, layer: ${nodeData.layer}`);
    }

    const preview = document.getElementById('hoverPreview');
    const previewTitle = document.getElementById('previewTitle');
    const previewContent = document.getElementById('previewContent');

    if (LOG_CONFIG.pink) {
        console.log(`[ホバープレビュー] DOM要素チェック - preview: ${preview ? 'あり' : 'なし'}, previewTitle: ${previewTitle ? 'あり' : 'なし'}, previewContent: ${previewContent ? 'あり' : 'なし'}`);
    }

    if (!preview || !previewTitle || !previewContent) {
        if (LOG_CONFIG.pink) {
            console.error('[ホバープレビュー] プレビュー用のDOM要素が見つかりません');
        }
        return;
    }

    // タイトル設定
    const nodeName = nodeData.text || 'スクリプト';
    previewTitle.textContent = `プレビュー: ${nodeName}`;

    // コンテンツ生成（このレイヤーに含まれるノードを表示）
    previewContent.innerHTML = '';

    // このピンクノードが展開する次のレイヤーのノードを取得
    const layerNodes = getNodesForPreview(nodeData);

    if (LOG_CONFIG.pink) {
        console.log(`[ホバープレビュー] レイヤーノード数: ${layerNodes ? layerNodes.length : 0}`);
    }

    if (layerNodes && layerNodes.length > 0) {
        layerNodes.slice(0, 5).forEach((childNode, index) => {
            const item = document.createElement('div');
            item.className = 'hover-preview-item';
            item.textContent = childNode.text || `ノード${index + 1}`;

            // ピンクノードの場合
            if (childNode.color === 'Pink') {
                item.innerHTML = '🟣 ' + item.textContent;
            }

            previewContent.appendChild(item);
        });

        if (layerNodes.length > 5) {
            const more = document.createElement('div');
            more.className = 'hover-preview-item';
            more.textContent = `... 他${layerNodes.length - 5}件`;
            more.style.color = 'var(--text-secondary)';
            previewContent.appendChild(more);
        }
    } else {
        const emptyItem = document.createElement('div');
        emptyItem.className = 'hover-preview-item';
        emptyItem.textContent = 'ノードがありません';
        emptyItem.style.color = 'var(--text-secondary)';
        previewContent.appendChild(emptyItem);
    }

    // 位置調整
    const rect = event.target.getBoundingClientRect();
    preview.style.left = (rect.right + 10) + 'px';
    preview.style.top = rect.top + 'px';

    // 表示
    preview.classList.add('show');

    if (LOG_CONFIG.pink) {
        console.log(`[ホバープレビュー] プレビュー表示完了 - 位置: (${preview.style.left}, ${preview.style.top})`);
    }
}

// プレビュー非表示
function hidePreview() {
    const preview = document.getElementById('hoverPreview');
    if (preview) {
        preview.classList.remove('show');
    }
}

// プレビュー用のノードデータ取得
function getNodesForPreview(parentNodeData) {
    // 親ノードのレイヤーの次のレイヤーからノードを取得
    const parentLayer = parentNodeData.layer || 1;
    const nextLayer = parentLayer + 1;

    if (nextLayer > 6) return [];

    // layerStructureから正しくノードを取得
    const nextLayerNodes = layerStructure[nextLayer] && layerStructure[nextLayer].nodes
        ? layerStructure[nextLayer].nodes
        : [];

    return nextLayerNodes;
}

// ノード要素からデータを取得
function getNodeDataFromElement(nodeElement) {
    const nodeId = nodeElement.dataset.nodeId;
    if (!nodeId) return null;

    // 既存のノード配列から検索（idプロパティを使用）
    return nodes.find(n => n.id === nodeId);
}

// ピンクノードドリルダウン処理（新UI用）
function handlePinkNodeDrilldown(nodeElement) {
    // ノードデータを取得（要素に保存されているか、配列から検索）
    let nodeData = nodeElement.nodeData;
    if (!nodeData) {
        nodeData = getNodeDataFromElement(nodeElement);
    }

    if (!nodeData) {
        console.warn('[ピンクノードドリルダウン] ノードデータが見つかりません');
        return;
    }

    if (LOG_CONFIG.pink) {
        console.log('[ピンクノードドリルダウン]', nodeData.text, 'レイヤー', nodeData.layer);
    }

    // 左パネルをdimmed状態に
    const leftPanel = document.getElementById('left-layer-panel');
    if (leftPanel) {
        leftPanel.classList.add('dimmed');
    }

    // 右パネルにレイヤーを表示
    showLayerInDrilldownPanel(nodeData);

    // パンくずリストを更新
    const layerName = nodeData.text || `スクリプト${nodeData.layer}`;
    breadcrumbStack.push({ name: layerName, layer: nodeData.layer + 1 });
    renderBreadcrumb();

    // ESCヒントを表示
    const escHint = document.getElementById('escHint');
    if (escHint) {
        escHint.classList.add('show');
    }

    // ドリルダウン状態を更新
    drilldownState.active = true;
    drilldownState.currentPinkNode = nodeElement;
    drilldownState.targetLayer = nodeData.layer + 1;
}

// ドリルダウンパネルにレイヤーを表示
function showLayerInDrilldownPanel(parentNodeData) {
    const rightPanel = document.getElementById('right-layer-panel');
    if (!rightPanel) return;

    const targetLayer = parentNodeData.layer + 1;

    // layerStructureから正しくノードを取得（既存ロジックと同じ）
    const layerNodes = layerStructure[targetLayer] && layerStructure[targetLayer].nodes
        ? layerStructure[targetLayer].nodes
        : [];

    if (LOG_CONFIG.pink) {
        console.log(`[ドリルダウン] レイヤー${targetLayer}のノード数: ${layerNodes.length}`);
        if (layerNodes.length > 0) {
            console.log(`[ドリルダウン] 最初のノード:`, layerNodes[0]);
        }
    }

    // 空状態を解除
    rightPanel.classList.remove('empty');

    // アニメーションクラス追加
    rightPanel.classList.add('slide-in');

    // コンテンツ生成
    const layerName = parentNodeData.text || `スクリプト${parentNodeData.layer}`;
    rightPanel.innerHTML = `
        <div class="layer-label" style="
            height: 40px;
            background: linear-gradient(135deg, var(--aurora-purple), var(--aurora-pink));
            margin: -20px -20px 20px -20px;
            border-radius: 20px 20px 0 0;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0 15px;
            color: white;
            font-weight: bold;
            font-size: 14px;
        ">
            <span>レイヤー${targetLayer} - ${layerName}</span>
            <button class="drilldown-edit-btn" onclick="enterEditMode(${targetLayer})" title="このレイヤーを編集">
                ✏️ 編集
            </button>
        </div>
        <div class="layer-indicator">L${targetLayer}</div>
        <div class="node-list-container" id="drilldown-nodes" style="position: relative; min-height: 400px;">
            <!-- ノードがここに表示される -->
        </div>
    `;

    // ノードを描画（既存のrenderNodesInLayerと同じロジック）
    const nodeContainer = rightPanel.querySelector('#drilldown-nodes');
    if (nodeContainer && layerNodes.length > 0) {
        // Y座標でソート
        const sortedNodes = layerNodes.sort((a, b) => a.y - b.y);

        sortedNodes.forEach(node => {
            const btn = document.createElement('div');
            btn.className = 'node-button';

            // テキストの省略表示（20文字以上は省略）
            const displayText = node.text.length > 20 ? node.text.substring(0, 20) + '...' : node.text;
            btn.textContent = displayText;
            btn.title = node.text; // ツールチップで完全なテキストを表示

            btn.style.backgroundColor = getColorCode(node.color);
            btn.style.position = 'absolute';
            btn.style.left = `${node.x || 90}px`;
            btn.style.top = `${node.y}px`;
            btn.dataset.nodeId = node.id;

            // 赤枠スタイルを適用
            if (node.redBorder) {
                btn.classList.add('red-border');
            }

            // 高さを設定
            if (node.height && node.height === 1) {
                btn.style.height = '1px';
                btn.style.minHeight = '1px';
                btn.style.fontSize = '0';
            } else {
                // ピンクノードの場合はドリルダウン可能にする
                if (node.color === 'Pink') {
                    btn.addEventListener('click', (e) => {
                        e.preventDefault();
                        e.stopPropagation();
                        handlePinkNodeDrilldown(btn);
                    });

                    // ノードデータを要素に保存
                    btn.nodeData = node;
                }

                // ダブルクリックで詳細設定を開く
                btn.addEventListener('dblclick', () => {
                    openNodeSettings(node);
                });
            }

            nodeContainer.appendChild(btn);
        });
    } else if (nodeContainer) {
        nodeContainer.innerHTML = '<div style="text-align: center; color: var(--text-secondary); padding: 20px;">ノードがありません</div>';
    }

    // アニメーション完了後にクラスを削除
    setTimeout(() => {
        rightPanel.classList.remove('slide-in');
    }, 400);
}

// ドリルダウンパネルを閉じる
function closeDrilldownPanel() {
    const rightPanel = document.getElementById('right-layer-panel');
    const leftPanel = document.getElementById('left-layer-panel');
    const escHint = document.getElementById('escHint');

    if (!rightPanel) return;

    // スライドアウトアニメーション
    rightPanel.classList.add('slide-out');

    setTimeout(() => {
        rightPanel.classList.remove('slide-out');
        rightPanel.classList.add('empty');
        rightPanel.innerHTML = `
            <div class="empty-message">
                <span>🟣 ピンクノードをクリックすると詳細が表示されます</span>
            </div>
        `;
    }, 400);

    // 左パネルのdimmedを解除
    if (leftPanel) {
        leftPanel.classList.remove('dimmed');
    }

    // ESCヒントを非表示
    if (escHint) {
        escHint.classList.remove('show');
    }

    // パンくずリストをリセット
    breadcrumbStack = [{ name: 'メインフロー', layer: 1 }];
    renderBreadcrumb();

    // ドリルダウン状態をクリア
    drilldownState.active = false;
    drilldownState.currentPinkNode = null;
    drilldownState.targetLayer = null;

    if (LOG_CONFIG.pink) {
        console.log('[ドリルダウン] パネルを閉じました');
    }
}

// 編集モードに入る（指定したレイヤーを左パネルで編集）
function enterEditMode(targetLayer) {
    if (LOG_CONFIG.breadcrumb) {
        console.log(`[編集モード] レイヤー${targetLayer}の編集モードに入ります`);
    }

    // ドリルダウンパネルを閉じる（パンくずリストは維持）
    const rightPanel = document.getElementById('right-layer-panel');
    const leftPanel = document.getElementById('left-layer-panel');
    const escHint = document.getElementById('escHint');

    if (rightPanel) {
        rightPanel.classList.add('slide-out');
        setTimeout(() => {
            rightPanel.classList.remove('slide-out');
            rightPanel.classList.add('empty');
            rightPanel.innerHTML = `
                <div class="empty-message">
                    <span>🟣 ピンクノードをクリックすると詳細が表示されます</span>
                </div>
            `;
        }, 400);
    }

    // 左パネルのdimmedを解除
    if (leftPanel) {
        leftPanel.classList.remove('dimmed');
    }

    // ESCヒントを非表示
    if (escHint) {
        escHint.classList.remove('show');
    }

    // ドリルダウン状態をクリア
    drilldownState.active = false;
    drilldownState.currentPinkNode = null;
    drilldownState.targetLayer = null;

    // 編集モード状態を有効化（renderNodesInLayerより前に設定）
    editModeState.active = true;
    editModeState.currentLayer = targetLayer;

    // leftVisibleLayerを編集対象レイヤーに設定（renderNodesInLayerより前に設定）
    leftVisibleLayer = targetLayer;

    // 左パネルの全レイヤーを非表示
    for (let i = 0; i <= 6; i++) {
        const layerPanel = document.getElementById(`layer-${i}`);
        if (layerPanel) {
            layerPanel.style.display = 'none';
        }
    }

    // 指定されたレイヤーのみ表示
    const targetLayerPanel = document.getElementById(`layer-${targetLayer}`);
    if (targetLayerPanel) {
        targetLayerPanel.style.display = 'block';

        // レイヤーのノードを再描画
        renderNodesInLayer(targetLayer, 'left');

        // 矢印を再描画
        setTimeout(() => {
            drawPanelArrows(`layer-${targetLayer}`);
        }, 100);

        if (LOG_CONFIG.breadcrumb) {
            console.log(`[編集モード] レイヤー${targetLayer}を表示しました`);
        }
    }

    // 編集モード状態を表示（パンくずリストに表示）
    const breadcrumb = document.getElementById('breadcrumb');
    if (breadcrumb) {
        // 編集モード表示を追加
        const editModeIndicator = document.createElement('div');
        editModeIndicator.className = 'edit-mode-indicator';
        editModeIndicator.innerHTML = '✏️ 編集モード <button class="exit-edit-btn" onclick="exitEditMode()">完了</button>';
        breadcrumb.appendChild(editModeIndicator);
    }

    if (LOG_CONFIG.breadcrumb) {
        console.log(`[編集モード] 編集モード有効化 - currentLayer: ${targetLayer}, leftVisibleLayer: ${leftVisibleLayer}`);
    }
}

// 編集モードを終了してメインフローに戻る
function exitEditMode() {
    if (LOG_CONFIG.breadcrumb) {
        console.log('[編集モード] 編集モードを終了します');
    }

    // 編集モード表示を削除
    const editModeIndicator = document.querySelector('.edit-mode-indicator');
    if (editModeIndicator) {
        editModeIndicator.remove();
    }

    // 左パネルの全レイヤーを非表示
    for (let i = 0; i <= 6; i++) {
        const layerPanel = document.getElementById(`layer-${i}`);
        if (layerPanel) {
            layerPanel.style.display = 'none';
        }
    }

    // レイヤー1（メインフロー）を表示
    const layer1Panel = document.getElementById('layer-1');
    if (layer1Panel) {
        layer1Panel.style.display = 'block';
        renderNodesInLayer(1, 'left');

        setTimeout(() => {
            drawPanelArrows('layer-1');
        }, 100);
    }

    // パンくずリストをリセット
    breadcrumbStack = [{ name: 'メインフロー', layer: 1 }];
    renderBreadcrumb();

    // 編集モード状態を無効化
    editModeState.active = false;
    editModeState.currentLayer = 1;

    // leftVisibleLayerをレイヤー1に戻す
    leftVisibleLayer = 1;

    if (LOG_CONFIG.breadcrumb) {
        console.log('[編集モード] メインフローに戻りました - leftVisibleLayer: 1');
    }
}

// ESCキー処理
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        // 編集モード中の場合
        if (editModeState.active) {
            e.preventDefault();
            exitEditMode();
        }
        // ドリルダウン中の場合
        else if (breadcrumbStack.length > 1) {
            e.preventDefault();
            closeDrilldownPanel();
        }
    }
});

// 初期化処理
function initLayerNavigation() {
    if (LOG_CONFIG.initialization) {
        console.log('[レイヤーナビゲーション] 初期化開始');
    }

    // パンくずリストを初期化
    renderBreadcrumb();

    // ホバープレビューを設定
    setupHoverPreview();

    if (LOG_CONFIG.initialization) {
        console.log('[レイヤーナビゲーション] 初期化完了');
    }
}

// DOMContentLoaded時に初期化
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initLayerNavigation);
} else {
    initLayerNavigation();
}
