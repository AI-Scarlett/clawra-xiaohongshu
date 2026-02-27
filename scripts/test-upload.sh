#!/bin/bash
# 测试小红书上传页面结构

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COOKIES_FILE="$SCRIPT_DIR/../storage/cookies.json"
TEMP_DIR="/tmp/xhs_test_$$"

mkdir -p "$TEMP_DIR"

# 启动 Xvfb
export DISPLAY=:99
Xvfb :99 -screen 0 1280x800x24 &
XVFB_PID=$!
sleep 2

cleanup() {
    rm -rf "$TEMP_DIR"
    kill $XVFB_PID 2>/dev/null || true
}
trap cleanup EXIT

# 创建测试脚本
cat > "$TEMP_DIR/test.js" << 'EOFJS'
const { chromium } = require('/root/.openclaw/skills/clawra-xiaohongshu/node_modules/playwright');
const fs = require('fs');
const path = require('path');

const COOKIES_FILE = '/root/.openclaw/skills/clawra-xiaohongshu/storage/cookies.json';
const OUTPUT_DIR = process.argv[1];

(async () => {
    console.log('启动浏览器...');
    
    const browser = await chromium.launch({
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const context = await browser.newContext({
        viewport: { width: 1280, height: 800 }
    });
    
    const cookies = JSON.parse(fs.readFileSync(COOKIES_FILE, 'utf8'));
    await context.addCookies(cookies);
    
    const page = await context.newPage();
    
    console.log('访问发布页面...');
    await page.goto('https://creator.xiaohongshu.com/publish/publish', { 
        waitUntil: 'networkidle',
        timeout: 60000 
    });
    
    await page.waitForTimeout(5000);
    
    // 截图
    await page.screenshot({ path: path.join(OUTPUT_DIR, 'full-page.png'), fullPage: true });
    console.log('✅ 全屏截图已保存:', path.join(OUTPUT_DIR, 'full-page.png'));
    
    // 获取页面 HTML
    const html = await page.content();
    fs.writeFileSync(path.join(OUTPUT_DIR, 'page.html'), html);
    console.log('✅ 页面 HTML 已保存:', path.join(OUTPUT_DIR, 'page.html'));
    
    // 查找所有 input 元素
    const inputs = await page.$$eval('input', els => 
        els.map(e => ({ type: e.type, name: e.name, placeholder: e.placeholder, className: e.className }))
    );
    console.log('\n📋 找到的 input 元素:');
    console.log(JSON.stringify(inputs, null, 2));
    
    // 查找所有 button 元素
    const buttons = await page.$$eval('button', els => 
        els.map(e => ({ text: e.innerText, className: e.className, type: e.type }))
    );
    console.log('\n📋 找到的 button 元素:');
    console.log(JSON.stringify(buttons.slice(0, 20), null, 2));
    
    // 查找上传相关元素
    const uploadElements = await page.$$eval('[class*="upload"], [class*="Upload"], [role="button"]', els => 
        els.map(e => ({ tag: e.tagName, class: e.className, text: e.innerText?.slice(0, 50) }))
    );
    console.log('\n📋 上传相关元素:');
    console.log(JSON.stringify(uploadElements.slice(0, 10), null, 2));
    
    await browser.close();
    console.log('\n✅ 完成！');
})();
EOFJS

mkdir -p "$TEMP_DIR/output"
node "$TEMP_DIR/test.js" "$TEMP_DIR/output"

echo ""
echo "================================"
echo "测试完成！文件保存在：$TEMP_DIR"
echo "================================"
