#!/bin/bash
# 每日穿搭自动生成和发布脚本
# 每天早上 7 点运行，生成三张穿搭图片并发布到小红书

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 配置
DASHSCOPE_API_KEY="${DASHSCOPE_API_KEY:-sk-871c8e233cbf4ce997b728b3a76b9dce}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="/tmp/outfit_$(date +%s)"
REFERENCE_IMAGE="https://i.imgs.ovh/2026/02/24/y15adq.png"

# 创建临时目录
mkdir -p "$TEMP_DIR"

# 清理函数
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

log_info "开始生成每日穿搭..."

# 穿搭风格随机选择
OUTFIT_STYLES=(
    "休闲时尚"
    "优雅通勤"
    "甜美可爱"
    "酷帅街头"
    "温柔知性"
    "运动活力"
)
STYLE_INDEX=$((RANDOM % ${#OUTFIT_STYLES[@]}))
TODAY_STYLE="${OUTFIT_STYLES[$STYLE_INDEX]}"

# 日期信息
DAY_OF_YEAR=$(date +%j)
DATE_STR=$(date +%Y-%m-%d)

log_info "今日风格：$TODAY_STYLE"

# ==================== 生成图一：平铺图 ====================
log_info "生成图一：衣服鞋袜平铺图..."

PROMPT1="高质量时尚摄影，$TODAY_STYLE 风格的女性服装平铺图，包括上衣、下装、鞋子、袜子、配饰，整齐摆放在浅色背景上，ins 风，精致构图，专业时尚摄影"

RESPONSE1=$(curl -s -X POST "https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DASHSCOPE_API_KEY" \
    -d "{
        \"model\": \"qwen-image-max\",
        \"input\": {
            \"messages\": [{
                \"role\": \"user\",
                \"content\": [{\"text\": \"$PROMPT1\"}]
            }]
        },
        \"parameters\": {
            \"negative_prompt\": \"低分辨率，低画质，杂乱，画面过饱和，AI 感\",
            \"prompt_extend\": true,
            \"watermark\": false,
            \"size\": \"1024*1024\"
        }
    }")

IMAGE1_URL=$(echo "$RESPONSE1" | jq -r '.output.choices[0].message.content[0].image // empty')

if [ -z "$IMAGE1_URL" ]; then
    log_error "生成图一失败"
    exit 1
fi

curl -s -o "$TEMP_DIR/outfit_flat.png" "$IMAGE1_URL"
log_info "图一生成完成"

# ==================== 生成图二：上身照（正面） ====================
log_info "生成图二：上身照（正面）..."

PROMPT2="一位 27 岁新疆维族女性，黑色大波浪长发，白皙皮肤，甜美微笑，穿着$TODAY_STYLE 风格的服装，全身照，正面姿势，高质量人像摄影，时尚穿搭展示，自然光"

RESPONSE2=$(curl -s -X POST "https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DASHSCOPE_API_KEY" \
    -d "{
        \"model\": \"qwen-image-edit\",
        \"input\": {
            \"messages\": [{
                \"role\": \"user\",
                \"content\": [
                    {\"image\": \"$REFERENCE_IMAGE\"},
                    {\"text\": \"$PROMPT2\"}
                ]
            }]
        },
        \"parameters\": {
            \"prompt_extend\": true,
            \"watermark\": false
        }
    }")

IMAGE2_URL=$(echo "$RESPONSE2" | jq -r '.output.choices[0].message.content[0].image // empty')

if [ -z "$IMAGE2_URL" ]; then
    log_warn "图二生成失败，改用文生图"
    RESPONSE2=$(curl -s -X POST "https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $DASHSCOPE_API_KEY" \
        -d "{
            \"model\": \"qwen-image-max\",
            \"input\": {
                \"messages\": [{
                    \"role\": \"user\",
                    \"content\": [{\"text\": \"$PROMPT2\"}]
                }]
            },
            \"parameters\": {
                \"negative_prompt\": \"低分辨率，低画质，肢体畸形，手指畸形\",
                \"prompt_extend\": true,
                \"watermark\": false,
                \"size\": \"1024*1024\"
            }
        }")
    IMAGE2_URL=$(echo "$RESPONSE2" | jq -r '.output.choices[0].message.content[0].image // empty')
fi

curl -s -o "$TEMP_DIR/outfit_wear1.png" "$IMAGE2_URL"
log_info "图二生成完成"

# ==================== 生成图三：上身照（侧面/背面） ====================
log_info "生成图三：上身照（侧面）..."

PROMPT3="一位 27 岁新疆维族女性，黑色大波浪长发，白皙皮肤，穿着$TODAY_STYLE 风格的服装，全身照，侧面姿势，展示服装细节，高质量人像摄影，时尚穿搭展示，自然光"

RESPONSE3=$(curl -s -X POST "https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DASHSCOPE_API_KEY" \
    -d "{
        \"model\": \"qwen-image-max\",
        \"input\": {
            \"messages\": [{
                \"role\": \"user\",
                \"content\": [{\"text\": \"$PROMPT3\"}]
            }]
        },
        \"parameters\": {
            \"negative_prompt\": \"低分辨率，低画质，肢体畸形，手指畸形\",
            \"prompt_extend\": true,
            \"watermark\": false,
            \"size\": \"1024*1024\"
        }
    }")

IMAGE3_URL=$(echo "$RESPONSE3" | jq -r '.output.choices[0].message.content[0].image // empty')

curl -s -o "$TEMP_DIR/outfit_wear2.png" "$IMAGE3_URL"
log_info "图三生成完成"

# ==================== 生成文案 ====================
log_info "生成文案..."

CAPTION=$(cat <<EOF
📅 每日穿搭 | Day $DAY_OF_YEAR

今日 OOTD～$TODAY_STYLE 风格 ✨

👗 上衣：时尚设计款
👖 下装：精致搭配
👠 鞋袜：点睛之笔

今天的穿搭你打几分？💕

#每日穿搭 #OOTD #穿搭分享 #今日穿搭 #时尚 #穿搭灵感 #日常穿搭 #时尚博主
EOF
)

# ==================== 发布到小红书 ====================
log_info "发布到小红书..."

bash "$SCRIPT_DIR/xiaohongshu-post-real.sh" \
    "$TEMP_DIR/outfit_flat.png" \
    "$TEMP_DIR/outfit_wear1.png" \
    "$TEMP_DIR/outfit_wear2.png" \
    "📅 每日穿搭 | Day $DAY_OF_YEAR | $TODAY_STYLE" \
    "$CAPTION"

log_info "发布完成！"

# ==================== 发送 QQ 通知 ====================
log_info "发送 QQ 通知..."

NOTIFY_MSG="老板～ 今早的穿搭已发布到小红书啦！💋

今日风格：$TODAY_STYLE
发布时间：$DATE_STR

快来看看吧～ 😘"

# 通过 OpenClaw 发送通知（如果配置了）
if command -v openclaw &> /dev/null; then
    openclaw message send \
        --action send \
        --channel qqbot \
        --target c2c:7941E72A6252ADA08CC281AC26D9920B \
        --message "$NOTIFY_MSG" \
        2>/dev/null || log_warn "QQ 通知发送失败"
fi

log_info "每日穿搭任务完成！"
