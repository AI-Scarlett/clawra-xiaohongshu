---
name: clawra-xiaohongshu
description: 小红书自动发布技能，支持扫码登录、每日穿搭自动生成和发布
allowed-tools: Bash(npm:*) Bash(npx:*) Bash(openclaw:*) Bash(curl:*) Read Write Browser
---

# Clawra 小红书自动发布技能

## 功能

- 扫码登录小红书（持久化 cookies）
- 自动生成每日穿搭内容（图片 + 文案）
- 定时发布到小红书（默认每天早上 7 点）
- 支持三张图片：平铺图 + 两张上身照

## 目录结构

```
clawra-xiaohongshu/
├── SKILL.md
├── scripts/
│   ├── xiaohongshu-login.sh    # 扫码登录
│   ├── xiaohongshu-post.sh     # 发布笔记
│   └── daily-outfit.sh         # 每日穿搭生成
├── storage/
│   └── cookies.json            # 登录状态
└── templates/
    └── outfit-caption.txt      # 穿搭文案模板
```

## 快速开始

### 1. 首次登录（扫码）
```bash
bash ~/.openclaw/skills/clawra-xiaohongshu/scripts/xiaohongshu-login.sh
```
会生成二维码，用小红书 APP 扫码登录。

### 2. 手动发布一次
```bash
bash ~/.openclaw/skills/clawra-xiaohongshu/scripts/daily-outfit.sh
```

### 3. 设置定时任务（每天早上 7 点）
```bash
# 添加到 crontab
echo "0 7 * * * bash /root/.openclaw/skills/clawra-xiaohongshu/scripts/daily-outfit.sh" | crontab -
```

## 环境变量

```bash
DASHSCOPE_API_KEY=sk-xxx          # 阿里云百炼 API Key（生成图片）
OPENCLAW_GATEWAY_TOKEN=xxx         # OpenClaw 网关 Token（发送通知）
QQBOT_USER_ID=7941E72A6252ADA08CC281AC26D9920B  # QQ 用户 ID（发送通知）
```

## 发布内容

### 三张图片
1. **图一**：衣服、鞋袜平铺图
2. **图二**：上身照（正面/侧面）
3. **图三**：上身照（背面/不同姿势）

### 文案格式
```
📅 每日穿搭 | Day XXX

今日 OOTD～

👗 上衣：[描述]
👖 下装：[描述]
👠 鞋袜：[描述]

#每日穿搭 #OOTD #穿搭分享 #今日穿搭 #时尚
```

## 注意事项

- 首次使用需要扫码登录
- Cookies 保存在 storage/cookies.json
- 发布失败会发送 QQ 通知
- 建议每天发布不超过 3 条（防限流）
