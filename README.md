# Clawra 小红书自动发布技能 📕

> 小红书自动发布技能，支持扫码登录、每日穿搭自动生成和发布

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Node](https://img.shields.io/badge/node-%3E%3D18.0.0-brightgreen.svg)

## ✨ 功能特性

- 🔐 **扫码登录** - 支持小红书 APP 扫码登录，持久化 cookies
- 🤖 **自动生成** - 使用 AI 自动生成每日穿搭内容（图片 + 文案）
- ⏰ **定时发布** - 支持定时任务，默认每天早上 7 点自动发布
- 📸 **多图支持** - 支持三张图片上传（平铺图 + 两张上身照）
- 💬 **智能文案** - 自动生成符合小红书风格的穿搭文案
- 🔔 **失败通知** - 发布失败时通过 QQ 发送通知

## 📦 快速安装

```bash
# 克隆仓库
git clone https://github.com/zhouxiaoming666/clawra-xiaohongshu.git
cd clawra-xiaohongshu

# 一键安装
bash install.sh

# 配置环境变量
cp .env.example .env
# 编辑 .env 填入 API keys

# 扫码登录
npm run login

# 发布测试
npm run post
```

## 📁 目录结构

```
clawra-xiaohongshu/
├── README.md              # 使用说明
├── SKILL.md               # OpenClaw 技能定义
├── package.json           # 项目配置
├── install.sh             # 快速安装脚本
├── scripts/
│   ├── xiaohongshu-login-fixed.sh  # 扫码登录
│   ├── xiaohongshu-post-real.sh    # 发布笔记
│   ├── daily-outfit.sh             # 每日穿搭
│   └── test-upload.sh              # 测试上传
├── storage/
│   └── cookies.json       # 登录状态
└── templates/
    └── outfit-caption.txt # 文案模板
```

## 🔗 相关链接

- **GitHub**: https://github.com/zhouxiaoming666/clawra-xiaohongshu
- [OpenClaw 文档](https://docs.openclaw.ai)
- [阿里云百炼](https://help.aliyun.com/product/42154.html)

---

**Made with ❤️ by Scarlett**
