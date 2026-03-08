#!/bin/bash
# 灵犀 - 小红书发布接口
# 供灵犀调用的统一发布接口

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STORAGE_DIR="$SCRIPT_DIR/../storage"
COOKIES_FILE="$STORAGE_DIR/cookies.json"
STATE_FILE="$STORAGE_DIR/login-state.json"

# 参数解析
TITLE=""
CONTENT=""
IMAGE_PATH=""
ACTION="post"

while [[ $# -gt 0 ]]; do
    case $1 in
        --title)
            TITLE="$2"
            shift 2
            ;;
        --content)
            CONTENT="$2"
            shift 2
            ;;
        --image)
            IMAGE_PATH="$2"
            shift 2
            ;;
        --check-login)
            ACTION="check"
            shift
            ;;
        --login)
            ACTION="login"
            shift
            ;;
        *)
            echo "未知参数：$1"
            exit 1
            ;;
    esac
done

# 检查登录状态
check_login_status() {
    if [ ! -f "$COOKIES_FILE" ]; then
        echo "NOT_LOGGED"
        return
    fi
    
    if [ ! -f "$STATE_FILE" ]; then
        echo "UNKNOWN"
        return
    fi
    
    LOGIN_TIME=$(cat "$STATE_FILE" | grep -o '"login_time":[0-9]*' | grep -o '[0-9]*')
    CURRENT_TIME=$(date +%s)
    EXPIRE_TIME=$((LOGIN_TIME + 2592000))  # 30 天
    
    if [ "$CURRENT_TIME" -ge "$EXPIRE_TIME" ]; then
        echo "EXPIRED"
        return
    fi
    
    DAYS_LEFT=$(( (EXPIRE_TIME - CURRENT_TIME) / 86400 ))
    echo "OK:$DAYS_LEFT"
}

# 执行登录
do_login() {
    echo "📱 开始登录流程..."
    bash "$SCRIPT_DIR/xiaohongshu-login.sh"
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo "✅ 登录成功"
        exit 0
    else
        echo "❌ 登录失败"
        exit 1
    fi
}

# 执行发布
do_post() {
    # 检查必填参数
    if [ -z "$TITLE" ] || [ -z "$CONTENT" ]; then
        echo "❌ 错误：标题和内容不能为空"
        echo ""
        echo "用法:"
        echo "  $0 --title \"标题\" --content \"内容\" [--image \"图片路径\"]"
        exit 1
    fi
    
    # 检查登录状态
    STATUS=$(check_login_status)
    
    case $STATUS in
        NOT_LOGGED)
            echo "❌ 未登录"
            echo "💡 请先运行：$0 --login"
            exit 1
            ;;
        EXPIRED)
            echo "❌ Cookie 已过期"
            echo "💡 请重新登录：$0 --login"
            exit 1
            ;;
        OK:*)
            DAYS_LEFT=${STATUS#OK:}
            echo "✅ Cookie 有效（剩余 ${DAYS_LEFT} 天）"
            ;;
        *)
            echo "⚠️  未知状态：$STATUS"
            ;;
    esac
    
    echo ""
    echo "=========================================="
    echo "📕 小红书发布"
    echo "=========================================="
    echo "标题：$TITLE"
    echo "内容长度：${#CONTENT} 字"
    echo "图片：${IMAGE_PATH:-无}"
    echo "=========================================="
    echo ""
    
    # 调用发布脚本
    if [ -n "$IMAGE_PATH" ]; then
        bash "$SCRIPT_DIR/xiaohongshu-post.sh" "$TITLE" "$CONTENT" "$IMAGE_PATH"
    else
        bash "$SCRIPT_DIR/xiaohongshu-post.sh" "$TITLE" "$CONTENT"
    fi
    
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo ""
        echo "✅ 发布成功！"
        exit 0
    else
        echo ""
        echo "❌ 发布失败"
        exit 1
    fi
}

# 主流程
case $ACTION in
    check)
        STATUS=$(check_login_status)
        case $STATUS in
            OK:*)
                DAYS_LEFT=${STATUS#OK:}
                echo "✅ 已登录（剩余 ${DAYS_LEFT} 天）"
                exit 0
                ;;
            NOT_LOGGED)
                echo "❌ 未登录"
                exit 1
                ;;
            EXPIRED)
                echo "❌ Cookie 已过期"
                exit 1
                ;;
            *)
                echo "⚠️  未知状态：$STATUS"
                exit 1
                ;;
        esac
        ;;
    
    login)
        do_login
        ;;
    
    post)
        do_post
        ;;
    
    *)
        echo "用法：$0 [选项]"
        echo ""
        echo "选项:"
        echo "  --login              登录"
        echo "  --check-login        检查登录状态"
        echo "  --title \"标题\"       笔记标题"
        echo "  --content \"内容\"     笔记正文"
        echo "  --image \"路径\"       封面图片路径"
        echo ""
        echo "示例:"
        echo "  # 登录"
        echo "  $0 --login"
        echo ""
        echo "  # 检查登录状态"
        echo "  $0 --check-login"
        echo ""
        echo "  # 发布笔记"
        echo "  $0 --title \"我的标题\" --content \"这是内容...\" --image \"/path/to/image.jpg\""
        exit 1
        ;;
esac
