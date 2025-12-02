// ============================================
// UIpowershell - Aurora Arrow Drawing Patch
// 既存の矢印描画関数をAurora風グラデーションに置き換えるパッチ
// 既存の機能はすべて保持
// ============================================

// Aurora色定義（グローバル設定に追加）
const AURORA_COLORS = {
    default: ['#667eea', '#764ba2'],
    green: ['#10b981', '#06b6d4'],   // 条件分岐開始/終了
    red: ['#ef4444', '#f87171'],      // False分岐
    blue: ['#3b82f6', '#60a5fa'],     // True分岐
    yellow: ['#fbbf24', '#f59e0b'],   // ループ
    pink: ['#ec4899', '#f472b6'],     // スクリプト化
    gray: ['#6b7280', '#9ca3af']      // デフォルト
};

// ============================================
// 既存のdrawDownArrow関数をAurora版に置き換え
// ※ ただしプレーンノード間（黒矢印）はシンプルな描画を維持
// ============================================
// このパッチは app-legacy.js の drawDownArrow より後に読み込まれるが、
// app-legacy.js側の関数が優先されるように、ここでは何もしない
// （app-legacy.jsで正しく定義済みのため、上書きしない）

// ============================================
// 既存のdrawBranchArrow関数をAurora版に置き換え
// ============================================
function drawBranchArrow(ctx, fromNode, toNode, branchType = 'true') {
    const fromRect = fromNode.getBoundingClientRect();
    const toRect = toNode.getBoundingClientRect();
    const containerRect = fromNode.closest('.node-list-container').getBoundingClientRect();

    const startX = fromRect.left + fromRect.width / 2 - containerRect.left;
    const startY = fromRect.bottom - containerRect.top;
    const endX = toRect.left + toRect.width / 2 - containerRect.left;
    const endY = toRect.top - containerRect.top;

    // 分岐タイプに応じたAurora色を選択
    const gradientColors = branchType === 'false' ? AURORA_COLORS.red : AURORA_COLORS.blue;

    // グラデーション作成
    const gradient = ctx.createLinearGradient(startX, startY, endX, endY);
    gradient.addColorStop(0, gradientColors[0]);
    gradient.addColorStop(1, gradientColors[1]);

    // 発光効果
    ctx.shadowColor = gradientColors[0];
    ctx.shadowBlur = 10;

    // 曲線の制御点を計算（既存のロジックを保持）
    const controlX = branchType === 'false' ? 
        Math.min(startX - 50, endX - 30) : 
        Math.max(startX + 50, endX + 30);
    const controlY = (startY + endY) / 2;

    // 曲線を描画
    ctx.strokeStyle = gradient;
    ctx.lineWidth = 3;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    
    ctx.beginPath();
    ctx.moveTo(startX, startY);
    ctx.quadraticCurveTo(controlX, controlY, endX, endY);
    ctx.stroke();

    // 矢印ヘッドを描画
    const angle = Math.atan2(endY - controlY, endX - controlX);
    drawArrowHeadAtAngle(ctx, endX, endY, angle, 10, 30, gradientColors[1]);

    // 影をリセット
    ctx.shadowBlur = 0;
    ctx.shadowColor = 'transparent';
}

// ============================================
// 矢印ヘッド描画の更新（色指定対応）
// ============================================
// 注: app-legacy.jsのdrawArrowHead関数を優先するため、ここでは定義しない
// app-legacy.jsの関数はstrokeStyleを使用してシンプルな矢印ヘッドを描画する

// 角度指定版の矢印ヘッド描画
function drawArrowHeadAtAngle(ctx, x, y, angle, headLength = 10, headAngle = 30, fillColor = null) {
    const headRadian = headAngle * Math.PI / 180;

    if (fillColor) {
        ctx.fillStyle = fillColor;
    }

    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.lineTo(
        x - headLength * Math.cos(angle - headRadian),
        y - headLength * Math.sin(angle - headRadian)
    );
    ctx.lineTo(
        x - headLength * Math.cos(angle + headRadian),
        y - headLength * Math.sin(angle + headRadian)
    );
    ctx.closePath();
    ctx.fill();
}

// ============================================
// ループ矢印のAurora版更新
// ============================================
function drawLoopArrow(ctx, fromNode, toNode, direction = 'right') {
    const fromRect = fromNode.getBoundingClientRect();
    const toRect = toNode.getBoundingClientRect();
    const containerRect = fromNode.closest('.node-list-container').getBoundingClientRect();

    const startX = fromRect.left + fromRect.width / 2 - containerRect.left;
    const startY = fromRect.bottom - containerRect.top;
    const endX = toRect.left + toRect.width / 2 - containerRect.left;
    const endY = toRect.top - containerRect.top;

    // ループはAurora黄色系グラデーション
    const gradientColors = AURORA_COLORS.yellow;

    // グラデーション作成
    const gradient = ctx.createLinearGradient(startX, startY, endX, endY);
    gradient.addColorStop(0, gradientColors[0]);
    gradient.addColorStop(1, gradientColors[1]);

    // 発光効果（ループは少し強めに）
    ctx.shadowColor = gradientColors[0];
    ctx.shadowBlur = 12;

    // ループの曲線を描画
    const loopOffset = direction === 'right' ? 60 : -60;
    const cp1x = startX + loopOffset;
    const cp1y = startY + 20;
    const cp2x = endX + loopOffset;
    const cp2y = endY - 20;

    ctx.strokeStyle = gradient;
    ctx.lineWidth = 3;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    
    ctx.beginPath();
    ctx.moveTo(startX, startY);
    ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, endX, endY);
    ctx.stroke();

    // 矢印ヘッド
    const angle = Math.atan2(endY - cp2y, endX - cp2x);
    drawArrowHeadAtAngle(ctx, endX, endY, angle, 10, 30, gradientColors[1]);

    // 影をリセット
    ctx.shadowBlur = 0;
    ctx.shadowColor = 'transparent';
}

// ============================================
// グローエフェクト用の特別な矢印描画（ピンクノード展開時）
// ============================================
function drawGlowArrow(ctx, fromNode, toNode) {
    const fromRect = fromNode.getBoundingClientRect();
    const toRect = toNode.getBoundingClientRect();
    const containerRect = fromNode.closest('.node-list-container').getBoundingClientRect();

    const startX = fromRect.left + fromRect.width / 2 - containerRect.left;
    const startY = fromRect.bottom - containerRect.top;
    const endX = toRect.left + toRect.width / 2 - containerRect.left;
    const endY = toRect.top - containerRect.top;

    // ピンクのAuroraグラデーション
    const gradientColors = AURORA_COLORS.pink;

    // アニメーション用のパルス効果
    const pulseIntensity = (Math.sin(Date.now() / 300) + 1) / 2;
    const glowSize = 10 + pulseIntensity * 10;

    // グラデーション作成
    const gradient = ctx.createLinearGradient(startX, startY, endX, endY);
    gradient.addColorStop(0, gradientColors[0]);
    gradient.addColorStop(0.5, '#ff6ec7');  // 中間に明るいピンク
    gradient.addColorStop(1, gradientColors[1]);

    // 強い発光効果
    ctx.shadowColor = gradientColors[0];
    ctx.shadowBlur = glowSize;

    // 線を描画（少し太め）
    ctx.strokeStyle = gradient;
    ctx.lineWidth = 4;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    
    // 二重線でより強調
    ctx.globalAlpha = 0.5;
    ctx.beginPath();
    ctx.moveTo(startX, startY);
    ctx.lineTo(endX, endY);
    ctx.stroke();

    ctx.globalAlpha = 1;
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(startX, startY);
    ctx.lineTo(endX, endY);
    ctx.stroke();

    // 矢印ヘッド
    drawArrowHead(ctx, startX, startY, endX, endY, 12, 30, gradientColors[1]);

    // リセット
    ctx.shadowBlur = 0;
    ctx.shadowColor = 'transparent';
    ctx.globalAlpha = 1;
}

// ============================================
// 既存のdrawArrows関数をパッチ（Aurora効果を削除）
// ============================================
// 注: グロー効果（drop-shadow フィルター）は削除済み
// プレーンノード間の矢印は黒いシンプルな線で描画する

// ============================================
// ユーティリティ: 色のブレンド（グラデーション中間色用）
// ============================================
function blendColors(color1, color2, ratio) {
    const hex2rgb = (hex) => {
        const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
        return result ? {
            r: parseInt(result[1], 16),
            g: parseInt(result[2], 16),
            b: parseInt(result[3], 16)
        } : null;
    };
    
    const rgb2hex = (r, g, b) => {
        return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
    };
    
    const c1 = hex2rgb(color1);
    const c2 = hex2rgb(color2);
    
    if (!c1 || !c2) return color1;
    
    const r = Math.round(c1.r * (1 - ratio) + c2.r * ratio);
    const g = Math.round(c1.g * (1 - ratio) + c2.g * ratio);
    const b = Math.round(c1.b * (1 - ratio) + c2.b * ratio);
    
    return rgb2hex(r, g, b);
}

console.log('UIpowershell Aurora Arrow Patch Applied');
