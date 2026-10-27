#!/bin/bash
# ==============================================================================
# setup_environment.sh - 一键初始化与依赖安装脚本
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================================================="
echo "          MCP 远程代码执行服务 - 运行环境自动初始化工具"
echo "=========================================================================="

# 1. 检查 Python 版本
PYTHON_BIN="${PYTHON_BIN:-python3}"
if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    echo "[-] 错误: 未检测到 $PYTHON_BIN，请先安装 Python 3.10+"
    exit 1
fi

PY_VER=$("$PYTHON_BIN" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "[+] 当前 Python 版本: $PY_VER"

# 2. 安装/更新 coding-tools-mcp 核心包
echo "[*] 正在安装 coding-tools-mcp..."
"$PYTHON_BIN" -m pip install --upgrade coding-tools-mcp

# 3. 执行热补丁注入 (注入 PROD 环境、双路由与免认证握手)
echo "[*] 正在为服务端注入 Gemini / ChatGPT 兼容补丁..."
"$PYTHON_BIN" "$SCRIPT_DIR/patch_mcp_server.py"

# 4. 检查/指导安装 DevTunnel
if ! command -v devtunnel >/dev/null 2>&1; then
    echo ""
    echo "[!] 提示: 系统尚未全局安装微软 devtunnel CLI (推荐的免费内网穿透工具)"
    echo "    安装方法 (Linux x64):"
    echo "    curl -sL https://aka.ms/TunnelsCliDownload/linux-x64 -o devtunnel && chmod +x devtunnel && sudo mv devtunnel /usr/local/bin/"
    echo "    登录并创建持久隧道:"
    echo "    devtunnel user login"
    echo "    devtunnel create <YOUR_TUNNEL_NAME>"
    echo "    devtunnel port create <YOUR_TUNNEL_NAME> -p 28767"
    echo "    devtunnel port access create <YOUR_TUNNEL_NAME> -p 28767 --anonymous"
    echo ""
fi

# 5. 准备配置文件
if [ ! -f "$SCRIPT_DIR/config.env" ]; then
    cp "$SCRIPT_DIR/config.env.template" "$SCRIPT_DIR/config.env"
    echo "[+] 已自动生成配置文件: $SCRIPT_DIR/config.env"
    echo "    请编辑 config.env 填入你的公网隧道网址和密码！"
else
    echo "[=] 配置文件 config.env 已存在，保留现有配置。"
fi

echo ""
echo "=========================================================================="
echo "[✔] 环境部署与补丁注入完成！"
echo "    启动服务: bash start_mcp_service.sh"
echo "    启动守护: nohup bash mcp_watchdog.sh >/dev/null 2>&1 &"
echo "=========================================================================="
