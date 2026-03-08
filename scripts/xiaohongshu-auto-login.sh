#!/bin/bash
# 小红书自动登录脚本 - Cookie 持久化版本
# 一次登录，长期使用（30 天内免登录）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STORAGE_DIR="$SCRIPT_DIR/../storage"
COOKIES_FILE="$STORAGE_DIR/cookies.json"
STATE_FILE="$STORAGE_DIR/login-state.json"

# 创建存储目录
mkdir -p "$STORAGE_DIR"

echo "=========================================="
echo "📕 小红书自动登录（持久化版本）"
echo "=========================================="
echo ""

# 检查是否有有效的 Cookie
if [ -f "$COOKIES_FILE" ]; then
    echo "✅ 发现已保存的 Cookie"
    
    # 检查 Cookie 是否过期
    if [ -f "$STATE_FILE" ]; then
        LOGIN_TIME=$(cat "$STATE_FILE" | grep -o '"login_time":[0-9]*' | grep -o '[0-9]*')
        CURRENT_TIME=$(date +%s)
        EXPIRE_TIME=$((LOGIN_TIME + 2592000))  # 30 天 = 2592000 秒
        
        if [ "$CURRENT_TIME" -lt "$EXPIRE_TIME" ]; then
            DAYS_LEFT=$(( (EXPIRE_TIME - CURRENT_TIME) / 86400 ))
            echo "✅ Cookie 仍在有效期内（剩余 ${DAYS_LEFT} 天）"
            echo "✅ 使用已保存的 Cookie 自动登录"
            echo ""
            echo "=========================================="
            echo "✅ 登录成功（使用缓存 Cookie）"
            echo "=========================================="
            exit 0
        else
            echo "⚠️  Cookie 已过期（${DAYS_LEFT} 天前到期）"
        fi
    fi
    
    echo "🔄 Cookie 可能已过期，尝试重新登录..."
    echo ""
fi

# 需要重新登录
echo "📱 开始新的登录流程..."
echo ""

# 创建 Node.js 登录脚本（带 Cookie 保存）
cat > "$SCRIPT_DIR/auto-login.js" << 'EOFNODE'
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const COOKIES_FILE = process.argv[2];
const STATE_FILE = process.argv[3];

console.log('🌐 启动浏览器...');

(async () => {
    let browser;
    try {
        browser = await chromium.launch({
            headless: true,  // 无头模式（服务器没有 X 服务器）
            args: [
                '--window-size=1920,1080',
                '--no-sandbox',
                '--disable-blink-features=AutomationControlled',
                '--disable-dev-shm-usage',
                '--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
            ]
        });
        
        const context = await browser.newContext({
            viewport: { width: 1920, height: 1080 },
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
        
        console.log('📱 访问小红书...');
        await page.goto('https://www.xiaohongshu.com/', { 
            waitUntil: 'networkidle',
            timeout: 60000
        });
        
        await page.waitForTimeout(3000);
        
        // 尝试点击登录按钮
        try {
            const loginButton = await page.$('button:has-text("登录"), .login-button, [data-action="login"]');
            if (loginButton) {
                await loginButton.click();
                console.log('✓ 点击了登录按钮');
                await page.waitForTimeout(3000);
            }
        } catch (e) {
            console.log('ℹ️  已在登录页或未找到登录按钮');
        }
        
        // 截图保存二维码
        console.log('\n📸 截取登录二维码...');
        const qrPagePath = path.join(path.dirname(COOKIES_FILE), 'login-qr.png');
        await page.screenshot({ path: qrPagePath, fullPage: true });
        console.log(`✅ 二维码已保存：${qrPagePath}`);
        
        console.log('\n========================================');
        console.log('📲 请查看二维码图片并扫码登录');
        console.log('========================================');
        console.log('\n💡 提示：');
        console.log('  1. 打开图片查看二维码：' + qrPagePath);
        console.log('  2. 打开小红书 APP 扫一扫');
        console.log('  3. 确认登录');
        console.log('\n⏳ 等待登录完成（最长 5 分钟）...\n');
        
        // 等待登录（检测 Cookie 变化）
        let loggedIn = false;
        let waitTime = 0;
        const maxWaitTime = 300000;  // 5 分钟
        
        while (!loggedIn && waitTime < maxWaitTime) {
            await page.waitForTimeout(3000);
            waitTime += 3000;
            
            const cookies = await context.cookies();
            const hasAuth = cookies.some(c => 
                c.name.includes('a1') || 
                c.name.includes('web_session') ||
                c.name.includes('session')
            );
            
            if (hasAuth) {
                loggedIn = true;
                console.log('✅ 检测到登录成功！');
            } else {
                const elapsed = Math.floor(waitTime / 1000);
                console.log(`⏳ 等待中... (${elapsed}s)`);
            }
        }
        
        if (!loggedIn) {
            console.log('\n❌ 登录超时（5 分钟）');
            process.exit(1);
        }
        
        // 获取并保存 Cookie
        console.log('\n💾 保存 Cookie...');
        const cookies = await context.cookies();
        
        // 过滤出有用的 Cookie
        const usefulCookies = cookies.filter(c => 
            c.name.includes('a1') || 
            c.name.includes('web_session') ||
            c.name.includes('session') ||
            c.name.includes('xsec_token')
        );
        
        fs.writeFileSync(COOKIES_FILE, JSON.stringify(cookies, null, 2));
        console.log(`✅ 已保存 ${cookies.length} 个 Cookie 到 ${COOKIES_FILE}`);
        
        // 保存登录状态
        const loginState = {
            login_time: Math.floor(Date.now() / 1000),
            login_date: new Date().toISOString(),
            cookie_count: cookies.length,
            expires_in_days: 30
        };
        fs.writeFileSync(STATE_FILE, JSON.stringify(loginState, null, 2));
        console.log(`✅ 已保存登录状态到 ${STATE_FILE}`);
        
        console.log('\n========================================');
        console.log('✅ 登录成功！');
        console.log(`📅 登录时间：${loginState.login_date}`);
        console.log(`⏰ 有效期至：${new Date(Date.now() + 30 * 86400000).toISOString()}`);
        console.log('========================================\n');
        
        await browser.close();
        process.exit(0);
        
    } catch (error) {
        console.error('❌ 登录失败:', error.message);
        if (browser) {
            await browser.close();
        }
        process.exit(1);
    }
})();
EOFNODE

# 执行登录脚本
echo "🚀 启动登录流程..."
node "$SCRIPT_DIR/auto-login.js" "$COOKIES_FILE" "$STATE_FILE"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ 登录完成！"
    echo "=========================================="
    echo ""
    echo "📊 登录信息:"
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    fi
    echo ""
    echo "💡 提示:"
    echo "  - Cookie 已保存到：$COOKIES_FILE"
    echo "  - 30 天内无需重新登录"
    echo "  - 如需重新登录，删除 $STORAGE_DIR 目录即可"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "❌ 登录失败"
    echo "=========================================="
    echo ""
    exit 1
fi
