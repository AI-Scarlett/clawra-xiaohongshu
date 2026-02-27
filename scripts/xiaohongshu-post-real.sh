#!/bin/bash
# 小红书真实发布脚本（Xvfb + Playwright 无头浏览器）
# 模拟真人操作发布笔记

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
TEMP_DIR="/tmp/xhs_real_$$"

mkdir -p "$TEMP_DIR"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# 参数
IMAGE1="${1:-}"
IMAGE2="${2:-}"
IMAGE3="${3:-}"
TITLE="${4:-今日穿搭分享}"
CAPTION="${5:-}"

if [ -z "$IMAGE1" ] || [ -z "$IMAGE2" ]; then
    log_error "用法：$0 <图 1> <图 2> [图 3] [标题] [文案]"
    exit 1
fi

log_info "准备发布小红书笔记..."
log_info "图片 1: $IMAGE1"
log_info "图片 2: $IMAGE2"
log_info "图片 3: ${IMAGE3:-无}"

# 检查 cookies
if [ ! -f "$COOKIES_FILE" ]; then
    log_error "未找到 cookies 文件"
    exit 1
fi

# 启动 Xvfb 虚拟显示器
export DISPLAY=:99
Xvfb :99 -screen 0 1280x800x24 &
XVFB_PID=$!

# 等待 Xvfb 启动
sleep 2

# 清理函数（包括 Xvfb）
cleanup_with_xvfb() {
    # 保留调试文件到固定目录
    if [ -d "$TEMP_DIR" ]; then
        cp -r "$TEMP_DIR" /tmp/xhs_debug_latest 2>/dev/null || true
        rm -rf "$TEMP_DIR"
    fi
    if [ -n "$XVFB_PID" ]; then
        kill $XVFB_PID 2>/dev/null || true
    fi
}
trap cleanup_with_xvfb EXIT

log_info "Xvfb 已启动 (PID: $XVFB_PID)"

# 创建 Node.js 发布脚本
cat > "$TEMP_DIR/post.js" << 'EOFJS'
const { chromium } = require('/root/.openclaw/skills/clawra-xiaohongshu/node_modules/playwright');
const fs = require('fs');
const path = require('path');

const COOKIES_FILE = process.argv[2];
const IMAGES = [process.argv[3], process.argv[4], process.argv[5]].filter(Boolean);
const TITLE = process.argv[6];
const CAPTION = process.argv[7];
const TEMP_DIR = process.argv[8];

(async () => {
    console.log('启动浏览器...');
    
    const browser = await chromium.launch({
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const context = await browser.newContext({
        viewport: { width: 1280, height: 800 }
    });
    
    // 加载 cookies
    let cookies;
    try {
        const cookiesRaw = fs.readFileSync(COOKIES_FILE, 'utf8');
        cookies = JSON.parse(cookiesRaw);
    } catch (e) {
        console.log('❌ 读取 cookies 失败:', e.message);
        console.log('Cookies 文件路径:', COOKIES_FILE);
        process.exit(1);
    }
    await context.addCookies(cookies);
    
    const page = await context.newPage();
    
    console.log('访问创作者平台...');
    await page.goto('https://creator.xiaohongshu.com/publish/publish', { 
        waitUntil: 'networkidle',
        timeout: 60000 
    });
    
    await page.waitForTimeout(5000);
    
    // 点击"上传图文" tab
    console.log('切换到上传图文模式...');
    try {
        // 使用 JavaScript 强制点击
        await page.evaluate(() => {
            const tabs = Array.from(document.querySelectorAll('span.title'));
            const imageTab = tabs.find(t => t.textContent.includes('上传图文') && !t.textContent.includes('视频'));
            if (imageTab) {
                imageTab.click();
                return true;
            }
            return false;
        });
        console.log('已切换到图文模式');
        await page.waitForTimeout(5000);
    } catch (e) {
        console.log('⚠️ 切换 tab 失败:', e.message);
    }
    
    // 检查是否已登录
    const currentUrl = page.url();
    if (currentUrl.includes('/login')) {
        console.log('❌ 未登录，cookies 可能已过期');
        await browser.close();
        process.exit(1);
    }
    
    console.log('已登录，开始发布...');
    
    // 上传图片
    console.log('上传图片...');
    
    // 等待页面稳定
    await page.waitForTimeout(5000);
    
    // 使用 JavaScript 查找并上传
    const uploadResult = await page.evaluate(async (imagePaths) => {
        // 查找上传按钮（原生 JS 选择器）
        const uploadBtn = document.querySelector('.upload-btn') ||
                          Array.from(document.querySelectorAll('button')).find(b => 
                              b.textContent.includes('上传')
                          ) ||
                          Array.from(document.querySelectorAll('div')).find(d => 
                              d.className.includes('upload') && d.textContent.includes('上传')
                          );
        
        if (!uploadBtn) {
            return { success: false, error: '未找到上传按钮' };
        }
        
        // 触发点击
        uploadBtn.click();
        
        // 等待文件输入出现
        await new Promise(r => setTimeout(r, 2000));
        
        // 查找文件输入
        const fileInput = document.querySelector('input[type="file"]');
        if (!fileInput) {
            return { success: false, error: '未找到文件输入框' };
        }
        
        return { success: true, found: 'upload-btn' };
    }, IMAGES);
    
    console.log('上传组件查找结果:', uploadResult);
    
    // 使用 Playwright 的文件上传
    const fileInput = await page.$('input[type="file"]');
    if (fileInput) {
        await fileInput.setInputFiles(IMAGES);
        console.log(`✅ 已选择 ${IMAGES.length} 张图片`);
        
        // 等待上传完成
        console.log('等待上传完成...');
        await page.waitForTimeout(15000);
        
        // 截图确认
        await page.screenshot({ path: path.join(TEMP_DIR, 'after-upload-confirm.png'), fullPage: true });
    } else {
        console.log('❌ 未找到文件上传框');
        await page.screenshot({ path: path.join(TEMP_DIR, 'upload-error.png'), fullPage: true });
        await browser.close();
        process.exit(1);
    }
    
    // 截图保存当前状态
    await page.screenshot({ path: path.join(TEMP_DIR, 'after-upload.png'), fullPage: true });
    console.log('上传后截图已保存');
    
    // 获取页面 HTML 用于调试
    const html = await page.content();
    fs.writeFileSync(path.join(TEMP_DIR, 'after-upload.html'), html);
    console.log('页面 HTML 已保存');
    
    // 填写标题和正文
    console.log('填写标题和正文...');
    
    // 使用 Playwright 的 locator API
    try {
        // 查找标题输入框
        const titleLocator = page.locator('input[placeholder*="标题"], input[placeholder*="赞"]').first();
        const titleCount = await titleLocator.count();
        
        if (titleCount > 0) {
            await titleLocator.fill(TITLE);
            console.log('✅ 标题已填写');
        } else {
            console.log('⚠️ 未找到标题输入框');
        }
    } catch (e) {
        console.log('⚠️ 标题填写失败:', e.message);
    }
    
    await page.waitForTimeout(2000);
    
    // 查找正文输入框
    try {
        const contentLocator = page.locator('textarea[placeholder*="正文"], textarea[placeholder*="描述"], textarea[placeholder*="真诚"]').first();
        const contentCount = await contentLocator.count();
        
        if (contentCount > 0) {
            await contentLocator.fill(CAPTION);
            console.log('✅ 正文已填写');
        } else {
            console.log('⚠️ 未找到正文输入框');
        }
    } catch (e) {
        console.log('⚠️ 正文填写失败:', e.message);
    }
    
    console.log('填写结果:', fillResult);
    
    await page.waitForTimeout(3000);
    
    await page.waitForTimeout(3000);
    
    // 截图保存填写后的状态
    await page.screenshot({ path: path.join(TEMP_DIR, 'after-fill.png'), fullPage: true });
    console.log('填写后截图已保存');
    
    // 点击发布
    console.log('点击发布按钮...');
    
    // 使用 JavaScript 查找发布按钮（可能是 span 或 div）
    const publishClicked = await page.evaluate(() => {
        // 查找包含"发布笔记"文本的元素
        const allElements = document.querySelectorAll('*');
        const publishBtn = Array.from(allElements).find(el => 
            el.textContent?.includes('发布笔记') && 
            (el.tagName === 'BUTTON' || el.tagName === 'SPAN' || el.tagName === 'DIV') &&
            el.offsetParent !== null // 元素可见
        );
        
        if (publishBtn) {
            publishBtn.click();
            return true;
        }
        return false;
    });
    
    if (publishClicked) {
        console.log('✅ 已点击发布按钮');
        
        // 等待发布完成
        console.log('等待发布完成...');
        await page.waitForTimeout(10000);
        
        // 检查是否发布成功
        const newUrl = page.url();
        if (newUrl.includes('/explore/')) {
            console.log('✅ 发布成功！');
            console.log('笔记 URL:', newUrl);
            
            fs.writeFileSync(
                path.join(TEMP_DIR, 'result.json'),
                JSON.stringify({ success: true, url: newUrl })
            );
        } else {
            console.log('⚠️ 发布状态未知，请检查小红书 APP');
            await page.screenshot({ path: path.join(TEMP_DIR, 'after-publish.png'), fullPage: true });
        }
    } else {
        console.log('❌ 未找到发布按钮');
        await page.screenshot({ path: path.join(TEMP_DIR, 'publish-btn-not-found.png'), fullPage: true });
    }
    
    await browser.close();
    console.log('完成！');
})();
EOFJS

# 运行发布脚本
node "$TEMP_DIR/post.js" "$COOKIES_FILE" "$IMAGE1" "$IMAGE2" "${IMAGE3:-}" "$TITLE" "$CAPTION" "$TEMP_DIR"

# 检查结果
if [ -f "$TEMP_DIR/result.json" ]; then
    NOTE_URL=$(jq -r '.url // empty' "$TEMP_DIR/result.json")
    if [ -n "$NOTE_URL" ]; then
        log_info "✅ 笔记已发布：$NOTE_URL"
    else
        log_warn "发布状态未知，请检查小红书 APP"
    fi
else
    log_warn "未找到发布结果文件"
fi

log_info "发布流程完成！"
