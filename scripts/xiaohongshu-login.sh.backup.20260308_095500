#!/bin/bash
# 小红书扫码登录脚本（无头模式）
# 生成登录二维码图片，用户扫码后保存 cookies

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STORAGE_DIR="$SCRIPT_DIR/../storage"
COOKIES_FILE="$STORAGE_DIR/cookies.json"
QR_CODE_DIR="$SCRIPT_DIR/../qrcode"

# 创建目录
mkdir -p "$STORAGE_DIR" "$QR_CODE_DIR"

log_info "启动小红书扫码登录（无头模式）..."

# 创建 Node.js 登录脚本
cat > "$SCRIPT_DIR/login.js" << 'EOF'
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const COOKIES_FILE = process.argv[1];
const QR_CODE_DIR = process.argv[2];

(async () => {
    console.log('启动浏览器...');
    
    const browser = await chromium.launch({
        headless: true,
        args: ['--window-size=1280,800', '--no-sandbox']
    });
    
    const context = await browser.newContext({
        viewport: { width: 1280, height: 800 }
    });
    
    const page = await context.newPage();
    
    console.log('访问小红书登录页面...');
    await page.goto('https://www.xiaohongshu.com/', { waitUntil: 'networkidle' });
    
    // 尝试点击登录按钮
    try {
        await page.click('button:has-text("登录"), .login-button, [data-action="login"]', { timeout: 5000 });
        console.log('点击登录按钮');
        await page.waitForTimeout(2000);
    } catch (e) {
        console.log('未找到登录按钮或已在登录页');
    }
    
    // 查找二维码并截图
    console.log('查找登录二维码...');
    await page.waitForTimeout(3000);
    
    // 尝试截取整个页面作为二维码
    const qrPath = path.join(QR_CODE_DIR, 'login-qr.png');
    await page.screenshot({ path: qrPath, fullPage: true });
    console.log(`二维码已保存到：${qrPath}`);
    
    // 尝试查找二维码元素并单独截图
    try {
        const qrElement = await page.$('canvas, img[src*="qr"], img[src*="code"], .qrcode, #qrcode');
        if (qrElement) {
            const qrElementPath = path.join(QR_CODE_DIR, 'login-qr-element.png');
            await qrElement.screenshot({ path: qrElementPath });
            console.log(`二维码元素已保存到：${qrElementPath}`);
        }
    } catch (e) {
        console.log('未找到独立二维码元素');
    }
    
    console.log('\n========================================');
    console.log('请查看二维码图片并用小红书 APP 扫码');
    console.log('等待扫码登录中...（最长 5 分钟）');
    console.log('========================================\n');
    
    // 等待登录（检测 URL 变化）
    try {
        await page.waitForFunction(() => {
            return window.location.href.includes('/explore/') || 
                   window.location.href.includes('/user/');
        }, { timeout: 300000 });
        console.log('检测到登录成功！');
    } catch (e) {
        console.log('等待超时，检查是否已登录...');
    }
    
    // 保存 cookies
    const cookies = await context.cookies();
    if (cookies.length > 0) {
        fs.writeFileSync(COOKIES_FILE, JSON.stringify(cookies, null, 2));
        console.log(`Cookies 已保存到：${COOKIES_FILE}`);
        console.log(`共保存 ${cookies.length} 个 cookies`);
    } else {
        console.log('未获取到 cookies，登录可能失败');
        process.exit(1);
    }
    
    await browser.close();
    console.log('登录完成！');
})();
EOF

# 运行登录脚本
node "$SCRIPT_DIR/login.js" "$COOKIES_FILE" "$QR_CODE_DIR"

# 检查 cookies 是否保存成功
if [ -f "$COOKIES_FILE" ]; then
    COOKIE_COUNT=$(jq length "$COOKIES_FILE" 2>/dev/null || echo "0")
    if [ "$COOKIE_COUNT" -gt 0 ]; then
        log_info "登录成功！保存了 $COOKIE_COUNT 个 cookies"
        log_info "下次发布将自动使用这些 cookies"
        log_info "二维码图片位置：$QR_CODE_DIR"
    else
        log_error "Cookies 文件为空，登录可能失败"
        exit 1
    fi
else
    log_error "Cookies 文件未创建，登录失败"
    exit 1
fi
