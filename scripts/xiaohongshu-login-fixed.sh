#!/bin/bash
# 小红书扫码登录脚本（修复版）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STORAGE_DIR="$SCRIPT_DIR/../storage"
QR_CODE_DIR="$SCRIPT_DIR/../qrcode"
COOKIES_FILE="$STORAGE_DIR/cookies.json"

# 清理并创建目录
rm -rf "$STORAGE_DIR/cookies.json"  # 删除可能是文件的 cookies.json
mkdir -p "$STORAGE_DIR" "$QR_CODE_DIR"

echo "=========================================="
echo "小红书扫码登录（修复版）"
echo "=========================================="
echo ""

# 创建修复后的 Node.js 登录脚本
cat > "$SCRIPT_DIR/login-fixed.js" << 'EOFNODE'
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const COOKIES_FILE = process.argv[1];
const QR_CODE_DIR = process.argv[2];

// 修复用户代理
const USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

(async () => {
    console.log('启动浏览器（带用户代理伪装）...');
    
    const browser = await chromium.launch({
        headless: true,
        args: [
            '--window-size=1920,1080',
            '--no-sandbox',
            '--disable-blink-features=AutomationControlled',
            '--disable-dev-shm-usage'
        ]
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        userAgent: USER_AGENT,
        locale: 'zh-CN',
        timezoneId: 'Asia/Shanghai'
    });
    
    // 隐藏自动化特征
    await context.addInitScript(() => {
        Object.defineProperty(navigator, 'webdriver', {
            get: () => undefined,
        });
    });
    
    const page = await context.newPage();
    
    console.log('访问小红书登录页面...');
    try {
        await page.goto('https://www.xiaohongshu.com/', { 
            waitUntil: 'networkidle',
            timeout: 60000
        });
    } catch (e) {
        console.log('页面加载可能受限:', e.message);
    }
    
    await page.waitForTimeout(5000);
    
    // 尝试点击登录按钮
    try {
        const loginButton = await page.$('button:has-text("登录"), .login-button, [data-action="login"], .login');
        if (loginButton) {
            await loginButton.click();
            console.log('点击了登录按钮');
            await page.waitForTimeout(3000);
        } else {
            console.log('未找到登录按钮，可能已在登录页');
        }
    } catch (e) {
        console.log('点击登录按钮失败:', e.message);
    }
    
    // 截图保存整个页面
    console.log('截取页面...');
    const qrPath = path.join(QR_CODE_DIR, 'login-qr-full.png');
    await page.screenshot({ path: qrPath, fullPage: true });
    console.log(`完整页面截图已保存到：${qrPath}`);
    
    // 尝试查找二维码元素
    console.log('查找二维码...');
    await page.waitForTimeout(3000);
    
    try {
        // 尝试多种选择器查找二维码
        const selectors = [
            'canvas',
            'img[src*="qr"]',
            'img[src*="code"]',
            '.qrcode',
            '#qrcode',
            '[class*="qr"]',
            '[class*="code"]'
        ];
        
        for (const selector of selectors) {
            try {
                const qrElement = await page.$(selector);
                if (qrElement) {
                    const qrElementPath = path.join(QR_CODE_DIR, 'login-qr-code.png');
                    await qrElement.screenshot({ path: qrElementPath });
                    console.log(`二维码截图已保存到：${qrElementPath}`);
                    break;
                }
            } catch (e) {
                continue;
            }
        }
    } catch (e) {
        console.log('查找二维码元素失败');
    }
    
    console.log('\n========================================');
    console.log('二维码图片位置：' + QR_CODE_DIR);
    console.log('请用小红书 APP 扫码登录');
    console.log('等待 5 分钟...');
    console.log('========================================\n');
    
    // 等待登录
    let loggedIn = false;
    try {
        await page.waitForFunction(() => {
            const url = window.location.href;
            return url.includes('/explore/') || 
                   url.includes('/user/') ||
                   url.includes('/profile');
        }, { timeout: 300000 });
        loggedIn = true;
        console.log('检测到登录成功！');
    } catch (e) {
        console.log('等待超时');
    }
    
    // 保存 cookies
    const cookies = await context.cookies();
    if (cookies.length > 0) {
        fs.writeFileSync(COOKIES_FILE, JSON.stringify(cookies, null, 2));
        console.log(`\n✓ Cookies 已保存到：${COOKIES_FILE}`);
        console.log(`✓ 共保存 ${cookies.length} 个 cookies`);
    } else {
        console.log('\n⚠ 未获取到 cookies');
    }
    
    await browser.close();
    console.log('\n登录流程完成！');
})();
EOFNODE

# 运行修复后的登录脚本
node "$SCRIPT_DIR/login-fixed.js" "$COOKIES_FILE" "$QR_CODE_DIR"

# 检查结果
echo ""
echo "=========================================="
if [ -f "$COOKIES_FILE" ]; then
    COOKIE_COUNT=$(jq length "$COOKIES_FILE" 2>/dev/null || echo "0")
    if [ "$COOKIE_COUNT" -gt 0 ]; then
        echo "✓ 登录成功！保存了 $COOKIE_COUNT 个 cookies"
    else
        echo "⚠ Cookies 文件为空"
    fi
else
    echo "⚠ Cookies 文件未创建"
fi

if [ -f "$QR_CODE_DIR/login-qr-full.png" ]; then
    echo "✓ 二维码截图：$QR_CODE_DIR/login-qr-full.png"
fi
echo "=========================================="
