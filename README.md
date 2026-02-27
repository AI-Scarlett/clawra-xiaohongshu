# Clawra 小红书自动发布技能 📕

> 小红书自动发布技能，支持扫码登录、每日穿搭自动生成和发布

## ✨ 功能特性

- 🔐 **扫码登录** - 支持小红书 APP 扫码登录，持久化 cookies
- 🤖 **自动生成** - 使用 AI 自动生成每日穿搭内容（图片 + 文案）
- ⏰ **定时发布** - 支持定时任务，默认每天早上 7 点自动发布
- 📸 **多图支持** - 支持三张图片上传（平铺图 + 两张上身照）
- 💬 **智能文案** - 自动生成符合小红书风格的穿搭文案
- 🔔 **失败通知** - 发布失败时通过 QQ 发送通知

## 📦 安装

### 前置要求

- Node.js >= 18.0.0
- OpenClaw >= 2026.2.0
- 阿里云百炼 API Key（用于生成图片）

### 安装步骤

```bash
# 克隆仓库
git clone https://github.com/SumeLabs/clawra-xiaohongshu.git
cd clawra-xiaohongshu

# 安装依赖
npm install

# 安装 Playwright 浏览器
npx playwright install chromium
```

## 🚀 快速开始

### 1. 配置环境变量

创建 `.env` 文件或设置环境变量：

```bash
# 阿里云百炼 API Key（生成图片）
DASHSCOPE_API_KEY=sk-xxx

# OpenClaw 网关 Token（发送通知）
OPENCLAW_GATEWAY_TOKEN=xxx

# QQ 用户 ID（发送通知）
QQBOT_USER_ID=7941E72A6252ADA08CC281AC26D9920B
```

### 2. 扫码登录

首次使用需要扫码登录小红书：

```bash
npm run login
# 或
bash scripts/xiaohongshu-login-fixed.sh
```

扫描生成的二维码后，cookies 会自动保存到 `storage/cookies.json`

### 3. 手动发布测试

```bash
npm run post
# 或
bash scripts/xiaohongshu-post-real.sh
```

### 4. 设置定时任务（可选）

设置每天早上 7 点自动发布：

```bash
# 添加到 crontab
echo "0 7 * * * cd /path/to/clawra-xiaohongshu && bash scripts/daily-outfit.sh" | crontab -
```

## 📁 目录结构

```
clawra-xiaohongshu/
├── README.md              # 使用说明
├── SKILL.md               # OpenClaw 技能定义
├── package.json           # 项目配置
├── scripts/
│   ├── xiaohongshu-login-fixed.sh  # 扫码登录脚本
│   ├── xiaohongshu-post-real.sh    # 发布笔记脚本
│   ├── daily-outfit.sh             # 每日穿搭生成
│   └── test-upload.sh              # 测试上传
├── storage/
│   └── cookies.json       # 登录状态（扫码后生成）
└── templates/
    └── outfit-caption.txt # 穿搭文案模板
```

## 🎨 发布内容

### 三张图片格式

1. **图一**：衣服、鞋袜平铺图
2. **图二**：上身照（正面/侧面）
3. **图三**：上身照（背面/不同姿势）

### 文案格式示例

```
📅 每日穿搭 | Day 001

今日 OOTD～

👗 上衣：白色蕾丝衬衫
👖 下装：高腰牛仔裤
👠 鞋袜：小白鞋

#每日穿搭 #OOTD #穿搭分享 #今日穿搭 #时尚
```

## ⚙️ 高级配置

### 自定义发布时间

编辑 `daily-outfit.sh` 中的发布时间：

```bash
PUBLISH_HOUR="9"  # 改为上午 9 点
```

### 自定义发布频率

建议每天发布不超过 3 条，避免被限流：

```bash
MAX_DAILY_POSTS="3"
```

### 使用代理（如需要）

如果服务器 IP 被限制，可以配置代理：

```bash
export HTTP_PROXY="http://proxy.example.com:8080"
export HTTPS_PROXY="http://proxy.example.com:8080"
```

## 🔧 故障排除

### 二维码无法显示

- 检查服务器网络连接
- 尝试使用国内 IP 或代理
- 查看 `storage/cookies.json/` 目录下的截图文件

### 发布失败

- 检查 cookies 是否过期（重新扫码登录）
- 检查图片格式是否正确（JPG/PNG）
- 查看脚本输出日志

### Cookies 失效

删除旧的 cookies 重新登录：

```bash
rm storage/cookies.json
npm run login
```

## 📝 注意事项

1. **防限流**：建议每天发布不超过 3 条
2. **IP 限制**：数据中心 IP 可能被小红书限制，建议使用住宅 IP
3. **内容质量**：确保发布的穿搭内容真实、高质量
4. **账号安全**：不要频繁发布相似内容，避免被判定为营销号

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

## 🔗 相关链接

- [OpenClaw 文档](https://docs.openclaw.ai)
- [阿里云百炼](https://help.aliyun.com/product/42154.html)
- [Playwright 文档](https://playwright.dev)

---

**Made with ❤️ by Scarlett for Boss**
