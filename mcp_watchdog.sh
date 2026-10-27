#!/bin/bash
# ==============================================================================
# mcp_watchdog.sh - 24/7 守护与故障自愈脚本
# 负责自动监控 MCP 服务端口活性、DevTunnel 隧道状态与异常自动恢复
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${1:-$SCRIPT_DIR/config.env}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[-] 错误: 未找到配置文件 $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

WATCHDOG_LOG="${WATCHDOG_LOG:-./mcp_watchdog.log}"
DEVTUNNEL_LOG="${DEVTUNNEL_LOG:-./devtunnel.log}"
DEVTUNNEL_NAME="${DEVTUNNEL_NAME:-<YOUR_DEVTUNNEL_NAME>}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$WATCHDOG_LOG"
}

log "[*] MCP 24/7 守护脚本启动..."
LAST_RECYCLE=$(date +%s)

while true; do
    # 1. 检查 MCP 服务端口状态
    PORT_DOWN=0
    if command -v fuser >/dev/null 2>&1; then
        if ! fuser "$LOCAL_PORT/tcp" >/dev/null 2>&1; then
            PORT_DOWN=1
        fi
    else
        if ! curl -s "http://$LOCAL_HOST:$LOCAL_PORT/mcp" >/dev/null 2>&1; then
            PORT_DOWN=1
        fi
    fi

    if [ "$PORT_DOWN" -eq 1 ]; then
        log "[!] 端口 $LOCAL_PORT 未在监听，正在触发自动重启..."
        bash "$SCRIPT_DIR/start_mcp_service.sh" "$CONFIG_FILE" >> "$WATCHDOG_LOG" 2>&1 || true
    fi

    # 2. 检查穿透隧道 DevTunnel 进程与状态 (如果使用 DevTunnel)
    if [ "$DEVTUNNEL_NAME" != "<YOUR_DEVTUNNEL_NAME>" ]; then
        TUNNEL_NEED_RESTART=0
        if ! pgrep -f "devtunnel host $DEVTUNNEL_NAME" >/dev/null 2>&1; then
            log "[!] DevTunnel 隧道进程丢失，准备启动..."
            TUNNEL_NEED_RESTART=1
        else
            # 检测隧道死锁标志 (如 Invalid channel ID)
            if tail -n 20 "$DEVTUNNEL_LOG" 2>/dev/null | grep -q "Invalid channel ID"; then
                log "[!] 检测到 DevTunnel 隧道死锁 (Invalid channel ID)，准备重置..."
                TUNNEL_NEED_RESTART=1
            fi

            # 周期性预防式重载 (默认 4 小时)，防止长连接 Relay 句柄老化
            NOW=$(date +%s)
            if [ $((NOW - LAST_RECYCLE)) -gt 14400 ]; then
                log "[*] 执行周期性 DevTunnel 预防式刷新..."
                TUNNEL_NEED_RESTART=1
                LAST_RECYCLE=$NOW
            fi
        fi

        if [ "$TUNNEL_NEED_RESTART" -eq 1 ]; then
            pkill -f "devtunnel host $DEVTUNNEL_NAME" 2>/dev/null || true
            sleep 2
            nohup devtunnel host "$DEVTUNNEL_NAME" </dev/null >> "$DEVTUNNEL_LOG" 2>&1 &
            sleep 2
            log "[✔] DevTunnel 隧道重启完成"
        fi
    fi

    sleep 5
done
