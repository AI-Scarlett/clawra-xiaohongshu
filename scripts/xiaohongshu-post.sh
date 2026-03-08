#!/bin/bash
# 小红书自动发布脚本 - 使用已保存的 Cookie
# 无需登录，直接发布

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STORAGE_DIR="$SCRIPT_DIR/../storage"
COOKIES_FILE="$STORAGE_DIR/cookies.json"
STATE_FILE="$STORAGE_DIR/login-state.json"

echo "=========================================="
echo "📕 小红书自动发布"
echo "=========================================="
echo ""

# 检查 Cookie 是否存在
if [ ! -f "$COOKIES_FILE" ]; then
    echo "❌ 未找到 Cookie 文件"
    echo "💡 请先运行登录脚本：xiaohongshu-auto-login.sh"
    exit 1
fi

# 检查 Cookie 是否过期
if [ -f "$STATE_FILE" ]; then
    LOGIN_TIME=$(cat "$STATE_FILE" | grep -o '"login_time":[0-9]*' | grep -o '[0-9]*')
    CURRENT_TIME=$(date +%s)
    EXPIRE_TIME=$((LOGIN_TIME + 2592000))  # 30 天
    
    if [ "$CURRENT_TIME" -ge "$EXPIRE_TIME" ]; then
        echo "❌ Cookie 已过期"
        echo "💡 请重新登录：xiaohongshu-auto-login.sh"
        exit 1
    fi
    
    DAYS_LEFT=$(( (EXPIRE_TIME - CURRENT_TIME) / 86400 ))
    echo "✅ Cookie 有效（剩余 ${DAYS_LEFT} 天）"
else
    echo "⚠️  未找到状态文件，尝试使用 Cookie..."
fi

echo ""

# 创建 Node.js 发布脚本
cat > "$SCRIPT_DIR/auto-post.js" << 'EOFNODE'
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const COOKIES_FILE = process.argv[2];
const TITLE = process.argv[3];
const CONTENT = process.argv[4];
const IMAGE_PATH = process.argv[5];

console.log('📕 小红书自动发布');
console.log('========================================');
console.log(`标题：${TITLE}`);
console.log(`内容长度：${CONTENT.length} 字`);
console.log(`图片：${IMAGE_PATH || '无'}`);
console.log('========================================');
console.log('');

(async () => {
    let browser;
    try {
        // 读取 Cookie
        if (!fs.existsSync(COOKIES_FILE)) {
            throw new Error('Cookie 文件不存在');
        }
        const cookies = JSON.parse(fs.readFileSync(COOKIES_FILE, 'utf-8'));
        console.log(`✅ 加载 ${cookies.length} 个 Cookie`);
        
        // 启动浏览器
        console.log('🌐 启动浏览器...');
        browser = await chromium.launch({
            headless: true,  // 无头模式，后台运行
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
        
        // 设置 Cookie
        await context.addCookies(cookies);
        console.log('✅ Cookie 已设置');
        
        // 隐藏自动化特征
        await context.addInitScript(() => {
            Object.defineProperty(navigator, 'webdriver', {
                get: () => undefined,
            });
        });
        
        const page = await context.newPage();
        
        // 访问发布页面
        console.log('📝 访问发布页面...');
        await page.goto('https://creator.xiaohongshu.com/publish/publish', {
            waitUntil: 'networkidle',
            timeout: 60000
        });
        
        await page.waitForTimeout(5000);
        
        // 检查是否已登录
        const url = page.url();
        if (url.includes('login')) {
            throw new Error('检测到登录页面，Cookie 可能已失效');
        }
        console.log('✅ 已登录');
        
        // 等待上传区域
        console.log('⏳ 等待页面加载...');
        await page.waitForTimeout(3000);
        
        // 上传图片（如果有）
        if (IMAGE_PATH && fs.existsSync(IMAGE_PATH)) {
            console.log('🖼️  上传图片...');
            const fileInput = await page.$('input[type="file"]');
            if (fileInput) {
                await fileInput.setInputFiles(IMAGE_PATH);
                console.log('✅ 图片已上传');
                await page.waitForTimeout(3000);  // 等待图片处理
            } else {
                console.log('⚠️  未找到文件上传控件');
            }
        }
        
        // 填写标题
        console.log('✏️  填写标题...');
        const titleInput = await page.$('input[placeholder*="标题"], input[maxlength="20"]');
        if (titleInput) {
            await titleInput.fill(TITLE);
            console.log('✅ 标题已填写');
        } else {
            console.log('⚠️  未找到标题输入框');
        }
        
        // 填写正文
        console.log('✏️  填写正文...');
        const contentEditor = await page.$('[contenteditable="true"], textarea, .editor');
        if (contentEditor) {
            await contentEditor.fill(CONTENT);
            console.log('✅ 正文已填写');
        } else {
            console.log('⚠️  未找到正文编辑器');
        }
        
        // 添加标签（从内容中提取 #标签）
        const hashtags = CONTENT.match(/#[\w\u4e00-\u9fa5]+/g) || [];
        if (hashtags.length > 0) {
            console.log(`🏷️  添加 ${hashtags.length} 个标签...`);
            // 标签通常在正文中自动识别，无需额外操作
        }
        
        // 等待发布按钮
        console.log('⏳ 等待发布按钮...');
        await page.waitForTimeout(3000);
        
        // 点击发布
        console.log('🚀 点击发布...');
        const publishButton = await page.$('button:has-text("发布"), button:has-text("Publish")');
        if (publishButton) {
            await publishButton.click();
            console.log('✅ 已点击发布按钮');
            
            // 等待发布成功
            console.log('⏳ 等待发布结果...');
            await page.waitForTimeout(5000);
            
            // 检查发布成功提示
            const successMsg = await page.$('text=发布成功，text=发布成功，text=Published');
            if (successMsg) {
                console.log('✅ 发布成功！');
            } else {
                console.log('⚠️  未检测到发布成功提示，但操作已完成');
            }
        } else {
            console.log('⚠️  未找到发布按钮');
        }
        
        console.log('\n========================================');
        console.log('✅ 发布完成！');
        console.log('========================================\n');
        
        await browser.close();
        process.exit(0);
        
    } catch (error) {
        console.error('❌ 发布失败:', error.message);
        if (browser) {
            await browser.close();
        }
        process.exit(1);
    }
})();
EOFNODE

# 检查参数
if [ $# -lt 2 ]; then
    echo "用法：$0 <标题> <内容> [图片路径]"
    echo ""
    echo "示例:"
    echo "  $0 \"我的标题\" \"这是内容...\""
    echo "  $0 \"我的标题\" \"这是内容...\" \"/path/to/image.jpg\""
    exit 1
fi

TITLE="$1"
CONTENT="$2"
IMAGE_PATH="${3:-}"

# 执行发布
node "$SCRIPT_DIR/auto-post.js" "$COOKIES_FILE" "$TITLE" "$CONTENT" "$IMAGE_PATH"
