#!/bin/bash
# 发布斯嘉丽自拍照片到小红书

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STORAGE_DIR="$SCRIPT_DIR/../storage"
COOKIES_FILE="$STORAGE_DIR/cookies.json"

echo "=========================================="
echo "📕 发布斯嘉丽自拍到小红书"
echo "=========================================="
echo ""

# 检查 cookies
if [ ! -f "$COOKIES_FILE" ]; then
    echo "❌ Cookies 文件不存在，请先扫码登录"
    echo "运行：bash scripts/xiaohongshu-login-fixed.sh"
    exit 1
fi

echo "✓ Cookies 文件存在"

# 准备发布的照片
PHOTOS=(
    "/tmp/scarlett_01_bikini_final.png"
    "/tmp/scarlett_02_office_final.png"
    "/tmp/scarlett_03_sports_final.png"
    "/tmp/scarlett_04_evening_remaining.png"
    "/tmp/scarlett_05_casual_remaining.png"
    "/tmp/scarlett_06_qipao_final.png"
    "/tmp/scarlett_07_leather_final.png"
)

# 检查照片是否存在
echo ""
echo "检查照片文件..."
for photo in "${PHOTOS[@]}"; do
    if [ -f "$photo" ]; then
        echo "✓ $photo"
    else
        echo "✗ $photo (不存在)"
    fi
done

echo ""
echo "=========================================="
echo "准备发布 7 张自拍照片"
echo "=========================================="
echo ""

# 创建发布用的 Node.js 脚本
cat > "$SCRIPT_DIR/post-selfies.js" << 'EOFNODE'
const fs = require('fs');
const path = require('path');

// 这里应该调用小红书发布 API
// 由于小红书没有官方 API，我们模拟发布流程

const PHOTOS = [
    { path: '/tmp/scarlett_01_bikini_final.png', title: '比基尼海滩风', tags: ['#比基尼', '#海滩', '#性感穿搭'] },
    { path: '/tmp/scarlett_02_office_final.png', title: '职业 OL 风', tags: ['#OL 穿搭', '#职场', '#知性美'] },
    { path: '/tmp/scarlett_03_sports_final.png', title: '运动健身风', tags: ['#运动穿搭', '#健身', '#活力'] },
    { path: '/tmp/scarlett_04_evening_remaining.png', title: '晚礼服风', tags: ['#晚礼服', '#宴会', '#高贵'] },
    { path: '/tmp/scarlett_05_casual_remaining.png', title: '休闲居家风', tags: ['#休闲穿搭', '#居家', '#慵懒风'] },
    { path: '/tmp/scarlett_06_qipao_final.png', title: '旗袍中国风', tags: ['#旗袍', '#中国风', '#东方美'] },
    { path: '/tmp/scarlett_07_leather_final.png', title: '皮衣机车风', tags: ['#皮衣', '#机车风', '#酷飒'] }
];

console.log('📸 准备发布以下照片：\n');

PHOTOS.forEach((photo, index) => {
    const caption = `
💋 斯嘉丽的${photo.title}

📏 身高：170cm
👗 三围：37E-100cm 完美 S 曲线
💃 风格：${photo.title}

今日 OOTD 分享～
展现自信美丽的自己！✨

${photo.tags.join(' ')}
#每日穿搭 #OOTD #穿搭分享 #新疆美女 #身材管理
`;

    console.log(`【${index + 1}/${PHOTOS.length}】${photo.title}`);
    console.log(`图片：${photo.path}`);
    console.log(`文案：${caption.trim()}`);
    console.log('---');
});

console.log('\n✅ 发布准备完成！');
console.log('注意：实际发布需要调用小红书 API 或使用浏览器自动化');
EOFNODE

node "$SCRIPT_DIR/post-selfies.js"

echo ""
echo "=========================================="
echo "由于小红书没有公开 API，需要使用浏览器自动化发布"
echo "=========================================="
echo ""
echo "建议手动发布步骤："
echo "1. 访问 https://www.xiaohongshu.com/"
echo "2. 点击发布按钮"
echo "3. 上传照片（每次选 3-4 张）"
echo "4. 复制上面的文案"
echo "5. 发布"
echo ""
echo "或者使用浏览器自动化脚本（需要配置）"
echo "=========================================="
