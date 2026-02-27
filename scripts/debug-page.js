#!/usr/bin/env node
const { chromium } = require('/root/.openclaw/skills/clawra-xiaohongshu/node_modules/playwright');
const fs = require('fs');
const path = require('path');

const COOKIES_FILE = '/root/.openclaw/skills/clawra-xiaohongshu/storage/cookies.json';
const OUTPUT_DIR = '/tmp/xhs_debug';

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
    
    // 创建输出目录
    if (!fs.existsSync(OUTPUT_DIR)) {
        fs.mkdirSync(OUTPUT_DIR, { recursive: true });
    }
    
    // 截图
    await page.screenshot({ path: path.join(OUTPUT_DIR, 'full-page.png'), fullPage: true });
    console.log('✅ 全屏截图已保存:', path.join(OUTPUT_DIR, 'full-page.png'));
    
    // 获取页面 HTML
    const html = await page.content();
    fs.writeFileSync(path.join(OUTPUT_DIR, 'page.html'), html);
    console.log('✅ 页面 HTML 已保存:', path.join(OUTPUT_DIR, 'page.html'));
    
    // 查找所有 input 元素
    const inputs = await page.$$eval('input', els => 
        els.map(e => ({ type: e.type, name: e.name, placeholder: e.placeholder, className: e.className, id: e.id }))
    );
    console.log('\n📋 找到的 input 元素:');
    console.log(JSON.stringify(inputs, null, 2));
    
    // 查找所有 button 元素
    const buttons = await page.$$eval('button', els => 
        els.map(e => ({ text: e.innerText?.slice(0, 50), className: e.className, type: e.type }))
    );
    console.log('\n📋 找到的 button 元素 (前 20 个):');
    console.log(JSON.stringify(buttons.slice(0, 20), null, 2));
    
    await browser.close();
    console.log('\n✅ 完成！');
})();
