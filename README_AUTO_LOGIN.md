# 小红书自动登录与发布 - 使用文档

> **版本:** v2.0 (Cookie 持久化)  
> **作者:** 斯嘉丽 Scarlett  
> **日期:** 2026-03-08

---

## 🎯 解决的问题

### 旧方案痛点
- ❌ 每次都要扫码登录
- ❌ Cookie 不保存，重复登录
- ❌ 需要手动操作浏览器

### 新方案优势
- ✅ **一次登录，30 天有效** - Cookie 持久化保存
- ✅ **自动发布** - 无需打开浏览器
- ✅ **后台运行** - 无头模式，不占用屏幕

---

## 📁 文件说明

| 文件 | 功能 |
|------|------|
| `xiaohongshu-auto-login.sh` | 自动登录（保存 Cookie） |
| `xiaohongshu-auto-post.sh` | 自动发布（使用 Cookie） |
| `storage/cookies.json` | Cookie 存储文件（自动生成） |
| `storage/login-state.json` | 登录状态（自动生成） |

---

## 🚀 快速开始

### 步骤 1: 登录（只需一次）

```bash
cd /root/.openclaw/skills/clawra-xiaohongshu/scripts

# 执行登录脚本
./xiaohongshu-auto-login.sh
```

**流程:**
1. 自动打开浏览器窗口
2. 显示登录二维码
3. 用手机小红书 APP 扫码
4. 确认登录
5. 自动保存 Cookie

**成功后输出:**
```
==========================================
✅ 登录成功！
📅 登录时间：2026-03-08T09:50:00.000Z
⏰ 有效期至：2026-04-07T09:50:00.000Z
==========================================
```

---

### 步骤 2: 发布笔记

```bash
# 基本用法
./xiaohongshu-auto-post.sh "标题" "正文内容"

# 带图片
./xiaohongshu-auto-post.sh "标题" "正文内容" "/path/to/image.jpg"
```

**示例:**
```bash
./xiaohongshu-auto-post.sh \
  "AI 工具推荐｜这 5 个神器让你效率翻倍" \
  "今天给大家分享 5 个超好用的 AI 工具... #AI #效率工具 #职场必备" \
  "/tmp/cover.jpg"
```

---

## 💡 使用场景

### 场景 1: 灵犀集成（推荐）

在灵犀中直接使用：

```
你：帮我发个小红书
斯嘉丽：好的老板，正在发布...
→ 自动调用 auto-post.sh
→ 使用已保存的 Cookie
→ 无需登录，直接发布
```

---

### 场景 2: 命令行发布

```bash
# 查看 Cookie 状态
cat storage/login-state.json

# 发布文字笔记
./xiaohongshu-auto-post.sh \
  "今日心情" \
  "阳光明媚，心情美美哒 ☀️ #日常"

# 发布图文笔记
./xiaohongshu-auto-post.sh \
  "美食探店" \
  "这家店真的太好吃了！#美食 #探店" \
  "/photos/food.jpg"
```

---

### 场景 3: 定时发布

配合 cron 实现定时发布：

```bash
# 编辑 crontab
crontab -e

# 添加定时任务（每天早上 9 点发布）
0 9 * * * cd /root/.openclaw/skills/clawra-xiaohongshu/scripts && \
  ./xiaohongshu-auto-post.sh \
  "早安｜每日正能量" \
  "新的一天，加油！#早安 #正能量" >> /var/log/xhs_post.log 2>&1
```

---

## 🔧 Cookie 管理

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

---

### 检查 Cookie 有效期

```bash
# 脚本会自动检查，无需手动操作
./xiaohongshu-auto-post.sh "标题" "内容"

# 如果 Cookie 过期，会提示：
# ❌ Cookie 已过期
# 💡 请重新登录：xiaohongshu-auto-login.sh
```

---

### 手动刷新 Cookie

```bash
# 方法 1: 删除 Cookie 重新登录
rm storage/cookies.json storage/login-state.json
./xiaohongshu-auto-login.sh

# 方法 2: 直接运行登录脚本（会覆盖旧 Cookie）
./xiaohongshu-auto-login.sh
```

---

### Cookie 存储位置

```
/root/.openclaw/skills/clawra-xiaohongshu/storage/
├── cookies.json        # Cookie 文件
└── login-state.json    # 登录状态
```

---

## 📊 日志与调试

### 查看发布日志

```bash
# 查看最近一次发布
tail -50 /var/log/xhs_post.log

# 实时查看
tail -f /var/log/xhs_post.log
```

---

### 调试模式

```bash
# 开启调试输出
DEBUG=1 ./xiaohongshu-auto-post.sh "标题" "内容"
```

---

## ⚠️ 注意事项

### 1. Cookie 有效期

- **理论有效期:** 30 天
- **实际有效期:** 取决于小红书官方策略
- **建议:** 每 2-3 周重新登录一次

---

### 2. 异地登录风险

如果频繁更换 IP 或设备，可能触发风控：

**解决方案:**
- 固定服务器 IP
- 使用固定 User-Agent
- 避免短时间内大量发布

---

### 3. 发布频率限制

- **建议频率:** 每天 1-3 篇
- **安全间隔:** 至少 1 小时
- **避免:** 短时间内连续发布

---

## 🎯 与灵犀集成

### 在灵犀中使用

编辑灵犀的小红书技能，添加自动发布支持：

```python
# 检测是否有 Cookie
if os.path.exists('storage/cookies.json'):
    # 使用自动发布
    subprocess.run([
        './xiaohongshu-auto-post.sh',
        title,
        content,
        image_path
    ])
else:
    # 需要登录
    print("需要先登录，请运行 xiaohongshu-auto-login.sh")
```

---

### 完整工作流

```
用户说："帮我发个小红书"
    ↓
1️⃣ 生成标题（5 个风格）
    ↓
2️⃣ 生成正文（600-800 字）
    ↓
3️⃣ 生成封面图（AI 或用户提供）
    ↓
4️⃣ 检查 Cookie
    ├─ 有效 → 直接发布
    └─ 过期 → 提示重新登录
    ↓
5️⃣ 发布成功，返回链接
```

---

## ❓ 常见问题

### Q: Cookie 能保存多久？
A: 理论 30 天，实际取决于小红书官方策略。建议 2-3 周重新登录一次。

### Q: 可以在多台设备使用吗？
A: 可以，但建议固定使用一台设备（服务器）发布。

### Q: 会被封号吗？
A: 正常使用不会。避免：
- 短时间内大量发布
- 发布违规内容
- 频繁更换 IP

### Q: 图片支持哪些格式？
A: JPG、PNG、WebP 等常见格式。

### Q: 支持视频发布吗？
A: 当前版本仅支持图文，视频发布需要额外开发。

---

## 📝 更新日志

### v2.0 (2026-03-08)
- ✅ Cookie 持久化（30 天有效）
- ✅ 自动登录脚本
- ✅ 自动发布脚本
- ✅ 无头模式发布
- ✅ 状态检查与过期提醒

### v1.0 (旧版本)
- ❌ 每次都需要登录
- ❌ 手动扫码
- ❌ 不保存 Cookie

---

## 📞 支持

如有问题，请联系：
- 作者：斯嘉丽 Scarlett
- 项目：Clawra Xiaohongshu
- 位置：`/root/.openclaw/skills/clawra-xiaohongshu/`

---

_一次登录，30 天无忧发布_ 💋
