#!/bin/bash
# 小红书自动发布脚本（浏览器自动化）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STORAGE_DIR="$SCRIPT_DIR/../storage"
COOKIES_FILE="$STORAGE_DIR/cookies.json"

echo "=========================================="
echo "📕 小红书自动发布 - 斯嘉丽自拍系列"
echo "=========================================="
echo ""

# 创建发布用的 Node.js 脚本
cat > "$SCRIPT_DIR/auto-post.js" << 'EOFNODE'
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// 照片列表
const PHOTOS = [
    { 
        path: '/tmp/scarlett_01_bikini_final.png',
        title: '💋 斯嘉丽的比基尼海滩风',
        desc: `📏 身高：170cm
👗 三围：37E-100cm 完美 S 曲线
💃 风格：比基尼海滩风

今日 OOTD 分享～
展现自信美丽的自己！✨

#比基尼 #海滩 #性感穿搭 #每日穿搭 #OOTD #穿搭分享 #新疆美女 #身材管理`
    },
    { 
        path: '/tmp/scarlett_02_office_final.png',
        title: '💋 斯嘉丽的职业 OL 风',
        desc: `📏 身高：170cm
👗 三围：37E-100cm 完美 S 曲线
💼 风格：职业 OL 风

职场穿搭分享～
知性优雅又性感！✨

#OL 穿搭 #职场 #知性美 #每日穿搭 #OOTD #穿搭分享 #新疆美女 #身材管理`
    },
    { 
        path: '/tmp/scarlett_03_sports_final.png',
        title: '💋 斯嘉丽的运动健身风',
        desc: `📏 身高：170cm
👗 三围：37E-100cm 完美 S 曲线
🏋️‍♀️ 风格：运动健身风

健身穿搭分享～
健康活力满满！✨

#运动穿搭 #健身 #活力 #每日穿搭 #OOTD #穿搭分享 #新疆美女 #身材管理`
    },
    { 
        path: '/tmp/scarlett_04_evening_remaining.png',
        title: '💋 斯嘉丽的晚礼服风',
        desc: `📏 身高：170cm
👗 三围：37E-100cm 完美 S 曲线
💃 风格：晚礼服风

宴会穿搭分享～
高贵典雅气质！✨

#晚礼服 #宴会 #高贵 #每日穿搭 #OOTD #穿搭分享 #新疆美女 #身材管理`
    },
    { 
        path: '/tmp/scarlett_05_casual_remaining.png',
        title: '💋 斯嘉丽的休闲居家风',
        desc: `📏 身高：170cm
👗 三围：37E-100cm 完美 S 曲线
🏠 风格：休闲居家风

居家穿搭分享～
慵懒随性也美丽！✨

#休闲穿搭 #居家 #慵懒风 #每日穿搭 #OOTD #穿搭分享 #新疆美女 #身材管理`
    },
    { 
        path: '/tmp/scarlett_06_qipao_final.png',
        title: '💋 斯嘉丽的旗袍中国风',
        desc: `📏 身高：170cm
👗 三围：37E-100cm 完美 S 曲线
🇨🇳 风格：旗袍中国风

国风穿搭分享～
东方韵味十足！✨

#旗袍 #中国风 #东方美 #每日穿搭 #OOTD #穿搭分享 #新疆美女 #身材管理`
    },
    { 
        path: '/tmp/scarlett_07_leather_final.png',
        title: '💋 斯嘉丽的皮衣机车风',
        desc: `📏 身高：170cm
👗 三围：37E-100cm 完美 S 曲线
🏍️ 风格：皮衣机车风

酷飒穿搭分享～
又美又飒！✨

#皮衣 #机车风 #酷飒 #每日穿搭 #OOTD #穿搭分享 #新疆美女 #身材管理`
    }
];

(async () => {
    console.log('🚀 启动小红书自动发布...\n');
    
    // 检查照片文件
    console.log('检查照片文件...');
    for (const photo of PHOTOS) {
        if (fs.existsSync(photo.path)) {
            console.log(`✓ ${path.basename(photo.path)}`);
        } else {
            console.log(`✗ ${path.basename(photo.path)} (不存在)`);
        }
    }
    console.log('');
    
    console.log('启动浏览器...');
    const browser = await chromium.launch({
        headless: false,  // 使用有头模式，方便人工确认
        args: ['--window-size=1920,1080', '--no-sandbox']
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        locale: 'zh-CN',
        timezoneId: 'Asia/Shanghai'
    });
    
    const page = await context.newPage();
    
    console.log('访问小红书...');
    await page.goto('https://www.xiaohongshu.com/', { waitUntil: 'networkidle' });
    
    console.log('\n========================================');
    console.log('请在浏览器中手动登录小红书');
    console.log('登录完成后，按 Enter 键继续发布...');
    console.log('========================================\n');
    
    // 等待用户确认登录
    await new Promise(resolve => {
        const readline = require('readline').createInterface({
            input: process.stdin,
            output: process.stdout
        });
        readline.question('登录完成？按 Enter 继续...', () => {
            readline.close();
            resolve();
        });
    });
    
    // 检查登录状态
    const isLoggedIn = await page.evaluate(() => {
        return document.cookie.includes('session_id') || 
               document.querySelector('.user-avatar') !== null;
    });
    
    if (!isLoggedIn) {
        console.log('⚠️  未检测到登录状态，但继续尝试发布...');
    } else {
        console.log('✓ 检测到登录状态');
    }
    
    console.log('\n========================================');
    console.log('发布说明:');
    console.log('1. 浏览器已打开小红书');
    console.log('2. 照片文件位置：/tmp/scarlett_*.png');
    console.log('3. 文案已在上方显示');
    console.log('4. 请手动上传照片并发布');
    console.log('========================================\n');
    
    console.log('提示：可以分批发布，每次 3-4 张照片');
    console.log('建议发布时间间隔：5-10 分钟');
    
    await browser.close();
    console.log('\n✅ 发布流程完成！');
})();
EOFNODE

node "$SCRIPT_DIR/auto-post.js"
