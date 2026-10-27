#!/bin/bash
# ==============================================================================
# start_mcp_service.sh - MCP 服务端单实例启动脚本
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${1:-$SCRIPT_DIR/config.env}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[-] 错误: 未找到配置文件 $CONFIG_FILE"
    echo "    请复制 config.env.template 为 config.env 并配置相应参数。"
    exit 1
fi

# 加载配置
source "$CONFIG_FILE"

# 检查占位符是否未替换
if [[ "$PUBLIC_BASE_URL" == *"<YOUR_"* ]]; then
    echo "[-] 警告: PUBLIC_BASE_URL 仍包含占位符，请先编辑 $CONFIG_FILE 填入实际隧道公网地址！"
    exit 1
fi

echo "[*] 启动配置信息:"
echo "    - 监听地址: http://$LOCAL_HOST:$LOCAL_PORT"
echo "    - 绑定公网: $PUBLIC_BASE_URL"
echo "    - 工作目录: $WORKSPACE_DIR"
echo "    - 暴露工具: $EXPOSED_TOOLS"

# 释放占用端口
if command -v fuser >/dev/null 2>&1; then
    fuser -k "$LOCAL_PORT/tcp" 2>/dev/null || true
    sleep 1
fi

# 导出 MCP 运行环境变量
export CODING_TOOLS_MCP_SERVER_URL="$PUBLIC_BASE_URL"
export CODING_TOOLS_MCP_OAUTH_PASSWORD="$OAUTH_USER_PASSWORD"
export CODING_TOOLS_MCP_OAUTH_TOKEN_SECRET="$OAUTH_TOKEN_SECRET"
export CODING_TOOLS_MCP_OAUTH_TOKEN_TTL="$OAUTH_TOKEN_TTL"
export CODING_TOOLS_MCP_OAUTH_CLIENT_ID="$OAUTH_CLIENT_ID"
export CODING_TOOLS_MCP_OAUTH_CLIENT_SECRET="$OAUTH_CLIENT_SECRET"
export CODING_TOOLS_MCP_OAUTH_REDIRECT_URIS="$OAUTH_REDIRECT_URIS"
export CODING_TOOLS_MCP_ALLOWED_ORIGINS="$ALLOWED_ORIGINS"
export CODING_TOOLS_MCP_EXPOSE_TOOLS="$EXPOSED_TOOLS"

mkdir -p "$(dirname "$LOG_FILE")"

# 启动服务端主进程
nohup "$PYTHON_EXEC" -m coding_tools_mcp.server \
    --workspace "$WORKSPACE_DIR" \
    --host "$LOCAL_HOST" \
    --port "$LOCAL_PORT" \
    --oauth-mode \
    --permission-mode "$PERMISSION_MODE" \
    --dangerously-fake-readonly-annotations \
    --shell-env-inherit all > "$LOG_FILE" 2>&1 &

PID=$!
sleep 2

if ps -p $PID >/dev/null 2>&1; then
    echo "[✔] MCP 服务已成功在后台启动 (PID: $PID)"
    echo "    日志输出: $LOG_FILE"
else
    echo "[-] 启动失败，请检查日志:"
    tail -n 20 "$LOG_FILE"
    exit 1
fi
