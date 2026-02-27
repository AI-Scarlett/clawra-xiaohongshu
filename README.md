# Clawra 小红书自动发布技能 📕

> 小红书完全自动化发布技能，支持扫码登录、AI 生成内容、无头浏览器自动发布

![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Node](https://img.shields.io/badge/node-%3E%3D18.0.0-brightgreen.svg)

## ✨ 核心功能

### 🤖 完全自动化发布
- 🔐 **一次扫码，永久登录** - Cookies 持久化保存
- 📸 **AI 自动生成图片** - 使用阿里云百炼生成高质量穿搭照
- 💬 **AI 智能文案** - 自动生成符合小红书风格的文案
- 🚀 **无头浏览器发布** - 模拟真人操作，自动上传发布
- ⏰ **定时任务** - 支持每天自动发布
- 🔔 **失败通知** - 发布失败通过 QQ 通知

## 📦 快速开始

### 1. 安装

```bash
# 克隆仓库
git clone https://github.com/zhouxiaoming666/clawra-xiaohongshu.git
cd clawra-xiaohongshu

# 安装依赖
bash install.sh
# 或手动安装
npm install
npx playwright install chromium
```

### 2. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env 填入你的 API keys
```

**.env 示例：**
```bash
# 阿里云百炼 API Key（生成图片）
DASHSCOPE_API_KEY=sk-xxxxxxxxxxxxxxxx

# OpenClaw 网关 Token（发送通知）
OPENCLAW_GATEWAY_TOKEN=xxx

# QQ 用户 ID（发送通知）
QQBOT_USER_ID=7941E72A6252ADA08CC281AC26D9920B
```

### 3. 扫码登录（仅需一次）

```bash
npm run login
```

扫描生成的二维码后，cookies 会自动保存到 `storage/cookies.json`

### 4. 自动发布

```bash
# 完全自动化发布（推荐）
npm run post

# 手动辅助发布
npm run post:manual

# 每日穿搭生成
npm run daily
```

## 🔄 完全自动化流程

```
1. 检查登录状态 (cookies)
   ↓
2. 加载 AI 生成的图片和文案
   ↓
3. 无头浏览器登录小红书
   ↓
4. 自动上传图片（3 张/篇）
   ↓
5. 自动填写标题和文案
   ↓
6. 自动添加标签
   ↓
7. 点击发布
   ↓
8. 保存更新后的 cookies
   ↓
9. 等待 5 分钟（防限流）
   ↓
10. 发布下一篇
```

## 📁 目录结构

```
clawra-xiaohongshu/
├── README.md                    # 使用说明
├── package.json                 # 项目配置
├── install.sh                   # 快速安装脚本
├── scripts/
│   ├── xiaohongshu-login-fixed.sh    # 扫码登录（改进版）
│   ├── xiaohongshu-fully-auto.sh     # 完全自动化发布 ⭐
│   ├── xiaohongshu-auto-post.sh      # 手动辅助发布
│   ├── daily-outfit.sh               # 每日穿搭生成
│   └── test-upload.sh                # 测试上传
├── storage/
│   └── cookies.json                  # 登录状态（持久化）
└── templates/
    └── outfit-caption.txt            # 文案模板
```

## 🎨 发布内容示例

### 第一篇：夏日穿搭合集
- 图 1：比基尼海滩风
- 图 2：职业 OL 风
- 图 3：运动健身风

### 第二篇：百变穿搭
- 图 1：晚礼服风
- 图 2：休闲居家风
- 图 3：旗袍中国风

### 第三篇：皮衣机车风
- 单图：酷飒皮衣造型

## ⚙️ 高级配置

### 自定义发布频率

编辑 `xiaohongshu-fully-auto.sh`：

```javascript
// 发布间隔（毫秒）
await page.waitForTimeout(300000);  // 5 分钟
```

### 自定义发布数量

```javascript
const POSTS = [
    // 添加更多篇笔记...
];
```

### 使用代理（如需要）

```bash
export HTTP_PROXY="http://proxy.example.com:8080"
export HTTPS_PROXY="http://proxy.example.com:8080"
```

## 🔧 故障排除

### Cookies 失效

```bash
# 删除旧 cookies
rm storage/cookies.json

# 重新登录
npm run login
```

### 发布失败

检查：
1. Cookies 是否有效
2. 图片文件是否存在
3. 网络连接是否正常
4. 查看脚本输出日志

### 二维码无法显示

- 检查服务器网络连接
- 查看 `qrcode/login-qr.png`
- 尝试使用国内 IP 或代理

## ⚠️ 注意事项

1. **防限流**：每篇笔记间隔至少 5 分钟
2. **每日限制**：建议每天不超过 3-5 篇
3. **IP 问题**：数据中心 IP 可能被限制，建议使用住宅 IP
4. **内容质量**：确保内容真实、高质量
5. **账号安全**：避免频繁发布相似内容

## 📝 更新日志

### v1.1.0 (2026-02-27)
- ✨ 新增完全自动化发布功能
- 🔐 改进登录流程，cookies 正确保存
- 🤖 使用无头浏览器模拟真人操作
- 📸 支持批量发布多篇笔记
- ⏰ 自动防限流等待机制

### v1.0.0 (2026-02-27)
- 🎉 初始版本发布
- 🔐 扫码登录功能
- 📸 手动辅助发布
- 💬 智能文案生成

## 🔗 相关链接

- **GitHub**: https://github.com/zhouxiaoming666/clawra-xiaohongshu
- [OpenClaw 文档](https://docs.openclaw.ai)
- [阿里云百炼](https://help.aliyun.com/product/42154.html)
- [Playwright 文档](https://playwright.dev)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

---

**Made with ❤️ by Scarlett for Boss**

**完全自动化，让发布更简单！** 🚀
