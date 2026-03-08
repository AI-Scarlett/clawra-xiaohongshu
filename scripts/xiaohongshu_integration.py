#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
灵犀 - 小红书发布集成模块
Xiaohongshu Integration for Lingxi

作者：斯嘉丽 Scarlett
日期：2026-03-08

功能：
- 检查登录状态
- 发布小红书笔记
- 错误处理与重试
"""

import subprocess
import json
import os
from pathlib import Path
from typing import Optional, Dict, Tuple
from dataclasses import dataclass


@dataclass
class PublishResult:
    """发布结果"""
    success: bool
    message: str
    days_left: Optional[int] = None
    error_code: Optional[str] = None


class XiaohongshuPublisher:
    """
    小红书发布器
    
    封装 clawra-xiaohongshu 脚本，提供 Python 接口
    """
    
    def __init__(self, script_dir: str = None):
        if script_dir is None:
            script_dir = Path(__file__).parent
        self.script_dir = Path(script_dir).expanduser()
        self.interface_script = self.script_dir / "lingxi-interface.sh"
        self.storage_dir = self.script_dir / "storage"
        self.cookies_file = self.storage_dir / "cookies.json"
        self.state_file = self.storage_dir / "login-state.json"
    
    def check_login_status(self) -> Tuple[bool, Optional[int], str]:
        """
        检查登录状态
        
        Returns:
            (is_logged_in, days_left, message)
        """
        if not self.interface_script.exists():
            return False, None, "❌ 接口脚本不存在"
        
        try:
            result = subprocess.run(
                ["bash", str(self.interface_script), "--check-login"],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            output = result.stdout.strip()
            
            if result.returncode == 0:
                # 已登录
                if "已登录" in output:
                    # 提取剩余天数
                    import re
                    match = re.search(r'剩余 (\d+) 天', output)
                    days_left = int(match.group(1)) if match else None
                    return True, days_left, output
                else:
                    return True, None, output
            else:
                # 未登录或过期
                if "未登录" in output:
                    return False, None, "❌ 未登录"
                elif "过期" in output:
                    return False, None, "❌ Cookie 已过期"
                else:
                    return False, None, output
                    
        except subprocess.TimeoutExpired:
            return False, None, "❌ 检查超时"
        except Exception as e:
            return False, None, f"❌ 检查失败：{e}"
    
    def login(self) -> bool:
        """
        执行登录
        
        Returns:
            登录是否成功
        """
        if not self.interface_script.exists():
            print("❌ 接口脚本不存在")
            return False
        
        try:
            print("📱 启动登录流程...")
            result = subprocess.run(
                ["bash", str(self.interface_script), "--login"],
                timeout=600  # 10 分钟超时
            )
            
            if result.returncode == 0:
                print("✅ 登录成功")
                return True
            else:
                print("❌ 登录失败")
                return False
                
        except subprocess.TimeoutExpired:
            print("❌ 登录超时")
            return False
        except Exception as e:
            print(f"❌ 登录失败：{e}")
            return False
    
    def publish(self, title: str, content: str, 
                image_path: Optional[str] = None) -> PublishResult:
        """
        发布小红书笔记
        
        Args:
            title: 标题
            content: 正文内容
            image_path: 封面图片路径（可选）
        
        Returns:
            发布结果
        """
        # 检查登录状态
        is_logged, days_left, msg = self.check_login_status()
        
        if not is_logged:
            return PublishResult(
                success=False,
                message=msg,
                error_code="NOT_LOGGED"
            )
        
        # 构建命令
        cmd = [
            "bash", str(self.interface_script),
            "--title", title,
            "--content", content
        ]
        
        if image_path:
            cmd.extend(["--image", image_path])
        
        try:
            print(f"📕 发布小红书笔记：{title}")
            print(f"   内容长度：{len(content)} 字")
            print(f"   图片：{image_path or '无'}")
            print(f"   Cookie 剩余：{days_left} 天")
            print("")
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=300  # 5 分钟超时
            )
            
            output = result.stdout + result.stderr
            
            if result.returncode == 0:
                return PublishResult(
                    success=True,
                    message="✅ 发布成功",
                    days_left=days_left
                )
            else:
                return PublishResult(
                    success=False,
                    message=f"❌ 发布失败：{output}",
                    days_left=days_left,
                    error_code="PUBLISH_FAILED"
                )
                
        except subprocess.TimeoutExpired:
            return PublishResult(
                success=False,
                message="❌ 发布超时（5 分钟）",
                days_left=days_left,
                error_code="TIMEOUT"
            )
        except Exception as e:
            return PublishResult(
                success=False,
                message=f"❌ 发布失败：{e}",
                days_left=days_left,
                error_code="ERROR"
            )
    
    def generate_caption(self, topic: str, style: str = "casual") -> str:
        """
        生成文案（简单版本，实际应该调用 LLM）
        
        Args:
            topic: 主题
            style: 风格（casual/professional/funny）
        
        Returns:
            生成的文案
        """
        # 这是一个简单模板，实际应该调用灵犀的模型生成
        templates = {
            "casual": f"""今天分享一下{topic}～

真的超好用的！强烈推荐给大家～

#{topic.replace(' ', '')} #好物分享 #推荐""",
            
            "professional": f"""专业解析：{topic}

核心要点：
1. 重要性
2. 应用场景
3. 实践建议

#专业知识 #{topic.replace(' ', '')} #学习分享""",
            
            "funny": f"""笑死！关于{topic}这件事...

我真的会谢！😂

#搞笑日常 #{topic.replace(' ', '')} #今日快乐"""
        }
        
        return templates.get(style, templates["casual"])


# 便捷函数
def check_status() -> Tuple[bool, Optional[int], str]:
    """检查登录状态"""
    publisher = XiaohongshuPublisher()
    return publisher.check_login_status()


def publish_note(title: str, content: str, 
                image_path: Optional[str] = None) -> PublishResult:
    """发布笔记"""
    publisher = XiaohongshuPublisher()
    return publisher.publish(title, content, image_path)


def do_login() -> bool:
    """执行登录"""
    publisher = XiaohongshuPublisher()
    return publisher.login()


# CLI 入口
if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 2:
        print("用法：python3 xiaohongshu_integration.py [command] [args]")
        print("")
        print("命令:")
        print("  check              检查登录状态")
        print("  login              登录")
        print("  publish <title> <content> [image]")
        print("                     发布笔记")
        print("")
        print("示例:")
        print("  python3 xiaohongshu_integration.py check")
        print("  python3 xiaohongshu_integration.py login")
        print("  python3 xiaohongshu_integration.py publish \"标题\" \"内容\" \"/path/to/image.jpg\"")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "check":
        is_logged, days, msg = check_status()
        print(msg)
        sys.exit(0 if is_logged else 1)
    
    elif command == "login":
        success = do_login()
        sys.exit(0 if success else 1)
    
    elif command == "publish":
        if len(sys.argv) < 4:
            print("❌ 错误：缺少标题或内容")
            sys.exit(1)
        
        title = sys.argv[2]
        content = sys.argv[3]
        image = sys.argv[4] if len(sys.argv) > 4 else None
        
        result = publish_note(title, content, image)
        print(result.message)
        sys.exit(0 if result.success else 1)
    
    else:
        print(f"❌ 未知命令：{command}")
        sys.exit(1)
