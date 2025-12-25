// ============================================
// UIpowershell - Legacy UI JavaScript
// 既存Windows Forms版の完全再現
// ============================================

const APP_VERSION = '1.1.1';  // アプリバージョン - 多重分岐UX改善（PowerShellダイアログ統合）
const API_BASE = 'http://localhost:8080/api';

// ============================================
// ノードサイズ設定
// ============================================
const NODE_HEIGHT = 24;      // ノードの高さ（元: 40px → 60%: 24px）
const NODE_WIDTH = 120;      // ノードの幅
const NODE_SPACING = 10;     // ノード間の間隔（10px）

// ============================================
// デバッグ設定
// ============================================

// 🔴 マスターフラグ: trueにすると全てのconsole.logが表示される（フィルター無効化）
// エラー対応時のみ true にしてください（通常は false）
const DISABLE_LOG_FILTER = false;

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
// 注意: history以外はすべてfalseにして、履歴ログだけを表示
const LOG_CONFIG = {
    breadcrumb: false,       // パンくずリストのログ
    pink: false,             // ピンクノード処理のログ
    initialization: false,   // 初期化処理のログ
    history: true,           // ✅ Undo/Redo履歴のログ（これだけtrue）
    controlLog: false,       // コントロールログ（起動時のタイムスタンプ）
    hoverPreview: false,     // ホバープレビューのログ
    loopGroups: false,       // ループグループ検出のログ
    apiTiming: false,        // API呼び出しタイミングのログ
    memoryLoad: false,       // memory.json読み込み警告
    buttonSettings: false,   // ボタン設定読み込みログ
    folderInit: false,       // フォルダ初期化ログ
    general: false,          // その他の一般ログ
    scriptDebug: false       // スクリプト化デバッグログ（問題調査用）
};

// フィルター付きログ関数
function debugLog(category, ...args) {
    if (DEBUG_FLAGS[category]) {
        console.log(...args);
    }
}

// ============================================
// コントロールログ関数
// ============================================

/**
 * コントロールログを記録（サーバーに送信）
 * 起動時からノード生成可能までのタイムスタンプを記録
 * @param {string} message - ログメッセージ
 */
async function writeControlLog(message) {
    const now = new Date();
    const timestamp = now.toISOString().replace('T', ' ').substring(0, 23);

    // 時刻をミリ秒付きでフォーマット (HH:MM:SS.mmm)
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');
    const milliseconds = String(now.getMilliseconds()).padStart(3, '0');
    const timeOnly = `${hours}:${minutes}:${seconds}.${milliseconds}`;

    const logMessage = `🕒 [ControlLog] [${timeOnly}] ${message}`;

    // ブラウザコンソールに表示（LOG_CONFIG.controlLogがtrueの場合のみ）
    if (LOG_CONFIG.controlLog) {
        console.log(logMessage);
    }

    try {
        await fetch(`${API_BASE}/control-log`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ message: `[BROWSER] [${timestamp}] ${message}` })
        });
    } catch (error) {
        // サーバーへの送信失敗は無視（起動初期はサーバーがまだ起動していない可能性がある）
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
        // DISABLE_LOG_FILTERがtrueの場合はフィルターをスキップ
        if (DISABLE_LOG_FILTER) {
            originalConsole[method].apply(console, args);
            const logEntry = {
                level: level,
                timestamp: new Date().toISOString(),
                message: args.map(arg => {
                    if (typeof arg === 'object') {
                        try { return JSON.stringify(arg); } catch (e) { return String(arg); }
                    }
                    return String(arg);
                }).join(' ')
            };
            consoleLogBuffer.push(logEntry);
            if (level === 'error') {
                sendLogsToServer([logEntry]);
                consoleLogBuffer = consoleLogBuffer.filter(log => log !== logEntry);
            }
            return;
        }

        // console.logのみフィルターを適用
        if (method === 'log') {
            // ログメッセージを文字列化
            const message = args.map(arg => String(arg)).join(' ');

            // LOG_CONFIG.pinkがtrueの場合、ピンク関連のログは常に表示
            const pinkRelatedPrefixes = [
                '[ホバープレビュー]', '[ピンク展開]', '[ピンク展開ポップアップ]', '[ピンク検出]', '[ピンクノード', '[ドリルダウン]'
            ];
            const isPinkLog = pinkRelatedPrefixes.some(prefix => message.includes(prefix));
            if (LOG_CONFIG.pink && isPinkLog) {
                // LOG_CONFIG.pinkが有効な場合はフィルターをスキップ
                originalConsole[method].apply(console, args);
                const logEntry = {
                    level: level,
                    timestamp: new Date().toISOString(),
                    message: message
                };
                consoleLogBuffer.push(logEntry);
                return;
            }

            // LOG_CONFIGに基づいてログを制御
            // ⚠️ 警告は常に表示、❌ エラーも常に表示
            const alwaysShowPrefixes = ['⚠', '❌'];
            if (alwaysShowPrefixes.some(prefix => message.includes(prefix))) {
                // 警告とエラーは常に表示
                originalConsole[method].apply(console, args);
                const logEntry = {
                    level: level,
                    timestamp: new Date().toISOString(),
                    message: message
                };
                consoleLogBuffer.push(logEntry);
                return;
            }

            // LOG_CONFIGで制御されるログ（アイコンがあっても制御対象）
            const logPrefixConfig = [
                { prefix: '🔍 [API Timing]', flag: 'apiTiming' },
                { prefix: '[ボタン設定]', flag: 'buttonSettings' },
                { prefix: '[ボタン生成]', flag: 'buttonSettings' },
                { prefix: '[初期化]', flag: 'folderInit' },
                { prefix: '│ ✅', flag: 'folderInit' },
                { prefix: '[ボタン有効化]', flag: 'folderInit' },
                { prefix: '[ボタンクリック]', flag: 'general' },
                { prefix: '[addNodeToLayer]', flag: 'general' },
                { prefix: '🕒 [ControlLog]', flag: 'controlLog' },
                { prefix: '[横スクロール]', flag: 'general' },
                { prefix: '[memory.json読み込み]', flag: 'memoryLoad' },
                { prefix: '✅ UIpowershell 初期化完了', flag: 'general' },
                // スクリプト化デバッグログ
                { prefix: '┌─ [memory.json', flag: 'scriptDebug' },
                { prefix: '│ [L', flag: 'scriptDebug' },
                { prefix: '│   ★', flag: 'scriptDebug' },
                { prefix: '└─ [memory.json', flag: 'scriptDebug' },
                { prefix: '┌─ [コード.json', flag: 'scriptDebug' },
                { prefix: '│ エントリ', flag: 'scriptDebug' },
                { prefix: '│ 最後のID', flag: 'scriptDebug' },
                { prefix: '│   [', flag: 'scriptDebug' },
                { prefix: '└────', flag: 'scriptDebug' }
            ];

            // LOG_CONFIGで制御されるログの処理
            for (const config of logPrefixConfig) {
                if (message.includes(config.prefix)) {
                    if (LOG_CONFIG[config.flag]) {
                        // フラグがtrueの場合は表示
                        originalConsole[method].apply(console, args);
                        const logEntry = {
                            level: level,
                            timestamp: new Date().toISOString(),
                            message: message
                        };
                        consoleLogBuffer.push(logEntry);
                        return;
                    } else {
                        // フラグがfalseの場合はサーバーにはログを送るが、ブラウザコンソールには表示しない
                        const logEntry = {
                            level: level,
                            timestamp: new Date().toISOString(),
                            message: message
                        };
                        consoleLogBuffer.push(logEntry);
                        return; // ブラウザコンソールへの出力をスキップ
                    }
                }
            }

            // 履歴ログは必ず表示（LOG_CONFIG.historyに関わらず）
            if (message.includes('[履歴]')) {
                originalConsole[method].apply(console, args);
                const logEntry = {
                    level: level,
                    timestamp: new Date().toISOString(),
                    message: message
                };
                consoleLogBuffer.push(logEntry);
                return;
            }

            // その他のログ：アイコンがないログは抑制
            const hasIcon = ['❌', '✅', '⚠', '🕒', '🎉', '🔍'].some(icon => message.includes(icon));
            if (!hasIcon) {
                // アイコンがないログは抑制
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
let rightVisibleLayer = 1;      // 右パネルに表示中のレイヤー（起動時は非表示、スクリプト展開時のみ表示）
let currentCategory = 1;        // 現在選択中のカテゴリー
let nodes = [];                 // 全ノード配列（全レイヤー）
let buttonSettings = [];        // ボタン設定.jsonのデータ
let categorySettings = [];      // カテゴリ設定.jsonのデータ
let variables = {};             // 変数データ
let folders = [];               // フォルダ一覧
let currentFolder = null;       // 現在のフォルダ
let isRestoringHistory = false; // Undo/Redo実行中フラグ（履歴記録をスキップするため）
let contextMenuTarget = null;   // 右クリックメニューの対象ノード
let draggedNode = null;         // ドラッグ中のノード
let dropIndicator = null;       // ドロップ位置インジケーター（青い線）
let layerStructure = {          // レイヤー構造
    0: { visible: false, nodes: [], edges: [] },
    1: { visible: true, nodes: [], edges: [] },
    2: { visible: false, nodes: [], edges: [] },
    3: { visible: false, nodes: [], edges: [] },
    4: { visible: false, nodes: [], edges: [] },
    5: { visible: false, nodes: [], edges: [] },
    6: { visible: false, nodes: [], edges: [] }
};

// ノードカウンター（ID生成用）
let nodeCounter = 1;

// GroupIDカウンター（オリジナルPowerShellと同じ仕様）
let loopGroupCounter = 1000;      // ループ用（1000番台）
let conditionGroupCounter = 2000; // 条件分岐用（2000番台）
let userGroupCounter = 3000;      // ユーザー作成グループ用（3000番台）

// ユーザーグループ管理
let userGroups = {};  // { groupId: { name: 'グループ名', collapsed: false, nodes: [...] } }

// 複数ノード選択管理
let selectedNodes = [];  // 選択中のノードID配列
let isMultiSelectMode = false;  // 複数選択モード中か

// ポップアップウィンドウ管理（レイヤー詳細）
let layerPopups = new Map();      // レイヤー番号 -> Windowオブジェクト
let layerPopupData = new Map();   // レイヤー番号 -> { layer, nodes, parentNode }

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

// ============================================
// 関数管理（関数化機能）
// ============================================

// 関数データ構造
// 関数はfunctions/フォルダに個別JSONで保存され、複数プロジェクトで共有可能
let userFunctions = [];  // { id, name, nodes, params: [], returns: [], createdAt, updatedAt }

// 関数IDカウンター
let functionIdCounter = 1;

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
    // ★修正: getBoundingClientRect()ではなく、ノードのstyle.topを直接使用
    // これによりスクロール位置やビューポートに依存しない正確な座標が得られる
    const fromTop = parseInt(fromNode.style.top, 10) || 0;
    const fromLeft = parseInt(fromNode.style.left, 10) || 90;
    const fromHeight = fromNode.offsetHeight || NODE_HEIGHT;
    const fromWidth = fromNode.offsetWidth || 120;

    const toTop = parseInt(toNode.style.top, 10) || 0;
    const toLeft = parseInt(toNode.style.left, 10) || 90;

    // 開始点: fromNodeの下端中央（0.5pxオフセットでシャープな線に）
    const startX = Math.floor(fromLeft + fromWidth / 2) + 0.5;
    const startY = Math.floor(fromTop + fromHeight) + 0.5;

    // 終了点: toNodeの上端中央
    const endX = Math.floor(toLeft + fromWidth / 2) + 0.5;
    const endY = Math.floor(toTop) + 0.5;

    // 詳細デバッグログ
    console.log(`[座標デバッグ] fromNode: top=${fromTop}, left=${fromLeft}, height=${fromHeight}, width=${fromWidth}`);
    console.log(`[座標デバッグ] toNode: top=${toTop}, left=${toLeft}`);
    console.log(`[座標デバッグ] 計算された矢印座標: (${startX}, ${startY}) → (${endX}, ${endY}), color=${color}`);
    console.log(`[座標デバッグ] Canvas dimensions: ${ctx.canvas.width} x ${ctx.canvas.height}`);

    // 線を描画
    console.log(`[矢印色デバッグ] 指定色: ${color}, ctx.strokeStyle設定前: ${ctx.strokeStyle}`);
    ctx.strokeStyle = color;
    console.log(`[矢印色デバッグ] ctx.strokeStyle設定後: ${ctx.strokeStyle}`);
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(startX, startY);
    ctx.lineTo(endX, endY);
    ctx.stroke();

    console.log(`[座標デバッグ] stroke() 実行完了, 最終strokeStyle: ${ctx.strokeStyle}`);

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
    ctx.imageSmoothingEnabled = false;
    const containerRect = leftContainer.getBoundingClientRect();
    const pinkRect = pinkNode.getBoundingClientRect();

    // ピンクノードの右端中央 → パネル右端
    const startX = pinkRect.right - containerRect.left;
    const startY = pinkRect.top + pinkRect.height / 2 - containerRect.top;
    const endX = leftContainer.offsetWidth;
    const endY = startY;

    ctx.strokeStyle = '#ffb6c1'; // LightPink (パステル)
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
    // 右パネル（*-right）はスキップ（ただしdrilldown-panelは除く）
    if (layerId.includes('-right') && layerId !== 'drilldown-panel') {
        return;
    }

    // console.log(`[デバッグ] drawPanelArrows() 呼び出し: layerId=${layerId}`);

    const canvas = arrowState.canvasMap.get(layerId);
    if (!canvas) {
        // 右パネルのCanvasが見つからない場合は警告を出さない
        if (!layerId.includes('-right') && layerId !== 'drilldown-panel') {
            console.error(`[デバッグ] Canvas が見つかりません: ${layerId}`);
        }
        return;
    }

    // ドリルダウンパネルの場合はright-layer-panelを取得
    const panelId = layerId === 'drilldown-panel' ? 'right-layer-panel' : layerId;
    const layerPanel = document.getElementById(panelId);
    if (!layerPanel) {
        if (!layerId.includes('-right') && layerId !== 'drilldown-panel') {
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

        // ★修正: min-heightスタイルから高さを取得（ノード配置に合わせて動的に設定されている）
        const minHeightStyle = nodeListContainer.style.minHeight;
        const minHeight = minHeightStyle ? parseInt(minHeightStyle, 10) : 700;
        const parentHeight = Math.max(nodeListContainer.clientHeight, nodeListContainer.offsetHeight, nodeListContainer.scrollHeight, minHeight, 700);

        // Canvasの内部描画サイズのみ更新（CSS で表示サイズは 100% に設定済み）
        canvas.width = parentWidth;
        canvas.height = parentHeight;

        // ★修正: CSSスタイルも更新（Canvas表示サイズをコンテナに合わせる）
        canvas.style.width = parentWidth + 'px';
        canvas.style.height = parentHeight + 'px';

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
    ctx.imageSmoothingEnabled = false;  // シャープな線のためにスムージングを無効化

    // 非表示ノード（折りたたみ中のグループノード等）をフィルタリング
    const allNodes = Array.from(layerPanel.querySelectorAll('.node-button'));
    const nodes = allNodes.filter(node => {
        // display: none のノードを除外
        const style = window.getComputedStyle(node);
        return style.display !== 'none' && style.visibility !== 'hidden';
    });
    // console.log(`[デバッグ] 取得したノード数: ${nodes.length} (全体: ${allNodes.length})`);

    // ノードをY座標でソート
    nodes.sort((a, b) => {
        const aTop = parseInt(a.style.top, 10) || 0;
        const bTop = parseInt(b.style.top, 10) || 0;
        return aTop - bTop;
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

        // 通常ノード間の矢印（黒）: White, Pink, Aquamarine, ActionOrange, ReadCyan を通常扱い
        const isCurrentNormal = isWhiteColor(currentColor) || isPinkColor(currentColor) || isAquamarineColor(currentColor) || isActionOrangeColor(currentColor) || isReadCyanColor(currentColor);
        const isNextNormal = isWhiteColor(nextColor) || isPinkColor(nextColor) || isAquamarineColor(nextColor) || isActionOrangeColor(nextColor) || isReadCyanColor(nextColor);

        // 通常ノード → 通常ノード
        if (isCurrentNormal && isNextNormal) {
            console.log(`[デバッグ] 通常→通常の矢印を描画: ${i} → ${i+1}`);
            drawDownArrow(ctx, currentNode, nextNode, '#000000');
            arrowCount++;
        }
        // 通常ノード → 緑（条件分岐開始前）
        else if (isCurrentNormal && isSpringGreenColor(nextColor)) {
            drawDownArrow(ctx, currentNode, nextNode, '#000000');
        }
        // 緑 → 通常ノード（条件分岐終了後）
        else if (isSpringGreenColor(currentColor) && isNextNormal) {
            drawDownArrow(ctx, currentNode, nextNode, '#000000');
        }
        // 通常ノード → 黄（ループ開始前）
        else if (isCurrentNormal && isLemonChiffonColor(nextColor)) {
            drawDownArrow(ctx, currentNode, nextNode, '#000000');
        }
        // 黄 → 通常ノード（ループ終了後）
        else if (isLemonChiffonColor(currentColor) && isNextNormal) {
            drawDownArrow(ctx, currentNode, nextNode, '#000000');
        }
        // 黄 → 緑（ループ開始 → 条件分岐開始）
        else if (isLemonChiffonColor(currentColor) && isSpringGreenColor(nextColor)) {
            drawDownArrow(ctx, currentNode, nextNode, '#000000');
        }
        // 緑 → 黄（条件分岐終了 → ループ終了）
        else if (isSpringGreenColor(currentColor) && isLemonChiffonColor(nextColor)) {
            drawDownArrow(ctx, currentNode, nextNode, '#000000');
        }
        // 緑 → 緑（条件分岐 → 条件分岐）
        else if (isSpringGreenColor(currentColor) && isSpringGreenColor(nextColor)) {
            drawDownArrow(ctx, currentNode, nextNode, '#000000');
        }
        // 黄 → 黄（ループ → ループ）
        else if (isLemonChiffonColor(currentColor) && isLemonChiffonColor(nextColor)) {
            drawDownArrow(ctx, currentNode, nextNode, '#000000');
        }
        // 注: 赤→赤と青→青はdrawConditionalBranchArrows内で処理されるため、ここでは削除
    }
    // console.log(`[デバッグ] 描画した通常矢印数: ${arrowCount}`);

    // コンテナの矩形とスクロール位置を取得（条件分岐とループで共通使用）
    const containerRect = nodeListContainer.getBoundingClientRect();
    const scrollTop = nodeListContainer.scrollTop || 0;
    const scrollLeft = nodeListContainer.scrollLeft || 0;

    // レイヤー番号を抽出
    const layerMatch = layerId.match(/layer-(\d+)/);
    const layerNumber = layerMatch ? parseInt(layerMatch[1], 10) : 1;

    // 条件分岐の矢印を描画（色ベース - Grayノードで分岐判定、多重分岐対応）
    conditionGroups.forEach(group => {
        drawConditionalBranchArrows(ctx, group.startNode, group.endNode, group.innerNodes, containerRect, scrollTop, scrollLeft, group.grayIndices, group.branchCount);
    });

    // 最大分岐オフセットを計算（ループ矢印が分岐矢印と重ならないように）
    // 分岐終了矢印のオフセット計算式: 20 + (branchIdx * 10)
    let maxBranchOffset = 0;
    conditionGroups.forEach(group => {
        const maxBranchIdx = group.branchCount - 1;
        const branchOffset = 20 + (maxBranchIdx * 10);
        if (branchOffset > maxBranchOffset) {
            maxBranchOffset = branchOffset;
        }
    });
    // ループ矢印のオフセット = 最大分岐オフセット + マージン（20px）
    // 分岐がない場合は従来の30pxを使用
    const loopArrowOffset = maxBranchOffset > 0 ? maxBranchOffset + 20 : 30;

    // ループの矢印を描画
    const loopGroups = findLoopGroups(nodes);
    if (LOG_CONFIG.loopGroups) {
        console.log(`🔍 [drawPanelArrows] layerId=${layerId}, ループグループ数: ${loopGroups.length}, loopArrowOffset: ${loopArrowOffset}`);
    }
    loopGroups.forEach(group => {
        if (LOG_CONFIG.loopGroups) {
            console.log(`🔍 [drawPanelArrows] ループ矢印描画: ${group.startNode.textContent} → ${group.endNode.textContent}`);
        }
        drawLoopArrows(ctx, group.startNode, group.endNode, containerRect, scrollTop, scrollLeft, loopArrowOffset);
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
                    const innerNodes = currentGroup.slice(1, -1);
                    // Grayノードのインデックスを収集（多重分岐対応）
                    const grayIndices = [];
                    innerNodes.forEach((n, idx) => {
                        if (isGrayColor(window.getComputedStyle(n).backgroundColor)) {
                            grayIndices.push(idx);
                        }
                    });

                    // 分岐数を計算（Grayノード数 + 1）
                    const branchCount = grayIndices.length + 1;

                    groups.push({
                        startNode: currentGroup[0],
                        endNode: currentGroup[currentGroup.length - 1],
                        innerNodes: innerNodes,
                        grayIndices: grayIndices,  // Grayノードの位置（多重分岐用）
                        branchCount: branchCount   // 分岐数
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

// 条件分岐の複雑な矢印を描画（多重分岐対応）
// grayIndices: innerNodes内のGrayノードのインデックス配列
// branchCount: 分岐数（デフォルト2 = if-else）
function drawConditionalBranchArrows(ctx, startNode, endNode, innerNodes, containerRect, scrollTop = 0, scrollLeft = 0, grayIndices = [], branchCount = 2) {
    // ★修正: style.topを直接使用（getBoundingClientRectはビューポート依存のため不正確）
    const startTop = parseInt(startNode.style.top, 10) || 0;
    const startLeft = parseInt(startNode.style.left, 10) || 90;
    const startHeight = startNode.offsetHeight || NODE_HEIGHT;
    const startWidth = startNode.offsetWidth || 120;

    const endTop = parseInt(endNode.style.top, 10) || 0;
    const endLeft = parseInt(endNode.style.left, 10) || 90;
    const endHeight = endNode.offsetHeight || NODE_HEIGHT;
    const endWidth = endNode.offsetWidth || 120;

    // 後方互換性: grayIndicesが渡されない場合は従来の方法で取得
    if (!grayIndices || grayIndices.length === 0) {
        grayIndices = [];
        innerNodes.forEach((n, idx) => {
            if (isGrayColor(window.getComputedStyle(n).backgroundColor)) {
                grayIndices.push(idx);
            }
        });
        branchCount = grayIndices.length + 1;
    }

    // 内部ノードをデバッグ出力
    console.log(`[条件分岐デバッグ] innerNodes数: ${innerNodes.length}, 分岐数: ${branchCount}, Grayインデックス: [${grayIndices.join(', ')}]`);

    // 各分岐のノードを収集
    // branches[0] = 開始→最初のGray間のノード（False分岐）
    // branches[1] = 最初のGray→2番目のGray間のノード（ElseIf1分岐）
    // ...
    // branches[N-1] = 最後のGray→終了間のノード（True分岐）
    const branches = [];
    let prevGrayIndex = -1;

    for (let i = 0; i < branchCount; i++) {
        const startIdx = prevGrayIndex + 1;
        const endIdx = (i < grayIndices.length) ? grayIndices[i] : innerNodes.length;

        const branchNodes = [];
        for (let j = startIdx; j < endIdx; j++) {
            const node = innerNodes[j];
            const color = window.getComputedStyle(node).backgroundColor;
            // Grayノードは除外
            if (!isGrayColor(color)) {
                branchNodes.push(node);
            }
        }
        branches.push(branchNodes);
        prevGrayIndex = (i < grayIndices.length) ? grayIndices[i] : innerNodes.length;
    }

    console.log(`[条件分岐] 分岐数: ${branches.length}`);
    branches.forEach((b, idx) => {
        console.log(`  分岐${idx}: ${b.length}ノード`);
    });

    // 分岐ごとの色を定義（多重分岐対応）
    const branchColors = getBranchColors(branchCount);

    // === 分岐ラベルを描画 ===
    drawBranchLabels(ctx, startNode, endNode, innerNodes, grayIndices, branchCount, branchColors);

    // === 各分岐の矢印を描画 ===

    for (let branchIdx = 0; branchIdx < branches.length; branchIdx++) {
        const branchNodes = branches[branchIdx];
        const branchColor = branchColors[branchIdx];
        const isFirstBranch = branchIdx === 0;
        const isLastBranch = branchIdx === branches.length - 1;

        if (branchNodes.length === 0) continue;

        const firstNode = branchNodes[0];
        const lastNode = branchNodes[branchNodes.length - 1];

        // 1. 開始ノード → 分岐の最初のノード
        if (isFirstBranch) {
            // False分岐: 下向き矢印
            drawDownArrow(ctx, startNode, firstNode, branchColor);
        } else {
            // ElseIf/True分岐: 右→下の複雑な矢印
            drawBranchStartArrow(ctx, startNode, firstNode, branchColor, branchIdx);
        }

        // 2. 分岐内のノード間の矢印
        for (let i = 0; i < branchNodes.length - 1; i++) {
            drawDownArrow(ctx, branchNodes[i], branchNodes[i + 1], branchColor);
        }

        // 3. 分岐の最後のノード → 終了ノード
        if (isFirstBranch) {
            // False分岐: 左→下→右の複雑な矢印
            drawBranchEndArrow(ctx, lastNode, endNode, branchColor, 'left', 0);
        } else if (isLastBranch) {
            // True分岐: 下向き矢印
            drawDownArrow(ctx, lastNode, endNode, branchColor);
        } else {
            // ElseIf分岐: 左→下→左の複雑な矢印（False分岐と同じ側だがオフセットが異なる）
            drawBranchEndArrow(ctx, lastNode, endNode, branchColor, 'left', branchIdx);
        }
    }
}

// 分岐色の配列を取得（多重分岐対応）
function getBranchColors(branchCount) {
    const baseColors = [
        'rgb(250, 128, 114)',  // 赤（False/最初の分岐）
        '#ff8c00',              // オレンジ（ElseIf1）
        '#ffd700',              // 黄色（ElseIf2）
        '#32cd32',              // ライムグリーン（ElseIf3）
        '#00ced1',              // ダークターコイズ（ElseIf4）
        '#9370db',              // ミディアムパープル（ElseIf5）
        '#ff69b4',              // ホットピンク（ElseIf6）
        '#1e90ff',              // DodgerBlue（True/最後の分岐）
    ];

    if (branchCount === 2) {
        // 従来の2分岐: 赤と青
        return ['rgb(250, 128, 114)', '#1e90ff'];
    }

    // 多重分岐: 最初は赤、最後は青、中間は順番に色を割り当て
    const colors = [];
    colors.push(baseColors[0]);  // 最初の分岐は赤

    for (let i = 1; i < branchCount - 1; i++) {
        const colorIdx = Math.min(i, baseColors.length - 2);
        colors.push(baseColors[colorIdx]);
    }

    colors.push(baseColors[baseColors.length - 1]);  // 最後の分岐は青

    return colors;
}

/**
 * 分岐ラベルを描画（True, ElseIf 1, ElseIf 2, ..., False）
 * Grayノードの少し下（下側分岐に寄せて）にラベルを配置
 */
function drawBranchLabels(ctx, startNode, endNode, innerNodes, grayIndices, branchCount, branchColors) {
    const startTop = parseInt(startNode.style.top, 10) || 0;
    const startLeft = parseInt(startNode.style.left, 10) || 90;
    const startHeight = startNode.offsetHeight || NODE_HEIGHT;
    const startWidth = startNode.offsetWidth || 120;

    // ラベルのスタイル設定
    ctx.font = 'bold 10px "Segoe UI", Arial, sans-serif';
    ctx.textBaseline = 'middle';

    // 分岐ラベル名を生成（True/Falseを修正）
    const branchLabels = [];
    for (let i = 0; i < branchCount; i++) {
        if (i === 0) {
            branchLabels.push('True');  // 最初の分岐はTrue（条件成立時）
        } else if (i === branchCount - 1) {
            branchLabels.push('False'); // 最後の分岐はFalse（Else）
        } else {
            branchLabels.push(`ElseIf ${i}`);
        }
    }

    // 最初の分岐（True）のラベルは開始ノードの下に表示（中央揃え）
    const firstLabel = branchLabels[0];
    const firstColor = branchColors[0];
    ctx.textAlign = 'center';
    const firstLabelX = startLeft + startWidth / 2;
    const firstLabelY = startTop + startHeight + 12;

    const firstLabelWidth = ctx.measureText(firstLabel).width + 10;
    ctx.fillStyle = 'rgba(255, 255, 255, 0.95)';
    ctx.fillRect(firstLabelX - firstLabelWidth / 2, firstLabelY - 7, firstLabelWidth, 14);
    ctx.strokeStyle = firstColor;
    ctx.lineWidth = 1.5;
    ctx.strokeRect(firstLabelX - firstLabelWidth / 2, firstLabelY - 7, firstLabelWidth, 14);
    ctx.fillStyle = firstColor;
    ctx.fillText(firstLabel, firstLabelX, firstLabelY);

    // Grayノードの少し下にラベルを配置（下側分岐に寄せる）
    for (let i = 1; i < branchCount; i++) {
        const label = branchLabels[i];
        const color = branchColors[i];

        // 対応するGrayノードを取得
        const grayIdx = grayIndices[i - 1];
        if (grayIdx === undefined || !innerNodes[grayIdx]) {
            continue;
        }

        const grayNode = innerNodes[grayIdx];
        const grayTop = parseInt(grayNode.style.top, 10) || 0;
        const grayLeft = parseInt(grayNode.style.left, 10) || 90;
        const grayWidth = grayNode.offsetWidth || 20;

        // ラベル位置（Grayノードの少し下、下側分岐に寄せる）
        ctx.textAlign = 'center';
        const labelX = grayLeft + grayWidth / 2;
        const labelY = grayTop + 10;  // 少し下にオフセット

        // ラベル背景（視認性向上）
        const labelWidth = ctx.measureText(label).width + 12;
        const labelHeight = 14;
        ctx.fillStyle = 'rgba(255, 255, 255, 0.95)';
        ctx.fillRect(labelX - labelWidth / 2, labelY - labelHeight / 2, labelWidth, labelHeight);

        // ラベル枠線（矢印と同じ色）
        ctx.strokeStyle = color;
        ctx.lineWidth = 1.5;
        ctx.strokeRect(labelX - labelWidth / 2, labelY - labelHeight / 2, labelWidth, labelHeight);

        // ラベルテキスト
        ctx.fillStyle = color;
        ctx.fillText(label, labelX, labelY);
    }
}

// 分岐開始の複雑な矢印を描画（右→下）
function drawBranchStartArrow(ctx, startNode, targetNode, color, branchIdx) {
    const startTop = parseInt(startNode.style.top, 10) || 0;
    const startLeft = parseInt(startNode.style.left, 10) || 90;
    const startHeight = startNode.offsetHeight || NODE_HEIGHT;
    const startWidth = startNode.offsetWidth || 120;

    const targetTop = parseInt(targetNode.style.top, 10) || 0;
    const targetLeft = parseInt(targetNode.style.left, 10) || 90;
    const targetHeight = targetNode.offsetHeight || NODE_HEIGHT;
    const targetWidth = targetNode.offsetWidth || 120;

    // 開始ノードの右端（Y座標は分岐ごとにオフセットして重なりを防ぐ）
    const lineStartX = startLeft + startWidth;
    // 中央を基準に分岐ごとに3pxずらす（上下に分散）
    const yOffset = (branchIdx - 3) * 3;  // branchIdx=1で-6、2で-3、3で0、4で+3...
    const lineStartY = startTop + startHeight / 2 + yOffset;
    // 分岐ごとにX方向もオフセットを変える
    const horizontalEndX = lineStartX + 20 + (branchIdx * 10);
    // ターゲットノードの中央Y座標
    const targetY = targetTop + targetHeight / 2;

    ctx.strokeStyle = color;
    ctx.lineWidth = 2;

    // 右への横線
    ctx.beginPath();
    ctx.moveTo(lineStartX, lineStartY);
    ctx.lineTo(horizontalEndX, lineStartY);
    ctx.stroke();

    // 下への縦線
    ctx.beginPath();
    ctx.moveTo(horizontalEndX, lineStartY);
    ctx.lineTo(horizontalEndX, targetY);
    ctx.stroke();

    // ターゲットノードへの横線
    const targetRightX = targetLeft + targetWidth;
    ctx.beginPath();
    ctx.moveTo(horizontalEndX, targetY);
    ctx.lineTo(targetRightX, targetY);
    ctx.stroke();
}

// 分岐終了の複雑な矢印を描画（左→下→右 または 右→下→左）
function drawBranchEndArrow(ctx, sourceNode, endNode, color, direction = 'left', branchIdx = 0) {
    const sourceTop = parseInt(sourceNode.style.top, 10) || 0;
    const sourceLeft = parseInt(sourceNode.style.left, 10) || 90;
    const sourceHeight = sourceNode.offsetHeight || NODE_HEIGHT;
    const sourceWidth = sourceNode.offsetWidth || 120;

    const endTop = parseInt(endNode.style.top, 10) || 0;
    const endLeft = parseInt(endNode.style.left, 10) || 90;
    const endHeight = endNode.offsetHeight || NODE_HEIGHT;
    const endWidth = endNode.offsetWidth || 120;

    // 終了ノードのY座標（分岐ごとにオフセットして重なりを防ぐ）
    // 中央を基準に分岐ごとに3pxずらす（上下に分散）
    const yOffset = (branchIdx - 2) * 3;  // branchIdx=0で-6、1で-3、2で0、3で+3...
    const lineEndY = endTop + endHeight / 2 + yOffset;

    ctx.strokeStyle = color;
    ctx.lineWidth = 2;

    if (direction === 'left') {
        // 左→下→右（False/ElseIf分岐用）
        const lineStartX = sourceLeft;
        const lineStartY = sourceTop + sourceHeight / 2;
        const horizontalEndX = Math.max(lineStartX - 20 - (branchIdx * 10), 0);

        // 左への横線
        ctx.beginPath();
        ctx.moveTo(lineStartX, lineStartY);
        ctx.lineTo(horizontalEndX, lineStartY);
        ctx.stroke();

        // 下への縦線
        ctx.beginPath();
        ctx.moveTo(horizontalEndX, lineStartY);
        ctx.lineTo(horizontalEndX, lineEndY);
        ctx.stroke();

        // 終了ノードへの横線と矢印
        ctx.beginPath();
        ctx.moveTo(horizontalEndX, lineEndY);
        ctx.lineTo(endLeft, lineEndY);
        ctx.stroke();

        // 矢印ヘッド
        drawArrowHead(ctx, horizontalEndX, lineEndY, endLeft, lineEndY);
    } else {
        // 右→下→左（旧ElseIf分岐用、現在は使用しない）
        const lineStartX = sourceLeft + sourceWidth;
        const lineStartY = sourceTop + sourceHeight / 2;
        const horizontalEndX = lineStartX + 20 + (branchIdx * 10);

        // 右への横線
        ctx.beginPath();
        ctx.moveTo(lineStartX, lineStartY);
        ctx.lineTo(horizontalEndX, lineStartY);
        ctx.stroke();

        // 下への縦線
        ctx.beginPath();
        ctx.moveTo(horizontalEndX, lineStartY);
        ctx.lineTo(horizontalEndX, lineEndY);
        ctx.stroke();

        // 終了ノードへの横線と矢印
        const endRightX = endLeft + endWidth;
        ctx.beginPath();
        ctx.moveTo(horizontalEndX, lineEndY);
        ctx.lineTo(endRightX, lineEndY);
        ctx.stroke();

        // 矢印ヘッド（逆向き）
        drawArrowHead(ctx, horizontalEndX, lineEndY, endRightX, lineEndY);
    }
}

// ============================================
// エッジベース矢印描画（v1.1.0新機能）
// ============================================

/**
 * エッジベースで条件分岐の矢印を描画
 * @param {CanvasRenderingContext2D} ctx - Canvasコンテキスト
 * @param {number} layer - レイヤー番号
 * @param {HTMLElement[]} nodes - DOMノード配列
 */
function drawEdgeBasedConditionArrows(ctx, layer, nodes) {
    const edges = layerStructure[layer]?.edges || [];
    if (edges.length === 0) {
        console.log(`[エッジ描画] レイヤー${layer}: エッジなし`);
        return false;  // エッジがない場合は旧方式にフォールバック
    }

    console.log(`[エッジ描画] レイヤー${layer}: ${edges.length}本のエッジを処理`);

    // 条件分岐用エッジのみ処理
    const conditionEdges = edges.filter(e => e.type === 'true' || e.type === 'false');

    conditionEdges.forEach(edge => {
        // ソースとターゲットのDOMノードを取得
        const sourceNode = nodes.find(n => n.dataset.nodeId === edge.source);
        const targetNode = nodes.find(n => n.dataset.nodeId === edge.target);

        if (!sourceNode || !targetNode) {
            console.warn(`[エッジ描画] ノード未発見: source=${edge.source}, target=${edge.target}`);
            return;
        }

        // 座標を取得
        const sourceTop = parseInt(sourceNode.style.top, 10) || 0;
        const sourceLeft = parseInt(sourceNode.style.left, 10) || 90;
        const sourceHeight = sourceNode.offsetHeight || NODE_HEIGHT;
        const sourceWidth = sourceNode.offsetWidth || 120;

        const targetTop = parseInt(targetNode.style.top, 10) || 0;
        const targetLeft = parseInt(targetNode.style.left, 10) || 90;
        const targetHeight = targetNode.offsetHeight || NODE_HEIGHT;
        const targetWidth = targetNode.offsetWidth || 120;

        // エッジタイプに応じた色を設定
        const edgeColor = edge.type === 'true' ? '#1e90ff' : 'rgb(250, 128, 114)';
        ctx.strokeStyle = edgeColor;
        ctx.lineWidth = 2;

        if (edge.type === 'true') {
            // True分岐: 開始ノード右端 → 右へ横線 → 下へ縦線 → 終了ノード右端
            const lineStartX = sourceLeft + sourceWidth;
            const lineStartY = sourceTop + sourceHeight / 2;
            const horizontalEndX = lineStartX + 30;  // 右へ30px
            const targetY = targetTop + targetHeight / 2;

            // 右への横線
            ctx.beginPath();
            ctx.moveTo(lineStartX, lineStartY);
            ctx.lineTo(horizontalEndX, lineStartY);
            ctx.stroke();

            // 下への縦線
            ctx.beginPath();
            ctx.moveTo(horizontalEndX, lineStartY);
            ctx.lineTo(horizontalEndX, targetY);
            ctx.stroke();

            // 終了ノードへの横線
            const targetRightX = targetLeft + targetWidth;
            ctx.beginPath();
            ctx.moveTo(horizontalEndX, targetY);
            ctx.lineTo(targetRightX, targetY);
            ctx.stroke();

            // ラベル描画
            ctx.fillStyle = edgeColor;
            ctx.font = '12px sans-serif';
            ctx.fillText('True', horizontalEndX + 5, lineStartY - 5);

        } else {
            // False分岐: 開始ノード左端 → 左へ横線 → 下へ縦線 → 終了ノード左端
            const lineStartX = sourceLeft;
            const lineStartY = sourceTop + sourceHeight / 2;
            const horizontalEndX = Math.max(lineStartX - 30, 10);  // 左へ30px
            const targetY = targetTop + targetHeight / 2;

            // 左への横線
            ctx.beginPath();
            ctx.moveTo(lineStartX, lineStartY);
            ctx.lineTo(horizontalEndX, lineStartY);
            ctx.stroke();

            // 下への縦線
            ctx.beginPath();
            ctx.moveTo(horizontalEndX, lineStartY);
            ctx.lineTo(horizontalEndX, targetY);
            ctx.stroke();

            // 終了ノードへの横線と矢印
            ctx.beginPath();
            ctx.moveTo(horizontalEndX, targetY);
            ctx.lineTo(targetLeft, targetY);
            ctx.stroke();

            // 矢印ヘッド
            drawArrowHead(ctx, horizontalEndX, targetY, targetLeft, targetY);

            // ラベル描画
            ctx.fillStyle = edgeColor;
            ctx.font = '12px sans-serif';
            ctx.fillText('False', horizontalEndX - 30, lineStartY - 5);
        }

        console.log(`[エッジ描画] ${edge.type}分岐: ${edge.source} → ${edge.target}`);
    });

    return conditionEdges.length > 0;  // エッジを描画した場合true
}

/**
 * レイヤーにエッジベースの条件分岐があるかチェック
 * @param {number} layer - レイヤー番号
 * @returns {boolean} エッジベースの条件分岐がある場合true
 */
function hasEdgeBasedConditions(layer) {
    const edges = layerStructure[layer]?.edges || [];
    return edges.some(e => e.type === 'true' || e.type === 'false');
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

        if (LOG_CONFIG.loopGroups) {
            console.log(`🔍 [findLoopGroups] ノード検証: text="${text}", color=${color}, isLemonChiffon=${isLemonChiffonColor(color)}, groupId=${groupId}`);
        }

        if (isLemonChiffonColor(color) && groupId) {
            if (LOG_CONFIG.loopGroups) {
                console.log(`🔍 [findLoopGroups] ✅ ループノード検出: text="${text}", groupId=${groupId}`);
            }
            if (!groupMap.has(groupId)) {
                groupMap.set(groupId, []);
            }
            groupMap.get(groupId).push(node);
        }
    });

    // 各グループで開始と終了を特定
    if (LOG_CONFIG.loopGroups) {
        console.log(`🔍 [findLoopGroups] groupMap.size=${groupMap.size}`);
    }
    groupMap.forEach((groupNodes, groupId) => {
        if (LOG_CONFIG.loopGroups) {
            console.log(`🔍 [findLoopGroups] GroupID=${groupId}, ノード数=${groupNodes.length}`);
        }
        if (groupNodes.length === 2) {
            // ★修正: getBoundingClientRect()はdisplay:noneから表示切替直後に正しい値を返さないため
            // style.topを使用（drawLoopArrowsと同じ方式）
            const sorted = groupNodes.sort((a, b) => {
                const aTop = parseInt(a.style.top, 10) || 0;
                const bTop = parseInt(b.style.top, 10) || 0;
                return aTop - bTop;
            });

            if (LOG_CONFIG.loopGroups) {
                console.log(`🔍 [findLoopGroups] ✅ ループグループ追加: ${sorted[0].textContent} → ${sorted[1].textContent}`);
            }
            groups.push({ startNode: sorted[0], endNode: sorted[1] });
        } else {
            if (LOG_CONFIG.loopGroups) {
                console.log(`🔍 [findLoopGroups] ⚠️ ノード数が2でない: ${groupNodes.length}`);
            }
        }
    });

    if (LOG_CONFIG.loopGroups) {
        console.log(`🔍 [findLoopGroups] 最終結果: ${groups.length}グループ`);
    }
    return groups;
}

// ループの矢印を描画
// loopOffset: 分岐矢印との競合を避けるための動的オフセット値
function drawLoopArrows(ctx, startNode, endNode, containerRect, scrollTop = 0, scrollLeft = 0, loopOffset = 30) {
    // ★修正: style.topを直接使用（getBoundingClientRectはビューポート依存のため不正確）
    const startTop = parseInt(startNode.style.top, 10) || 0;
    const startLeft = parseInt(startNode.style.left, 10) || 90;
    const startHeight = startNode.offsetHeight || NODE_HEIGHT;

    const endTop = parseInt(endNode.style.top, 10) || 0;
    const endLeft = parseInt(endNode.style.left, 10) || 90;
    const endHeight = endNode.offsetHeight || NODE_HEIGHT;

    // 開始ノードの左端から左に出る（動的オフセットを使用、最小10pxを確保）
    const startX = startLeft;
    const startY = startTop + startHeight / 2;
    const horizontalEndX = Math.max(startX - loopOffset, 10);

    // 終了ノードの中央Y座標
    const endY = endTop + endHeight / 2;

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
    const endStartX = endLeft;
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

// 色がActionOrange（アクション系）かどうかを判定
function isActionOrangeColor(colorString) {
    const match = colorString.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
    if (match) {
        const r = parseInt(match[1]);
        const g = parseInt(match[2]);
        const b = parseInt(match[3]);
        return r === 255 && g === 220 && b === 180;
    }
    return false;
}

// 色がReadCyan（読み込み・取得系）かどうかを判定
function isReadCyanColor(colorString) {
    const match = colorString.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
    if (match) {
        const r = parseInt(match[1]);
        const g = parseInt(match[2]);
        const b = parseInt(match[3]);
        return r === 200 && g === 230 && b === 250;
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
        // rgb(200, 220, 255) 薄い青
        const isMatch = (r === 200 && g === 220 && b === 255);
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
        // #ffb6c1 = rgb(255, 182, 193) LightPink (パステル)
        // 旧色も互換性のため残す: (252, 160, 158), (227, 206, 229), (255, 192, 203), (255, 20, 147)
        const isPink = (r === 255 && g === 182 && b === 193) ||  // LightPink #ffb6c1 (パステル)
               (r === 255 && g === 20 && b === 147) ||  // DeepPink #ff1493 (旧色)
               (r === 255 && g === 192 && b === 203) || // Standard Pink
               (r === 227 && g === 206 && b === 229) || // ピンク青色
               (r === 252 && g === 160 && b === 158);   // ピンク赤色（旧色）

        if (LOG_CONFIG.pink) {
            console.log(`[ピンク検出] 色: ${colorString}, RGB: (${r},${g},${b}), ピンク判定: ${isPink}`);
        }
        return isPink;
    }
    return false;
}

// groupIdがユーザー作成グループかどうかを判定（3000番台）
function isUserGroup(groupId) {
    if (groupId === null || groupId === undefined) return false;
    const id = parseInt(groupId);
    return id >= 3000 && id < 4000;
}

// groupIdがループグループかどうかを判定（1000番台）
function isLoopGroup(groupId) {
    if (groupId === null || groupId === undefined) return false;
    const id = parseInt(groupId);
    return id >= 1000 && id < 2000;
}

// groupIdが条件分岐グループかどうかを判定（2000番台）
function isConditionGroup(groupId) {
    if (groupId === null || groupId === undefined) return false;
    const id = parseInt(groupId);
    return id >= 2000 && id < 3000;
}

// パネル間矢印を描画（ピンクノードのスクリプト展開用）
function drawCrossPanelArrows() {
    const mainCanvas = arrowState.canvasMap.get('main');
    if (!mainCanvas) return;

    const ctx = mainCanvas.getContext('2d', { willReadFrequently: true });
    ctx.imageSmoothingEnabled = false;
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
    ctx.strokeStyle = '#ffb6c1'; // LightPink (パステル)
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

    // コントロールログ: DOMContentLoaded
    await writeControlLog('✅ [INIT] DOMContentLoaded - HTMLロード完了');

    // 矢印描画機能を初期化（arrow-drawing.jsの内容が統合されているため即座に利用可能）
    console.log('[矢印] Arrow drawing initialization...');
    initializeArrowCanvas();
    refreshAllArrows();
    window.arrowDrawing.initialized = true;
    console.log('[矢印] Arrow drawing initialized successfully');
    // console.log(`[デバッグ] Canvas数: ${window.arrowDrawing.state.canvasMap.size}`);

    // コントロールログ: 矢印描画初期化完了
    await writeControlLog('✅ [INIT] 矢印描画機能の初期化完了');

    // ドロップ位置インジケーターを作成
    createDropIndicator();

    // ウィンドウリサイズ時に矢印を再描画
    window.addEventListener('resize', resizeCanvases);

    // 画面幅チェック
    checkScreenWidth();

    // API接続テスト
    await testApiConnection();
    await writeControlLog('✅ [INIT] APIサーバー接続テスト完了');

    // 左右パネル表示を初期化
    updateDualPanelDisplay();

    // カテゴリ設定.jsonを読み込み
    await loadCategorySettings();
    await writeControlLog('✅ [INIT] カテゴリ設定の読み込み完了');

    // カテゴリボタン・パネルを動的生成
    generateCategoryUI();
    await writeControlLog('✅ [INIT] カテゴリUI動的生成完了');

    // ボタン設定.jsonを読み込み
    await loadButtonSettings();
    await writeControlLog('✅ [INIT] ボタン設定の読み込み完了');

    // カテゴリーパネルにノード追加ボタンを生成（初期は無効化）
    generateAddNodeButtons();

    // 初期カテゴリーの色を設定
    switchCategory(1);

    // イベントリスナー設定
    setupEventListeners();

    // ダイアログのイベントリスナー設定（DOM ready後）
    setupDialogEventListeners();
    await writeControlLog('✅ [INIT] イベントリスナー設定完了');

    // 変数を読み込み
    await loadVariables();
    await writeControlLog('✅ [INIT] 変数の読み込み完了');

    // フォルダ一覧を読み込み（デフォルトフォルダ自動選択）
    console.log('[初期化] フォルダ初期化を開始...');
    await loadFolders();
    console.log('[初期化] ✅ フォルダ初期化完了 - currentFolder:', currentFolder);
    await writeControlLog('✅ [INIT] フォルダ初期化完了');

    // ボタンを有効化
    enableAddNodeButtons();
    await writeControlLog('✅ [INIT] ノード追加ボタンを有効化');

    // 既存のノードを読み込み（memory.jsonから）
    // ※loadFolders()の後に実行（currentFolderが設定された後）
    await loadExistingNodes();
    await writeControlLog('✅ [INIT] 既存ノードの読み込み完了');

    // Excel接続情報を復元（変数も含む）
    await loadConnectionState();
    await writeControlLog('✅ [INIT] 接続情報の復元完了');

    console.log('═══════════════════════════════════════════════');
    console.log(`✅ UIpowershell 初期化完了 [Version: ${APP_VERSION}]`);
    console.log('═══════════════════════════════════════════════');

    // ロボットプロファイルを読み込み
    await loadRobotProfile();
    setupRobotProfileAutoSave();
    await writeControlLog('✅ [INIT] ロボットプロファイル読み込み完了');

    // コントロールログ: 初期化完了、ノード生成可能
    await writeControlLog('🎉 [READY] 初期化完了 - ノード生成可能');

    // ローディングオーバーレイを非表示
    const loadingOverlay = document.getElementById('loading-overlay');
    if (loadingOverlay) {
        loadingOverlay.classList.add('hidden');
        console.log('[初期化] ローディングオーバーレイを非表示にしました');
    }

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

            if (overflow > 0 && LOG_CONFIG.general) {
                console.log(`⚠️ [横スクロール] はみ出し +${overflow}px（推奨: コンテナ ${containerWidth - overflow - 5}px以下）`);
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
    const t0 = performance.now();
    console.log('🔍 [API Timing] /health リクエスト開始');

    try {
        const t1 = performance.now();
        const response = await fetch(`${API_BASE}/health`);
        const t2 = performance.now();
        console.log(`🔍 [API Timing] /health フェッチ完了: ${(t2-t1).toFixed(1)}ms`);

        const data = await response.json();
        const t3 = performance.now();
        console.log(`🔍 [API Timing] /health JSON解析完了: ${(t3-t2).toFixed(1)}ms`);
        console.log(`🔍 [API Timing] /health 合計: ${(t3-t0).toFixed(1)}ms`);

        console.log('API接続成功:', data);
        return true;
    } catch (error) {
        console.error('API接続失敗:', error);
        await showAlertDialog('APIサーバーに接続できません。\nadapter/api-server-v2.ps1 を起動してください。', '接続エラー');
        return false;
    }
}

async function callApi(endpoint, method = 'GET', body = null, options = {}) {
    const t0 = performance.now();
    const timeoutMs = options.timeout || 120000; // デフォルト2分
    console.log(`🔍 [API Timing] ${endpoint} リクエスト開始 (${method})`);

    const fetchOptions = {
        method: method,
        headers: { 'Content-Type': 'application/json' }
    };

    if (body) {
        fetchOptions.body = JSON.stringify(body);
    }

    // AbortControllerでタイムアウト制御
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeoutMs);
    fetchOptions.signal = controller.signal;

    try {
        const t1 = performance.now();
        const response = await fetch(`${API_BASE}${endpoint}`, fetchOptions);
        const t2 = performance.now();
        clearTimeout(timeoutId);
        console.log(`🔍 [API Timing] ${endpoint} フェッチ完了: ${(t2-t1).toFixed(1)}ms`);

        // HTTPステータスコード別のエラーハンドリング
        if (response.status === 408) {
            throw new Error('サーバータイムアウト: 処理に時間がかかりすぎました。再度お試しください。');
        }
        if (response.status === 500) {
            throw new Error('サーバー内部エラー: サーバーで問題が発生しました。ログを確認してください。');
        }
        if (response.status === 503) {
            throw new Error('サービス利用不可: サーバーが一時的に利用できません。しばらく待ってから再試行してください。');
        }

        // レスポンスボディを先にテキストとして読み取る（空レスポンス対策）
        const responseText = await response.text();

        // 空レスポンスの場合
        if (!responseText || responseText.trim() === '') {
            if (response.ok) {
                // 成功だが空の場合は空オブジェクトを返す
                return {};
            }
            throw new Error(`空のレスポンス: サーバーが応答を返しませんでした (HTTP ${response.status})`);
        }

        // JSONパース
        let data;
        try {
            data = JSON.parse(responseText);
        } catch (parseError) {
            console.error(`[API] JSONパースエラー:`, parseError);
            console.error(`[API] 受信したテキスト (先頭200文字):`, responseText.substring(0, 200));
            throw new Error('JSONパースエラー: サーバーからの応答が不正です');
        }

        const t3 = performance.now();
        console.log(`🔍 [API Timing] ${endpoint} JSON解析完了: ${(t3-t2).toFixed(1)}ms`);
        console.log(`🔍 [API Timing] ${endpoint} 合計: ${(t3-t0).toFixed(1)}ms`);

        // response.okでない場合はエラー情報を含めて返す
        if (!response.ok) {
            data._httpStatus = response.status;
            data._httpStatusText = response.statusText;
        }

        return data;
    } catch (error) {
        clearTimeout(timeoutId);

        // AbortErrorの場合はタイムアウト
        if (error.name === 'AbortError') {
            throw new Error(`クライアントタイムアウト: ${timeoutMs / 1000}秒を超えました`);
        }

        // ネットワークエラーの場合
        if (error.name === 'TypeError' && error.message.includes('fetch')) {
            throw new Error('ネットワークエラー: サーバーに接続できません。サーバーが起動しているか確認してください。');
        }

        throw error;
    }
}

// ============================================
// ボタン設定.json読み込み
// ============================================

async function loadButtonSettings() {
    const t0 = performance.now();
    try {
        console.log('[ボタン設定] ロード開始...');
        console.log('🔍 [API Timing] /button-settings.json リクエスト開始');

        // APIサーバー経由でボタン設定.jsonを読み込み
        // 注: 日本語URLのエンコード問題を避けるため、英語エイリアスを使用
        const t1 = performance.now();
        const response = await fetch('/button-settings.json');
        const t2 = performance.now();
        console.log(`🔍 [API Timing] /button-settings.json フェッチ完了: ${(t2-t1).toFixed(1)}ms`);

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        buttonSettings = await response.json();
        const t3 = performance.now();
        console.log(`🔍 [API Timing] /button-settings.json JSON解析完了: ${(t3-t2).toFixed(1)}ms`);
        console.log(`🔍 [API Timing] /button-settings.json 合計: ${(t3-t0).toFixed(1)}ms`);

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
// カテゴリ設定.json読み込み
// ============================================

async function loadCategorySettings() {
    try {
        console.log('[カテゴリ設定] ロード開始...');

        const response = await fetch('/category-settings.json');
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        categorySettings = await response.json();
        console.log('[カテゴリ設定] ✅ ロード完了:', categorySettings.length, '個');
    } catch (error) {
        console.error('[カテゴリ設定] ❌ ロード失敗:', error);
        categorySettings = [];
    }
}

// ============================================
// カテゴリボタン・パネルを動的生成
// ============================================

function generateCategoryUI() {
    console.log('[カテゴリUI] 動的生成開始...');

    const categoryButtonsContainer = document.getElementById('category-buttons');
    const nodePanelsContainer = document.getElementById('node-buttons-container');

    if (!categoryButtonsContainer || !nodePanelsContainer) {
        console.error('[カテゴリUI] コンテナが見つかりません');
        return;
    }

    // 既存のコンテンツをクリア
    categoryButtonsContainer.innerHTML = '';
    nodePanelsContainer.innerHTML = '';

    // カテゴリ設定からUI生成
    categorySettings.forEach((category, index) => {
        // カテゴリボタンを作成
        const btn = document.createElement('button');
        btn.className = 'category-btn' + (index === 0 ? ' active' : '');
        btn.textContent = category.名前;
        btn.dataset.category = category.番号;
        btn.dataset.color = category.色;
        btn.style.backgroundColor = category.色;
        btn.onclick = () => switchCategory(category.番号);

        // マウスオーバーで説明表示
        btn.onmouseenter = () => {
            document.getElementById('description-text').textContent = category.説明 || 'カテゴリの説明';
        };
        btn.onmouseleave = () => {
            document.getElementById('description-text').textContent = 'ノードやカテゴリにマウスを乗せると説明が表示されます。';
        };

        categoryButtonsContainer.appendChild(btn);

        // カテゴリパネルを作成
        const panel = document.createElement('div');
        panel.id = `category-panel-${category.番号}`;
        panel.className = 'category-panel' + (index === 0 ? ' active' : '');
        nodePanelsContainer.appendChild(panel);
    });

    console.log('[カテゴリUI] ✅ 動的生成完了:', categorySettings.length, '個のカテゴリ');
}

// ============================================
// カテゴリーパネルにノード追加ボタンを生成
// ============================================

function generateAddNodeButtons() {
    console.log('[ボタン生成] 開始 - buttonSettings:', buttonSettings.length, '個');

    // カテゴリ設定から動的にpanelMappingを構築
    const panelMapping = {};
    categorySettings.forEach(cat => {
        panelMapping[cat.番号] = `category-panel-${cat.番号}`;
    });

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
        btn.title = setting.テキスト;  // ツールチップでフルテキスト表示
        btn.style.backgroundColor = getColorCode(setting.背景色);
        btn.dataset.setting = JSON.stringify(setting);
        btn.disabled = true;  // 初期化完了まで無効化

        btn.onclick = async () => {
            // 二重クリック防止: 処理中は無視
            if (btn.disabled || btn.dataset.processing === 'true') {
                console.log('[ボタンクリック] ⚠ 処理中のため無視しました');
                return;
            }

            // 処理中フラグを設定
            btn.dataset.processing = 'true';
            btn.style.opacity = '0.6';
            btn.style.cursor = 'wait';

            console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            console.log('[ボタンクリック] ✅ ボタンがクリックされました');
            console.log('[ボタンクリック] テキスト:', setting.テキスト);
            console.log('[ボタンクリック] 処理番号:', setting.処理番号);
            console.log('[ボタンクリック] 関数名:', setting.関数名);
            console.log('[ボタンクリック] 背景色:', setting.背景色);
            console.log('[ボタンクリック] setting全体:', setting);
            console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

            try {
                // ============================================
                // 🔄 移行完了: 条件分岐・ループビルダーはPowerShell Windows Forms版に統一
                // ============================================
                // 以前はWeb UIダイアログを表示していましたが、現在は全てのボタンで
                // API経由で00_code/*.ps1を呼び出す統一処理に変更されました。
                //
                // - 1-2.ps1 (条件分岐): ShowConditionBuilder をPowerShell Windows Forms で表示
                // - 1-3.ps1 (ループ): ShowLoopBuilder をPowerShell Windows Forms で表示
                // - その他のボタンも同様にAPI経由で処理
                //
                // メリット:
                // - コードの一貫性が向上（全てのパラメータ入力UIがPowerShell Windows Forms）
                // - JavaScript約900行削除による保守性向上
                // - 変数管理システムとの深い統合
                // ============================================

                // 全てのボタンで統一的にノード追加処理
                // ※ 条件分岐(1-2)の場合、PowerShellダイアログで分岐数も選択される
                await addNodeToLayer(setting);

            } catch (error) {
                console.error('[ボタンクリック] ❌ エラーが発生しました:', error);
                console.error('[ボタンクリック] スタックトレース:', error.stack);
            } finally {
                // 処理完了: ボタンを再有効化
                btn.dataset.processing = 'false';
                btn.style.opacity = '1';
                btn.style.cursor = 'pointer';
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
        'Pink': '#ffb6c1',                       // LightPink (パステル)
        'Salmon': 'rgb(250, 128, 114)',          // 条件分岐 False分岐（赤）
        'LightBlue': 'rgb(200, 220, 255)',       // 条件分岐 True分岐（青）薄い青
        'Gray': 'rgb(128, 128, 128)',            // 条件分岐 中間ライン
        'Aquamarine': 'rgb(127, 255, 212)',      // 関数ノード（水色）
        'ActionOrange': 'rgb(255, 220, 180)',    // アクション系（外部変更）
        'ReadCyan': 'rgb(200, 230, 250)',        // 読み込み・取得系
        'LightCyan': 'rgb(200, 230, 250)',       // 読み込み・取得系（互換）
        'LightGreen': 'rgb(144, 238, 144)'       // 行ループ
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

    // カテゴリーボタンの選択状態を更新
    const categoryBtns = document.querySelectorAll('.category-btn');
    categoryBtns.forEach(btn => {
        btn.classList.remove('active');
    });
    const selectedBtn = document.querySelector(`.category-btn[data-category="${categoryNum}"]`);
    if (selectedBtn) {
        selectedBtn.classList.add('active');
        // ノード追加ボタンパネルの背景色を選択されたカテゴリーの色に変更
        const categoryColor = selectedBtn.dataset.color;
        const container = document.getElementById('node-buttons-container');
        if (container && categoryColor) {
            container.style.backgroundColor = categoryColor;
        }
    }
}

// ============================================
// ノード追加
// ============================================

// 親ピンクノードのスクリプトを更新する関数（完全再構築方式）
async function updateParentPinkNode(addedNodes, deletedNodes = []) {
    console.log('[親ピンクノード更新] ========== 開始（完全再構築方式） ==========');
    console.log('[親ピンクノード更新] 現在のレイヤー:', leftVisibleLayer);

    // レイヤー1の場合は親がいないのでスキップ
    if (leftVisibleLayer < 2) {
        console.log('[親ピンクノード更新] レイヤー1なので親ピンクノードなし');
        return;
    }

    const parentLayer = leftVisibleLayer - 1;
    console.log('[親ピンクノード更新] 親レイヤー:', parentLayer);

    const parentPinkNodeId = pinkSelectionArray[parentLayer].expandedNode;
    console.log('[親ピンクノード更新] 親ピンクノードID:', parentPinkNodeId);

    if (!parentPinkNodeId) {
        console.warn('[親ピンクノード更新] ⚠ 親ピンクノードIDが見つかりません');
        return;
    }

    // 親ピンクノードを取得
    const parentPinkNode = layerStructure[parentLayer].nodes.find(n => n.id === parentPinkNodeId);

    if (!parentPinkNode) {
        console.error('[親ピンクノード更新] ❌ 親ピンクノードが見つかりません: ID=', parentPinkNodeId);
        return;
    }

    console.log('[親ピンクノード更新] ✅ 親ピンクノード取得成功:', `${parentPinkNode.id}(${parentPinkNode.text})`);
    console.log('[親ピンクノード更新] 親ピンクノードの現在のscript:', parentPinkNode.script);

    // ★★★ 新方式: 現在のレイヤーから完全再構築 ★★★
    console.log('[親ピンクノード更新] ========== 現在のレイヤーから完全再構築 ==========');

    // 現在のレイヤーのすべてのノードをY座標でソート
    const currentLayerNodes = [...layerStructure[leftVisibleLayer].nodes].sort((a, b) => a.y - b.y);
    console.log('[親ピンクノード更新] 現在のレイヤーのノード数:', currentLayerNodes.length);
    console.log('[親ピンクノード更新] ノード一覧:', currentLayerNodes.map(n => `${n.id}(${n.text})`).join(', '));

    // 🔍 各ノードの詳細情報をログ出力
    console.log('[親ピンクノード更新] 🔍 各ノードの詳細:');
    currentLayerNodes.forEach((node, idx) => {
        console.log(`  [${idx}] ID=${node.id}, text="${node.text}", color=${node.color}`);
        console.log(`       scriptフィールド: ${node.script ? node.script.substring(0, 100) : '(なし)'}`);
        // code.jsonエントリも確認
        const codeEntry = codeData["エントリ"] ? codeData["エントリ"][`${node.id}-1`] : null;
        console.log(`       code.jsonエントリ[${node.id}-1]: ${codeEntry ? codeEntry.substring(0, 100) : '(なし)'}`);
    });

    // 全ノードからscriptを再構築（Pinkノードのscriptは含めない）
    const newScript = currentLayerNodes.map(node =>
        `${node.id};${node.color};${node.text};`
    ).join('_');

    console.log('[親ピンクノード更新] 🔍 再構築後のscript:', newScript);
    console.log('[親ピンクノード更新] ⚠️ 注意: このscriptにはメタ情報のみで、実際のコード内容は含まれていません');

    // 親ピンクノードのscriptを更新
    console.log('[親ピンクノード更新] ========== 親ピンクノードscript更新 ==========');
    console.log('[親ピンクノード更新] 更新前の親ピンクノードscript:', parentPinkNode.script);
    parentPinkNode.script = newScript;
    console.log('[親ピンクノード更新] 更新後の親ピンクノードscript:', parentPinkNode.script);

    // グローバルnodesも更新
    const globalNode = nodes.find(n => n.id === parentPinkNodeId);
    if (globalNode) {
        console.log('[親ピンクノード更新] グローバルnodesも更新します');
        globalNode.script = parentPinkNode.script;
    }

    // コード.jsonに保存（"AAAA\n"プレフィックス付き、改行区切り）
    const formattedEntryString = 'AAAA\n' + parentPinkNode.script.replace(/_/g, '\n');
    console.log('[親ピンクノード更新] ========== code.json保存 ==========');
    console.log('[親ピンクノード更新] 保存するノードID:', parentPinkNodeId);
    console.log('[親ピンクノード更新] フォーマット後のエントリ:', formattedEntryString);
    console.log('[親ピンクノード更新] 🔍 code.jsonに保存される内容にはPowerShellコードが含まれていません');
    console.log('[親ピンクノード更新] 🔍 子ノードの実際のコードは各ノードIDのエントリに保存されています');

    try {
        await setCodeEntry(parentPinkNodeId, formattedEntryString);
        console.log('[親ピンクノード更新] ✅ コード.json保存成功 - ノードID:', parentPinkNodeId);

        // 🔍 保存後のcode.jsonエントリを確認
        const savedEntry = codeData["エントリ"] ? codeData["エントリ"][`${parentPinkNodeId}-1`] : null;
        console.log('[親ピンクノード更新] 🔍 保存後のcode.jsonエントリ確認:');
        console.log(`  code.json["エントリ"]["${parentPinkNodeId}-1"]:`, savedEntry);
    } catch (error) {
        console.error('[親ピンクノード更新] ❌ コード.json保存エラー:', error);
        await showAlertDialog('親ピンクノードの更新に失敗しました。コンソールを確認してください。', '保存エラー');
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
        // 条件分岐：多重分岐対応（開始・中間×N・終了）
        // branchCountはPowerShellダイアログで選択される
        console.log(`[addNodeToLayer] 条件分岐セット追加を開始`);
        addedNodes = await addConditionSet(setting);
        if (addedNodes === null) {
            console.log('[addNodeToLayer] 条件分岐セット追加がキャンセルされました');
            return;
        }
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
                // キャンセルされた場合：作成済みのノードを削除
                console.warn('[addNodeToLayer] ⚠ コード生成がキャンセルされました - ノードを削除します');

                // nodes配列から削除
                const nodeIndex = nodes.findIndex(n => n.id === node.id);
                if (nodeIndex !== -1) {
                    nodes.splice(nodeIndex, 1);
                }

                // layerStructureから削除
                const layerIndex = layerStructure[leftVisibleLayer].nodes.findIndex(n => n.id === node.id);
                if (layerIndex !== -1) {
                    layerStructure[leftVisibleLayer].nodes.splice(layerIndex, 1);
                }

                console.log('[addNodeToLayer] ノード削除完了 - 処理を中止します');
                return;
            }
        } catch (error) {
            console.error('[addNodeToLayer] ❌ generateCode() でエラーが発生しました:', error);
            console.error('[addNodeToLayer] スタックトレース:', error.stack);

            // エラー時もノードを削除
            const nodeIndex = nodes.findIndex(n => n.id === node.id);
            if (nodeIndex !== -1) {
                nodes.splice(nodeIndex, 1);
            }
            const layerIndex = layerStructure[leftVisibleLayer].nodes.findIndex(n => n.id === node.id);
            if (layerIndex !== -1) {
                layerStructure[leftVisibleLayer].nodes.splice(layerIndex, 1);
            }
            return;
        }

        // ★修正：画面を再描画（矢印も更新される）
        console.log('[addNodeToLayer] renderNodesInLayer() を呼び出します');
        renderNodesInLayer(leftVisibleLayer);
        reorderNodesInLayer(leftVisibleLayer);
        console.log('[addNodeToLayer] 通常ノード追加が完了');
    }

    // ★ 同じレイヤーのピンクノード展開状態を無効化（レイヤー編集により既存の展開状態は無効）
    if (pinkSelectionArray[leftVisibleLayer].expandedNode !== null) {
        console.log(`[addNodeToLayer] ⚠️ レイヤー${leftVisibleLayer}のピンクノード展開状態を無効化します（ノード追加によりレイヤーが変更されたため）`);
        console.log(`[addNodeToLayer] 無効化前: expandedNode=${pinkSelectionArray[leftVisibleLayer].expandedNode}, value=${pinkSelectionArray[leftVisibleLayer].value}`);
        pinkSelectionArray[leftVisibleLayer].value = 0;
        pinkSelectionArray[leftVisibleLayer].expandedNode = null;
        pinkSelectionArray[leftVisibleLayer].yCoord = 0;
        pinkSelectionArray[leftVisibleLayer].initialY = 0;
        console.log(`[addNodeToLayer] ✅ 無効化完了`);
    }

    // ★ ドリルダウンパネルが編集されたレイヤーの子レイヤーを表示している場合は閉じる
    if (drilldownState.active && drilldownState.targetLayer === leftVisibleLayer + 1) {
        console.log(`[addNodeToLayer] ⚠️ ドリルダウンパネルを閉じます（編集中のレイヤー${leftVisibleLayer}の子レイヤーを表示中のため）`);
        closeDrilldownPanel();
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
function addSingleNode(setting, customText = null, customY = null, customGroupId = null, customHeight = NODE_HEIGHT, customNodeId = null) {
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
        baseY + NODE_SPACING,
        groupId,
        NODE_HEIGHT,
        `${baseId}-2`  // カスタムID指定
    );

    console.log(`[ループ作成完了] startNode.id: ${startNode.id}, endNode.id: ${endNode.id} (GroupID=${groupId}, ベースID=${baseId})`);

    renderNodesInLayer(leftVisibleLayer);
    reorderNodesInLayer(leftVisibleLayer);

    // 追加されたノードを返す
    return [startNode, endNode];
}

// 条件分岐セット（多重分岐対応）を追加
// PowerShellダイアログで分岐数と条件を同時に設定
// Grayノード（中間ライン）でTrue/Else-if/False分岐を視覚的に分離
async function addConditionSet(setting) {
    const groupId = conditionGroupCounter++;
    const baseY = getNextAvailableY(leftVisibleLayer);

    // ベースIDを取得してカウンタをインクリメント
    const baseId = nodeCounter;
    nodeCounter++;

    console.log(`[条件分岐作成] GroupID=${groupId}, ベースID=${baseId}`);

    // コード生成（条件式）を先に呼び出してbranchCountを取得
    // PowerShellダイアログがJSON形式で返す: {"branchCount": N, "code": "..."}
    console.log(`[条件分岐作成] コード生成ダイアログを表示 - ベースID: ${baseId}`);
    const result = await generateCode(setting.処理番号, `${baseId}`);

    // キャンセル時はnullが返る
    if (result === null) {
        console.log(`[条件分岐作成] キャンセルされました`);
        nodeCounter--;  // カウンタを戻す
        return null;
    }

    // JSONレスポンスをパースしてbranchCountを取得
    let branchCount = 2;  // デフォルト
    try {
        // resultがJSON文字列の場合パースする
        if (typeof result === 'string' && result.startsWith('{')) {
            const parsed = JSON.parse(result);
            branchCount = parsed.branchCount || 2;
            console.log(`[条件分岐作成] JSONからbranchCount取得: ${branchCount}`);
        }
    } catch (e) {
        console.log(`[条件分岐作成] JSONパース失敗、デフォルトbranchCount=2を使用: ${e.message}`);
    }

    // 分岐数を検証（最小2、最大10）
    branchCount = Math.max(2, Math.min(10, branchCount));
    const grayNodeCount = branchCount - 1;  // Grayノード数 = 分岐数 - 1

    console.log(`[条件分岐作成] 分岐数=${branchCount}, Grayノード数=${grayNodeCount}`);

    const allNodes = [];

    // 1. 開始ボタン（緑）
    const startNode = addSingleNode(
        { ...setting, テキスト: '条件分岐 開始', ボタン名: `${baseId}-1` },
        '条件分岐 開始',
        baseY,
        groupId,
        40,
        `${baseId}-1`  // カスタムID指定
    );
    startNode.branchCount = branchCount;  // 分岐数をノードに保存
    allNodes.push(startNode);

    // 2. 中間ライン（グレー、高さ1px）- 分岐の境界
    // branchCount=2: Gray1個（False/True境界）
    // branchCount=3: Gray2個（False/ElseIf1/True境界）
    // branchCount=N: Gray(N-1)個
    for (let i = 0; i < grayNodeCount; i++) {
        const branchLabel = getBranchLabel(i, grayNodeCount);
        const middleNode = addSingleNode(
            { ...setting, テキスト: `条件分岐 ${branchLabel}`, 背景色: 'Gray', ボタン名: `${baseId}-${i + 2}` },
            `条件分岐 ${branchLabel}`,
            baseY + NODE_SPACING * (i + 1) - 5,  // 5px上に調整
            groupId,
            1,  // 高さ1px
            `${baseId}-${i + 2}`  // カスタムID指定
        );
        middleNode.branchIndex = i;  // 何番目のGrayか
        allNodes.push(middleNode);
    }

    // 3. 終了ボタン（緑）
    const endNode = addSingleNode(
        { ...setting, テキスト: '条件分岐 終了', ボタン名: `${baseId}-${grayNodeCount + 2}` },
        '条件分岐 終了',
        baseY + NODE_SPACING * (grayNodeCount + 1),
        groupId,
        NODE_HEIGHT,
        `${baseId}-${grayNodeCount + 2}`  // カスタムID指定
    );
    allNodes.push(endNode);

    console.log(`[条件分岐作成完了] ノード数=${allNodes.length}, 開始:${startNode.id}, 終了:${endNode.id} (GroupID=${groupId})`);

    renderNodesInLayer(leftVisibleLayer);
    reorderNodesInLayer(leftVisibleLayer);

    // 追加されたノードを返す
    return allNodes;
}

// 分岐ラベルを取得（多重分岐用）
function getBranchLabel(grayIndex, totalGrays) {
    if (totalGrays === 1) {
        return '中間';  // 従来の2分岐
    }
    // 多重分岐の場合
    // Gray0 = False/ElseIf1境界
    // Gray1 = ElseIf1/ElseIf2境界 or ElseIf1/True境界
    // ...
    if (grayIndex === 0) {
        return 'False境界';
    } else if (grayIndex === totalGrays - 1) {
        return 'True境界';
    } else {
        return `ElseIf${grayIndex}境界`;
    }
}

// 次の利用可能なY座標を取得
function getNextAvailableY(layer) {
    const layerNodes = layerStructure[layer].nodes;
    if (layerNodes.length === 0) return 10;

    const maxY = Math.max(...layerNodes.map(n => n.y));
    return maxY + NODE_HEIGHT + 5; // ボタン高さ + マージン5px
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

    // レイヤーラベルを更新（ツールバーが存在する場合のみ）
    const layerLabel = document.getElementById('current-layer-label');
    if (layerLabel) {
        layerLabel.textContent = `レイヤー${leftVisibleLayer} / レイヤー${rightVisibleLayer}`;
    }

    // ナビゲーションボタンの状態を更新（ボタンが存在する場合のみ）
    updateNavigationButtons();
}

// ============================================
// レイヤー内のノードを描画
// ============================================

function renderNodesInLayer(layer, panelSide = 'left') {
    // 左パネルまたは右パネルのコンテナを取得
    let container;

    if (panelSide === 'right') {
        // 右パネル（ドリルダウンパネル）
        const rightPanel = document.getElementById('right-layer-panel');
        if (!rightPanel) {
            console.warn(`[レンダリング] 右パネルが見つかりません`);
            return;
        }

        // ノードがない場合は右パネルを空状態にする
        if (!layerStructure[layer] || layerStructure[layer].nodes.length === 0) {
            console.log(`[レンダリング] レイヤー${layer}にノードがないため、右パネルを空状態にします`);
            rightPanel.classList.add('empty');
            rightPanel.innerHTML = '';
            return;
        }

        // emptyクラスを削除
        rightPanel.classList.remove('empty');

        // コンテンツをクリアしてコンテナを作成
        rightPanel.innerHTML = `
            <div class="layer-label">レイヤー${layer}</div>
            <div class="node-list-container"></div>
        `;

        container = rightPanel.querySelector('.node-list-container');
    } else {
        // 左パネル対応: コンテナを取得
        const layerId = `layer-${layer}`;
        container = document.querySelector(`#${layerId} .node-list-container`);
        if (!container) {
            console.warn(`[レンダリング] コンテナが見つかりません: ${layerId}`);
            return;
        }
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

        // ユーザーグループIDを設定
        if (node.userGroupId !== null && node.userGroupId !== undefined) {
            btn.dataset.userGroupId = node.userGroupId;
            btn.classList.add('user-grouped');

            // グループ情報を取得して色を設定
            const groupInfo = userGroups[node.userGroupId];
            if (groupInfo) {
                // グループ名をツールチップに追加
                btn.title = `[${groupInfo.name}] ${node.text}`;

                // 折りたたみ状態かチェック
                if (groupInfo.collapsed) {
                    // 折りたたみ中は最初のノードのみ表示（グループ代表）
                    const groupNodes = layerNodes.filter(n => n.userGroupId === node.userGroupId);
                    const firstNode = groupNodes.sort((a, b) => a.y - b.y)[0];
                    if (node.id !== firstNode.id) {
                        btn.style.display = 'none';  // 非表示
                    } else {
                        // 代表ノードはグループ名を表示
                        btn.textContent = `📁 ${groupInfo.name} (${groupNodes.length}個)`;
                        btn.classList.add('group-collapsed');
                    }
                }
            }
        }

        console.log(`[デバッグ] ノード配置: x=${node.x || 90}px, y=${node.y}px, text="${node.text}", groupId=${node.groupId || 'なし'}, userGroupId=${node.userGroupId || 'なし'}`);

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
                console.log(`[クリック検出] ノード「${node.text}」(color:${node.color}) がクリックされました。Shift:${e.shiftKey}`);
                if (e.shiftKey) {
                    // Shift+クリック: 赤枠トグル
                    e.preventDefault();
                    e.stopPropagation();
                    handleShiftClick(node);
                } else {
                    // 通常クリック: ピンクノードまたは関数ノードの場合は展開処理
                    console.log(`[クリック判定] node.color === 'Pink' ? ${node.color === 'Pink'}, node.color === 'Aquamarine' ? ${node.color === 'Aquamarine'}`);
                    if (node.color === 'Pink') {
                        e.preventDefault();
                        e.stopPropagation();
                        console.log(`[ピンクノード検出] handlePinkNodeClick を呼び出します`);
                        handlePinkNodeClick(node);
                    } else if (node.color === 'Aquamarine' || isAquamarineColor(node.color)) {
                        // 関数ノード（水色）の場合は展開処理
                        e.preventDefault();
                        e.stopPropagation();
                        console.log(`[関数ノード検出] expandFunctionNode を呼び出します`);
                        expandFunctionNode(node);
                    } else {
                        // Pinkノード・関数ノード以外がクリックされたらドリルダウンパネルを閉じる
                        if (drilldownState.active) {
                            console.log(`[クリック] 非Pinkノードクリック → ドリルダウンパネルを閉じます`);
                            closeDrilldownPanel();
                        }
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

    // ノード数が多い場合にコンテナの高さを動的に調整
    if (layerNodes.length > 0) {
        const maxY = Math.max(...layerNodes.map(n => n.y)) + (NODE_HEIGHT * 2); // ノード高さ + 余白
        container.style.minHeight = `${Math.max(700, maxY)}px`;
        console.log(`[レンダリング] コンテナ高さを調整: ${Math.max(700, maxY)}px (最大Y座標: ${maxY - 80}px)`);
    }

    // ボード（コンテナ空白部分）の右クリックメニューを設定
    container.removeEventListener('contextmenu', handleBoardContextMenu);  // 重複防止
    container.addEventListener('contextmenu', handleBoardContextMenu);

    // ボード（コンテナ空白部分）のクリックでドリルダウンパネルを閉じる
    container.removeEventListener('click', handleBoardClick);  // 重複防止
    container.addEventListener('click', handleBoardClick);

    // グローエフェクトはapplyGlowEffects()で一括適用

    // ユーザーグループのオーバーレイ背景を描画
    renderGroupOverlays(container, layerNodes);

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

// ボードの右クリックイベントハンドラ
function handleBoardContextMenu(e) {
    // ノードボタン上でのクリックは無視（ノード用メニューが表示される）
    if (e.target.closest('.node-button')) {
        return;
    }
    // ボード用メニューを表示
    showBoardContextMenu(e);
}

// ボードのクリックイベントハンドラ（左クリック）
function handleBoardClick(e) {
    // ノードボタン上でのクリックは無視
    if (e.target.closest('.node-button')) {
        return;
    }
    // ボード（空白部分）がクリックされたらドリルダウンパネルを閉じる
    if (drilldownState.active) {
        console.log(`[ボードクリック] 背景クリック → ドリルダウンパネルを閉じます`);
        closeDrilldownPanel();
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

    // ドロップインジケーターを非表示
    hideDropIndicator();
}

// ============================================
// ドロップ位置インジケーター
// ============================================

/**
 * ドロップ位置インジケーター要素を作成
 */
function createDropIndicator() {
    dropIndicator = document.createElement('div');
    dropIndicator.id = 'drop-indicator';
    dropIndicator.style.cssText = `
        position: absolute;
        left: 10px;
        right: 10px;
        height: 3px;
        background: linear-gradient(90deg, #1e90ff, #00bfff, #1e90ff);
        border-radius: 2px;
        box-shadow: 0 0 8px rgba(30, 144, 255, 0.8);
        pointer-events: none;
        display: none;
        z-index: 1000;
        transition: top 0.1s ease-out;
    `;
    document.body.appendChild(dropIndicator);
    console.log('[ドロップインジケーター] 初期化完了');
}

/**
 * ドロップ位置インジケーターを表示・更新
 */
function showDropIndicator(container, mouseY) {
    if (!dropIndicator || !container) return;

    const containerRect = container.getBoundingClientRect();
    const relativeY = mouseY - containerRect.top + container.scrollTop;

    // 現在のレイヤーのノードを取得（Y座標でソート）
    const layerNodes = [...layerStructure[leftVisibleLayer].nodes].sort((a, b) => a.y - b.y);

    if (layerNodes.length === 0) {
        // ノードがない場合は最上部に表示
        dropIndicator.style.top = `${containerRect.top + 10}px`;
        dropIndicator.style.left = `${containerRect.left + 10}px`;
        dropIndicator.style.width = `${containerRect.width - 20}px`;
        dropIndicator.style.display = 'block';
        return;
    }

    // マウス位置に最も近いノード間の位置を計算
    let indicatorY = 10;  // デフォルトは最上部

    for (let i = 0; i < layerNodes.length; i++) {
        const node = layerNodes[i];
        const nodeHeight = node.color === 'Gray' ? 1 : NODE_HEIGHT;
        const nodeBottom = node.y + nodeHeight;

        if (relativeY < node.y) {
            // このノードの上に挿入
            indicatorY = node.y - 5;
            break;
        } else if (i === layerNodes.length - 1) {
            // 最後のノードの下に挿入
            indicatorY = nodeBottom + 10;
        } else {
            // 次のノードとの間をチェック
            const nextNode = layerNodes[i + 1];
            if (relativeY < nextNode.y) {
                // このノードと次のノードの間
                indicatorY = nodeBottom + (nextNode.y - nodeBottom) / 2;
                break;
            }
        }
    }

    // インジケーターを配置
    dropIndicator.style.top = `${containerRect.top + indicatorY - container.scrollTop}px`;
    dropIndicator.style.left = `${containerRect.left + 10}px`;
    dropIndicator.style.width = `${containerRect.width - 20}px`;
    dropIndicator.style.display = 'block';
}

/**
 * ドロップ位置インジケーターを非表示
 */
function hideDropIndicator() {
    if (dropIndicator) {
        dropIndicator.style.display = 'none';
    }
}

function handleDragOver(e) {
    if (e.preventDefault) {
        e.preventDefault();
    }

    e.dataTransfer.dropEffect = 'move';

    const target = e.target;
    if (target && target.classList) {
        if (target.classList.contains('node-button') && target !== draggedNode) {
            target.classList.add('drag-over');
            // ノード上でもインジケーターを表示
            const container = target.closest('.node-list-container');
            if (container) {
                showDropIndicator(container, e.clientY);
            }
        } else if (target.classList.contains('node-list-container')) {
            // レイヤーパネルへのドロップも許可
            target.classList.add('drag-over-container');
            // ドロップ位置インジケーターを表示
            showDropIndicator(target, e.clientY);
        }
    }

    return false;
}

async function handleDrop(e) {
    if (e.stopPropagation) {
        e.stopPropagation();
    }

    // ドロップインジケーターを非表示
    hideDropIndicator();

    const target = e.target;
    if (target && target.classList) {
        target.classList.remove('drag-over');
        target.classList.remove('drag-over-container');
    }

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
    if (target && target.classList && target.classList.contains('node-button') && target !== draggedNode) {
        const targetNodeId = target.dataset.nodeId;
        const targetNodeData = layerStructure[leftVisibleLayer].nodes.find(n => n.id === targetNodeId);

        if (!targetNodeData) {
            return false;
        }

        newY = targetNodeData.y;
    }
    // ケース2: レイヤーパネルの空きスペースへのドロップ
    else if (target && target.classList && target.classList.contains('node-list-container')) {
        // ドロップ位置のY座標を計算（中間ノードの高さを考慮）
        const rect = target.getBoundingClientRect();
        const relativeY = e.clientY - rect.top + target.scrollTop;  // スクロール位置を考慮

        // 現在のレイヤーのノードを取得（Y座標でソート、ドラッグ中のノードを除外）
        const layerNodes = [...layerStructure[leftVisibleLayer].nodes]
            .filter(n => n.id !== draggedNodeData.id)
            .sort((a, b) => a.y - b.y);

        if (layerNodes.length === 0) {
            // ノードがない場合は最上部
            newY = 10;
        } else {
            // マウス位置がどのノードの間にあるかを判定
            let insertIndex = layerNodes.length;  // デフォルトは最後

            for (let i = 0; i < layerNodes.length; i++) {
                const node = layerNodes[i];
                const nodeHeight = node.color === 'Gray' ? 1 : NODE_HEIGHT;
                const nodeBottom = node.y + nodeHeight;

                if (relativeY < node.y) {
                    // このノードの上に挿入
                    insertIndex = i;
                    break;
                } else if (i < layerNodes.length - 1) {
                    // 次のノードとの間をチェック
                    const nextNode = layerNodes[i + 1];
                    const midPoint = nodeBottom + (nextNode.y - nodeBottom) / 2;
                    if (relativeY < midPoint) {
                        // このノードの下に挿入
                        insertIndex = i + 1;
                        break;
                    }
                }
            }

            // 挿入位置に基づいてY座標を設定
            if (insertIndex === 0) {
                // 最初のノードの上
                newY = layerNodes[0].y - 1;
            } else if (insertIndex >= layerNodes.length) {
                // 最後のノードの下
                const lastNode = layerNodes[layerNodes.length - 1];
                const lastNodeHeight = lastNode.color === 'Gray' ? 1 : NODE_HEIGHT;
                newY = lastNode.y + lastNodeHeight + 1;
            } else {
                // 中間位置（前のノードの下、次のノードの上）
                const prevNode = layerNodes[insertIndex - 1];
                const nextNode = layerNodes[insertIndex];
                const prevNodeHeight = prevNode.color === 'Gray' ? 1 : NODE_HEIGHT;
                newY = prevNode.y + prevNodeHeight + (nextNode.y - (prevNode.y + prevNodeHeight)) / 2;
            }
        }

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
        await showAlertDialog('この位置には配置できません。\n同色のノードブロックと衝突します。', '配置エラー');
        return false;
    }

    // 2. グループ内順序違反チェック
    const groupOrderViolation = checkGroupOrderViolation(
        draggedNodeData,
        currentY,
        newY
    );

    if (groupOrderViolation) {
        await showAlertDialog('この位置には配置できません。\n同じグループ内のノードをまたぐことはできません。', '配置エラー');
        return false;
    }

    // 3. ネスト禁止チェック
    const nestingValidation = validateNesting(
        draggedNodeData,
        newY
    );

    if (nestingValidation.isProhibited) {
        await showAlertDialog(`この位置には配置できません。\n${nestingValidation.reason}`, '配置エラー');
        return false;
    }

    // 4. ユーザーグループ侵入禁止チェック（非グループノードがグループ内に入ることを禁止）
    if (!isUserGroup(draggedNodeData.userGroupId)) {
        const groupInvasionCheck = checkGroupInvasion(draggedNodeData, newY);
        if (groupInvasionCheck.isProhibited) {
            await showAlertDialog(`この位置には配置できません。\n${groupInvasionCheck.reason}`, '配置エラー');
            return false;
        }
    }

    // ============================
    // バリデーション通過 → 移動実行
    // ============================

    // ユーザーグループに所属している場合はグループ全体を移動
    if (isUserGroup(draggedNodeData.userGroupId)) {
        const groupId = draggedNodeData.userGroupId;
        const deltaY = newY - currentY;  // 移動オフセット

        // グループ全体の移動が可能かチェック
        const groupMoveResult = validateGroupMove(groupId, deltaY);
        if (!groupMoveResult.valid) {
            await showAlertDialog(`グループ全体を移動できません。\n${groupMoveResult.error}`, '配置エラー');
            return false;
        }

        // グループ内の全ノードを同じオフセットで移動
        const groupNodes = layerStructure[leftVisibleLayer].nodes.filter(n => n.userGroupId === groupId);
        groupNodes.forEach(node => {
            node.y += deltaY;
            // 最小値チェック
            if (node.y < 10) node.y = 10;
        });

        console.log(`[グループ移動] グループID=${groupId}, オフセット=${deltaY}, ノード数=${groupNodes.length}`);
    } else {
        // 通常のノード移動
        draggedNodeData.y = newY;
    }

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

    // 折りたたみ中のグループの非代表ノードを特定
    const collapsedHiddenNodes = new Set();
    const collapsedGroups = {};  // { groupId: representativeNodeId }

    // 折りたたみ中のグループを収集
    for (const [groupId, groupInfo] of Object.entries(userGroups)) {
        if (groupInfo.collapsed) {
            // このグループのノードを取得
            const groupNodes = layerNodes.filter(n => n.userGroupId == groupId);
            if (groupNodes.length > 0) {
                // Y座標でソートして最初のノードを代表に
                const sorted = [...groupNodes].sort((a, b) => a.y - b.y);
                collapsedGroups[groupId] = sorted[0].id;
                // 代表以外を非表示ノードとして登録
                for (let i = 1; i < sorted.length; i++) {
                    collapsedHiddenNodes.add(sorted[i].id);
                }
            }
        }
    }

    // 条件分岐グループをgroupIdごとに収集（多重分岐対応）
    const conditionGroups = {};

    for (let i = 0; i < layerNodes.length; i++) {
        const node = layerNodes[i];

        // 条件分岐ノード（SpringGreenまたはGray）かつgroupIdを持つ
        if (node.groupId && (node.color === 'SpringGreen' || node.color === 'Gray')) {
            const gid = node.groupId.toString();

            if (!conditionGroups[gid]) {
                conditionGroups[gid] = {
                    startIndex: -1,
                    middleIndices: [],  // 複数の中間ノードに対応
                    endIndex: -1
                };
            }

            if (node.text === '条件分岐 開始') {
                conditionGroups[gid].startIndex = i;
                console.log(`[色変更] 条件分岐 開始 見つかった: groupId=${gid}, index=${i}`);
            } else if (node.color === 'Gray') {
                // Grayノード（中間ノード）を配列に追加
                conditionGroups[gid].middleIndices.push(i);
                console.log(`[色変更] 条件分岐 中間(Gray) 見つかった: groupId=${gid}, index=${i}, text="${node.text}"`);
            } else if (node.text === '条件分岐 終了') {
                conditionGroups[gid].endIndex = i;
                console.log(`[色変更] 条件分岐 終了 見つかった: groupId=${gid}, index=${i}`);
            }
        }
    }

    console.log(`[色変更] 検出された条件分岐グループ数: ${Object.keys(conditionGroups).length}`);

    let currentY = 10;

    layerNodes.forEach((node, index) => {
        const buttonText = node.text;
        const beforeColor = node.color;

        // このノードがどの条件分岐グループに属するかチェック
        let inFalseBranch = false;
        let inTrueBranch = false;
        let outsideAllBranches = true;

        for (const gid in conditionGroups) {
            const group = conditionGroups[gid];
            const { startIndex, middleIndices, endIndex } = group;

            // グループが完全かチェック（中間ノードが1つ以上必要）
            if (startIndex === -1 || middleIndices.length === 0 || endIndex === -1) {
                continue;
            }

            // 多重分岐対応: middleIndicesをソートして境界を決定
            const sortedMiddles = [...middleIndices].sort((a, b) => a - b);
            const firstMiddle = sortedMiddles[0];
            const lastMiddle = sortedMiddles[sortedMiddles.length - 1];

            // 開始〜最初の中間の間: False分岐（Salmon）
            if (index > startIndex && index < firstMiddle) {
                inFalseBranch = true;
                outsideAllBranches = false;
                console.log(`[色変更] index=${index} "${node.text}" は groupId=${gid} の False分岐内`);
                break;
            }
            // 最後の中間〜終了の間: True分岐（LightBlue）
            else if (index > lastMiddle && index < endIndex) {
                inTrueBranch = true;
                outsideAllBranches = false;
                console.log(`[色変更] index=${index} "${node.text}" は groupId=${gid} の True分岐内`);
                break;
            }
            // 中間同士の間: 中間分岐（White - 今のところWhiteとする）
            else if (sortedMiddles.length > 1) {
                let inMiddleBranch = false;
                for (let m = 0; m < sortedMiddles.length - 1; m++) {
                    if (index > sortedMiddles[m] && index < sortedMiddles[m + 1]) {
                        inMiddleBranch = true;
                        outsideAllBranches = false;
                        console.log(`[色変更] index=${index} "${node.text}" は groupId=${gid} の 中間分岐${m + 1}内`);
                        break;
                    }
                }
                if (inMiddleBranch) break;
            }
            // 開始〜終了の範囲内（開始、中間、終了自体）
            if (index >= startIndex && index <= endIndex) {
                outsideAllBranches = false;
            }
        }

        // 色を設定
        if (inFalseBranch) {
            // False分岐: Salmon
            if (node.color !== 'Pink') {
                node.color = 'Salmon';
                console.log(`[色変更] index=${index} "${node.text}": ${beforeColor} → Salmon (False分岐)`);
            }
        } else if (inTrueBranch) {
            // True分岐: LightBlue
            if (node.color !== 'Pink') {
                node.color = 'LightBlue';
                console.log(`[色変更] index=${index} "${node.text}": ${beforeColor} → LightBlue (True分岐)`);
            }
        } else if (outsideAllBranches) {
            // すべての条件分岐の外側：SalmonまたはLightBlueの場合はWhiteに戻す
            if (node.color === 'Salmon' || node.color === 'LightBlue') {
                node.color = 'White';
                console.log(`[色変更] index=${index} "${node.text}": ${beforeColor} → White (外側)`);
            }
        } else {
            // 条件分岐の構成ノード（開始、中間、終了）自体
            console.log(`[色変更] index=${index} "${node.text}": ${beforeColor} のまま（構成ノード）`);
        }

        // 折りたたみ中の非表示ノードはスキップ（Y座標計算に含めない）
        if (collapsedHiddenNodes.has(node.id)) {
            // 非表示ノードは代表ノードと同じY座標に設定（見えないが位置は維持）
            // 実際の表示には影響しない
            return;
        }

        // ボタン間隔と高さの調整（Grayノード=中間ノードの場合は特殊）
        // 多重分岐対応: テキストではなく色でチェック
        let interval, height;
        if (node.color === 'Gray') {
            interval = 10;  // 通常20のところ10
            height = 0;     // 通常NODE_HEIGHTのところ0（高さ1pxだが間隔計算では0扱い）
        } else {
            interval = 20;
            height = NODE_HEIGHT;
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

    // 一旦表示してサイズを取得（非表示状態で）
    menu.style.visibility = 'hidden';
    menu.classList.add('show');

    const menuRect = menu.getBoundingClientRect();
    const viewportHeight = window.innerHeight;
    const viewportWidth = window.innerWidth;

    // X座標：右端を超える場合は左に表示
    let x = e.pageX;
    if (e.clientX + menuRect.width > viewportWidth) {
        x = e.pageX - menuRect.width;
    }

    // Y座標：下端を超える場合は上に表示
    let y = e.pageY;
    if (e.clientY + menuRect.height > viewportHeight) {
        y = e.pageY - menuRect.height;
    }

    // 位置を確定して表示
    menu.style.left = `${x}px`;
    menu.style.top = `${y}px`;
    menu.style.visibility = 'visible';

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

    // 関数化ボタンの表示/非表示を制御
    const functionizeMenuItem = document.getElementById('functionize-menu-item');
    // 赤枠ノードが1個以上ある場合に関数化ボタンを表示
    if (redBorderNodes.length >= 1) {
        functionizeMenuItem.style.display = 'block';
    } else {
        functionizeMenuItem.style.display = 'none';
    }

    // グループ化ボタンの表示/非表示を制御
    const groupizeMenuItem = document.getElementById('groupize-menu-item');
    const ungroupMenuItem = document.getElementById('ungroup-menu-item');
    const toggleGroupMenuItem = document.getElementById('toggle-group-menu-item');

    // 赤枠ノードが2個以上あり、かつユーザーグループ未所属ならグループ化ボタンを表示
    const nonGroupedRedNodes = redBorderNodes.filter(n => !isUserGroup(n.userGroupId));
    if (nonGroupedRedNodes.length >= 2) {
        groupizeMenuItem.style.display = 'block';
    } else {
        groupizeMenuItem.style.display = 'none';
    }

    // クリックしたノードがユーザーグループに所属していればグループ解除と折りたたみボタンを表示
    if (node && isUserGroup(node.userGroupId)) {
        ungroupMenuItem.style.display = 'block';
        toggleGroupMenuItem.style.display = 'block';
        // 折りたたみ状態に応じてテキストを変更
        const groupInfo = userGroups[node.userGroupId];
        if (groupInfo && groupInfo.collapsed) {
            toggleGroupMenuItem.textContent = '🔼 グループ展開';
        } else {
            toggleGroupMenuItem.textContent = '🔽 グループ折りたたみ';
        }
    } else {
        ungroupMenuItem.style.display = 'none';
        toggleGroupMenuItem.style.display = 'none';
    }

    // メニュー外クリックで閉じる
    setTimeout(() => {
        document.addEventListener('click', hideContextMenu);
    }, 100);
}

function hideContextMenu() {
    document.getElementById('context-menu').classList.remove('show');
    document.getElementById('board-context-menu').classList.remove('show');
    document.removeEventListener('click', hideContextMenu);
}

// ============================================
// ボード用右クリックメニュー
// ============================================

// ボード右クリック時のクリック位置を保存
let boardClickPosition = { x: 0, y: 0 };

// ボード用右クリックメニューを表示
function showBoardContextMenu(e) {
    e.preventDefault();

    // ノード用メニューを非表示
    document.getElementById('context-menu').classList.remove('show');

    const menu = document.getElementById('board-context-menu');

    // 一旦表示してサイズを取得（非表示状態で）
    menu.style.visibility = 'hidden';
    menu.classList.add('show');

    const menuRect = menu.getBoundingClientRect();
    const viewportHeight = window.innerHeight;
    const viewportWidth = window.innerWidth;

    // X座標：右端を超える場合は左に表示
    let x = e.pageX;
    if (e.clientX + menuRect.width > viewportWidth) {
        x = e.pageX - menuRect.width;
    }

    // Y座標：下端を超える場合は上に表示
    let y = e.pageY;
    if (e.clientY + menuRect.height > viewportHeight) {
        y = e.pageY - menuRect.height;
    }

    // 位置を確定して表示
    menu.style.left = `${x}px`;
    menu.style.top = `${y}px`;
    menu.style.visibility = 'visible';

    // クリック位置を保存（ノード作成時に使用）
    const container = e.target.closest('.node-list-container');
    if (container) {
        const rect = container.getBoundingClientRect();
        boardClickPosition = {
            x: e.clientX - rect.left + container.scrollLeft,
            y: e.clientY - rect.top + container.scrollTop
        };
    }

    console.log('[ボード右クリック] 位置:', boardClickPosition);

    // メニュー外クリックで閉じる
    setTimeout(() => {
        document.addEventListener('click', hideContextMenu);
    }, 100);
}

// ボードメニューから貼り付け（クリック位置に貼り付け）
async function pasteNodeFromBoardMenu() {
    if (!nodeClipboard) {
        console.warn('[貼り付け] クリップボードが空です');
        showToast('コピーされたノードがありません', 'warning');
        hideContextMenu();
        return false;
    }

    console.log(`[ボード貼り付け] クリック位置に貼り付け:`, boardClickPosition);
    const sourceNode = nodeClipboard.node;
    const sourceScript = nodeClipboard.script || '';

    try {
        // 新しいノードIDを生成
        const timestamp = Date.now();
        const random = Math.floor(Math.random() * 900) + 100;
        const newNodeId = `node-${timestamp}-${random}`;

        // クリック位置を基準に重複しない位置を探す
        const newY = findNonOverlappingY(leftVisibleLayer, boardClickPosition.y);

        // 新しいノードを作成
        const newNode = {
            id: newNodeId,
            name: newNodeId,
            text: sourceNode.text,
            color: sourceNode.color,
            layer: leftVisibleLayer,  // 現在のレイヤーに貼り付け
            y: newY,
            x: sourceNode.x,
            width: sourceNode.width,
            height: sourceNode.height,
            groupId: sourceNode.groupId,
            処理番号: sourceNode.処理番号 || '',
            script: sourceScript,
            関数名: sourceNode.関数名 || ''
        };

        console.log(`[ボード貼り付け] 新しいノード: ID=${newNodeId}, Y=${newY}`);

        // layerStructure に追加
        layerStructure[newNode.layer].nodes.push(newNode);
        nodes.push(newNode);

        // スクリプトがある場合はコード.jsonにも保存
        if (sourceScript && sourceScript.trim() !== '') {
            await setCodeEntry(newNodeId, sourceScript);
        }

        // memory.json に保存
        await saveMemoryJson();

        // UIを再描画
        renderNodesInLayer(leftVisibleLayer, 'left');

        console.log(`[ボード貼り付け] ✅ 成功`);
        showToast(`ノードを貼り付けました`, 'success');

        hideContextMenu();
        return true;
    } catch (error) {
        console.error('[ボード貼り付け] エラー:', error);
        showToast(`貼り付けエラー: ${error.message}`, 'error');
        hideContextMenu();
        return false;
    }
}

// 全ての赤枠を解除
function clearAllRedBorders() {
    const currentLayerNodes = layerStructure[leftVisibleLayer]?.nodes || [];
    let clearedCount = 0;

    currentLayerNodes.forEach(node => {
        if (node.redBorder) {
            node.redBorder = false;
            clearedCount++;
        }
    });

    if (clearedCount > 0) {
        renderNodesInLayer(leftVisibleLayer, 'left');
        showToast(`${clearedCount}個の赤枠を解除しました`, 'success');
    } else {
        showToast('赤枠のノードはありません', 'info');
    }

    hideContextMenu();
}

// ノード設定（右クリックメニューから）
function openNodeSettingsFromContextMenu() {
    if (!contextMenuTarget) return;

    console.log('[右クリック] ノード設定を開く:', contextMenuTarget.text, 'ID:', contextMenuTarget.id);
    openNodeSettings(contextMenuTarget);
    hideContextMenu();
}

// コピー（右クリックメニューから）
function copyNodeFromContextMenu() {
    if (!contextMenuTarget) return;

    console.log('[右クリック] ノードをコピー:', contextMenuTarget.text, 'Name:', contextMenuTarget.name);
    copyNode(contextMenuTarget.name);
    hideContextMenu();
}

// 貼り付け（右クリックメニューから）
async function pasteNodeFromContextMenu() {
    console.log('[右クリック] ノードを貼り付け');
    await pasteNode();
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

// スクリプト編集（PowerShell Windows Forms版）
async function editScript() {
    if (!contextMenuTarget) return;

    console.log('✅ [editScript] ノード編集開始:', contextMenuTarget.text, 'ID:', contextMenuTarget.id);

    // コード.json からコード内容を取得
    const code = getCodeEntry(contextMenuTarget.id);
    console.log('✅ [editScript] 取得したコード長:', code ? code.length : 0);
    console.log('✅ [editScript] 取得したコード内容:', code);

    hideContextMenu();

    const requestBody = {
        nodeId: contextMenuTarget.id,
        nodeName: contextMenuTarget.text,
        currentScript: code || ''
    };
    console.log('✅ [editScript] APIリクエストボディ:', JSON.stringify(requestBody, null, 2));

    try {
        // PowerShell Windows Formsダイアログを呼び出し（ダイアログ用に長めのタイムアウト）
        console.log('✅ [editScript] PowerShell編集ダイアログを呼び出します...');
        const result = await callApi('/node/edit-script', 'POST', requestBody, { timeout: 600000 });

        // HTTPエラーの場合
        if (result._httpStatus) {
            console.error('[editScript] サーバーエラー:', result);
            await showAlertDialog(`サーバーエラー (${result._httpStatus}): ${result.error || result._httpStatusText}`, 'サーバーエラー');
            return;
        }

        if (result.cancelled) {
            console.log('⚠ [editScript] ユーザーがキャンセルしました');
            return;
        }

        if (result.success && result.newScript !== undefined) {
            console.log('✅ [editScript] 編集完了 - 新しいスクリプト長:', result.newScript.length);

            // コード.json に保存
            await setCodeEntry(contextMenuTarget.id, result.newScript);

            console.log(`[editScript] ✅ ノード「${contextMenuTarget.text}」のスクリプトを更新しました`);
        }

    } catch (error) {
        console.error('[editScript] エラー:', error);
        await showAlertDialog(`スクリプト編集中にエラーが発生しました: ${error.message}`, 'エラー');
    }
}

// スクリプト実行（選択したノード単体を実行）
async function executeScript() {
    if (!contextMenuTarget) return;

    const script = contextMenuTarget.script || '';

    if (!script || script.trim() === '') {
        await showAlertDialog('実行するスクリプトが設定されていません。\n「スクリプト編集」でスクリプトを設定してください。', 'スクリプト未設定');
        hideContextMenu();
        return;
    }

    const confirmed = await showConfirmDialog(`ノード「${contextMenuTarget.text}」のスクリプトを実行しますか？\n\nスクリプト内容:\n${script.substring(0, 200)}${script.length > 200 ? '...' : ''}`, 'スクリプト実行確認');
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
            await showAlertDialog(`スクリプト実行完了！\n\n出力:\n${result.output || '(出力なし)'}`, '実行完了');
        } else {
            await showAlertDialog(`スクリプト実行失敗:\n${result.error}`, '実行失敗');
        }
    } catch (error) {
        console.error('スクリプト実行エラー:', error);
        await showAlertDialog(`スクリプト実行中にエラーが発生しました:\n${error.message}`, 'エラー');
    }

    hideContextMenu();
}

// ノード発火（コード.jsonの生成コードを即座に実行）
async function executeNodeCode() {
    if (!contextMenuTarget) return;

    // コード.jsonから生成コードを取得
    const code = getCodeEntry(contextMenuTarget.id);

    if (!code || code.trim() === '') {
        await showAlertDialog('実行するコードがありません。\nノードのコードが生成されていない可能性があります。', 'コード未生成');
        hideContextMenu();
        return;
    }

    console.log(`[ノード発火] ノード: ${contextMenuTarget.text} (ID: ${contextMenuTarget.id})`);
    console.log(`[ノード発火] コード長: ${code.length}文字`);

    try {
        // スクリプト実行APIエンドポイントを呼び出し
        const result = await callApi('/execute/script', 'POST', {
            script: code,
            nodeName: contextMenuTarget.text
        });

        if (result.success) {
            console.log(`[ノード発火] ✅ 実行成功`);
            await showAlertDialog(`🔥 ノード発火完了！\n\nノード: ${contextMenuTarget.text}\n\n出力:\n${result.output || '(出力なし)'}`, '発火完了');
        } else {
            console.error(`[ノード発火] ❌ 実行失敗:`, result.error);
            await showAlertDialog(`ノード発火失敗:\n${result.error}`, '発火失敗');
        }
    } catch (error) {
        console.error('[ノード発火] エラー:', error);
        await showAlertDialog(`ノード発火中にエラーが発生しました:\n${error.message}`, 'エラー');
    }

    hideContextMenu();
}

// レイヤー化（赤枠ノードをまとめて1つのピンクノードにする）
async function layerizeNode() {
    if (!contextMenuTarget) {
        await showAlertDialog('ノードが選択されていません。', 'エラー');
        return;
    }

    console.log(`[レイヤー化] ========== レイヤー化開始 ==========`);
    console.log(`[レイヤー化] 現在のleftVisibleLayer: ${leftVisibleLayer}`);
    console.log(`[レイヤー化] 現在のrightVisibleLayer: ${rightVisibleLayer}`);
    console.log(`[レイヤー化] パンくずリスト:`, breadcrumbStack);
    console.log(`[レイヤー化] pinkSelectionArray:`, JSON.stringify(pinkSelectionArray, null, 2));

    const layerNodes = layerStructure[leftVisibleLayer].nodes;

    // 赤枠ノードを収集
    let redBorderNodes = layerNodes.filter(n => n.redBorder);

    if (redBorderNodes.length === 0) {
        await showAlertDialog('レイヤー化するには、まず赤枠でノードを選択してください。', '選択エラー');
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

    // 削除したノード情報を配列に追加（ID;色;テキスト;groupId;script）
    // 注意: Pinkノードのscriptフィールドは含めない（Pink→Pinkのネスト時に子ノード情報が重複するため）
    // ただし、Aquamarineノード（関数ノード）はscriptを保持する必要がある
    const deletedNodeInfo = sortedRedNodes.map(node => {
        const groupIdStr = (node.groupId !== null && node.groupId !== undefined) ? node.groupId : '';
        // Aquamarineノード（関数ノード）の場合はscriptを保存
        // _を|にエンコードして保存（展開時に_で分割されるのを防ぐ）
        if (node.color === 'Aquamarine' && node.script) {
            const encodedScript = node.script.replace(/_/g, '|');
            console.log(`[レイヤー化] Aquamarineノード(${node.id})のscriptを保存(エンコード済): ${encodedScript.substring(0, 50)}...`);
            return `${node.id};${node.color};${node.text};${groupIdStr};${encodedScript}`;
        }
        return `${node.id};${node.color};${node.text};${groupIdStr}`;
    });

    const entryString = deletedNodeInfo.join('_');

    // 赤枠ノードをグローバル配列とレイヤーから削除
    console.log(`[レイヤー化] ========== ノード削除処理開始 ==========`);
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

    console.log(`[レイヤー化] ✅ ${sortedRedNodes.length}個のノードを削除しました`);

    // 新しいピンクノードを作成
    // ID形式を addSingleNode と統一（数値-1 形式）
    const newNodeIdNum = nodeCounter++;
    const newNodeId = `${newNodeIdNum}-1`;
    const newNode = {
        id: newNodeId,
        text: 'スクリプト',
        color: 'Pink',
        処理番号: '99-1',
        layer: leftVisibleLayer,
        y: minY,
        x: 90,
        width: NODE_WIDTH,
        height: NODE_HEIGHT,
        script: entryString,  // 削除したノードの情報を保存
        redBorder: false
    };

    // グローバル配列とレイヤーに追加
    nodes.push(newNode);
    layerNodes.push(newNode);
    console.log(`[レイヤー化] ✅ 新しいピンクノード作成: ID=${newNodeId}`);

    // Pink選択配列を更新（PowerShell互換）
    pinkSelectionArray[leftVisibleLayer].initialY = minY;
    pinkSelectionArray[leftVisibleLayer].value = 1;

    // ★★★ 追加: コード.jsonにピンクノードの内容を保存 ★★★
    console.log(`[レイヤー化] ========== code.json保存処理開始 ==========`);
    console.log(`[レイヤー化] 新しいピンクノードID: ${newNodeId}`);
    console.log(`[レイヤー化] entryString (子ノードリスト): ${entryString}`);

    // 🔍 削除されたノードのcode.jsonエントリを確認
    console.log(`[レイヤー化] 🔍 削除された各ノードのcode.jsonエントリ:`);
    sortedRedNodes.forEach(node => {
        const codeEntry = codeData["エントリ"] ? codeData["エントリ"][`${node.id}-1`] : null;
        console.log(`  ノードID=${node.id} (${node.text}), code.json[${node.id}-1]: ${codeEntry ? codeEntry.substring(0, 80) + '...' : '(なし)'}`);
    });

    // entryStringを "AAAA" プレフィックス付き、改行区切りに変換
    // 現在: "30-1;Pink;スクリプト;_31-1;White;処理A;_32-1;White;処理B;"
    // 変換後: "AAAA\n30-1;Pink;スクリプト;\n31-1;White;処理A;\n32-1;White;処理B;"
    const formattedEntryString = 'AAAA\n' + entryString.replace(/_/g, '\n');
    console.log(`[レイヤー化] フォーマット後のエントリ: ${formattedEntryString}`);
    console.log(`[レイヤー化] 🔍 この内容にはメタ情報のみで、実際のコードは含まれていません`);
    console.log(`[レイヤー化] 🔍 実際のコードは各子ノードIDのエントリに保存されています`);

    // コード.jsonに保存（setCodeEntry関数を使用）
    try {
        await setCodeEntry(newNodeId, formattedEntryString);
        console.log(`[レイヤー化] ✅ コード.json保存成功 - ノードID: ${newNodeId}`);

        // 🔍 保存後のcode.jsonエントリを確認
        const savedEntry = codeData["エントリ"] ? codeData["エントリ"][`${newNodeId}-1`] : null;
        console.log(`[レイヤー化] 🔍 保存後のcode.jsonエントリ確認:`);
        console.log(`  code.json["エントリ"]["${newNodeId}-1"]:`, savedEntry);
    } catch (error) {
        console.error(`[レイヤー化] ❌ コード.json保存エラー:`, error);
        await showAlertDialog('ピンクノードの保存に失敗しました。コンソールを確認してください。', '保存エラー');
    }
    console.log(`[レイヤー化] ========== code.json保存処理完了 ==========`);

    // ★★★ 追加: レイヤー2以降の場合、親ピンクノードに反映 ★★★
    if (leftVisibleLayer >= 2) {
        console.log(`[レイヤー化] ========== 親ピンクノード更新処理開始 ==========`);
        await updateParentPinkNode([newNode], sortedRedNodes);
        console.log(`[レイヤー化] ========== 親ピンクノード更新処理完了 ==========`);
    }

    // 左右パネルの表示を更新
    updateDualPanelDisplay();

    // 画面を再描画（左右両パネル）
    renderNodesInLayer(leftVisibleLayer, 'left');
    renderNodesInLayer(rightVisibleLayer, 'right');

    // memory.json自動保存
    saveMemoryJson();

    // 矢印を再描画
    refreshAllArrows();

    console.log(`[レイヤー化] ✅ 完了: レイヤー${leftVisibleLayer}の${sortedRedNodes.length}個のノード → ピンクノード${newNodeId}`);

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

    const confirmed = await showConfirmDialog(confirmMessage, 'ノード削除確認');
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

    // v1.1.0: 関連するエッジも削除
    const layerEdges = layerStructure[leftVisibleLayer].edges || [];
    layerStructure[leftVisibleLayer].edges = layerEdges.filter(edge => {
        const isRelated = deleteTargets.includes(edge.source) || deleteTargets.includes(edge.target);
        if (isRelated) {
            console.log(`[削除] エッジ削除: ${edge.id} (${edge.source} → ${edge.target})`);
        }
        return !isRelated;
    });

    renderNodesInLayer(leftVisibleLayer);
    reorderNodesInLayer(leftVisibleLayer);

    // ★ 同じレイヤーのピンクノード展開状態を無効化（レイヤー編集により既存の展開状態は無効）
    if (pinkSelectionArray[leftVisibleLayer].expandedNode !== null) {
        console.log(`[削除完了] ⚠️ レイヤー${leftVisibleLayer}のピンクノード展開状態を無効化します（ノード削除によりレイヤーが変更されたため）`);
        pinkSelectionArray[leftVisibleLayer].value = 0;
        pinkSelectionArray[leftVisibleLayer].expandedNode = null;
        pinkSelectionArray[leftVisibleLayer].yCoord = 0;
        pinkSelectionArray[leftVisibleLayer].initialY = 0;
    }

    // ★ ドリルダウンパネルが編集されたレイヤーの子レイヤーを表示している場合は閉じる
    if (drilldownState.active && drilldownState.targetLayer === leftVisibleLayer + 1) {
        console.log(`[削除完了] ⚠️ ドリルダウンパネルを閉じます（編集中のレイヤー${leftVisibleLayer}の子レイヤーを表示中のため）`);
        closeDrilldownPanel();
    }

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
    console.log(`[ピンク展開] === handlePinkNodeClick 開始 ===`);
    console.log(`[ピンク展開] 「${node.text}」(ID:${node.id}) L${node.layer}→L${node.layer + 1}`);

    const parentLayer = node.layer;
    const nextLayer = parentLayer + 1;

    console.log(`[ピンク展開] parentLayer=${parentLayer}, nextLayer=${nextLayer}`);

    // レイヤー上限チェック
    if (nextLayer > 6) {
        console.log(`[ピンク展開] レイヤー上限エラー（nextLayer=${nextLayer}）`);
        await showAlertDialog('これ以上レイヤーを展開できません（最大レイヤー6）。', 'レイヤー上限');
        return;
    }

    // ★★★ レイヤー2以降はポップアップウィンドウで表示 ★★★
    console.log(`[ピンク展開] nextLayer >= 2 ? ${nextLayer >= 2}`);
    if (nextLayer >= 2) {
        console.log(`[ピンク展開] handlePinkNodeClickPopup を呼び出します`);
        await handlePinkNodeClickPopup(node);
        console.log(`[ピンク展開] handlePinkNodeClickPopup から戻りました`);
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
        await showAlertDialog('このスクリプト化ノードは空です。展開するノードがありません。', '空のノード');
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
        const nodeHeight = isMiddleNode ? 1 : NODE_HEIGHT;
        const nodeWidth = isMiddleNode ? 20 : 120;

        // ボタン間隔と高さの調整（"条件分岐 中間"の場合は特殊）
        const interval = isMiddleNode ? 10 : 20;  // 通常20のところ10
        const heightForNext = isMiddleNode ? 0 : NODE_HEIGHT;  // 通常40のところ0

        // Y座標を設定
        const nodeY = baseY + interval;

        // 新しいノードを作成
        // ID形式を addSingleNode と統一（数値-1 形式）
        const newNodeIdNum = nodeCounter++;
        const newNodeId = `${newNodeIdNum}-1`;
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

    // プレビューパネルをクリア
    if (LOG_CONFIG.pink) {
        console.log(`[ピンク展開] ⏹️ プレビュークリア開始 - タイマーID: ${hoverTimer}`);
    }
    clearTimeout(hoverTimer);
    hidePreview();
    if (LOG_CONFIG.pink) {
        console.log(`[ピンク展開] ⏹️ プレビュークリア完了 (handlePinkNodeClick)`);
    }

    console.log(`[展開完了] レイヤー${parentLayer} → レイヤー${nextLayer}: ${node.text} (${entries.length}個のノード展開、レイヤー移動なし)`);
    console.log(`[パネル表示] 左: レイヤー${leftVisibleLayer}, 右: レイヤー${rightVisibleLayer}`);

    // メインパネル直接表示（オーバーレイ版は使用しない）
    // レイヤー展開後、通常の2パネル表示を維持
}

// ============================================
// ピンクノード展開（ポップアップウィンドウ版）
// ============================================
async function handlePinkNodeClickPopup(node) {
    console.log(`[ピンク展開ポップアップ] 「${node.text}」(ID:${node.id}) L${node.layer}→L${node.layer + 1}`);

    const parentLayer = node.layer;
    const nextLayer = parentLayer + 1;

    // 🔍 デバッグ: 展開前のlayerStructure全体の状態を出力
    console.log(`[ピンク展開ポップアップ] 🔍 展開前のlayerStructure全体:`);
    for (let i = 0; i <= 6; i++) {
        const layerNodeIds = layerStructure[i].nodes.map(n => `${n.id}(${n.text})`).join(', ');
        console.log(`🔍   L${i}: [${layerNodeIds}] (${layerStructure[i].nodes.length}個)`);
    }

    // scriptプロパティを解析してノードを展開
    if (!node.script || node.script.trim() === '') {
        console.warn(`[ピンク展開ポップアップ] scriptデータなし`);
        await showAlertDialog('このスクリプト化ノードは空です。展開するノードがありません。', '空のノード');
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
    console.log(`[ピンク展開ポップアップ] レイヤー${nextLayer}をクリアします`);
    layerStructure[nextLayer].nodes = [];

    // scriptデータを解析（形式: ID;色;テキスト;スクリプト）
    const entries = node.script.split('_').filter(e => e.trim() !== '');
    console.log(`[ピンク展開ポップアップ] ${entries.length}個のノードを展開`);

    let baseY = 10; // 初期Y座標
    const expandedNodes = []; // 展開されたノード配列

    entries.forEach((entry, index) => {
        const parts = entry.split(';');
        if (parts.length < 3) {
            console.warn(`[展開処理] エントリ${index}のフォーマットが不正: ${entry}`);
            return;
        }

        const originalId = parts[0];
        const color = parts[1];
        const text = parts[2];
        // parts[3]はgroupId（レイヤー化処理で保存された値）
        const groupIdFromScript = parts[3] || '';
        // groupIdを数値に変換（空文字列の場合はnull）
        const groupId = groupIdFromScript ? parseInt(groupIdFromScript) : null;
        // parts[4]以降がscript（通常は空）
        // Aquamarineノードの場合、scriptに;が含まれるため、parts[4]以降を全て結合する
        let script = '';
        if (color === 'Aquamarine' && parts.length > 4) {
            // parts[4]以降を;で結合してscriptを復元
            script = parts.slice(4).join(';');
            // |を_にデコード
            script = script.replace(/\|/g, '_');
            console.log(`[展開処理] Aquamarineノードのscriptをデコード: ${script.substring(0, 80)}...`);
        } else {
            script = parts[4] || '';
        }

        console.warn(`🔍🔍🔍 [展開処理] originalId="${originalId}", color=${color}, text="${text}", groupId=${groupId}, script="${script ? script.substring(0, 30) + '...' : '(なし)'}`);

        // ピンクノードの場合、コード.jsonからscriptデータを復元
        if (color === 'Pink' && !script) {
            const savedScript = getCodeEntry(originalId);
            if (savedScript) {
                script = savedScript
                    .replace(/^AAAA\n/, '')
                    .replace(/\n---\n/g, '_')
                    .replace(/\n/g, '_')
                    .replace(/_+/g, '_')
                    .trim();
            }
        }

        // Aquamarineノード（関数ノード）の場合のフォールバック処理
        // 通常はレイヤー化時に保存されたscript（parts[4]）から復元されるが、
        // 古いデータの場合はグローバル配列やuserFunctionsから検索
        if (color === 'Aquamarine' && !script) {
            console.log(`[展開処理] Aquamarineノード(${originalId})のscriptがレイヤーデータにありません。フォールバック検索開始...`);
            // 元のノードをグローバル配列から検索（originalIdで検索）
            const originalNode = nodes.find(n => n.id === originalId);
            if (originalNode && originalNode.script) {
                script = originalNode.script;
                console.log(`[展開処理] Aquamarineノードのscriptをグローバル配列から復元: ${script.substring(0, 50)}...`);
            } else {
                // userFunctionsからも検索
                const funcNode = nodes.find(n => n.functionId && n.id === originalId);
                if (funcNode && funcNode.script) {
                    script = funcNode.script;
                    console.log(`[展開処理] Aquamarineノードのscriptをfunctionノードから復元: ${script.substring(0, 50)}...`);
                } else {
                    console.warn(`[展開処理] ⚠ Aquamarineノード(${originalId})のscriptが見つかりません（レイヤーデータ、グローバル配列、userFunctionsすべて検索済み）`);
                }
            }
        }

        // 条件分岐の中間ノードは高さ1px、幅20px
        const isMiddleNode = (text === '条件分岐 中間' || color === 'Gray');
        const nodeHeight = isMiddleNode ? 1 : NODE_HEIGHT;
        const nodeWidth = isMiddleNode ? 20 : 120;
        const interval = isMiddleNode ? 10 : 20;
        const heightForNext = isMiddleNode ? 0 : NODE_HEIGHT;

        // Y座標を設定
        const nodeY = baseY + interval;

        // 新しいノードを作成
        // ID形式を addSingleNode と統一（数値-1 形式）
        const newNodeIdNum = nodeCounter++;
        const newNodeId = `${newNodeIdNum}-1`;
        const newNode = {
            id: newNodeId,
            text: text,
            color: color,
            処理番号: '99-1',
            layer: nextLayer,
            y: nodeY,
            x: 90,
            width: nodeWidth,
            height: nodeHeight,
            script: script,
            redBorder: false,
            groupId: groupId  // 🔥 元のノードからgroupIdをコピー
        };

        console.log(`[展開処理] ノード作成: ID=${newNodeId}, テキスト=${text}, 色=${color}, Y=${nodeY}, groupId=${groupId}`);

        // グローバル配列とレイヤーに追加
        nodes.push(newNode);
        layerStructure[nextLayer].nodes.push(newNode);
        expandedNodes.push(newNode);

        // ノードのエントリを新しいIDでコード.jsonに保存
        if (color === 'Pink') {
            // Pinkノードの場合、コード.jsonから復元したエントリを新しいIDで保存
            const savedScriptForCodeJson = getCodeEntry(originalId);
            if (savedScriptForCodeJson) {
                console.log(`[展開処理] ピンクノードを元のID(${originalId})から新しいID(${newNodeId})にコピーします`);
                setCodeEntry(newNodeId, savedScriptForCodeJson).then(() => {
                    console.log(`[展開処理] ✅ コード.json保存成功 - 新しいID: ${newNodeId}`);
                }).catch(error => {
                    console.error(`[展開処理] ❌ コード.json保存エラー:`, error);
                });
            } else {
                console.warn(`[展開処理] ⚠ 元のID(${originalId})のピンクノードエントリが見つかりません`);
            }
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

        // 次のノードのbaseY計算
        baseY = nodeY + heightForNext;
    });

    // 🔍 デバッグ: 展開後のlayerStructure全体の状態を出力
    console.log(`[ピンク展開ポップアップ] 🔍 展開後のlayerStructure全体:`);
    for (let i = 0; i <= 6; i++) {
        const layerNodeIds = layerStructure[i].nodes.map(n => `${n.id}(${n.text})`).join(', ');
        console.log(`🔍   L${i}: [${layerNodeIds}] (${layerStructure[i].nodes.length}個)`);
    }

    // 親ノードのscriptを新しいIDで更新（展開後のノードで再生成）
    const newScript = expandedNodes.map(n => {
        const groupIdStr = (n.groupId !== null && n.groupId !== undefined) ? n.groupId : '';
        // Aquamarineノードの場合はscriptも保存
        const scriptStr = n.script || '';
        return `${n.id};${n.color};${n.text};${groupIdStr};${scriptStr}`;
    }).join('_');

    console.log(`[展開処理] 親ノードのscriptを新しいIDで更新: ${newScript.substring(0, 100)}...`);
    node.script = newScript;

    // グローバル配列のノードも更新
    const globalNode = nodes.find(n => n.id === node.id);
    if (globalNode) {
        globalNode.script = newScript;
    }

    // レイヤー構造のノードも更新
    const layerNode = layerStructure[parentLayer].nodes.find(n => n.id === node.id);
    if (layerNode) {
        layerNode.script = newScript;
    }

    // memory.json自動保存
    await saveMemoryJson();

    // 右パネルにドリルダウンプレビュー表示（ピンク展開時はプレビューのみ、パンくずは不変）
    console.log(`[ピンク展開ポップアップ] ドリルダウンパネルを表示: レイヤー${parentLayer} → レイヤー${nextLayer}: ${node.text} (${expandedNodes.length}個のノード展開)`);
    console.log(`[ピンク展開ポップアップ] 📍 パンくずは変更しません（左パネル連動のため）`);
    console.log(`[ピンク展開ポップアップ] 現在のbreadcrumbStack:`, breadcrumbStack.map(b => `L${b.layer}:${b.name}`).join(' → '));

    // ドリルダウンパネルにプレビュー表示（編集ボタン付き）
    showLayerInDrilldownPanel(node, expandedNodes);

    // グローエフェクトを再適用（レンダリング後に実行）
    setTimeout(() => {
        applyGlowEffects();
    }, 50);

    // 矢印を再描画
    refreshAllArrows();

    // プレビューパネルをクリア
    if (LOG_CONFIG.pink) {
        console.log(`[ピンク展開ポップアップ] ⏹️ プレビュークリア開始 - タイマーID: ${hoverTimer}`);
    }
    clearTimeout(hoverTimer);
    hidePreview();
    if (LOG_CONFIG.pink) {
        console.log(`[ピンク展開ポップアップ] ⏹️ プレビュークリア完了 (handlePinkNodeClickPopup)`);
    }
}

// 赤枠に挟まれたボタンスタイルを適用
async function applyRedBorderToGroup() {
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
        await showAlertDialog('赤枠ノードが2つ以上必要です。', '選択エラー');
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
    await showAlertDialog(`${appliedCount}個のノードに赤枠を適用しました。`, '赤枠適用完了');

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
        await showAlertDialog('削除するノードがありません。', 'お知らせ');
        return;
    }

    // 確認ダイアログ（全レイヤーの合計ノード数を表示）
    const confirmed = await showConfirmDialog(
        `⚠️ すべてのレイヤーのノード（合計${totalNodeCount}個）とコード.jsonを削除します。\n\n` +
        `この操作は取り消せません。本当に削除しますか？\n\n` +
        `削除されるノード:\n` +
        Object.keys(layerCounts)
            .filter(layer => layerCounts[layer] > 0)
            .map(layer => `  レイヤー${layer}: ${layerCounts[layer]}個`)
            .join('\n'),
        '⚠️ 全削除確認'
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
            await showAlertDialog(`ノード削除に失敗しました: ${result.error}`, '削除エラー');
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
            await showAlertDialog(`コード.json初期化に失敗しました: ${codeResult.error}`, '初期化エラー');
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

        // ステップ4: レイヤー1に戻る
        console.log('[全削除] ステップ4: レイヤー1に戻ります...');
        leftVisibleLayer = 1;
        rightVisibleLayer = 2;
        breadcrumbStack = [{ name: 'メインフロー', layer: 1 }];
        renderBreadcrumb();
        updateDualPanelDisplay();

        // 右パネルを空状態に戻す
        const rightPanel = document.getElementById('right-layer-panel');
        if (rightPanel) {
            rightPanel.classList.add('empty');
            rightPanel.innerHTML = '';
        }

        // ステップ5: 画面を再描画
        console.log('[全削除] ステップ5: 画面を再描画します...');
        renderNodesInLayer(leftVisibleLayer, 'left');
        renderNodesInLayer(rightVisibleLayer, 'right');

        // ステップ6: memory.json自動保存
        console.log('[全削除] ステップ6: memory.jsonを保存します...');
        await saveMemoryJson();

        console.log('[全削除] ✅ すべての処理が完了しました');
        await showAlertDialog(`${totalNodeCount}個のノードとコード.jsonを削除しました。`, '削除完了');
    } catch (error) {
        console.error('[全削除] ❌ エラー:', error);
        console.error('[全削除] スタックトレース:', error.stack);
        await showAlertDialog(`削除中にエラーが発生しました: ${error.message}`, 'エラー');
    }
}

// ============================================
// レイヤーナビゲーション
// ============================================

async function navigateLayer(direction) {
    console.log(`[レイヤー移動] ⬅️➡️ navigateLayer("${direction}") - 現在leftVisibleLayer=${leftVisibleLayer}`);

    // ドリルダウンパネルがアクティブな場合はクリア
    if (drilldownState && drilldownState.active) {
        console.log(`[レイヤー移動] ドリルダウンパネルをクローズします`);
        closeDrilldownPanel();
    }

    if (direction === 'right') {
        // 右矢印: レイヤーを進む（PowerShellの「左矢印」= 画面が左にスライド）

        // スクリプト展開チェック（レイヤー1以降）
        if (leftVisibleLayer >= 1) {
            if (pinkSelectionArray[leftVisibleLayer].value !== 1) {
                await showAlertDialog(`レイヤー${leftVisibleLayer + 1} に進むには、\nレイヤー${leftVisibleLayer} でスクリプト化ノードを展開してください。\n\n操作手順:\n1. Shift を押しながら複数のノードをクリック（赤枠が付きます）\n2. 「レイヤー化」ボタンをクリック\n3. 作成されたスクリプト化ノード（ピンク色）をクリック\n4. 次のレイヤーに展開されます`, '操作ガイド');
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

            // ★ パンくずリストを左パネルに連動して更新
            updateBreadcrumbForLayer(leftVisibleLayer);
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

            // ★ パンくずリストを左パネルに連動して更新
            updateBreadcrumbForLayer(leftVisibleLayer);
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
// 変数管理（タブ内実装版）
// ============================================

// 編集中の変数名（null = 新規追加）
let editingVariableName = null;

// 変数一覧を読み込み、タブに表示
async function loadVariables() {
    try {
        const result = await callApi('/variables');
        if (result.success) {
            variables = result.variables || {};
            console.log('変数読み込み完了:', Object.keys(variables).length, '個');
            renderVariablesList();
        }
    } catch (error) {
        console.error('変数読み込み失敗:', error);
    }
}

// 変数リストを描画
function renderVariablesList() {
    console.log('[変数リスト] renderVariablesList() 呼び出し');
    console.log('[変数リスト] variables:', variables);
    console.log('[変数リスト] variablesの型:', typeof variables);
    console.log('[変数リスト] variablesのキー:', Object.keys(variables || {}));

    const container = document.getElementById('variables-list');
    if (!container) {
        console.log('[変数リスト] containerが見つかりません');
        return;
    }

    // 変数データを配列に変換
    let varList = [];
    if (Array.isArray(variables)) {
        varList = variables;
    } else if (typeof variables === 'object' && variables !== null) {
        varList = Object.entries(variables).map(([name, data]) => ({
            name: name,
            value: data.value || data,
            type: data.type || '単一値',
            displayValue: data.displayValue || String(data.value || data)
        }));
    }
    console.log('[変数リスト] varList:', varList.length, '件');

    if (varList.length === 0) {
        container.innerHTML = `
            <div class="variables-empty">
                <div class="variables-empty-icon">📦</div>
                <div class="variables-empty-text">変数がありません<br>「＋ 追加」ボタンで作成できます</div>
            </div>
        `;
        return;
    }

    container.innerHTML = varList.map(v => `
        <div class="variable-item" onclick="showVariableEditor('${escapeHtml(v.name)}')">
            <div class="variable-item-info">
                <div class="variable-item-name">${escapeHtml(v.name)}</div>
                <div class="variable-item-meta">
                    <span class="variable-item-type">${escapeHtml(v.type)}</span>
                    <span class="variable-item-value">${escapeHtml(v.displayValue || '')}</span>
                </div>
            </div>
            <div class="variable-item-actions">
                <button class="variable-item-btn delete" onclick="event.stopPropagation(); deleteVariableConfirm('${escapeHtml(v.name)}')">🗑</button>
            </div>
        </div>
    `).join('');
}

// HTMLエスケープ関数
function escapeHtml(text) {
    if (text == null) return '';
    const div = document.createElement('div');
    div.textContent = String(text);
    return div.innerHTML;
}

// 変数エディタを表示
function showVariableEditor(name) {
    editingVariableName = name;
    const editor = document.getElementById('variable-editor');
    const title = document.getElementById('variable-editor-title');
    const nameInput = document.getElementById('variable-name-input');
    const typeSelect = document.getElementById('variable-type-select');
    const valueInput = document.getElementById('variable-value-input');

    if (name) {
        // 編集モード
        title.textContent = '変数を編集';
        nameInput.value = name;
        nameInput.disabled = true; // 名前は変更不可

        // 変数データを取得
        let varData = null;
        if (Array.isArray(variables)) {
            varData = variables.find(v => v.name === name);
        } else if (variables[name]) {
            varData = variables[name];
            if (typeof varData !== 'object') {
                varData = { value: varData, type: '単一値' };
            }
        }

        if (varData) {
            typeSelect.value = varData.type || '単一値';
            onVariableTypeChange();

            if (varData.type === '二次元') {
                initGridEditor(varData.value);
            } else if (varData.type === '一次元') {
                valueInput.value = Array.isArray(varData.value) ? varData.value.join('\n') : String(varData.value || '');
            } else {
                valueInput.value = String(varData.value || '');
            }
        }
    } else {
        // 新規追加モード
        title.textContent = '変数を追加';
        nameInput.value = '';
        nameInput.disabled = false;
        typeSelect.value = '単一値';
        valueInput.value = '';
        onVariableTypeChange();
        initGridEditor([['']]);
    }

    editor.style.display = 'flex';
}

// 変数エディタを非表示
function hideVariableEditor() {
    const editor = document.getElementById('variable-editor');
    editor.style.display = 'none';
    editingVariableName = null;
}

// データ型変更時の処理
function onVariableTypeChange() {
    const typeSelect = document.getElementById('variable-type-select');
    const valueField = document.getElementById('variable-value-field');
    const gridField = document.getElementById('variable-grid-field');
    const valueInput = document.getElementById('variable-value-input');

    if (typeSelect.value === '二次元') {
        valueField.style.display = 'none';
        gridField.style.display = 'block';
        // グリッドが空の場合は初期化
        const tbody = document.getElementById('grid-editor-body');
        if (!tbody.children.length) {
            initGridEditor([['']]);
        }
    } else {
        valueField.style.display = 'block';
        gridField.style.display = 'none';

        // プレースホルダーを更新
        if (typeSelect.value === '一次元') {
            valueInput.placeholder = '値を入力（改行区切りで配列になります）';
        } else {
            valueInput.placeholder = '値を入力';
        }
    }
}

// 変数を保存
async function saveVariable() {
    const nameInput = document.getElementById('variable-name-input');
    const typeSelect = document.getElementById('variable-type-select');
    const valueInput = document.getElementById('variable-value-input');

    const name = nameInput.value.trim();
    const type = typeSelect.value;

    if (!name) {
        await showAlertDialog('変数名を入力してください', 'エラー');
        return;
    }

    let value;
    if (type === '二次元') {
        value = getGridData();
    } else if (type === '一次元') {
        value = valueInput.value.split('\n').filter(line => line !== '');
    } else {
        value = valueInput.value;
    }

    try {
        let result;
        if (editingVariableName) {
            // 更新
            result = await fetch(`${API_BASE}/variables/${encodeURIComponent(name)}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ value, type })
            }).then(r => r.json());
        } else {
            // 新規追加
            result = await fetch(`${API_BASE}/variables`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ name, value, type })
            }).then(r => r.json());
        }

        if (result.success) {
            console.log(`✅ [変数] ${editingVariableName ? '更新' : '追加'}成功: ${name}`);
            hideVariableEditor();
            await loadVariables();
        } else {
            await showAlertDialog(`変数の保存に失敗しました: ${result.error}`, 'エラー');
        }
    } catch (error) {
        console.error('変数保存エラー:', error);
        await showAlertDialog(`変数の保存中にエラーが発生しました: ${error.message}`, 'エラー');
    }
}

// 変数削除の確認
async function deleteVariableConfirm(name) {
    const confirmed = await showConfirmDialog(`変数「${name}」を削除しますか？`, '変数の削除');
    if (confirmed) {
        await deleteVariable(name);
    }
}

// 変数を削除
async function deleteVariable(name) {
    try {
        const result = await fetch(`${API_BASE}/variables/${encodeURIComponent(name)}`, {
            method: 'DELETE'
        }).then(r => r.json());

        if (result.success) {
            console.log(`✅ [変数] 削除成功: ${name}`);
            await loadVariables();
        } else {
            await showAlertDialog(`変数の削除に失敗しました: ${result.error}`, 'エラー');
        }
    } catch (error) {
        console.error('変数削除エラー:', error);
        await showAlertDialog(`変数の削除中にエラーが発生しました: ${error.message}`, 'エラー');
    }
}

// ============================================
// 二次元配列グリッドエディタ
// ============================================

// グリッドを初期化
function initGridEditor(data) {
    const tbody = document.getElementById('grid-editor-body');
    if (!data || !Array.isArray(data) || data.length === 0) {
        data = [['']];
    }

    // 行数と列数を取得
    const rows = data.length;
    const cols = Math.max(...data.map(row => Array.isArray(row) ? row.length : 1), 1);

    tbody.innerHTML = '';
    for (let i = 0; i < rows; i++) {
        const tr = document.createElement('tr');
        for (let j = 0; j < cols; j++) {
            const td = document.createElement('td');
            const input = document.createElement('input');
            input.type = 'text';
            input.value = (data[i] && data[i][j]) ? String(data[i][j]) : '';
            td.appendChild(input);
            tr.appendChild(td);
        }
        tbody.appendChild(tr);
    }
}

// グリッドデータを取得
function getGridData() {
    const tbody = document.getElementById('grid-editor-body');
    const rows = tbody.querySelectorAll('tr');
    const data = [];

    rows.forEach(tr => {
        const rowData = [];
        tr.querySelectorAll('input').forEach(input => {
            rowData.push(input.value);
        });
        data.push(rowData);
    });

    return data;
}

// 行を追加
function addGridRow() {
    const tbody = document.getElementById('grid-editor-body');
    const cols = tbody.firstChild ? tbody.firstChild.children.length : 1;

    const tr = document.createElement('tr');
    for (let j = 0; j < cols; j++) {
        const td = document.createElement('td');
        const input = document.createElement('input');
        input.type = 'text';
        td.appendChild(input);
        tr.appendChild(td);
    }
    tbody.appendChild(tr);
}

// 列を追加
function addGridCol() {
    const tbody = document.getElementById('grid-editor-body');
    const rows = tbody.querySelectorAll('tr');

    if (rows.length === 0) {
        addGridRow();
        return;
    }

    rows.forEach(tr => {
        const td = document.createElement('td');
        const input = document.createElement('input');
        input.type = 'text';
        td.appendChild(input);
        tr.appendChild(td);
    });
}

// 行を削除
function removeGridRow() {
    const tbody = document.getElementById('grid-editor-body');
    if (tbody.children.length > 1) {
        tbody.removeChild(tbody.lastChild);
    }
}

// 列を削除
function removeGridCol() {
    const tbody = document.getElementById('grid-editor-body');
    const rows = tbody.querySelectorAll('tr');

    rows.forEach(tr => {
        if (tr.children.length > 1) {
            tr.removeChild(tr.lastChild);
        }
    });
}

// 旧関数（互換性のため残す）
async function openVariableModal() {
    // タブに切り替えてエディタを開く
    switchLeftPanelTab('variables');
    showVariableEditor(null);
}

// ============================================
// ヘルプモーダル
// ============================================

function openHelpModal() {
    const modal = document.getElementById('help-modal');
    if (modal) {
        modal.style.display = 'flex';
    }
}

function closeHelpModal() {
    const modal = document.getElementById('help-modal');
    if (modal) {
        modal.style.display = 'none';
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

// ============================================
// フォルダ管理（PowerShell Windows Forms版に移行）
// ============================================

// 統合されたフォルダ管理関数（作成・切替・削除）
function folderManagement() {
    console.log('[フォルダ管理] folderManagement() を呼び出し');
    // フォルダ管理ダイアログを表示（作成・切替・削除を統合）
    switchFolder();
}

// 後方互換性のため残す
function createFolder() {
    console.log('[フォルダ管理] createFolder() → folderManagement() にリダイレクト');
    folderManagement();
}

async function switchFolder() {
    console.log('✅ [フォルダ管理] ダイアログを開く（PowerShell Windows Forms版）');

    try {
        // API経由でPowerShell Windows Forms ダイアログを表示（ダイアログ用に長めのタイムアウト）
        const result = await callApi('/folders/switch-dialog', 'POST', null, { timeout: 300000 });

        // HTTPエラーの場合
        if (result._httpStatus) {
            console.error('❌ [フォルダ切替] HTTPエラー:', result._httpStatus);
            await showAlertDialog(`サーバーエラー (${result._httpStatus}): ${result.error || result._httpStatusText}`, 'サーバーエラー');
            return;
        }

        if (result.cancelled) {
            console.log('✅ [フォルダ切替] キャンセルされました');
            return;
        }

        if (result.success) {
            console.log('✅ [フォルダ切替] フォルダ選択完了:', result.folderName);

            // フォルダが切り替えられた場合
            if (result.switched) {
                console.log('✅ [フォルダ切替] フォルダが切り替えられました:', result.folderName);
                currentFolder = result.folderName;

                // コード.json、variables.json、memory.jsonを再読み込み
                await loadCodeJson();
                await loadVariablesJson();
                await loadExistingNodes();
                await loadFolders();

                console.log('✅ [フォルダ切替] データ再読み込み完了');
            } else {
                console.log('✅ [フォルダ切替] 同じフォルダが選択されました（変更なし）');
            }
        } else {
            console.error('❌ [フォルダ切替] エラー:', result.error);
            await showAlertDialog(`フォルダ切替エラー: ${result.error}`, 'フォルダ切替エラー');
        }

    } catch (error) {
        console.error('❌ [フォルダ切替] 予期しないエラー:', error);
        await showAlertDialog(`フォルダ切替中にエラーが発生しました: ${error.message}`, 'エラー');
    }
}

function closeFolderModal() {
    console.log('[フォルダ切替] closeFolderModal() は廃止されました（PowerShell Windows Forms版に移行）');
}

async function selectFolder() {
    console.log('[フォルダ切替] selectFolder() は廃止されました（PowerShell Windows Forms版に移行）');
    console.log('[フォルダ切替] 代わりに switchFolder() を使用してください');
}

// ============================================
// アプリケーション終了
// ============================================

async function exitApplication() {
    console.log('[終了] exitApplication() が呼び出されました');

    // 確認ダイアログを表示
    const confirmed = await showConfirmDialog('アプリケーションを終了しますか？', '終了確認');
    if (!confirmed) {
        console.log('[終了] ユーザーがキャンセルしました');
        return;
    }

    try {
        // サーバーに終了リクエストを送信
        console.log('[終了] サーバーに終了リクエストを送信...');
        const response = await fetch(`${API_BASE}/shutdown`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        });

        const result = await response.json();

        if (result.success) {
            console.log('[終了] サーバー終了処理が開始されました');
            // ブラウザウィンドウを閉じる
            window.close();
            // window.close()が動作しない場合は終了メッセージを表示
            document.body.innerHTML = '<div style="display: flex; justify-content: center; align-items: center; height: 100vh; font-size: 24px; font-family: sans-serif; background-color: #f5f5f5;"><div style="text-align: center;"><p>アプリケーションを終了しました。</p><p style="font-size: 16px; color: #666;">このウィンドウを閉じてください。</p></div></div>';
        } else {
            console.error('[終了] サーバー終了エラー:', result.error);
            await showAlertDialog(`終了処理中にエラーが発生しました: ${result.error}`, 'エラー');
        }
    } catch (error) {
        console.error('[終了] 予期しないエラー:', error);
        // サーバーに接続できない場合でもブラウザを閉じる
        window.close();
        document.body.innerHTML = '<div style="display: flex; justify-content: center; align-items: center; height: 100vh; font-size: 24px; font-family: sans-serif; background-color: #f5f5f5;"><div style="text-align: center;"><p>アプリケーションを終了しました。</p><p style="font-size: 16px; color: #666;">このウィンドウを閉じてください。</p></div></div>';
    }
}

// ============================================
// コード生成
// ============================================

async function executeCode() {
    const confirmed = await showConfirmDialog('PowerShellコードを生成しますか？', 'コード生成確認');
    if (!confirmed) return;

    const startTime = performance.now();
    console.log(`[実行] レイヤー${leftVisibleLayer} のコード生成を開始...`);

    try {
        // 現在のレイヤーのノードを取得
        const currentLayerNodes = layerStructure[leftVisibleLayer]?.nodes || [];

        // ノードが存在しない場合の検証
        if (currentLayerNodes.length === 0) {
            console.log('❌ [実行] ノードがありません');
            await showAlertDialog('現在のレイヤーにノードがありません。ノードを追加してから実行してください。', 'ノードなし');
            return;
        }

        console.log(`[実行] ノード数: ${currentLayerNodes.length}個`);

        // 全レイヤーのノードを収集（関数ノードのscript取得用）
        const allLayerNodes = [];
        Object.keys(layerStructure).forEach(layerKey => {
            const layerNodes = layerStructure[layerKey]?.nodes || [];
            layerNodes.forEach(n => {
                allLayerNodes.push({
                    id: n.id,
                    text: n.text,
                    color: n.color,
                    y: n.y,
                    処理番号: n.処理番号,
                    script: n.script || '',
                    layer: layerKey
                });
            });
        });
        console.log(`[実行] 全レイヤーノード数: ${allLayerNodes.length}個`);

        // 送信データを準備
        const requestData = {
            nodes: currentLayerNodes.map(n => ({
                id: n.id,
                text: n.text,
                color: n.color,
                y: n.y,
                処理番号: n.処理番号,
                script: n.script || ''  // Pinkノードの子ノード情報
            })),
            allNodes: allLayerNodes,  // 全レイヤーのノード（関数ノード展開用）
            outputPath: null,
            openFile: false
        };

        console.log('[実行] API送信データ:', JSON.stringify(requestData, null, 2));

        // 現在のレイヤーのノードを送信
        const apiStartTime = performance.now();
        const result = await callApi('/execute/generate', 'POST', requestData);
        if (result.success) {
            console.log(`✅ [実行] 成功 - ノード数: ${result.nodeCount}個, コード長: ${result.code?.length || 0}文字`);

            // PowerShell Windows Formsでコード結果を表示
            try {
                const showResultResponse = await fetch(`${API_BASE}/code-result/show`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        code: result.code,
                        nodeCount: result.nodeCount,
                        outputPath: result.outputPath,
                        timestamp: new Date().toLocaleString('ja-JP')
                    })
                });

                const showResultData = await showResultResponse.json();

                if (showResultData.success) {
                    console.log('✅ [実行] コード結果ダイアログを表示しました');
                } else {
                    console.error('❌ [実行] コード結果ダイアログ表示エラー:', showResultData.error);
                }
            } catch (error) {
                console.error('❌ [実行] コード結果ダイアログ表示エラー:', error);
            }
        } else {
            console.error(`❌ [実行] 失敗: ${result.error}`);
            await showAlertDialog(`コード生成失敗: ${result.error}`, 'コード生成失敗');
        }
    } catch (error) {
        const endTime = performance.now();
        const totalDuration = (endTime - startTime).toFixed(2);
        console.error('❌ [実行] コード生成エラー (所要時間: ' + totalDuration + 'ms)');
        console.error('❌ [実行] エラーメッセージ:', error.message);
        console.error('❌ [実行] スタックトレース:', error.stack);
        console.log('═══════════════════════════════════════════════');
        console.log('');
        await showAlertDialog(`コード生成中にエラーが発生しました: ${error.message}`, 'エラー');
    }
}

// ============================================
// 部分実行機能（紫の横棒UI版）
// ============================================

// 部分実行モードの状態
let partialExecuteMode = {
    active: false,
    startY: null,      // 開始バーのY座標
    endY: null,        // 終了バーのY座標
    startNodeIndex: 0, // 開始ノードのインデックス（0-indexed）
    endNodeIndex: null // 終了ノードのインデックス（0-indexed）
};

// 部分実行モードを開始/終了
async function openPartialExecuteDialog() {
    if (partialExecuteMode.active) {
        // すでにアクティブなら終了
        closePartialExecuteMode();
        return;
    }

    // 現在のレイヤーのノードを取得
    const currentLayerNodes = layerStructure[leftVisibleLayer]?.nodes || [];

    if (currentLayerNodes.length === 0) {
        await showAlertDialog('現在のレイヤーにノードがありません。', 'ノードなし');
        return;
    }

    // ノードをY座標でソート
    const sortedNodes = [...currentLayerNodes].sort((a, b) => a.y - b.y);

    // 初期位置を設定（最初と最後のノード）
    const firstNode = sortedNodes[0];
    const lastNode = sortedNodes[sortedNodes.length - 1];

    partialExecuteMode.active = true;
    partialExecuteMode.startY = firstNode.y - 5;  // ノードの少し上
    partialExecuteMode.endY = lastNode.y + NODE_HEIGHT + 5;    // ノードの少し下
    partialExecuteMode.startNodeIndex = 0;
    partialExecuteMode.endNodeIndex = sortedNodes.length - 1;

    // 紫の横棒を描画
    renderPartialExecuteBars();

    // 実行ボタンを表示
    showPartialExecuteControls();

    console.log('[部分実行] モード開始');
}

// 部分実行モードを終了
function closePartialExecuteMode() {
    partialExecuteMode.active = false;

    // 横棒を削除
    const startBar = document.getElementById('partial-start-bar');
    const endBar = document.getElementById('partial-end-bar');
    const controls = document.getElementById('partial-execute-controls');
    const overlay = document.getElementById('partial-execute-overlay-area');

    if (startBar) startBar.remove();
    if (endBar) endBar.remove();
    if (controls) controls.remove();
    if (overlay) overlay.remove();

    // ノードのハイライトを解除
    clearPartialExecuteHighlight();

    console.log('[部分実行] モード終了');
}

// 紫の横棒を描画
function renderPartialExecuteBars() {
    const container = document.querySelector(`#layer-${leftVisibleLayer} .node-list-container`);
    if (!container) return;

    // 既存のバーを削除
    const existingStart = document.getElementById('partial-start-bar');
    const existingEnd = document.getElementById('partial-end-bar');
    if (existingStart) existingStart.remove();
    if (existingEnd) existingEnd.remove();

    // 開始バー
    const startBar = document.createElement('div');
    startBar.id = 'partial-start-bar';
    startBar.className = 'partial-execute-bar';
    startBar.innerHTML = '<span class="bar-label">▶ 開始</span>';
    startBar.style.cssText = `
        position: absolute;
        left: 0;
        top: ${partialExecuteMode.startY}px;
        width: 100%;
        height: 4px;
        background: linear-gradient(90deg, #3498db, #2980b9);
        cursor: ns-resize;
        z-index: 1000;
        box-shadow: 0 2px 8px rgba(52, 152, 219, 0.5);
    `;
    startBar.querySelector('.bar-label').style.cssText = `
        position: absolute;
        left: 5px;
        top: -18px;
        font-size: 11px;
        color: #2980b9;
        font-weight: bold;
        background: white;
        padding: 2px 6px;
        border-radius: 3px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.2);
    `;

    // 終了バー
    const endBar = document.createElement('div');
    endBar.id = 'partial-end-bar';
    endBar.className = 'partial-execute-bar';
    endBar.innerHTML = '<span class="bar-label">■ 終了</span>';
    endBar.style.cssText = `
        position: absolute;
        left: 0;
        top: ${partialExecuteMode.endY}px;
        width: 100%;
        height: 4px;
        background: linear-gradient(90deg, #2980b9, #3498db);
        cursor: ns-resize;
        z-index: 1000;
        box-shadow: 0 2px 8px rgba(52, 152, 219, 0.5);
    `;
    endBar.querySelector('.bar-label').style.cssText = `
        position: absolute;
        left: 5px;
        top: 6px;
        font-size: 11px;
        color: #2980b9;
        font-weight: bold;
        background: white;
        padding: 2px 6px;
        border-radius: 3px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.2);
    `;

    container.appendChild(startBar);
    container.appendChild(endBar);

    // ドラッグイベントを設定
    setupBarDrag(startBar, 'start');
    setupBarDrag(endBar, 'end');

    // 紫の膜を描画
    updatePartialExecuteOverlay();

    // ハイライトを更新
    updatePartialExecuteHighlight();
}

// 紫の膜（オーバーレイ）を更新
function updatePartialExecuteOverlay() {
    const container = document.querySelector(`#layer-${leftVisibleLayer} .node-list-container`);
    if (!container) return;

    // 既存のオーバーレイを削除
    const existingOverlay = document.getElementById('partial-execute-overlay-area');
    if (existingOverlay) existingOverlay.remove();

    // オーバーレイを作成
    const overlay = document.createElement('div');
    overlay.id = 'partial-execute-overlay-area';

    const top = partialExecuteMode.startY + 4;  // 開始バーの下端から
    const height = partialExecuteMode.endY - partialExecuteMode.startY - 4;  // 終了バーの上端まで

    overlay.style.cssText = `
        position: absolute;
        left: 0;
        top: ${top}px;
        width: 100%;
        height: ${height}px;
        background: linear-gradient(180deg,
            rgba(64, 224, 208, 0.2) 0%,
            rgba(0, 206, 209, 0.15) 50%,
            rgba(64, 224, 208, 0.2) 100%);
        pointer-events: none;
        z-index: 500;
        border-left: 2px solid rgba(0, 206, 209, 0.4);
        border-right: 2px solid rgba(0, 206, 209, 0.4);
    `;

    container.appendChild(overlay);
}

// バーのドラッグを設定
function setupBarDrag(bar, type) {
    let isDragging = false;
    let startMouseY = 0;
    let startBarY = 0;

    bar.addEventListener('mousedown', (e) => {
        isDragging = true;
        startMouseY = e.clientY;
        startBarY = type === 'start' ? partialExecuteMode.startY : partialExecuteMode.endY;
        e.preventDefault();
    });

    document.addEventListener('mousemove', (e) => {
        if (!isDragging) return;

        const container = document.querySelector(`#layer-${leftVisibleLayer} .node-list-container`);
        if (!container) return;

        const containerRect = container.getBoundingClientRect();
        const deltaY = e.clientY - startMouseY;
        let newY = startBarY + deltaY;

        // 範囲制限
        const minY = 0;
        const maxY = container.scrollHeight - 10;
        newY = Math.max(minY, Math.min(maxY, newY));

        // 開始・終了の順序を維持
        if (type === 'start') {
            if (newY < partialExecuteMode.endY - 20) {
                partialExecuteMode.startY = newY;
                bar.style.top = `${newY}px`;
            }
        } else {
            if (newY > partialExecuteMode.startY + 20) {
                partialExecuteMode.endY = newY;
                bar.style.top = `${newY}px`;
            }
        }

        // ハイライトと膜を更新
        updatePartialExecuteHighlight();
        updatePartialExecuteOverlay();
    });

    document.addEventListener('mouseup', () => {
        if (isDragging) {
            isDragging = false;
            // ノード位置にスナップ
            snapBarToNodePosition(type);
            // ノードインデックスを更新
            updatePartialExecuteNodeIndices();
        }
    });
}

// バーをノード位置にスナップ
function snapBarToNodePosition(type) {
    const currentLayerNodes = layerStructure[leftVisibleLayer]?.nodes || [];
    const sortedNodes = [...currentLayerNodes].sort((a, b) => a.y - b.y);

    if (sortedNodes.length === 0) return;

    const bar = document.getElementById(type === 'start' ? 'partial-start-bar' : 'partial-end-bar');
    if (!bar) return;

    const currentY = type === 'start' ? partialExecuteMode.startY : partialExecuteMode.endY;

    // 最も近いノードを探す
    let closestNode = null;
    let closestDistance = Infinity;

    sortedNodes.forEach(node => {
        // 開始バーはノードの上端、終了バーはノードの下端を基準
        const targetY = type === 'start' ? node.y - 5 : node.y + NODE_HEIGHT + 5;
        const distance = Math.abs(currentY - targetY);

        if (distance < closestDistance) {
            closestDistance = distance;
            closestNode = node;
        }
    });

    if (closestNode) {
        // スナップ位置を設定
        const snapY = type === 'start' ? closestNode.y - 5 : closestNode.y + NODE_HEIGHT + 5;

        if (type === 'start') {
            // 終了バーより上にスナップ
            if (snapY < partialExecuteMode.endY - 20) {
                partialExecuteMode.startY = snapY;
                bar.style.top = `${snapY}px`;
            }
        } else {
            // 開始バーより下にスナップ
            if (snapY > partialExecuteMode.startY + 20) {
                partialExecuteMode.endY = snapY;
                bar.style.top = `${snapY}px`;
            }
        }

        // ハイライトと膜を更新
        updatePartialExecuteHighlight();
        updatePartialExecuteOverlay();

        console.log(`[部分実行] ${type}バーをノード「${closestNode.text}」にスナップ: Y=${type === 'start' ? partialExecuteMode.startY : partialExecuteMode.endY}`);
    }
}

// 範囲内のノードをハイライト
function updatePartialExecuteHighlight() {
    const currentLayerNodes = layerStructure[leftVisibleLayer]?.nodes || [];
    const sortedNodes = [...currentLayerNodes].sort((a, b) => a.y - b.y);

    // すべてのノードボタンを取得
    const container = document.querySelector(`#layer-${leftVisibleLayer} .node-list-container`);
    if (!container) return;

    const nodeButtons = container.querySelectorAll('.node-button');

    nodeButtons.forEach(btn => {
        const nodeId = btn.dataset.nodeId;
        const node = sortedNodes.find(n => String(n.id) === nodeId);

        if (node) {
            const nodeY = node.y;
            const nodeBottom = nodeY + 40;

            // バーの範囲内かチェック
            if (nodeY >= partialExecuteMode.startY - 20 && nodeBottom <= partialExecuteMode.endY + 20) {
                // 範囲内: 紫のハイライト
                btn.style.outline = '3px solid rgba(155, 89, 182, 0.7)';
                btn.style.outlineOffset = '-3px';
                btn.style.boxShadow = '0 0 10px rgba(155, 89, 182, 0.4)';
            } else {
                // 範囲外: ハイライト解除
                btn.style.outline = '';
                btn.style.outlineOffset = '';
                btn.style.boxShadow = '';
            }
        }
    });
}

// ハイライトを解除
function clearPartialExecuteHighlight() {
    const container = document.querySelector(`#layer-${leftVisibleLayer} .node-list-container`);
    if (!container) return;

    const nodeButtons = container.querySelectorAll('.node-button');
    nodeButtons.forEach(btn => {
        btn.style.outline = '';
        btn.style.outlineOffset = '';
        btn.style.boxShadow = '';
    });
}

// ノードインデックスを更新
function updatePartialExecuteNodeIndices() {
    const currentLayerNodes = layerStructure[leftVisibleLayer]?.nodes || [];
    const sortedNodes = [...currentLayerNodes].sort((a, b) => a.y - b.y);

    let startIndex = 0;
    let endIndex = sortedNodes.length - 1;

    sortedNodes.forEach((node, index) => {
        const nodeY = node.y;
        const nodeBottom = nodeY + 40;

        if (nodeY >= partialExecuteMode.startY - 20 && startIndex === 0) {
            startIndex = index;
        }
        if (nodeBottom <= partialExecuteMode.endY + 20) {
            endIndex = index;
        }
    });

    partialExecuteMode.startNodeIndex = startIndex;
    partialExecuteMode.endNodeIndex = endIndex;

    // コントロールの表示を更新
    updatePartialExecuteControlsInfo();

    console.log(`[部分実行] 範囲更新: ${startIndex + 1}〜${endIndex + 1}`);
}

// 実行コントロールを表示
function showPartialExecuteControls() {
    // 既存のコントロールを削除
    const existing = document.getElementById('partial-execute-controls');
    if (existing) existing.remove();

    const currentLayerNodes = layerStructure[leftVisibleLayer]?.nodes || [];
    const sortedNodes = [...currentLayerNodes].sort((a, b) => a.y - b.y);

    const controls = document.createElement('div');
    controls.id = 'partial-execute-controls';
    controls.style.cssText = `
        position: fixed;
        bottom: 50px;
        left: 50%;
        transform: translateX(-50%);
        background: white;
        border: 2px solid #3498db;
        border-radius: 8px;
        padding: 12px 20px;
        z-index: 10000;
        box-shadow: 0 4px 20px rgba(52, 152, 219, 0.3);
        display: flex;
        align-items: center;
        gap: 15px;
    `;

    controls.innerHTML = `
        <span style="color: #2980b9; font-weight: bold;">部分実行モード</span>
        <span id="partial-range-info" style="color: #666; font-size: 0.9em;">
            範囲: 1〜${sortedNodes.length}
        </span>
        <button onclick="executePartialCode()" style="
            padding: 8px 20px;
            border: none;
            border-radius: 4px;
            background: linear-gradient(135deg, #3498db, #2980b9);
            color: white;
            cursor: pointer;
            font-weight: bold;
        ">▶ 実行</button>
        <button onclick="closePartialExecuteMode()" style="
            padding: 8px 16px;
            border: 1px solid #ccc;
            border-radius: 4px;
            background: #f5f5f5;
            cursor: pointer;
        ">閉じる</button>
    `;

    document.body.appendChild(controls);
}

// コントロールの情報を更新
function updatePartialExecuteControlsInfo() {
    const info = document.getElementById('partial-range-info');
    if (info) {
        info.textContent = `範囲: ${partialExecuteMode.startNodeIndex + 1}〜${partialExecuteMode.endNodeIndex + 1}`;
    }
}

// 部分実行を実行
async function executePartialCode() {
    if (!partialExecuteMode.active) {
        await showAlertDialog('部分実行モードがアクティブではありません。', 'モード未アクティブ');
        return;
    }

    const startIndex = partialExecuteMode.startNodeIndex;
    const endIndex = partialExecuteMode.endNodeIndex;

    console.log(`[部分実行] 実行開始: インデックス ${startIndex}〜${endIndex}`);

    try {
        // 現在のレイヤーのノードを取得
        const currentLayerNodes = layerStructure[leftVisibleLayer]?.nodes || [];

        // ノードをY座標でソート
        const sortedNodes = [...currentLayerNodes].sort((a, b) => a.y - b.y);

        // 範囲内のノードを抽出
        const selectedNodes = sortedNodes.slice(startIndex, endIndex + 1);

        console.log(`[部分実行] 選択されたノード数: ${selectedNodes.length}個`);
        console.log('[部分実行] 選択されたノード:', selectedNodes.map(n => n.text));

        if (selectedNodes.length === 0) {
            await showAlertDialog('選択された範囲にノードがありません。', '選択エラー');
            return;
        }

        // 送信データを準備
        const requestData = {
            nodes: selectedNodes.map(n => ({
                id: n.id,
                text: n.text,
                color: n.color,
                y: n.y,
                処理番号: n.処理番号,
                script: n.script || ''
            })),
            outputPath: null,
            openFile: false,
            partialExecution: true,
            startLine: startIndex + 1,
            endLine: endIndex + 1
        };

        console.log('[部分実行] API送信データ:', JSON.stringify(requestData, null, 2));

        // APIを呼び出し
        const result = await callApi('/execute/generate', 'POST', requestData);

        if (result.success) {
            console.log(`✅ [部分実行] 成功 - ノード数: ${result.nodeCount}個, コード長: ${result.code?.length || 0}文字`);

            // PowerShell Windows Formsでコード結果を表示
            try {
                const showResultResponse = await fetch(`${API_BASE}/code-result/show`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        code: result.code,
                        nodeCount: result.nodeCount,
                        outputPath: result.outputPath,
                        timestamp: new Date().toLocaleString('ja-JP'),
                        partialExecution: true,
                        range: `${startIndex + 1}〜${endIndex + 1}`
                    })
                });

                const showResultData = await showResultResponse.json();

                if (showResultData.success) {
                    console.log('✅ [部分実行] コード結果ダイアログを表示しました');
                } else {
                    console.error('❌ [部分実行] コード結果ダイアログ表示エラー:', showResultData.error);
                }
            } catch (error) {
                console.error('❌ [部分実行] コード結果ダイアログ表示エラー:', error);
            }
        } else {
            console.error(`❌ [部分実行] 失敗: ${result.error}`);
            await showAlertDialog(`部分実行失敗: ${result.error}`, '部分実行失敗');
        }
    } catch (error) {
        console.error('❌ [部分実行] エラー:', error);
        await showAlertDialog(`部分実行中にエラーが発生しました: ${error.message}`, 'エラー');
    }
}

// ============================================
// コード結果モーダル（PowerShell Windows Forms版に移行）
// ============================================

function closeCodeResultModal() {
    console.log('[コード結果] closeCodeResultModal() は廃止されました（PowerShell Windows Forms版に移行）');
}

function copyGeneratedCode() {
    console.log('[コード結果] copyGeneratedCode() は廃止されました（PowerShell Windows Forms版に移行）');
    console.log('[コード結果] コピー機能はPowerShellダイアログ内のボタンで実行されます');
}

function openGeneratedFile() {
    console.log('[コード結果] openGeneratedFile() は廃止されました（PowerShell Windows Forms版に移行）');
    console.log('[コード結果] ファイルを開く機能はPowerShellダイアログ内のボタンで実行されます');
    if (window.lastGeneratedCode && window.lastGeneratedCode.path) {
        // PowerShellでファイルを開く（Windows環境）
        showAlertDialog(`ファイルを開きます: ${window.lastGeneratedCode.path}\n\n（この機能はブラウザ制限により未実装です）`, 'ファイル操作');
    } else {
        showAlertDialog('出力ファイルのパスが見つかりません。', 'エラー');
    }
}

// ============================================
// スナップショット機能
// ============================================

async function createSnapshot() {
    console.log('[スナップショット] 作成開始');

    if (!currentFolder) {
        await showAlertDialog('フォルダが選択されていません。\n先にフォルダを選択または作成してください。', 'フォルダ未選択');
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

        await showAlertDialog(`📸 スナップショット作成完了\n\n作成日時: ${timestampJP}\nフォルダ: ${currentFolder}\n\n「↩️ 復元」ボタンでこの状態に戻すことができます。`, 'スナップショット完了');

    } catch (error) {
        console.error('[スナップショット] ❌ エラー:', error);
        await showAlertDialog(`スナップショット作成中にエラーが発生しました:\n${error.message}`, 'エラー');
    }
}

async function restoreSnapshot() {
    console.log('[スナップショット復元] 開始');

    if (!currentFolder) {
        await showAlertDialog('フォルダが選択されていません。\n先にフォルダを選択してください。', 'フォルダ未選択');
        return;
    }

    try {
        const storageKey = `snapshot_${currentFolder}`;
        const infoKey = `snapshot_info_${currentFolder}`;

        // スナップショット存在確認
        const snapshotData = localStorage.getItem(storageKey);
        if (!snapshotData) {
            await showAlertDialog('スナップショットが存在しません。\n\n先に「📸 スナップショット」ボタンで現在の状態を保存してください。', 'スナップショット未保存');
            console.log('[スナップショット復元] スナップショット未保存');
            return;
        }

        // スナップショット情報を取得
        const snapshotInfoData = localStorage.getItem(infoKey);
        const snapshotInfo = snapshotInfoData ? JSON.parse(snapshotInfoData) : null;
        const snapshotDate = snapshotInfo ? snapshotInfo.作成日時 : '不明';

        console.log(`[スナップショット復元] スナップショット作成日時: ${snapshotDate}`);

        // 確認ダイアログ（PowerShell版と同じ）
        const confirmed = await showConfirmDialog(
            `スナップショットの状態に復元します。\n\n` +
            `スナップショット作成日時: ${snapshotDate}\n` +
            `フォルダ: ${currentFolder}\n\n` +
            `現在の変更は失われますがよろしいですか？`,
            'スナップショット復元確認'
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

        await showAlertDialog(`復元完了\n\nスナップショットから復元しました。\n\n復元日時: ${snapshotDate}`, '復元完了');

    } catch (error) {
        console.error('[スナップショット復元] ❌ エラー:', error);
        await showAlertDialog(`スナップショット復元中にエラーが発生しました:\n${error.message}`, 'エラー');
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
            layerStructure[i].edges = [];  // v1.1.0: エッジもクリア
        }

        // memory.jsonからノードを復元
        console.log('┌─ [memory.json復元] 開始 ─────────────────────');
        for (let layerNum = 1; layerNum <= 6; layerNum++) {
            const layerData = memoryData[layerNum.toString()];
            if (!layerData || !layerData.構成) continue;

            layerData.構成.forEach((nodeData, index) => {
                // IDが保存されていればそれを使用、なければボタン名またはレイヤー+インデックスから生成
                let nodeId;
                if (nodeData.ID) {
                    // 新形式: IDフィールドがある
                    nodeId = nodeData.ID;
                    console.log(`│ [L${layerNum}] ノード${index + 1}: ID復元 = ${nodeId}`);
                } else if (nodeData.ボタン名 && nodeData.ボタン名.includes('-')) {
                    // 旧形式互換: ボタン名が「13-1」などのID形式の場合はそれを使用
                    nodeId = nodeData.ボタン名;
                    console.log(`│ [L${layerNum}] ノード${index + 1}: ボタン名からID復元 = ${nodeId}`);
                } else {
                    // ID形式を addSingleNode と統一（数値-1 形式）
                    const newIdNum = nodeCounter++;
                    nodeId = `${newIdNum}-1`;
                    console.log(`│ [L${layerNum}] ノード${index + 1}: ID新規生成 = ${nodeId} (⚠️ IDフィールドなし)`);
                }

                // デバッグ: Pinkノードのscript内容を詳細出力
                if (nodeData.ボタン色 === 'Pink') {
                    console.log(`│   ★ Pinkノード検出: テキスト="${nodeData.テキスト}"`);
                    console.log(`│   ★ script内容: "${nodeData.script || '(空)'}"`);
                    console.log(`│   ★ nodeData全体:`, JSON.stringify(nodeData, null, 2));
                }

                const node = {
                    id: nodeId,
                    name: nodeData.ボタン名 || '',
                    text: nodeData.テキスト || '',
                    color: nodeData.ボタン色 || 'White',
                    layer: layerNum,
                    y: nodeData.Y座標 || 10,
                    x: nodeData.X座標 || 10,
                    width: nodeData.幅 || NODE_WIDTH,
                    height: nodeData.高さ || NODE_HEIGHT,
                    groupId: nodeData.GroupID || null,
                    userGroupId: nodeData.userGroupId || null,  // ユーザーグループID
                    処理番号: nodeData.処理番号 || '',
                    script: nodeData.script || '',
                    関数名: nodeData.関数名 || ''
                };

                nodes.push(node);
                layerStructure[layerNum].nodes.push(node);
            });

            // v1.1.0: エッジデータを復元
            if (layerData.edges && Array.isArray(layerData.edges)) {
                layerStructure[layerNum].edges = layerData.edges;
                if (layerData.edges.length > 0) {
                    console.log(`│ [L${layerNum}] エッジ復元: ${layerData.edges.length}本`);
                }
            }
        }
        console.log('└─ [memory.json復元] 完了 ─────────────────────');

        // nodeCounter を更新（既存ノードの最大ID + 1）
        let needsSave = false;
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

        // v1.1.0: conditionGroupCounter と loopGroupCounter も更新（エッジのgroupIdから）
        for (let layerNum = 0; layerNum <= 6; layerNum++) {
            const layerEdges = layerStructure[layerNum]?.edges || [];
            layerEdges.forEach(edge => {
                if (edge.groupId && typeof edge.groupId === 'number') {
                    // 条件分岐用（2000番台）
                    if (edge.groupId >= 2000 && edge.groupId < 3000) {
                        if (edge.groupId >= conditionGroupCounter) {
                            conditionGroupCounter = edge.groupId + 1;
                        }
                    }
                    // ループ用（1000番台）
                    else if (edge.groupId >= 1000 && edge.groupId < 2000) {
                        if (edge.groupId >= loopGroupCounter) {
                            loopGroupCounter = edge.groupId + 1;
                        }
                    }
                }
            });
        }
        console.log(`[memory.json読み込み] conditionGroupCounter を ${conditionGroupCounter}, loopGroupCounter を ${loopGroupCounter} に更新しました`);

        // ユーザーグループを復元
        if (memoryData.userGroups) {
            restoreUserGroups(memoryData.userGroups);
        } else {
            // userGroupsが保存されていない場合はクリア
            userGroups = {};
            userGroupCounter = 3000;
        }

        // IDフィールドがなかった場合は、新しいIDでmemory.jsonを再保存
        // これにより、次回起動時にIDが維持される
        for (let layerNum = 1; layerNum <= 6; layerNum++) {
            const layerData = memoryData[layerNum.toString()];
            if (!layerData || !layerData.構成) continue;
            layerData.構成.forEach((nodeData) => {
                if (!nodeData.ID) {
                    needsSave = true;
                }
            });
        }
        if (needsSave && !isRestoringHistory) {
            console.log('[memory.json復元] IDフィールドがないノードがあるため、memory.jsonを再保存します');
            // 非同期で保存（await不要、バックグラウンドで実行）
            setTimeout(() => saveMemoryJson(), 500);
        } else if (needsSave && isRestoringHistory) {
            console.log('[memory.json復元] Undo/Redo実行中のため、自動保存をスキップします');
        }

        // 左パネルのみを再描画（起動時は右パネルを非表示）
        renderNodesInLayer(leftVisibleLayer, 'left');
        // 右パネル（ドリルダウンパネル）は起動時は非表示（スクリプト展開時のみ表示）
        const rightPanel = document.getElementById('right-layer-panel');
        if (rightPanel) {
            rightPanel.classList.add('empty');
            rightPanel.innerHTML = '';
        }
        console.log(`memory.jsonから${nodes.length}個のノードを復元しました`);
        console.log(`[表示] 左パネル: レイヤー${leftVisibleLayer}, 右パネル: 非表示（起動時）`);
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

        console.log('┌─ [memory.json保存] 開始 ─────────────────────');
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
                nodes: nodesWithIndex,
                edges: layerStructure[i].edges || []  // v1.1.0: エッジデータを保存
            };

            // デバッグ: エッジ情報を出力
            const layerEdges = layerStructure[i].edges || [];
            if (layerEdges.length > 0) {
                console.log(`│ [L${i}] エッジ数: ${layerEdges.length}`);
            }

            // デバッグ: Pinkノードの情報を出力
            nodesWithIndex.forEach(node => {
                if (node.color === 'Pink') {
                    console.log(`│ [L${i}] Pinkノード保存: ID=${node.id}, script="${node.script || '(空)'}"`);
                }
            });
        }
        console.log('└─ [memory.json保存] API呼び出し ────────────────');

        // ユーザーグループ情報も含める
        const saveData = {
            layerStructure: formattedLayerStructure,
            userGroups: getUserGroupsForSave()
        };

        const response = await fetch(`${API_BASE}/folders/${currentFolder}/memory`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(saveData)
        });

        const result = await response.json();

        if (result.success) {
            console.log('memory.json保存成功:', result.message);

            // Undo/Redoボタンの状態を更新
            await updateUndoRedoButtons();
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
            // デバッグ: コード.jsonのエントリ一覧を出力
            console.log('┌─ [コード.json読み込み] 成功 ─────────────────');
            console.log('│ エントリ数:', Object.keys(codeData["エントリ"]).length);
            console.log('│ 最後のID:', codeData["最後のID"]);
            console.log('│ エントリキー一覧:', Object.keys(codeData["エントリ"]).join(', '));
            // 各エントリの先頭50文字を出力
            Object.entries(codeData["エントリ"]).forEach(([key, value]) => {
                const preview = value ? value.substring(0, 50).replace(/\r?\n/g, '\\n') : '(空)';
                console.log(`│   [${key}]: "${preview}${value && value.length > 50 ? '...' : ''}"`);
            });
            console.log('└─────────────────────────────────────────────');
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

// ノード設定（PowerShell Windows Forms版）
async function openNodeSettings(node) {
    if (LOG_CONFIG.scriptDebug) console.log('✅ [ノード設定] モーダルを開く:', node.text, 'ID:', node.id);

    // ノードIDで最新の情報を取得（layerStructureから）
    let actualNode = null;
    for (let layer = 1; layer <= 6; layer++) {
        const found = layerStructure[layer].nodes.find(n => n.id === node.id);
        if (found) {
            actualNode = found;
            break;
        }
    }

    if (!actualNode) {
        console.error('❌ [ノード設定] ノードIDが見つかりません:', node.id);
        await showAlertDialog('ノード情報が見つかりませんでした。', 'ノード未検出');
        return;
    }

    // コード.jsonからスクリプトを取得
    let scriptContent = getCodeEntry(actualNode.id);

    // Pinkノードの場合、コード.jsonにエントリがなければscriptプロパティから子ノード情報を使用
    if (!scriptContent && actualNode.color === 'Pink' && actualNode.script) {
        if (LOG_CONFIG.scriptDebug) console.log('✅ [ノード設定] Pinkノード: scriptプロパティから子ノード情報を取得');
        // Pinkノードのscriptは子ノードのメタ情報（ID;色;テキスト;groupId）
        // これをAAA形式に変換してダイアログに表示
        scriptContent = 'AAAA\n' + actualNode.script.replace(/_/g, '\n');
    }

    // 関数ノード（Aquamarine）の場合、scriptプロパティから子ノード情報を見やすく整形して表示
    if ((actualNode.color === 'Aquamarine' || isAquamarineColor(actualNode.color)) && actualNode.script) {
        if (LOG_CONFIG.scriptDebug) console.log('✅ [ノード設定] 関数ノード: scriptプロパティから子ノード情報を取得');
        // 関数ノードのscriptは子ノードのメタ情報（ID;色;テキスト;groupId）
        // 見やすく整形して表示
        const nodeList = actualNode.script.split('_');
        const formattedList = nodeList.map((entry, index) => {
            const parts = entry.split(';');
            if (parts.length >= 3) {
                const nodeId = parts[0];
                const color = parts[1];
                const text = parts[2];
                return `[${index + 1}] ${text} (${color})`;
            }
            return entry;
        }).join('\n');
        scriptContent = `=== 関数に含まれるノード ===\n\n${formattedList}\n\n=== 元データ ===\n${actualNode.script.replace(/_/g, '\n')}`;
    }

    if (LOG_CONFIG.scriptDebug) console.log('✅ [ノード設定] スクリプト取得:', scriptContent ? scriptContent.length : 0, '文字');

    // リクエストボディを作成
    const requestBody = {
        nodeId: actualNode.id,
        nodeName: actualNode.text,
        color: actualNode.color || 'White',
        width: actualNode.width || 120,
        height: actualNode.height || NODE_HEIGHT,
        x: actualNode.x || 10,
        y: actualNode.y || 10,
        script: scriptContent || '',
        処理番号: actualNode.処理番号 || ''
    };

    // カスタムフィールドを追加
    if (actualNode.conditionExpression) {
        requestBody.conditionExpression = actualNode.conditionExpression;
    }
    if (actualNode.loopCount) {
        requestBody.loopCount = actualNode.loopCount;
    }
    if (actualNode.loopVariable) {
        requestBody.loopVariable = actualNode.loopVariable;
    }

    if (LOG_CONFIG.scriptDebug) console.log('✅ [ノード設定] APIリクエストボディ:', JSON.stringify(requestBody, null, 2));

    try {
        // PowerShell Windows Formsダイアログを呼び出し（ダイアログ用に長めのタイムアウト）
        if (LOG_CONFIG.scriptDebug) console.log('✅ [ノード設定] PowerShell設定ダイアログを呼び出します...');
        const result = await callApi('/node/settings', 'POST', requestBody, { timeout: 600000 });

        // HTTPエラーの場合
        if (result._httpStatus) {
            console.error('❌ [ノード設定] サーバーエラー:', result);
            await showAlertDialog(`サーバーエラー (${result._httpStatus}): ${result.error || result._httpStatusText}`, 'サーバーエラー');
            return;
        }

        if (result.cancelled) {
            return;
        }

        if (result.success && result.settings) {
            if (LOG_CONFIG.scriptDebug) console.log('✅ [ノード設定] 編集完了:', result.settings);

            // ノード情報を更新
            actualNode.text = result.settings.text;
            actualNode.color = result.settings.color;
            actualNode.width = result.settings.width;
            actualNode.height = result.settings.height;
            actualNode.x = result.settings.x;
            actualNode.y = result.settings.y;

            // カスタムフィールドを更新
            if (result.settings.conditionExpression !== undefined) {
                actualNode.conditionExpression = result.settings.conditionExpression;
            }
            if (result.settings.loopCount !== undefined) {
                actualNode.loopCount = result.settings.loopCount;
            }
            if (result.settings.loopVariable !== undefined) {
                actualNode.loopVariable = result.settings.loopVariable;
            }

            // スクリプトをコード.jsonに保存
            await setCodeEntry(actualNode.id, result.settings.script);

            // 画面を再描画
            renderNodesInLayer(leftVisibleLayer);
            await saveMemoryJson();
        }

    } catch (error) {
        console.error('❌ [ノード設定] エラー:', error);
        await showAlertDialog(`ノード設定中にエラーが発生しました: ${error.message}`, 'エラー');
    }
}

function closeNodeSettingsModal() {
    // Web UIモーダルは廃止（PowerShell Windows Forms版を使用）
}

async function saveNodeSettings() {
    // Web UIモーダルは廃止（PowerShell Windows Forms版を使用）
}

// ============================================
// 同色ノード衝突チェック
// ============================================

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

// ============================================
// 同じグループ内のノード順序違反チェック
// ============================================

/**
 * 同じgroupId内のノードの順序を保つためのチェック
 * 条件分岐やループのグループ内で、ノードが他のメンバーをまたぐことを禁止する
 */
function checkGroupOrderViolation(movingNode, currentY, newY) {
    // groupIdを持たないノードはチェック不要
    if (!movingNode.groupId) {
        return false;
    }

    const layerNodes = layerStructure[leftVisibleLayer].nodes;
    const groupId = movingNode.groupId;

    // 同じgroupIdを持つすべてのノードを取得
    const sameGroupNodes = layerNodes.filter(n =>
        n.groupId !== null &&
        n.groupId !== undefined &&
        n.groupId.toString() === groupId.toString()
    );

    // グループが1つのノードしか持たない場合はチェック不要
    if (sameGroupNodes.length <= 1) {
        return false;
    }

    // Y座標でソート
    const sortedNodes = sameGroupNodes.sort((a, b) => a.y - b.y);

    // 移動中のノードの現在の順序位置を取得
    const currentIndex = sortedNodes.findIndex(n => n.id === movingNode.id);
    if (currentIndex === -1) {
        return false;
    }

    // 移動範囲を計算
    const minY = Math.min(currentY, newY);
    const maxY = Math.max(currentY, newY);

    // 同じグループ内の他のノードをまたぐかチェック
    for (let i = 0; i < sortedNodes.length; i++) {
        const node = sortedNodes[i];

        // 自分自身はスキップ
        if (node.id === movingNode.id) continue;

        // 他のノードが移動範囲内に存在する場合、順序違反
        if (node.y > minY && node.y < maxY) {
            console.log(`[グループ順序違反] ノード "${movingNode.text}" (groupId=${groupId}) が同じグループ内のノード "${node.text}" をまたぐため禁止`);
            return true;
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
    // 1. グループ分断チェック
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
    // 2. グループ全体としての整合性チェック
    // ============================

    let groupCheckPassed = false;

    if (isGreen && movingNode.groupId) {
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
            // グループ全体のチェックをパスした
            groupCheckPassed = true;
        }
    }

    if (isYellow && movingNode.groupId) {
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
            // グループ全体のチェックをパスした
            groupCheckPassed = true;
        }
    }

    // ============================
    // 3. 単体ノードチェック（グループチェックをパスしなかった場合のみ）
    // ============================

    if (!groupCheckPassed) {
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
            showAlertDialog('memory.json を保存しました', '保存完了');
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
            showAlertDialog('Undo機能は将来実装予定です', '未実装');
            return;
        }

        // Ctrl+Y: Redo（将来機能）
        if (e.key === 'y' && e.ctrlKey && !e.shiftKey && !e.altKey) {
            e.preventDefault();
            showAlertDialog('Redo機能は将来実装予定です', '未実装');
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
                showAlertDialog('条件式が設定されていません。', '入力エラー');
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
                showAlertDialog('ループ構文が設定されていません。', '入力エラー');
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
 * @param {number} timeoutMs - タイムアウト時間（ミリ秒、デフォルト5分）
 * @returns {Promise<string>} - 生成されたコード
 */
async function executeNodeFunction(functionName, params = {}, timeoutMs = 300000) {
    try {
        console.log(`[ノード関数実行] 関数: ${functionName}, パラメータ:`, params);

        // AbortControllerで長いタイムアウトを設定（ダイアログ操作対応）
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

        try {
            const response = await fetch(`${API_BASE}/node/execute/${functionName}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(params),
                signal: controller.signal
            });

            clearTimeout(timeoutId);

            // 408 Request Timeout の特別処理
            if (response.status === 408) {
                console.error(`[ノード関数実行] ⚠ サーバータイムアウト (408)`);
                console.error(`[ノード関数実行] ダイアログ操作に時間がかかりすぎた可能性があります`);
                throw new Error('サーバータイムアウト: ダイアログ操作を30秒以内に完了してください。server.psd1でタイムアウト時間を延長できます。');
            }

            // レスポンスボディを先にテキストとして読み取る（空レスポンス対策）
            const responseText = await response.text();

            // 空レスポンスの場合のエラーハンドリング
            if (!responseText || responseText.trim() === '') {
                console.error(`[ノード関数実行] ⚠ 空のレスポンスを受信しました`);
                throw new Error(`空のレスポンス: サーバーが応答を返しませんでした (HTTP ${response.status})`);
            }

            // JSONパース（エラーハンドリング付き）
            let result;
            try {
                result = JSON.parse(responseText);
            } catch (parseError) {
                console.error(`[ノード関数実行] ⚠ JSONパースエラー:`, parseError);
                console.error(`[ノード関数実行] 受信したテキスト (先頭200文字):`, responseText.substring(0, 200));
                throw new Error(`JSONパースエラー: サーバーからの応答が不正です`);
            }

            if (!response.ok) {
                console.error(`[ノード関数実行] サーバーエラー詳細:`, result);
                if (result.error) {
                    console.error(`[ノード関数実行] エラーメッセージ: ${result.error}`);
                }
                if (result.stackTrace) {
                    console.error(`[ノード関数実行] スタックトレース:\n${result.stackTrace}`);
                }
                throw new Error(`API Error: ${response.status} - ${result.error || response.statusText}`);
            }

            // キャンセルされた場合はnullを返す（エラーではない）
            if (result.cancelled) {
                console.log(`[ノード関数実行] ユーザーがキャンセルしました`);
                return null;
            }

            if (result.success && result.code) {
                console.log(`[ノード関数実行] 成功 - コード長: ${result.code.length}文字`);
                return result.code;
            } else {
                throw new Error(result.error || '不明なエラー');
            }
        } catch (fetchError) {
            clearTimeout(timeoutId);
            if (fetchError.name === 'AbortError') {
                throw new Error(`クライアントタイムアウト: ${timeoutMs / 1000}秒を超えました`);
            }
            throw fetchError;
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
// 🔄 移行完了: ShowConditionBuilder/ShowLoopBuilder は削除（PowerShell版に移行）
const codeGeneratorFunctions = {
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
                // 通常処理
                entryString = await generatorFunc();
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

        // JSONレスポンスの処理（条件分岐ダイアログ対応）
        // 形式: {"branchCount": N, "code": "..."}
        let codeToSave = entryString;
        try {
            if (typeof entryString === 'string' && entryString.startsWith('{')) {
                const parsed = JSON.parse(entryString);
                if (parsed.code) {
                    // JSONの場合はcodeフィールドのみを保存
                    codeToSave = parsed.code;
                    console.log(`[コード生成] JSONレスポンスからコードを抽出: branchCount=${parsed.branchCount}`);
                }
            }
        } catch (e) {
            // JSONパース失敗時はそのまま使用
            console.log(`[コード生成] JSONパース失敗、元の値をそのまま使用`);
        }

        // コード.jsonに保存
        console.log(`[コード生成] コード.jsonに保存します - ノードID: ${ノードID}`);
        await setCodeEntry(ノードID, codeToSave);

        console.log(`[コード生成] 成功: ノードID ${ノードID} に保存しました`);
        return entryString;  // 呼び出し元にはJSONを含む元の値を返す
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
                showAlertDialog('最低一つの条件が必要です。', '削除不可');
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
                    <input type="text" id="loop-end-value" value="1" style="flex: 1; padding: 5px;">
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
            : document.getElementById('loop-end-value')?.value || '1';
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

// パンくずリストを左パネルの現在レイヤーに合わせて更新
function updateBreadcrumbForLayer(layer) {
    console.log(`[パンくずリスト] 🔄 updateBreadcrumbForLayer(${layer}) 呼び出し - leftVisibleLayer=${leftVisibleLayer}`);
    console.log(`[パンくずリスト] 更新前:`, breadcrumbStack.map(b => `L${b.layer}:${b.name}`).join(' → '));

    breadcrumbStack = [];

    for (let i = 1; i <= layer; i++) {
        breadcrumbStack.push({
            name: i === 1 ? 'メインフロー' : `レイヤー${i}`,
            layer: i
        });
    }

    console.log(`[パンくずリスト] 更新後:`, breadcrumbStack.map(b => `L${b.layer}:${b.name}`).join(' → '));

    renderBreadcrumb();
}

// パンくずリストを描画
function renderBreadcrumb() {
    console.log(`[パンくずリスト] 🎨 renderBreadcrumb() 呼び出し`);
    console.log(`[パンくずリスト] 現在のスタック:`, breadcrumbStack.map(b => `L${b.layer}:${b.name}`).join(' → '));

    const breadcrumb = document.getElementById('breadcrumb');
    if (!breadcrumb) return;

    breadcrumb.innerHTML = '';

    breadcrumbStack.forEach((item, index) => {
        const breadcrumbItem = document.createElement('div');
        breadcrumbItem.className = 'breadcrumb-item';
        breadcrumbItem.dataset.layer = item.layer;
        breadcrumbItem.textContent = index === 0 ? '📍 ' + item.name : item.name;

        if (index === breadcrumbStack.length - 1) {
            breadcrumbItem.classList.add('current');
        }

        // クリックイベント
        if (index < breadcrumbStack.length - 1) {
            breadcrumbItem.style.cursor = 'pointer';
            breadcrumbItem.addEventListener('click', () => {
                navigateToBreadcrumbLayer(item.layer, index);
            });
        }

        breadcrumb.appendChild(breadcrumbItem);

        // セパレータ追加（縦展開用）
        if (index < breadcrumbStack.length - 1) {
            const separator = document.createElement('div');
            separator.className = 'breadcrumb-separator';
            separator.textContent = '↓';
            breadcrumb.appendChild(separator);
        }
    });

    if (LOG_CONFIG.breadcrumb) {
        console.log('[パンくずリスト] 描画完了:', breadcrumbStack.map(b => b.name).join(' ↓ '));
    }
}

// パンくずリストからレイヤーに移動
function navigateToBreadcrumbLayer(targetLayer, targetIndex) {
    if (LOG_CONFIG.breadcrumb) {
        console.log(`[パンくずナビゲーション] レイヤー${targetLayer}に移動、インデックス${targetIndex}`);
    }

    // 🔍 デバッグ: パンくずナビゲーション前のlayerStructure全体の状態を出力
    console.log(`[パンくずナビゲーション] 🔍 ナビゲーション前のlayerStructure全体:`);
    for (let i = 0; i <= 6; i++) {
        const layerNodeIds = layerStructure[i].nodes.map(n => `${n.id}(${n.text})`).join(', ');
        console.log(`🔍   L${i}: [${layerNodeIds}] (${layerStructure[i].nodes.length}個)`);
    }

    // スタックを切り詰め
    breadcrumbStack = breadcrumbStack.slice(0, targetIndex + 1);

    // ドリルダウンパネルを閉じる（オーバーレイ版を終了）
    if (drilldownState.active) {
        const rightPanel = document.getElementById('right-layer-panel');
        const leftPanel = document.getElementById('left-layer-panel');
        const escHint = document.getElementById('escHint');

        // 右パネルをクリア（アニメーションなし）
        if (rightPanel) {
            rightPanel.classList.add('empty');
            rightPanel.innerHTML = '';
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
    }

    // メインパネル表示に切り替え（左パネルのみ）
    leftVisibleLayer = targetLayer;

    // 右パネルをリセット（スクリプト展開が解除されるため）
    const rightPanel = document.getElementById('right-layer-panel');
    if (rightPanel) {
        rightPanel.classList.add('empty');
        rightPanel.innerHTML = '';
    }

    if (LOG_CONFIG.breadcrumb) {
        console.log(`[パンくずナビゲーション] メインパネル表示に切り替え - 左: L${leftVisibleLayer}, 右パネル: リセット`);
    }

    // パンくずリストを更新
    renderBreadcrumb();

    // デュアルパネル表示を更新
    updateDualPanelDisplay();

    // 画面を再描画（左パネルのみ）
    renderNodesInLayer(leftVisibleLayer, 'left');

    // 矢印を再描画
    refreshAllArrows();
}

// ホバープレビューのセットアップ
function setupHoverPreview() {
    if (LOG_CONFIG.pink) {
        console.log('[ホバープレビュー] setupHoverPreview初期化開始');
    }

    // 全てのピンクノードにホバーイベントを設定
    document.addEventListener('mouseenter', (e) => {
        if (e.target && e.target.classList && e.target.classList.contains('node-button')) {
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
        if (e.target && e.target.classList && e.target.classList.contains('node-button')) {
            if (LOG_CONFIG.pink) {
                console.log(`[ホバープレビュー] ノードからマウスリーブ: ${e.target.dataset.nodeId}, タイマーID: ${hoverTimer}`);
            }
            clearTimeout(hoverTimer);
            if (LOG_CONFIG.pink) {
                console.log(`[ホバープレビュー] ⏹️ タイマークリア実行 (mouseleave)`);
            }
            hidePreview();
        }
    }, true);

    // プレビューパネルのDOM変更を監視
    const previewElement = document.getElementById('hoverPreview');
    if (previewElement && LOG_CONFIG.pink) {
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                if (mutation.type === 'attributes' && mutation.attributeName === 'class') {
                    const classList = previewElement.classList;
                    const hasShow = classList.contains('show');
                    console.log(`[ホバープレビュー] 🔶 DOM変更検出: showクラス=${hasShow}, 全クラス=[${previewElement.className}]`);
                    console.log(`[ホバープレビュー] 🔶 変更時スタックトレース:`);
                    console.trace();
                }
            });
        });
        observer.observe(previewElement, { attributes: true, attributeFilter: ['class'] });
        console.log('[ホバープレビュー] 🔶 DOM変更監視を開始しました');
    }

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

    // ★ アクティブ状態をチェック（レイヤー編集後の古いピンクノードはプレビューを表示しない）
    const layer = nodeData.layer;
    const isActive = pinkSelectionArray[layer].expandedNode === nodeData.id;

    if (LOG_CONFIG.pink) {
        console.log(`[ホバープレビュー] アクティブ状態チェック - layer: ${layer}, expandedNode: ${pinkSelectionArray[layer].expandedNode}, nodeData.id: ${nodeData.id}, isActive: ${isActive}`);
    }

    if (!isActive) {
        if (LOG_CONFIG.pink) {
            console.log(`[ホバープレビュー] ⚠️ 非アクティブなピンクノードのため、プレビューを表示しません`);
        }
        return;
    }

    // 0.8秒後にプレビュー表示
    hoverTimer = setTimeout(() => {
        if (LOG_CONFIG.pink) {
            console.log(`[ホバープレビュー] ⏰ タイマー発火 - 0.8秒経過、showPreview呼び出し (タイマーID: ${hoverTimer})`);
        }
        showPreview(event, nodeData);
    }, 800);
    if (LOG_CONFIG.pink) {
        console.log(`[ホバープレビュー] ⏱️ タイマー設定完了 - タイマーID: ${hoverTimer}, ノード: ${nodeData.text}`);
    }
}

// プレビュー表示
function showPreview(event, nodeData) {
    if (LOG_CONFIG.pink) {
        console.log(`[ホバープレビュー] 🔴 showPreview開始 - nodeData.text: ${nodeData.text}, layer: ${nodeData.layer}`);
        console.log(`[ホバープレビュー] 🔴 呼び出し元スタックトレース:`);
        console.trace();
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
    if (LOG_CONFIG.pink) {
        console.log(`[ホバープレビュー] 🟢 showクラスを追加します - 現在のクラス: ${preview.className}`);
    }
    preview.classList.add('show');
    if (LOG_CONFIG.pink) {
        console.log(`[ホバープレビュー] 🟢 showクラス追加完了 - 新しいクラス: ${preview.className}`);
        console.log(`[ホバープレビュー] プレビュー表示完了 - 位置: (${preview.style.left}, ${preview.style.top})`);
    }
}

// プレビュー非表示
function hidePreview() {
    if (LOG_CONFIG.pink) {
        console.log('[ホバープレビュー] 🔵 hidePreview呼び出し');
        console.log('[ホバープレビュー] 🔵 呼び出し元スタックトレース:');
        console.trace();
    }
    const preview = document.getElementById('hoverPreview');
    if (preview) {
        const hadShowClass = preview.classList.contains('show');
        preview.classList.remove('show');
        if (LOG_CONFIG.pink) {
            console.log(`[ホバープレビュー] プレビュー非表示実行 - showクラスあり: ${hadShowClass}`);
        }
    } else {
        if (LOG_CONFIG.pink) {
            console.log('[ホバープレビュー] プレビュー要素が見つかりません');
        }
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

    // 右パネルにプレビュー表示（ドリルダウンはプレビュー機能なのでパンくずは更新しない）
    const nextLayer = nodeData.layer + 1;
    const expandedNodes = layerStructure[nextLayer]?.nodes || [];
    showLayerInDrilldownPanel(nodeData, expandedNodes);

    if (LOG_CONFIG.pink) {
        console.log(`[ピンクノードドリルダウン] 右パネルプレビュー表示: レイヤー${nextLayer}`);
    }
}

// ドリルダウンパネルにレイヤーを表示
function showLayerInDrilldownPanel(parentNodeData) {
    // デバッグ：本当にこの関数が呼ばれているか確認
    window.DRILLDOWN_CALLED = (window.DRILLDOWN_CALLED || 0) + 1;
    console.warn(`🔍🔍🔍 [ドリルダウン] showLayerInDrilldownPanel() 呼び出し回数: ${window.DRILLDOWN_CALLED}`);
    console.error(`🔍🔍🔍 [ドリルダウン] 親ノード: L${parentNodeData?.layer} "${parentNodeData?.text}"`);

    console.log(`🔍 [ドリルダウン] 🔷 showLayerInDrilldownPanel() 呼び出し - 親ノード: L${parentNodeData.layer} "${parentNodeData.text}"`);
    console.log(`🔍 [ドリルダウン] leftVisibleLayer=${leftVisibleLayer}`);
    console.log(`🔍 [ドリルダウン] 現在のbreadcrumbStack:`, breadcrumbStack.map(b => `L${b.layer}:${b.name}`).join(' → '));

    const rightPanel = document.getElementById('right-layer-panel');
    if (!rightPanel) {
        console.log(`🔍 [ドリルダウン] ❌ right-layer-panel が見つかりません`);
        return;
    }

    const targetLayer = parentNodeData.layer + 1;

    // layerStructureから正しくノードを取得（既存ロジックと同じ）
    const layerNodes = layerStructure[targetLayer] && layerStructure[targetLayer].nodes
        ? layerStructure[targetLayer].nodes
        : [];

    console.log(`🔍 [ドリルダウン] レイヤー${targetLayer}のノード数: ${layerNodes.length}`);
    if (layerNodes.length > 0) {
        console.log(`🔍 [ドリルダウン] 最初のノード:`, layerNodes[0]);
    }

    // 空状態を解除
    rightPanel.classList.remove('empty');

    // アニメーションクラス追加
    rightPanel.classList.add('slide-in');

    console.log(`🔍 [ドリルダウン] rightPanel.innerHTML生成開始`);

    // コンテンツ生成
    const layerName = parentNodeData.text || `スクリプト${parentNodeData.layer}`;
    rightPanel.innerHTML = `
        <div class="layer-label" style="
            height: 32px;
            background: #f8fafc;
            margin: 0;
            border-radius: 8px 8px 0 0;
            display: flex;
            align-items: center;
            justify-content: flex-start;
            gap: 10px;
            padding: 0 12px 0 16px;
            color: #334155;
            font-weight: 600;
            font-size: 12px;
            cursor: pointer;
            border-bottom: 1px solid #e2e8f0;
            position: relative;
        " title="クリックで編集モードに入る">
            <span style="position: absolute; left: 0; top: 6px; bottom: 6px; width: 3px; background: linear-gradient(to bottom, #3b82f6, #22d3ee); border-radius: 0 2px 2px 0;"></span>
            <span>レイヤー${targetLayer} - ${layerName}</span>
            <span style="font-size: 11px; opacity: 0.6; margin-left: auto;">✏️ クリックで編集</span>
        </div>
        <div class="layer-indicator">L${targetLayer}</div>
        <div class="node-list-container" id="drilldown-nodes" style="position: relative; cursor: pointer;" title="クリックで編集モードに入る">
            <!-- ノードがここに表示される -->
        </div>
    `;

    // ドリルダウンパネル全体のクリックで編集モードに入る
    rightPanel.addEventListener('click', function drilldownPanelClickHandler(e) {
        // ノードボタンのクリックは除外（ノード自体の操作を優先）
        if (e.target.closest('.node-button')) {
            return;
        }
        console.log(`[ドリルダウン] パネルクリック → 編集モードに入ります（レイヤー${targetLayer}）`);
        enterEditMode(targetLayer);
    }, { once: true }); // 一度だけ実行（編集モードに入ったら不要）

    // ノードを描画（既存のrenderNodesInLayerと同じロジック）
    const nodeContainer = rightPanel.querySelector('#drilldown-nodes');
    console.log(`🔍 [ドリルダウン] nodeContainer=${nodeContainer ? '✅あり' : '❌なし'}, layerNodes.length=${layerNodes.length}`);
    console.log(`🔍 [ドリルダウン] 条件チェック: nodeContainer=${!!nodeContainer}, layerNodes.length=${layerNodes.length}, layerNodes.length > 0=${layerNodes.length > 0}`);
    console.log(`🔍 [ドリルダウン] 条件全体: ${!!(nodeContainer && layerNodes.length > 0)}`);

    if (nodeContainer && layerNodes.length > 0) {
        console.log(`🔍 [ドリルダウン] ✅ IF文の中に入りました！ノード描画開始: ${layerNodes.length}個`);
        // Y座標でソート
        const sortedNodes = layerNodes.sort((a, b) => a.y - b.y);
        console.log(`🔍 [ドリルダウン] sortedNodes.length=${sortedNodes.length}`);

        try {
            sortedNodes.forEach((node, index) => {
                console.log(`🔍 [ドリルダウン] forEachループ ${index}回目開始`);

                const btn = document.createElement('div');
                btn.className = 'node-button';

                // デバッグ: ノードデータの確認
                console.log(`🔍 [ドリルダウン] ノードデータ: text="${node.text}", color=${node.color}, groupId=${node.groupId}, id=${node.id}`);

                // テキストの省略表示（20文字以上は省略）
                const displayText = node.text.length > 20 ? node.text.substring(0, 20) + '...' : node.text;
                btn.textContent = displayText;
                btn.title = node.text; // ツールチップで完全なテキストを表示

                btn.style.backgroundColor = getColorCode(node.color);
                btn.style.position = 'absolute';
                btn.style.left = `${node.x || 90}px`;
                btn.style.top = `${node.y}px`;
                btn.dataset.nodeId = node.id;

                // GroupIDを設定（ループ検出用）
                if (node.groupId !== null && node.groupId !== undefined) {
                    btn.dataset.groupId = node.groupId;
                    console.log(`🔍 [ドリルダウン] ノードにGroupID設定: text="${node.text}", groupId=${node.groupId}`);
                } else {
                    console.log(`🔍 [ドリルダウン] GroupIDなし: text="${node.text}", groupId=${node.groupId}`);
                }

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
                console.log(`🔍 [ドリルダウン] forEachループ ${index}回目完了`);
            });
        } catch (error) {
            console.log(`🔍 [ドリルダウン] ❌ エラー発生: ${error.message}`);
            console.error(`🔍 [ドリルダウン] エラー詳細:`, error);
        }

        console.log(`🔍 [ドリルダウン] ノード描画完了: ${sortedNodes.length}個`);

        // ノード数が多い場合にコンテナの高さを動的に調整（コンテンツに合わせる）
        if (sortedNodes.length > 0) {
            const maxY = Math.max(...sortedNodes.map(n => n.y)) + (NODE_HEIGHT * 2); // ノード高さ + 余白
            // 固定の700pxではなく、コンテンツの高さのみを設定（スクロールバー防止）
            nodeContainer.style.minHeight = `${maxY}px`;
            console.log(`🔍 [ドリルダウン] コンテナ高さを調整: ${maxY}px`);
        }

        // Canvas要素を追加して矢印を描画
        const existingCanvas = nodeContainer.querySelector('.arrow-canvas');
        if (existingCanvas) {
            console.log(`🔍 [ドリルダウン] 既存Canvasを削除`);
            existingCanvas.remove(); // 既存のCanvasがあれば削除
        }

        console.log(`🔍 [ドリルダウン] Canvas要素作成開始`);
        const canvas = document.createElement('canvas');
        canvas.className = 'arrow-canvas';
        canvas.style.position = 'absolute';
        canvas.style.top = '0';
        canvas.style.left = '0';
        canvas.style.pointerEvents = 'none'; // クリックイベントを透過
        canvas.style.zIndex = '1'; // ノードの上に表示
        canvas.style.width = '100%';
        canvas.style.height = '100%';

        // Canvasサイズを親要素に合わせる
        const width = Math.max(nodeContainer.clientWidth, nodeContainer.offsetWidth, nodeContainer.scrollWidth, 299);
        const height = Math.max(nodeContainer.clientHeight, nodeContainer.offsetHeight, nodeContainer.scrollHeight, 1200);
        canvas.width = width;
        canvas.height = height;

        nodeContainer.appendChild(canvas);

        // CanvasをarrowState.canvasMapに登録
        arrowState.canvasMap.set('drilldown-panel', canvas);
        console.log('🔍 [ドリルダウン] Canvasをarrowstate.canvasMapに登録: drilldown-panel');

        // 矢印を描画（編集パネルと共通のdrawPanelArrows関数を使用）
        setTimeout(() => {
            console.log('🔍 [ドリルダウン] drawPanelArrows呼び出し開始');
            drawPanelArrows('drilldown-panel');
            console.log('🔍 [ドリルダウン] drawPanelArrows呼び出し完了');
        }, 100);
    } else if (nodeContainer) {
        nodeContainer.innerHTML = '<div style="text-align: center; color: var(--text-secondary); padding: 20px;">ノードがありません</div>';
    }

    // ドリルダウン状態を更新
    drilldownState.active = true;
    drilldownState.currentPinkNode = parentNodeData;
    drilldownState.targetLayer = targetLayer;

    // アニメーション完了後にクラスを削除
    setTimeout(() => {
        rightPanel.classList.remove('slide-in');
    }, 400);
}

// ドリルダウンパネルを閉じる
function closeDrilldownPanel() {
    console.log(`[ドリルダウン] ❌ closeDrilldownPanel() 呼び出し`);
    console.log(`[ドリルダウン] 現在のbreadcrumbStack:`, breadcrumbStack.map(b => `L${b.layer}:${b.name}`).join(' → '));

    const rightPanel = document.getElementById('right-layer-panel');
    const leftPanel = document.getElementById('left-layer-panel');
    const escHint = document.getElementById('escHint');

    if (!rightPanel) return;

    // スライドアウトアニメーション
    rightPanel.classList.add('slide-out');

    setTimeout(() => {
        rightPanel.classList.remove('slide-out');
        rightPanel.classList.add('empty');
        rightPanel.innerHTML = '';
    }, 400);

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

    // グロー効果を解除（Pinkノードのピックアップ状態を解除）
    clearGlowEffects();

    // ★ パンくずリストは左パネルに連動するため、ドリルダウンを閉じても変更しない

    if (LOG_CONFIG.pink) {
        console.log('[ドリルダウン] パネルを閉じました');
    }
}

// グロー効果をすべて解除
function clearGlowEffects() {
    console.log('[グロー効果] clearGlowEffects() - グロー効果を解除');

    // グロー状態をクリア
    glowState.sourceNode = null;
    glowState.sourceLayer = null;
    glowState.targetLayer = null;

    // すべてのノードからglow-sourceクラスとインラインスタイルを削除
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

    // グロー矢印インジケーター（▶）を削除
    const existingArrows = document.querySelectorAll('.glow-arrow-indicator');
    existingArrows.forEach(el => el.remove());
    console.log(`[グロー効果] ${existingArrows.length}個のグロー矢印を削除しました`);

    // ピンク矢印の状態もクリア
    arrowState.pinkSelected = false;
    arrowState.selectedPinkButton = null;

    // 矢印を再描画（ピンク矢印を消すため）
    if (window.arrowDrawing) {
        window.arrowDrawing.drawPanelArrows(`layer-${leftVisibleLayer}`);
    }

    console.log(`[グロー効果] ${existingGlowSources.length}個のグロー効果を解除しました`);
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
            rightPanel.innerHTML = '';
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

    // ★ パンくずリストを左パネルに連動して更新（プレビューから実際の編集モードへ移行）
    updateBreadcrumbForLayer(targetLayer);

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

    if (LOG_CONFIG.breadcrumb) {
        console.log(`[編集モード] 編集モード有効化 - currentLayer: ${targetLayer}, leftVisibleLayer: ${leftVisibleLayer}`);
    }
}

// 編集モードを終了してメインフローに戻る
function exitEditMode() {
    if (LOG_CONFIG.breadcrumb) {
        console.log('[編集モード] 編集モードを終了します');
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

// ============================================
// コピー/貼り付け機能
// ============================================
// 使い方:
//   1. ノードをクリックして選択
//   2. Ctrl+C でコピー（または右クリックメニューから「コピー」）
//   3. Ctrl+V で貼り付け（または右クリックメニューから「貼り付け」）
// ※ 現在は手動で setSelectedNode() を呼び出す必要があります
// ※ 今後、ノードクリックイベントに統合予定
// ============================================

// クリップボード（コピーされたノード情報を保持）
let nodeClipboard = null;

// 選択されたノードの状態を追跡
let selectedNodeState = {
    nodeId: null,           // 選択されたノードID
    layerId: null,          // 選択されたノードのレイヤーID
    lastClickTime: null     // 最後にクリックされた時刻
};

// 現在のレイヤーデータを取得
function getCurrentLayerData() {
    if (!layerStructure[leftVisibleLayer]) {
        console.warn('[レイヤー] レイヤーデータが見つかりません:', leftVisibleLayer);
        return { 構成: [] };
    }

    return {
        構成: layerStructure[leftVisibleLayer].nodes
    };
}

// 現在のレイヤーデータを再読み込み
async function loadCurrentLayerData() {
    console.log('[レイヤー] レイヤーデータを再読み込み中...');
    try {
        await loadExistingNodes();
        console.log('[レイヤー] ✅ レイヤーデータの再読み込み完了');
    } catch (error) {
        console.error('[レイヤー] レイヤーデータの再読み込み失敗:', error);
        throw error;
    }
}

// 重複しないY座標を計算（既存ノードと重ならない位置を探す）
function findNonOverlappingY(targetLayer, desiredY, nodeHeight = NODE_HEIGHT, gridSize = NODE_SPACING) {
    const layerNodes = layerStructure[targetLayer]?.nodes || [];

    // desiredYをグリッドにスナップ
    let newY = Math.round(desiredY / gridSize) * gridSize + 30;

    // 既存ノードのY座標を取得してソート
    const existingYs = layerNodes.map(n => n.y).sort((a, b) => a - b);

    // 重複チェック：同じY座標にノードがあれば下にずらす
    while (existingYs.includes(newY)) {
        newY += gridSize;
        console.log(`[Y座標調整] 重複検出、新しいY=${newY}`);
    }

    return newY;
}

// ノードをコピー
async function copyNode(nodeId) {
    console.log(`[コピー] ノードをコピー: ${nodeId}`);

    // レイヤー情報から元のノードを取得
    const currentLayer = getCurrentLayerData();
    // ノードは name プロパティで識別される（ボタン名に対応）
    const sourceNode = currentLayer.構成.find(n => n.name === nodeId);

    if (!sourceNode) {
        console.error(`[コピー] ノードが見つかりません: ${nodeId}`);
        return false;
    }

    // コード.json から最新のスクリプトを取得
    const script = getCodeEntry(sourceNode.id);
    console.log(`[コピー] コード.jsonからスクリプトを取得: ${script ? script.length : 0}文字`);

    // クリップボードに保存（サーバー側で検索するために id プロパティを使用）
    nodeClipboard = {
        nodeId: sourceNode.id,  // name ではなく id を保存
        nodeName: nodeId,       // name も保持しておく
        node: sourceNode,
        script: script          // コード.jsonから取得したスクリプトを保存
    };

    console.log(`[コピー] ✅ ノードをクリップボードにコピーしました:`, sourceNode);
    console.log(`[コピー] ID=${sourceNode.id}, Name=${nodeId}, Script長=${script ? script.length : 0}`);
    showToast('ノードをコピーしました', 'success');
    return true;
}

// ノードを貼り付け
async function pasteNode() {
    if (!nodeClipboard) {
        console.warn('[貼り付け] クリップボードが空です');
        showToast('コピーされたノードがありません', 'warning');
        return false;
    }

    console.log(`[貼り付け] ノードを貼り付け:`, nodeClipboard);
    const sourceNode = nodeClipboard.node;
    const sourceScript = nodeClipboard.script || '';

    try {
        // 新しいノードIDを生成（タイムスタンプベース）
        const timestamp = Date.now();
        const random = Math.floor(Math.random() * 900) + 100;
        const newNodeId = `node-${timestamp}-${random}`;

        // Y座標を計算（重複しない位置を探す）
        const desiredY = sourceNode.y + 60;  // 元のノードの1グリッド下を希望
        const newY = findNonOverlappingY(sourceNode.layer, desiredY);

        // 新しいノードを作成（元のノードの全プロパティをコピー）
        const newNode = {
            id: newNodeId,
            name: newNodeId,
            text: sourceNode.text,
            color: sourceNode.color,
            layer: sourceNode.layer,
            y: newY,
            x: sourceNode.x,
            width: sourceNode.width,
            height: sourceNode.height,
            groupId: sourceNode.groupId,
            処理番号: sourceNode.処理番号 || '',
            script: sourceScript,
            関数名: sourceNode.関数名 || ''
        };

        console.log(`[貼り付け] 新しいノードを作成: ID=${newNodeId}, Y=${newY}, Script長=${sourceScript ? sourceScript.length : 0}`);

        // layerStructure に新しいノードを追加
        layerStructure[newNode.layer].nodes.push(newNode);
        nodes.push(newNode);

        console.log(`[貼り付け] レイヤー${newNode.layer}に追加完了`);

        // スクリプトがある場合は、コード.jsonにも保存
        if (sourceScript && sourceScript.trim() !== '') {
            console.log(`[貼り付け] コード.jsonにスクリプトを保存: ID=${newNodeId}, Script長=${sourceScript.length}`);
            await setCodeEntry(newNodeId, sourceScript);
        }

        // memory.json に保存
        await saveMemoryJson();

        // UIを再描画
        renderNodesInLayer(leftVisibleLayer, 'left');

        console.log(`[貼り付け] ✅ ノード貼り付け成功`);
        showToast(`ノードを貼り付けました`, 'success');

        return true;
    } catch (error) {
        console.error('[貼り付け] エラー:', error);
        showToast(`貼り付けエラー: ${error.message}`, 'error');
        return false;
    }
}

// Ctrl+C / Ctrl+V キーボードショートカット
document.addEventListener('keydown', (e) => {
    // Ctrl+C: コピー
    if (e.ctrlKey && e.key === 'c') {
        // 選択中のノードを取得
        const selectedNode = getSelectedNode();
        if (selectedNode) {
            e.preventDefault();
            copyNode(selectedNode.name);
        }
    }

    // Ctrl+V: 貼り付け
    if (e.ctrlKey && e.key === 'v') {
        if (nodeClipboard) {
            e.preventDefault();
            pasteNode();
        }
    }
});

// 選択中のノードを取得
function getSelectedNode() {
    if (!selectedNodeState.nodeId) {
        console.log('[選択] 選択されたノードがありません');
        return null;
    }

    // 選択されたレイヤーのデータを取得
    const layerData = getCurrentLayerData();
    if (!layerData || !layerData.構成) {
        console.warn('[選択] レイヤーデータが見つかりません');
        return null;
    }

    // ノードを検索（name プロパティはボタン名に対応）
    const node = layerData.構成.find(n => n.name === selectedNodeState.nodeId);
    if (node) {
        console.log('[選択] 選択ノード:', node);
        return node;
    }

    console.warn(`[選択] ノードID ${selectedNodeState.nodeId} が見つかりません`);
    return null;
}

// ノードが選択されたことを記録（他の部分から呼び出す用）
function setSelectedNode(nodeId, layerId) {
    selectedNodeState.nodeId = nodeId;
    selectedNodeState.layerId = layerId || leftVisibleLayer;
    selectedNodeState.lastClickTime = Date.now();
    console.log('[選択] ノードを選択:', nodeId);
}

// トースト通知を表示（簡易実装）
function showToast(message, type = 'info') {
    console.log(`[トースト ${type}] ${message}`);
    showAlertDialog(message, 'お知らせ'); // カスタムモーダルダイアログを使用
}

// ============================================
// ポップアップウィンドウからのメッセージ受信
// ============================================
window.addEventListener('message', (event) => {
    // セキュリティチェック（同一オリジンのみ許可）
    if (event.origin !== window.location.origin) {
        console.warn('[postMessage] 不正なオリジンからのメッセージを無視:', event.origin);
        return;
    }

    console.log('[postMessage] メッセージ受信:', event.data);

    if (event.data.type === 'POPUP_READY') {
        // ポップアップが準備完了 - データを送信
        console.log('[postMessage] ポップアップが準備完了しました');

        // すべてのポップアップにデータを送信（どのレイヤーか特定できないため）
        layerPopupData.forEach((data, layer) => {
            const popup = layerPopups.get(layer);
            if (popup && !popup.closed) {
                console.log(`[postMessage] レイヤー${layer}にデータを送信: ${data.nodes.length}ノード`);
                popup.postMessage({
                    type: 'SHOW_LAYER_DETAIL',
                    layer: data.layer,
                    nodes: data.nodes,
                    parentNode: data.parentNode
                }, window.location.origin);
            }
        });
    } else if (event.data.type === 'POPUP_CLOSED') {
        // ポップアップが閉じられた
        const layer = event.data.layer;
        console.log(`[postMessage] ポップアップ（レイヤー${layer}）が閉じられました`);
        if (layerPopups.has(layer)) {
            layerPopups.delete(layer);
        }
        if (layerPopupData.has(layer)) {
            layerPopupData.delete(layer);
        }
    } else if (event.data.type === 'REQUEST_LAYER_DATA') {
        // ポップアップからレイヤーデータ更新をリクエスト
        const layer = event.data.layer;
        console.log(`[postMessage] レイヤー${layer}のデータ更新リクエストを受信`);

        const layerNodes = layerStructure[layer].nodes || [];
        const popup = layerPopups.get(layer);

        if (popup && !popup.closed) {
            popup.postMessage({
                type: 'UPDATE_NODES',
                nodes: layerNodes
            }, window.location.origin);
            console.log(`[postMessage] レイヤー${layer}にデータを送信: ${layerNodes.length}ノード`);
        }
    } else if (event.data.type === 'NODE_CLICKED_IN_POPUP') {
        // ポップアップ内でノードがクリックされた
        console.log(`[postMessage] ポップアップ内でノードクリック: ${event.data.nodeId}`);
        // 必要に応じて処理を追加
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

// 注: drawDrilldownArrows関数は削除され、代わりに共通のdrawPanelArrows関数を使用するようになりました

// ============================================================================
// Undo/Redo 操作履歴機能
// ============================================================================

/**
 * ユーザーにメッセージを表示（トースト通知）
 * @param {string} message - 表示するメッセージ
 * @param {string} type - メッセージタイプ ('success', 'warning', 'error')
 */
function showMessage(message, type = 'info') {
    // 既存の通知を削除
    const existingToast = document.querySelector('.toast-notification');
    if (existingToast) {
        existingToast.remove();
    }

    // トースト要素を作成
    const toast = document.createElement('div');
    toast.className = 'toast-notification';
    toast.textContent = message;

    // タイプに応じたスタイルを設定
    const colors = {
        success: '#4caf50',
        warning: '#ff9800',
        error: '#f44336',
        info: '#2196f3'
    };

    toast.style.cssText = `
        position: fixed;
        top: 80px;
        right: 20px;
        padding: 12px 20px;
        background-color: ${colors[type] || colors.info};
        color: white;
        border-radius: 4px;
        box-shadow: 0 4px 6px rgba(0,0,0,0.3);
        z-index: 10000;
        font-size: 14px;
        opacity: 0;
        transition: opacity 0.3s ease-in-out;
    `;

    // DOMに追加
    document.body.appendChild(toast);

    // フェードイン
    setTimeout(() => {
        toast.style.opacity = '1';
    }, 10);

    // 3秒後にフェードアウトして削除
    setTimeout(() => {
        toast.style.opacity = '0';
        setTimeout(() => {
            toast.remove();
        }, 300);
    }, 3000);
}

// ============================================================================
// カスタムモーダルダイアログ（ブラウザネイティブ alert/confirm の代替）
// ============================================================================

/**
 * カスタムアラートダイアログを表示
 * @param {string} message - 表示するメッセージ
 * @param {string} title - ダイアログのタイトル（省略可）
 * @returns {Promise<void>} ユーザーがOKを押すと解決
 */
function showAlertDialog(message, title = 'お知らせ') {
    return new Promise((resolve) => {
        // 既存のダイアログを削除
        const existingDialog = document.querySelector('.custom-dialog-overlay');
        if (existingDialog) {
            existingDialog.remove();
        }

        // オーバーレイを作成
        const overlay = document.createElement('div');
        overlay.className = 'custom-dialog-overlay';
        overlay.style.cssText = `
            display: flex;
            position: fixed;
            z-index: 99999;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.5);
            backdrop-filter: blur(5px);
            justify-content: center;
            align-items: center;
        `;

        // ダイアログコンテナを作成
        const dialog = document.createElement('div');
        dialog.className = 'custom-dialog';
        dialog.style.cssText = `
            background: #e0e5ec;
            padding: 24px;
            border-radius: 20px;
            width: 400px;
            max-width: 90%;
            max-height: 80vh;
            overflow-y: auto;
            box-shadow:
                12px 12px 24px rgba(163, 177, 198, 0.6),
                -12px -12px 24px rgba(255, 255, 255, 0.5);
            animation: dialogFadeIn 0.2s ease-out;
        `;

        // タイトル
        const titleEl = document.createElement('div');
        titleEl.style.cssText = `
            font-size: 18px;
            font-weight: bold;
            color: #333;
            margin-bottom: 16px;
            padding-bottom: 12px;
            border-bottom: 2px solid rgba(99, 102, 241, 0.3);
        `;
        titleEl.textContent = title;

        // メッセージ
        const messageEl = document.createElement('div');
        messageEl.style.cssText = `
            font-size: 14px;
            color: #555;
            line-height: 1.6;
            margin-bottom: 24px;
            white-space: pre-wrap;
            word-break: break-word;
        `;
        messageEl.textContent = message;

        // ボタンコンテナ
        const buttonContainer = document.createElement('div');
        buttonContainer.style.cssText = `
            display: flex;
            justify-content: center;
            gap: 12px;
        `;

        // OKボタン
        const okButton = document.createElement('button');
        okButton.textContent = 'OK';
        okButton.style.cssText = `
            padding: 10px 32px;
            font-size: 14px;
            font-weight: bold;
            color: white;
            background: linear-gradient(135deg, #6366f1, #8b5cf6);
            border: none;
            border-radius: 10px;
            cursor: pointer;
            transition: all 0.2s ease;
            box-shadow:
                4px 4px 8px rgba(163, 177, 198, 0.4),
                -4px -4px 8px rgba(255, 255, 255, 0.4);
        `;
        okButton.onmouseenter = () => {
            okButton.style.transform = 'scale(1.05)';
            okButton.style.boxShadow = '0 0 15px rgba(99, 102, 241, 0.5)';
        };
        okButton.onmouseleave = () => {
            okButton.style.transform = 'scale(1)';
            okButton.style.boxShadow = '4px 4px 8px rgba(163, 177, 198, 0.4), -4px -4px 8px rgba(255, 255, 255, 0.4)';
        };
        okButton.onclick = () => {
            overlay.remove();
            resolve();
        };

        // 組み立て
        buttonContainer.appendChild(okButton);
        dialog.appendChild(titleEl);
        dialog.appendChild(messageEl);
        dialog.appendChild(buttonContainer);
        overlay.appendChild(dialog);
        document.body.appendChild(overlay);

        // フォーカス
        okButton.focus();

        // Enterキーで閉じる
        overlay.addEventListener('keydown', (e) => {
            if (e.key === 'Enter' || e.key === 'Escape') {
                overlay.remove();
                resolve();
            }
        });
    });
}

/**
 * カスタム確認ダイアログを表示
 * @param {string} message - 表示するメッセージ
 * @param {string} title - ダイアログのタイトル（省略可）
 * @returns {Promise<boolean>} ユーザーがOKを押すとtrue、キャンセルでfalse
 */
function showConfirmDialog(message, title = '確認') {
    return new Promise((resolve) => {
        // 既存のダイアログを削除
        const existingDialog = document.querySelector('.custom-dialog-overlay');
        if (existingDialog) {
            existingDialog.remove();
        }

        // オーバーレイを作成
        const overlay = document.createElement('div');
        overlay.className = 'custom-dialog-overlay';
        overlay.style.cssText = `
            display: flex;
            position: fixed;
            z-index: 99999;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.5);
            backdrop-filter: blur(5px);
            justify-content: center;
            align-items: center;
        `;

        // ダイアログコンテナを作成
        const dialog = document.createElement('div');
        dialog.className = 'custom-dialog';
        dialog.style.cssText = `
            background: #e0e5ec;
            padding: 24px;
            border-radius: 20px;
            width: 450px;
            max-width: 90%;
            max-height: 80vh;
            overflow-y: auto;
            box-shadow:
                12px 12px 24px rgba(163, 177, 198, 0.6),
                -12px -12px 24px rgba(255, 255, 255, 0.5);
            animation: dialogFadeIn 0.2s ease-out;
        `;

        // タイトル
        const titleEl = document.createElement('div');
        titleEl.style.cssText = `
            font-size: 18px;
            font-weight: bold;
            color: #333;
            margin-bottom: 16px;
            padding-bottom: 12px;
            border-bottom: 2px solid rgba(236, 72, 153, 0.3);
        `;
        titleEl.textContent = title;

        // メッセージ
        const messageEl = document.createElement('div');
        messageEl.style.cssText = `
            font-size: 14px;
            color: #555;
            line-height: 1.6;
            margin-bottom: 24px;
            white-space: pre-wrap;
            word-break: break-word;
        `;
        messageEl.textContent = message;

        // ボタンコンテナ
        const buttonContainer = document.createElement('div');
        buttonContainer.style.cssText = `
            display: flex;
            justify-content: center;
            gap: 16px;
        `;

        // キャンセルボタン
        const cancelButton = document.createElement('button');
        cancelButton.textContent = 'キャンセル';
        cancelButton.style.cssText = `
            padding: 10px 24px;
            font-size: 14px;
            font-weight: bold;
            color: #666;
            background: #e0e5ec;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            transition: all 0.2s ease;
            box-shadow:
                4px 4px 8px rgba(163, 177, 198, 0.4),
                -4px -4px 8px rgba(255, 255, 255, 0.4);
        `;
        cancelButton.onmouseenter = () => {
            cancelButton.style.transform = 'scale(1.05)';
            cancelButton.style.background = '#d0d5dc';
        };
        cancelButton.onmouseleave = () => {
            cancelButton.style.transform = 'scale(1)';
            cancelButton.style.background = '#e0e5ec';
        };
        cancelButton.onclick = () => {
            overlay.remove();
            resolve(false);
        };

        // OKボタン
        const okButton = document.createElement('button');
        okButton.textContent = 'OK';
        okButton.style.cssText = `
            padding: 10px 32px;
            font-size: 14px;
            font-weight: bold;
            color: white;
            background: linear-gradient(135deg, #ec4899, #f472b6);
            border: none;
            border-radius: 10px;
            cursor: pointer;
            transition: all 0.2s ease;
            box-shadow:
                4px 4px 8px rgba(163, 177, 198, 0.4),
                -4px -4px 8px rgba(255, 255, 255, 0.4);
        `;
        okButton.onmouseenter = () => {
            okButton.style.transform = 'scale(1.05)';
            okButton.style.boxShadow = '0 0 15px rgba(236, 72, 153, 0.5)';
        };
        okButton.onmouseleave = () => {
            okButton.style.transform = 'scale(1)';
            okButton.style.boxShadow = '4px 4px 8px rgba(163, 177, 198, 0.4), -4px -4px 8px rgba(255, 255, 255, 0.4)';
        };
        okButton.onclick = () => {
            overlay.remove();
            resolve(true);
        };

        // 組み立て
        buttonContainer.appendChild(cancelButton);
        buttonContainer.appendChild(okButton);
        dialog.appendChild(titleEl);
        dialog.appendChild(messageEl);
        dialog.appendChild(buttonContainer);
        overlay.appendChild(dialog);
        document.body.appendChild(overlay);

        // OKボタンにフォーカス
        okButton.focus();

        // キーボードイベント
        overlay.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                overlay.remove();
                resolve(true);
            } else if (e.key === 'Escape') {
                overlay.remove();
                resolve(false);
            }
        });
    });
}

/**
 * カスタムプロンプトダイアログを表示
 * @param {string} message - 表示するメッセージ
 * @param {string} title - ダイアログのタイトル（省略可）
 * @param {string} defaultValue - 入力欄のデフォルト値（省略可）
 * @returns {Promise<string|null>} ユーザーが入力した値、キャンセルでnull
 */
function showPromptDialog(message, title = '入力', defaultValue = '') {
    return new Promise((resolve) => {
        // 既存のダイアログを削除
        const existingDialog = document.querySelector('.custom-dialog-overlay');
        if (existingDialog) {
            existingDialog.remove();
        }

        // オーバーレイを作成
        const overlay = document.createElement('div');
        overlay.className = 'custom-dialog-overlay';
        overlay.style.cssText = `
            display: flex;
            position: fixed;
            z-index: 99999;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.5);
            backdrop-filter: blur(5px);
            justify-content: center;
            align-items: center;
        `;

        // ダイアログコンテナを作成
        const dialog = document.createElement('div');
        dialog.className = 'custom-dialog';
        dialog.style.cssText = `
            background: #e0e5ec;
            padding: 24px;
            border-radius: 20px;
            width: 450px;
            max-width: 90%;
            max-height: 80vh;
            overflow-y: auto;
            box-shadow:
                12px 12px 24px rgba(163, 177, 198, 0.6),
                -12px -12px 24px rgba(255, 255, 255, 0.5);
            animation: dialogFadeIn 0.2s ease-out;
        `;

        // タイトル
        const titleEl = document.createElement('div');
        titleEl.style.cssText = `
            font-size: 18px;
            font-weight: bold;
            color: #333;
            margin-bottom: 16px;
            padding-bottom: 12px;
            border-bottom: 2px solid rgba(127, 255, 212, 0.5);
        `;
        titleEl.textContent = title;

        // メッセージ
        const messageEl = document.createElement('div');
        messageEl.style.cssText = `
            font-size: 14px;
            color: #555;
            line-height: 1.6;
            margin-bottom: 16px;
            white-space: pre-wrap;
            word-break: break-word;
        `;
        messageEl.textContent = message;

        // 入力欄
        const inputEl = document.createElement('input');
        inputEl.type = 'text';
        inputEl.value = defaultValue;
        inputEl.style.cssText = `
            width: 100%;
            padding: 12px 16px;
            font-size: 14px;
            border: none;
            border-radius: 10px;
            background: #e0e5ec;
            color: #333;
            margin-bottom: 24px;
            box-sizing: border-box;
            box-shadow:
                inset 4px 4px 8px rgba(163, 177, 198, 0.4),
                inset -4px -4px 8px rgba(255, 255, 255, 0.4);
            outline: none;
        `;
        inputEl.onfocus = () => {
            inputEl.style.boxShadow = `
                inset 4px 4px 8px rgba(163, 177, 198, 0.4),
                inset -4px -4px 8px rgba(255, 255, 255, 0.4),
                0 0 0 2px rgba(127, 255, 212, 0.5)
            `;
        };
        inputEl.onblur = () => {
            inputEl.style.boxShadow = `
                inset 4px 4px 8px rgba(163, 177, 198, 0.4),
                inset -4px -4px 8px rgba(255, 255, 255, 0.4)
            `;
        };

        // ボタンコンテナ
        const buttonContainer = document.createElement('div');
        buttonContainer.style.cssText = `
            display: flex;
            justify-content: center;
            gap: 16px;
        `;

        // キャンセルボタン
        const cancelButton = document.createElement('button');
        cancelButton.textContent = 'キャンセル';
        cancelButton.style.cssText = `
            padding: 10px 24px;
            font-size: 14px;
            font-weight: bold;
            color: #666;
            background: #e0e5ec;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            transition: all 0.2s ease;
            box-shadow:
                4px 4px 8px rgba(163, 177, 198, 0.4),
                -4px -4px 8px rgba(255, 255, 255, 0.4);
        `;
        cancelButton.onmouseenter = () => {
            cancelButton.style.transform = 'scale(1.05)';
            cancelButton.style.background = '#d0d5dc';
        };
        cancelButton.onmouseleave = () => {
            cancelButton.style.transform = 'scale(1)';
            cancelButton.style.background = '#e0e5ec';
        };
        cancelButton.onclick = () => {
            overlay.remove();
            resolve(null);
        };

        // OKボタン
        const okButton = document.createElement('button');
        okButton.textContent = 'OK';
        okButton.style.cssText = `
            padding: 10px 32px;
            font-size: 14px;
            font-weight: bold;
            color: #333;
            background: linear-gradient(135deg, rgb(127, 255, 212), rgb(100, 220, 180));
            border: none;
            border-radius: 10px;
            cursor: pointer;
            transition: all 0.2s ease;
            box-shadow:
                4px 4px 8px rgba(163, 177, 198, 0.4),
                -4px -4px 8px rgba(255, 255, 255, 0.4);
        `;
        okButton.onmouseenter = () => {
            okButton.style.transform = 'scale(1.05)';
            okButton.style.boxShadow = '0 0 15px rgba(127, 255, 212, 0.5)';
        };
        okButton.onmouseleave = () => {
            okButton.style.transform = 'scale(1)';
            okButton.style.boxShadow = '4px 4px 8px rgba(163, 177, 198, 0.4), -4px -4px 8px rgba(255, 255, 255, 0.4)';
        };
        okButton.onclick = () => {
            const value = inputEl.value.trim();
            overlay.remove();
            resolve(value || null);
        };

        // 組み立て
        buttonContainer.appendChild(cancelButton);
        buttonContainer.appendChild(okButton);
        dialog.appendChild(titleEl);
        dialog.appendChild(messageEl);
        dialog.appendChild(inputEl);
        dialog.appendChild(buttonContainer);
        overlay.appendChild(dialog);
        document.body.appendChild(overlay);

        // 入力欄にフォーカス
        inputEl.focus();
        inputEl.select();

        // キーボードイベント
        overlay.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                const value = inputEl.value.trim();
                overlay.remove();
                resolve(value || null);
            } else if (e.key === 'Escape') {
                overlay.remove();
                resolve(null);
            }
        });
    });
}

// CSSアニメーション追加
(function addDialogStyles() {
    const style = document.createElement('style');
    style.textContent = `
        @keyframes dialogFadeIn {
            from {
                opacity: 0;
                transform: scale(0.9);
            }
            to {
                opacity: 1;
                transform: scale(1);
            }
        }
    `;
    document.head.appendChild(style);
})();

/**
 * Undo/Redoボタンの状態を更新
 */
async function updateUndoRedoButtons() {
    try {
        const response = await fetch(`${API_BASE}/history/status`);
        const data = await response.json();

        const undoBtn = document.getElementById('btn-undo');
        const redoBtn = document.getElementById('btn-redo');

        if (data.success) {
            // Undoボタンの状態（CSSクラスで制御）
            if (data.canUndo) {
                undoBtn.classList.remove('disabled');
            } else {
                undoBtn.classList.add('disabled');
            }

            // Redoボタンの状態（CSSクラスで制御）
            if (data.canRedo) {
                redoBtn.classList.remove('disabled');
            } else {
                redoBtn.classList.add('disabled');
            }

            if (LOG_CONFIG.history) {
                console.log(`[履歴] ボタン状態更新: Undo=${data.canUndo}, Redo=${data.canRedo}, Position=${data.position}/${data.count}`);
            }
        }
    } catch (error) {
        console.error('[履歴] ボタン状態更新エラー:', error);
    }
}

/**
 * Undo操作を実行
 */
async function undoOperation() {
    // ボタンが無効な場合は何もしない
    const undoBtn = document.getElementById('btn-undo');
    if (undoBtn && undoBtn.classList.contains('disabled')) {
        console.log('[履歴] Undoボタンが無効です');
        return;
    }

    try {
        // 履歴復元中フラグを立てる（自動保存を防ぐため）
        isRestoringHistory = true;

        if (LOG_CONFIG.history) {
            console.log('[履歴] Undo実行開始...');
        }

        const response = await fetch(`${API_BASE}/history/undo`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        });

        if (LOG_CONFIG.history) {
            console.log('[履歴] レスポンス受信:', response.status, response.statusText);
        }

        const data = await response.json();

        if (LOG_CONFIG.history) {
            console.log('[履歴] レスポンスデータ:', JSON.stringify(data));
        }

        if (data.success) {
            console.log('[履歴] Undo成功:', data.operation?.description);

            // memory.jsonを再読み込み
            await loadExistingNodes();

            // ボタン状態を更新
            await updateUndoRedoButtons();

            // 成功メッセージ
            showMessage(`✅ Undo: ${data.operation?.description || '操作を戻しました'}`, 'success');
        } else {
            console.warn('[履歴] Undo失敗:', data.error);
            showMessage(`⚠️ ${data.error || 'Undoできません'}`, 'warning');
        }
    } catch (error) {
        console.error('[履歴] Undoエラー:', error);
        showMessage('❌ Undoに失敗しました', 'error');
    } finally {
        // 履歴復元中フラグをクリア
        isRestoringHistory = false;
    }
}

/**
 * Redo操作を実行
 */
async function redoOperation() {
    // ボタンが無効な場合は何もしない
    const redoBtn = document.getElementById('btn-redo');
    if (redoBtn && redoBtn.classList.contains('disabled')) {
        console.log('[履歴] Redoボタンが無効です');
        return;
    }

    try {
        // 履歴復元中フラグを立てる（自動保存を防ぐため）
        isRestoringHistory = true;

        if (LOG_CONFIG.history) {
            console.log('[履歴] Redo実行開始...');
        }

        const response = await fetch(`${API_BASE}/history/redo`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        });

        if (LOG_CONFIG.history) {
            console.log('[履歴] レスポンス受信:', response.status, response.statusText);
        }

        const data = await response.json();

        if (LOG_CONFIG.history) {
            console.log('[履歴] レスポンスデータ:', JSON.stringify(data));
        }

        if (data.success) {
            console.log('[履歴] Redo成功:', data.operation?.description);

            // memory.jsonを再読み込み
            await loadExistingNodes();

            // ボタン状態を更新
            await updateUndoRedoButtons();

            // 成功メッセージ
            showMessage(`✅ Redo: ${data.operation?.description || '操作をやり直しました'}`, 'success');
        } else {
            console.warn('[履歴] Redo失敗:', data.error);
            showMessage(`⚠️ ${data.error || 'Redoできません'}`, 'warning');
        }
    } catch (error) {
        console.error('[履歴] Redoエラー:', error);
        showMessage('❌ Redoに失敗しました', 'error');
    } finally {
        // 履歴復元中フラグをクリア
        isRestoringHistory = false;
    }
}

/**
 * 履歴を初期化
 */
async function initializeHistory() {
    if (LOG_CONFIG.history) {
        console.log('[履歴] 初期化開始...');
    }

    try {
        const response = await fetch(`${API_BASE}/history/init`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        });

        const data = await response.json();

        if (data.success) {
            if (LOG_CONFIG.history) {
                console.log('[履歴] 初期化完了:', data);
            }
            await updateUndoRedoButtons();
        } else {
            if (LOG_CONFIG.history) {
                console.warn('[履歴] 初期化失敗:', data.error);
            }
        }
    } catch (error) {
        if (LOG_CONFIG.history) {
            console.error('[履歴] 初期化エラー:', error);
        }
    }
}

// DOMContentLoaded時に初期化
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        initLayerNavigation();

        // Undo/Redoボタンの初期状態を設定
        setTimeout(() => {
            updateUndoRedoButtons();  // initializeHistory()の代わりに直接ボタン状態を更新
        }, 1000);
    });
} else {
    initLayerNavigation();

    // Undo/Redoボタンの初期状態を設定
    setTimeout(() => {
        updateUndoRedoButtons();  // initializeHistory()の代わりに直接ボタン状態を更新
    }, 1000);
}

// ============================================
// 左パネル タブ切り替え
// ============================================
function switchLeftPanelTab(tabId) {
    console.log(`[タブ] 切り替え: ${tabId}`);

    // タブヘッダーのアクティブ状態を更新
    document.querySelectorAll('.left-panel-tab').forEach(tab => {
        if (tab.dataset.tab === tabId) {
            tab.classList.add('active');
        } else {
            tab.classList.remove('active');
        }
    });

    // タブコンテンツの表示/非表示を切り替え
    document.querySelectorAll('.left-panel-tab-content').forEach(content => {
        if (content.id === `tab-content-${tabId}`) {
            content.classList.add('active');
        } else {
            content.classList.remove('active');
        }
    });

    // ロボットタブに切り替えた時、ノード数を更新
    if (tabId === 'robot') {
        updateRobotNodeCount();
    }

    // 変数タブに切り替えた時、変数リストを描画
    if (tabId === 'variables') {
        renderVariablesList();
    }

    // 関数タブに切り替えた時、関数リストを描画
    if (tabId === 'functions') {
        renderFunctionsList();
    }

    // 接続タブに切り替えた時、接続状態を更新
    if (tabId === 'connection') {
        updateExcelConnectionUI();
    }
}

// ============================================
// Excel接続機能
// ============================================

// Excel接続状態を管理
const excelConnectionState = {
    connected: false,
    filePath: '',
    sheetName: '',
    variableName: 'Excel2次元配列',
    data: null,
    rowCount: 0,
    colCount: 0,
    headers: []
};

// 接続情報をサーバーに保存
async function saveConnectionState() {
    try {
        if (!currentFolder) {
            console.warn('[接続情報] currentFolderが未設定のため保存をスキップ');
            return;
        }

        const connectionData = {
            folder: currentFolder,
            excel: {
                connected: excelConnectionState.connected,
                filePath: excelConnectionState.filePath,
                sheetName: excelConnectionState.sheetName,
                variableName: excelConnectionState.variableName,
                rowCount: excelConnectionState.rowCount,
                colCount: excelConnectionState.colCount,
                headers: excelConnectionState.headers
            }
        };

        console.log('[接続情報] 保存開始:', currentFolder);

        const response = await fetch('/api/connection', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(connectionData)
        });

        if (response.ok) {
            console.log('[接続情報] 保存完了');
        }
    } catch (error) {
        console.error('[接続情報] 保存エラー:', error);
    }
}

// 接続情報をサーバーから復元
async function loadConnectionState() {
    try {
        if (!currentFolder) {
            console.warn('[接続情報] currentFolderが未設定のため復元をスキップ');
            return;
        }

        console.log('[接続情報] 復元開始 フォルダ:', currentFolder);

        const response = await fetch(`/api/connection?folder=${encodeURIComponent(currentFolder)}`);
        if (!response.ok) return;

        const result = await response.json();
        if (!result.success || !result.data || !result.data.excel) return;

        const excel = result.data.excel;
        if (!excel.connected) return;

        console.log('[接続情報] 復元データ:', excel);

        // 状態を復元
        excelConnectionState.connected = excel.connected;
        excelConnectionState.filePath = excel.filePath;
        excelConnectionState.sheetName = excel.sheetName;
        excelConnectionState.variableName = excel.variableName;
        excelConnectionState.rowCount = excel.rowCount;
        excelConnectionState.colCount = excel.colCount;
        excelConnectionState.headers = excel.headers || [];

        // UIを復元
        const filePathInput = document.getElementById('excel-file-path');
        const sheetSelect = document.getElementById('excel-sheet-select');
        const variableNameInput = document.getElementById('excel-variable-name');

        if (filePathInput) filePathInput.value = excel.filePath;
        if (variableNameInput) variableNameInput.value = excel.variableName;

        // シート選択を復元
        if (sheetSelect && excel.sheetName) {
            sheetSelect.innerHTML = `<option value="${excel.sheetName}">${excel.sheetName}</option>`;
            sheetSelect.value = excel.sheetName;
            sheetSelect.disabled = false;
        }

        // 接続タブのUI更新
        updateExcelConnectionUI();

        // variables.jsonからExcel変数を読み込んでvariablesにマージ
        try {
            const varResponse = await fetch(`${API_BASE}/folders/${currentFolder}/variables`);
            const varResult = await varResponse.json();
            if (varResult.success && varResult.data) {
                // variablesが配列の場合はオブジェクトに変換
                if (Array.isArray(variables)) {
                    console.log('[接続情報] variablesを配列からオブジェクトに変換');
                    variables = {};
                }

                // Excel変数名に対応する変数があれば追加
                const varName = excel.variableName;
                if (varResult.data[varName]) {
                    variables[varName] = varResult.data[varName];
                    console.log('[接続情報] Excel変数を復元:', varName);
                }
            }
        } catch (varError) {
            console.warn('[接続情報] 変数読み込みエラー:', varError);
        }

        // 変数タブのリスト更新
        renderVariablesList();

        console.log('[接続情報] 復元完了');
    } catch (error) {
        console.error('[接続情報] 復元エラー:', error);
    }
}

// Excel接続UIを更新
function updateExcelConnectionUI() {
    const badge = document.getElementById('excel-connection-badge');
    const connectBtn = document.getElementById('excel-connect-btn');
    const disconnectBtn = document.getElementById('excel-disconnect-btn');
    const infoPanel = document.getElementById('excel-connection-info');

    if (excelConnectionState.connected) {
        badge.textContent = '接続中';
        badge.classList.remove('disconnected');
        badge.classList.add('connected');
        connectBtn.style.display = 'none';
        disconnectBtn.style.display = 'block';
        infoPanel.style.display = 'block';

        document.getElementById('excel-row-count').textContent = excelConnectionState.rowCount;
        document.getElementById('excel-col-count').textContent = excelConnectionState.colCount;
        document.getElementById('excel-headers').textContent = excelConnectionState.headers.slice(0, 3).join(', ') + (excelConnectionState.headers.length > 3 ? '...' : '');
    } else {
        badge.textContent = '未接続';
        badge.classList.remove('connected');
        badge.classList.add('disconnected');
        connectBtn.style.display = 'block';
        disconnectBtn.style.display = 'none';
        infoPanel.style.display = 'none';
    }
}

// Excelファイル参照ボタン
async function browseExcelFile() {
    console.log('[Excel接続] ファイル選択開始');
    try {
        const response = await fetch('/api/excel/browse', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        });

        if (!response.ok) {
            throw new Error('ファイル選択に失敗しました');
        }

        const result = await response.json();
        console.log('[Excel接続] ファイル選択結果:', result);

        if (result.success && result.filePath) {
            document.getElementById('excel-file-path').value = result.filePath;
            excelConnectionState.filePath = result.filePath;

            // シート一覧を取得
            await loadExcelSheets(result.filePath);
        }
    } catch (error) {
        console.error('[Excel接続] エラー:', error);
        alert('ファイル選択に失敗しました: ' + error.message);
    }
}

// Excelシート一覧を取得
async function loadExcelSheets(filePath) {
    console.log('[Excel接続] シート一覧取得:', filePath);
    try {
        const response = await fetch('/api/excel/sheets', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ filePath: filePath })
        });

        if (!response.ok) {
            throw new Error('シート一覧の取得に失敗しました');
        }

        const result = await response.json();
        console.log('[Excel接続] シート一覧:', result);

        const sheetSelect = document.getElementById('excel-sheet-select');
        sheetSelect.innerHTML = '<option value="">シートを選択...</option>';

        if (result.success && result.sheets && result.sheets.length > 0) {
            result.sheets.forEach(sheet => {
                const option = document.createElement('option');
                option.value = sheet;
                option.textContent = sheet;
                sheetSelect.appendChild(option);
            });
            sheetSelect.disabled = false;
            sheetSelect.selectedIndex = 1; // 最初のシートを選択

            // シート選択時に接続ボタンを有効化
            sheetSelect.onchange = function() {
                const connectBtn = document.getElementById('excel-connect-btn');
                connectBtn.disabled = !this.value;
                excelConnectionState.sheetName = this.value;
            };

            // 自動的に最初のシートを選択
            excelConnectionState.sheetName = result.sheets[0];
            document.getElementById('excel-connect-btn').disabled = false;
        }
    } catch (error) {
        console.error('[Excel接続] シート取得エラー:', error);
        alert('シート一覧の取得に失敗しました: ' + error.message);
    }
}

// Excel接続（データ読み込み）
async function connectExcel() {
    const filePath = document.getElementById('excel-file-path').value;
    const sheetName = document.getElementById('excel-sheet-select').value;
    const variableName = document.getElementById('excel-variable-name').value || 'Excel2次元配列';

    if (!filePath || !sheetName) {
        alert('ファイルとシートを選択してください');
        return;
    }

    console.log('[Excel接続] 接続開始:', { filePath, sheetName, variableName });

    try {
        const response = await fetch('/api/excel/connect', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                filePath: filePath,
                sheetName: sheetName,
                variableName: variableName
            })
        });

        if (!response.ok) {
            throw new Error('Excel接続に失敗しました');
        }

        const result = await response.json();
        console.log('[Excel接続] 接続結果:', result);

        if (result.success) {
            excelConnectionState.connected = true;
            excelConnectionState.filePath = filePath;
            excelConnectionState.sheetName = sheetName;
            excelConnectionState.variableName = variableName;
            excelConnectionState.rowCount = result.rowCount;
            excelConnectionState.colCount = result.colCount;
            excelConnectionState.headers = result.headers || [];

            // サーバーで変数が保存されたので、変数を再読み込み
            console.log('[Excel接続] サーバーから変数を再読み込み');
            await loadVariables();
            console.log('[Excel接続] 変数読み込み完了, キー:', Object.keys(variables));

            updateExcelConnectionUI();

            // 接続情報を永続化
            await saveConnectionState();

            alert(`Excel接続完了: ${result.rowCount}行 x ${result.colCount}列 のデータを読み込みました`);
            console.log('[Excel接続] 接続完了');
        } else {
            throw new Error(result.error || '接続に失敗しました');
        }
    } catch (error) {
        console.error('[Excel接続] エラー:', error);
        alert('Excel接続に失敗しました: ' + error.message);
    }
}

// Excel切断
async function disconnectExcel() {
    console.log('[Excel接続] 切断');

    // 変数から削除
    if (excelConnectionState.variableName && variables[excelConnectionState.variableName]) {
        delete variables[excelConnectionState.variableName];
        saveVariablesToServer();
        // 変数リストを更新
        renderVariablesList();
    }

    // 状態をリセット
    excelConnectionState.connected = false;
    excelConnectionState.filePath = '';
    excelConnectionState.sheetName = '';
    excelConnectionState.data = null;
    excelConnectionState.rowCount = 0;
    excelConnectionState.colCount = 0;
    excelConnectionState.headers = [];

    // UIをリセット
    document.getElementById('excel-file-path').value = '';
    document.getElementById('excel-sheet-select').innerHTML = '<option value="">シートを選択...</option>';
    document.getElementById('excel-sheet-select').disabled = true;
    document.getElementById('excel-connect-btn').disabled = true;

    updateExcelConnectionUI();

    // 接続情報を永続化（切断状態を保存）
    await saveConnectionState();
}

// 変数をサーバーに保存
async function saveVariablesToServer() {
    try {
        await fetch('/api/variables', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(variables)
        });
    } catch (error) {
        console.error('[変数保存] エラー:', error);
    }
}

// ============================================
// ロボットプロファイル機能
// ============================================

// ロボット画像選択ダイアログを開く
function selectRobotImage() {
    document.getElementById('robot-image-input').click();
}

// ロボット画像を更新
function updateRobotImage(input) {
    if (input.files && input.files[0]) {
        const file = input.files[0];
        const reader = new FileReader();

        reader.onload = function(e) {
            const avatarImg = document.getElementById('robot-avatar-img');
            if (avatarImg) {
                avatarImg.src = e.target.result;
            }

            console.log('[ロボット] 画像が更新されました');

            // 画像更新後にプロファイルを保存
            saveRobotProfile();
        };

        reader.readAsDataURL(file);
    }
}

// ロボットのノード数を更新
function updateRobotNodeCount() {
    const nodeCount = nodes ? nodes.length : 0;
    const countElement = document.getElementById('robot-node-count');
    if (countElement) {
        countElement.textContent = nodeCount;
    }
}

// ロボットの背景色を選択（プリセットカラー）
function selectRobotBgColor(element) {
    const color = element.dataset.color;

    // 選択状態を更新
    document.querySelectorAll('.robot-bgcolor-circle').forEach(circle => {
        circle.classList.remove('selected');
    });
    element.classList.add('selected');

    // Canvasで背景色付き画像を生成（完了後に保存）
    generateRobotImageWithBg(color, true);

    console.log('[ロボット] 背景色を変更:', color);
}

// 背景色付きロボット画像を生成
function generateRobotImageWithBg(bgColor, saveAfter = false) {
    const avatarImg = document.getElementById('robot-avatar-img');
    if (!avatarImg) return;

    // 元のロボット画像を読み込み
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = function() {
        const canvas = document.createElement('canvas');
        const size = 200; // 高解像度
        canvas.width = size;
        canvas.height = size;
        const ctx = canvas.getContext('2d');

        // 背景色で円を描画
        ctx.fillStyle = bgColor;
        ctx.beginPath();
        ctx.arc(size/2, size/2, size/2, 0, Math.PI * 2);
        ctx.fill();

        // ロボット画像を中央に描画
        const imgSize = size * 0.75;
        const offset = (size - imgSize) / 2;
        ctx.drawImage(img, offset, offset, imgSize, imgSize);

        // アバター画像を更新
        avatarImg.src = canvas.toDataURL('image/png');

        // 画像生成完了後に保存
        if (saveAfter) {
            saveRobotProfile();
        }
    };

    // 常にrobo.pngを元画像として使用
    img.src = 'robo.png';
}

// 現在選択されている背景色を取得
function getSelectedBgColor() {
    const selected = document.querySelector('.robot-bgcolor-circle.selected');
    return selected ? selected.dataset.color : '#e8f4fc';
}

// ロボットプロファイルを保存
async function saveRobotProfile() {
    try {
        const profile = {
            name: document.getElementById('robot-name')?.value || '',
            author: document.getElementById('robot-author')?.value || '',
            role: document.getElementById('robot-role')?.value || '',
            memo: document.getElementById('robot-memo')?.value || '',
            image: getRobotImageData(),
            bgcolor: getSelectedBgColor(),
            hasVoice: document.getElementById('robot-has-voice')?.checked ?? true,
            hasDisplay: document.getElementById('robot-has-display')?.checked ?? true
        };

        const response = await fetch('/api/robot-profile', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(profile)
        });

        const result = await response.json();
        if (result.success) {
            console.log('[ロボット] プロファイルを保存しました');
        } else {
            console.error('[ロボット] 保存エラー:', result.error);
        }
    } catch (error) {
        console.error('[ロボット] 保存エラー:', error);
    }
}

// ロボット画像のデータURLを取得
function getRobotImageData() {
    const img = document.getElementById('robot-avatar-img');
    if (img && img.src) {
        // デフォルトのrobo.pngの場合は空文字を返す
        if (img.src.endsWith('robo.png')) {
            return '';
        }
        return img.src;
    }
    return '';
}

// ロボットプロファイルを読み込み
async function loadRobotProfile() {
    try {
        const response = await fetch('/api/robot-profile');
        const result = await response.json();

        if (result.success && result.profile) {
            const profile = result.profile;

            // フィールドに値を設定
            if (document.getElementById('robot-name')) {
                document.getElementById('robot-name').value = profile.name || '';
            }
            if (document.getElementById('robot-author')) {
                document.getElementById('robot-author').value = profile.author || '';
            }
            if (document.getElementById('robot-role')) {
                document.getElementById('robot-role').value = profile.role || '';
            }
            if (document.getElementById('robot-memo')) {
                document.getElementById('robot-memo').value = profile.memo || '';
            }

            // バージョンを表示
            if (document.getElementById('robot-version')) {
                document.getElementById('robot-version').textContent = profile.version || '1.0.0.0';
            }

            // 画像を復元
            if (profile.image && !profile.image.includes('robo.png')) {
                const avatarDiv = document.getElementById('robot-avatar');
                const avatarImg = document.getElementById('robot-avatar-img');

                if (avatarImg) {
                    avatarImg.src = profile.image;
                }
            }

            // 背景色を復元
            if (profile.bgcolor) {
                // 対応する色の円を選択状態にする
                document.querySelectorAll('.robot-bgcolor-circle').forEach(circle => {
                    circle.classList.remove('selected');
                    if (circle.dataset.color === profile.bgcolor) {
                        circle.classList.add('selected');
                    }
                });
                // Canvas で背景色付き画像を生成
                generateRobotImageWithBg(profile.bgcolor);
            }

            // 音声・表示チェックボックスを復元
            if (document.getElementById('robot-has-voice')) {
                document.getElementById('robot-has-voice').checked = profile.hasVoice !== false;
            }
            if (document.getElementById('robot-has-display')) {
                document.getElementById('robot-has-display').checked = profile.hasDisplay !== false;
            }

            console.log('[ロボット] プロファイルを読み込みました');
        } else {
            // プロファイルがない場合、デフォルト背景色で画像を生成
            generateRobotImageWithBg('#e8f4fc');
        }
    } catch (error) {
        console.error('[ロボット] 読み込みエラー:', error);
        // エラー時もデフォルト背景色で画像を生成
        generateRobotImageWithBg('#e8f4fc');
    }
}

// ロボットプロファイルの自動保存を設定
function setupRobotProfileAutoSave() {
    const fields = ['robot-name', 'robot-author', 'robot-role', 'robot-memo'];

    fields.forEach(fieldId => {
        const element = document.getElementById(fieldId);
        if (element) {
            // 入力が止まってから500ms後に保存
            let saveTimeout;
            element.addEventListener('input', () => {
                clearTimeout(saveTimeout);
                saveTimeout = setTimeout(saveRobotProfile, 500);
            });
        }
    });

    // チェックボックスの変更も保存トリガーに追加
    const checkboxes = ['robot-has-voice', 'robot-has-display'];
    checkboxes.forEach(checkboxId => {
        const element = document.getElementById(checkboxId);
        if (element) {
            element.addEventListener('change', () => {
                saveRobotProfile();
            });
        }
    });

    console.log('[ロボット] 自動保存を設定しました');
}

// ============================================
// 関数化機能
// ============================================

/**
 * 関数リストを描画
 * @param {string} filterText - フィルター文字列（省略可）
 */
function renderFunctionsList(filterText = '') {
    const listContainer = document.getElementById('functions-list');
    const emptyMessage = document.getElementById('functions-empty-message');

    if (!listContainer) return;

    // 空メッセージ以外をクリア
    const existingItems = listContainer.querySelectorAll('.function-item');
    existingItems.forEach(item => item.remove());

    // フィルタリング
    const filterLower = filterText.toLowerCase().trim();
    const filteredFunctions = filterLower
        ? userFunctions.filter(f => f.name.toLowerCase().includes(filterLower))
        : userFunctions;

    // 関数がない場合は空メッセージを表示
    if (userFunctions.length === 0) {
        if (emptyMessage) emptyMessage.style.display = 'block';
        return;
    }

    // フィルター結果が0件の場合
    if (filteredFunctions.length === 0 && filterLower) {
        if (emptyMessage) {
            emptyMessage.style.display = 'block';
            emptyMessage.textContent = `「${filterText}」に一致する関数がありません`;
        }
        return;
    }

    if (emptyMessage) {
        emptyMessage.style.display = 'none';
        emptyMessage.innerHTML = '関数がありません。<br>ノードを選択して右クリック→「関数化」で作成できます。';
    }

    // 関数アイテムを描画
    filteredFunctions.forEach(func => {
        const item = document.createElement('div');
        item.className = 'function-item';
        item.onclick = () => addFunctionToBoard(func.id);

        const nodeCount = func.nodes ? func.nodes.length : 0;

        item.innerHTML = `
            <div class="function-item-info">
                <div class="function-item-name">${escapeHtml(func.name)}</div>
                <div class="function-item-meta">
                    <span class="function-item-nodes">${nodeCount}ノード</span>
                </div>
            </div>
            <div class="function-item-actions">
                <button class="function-item-btn edit" onclick="event.stopPropagation(); editFunction('${func.id}')" title="編集">✏️</button>
                <button class="function-item-btn duplicate" onclick="event.stopPropagation(); duplicateFunction('${func.id}')" title="複製">📋</button>
                <button class="function-item-btn export" onclick="event.stopPropagation(); exportFunction('${func.id}')" title="エクスポート">📤</button>
                <button class="function-item-btn delete" onclick="event.stopPropagation(); deleteFunction('${func.id}')" title="削除">🗑️</button>
            </div>
        `;

        listContainer.appendChild(item);
    });

    console.log(`[関数] ${filteredFunctions.length}/${userFunctions.length}個の関数を描画しました`);
}

/**
 * 関数リストをフィルター
 * @param {string} searchText - 検索文字列
 */
function filterFunctions(searchText) {
    renderFunctionsList(searchText);
}

/**
 * 赤枠ノードを関数化する
 */
async function functionizeNodes() {
    console.log('[関数化] ========== 関数化開始 ==========');

    const layerNodes = layerStructure[leftVisibleLayer]?.nodes || [];
    let redBorderNodes = layerNodes.filter(n => n.redBorder);

    if (redBorderNodes.length === 0) {
        await showAlertDialog('関数化するには、まず赤枠でノードを選択してください。', '選択エラー');
        hideContextMenu();
        return;
    }

    // 赤枠に挟まれたノードも赤枠にする
    if (redBorderNodes.length >= 2) {
        const sortedNodes = [...layerNodes].sort((a, b) => a.y - b.y);
        const redBorderIndices = redBorderNodes.map(node => sortedNodes.findIndex(n => n.id === node.id));
        const startIndex = Math.min(...redBorderIndices);
        const endIndex = Math.max(...redBorderIndices);

        for (let i = startIndex + 1; i < endIndex; i++) {
            const enclosedNode = sortedNodes[i];
            if (!enclosedNode.redBorder) {
                enclosedNode.redBorder = true;
                const globalNode = nodes.find(n => n.id === enclosedNode.id);
                if (globalNode) globalNode.redBorder = true;
            }
        }
        redBorderNodes = layerNodes.filter(n => n.redBorder);
    }

    // Y座標でソート
    const sortedRedNodes = [...redBorderNodes].sort((a, b) => a.y - b.y);

    // 関数名を入力
    const functionName = await showPromptDialog('関数名を入力してください:', '関数化', 'マイ関数');
    if (!functionName) {
        hideContextMenu();
        return;
    }

    // 関数を作成（スクリプトをコード.jsonから取得）
    const newFunction = {
        id: `func_${functionIdCounter++}`,
        name: functionName,
        nodes: sortedRedNodes.map(node => {
            // スクリプトをコード.jsonから取得
            const script = getCodeEntry(node.id) || node.script || '';
            console.log(`[関数化] ノード ${node.text} (${node.id}) のスクリプト取得: ${script.length}文字`);
            return {
                id: node.id,
                text: node.text,
                color: node.color,
                処理番号: node.処理番号,
                script: script,
                groupId: node.groupId || null,
                width: node.width || 120,
                height: node.height || NODE_HEIGHT
            };
        }),
        params: [],    // 将来の拡張用
        returns: [],   // 将来の拡張用
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    };

    // 関数リストに追加
    userFunctions.push(newFunction);

    console.log(`[関数化] 関数を作成: ${newFunction.name} (${newFunction.nodes.length}ノード)`);

    // 関数をファイルに保存
    await saveFunctionToFile(newFunction);

    // 赤枠を解除
    sortedRedNodes.forEach(node => {
        node.redBorder = false;
        const globalNode = nodes.find(n => n.id === node.id);
        if (globalNode) globalNode.redBorder = false;
    });

    // 画面を再描画
    renderNodesInLayer(leftVisibleLayer, 'left');

    // 関数タブに切り替えて表示
    switchLeftPanelTab('functions');

    await showAlertDialog(`関数「${functionName}」を作成しました。`, '関数化完了');

    hideContextMenu();
    console.log('[関数化] ========== 関数化完了 ==========');
}

/**
 * 関数をボードに追加（関数ノードとして配置）
 */
async function addFunctionToBoard(functionId) {
    const func = userFunctions.find(f => f.id === functionId);
    if (!func) {
        console.error(`[関数] 関数が見つかりません: ${functionId}`);
        return;
    }

    console.log(`[関数] ボードに追加: ${func.name}`);

    const layerNodes = layerStructure[leftVisibleLayer]?.nodes || [];

    // 新しいノードのY座標を計算
    let maxY = 10;
    layerNodes.forEach(node => {
        const nodeBottom = (node.y || 0) + (node.height || NODE_HEIGHT);
        if (nodeBottom > maxY) maxY = nodeBottom;
    });
    const newY = maxY + 10;

    // 関数ノードを作成（水色）
    const newNodeIdNum = nodeCounter++;
    const newNodeId = `${newNodeIdNum}-1`;

    const functionNode = {
        id: newNodeId,
        text: func.name,
        color: 'Aquamarine',  // 水色
        処理番号: '98-1',     // 関数呼び出し用の処理番号
        layer: leftVisibleLayer,
        y: newY,
        x: 90,
        width: NODE_WIDTH,
        height: NODE_HEIGHT,
        functionId: func.id,  // 参照する関数ID
        script: generateFunctionScript(func),  // 関数の内容をスクリプトとして保存
        redBorder: false
    };

    // グローバル配列とレイヤーに追加
    nodes.push(functionNode);
    layerNodes.push(functionNode);

    console.log(`[関数] 関数ノード作成: ID=${newNodeId}, 関数=${func.name}`);

    // 関数内の各ノードのスクリプトをコード.jsonに保存
    for (const node of func.nodes) {
        if (node.script && node.script.trim() !== '') {
            console.log(`[関数] ノード「${node.text}」のスクリプトをコード.jsonに保存 (ID: ${node.id}, ${node.script.length}文字)`);
            try {
                await setCodeEntry(node.id, node.script);
            } catch (error) {
                console.error(`[関数] ノード「${node.text}」のスクリプト保存エラー:`, error);
            }
        }
    }

    // 画面を再描画
    renderNodesInLayer(leftVisibleLayer, 'left');
    refreshAllArrows();

    // memory.json自動保存
    saveMemoryJson();
}

/**
 * 関数のスクリプトを生成（ピンクノードと同様の形式）
 */
function generateFunctionScript(func) {
    // ノード情報を「ID;色;テキスト;groupId」形式で結合
    const nodeInfoList = func.nodes.map(node => {
        const groupIdStr = (node.groupId !== null && node.groupId !== undefined) ? node.groupId : '';
        return `${node.id};${node.color};${node.text};${groupIdStr}`;
    });
    return nodeInfoList.join('_');
}

/**
 * 関数をファイルに保存
 */
async function saveFunctionToFile(func) {
    try {
        const response = await fetch(`${API_BASE}/functions/save`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(func)
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        console.log(`[関数] ファイルに保存: ${func.name}`);
    } catch (error) {
        console.error(`[関数] 保存エラー:`, error);
        // API未実装の場合はローカルストレージに保存
        saveFunctionsToLocalStorage();
    }
}

/**
 * 関数をローカルストレージに保存（フォールバック）
 */
function saveFunctionsToLocalStorage() {
    try {
        localStorage.setItem('userFunctions', JSON.stringify(userFunctions));
        console.log(`[関数] ローカルストレージに保存: ${userFunctions.length}個`);
    } catch (error) {
        console.error(`[関数] ローカルストレージ保存エラー:`, error);
    }
}

/**
 * 関数をローカルストレージから読み込み
 */
function loadFunctionsFromLocalStorage() {
    try {
        const stored = localStorage.getItem('userFunctions');
        if (stored) {
            userFunctions = JSON.parse(stored);
            // IDカウンターを更新
            userFunctions.forEach(func => {
                const idNum = parseInt(func.id.replace('func_', ''));
                if (idNum >= functionIdCounter) {
                    functionIdCounter = idNum + 1;
                }
            });
            console.log(`[関数] ローカルストレージから読み込み: ${userFunctions.length}個`);
        }
    } catch (error) {
        console.error(`[関数] ローカルストレージ読み込みエラー:`, error);
    }
}

/**
 * 関数を削除
 */
async function deleteFunction(functionId) {
    const func = userFunctions.find(f => f.id === functionId);
    if (!func) return;

    const confirmed = await showConfirmDialog(
        `関数「${func.name}」を削除しますか？`,
        '関数削除確認'
    );

    if (!confirmed) return;

    // 配列から削除
    const index = userFunctions.findIndex(f => f.id === functionId);
    if (index !== -1) {
        userFunctions.splice(index, 1);
    }

    // ファイルから削除
    try {
        await fetch(`${API_BASE}/functions/delete`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id: functionId })
        });
    } catch (error) {
        console.error(`[関数] 削除エラー:`, error);
    }

    // ローカルストレージも更新
    saveFunctionsToLocalStorage();

    // リストを再描画
    renderFunctionsList();

    console.log(`[関数] 削除完了: ${func.name}`);
}

/**
 * 関数をエクスポート
 */
async function exportFunction(functionId) {
    const func = userFunctions.find(f => f.id === functionId);
    if (!func) return;

    // JSONファイルとしてダウンロード
    const jsonStr = JSON.stringify(func, null, 2);
    const blob = new Blob([jsonStr], { type: 'application/json' });
    const url = URL.createObjectURL(blob);

    const a = document.createElement('a');
    a.href = url;
    a.download = `${func.name}.json`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);

    console.log(`[関数] エクスポート: ${func.name}`);
}

/**
 * 関数を編集（エディタダイアログを開く）
 */
let currentEditingFunctionId = null;
let currentEditingNodes = [];

function editFunction(functionId) {
    const func = userFunctions.find(f => f.id === functionId);
    if (!func) {
        console.error(`[関数] 編集対象が見つかりません: ${functionId}`);
        return;
    }

    console.log(`[関数エディタ] 開始: ${func.name} (${func.nodes.length}ノード)`);

    currentEditingFunctionId = functionId;
    currentEditingNodes = JSON.parse(JSON.stringify(func.nodes)); // ディープコピー

    // モーダルを表示
    const modal = document.getElementById('function-editor-modal');
    const nameInput = document.getElementById('function-editor-name');

    if (modal && nameInput) {
        nameInput.value = func.name;
        renderFunctionEditorNodes();
        modal.style.display = 'flex';
    }
}

/**
 * 関数エディタを閉じる
 */
function closeFunctionEditor() {
    const modal = document.getElementById('function-editor-modal');
    if (modal) {
        modal.style.display = 'none';
    }
    currentEditingFunctionId = null;
    currentEditingNodes = [];
}

/**
 * 関数エディタのノードリストを描画
 */
function renderFunctionEditorNodes() {
    const listContainer = document.getElementById('function-editor-nodes-list');
    const countBadge = document.getElementById('function-editor-node-count');

    if (!listContainer) return;

    listContainer.innerHTML = '';

    if (currentEditingNodes.length === 0) {
        listContainer.innerHTML = '<div class="function-editor-empty-message">ノードがありません</div>';
    } else {
        currentEditingNodes.forEach((node, index) => {
            const item = document.createElement('div');
            item.className = 'function-editor-node-item';
            item.draggable = true;
            item.dataset.index = index;

            // ノードの色を背景に適用
            const nodeColor = getColorCode(node.color) || '#fff';
            item.style.backgroundColor = nodeColor;

            // スクリプトプレビューまたは処理番号を表示
            let infoText = '';
            if (node.script && node.script.trim()) {
                // スクリプトの最初の行を表示
                const firstLine = node.script.split('\n')[0].trim();
                infoText = firstLine.substring(0, 40) + (firstLine.length > 40 ? '...' : '');
            } else if (node.処理番号) {
                infoText = `処理番号: ${node.処理番号}`;
            }

            item.innerHTML = `
                <span class="function-editor-node-drag-handle">≡</span>
                <div class="function-editor-node-info">
                    <div class="function-editor-node-text">${escapeHtml(node.text || '無題')}</div>
                    <div class="function-editor-node-script-preview">${escapeHtml(infoText)}</div>
                </div>
                <div class="function-editor-node-actions">
                    <button class="function-editor-node-btn" onclick="editFunctionNodeName(${index})" title="名前変更">📝</button>
                    <button class="function-editor-node-btn" onclick="editFunctionNodeScript(${index})" title="スクリプト編集">✏️</button>
                    <button class="function-editor-node-btn delete" onclick="deleteFunctionNode(${index})" title="削除">🗑️</button>
                </div>
            `;

            // ドラッグ＆ドロップイベント
            item.addEventListener('dragstart', handleNodeDragStart);
            item.addEventListener('dragover', handleNodeDragOver);
            item.addEventListener('drop', handleNodeDrop);
            item.addEventListener('dragend', handleNodeDragEnd);

            listContainer.appendChild(item);
        });
    }

    if (countBadge) {
        countBadge.textContent = `${currentEditingNodes.length}個`;
    }
}

/**
 * ノードのドラッグ開始
 */
let draggedNodeIndex = null;

function handleNodeDragStart(e) {
    draggedNodeIndex = parseInt(e.target.dataset.index);
    e.target.classList.add('dragging');
    e.dataTransfer.effectAllowed = 'move';
}

/**
 * ノードのドラッグオーバー
 */
function handleNodeDragOver(e) {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';

    const item = e.target.closest('.function-editor-node-item');
    if (item && parseInt(item.dataset.index) !== draggedNodeIndex) {
        // 既存のdrag-overクラスを削除
        document.querySelectorAll('.function-editor-node-item.drag-over').forEach(el => {
            el.classList.remove('drag-over');
        });
        item.classList.add('drag-over');
    }
}

/**
 * ノードのドロップ
 */
function handleNodeDrop(e) {
    e.preventDefault();

    const item = e.target.closest('.function-editor-node-item');
    if (!item) return;

    const targetIndex = parseInt(item.dataset.index);

    if (draggedNodeIndex !== null && draggedNodeIndex !== targetIndex) {
        // ノードを並べ替え
        const [movedNode] = currentEditingNodes.splice(draggedNodeIndex, 1);
        currentEditingNodes.splice(targetIndex, 0, movedNode);

        console.log(`[関数エディタ] ノード並べ替え: ${draggedNodeIndex} → ${targetIndex}`);

        renderFunctionEditorNodes();
    }
}

/**
 * ノードのドラッグ終了
 */
function handleNodeDragEnd(e) {
    e.target.classList.remove('dragging');
    document.querySelectorAll('.function-editor-node-item.drag-over').forEach(el => {
        el.classList.remove('drag-over');
    });
    draggedNodeIndex = null;
}

/**
 * 関数内ノードの名前を変更
 */
async function editFunctionNodeName(index) {
    const node = currentEditingNodes[index];
    if (!node) return;

    console.log(`[関数エディタ] 名前変更: ${index} - ${node.text}`);

    const newText = await showPromptDialog(
        'ノード名を入力してください:',
        '名前の変更',
        node.text || ''
    );

    if (newText === null) return; // キャンセル

    node.text = newText.trim() || '無題';

    console.log(`[関数エディタ] 名前更新: ${node.text}`);
    renderFunctionEditorNodes();
}

/**
 * 関数内ノードのスクリプトを直接編集
 */
async function editFunctionNodeScript(index) {
    const node = currentEditingNodes[index];
    if (!node) return;

    console.log(`[関数エディタ] スクリプト編集: ${index} - ${node.text}`);

    // スクリプトが空の場合、generateCodeで生成するか確認
    let currentScript = node.script || '';

    if (!currentScript && node.処理番号) {
        const generateNew = await showConfirmDialog(
            'スクリプトが空です。新しいスクリプトを生成しますか？\n\n「はい」→ 引数設定ダイアログで生成\n「いいえ」→ 空のエディタを開く',
            'スクリプト生成'
        );

        if (generateNew) {
            try {
                const generatedScript = await generateCode(node.処理番号, node.id);
                if (generatedScript) {
                    node.script = generatedScript;
                    console.log(`[関数エディタ] スクリプト生成完了: ${generatedScript.length}文字`);
                    renderFunctionEditorNodes();
                    return;
                }
            } catch (error) {
                console.error('[関数エディタ] スクリプト生成エラー:', error);
            }
            return;
        }
    }

    // PowerShell Windows Formsダイアログで直接編集
    const requestBody = {
        nodeId: node.id,
        nodeName: node.text,
        currentScript: currentScript
    };

    try {
        const response = await fetch(`${API_BASE}/node/edit-script`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(requestBody)
        });

        const result = await response.json();

        if (!response.ok) {
            console.error('[関数エディタ] サーバーエラー:', result);
            await showAlertDialog(`エラーが発生しました: ${result.error || 'Unknown error'}`, 'サーバーエラー');
            return;
        }

        if (result.cancelled) {
            console.log('[関数エディタ] スクリプト編集がキャンセルされました');
            return;
        }

        if (result.success && result.newScript !== undefined) {
            node.script = result.newScript;

            console.log(`[関数エディタ] スクリプト更新: ${node.text}`);
            console.log(`[関数エディタ] 新スクリプト長: ${result.newScript.length}文字`);

            renderFunctionEditorNodes();
        }

    } catch (error) {
        console.error('[関数エディタ] スクリプト編集エラー:', error);
        await showAlertDialog(`スクリプト編集中にエラーが発生しました: ${error.message}`, 'エラー');
    }
}

/**
 * 関数内ノードを削除
 */
async function deleteFunctionNode(index) {
    const node = currentEditingNodes[index];
    if (!node) return;

    const confirmed = await showConfirmDialog(
        `ノード「${node.text || '無題'}」を削除しますか？`,
        'ノード削除確認'
    );

    if (!confirmed) return;

    currentEditingNodes.splice(index, 1);
    console.log(`[関数エディタ] ノード削除: ${index}`);
    renderFunctionEditorNodes();
}

/**
 * 関数にノードを追加（パレットを表示）
 */
function addNodeToFunction() {
    openNodePalette();
}

/**
 * ノード選択パレットを開く
 */
function openNodePalette() {
    const modal = document.getElementById('node-palette-modal');
    const container = document.getElementById('node-palette-buttons');

    if (!modal || !container) return;

    // ボタンを生成
    container.innerHTML = '';

    if (buttonSettings.length === 0) {
        container.innerHTML = '<div style="padding: 20px; text-align: center; color: #888;">ボタン設定が読み込まれていません</div>';
    } else {
        buttonSettings.forEach(setting => {
            const btn = document.createElement('button');
            btn.className = 'node-palette-btn';
            btn.textContent = setting.テキスト;
            btn.style.backgroundColor = getColorCode(setting.背景色);
            btn.title = setting.説明 || setting.テキスト;
            btn.onclick = () => selectNodeFromPalette(setting);
            container.appendChild(btn);
        });
    }

    modal.style.display = 'flex';
    console.log(`[ノードパレット] 開く - ${buttonSettings.length}個のボタン`);
}

/**
 * ノード選択パレットを閉じる
 */
function closeNodePalette() {
    const modal = document.getElementById('node-palette-modal');
    if (modal) {
        modal.style.display = 'none';
    }
}

/**
 * パレットからノードを選択して追加
 */
async function selectNodeFromPalette(setting) {
    console.log(`[関数エディタ] ノード選択: ${setting.テキスト} (${setting.処理番号})`);

    // パレットを一旦閉じる
    closeNodePalette();

    // 一時的なノードIDを生成（アンダースコアはメタデータの区切り文字と競合するため使用しない）
    const tempNodeId = `fn${Date.now()}`;

    // 条件分岐・ループは特殊処理が必要
    if (setting.処理番号 === '1-2' || setting.処理番号 === '1-3') {
        await showAlertDialog(
            '条件分岐・ループは関数内に直接追加できません。\n先にメインフローで作成してから関数化してください。',
            '制限事項'
        );
        return;
    }

    // generateCodeでスクリプトを生成（引数設定ダイアログが表示される）
    try {
        const generatedScript = await generateCode(setting.処理番号, tempNodeId);

        if (generatedScript === null || generatedScript === undefined) {
            console.log('[関数エディタ] スクリプト生成がキャンセルされました');
            return;
        }

        const newNode = {
            id: tempNodeId,
            text: setting.テキスト,
            color: setting.背景色 || 'LightBlue',
            処理番号: setting.処理番号,
            script: generatedScript,
            width: 120,
            height: NODE_HEIGHT
        };

        currentEditingNodes.push(newNode);
        console.log(`[関数エディタ] ノード追加完了: ${newNode.text} (${setting.処理番号})`);
        console.log(`[関数エディタ] スクリプト長: ${generatedScript.length}文字`);

        renderFunctionEditorNodes();

    } catch (error) {
        console.error('[関数エディタ] スクリプト生成エラー:', error);
        await showAlertDialog(`ノード追加中にエラーが発生しました: ${error.message}`, 'エラー');
    }
}

/**
 * 関数エディタの変更を保存
 */
async function saveFunctionEdits() {
    if (!currentEditingFunctionId) return;

    const func = userFunctions.find(f => f.id === currentEditingFunctionId);
    if (!func) return;

    const nameInput = document.getElementById('function-editor-name');
    const newName = nameInput ? nameInput.value.trim() : func.name;

    if (!newName) {
        await showAlertDialog('関数名を入力してください。', 'エラー');
        return;
    }

    // 更新
    func.name = newName;
    func.nodes = JSON.parse(JSON.stringify(currentEditingNodes));
    func.updatedAt = new Date().toISOString();

    console.log(`[関数エディタ] 保存: ${func.name} (${func.nodes.length}ノード)`);

    // 各ノードのスクリプトをコード.jsonに保存
    for (const node of func.nodes) {
        if (node.script && node.script.trim() !== '') {
            console.log(`[関数エディタ] ノード「${node.text}」のスクリプトをコード.jsonに保存 (ID: ${node.id}, ${node.script.length}文字)`);
            try {
                await setCodeEntry(node.id, node.script);
            } catch (error) {
                console.error(`[関数エディタ] ノード「${node.text}」のスクリプト保存エラー:`, error);
            }
        }
    }

    // ファイルに保存
    await saveFunctionToFile(func);

    // ローカルストレージも更新
    saveFunctionsToLocalStorage();

    // ボード上の該当する関数ノードも更新
    const newScript = generateFunctionScript(func);
    let updatedCount = 0;

    // グローバルnodesを更新
    nodes.forEach(node => {
        if (node.functionId === func.id) {
            node.script = newScript;
            node.text = func.name;  // 名前も更新
            updatedCount++;
        }
    });

    // layerStructure内のノードも更新
    Object.keys(layerStructure).forEach(layerKey => {
        const layerNodes = layerStructure[layerKey]?.nodes || [];
        layerNodes.forEach(node => {
            if (node.functionId === func.id) {
                node.script = newScript;
                node.text = func.name;
            }
        });
    });

    if (updatedCount > 0) {
        console.log(`[関数エディタ] ボード上の${updatedCount}個の関数ノードを更新しました`);
        // 画面を再描画
        renderNodesInLayer(leftVisibleLayer, 'left');
        // memory.jsonを保存
        saveMemoryJson();
    }

    // リストを再描画
    renderFunctionsList();

    // エディタを閉じる
    closeFunctionEditor();

    console.log(`[関数エディタ] 保存完了`);
}

/**
 * 関数を複製
 */
async function duplicateFunction(functionId) {
    const func = userFunctions.find(f => f.id === functionId);
    if (!func) {
        console.error(`[関数] 複製対象が見つかりません: ${functionId}`);
        return;
    }

    console.log(`[関数複製] 開始: ${func.name}`);

    // 新しい関数名を入力
    const newName = await showPromptDialog(
        '複製後の関数名を入力してください:',
        '関数の複製',
        `${func.name}_コピー`
    );

    if (!newName || newName.trim() === '') {
        console.log('[関数複製] キャンセルされました');
        return;
    }

    // 新しい関数を作成（ディープコピー）
    const newFunction = {
        id: `func_${functionIdCounter++}`,
        name: newName.trim(),
        nodes: JSON.parse(JSON.stringify(func.nodes)), // ディープコピー
        params: JSON.parse(JSON.stringify(func.params || [])),
        returns: JSON.parse(JSON.stringify(func.returns || [])),
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    };

    // 関数リストに追加
    userFunctions.push(newFunction);

    console.log(`[関数複製] 作成完了: ${newFunction.name} (${newFunction.nodes.length}ノード)`);

    // ファイルに保存
    await saveFunctionToFile(newFunction);

    // ローカルストレージも更新
    saveFunctionsToLocalStorage();

    // リストを再描画
    renderFunctionsList();

    console.log(`[関数複製] 完了: ${func.name} → ${newFunction.name}`);
}

/**
 * 関数をインポート
 */
async function importFunction() {
    // ファイル選択ダイアログを開く
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json';

    input.onchange = async (e) => {
        const file = e.target.files[0];
        if (!file) return;

        try {
            const text = await file.text();
            const func = JSON.parse(text);

            // 必須フィールドの検証
            if (!func.name || !func.nodes) {
                await showAlertDialog('無効な関数ファイルです。', 'インポートエラー');
                return;
            }

            // 新しいIDを割り当て
            func.id = `func_${functionIdCounter++}`;
            func.updatedAt = new Date().toISOString();

            // 関数リストに追加
            userFunctions.push(func);

            // 保存
            await saveFunctionToFile(func);
            saveFunctionsToLocalStorage();

            // リストを再描画
            renderFunctionsList();

            await showAlertDialog(`関数「${func.name}」をインポートしました。`, 'インポート完了');
            console.log(`[関数] インポート: ${func.name}`);
        } catch (error) {
            console.error(`[関数] インポートエラー:`, error);
            await showAlertDialog('ファイルの読み込みに失敗しました。', 'インポートエラー');
        }
    };

    input.click();
}

/**
 * 関数ノードの色判定（水色）
 */
function isAquamarineColor(colorString) {
    if (!colorString) return false;

    // 'Aquamarine' という名前でもマッチ
    if (colorString === 'Aquamarine') return true;

    // RGB値でマッチ
    const match = colorString.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
    if (match) {
        const r = parseInt(match[1]);
        const g = parseInt(match[2]);
        const b = parseInt(match[3]);
        return r === 127 && g === 255 && b === 212;
    }
    return false;
}

/**
 * 関数ノードをクリックした時の処理（ピンクノードと同様に展開）
 */
async function expandFunctionNode(node) {
    if (!node.functionId) {
        console.warn(`[関数] 関数IDが見つかりません: ${node.id}`);
        return;
    }

    const func = userFunctions.find(f => f.id === node.functionId);
    if (!func) {
        console.error(`[関数] 関数が見つかりません: ${node.functionId}`);
        return;
    }

    console.log(`[関数] 関数ノードを展開: ${func.name}`);

    // 関数の内容をモーダルで表示（ピンクノードと同様）
    const functionNodes = func.nodes.map((n, index) => ({
        ...n,
        id: `preview_${index}`,
        x: 90,
        y: 10 + (index * 50),
        layer: leftVisibleLayer + 1
    }));

    showLayerDetailModal(leftVisibleLayer + 1, functionNodes, node);
}

// ============================================
// ユーザーグループ機能（WinActor風グループ化）
// ============================================

/**
 * 赤枠ノードをグループ化する
 */
async function groupizeNodes() {
    hideContextMenu();

    const currentLayerNodes = layerStructure[leftVisibleLayer]?.nodes || [];
    const redBorderNodes = currentLayerNodes.filter(n => n.redBorder && !isUserGroup(n.groupId));

    if (redBorderNodes.length < 2) {
        await showAlertDialog('グループ化するには2個以上のノードを選択してください。', 'グループ化');
        return;
    }

    // Y座標でソート
    const sortedNodes = [...redBorderNodes].sort((a, b) => a.y - b.y);

    // バリデーション: 条件分岐/ループをまたいでいないかチェック
    const validationResult = validateGroupSelection(sortedNodes);
    if (!validationResult.valid) {
        await showAlertDialog(validationResult.error, 'グループ化エラー');
        return;
    }

    // グループ名を入力
    const groupName = await showPromptDialog('グループ名を入力してください:', 'グループ化', 'グループ');
    if (!groupName) {
        return; // キャンセル
    }

    // 新しいグループIDを生成
    const newGroupId = userGroupCounter++;

    // ユーザーグループ情報を保存
    userGroups[newGroupId] = {
        name: groupName,
        collapsed: false,
        nodeIds: sortedNodes.map(n => n.id),
        layer: leftVisibleLayer
    };

    // 各ノードにグループIDを設定
    sortedNodes.forEach(node => {
        node.userGroupId = newGroupId;
        node.redBorder = false; // 赤枠を解除
    });

    console.log(`[グループ化] グループ「${groupName}」を作成しました (ID: ${newGroupId}, ノード数: ${sortedNodes.length})`);

    // 再描画
    renderNodesInLayer(leftVisibleLayer);
    await saveMemoryJson();

    await showAlertDialog(`グループ「${groupName}」を作成しました。\n(${sortedNodes.length}個のノード)`, 'グループ化完了');
}

/**
 * グループ選択のバリデーション
 * - 条件分岐/ループをまたいでいないかチェック
 * - ネストしていないかチェック
 */
function validateGroupSelection(selectedNodes) {
    const nodeIds = new Set(selectedNodes.map(n => n.id));
    const currentLayerNodes = layerStructure[leftVisibleLayer]?.nodes || [];

    // 全ての条件分岐/ループグループを取得
    const structureGroups = {};  // { groupId: { nodes: [], type: 'loop' | 'condition' } }

    currentLayerNodes.forEach(node => {
        if (isLoopGroup(node.groupId)) {
            if (!structureGroups[node.groupId]) {
                structureGroups[node.groupId] = { nodes: [], type: 'loop' };
            }
            structureGroups[node.groupId].nodes.push(node);
        } else if (isConditionGroup(node.groupId)) {
            if (!structureGroups[node.groupId]) {
                structureGroups[node.groupId] = { nodes: [], type: 'condition' };
            }
            structureGroups[node.groupId].nodes.push(node);
        }
    });

    // 各構造グループについて、選択ノードが部分的にまたいでいないかチェック
    for (const [groupId, groupInfo] of Object.entries(structureGroups)) {
        const groupNodeIds = groupInfo.nodes.map(n => n.id);
        const selectedInGroup = groupNodeIds.filter(id => nodeIds.has(id));

        // グループの一部だけが選択されている場合はエラー
        if (selectedInGroup.length > 0 && selectedInGroup.length < groupNodeIds.length) {
            const typeName = groupInfo.type === 'loop' ? 'ループ' : '条件分岐';
            return {
                valid: false,
                error: `${typeName}の開始/終了ノードを部分的に選択することはできません。\n${typeName}全体を選択するか、${typeName}を含まないように選択してください。`
            };
        }
    }

    // 既存のユーザーグループに所属していないかチェック
    for (const node of selectedNodes) {
        if (isUserGroup(node.userGroupId)) {
            return {
                valid: false,
                error: `ノード「${node.text}」は既にグループに所属しています。\n先にグループを解除してください。`
            };
        }
    }

    return { valid: true };
}

/**
 * 非グループノードがユーザーグループ内に侵入しないかチェック
 */
function checkGroupInvasion(draggedNode, newY) {
    const currentLayerNodes = layerStructure[leftVisibleLayer]?.nodes || [];
    const nodeHeight = draggedNode.color === 'Gray' ? 1 : 40;
    const nodeBottom = newY + nodeHeight;

    // 全てのユーザーグループの範囲を取得
    const groupRanges = {};  // { groupId: { minY, maxY, name } }

    currentLayerNodes.forEach(node => {
        if (node.id === draggedNode.id) return;  // 自分自身はスキップ
        if (!isUserGroup(node.userGroupId)) return;

        const groupId = node.userGroupId;
        if (!groupRanges[groupId]) {
            const groupInfo = userGroups[groupId];
            groupRanges[groupId] = {
                minY: Infinity,
                maxY: -Infinity,
                name: groupInfo?.name || 'グループ'
            };
        }

        const nHeight = node.color === 'Gray' ? 1 : 40;
        groupRanges[groupId].minY = Math.min(groupRanges[groupId].minY, node.y);
        groupRanges[groupId].maxY = Math.max(groupRanges[groupId].maxY, node.y + nHeight);
    });

    // ドロップ位置がいずれかのグループ範囲内にあるかチェック
    for (const [groupId, range] of Object.entries(groupRanges)) {
        // ノードがグループ範囲と重なるかチェック
        const overlaps = newY < range.maxY && nodeBottom > range.minY;
        if (overlaps) {
            return {
                isProhibited: true,
                reason: `グループ「${range.name}」の内部には配置できません。\nグループ外に配置してください。`
            };
        }
    }

    return { isProhibited: false };
}

/**
 * ユーザーグループのオーバーレイ背景を描画
 */
function renderGroupOverlays(container, layerNodes) {
    // 既存のグループオーバーレイを削除
    container.querySelectorAll('.user-group-overlay').forEach(el => el.remove());

    // ユーザーグループを収集
    const groupedNodes = {};  // { groupId: [nodes] }

    layerNodes.forEach(node => {
        if (isUserGroup(node.userGroupId)) {
            if (!groupedNodes[node.userGroupId]) {
                groupedNodes[node.userGroupId] = [];
            }
            groupedNodes[node.userGroupId].push(node);
        }
    });

    // 各グループのオーバーレイを描画
    const groupColors = [
        'rgba(245, 158, 11, 0.15)',   // オレンジ
        'rgba(59, 130, 246, 0.15)',   // ブルー
        'rgba(16, 185, 129, 0.15)',   // グリーン
        'rgba(139, 92, 246, 0.15)',   // パープル
        'rgba(236, 72, 153, 0.15)',   // ピンク
    ];

    let colorIndex = 0;
    for (const [groupId, nodes] of Object.entries(groupedNodes)) {
        const groupInfo = userGroups[groupId];
        if (!groupInfo || groupInfo.collapsed) continue;  // 折りたたみ中はスキップ

        // グループの範囲を計算
        const sortedNodes = [...nodes].sort((a, b) => a.y - b.y);
        const minY = sortedNodes[0].y - 5;
        const lastNode = sortedNodes[sortedNodes.length - 1];
        const lastNodeHeight = lastNode.color === 'Gray' ? 1 : 40;
        const maxY = lastNode.y + lastNodeHeight + 5;

        // オーバーレイを作成
        const overlay = document.createElement('div');
        overlay.className = 'user-group-overlay';
        overlay.dataset.groupId = groupId;

        const baseColor = groupColors[colorIndex % groupColors.length];
        const borderColor = baseColor.replace('0.15', '0.4');

        overlay.style.cssText = `
            position: absolute;
            left: 5px;
            top: ${minY}px;
            width: calc(100% - 10px);
            height: ${maxY - minY}px;
            background: linear-gradient(180deg,
                ${baseColor} 0%,
                ${baseColor.replace('0.15', '0.1')} 50%,
                ${baseColor} 100%);
            pointer-events: none;
            z-index: 0;
            border-radius: 8px;
            border: 2px dashed ${borderColor};
        `;

        // グループ名ラベルを追加
        const label = document.createElement('div');
        label.className = 'user-group-label';
        label.textContent = `📁 ${groupInfo.name}`;
        label.style.cssText = `
            position: absolute;
            top: -2px;
            left: 10px;
            font-size: 11px;
            font-weight: bold;
            color: ${borderColor.replace('0.4', '0.9')};
            background: white;
            padding: 0 4px;
            border-radius: 3px;
            pointer-events: none;
        `;
        overlay.appendChild(label);

        container.appendChild(overlay);
        colorIndex++;
    }
}

/**
 * グループ移動のバリデーション
 * グループ全体を移動した場合に、条件分岐/ループと衝突しないかチェック
 */
function validateGroupMove(groupId, deltaY) {
    const currentLayerNodes = layerStructure[leftVisibleLayer]?.nodes || [];
    const groupNodes = currentLayerNodes.filter(n => n.userGroupId === groupId);

    if (groupNodes.length === 0) {
        return { valid: false, error: 'グループが見つかりません。' };
    }

    // グループの移動後の範囲を計算
    const sortedGroupNodes = [...groupNodes].sort((a, b) => a.y - b.y);
    const newMinY = sortedGroupNodes[0].y + deltaY;
    const lastNode = sortedGroupNodes[sortedGroupNodes.length - 1];
    const lastNodeHeight = lastNode.color === 'Gray' ? 1 : 40;
    const newMaxY = lastNode.y + deltaY + lastNodeHeight;

    // 最小値チェック
    if (newMinY < 10) {
        return { valid: false, error: '上端を超えて移動できません。' };
    }

    // グループに含まれないノードの条件分岐/ループ範囲をチェック
    const groupNodeIds = new Set(groupNodes.map(n => n.id));

    // 全ての条件分岐/ループグループを取得
    const structureGroups = {};  // { groupId: { nodes: [], type: 'loop' | 'condition', minY, maxY } }

    currentLayerNodes.forEach(node => {
        // グループに含まれるノードはスキップ
        if (groupNodeIds.has(node.id)) return;

        if (isLoopGroup(node.groupId)) {
            if (!structureGroups[node.groupId]) {
                structureGroups[node.groupId] = { nodes: [], type: 'loop' };
            }
            structureGroups[node.groupId].nodes.push(node);
        } else if (isConditionGroup(node.groupId)) {
            if (!structureGroups[node.groupId]) {
                structureGroups[node.groupId] = { nodes: [], type: 'condition' };
            }
            structureGroups[node.groupId].nodes.push(node);
        }
    });

    // 各構造グループの範囲を計算し、移動後のグループと重なりがないかチェック
    for (const [sgId, sgInfo] of Object.entries(structureGroups)) {
        if (sgInfo.nodes.length < 2) continue;  // 開始/終了が揃っていない場合はスキップ

        const sortedStructNodes = [...sgInfo.nodes].sort((a, b) => a.y - b.y);
        const structMinY = sortedStructNodes[0].y;
        const lastStructNode = sortedStructNodes[sortedStructNodes.length - 1];
        const lastStructHeight = lastStructNode.color === 'Gray' ? 1 : 40;
        const structMaxY = lastStructNode.y + lastStructHeight;

        // 範囲の重なりをチェック（部分的に含まれる場合はエラー）
        const overlaps = newMinY < structMaxY && newMaxY > structMinY;
        const fullyInside = newMinY >= structMinY && newMaxY <= structMaxY;
        const fullyOutside = newMaxY <= structMinY || newMinY >= structMaxY;

        if (overlaps && !fullyInside && !fullyOutside) {
            const typeName = sgInfo.type === 'loop' ? 'ループ' : '条件分岐';
            return {
                valid: false,
                error: `${typeName}の内部に部分的に入り込むことはできません。`
            };
        }
    }

    return { valid: true };
}

/**
 * グループを解除する
 */
async function ungroupNodes() {
    hideContextMenu();

    if (!contextMenuTarget || !isUserGroup(contextMenuTarget.userGroupId)) {
        await showAlertDialog('グループに所属していないノードです。', 'グループ解除');
        return;
    }

    const groupId = contextMenuTarget.userGroupId;
    const groupInfo = userGroups[groupId];

    if (!groupInfo) {
        await showAlertDialog('グループ情報が見つかりません。', 'グループ解除');
        return;
    }

    const confirmed = await showConfirmDialog(
        `グループ「${groupInfo.name}」を解除しますか？`,
        'グループ解除'
    );

    if (!confirmed) return;

    // グループに所属する全ノードのuserGroupIdをクリア
    const currentLayerNodes = layerStructure[leftVisibleLayer]?.nodes || [];
    currentLayerNodes.forEach(node => {
        if (node.userGroupId === groupId) {
            delete node.userGroupId;
        }
    });

    // グループ情報を削除
    delete userGroups[groupId];

    console.log(`[グループ解除] グループ「${groupInfo.name}」を解除しました`);

    // 再描画
    renderNodesInLayer(leftVisibleLayer);
    await saveMemoryJson();

    await showAlertDialog(`グループ「${groupInfo.name}」を解除しました。`, 'グループ解除完了');
}

/**
 * グループの折りたたみ/展開をトグルする
 */
async function toggleGroupCollapse() {
    hideContextMenu();

    if (!contextMenuTarget || !isUserGroup(contextMenuTarget.userGroupId)) {
        return;
    }

    const groupId = contextMenuTarget.userGroupId;
    const groupInfo = userGroups[groupId];

    if (!groupInfo) return;

    // 折りたたみ状態をトグル
    groupInfo.collapsed = !groupInfo.collapsed;

    console.log(`[グループ] グループ「${groupInfo.name}」を${groupInfo.collapsed ? '折りたたみ' : '展開'}しました`);

    // 再描画
    renderNodesInLayer(leftVisibleLayer);
    await saveMemoryJson();
}

/**
 * 入力ダイアログを表示
 */
function showPromptDialog(message, title, defaultValue = '') {
    return new Promise((resolve) => {
        // 既存のモーダルを流用するか、シンプルなpromptを使用
        const result = prompt(message, defaultValue);
        resolve(result);
    });
}

/**
 * ユーザーグループをmemory.jsonに保存するためのデータを取得
 */
function getUserGroupsForSave() {
    return JSON.parse(JSON.stringify(userGroups));
}

/**
 * memory.jsonからユーザーグループを復元
 */
function restoreUserGroups(savedGroups) {
    if (savedGroups && typeof savedGroups === 'object') {
        userGroups = JSON.parse(JSON.stringify(savedGroups));
        // userGroupCounterを更新
        const maxId = Math.max(3000, ...Object.keys(userGroups).map(id => parseInt(id)));
        userGroupCounter = maxId + 1;
        console.log(`[グループ復元] ${Object.keys(userGroups).length}個のグループを復元しました`);
    }
}

// ============================================
// 初期化時に関数をロード
// ============================================

// DOMContentLoadedで関数を読み込み
document.addEventListener('DOMContentLoaded', () => {
    loadFunctionsFromLocalStorage();
});
