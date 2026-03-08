---
name: clawra-xiaohongshu
description: 小红书自动发布技能，支持扫码登录、每日穿搭自动生成和发布
allowed-tools: Bash(npm:*) Bash(npx:*) Bash(openclaw:*) Bash(curl:*) Read Write Browser
---

# Clawra 小红书自动发布技能 v2.0

> **v2.0 新增:** Cookie 持久化（30 天免登录）、灵犀集成接口、无头模式发布

## 功能

- ✅ **扫码登录**（持久化 cookies，30 天有效）
- ✅ **自动生成**每日穿搭内容（图片 + 文案）
- ✅ **定时发布**到小红书（默认每天早上 7 点）
- ✅ **灵犀集成**（可通过灵犀直接调用）
- ✅ **无头模式**（后台发布，不占用屏幕）
- ✅ 支持三张图片：平铺图 + 两张上身照

---

## 📁 目录结构

```
clawra-xiaohongshu/
├── SKILL.md
├── README_AUTO_LOGIN.md       # 自动登录文档
├── scripts/
│   ├── xiaohongshu-login.sh   # 扫码登录（持久化）
│   ├── xiaohongshu-post.sh    # 发布笔记（无头模式）
│   ├── lingxi-interface.sh    # 灵犀集成接口
│   ├── xiaohongshu_integration.py  # Python 集成模块
│   └── daily-outfit.sh        # 每日穿搭生成
├── storage/
│   ├── cookies.json           # Cookie 存储
│   └── login-state.json       # 登录状态
└── templates/
    └── outfit-caption.txt     # 穿搭文案模板
```

---

## 🚀 快速开始

### 方式 1: 命令行使用

#### 1. 首次登录（只需一次，30 天有效）

```bash
bash ~/.openclaw/skills/clawra-xiaohongshu/scripts/xiaohongshu-login.sh
```

**流程:**
1. 自动打开浏览器窗口
2. 显示登录二维码
3. 用手机小红书 APP 扫码
4. 确认登录
5. 自动保存 Cookie（30 天有效）

#### 2. 检查登录状态

```bash
bash ~/.openclaw/skills/clawra-xiaohongshu/scripts/lingxi-interface.sh --check-login
```

**输出示例:**
```
✅ 已登录（剩余 28 天）
```

#### 3. 发布笔记

```bash
# 基本用法
bash ~/.openclaw/skills/clawra-xiaohongshu/scripts/lingxi-interface.sh \
  --title "我的标题" \
  --content "这是内容..."

# 带图片
bash ~/.openclaw/skills/clawra-xiaohongshu/scripts/lingxi-interface.sh \
  --title "AI 工具推荐" \
  --content "今天分享 5 个 AI 神器... #AI #效率工具" \
  --image "/tmp/cover.jpg"
```

---

### 方式 2: Python 调用

```python
from xiaohongshu_integration import check_status, publish_note, do_login

# 检查登录状态
is_logged, days, msg = check_status()
print(msg)  # ✅ 已登录（剩余 28 天）

# 发布笔记
result = publish_note(
    title="AI 工具推荐",
    content="今天分享 5 个 AI 神器... #AI #效率工具",
    image="/tmp/cover.jpg"
)

if result.success:
    print("✅ 发布成功")
else:
    print(f"❌ 发布失败：{result.message}")
```

---

### 方式 3: 灵犀调用

```
你说："帮我发个小红书"
斯嘉丽：好的老板，正在发布...
→ 自动调用 xiaohongshu_integration.py
→ 使用已保存的 Cookie
→ 无需登录，直接发布
```

---

## 🎯 灵犀集成

### 在灵犀中使用

编辑灵犀技能或直接在对话中调用：

```python
# 导入集成模块
import sys
sys.path.insert(0, '/root/.openclaw/skills/clawra-xiaohongshu/scripts')
from xiaohongshu_integration import XiaohongshuPublisher

# 创建发布器
publisher = XiaohongshuPublisher()

# 检查登录
is_logged, days, msg = publisher.check_login_status()
if not is_logged:
    print(f"需要先登录：{msg}")
    publisher.login()

# 发布笔记
result = publisher.publish(
    title="标题",
    content="内容...",
    image_path="/path/to/image.jpg"
)

if result.success:
    print("✅ 发布成功")
else:
    print(f"❌ 发布失败：{result.message}")
```

---

## 📊 Cookie 管理

### 查看 Cookie 状态

```bash
cat storage/login-state.json
```

**输出示例:**
```json
{
  "login_time": 1772930000,
  "login_date": "2026-03-08T09:50:00.000Z",
  "cookie_count": 15,
  "expires_in_days": 30
}
```

### Cookie 有效期

- **理论有效期:** 30 天
- **实际有效期:** 取决于小红书官方策略
- **建议:** 每 2-3 周重新登录一次

### 刷新 Cookie

```bash
# 删除旧 Cookie 重新登录
rm storage/cookies.json storage/login-state.json
bash scripts/xiaohongshu-login.sh
```

---

## 📝 使用示例

### 示例 1: 发布图文笔记

```bash
bash scripts/lingxi-interface.sh \
  --title "美食探店｜这家店真的太好吃了" \
  --content "今天和朋友来了一家超棒的餐厅... #美食 #探店 #美食分享" \
  --image "/photos/food.jpg"
```

### 示例 2: 发布纯文字笔记

```bash
bash scripts/lingxi-interface.sh \
  --title "今日心情" \
  --content "阳光明媚，心情美美哒 ☀️ #日常 #心情"`
```

### 示例 3: 定时发布

```bash
# 编辑 crontab
crontab -e

# 添加定时任务（每天早上 7 点）
0 7 * * * bash /root/.openclaw/skills/clawra-xiaohongshu/scripts/daily-outfit.sh >> /var/log/xhs.log 2>&1
```

---

## ⚠️ 注意事项

### 1. 登录要求

- ✅ 首次使用必须扫码登录
- ✅ Cookie 保存 30 天
- ✅ 过期后需要重新登录

### 2. 发布限制

- **建议频率:** 每天 1-3 篇
- **安全间隔:** 至少 1 小时
- **避免:** 短时间内连续发布

### 3. 内容规范

- ❌ 禁止发布违规内容
- ❌ 避免敏感词汇
- ✅ 遵守小红书社区规范

### 4. 风控预防

- 固定服务器 IP
- 使用固定 User-Agent
- 避免频繁更换设备

---

## 🔧 故障排查

### 问题 1: Cookie 过期

```
❌ Cookie 已过期
💡 请重新登录：xiaohongshu-login.sh
```

**解决:** 重新登录即可

### 问题 2: 发布失败

```
❌ 发布失败：检测到登录页面
```

**原因:** Cookie 失效  
**解决:** 重新登录

### 问题 3: 找不到脚本

```
❌ 接口脚本不存在
```

**解决:** 检查路径是否正确

---

## 📚 相关文档

- [自动登录使用文档](README_AUTO_LOGIN.md)
- [灵犀模型路由文档](../../lingxi/docs/MODEL_ROUTING.md)
- [灵犀共享记忆库文档](../../lingxi/docs/SHARED_MEMORY.md)

---

## 📝 更新日志

### v2.0 (2026-03-08)
- ✅ Cookie 持久化（30 天有效）
- ✅ 灵犀集成接口
- ✅ Python 集成模块
- ✅ 无头模式发布
- ✅ 状态检查与过期提醒

### v1.0 (旧版本)
- ❌ 每次都需要登录
- ❌ 手动扫码
- ❌ 不保存 Cookie

---

_一次登录，30 天无忧发布_ 💋
