@echo off
setlocal enabledelayedexpansion

REM ==============================================================================
REM start_mcp_windows.bat - Windows 本地/工作站 MCP 服务启动脚本
REM ==============================================================================

REM 1. 基础工作区与端口配置
set "PYTHON_EXEC=python.exe"
REM 注意: Windows 路径请使用正斜杠 (如 E:/ 或 E:/my_workspace)，避免反斜杠在引号中转义引发语法错误
set "WORKSPACE_DIR=E:/"
set "LOCAL_PORT=28770"
set "LOCAL_HOST=127.0.0.1"

REM 2. 公网穿透与安全配置 (DevTunnel)
set "CODING_TOOLS_MCP_SERVER_URL=https://<YOUR_TUNNEL_NAME>-28770.<REGION>.devtunnels.ms"
set "CODING_TOOLS_MCP_OAUTH_PASSWORD=pace_mcp_password"
set "CODING_TOOLS_MCP_OAUTH_TOKEN_SECRET=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
set "CODING_TOOLS_MCP_OAUTH_TOKEN_TTL=604800"
set "CODING_TOOLS_MCP_OAUTH_CLIENT_ID=nfHyRokxtNzAlrEvMXX29sKF6W30VMOR"
set "CODING_TOOLS_MCP_OAUTH_CLIENT_SECRET=149g6CD2n9UlnGnprlJG1OR64mOkefYYWJecM6BNkL0"

REM 3. 授权回调与跨域配置 (已集成动态域名匹配，自动兼容 Google Gemini / ChatGPT 动态分配的回调)
set "CODING_TOOLS_MCP_OAUTH_REDIRECT_URIS=https://gemini.google.com/auth/callback,https://gemini.google.com/oauth/callback,https://gemini.google.com/callback,https://gemini.google.com,http://127.0.0.1/callback,https://localhost/callback,https://chatgpt.com,https://chat.openai.com"
set "CODING_TOOLS_MCP_ALLOWED_ORIGINS=https://gemini.google.com,https://chatgpt.com,https://chat.openai.com,%CODING_TOOLS_MCP_SERVER_URL%"
set "CODING_TOOLS_MCP_EXPOSE_TOOLS=list_dir,exec_command,read_file,apply_patch"

echo [*] 正在启动 Windows 本地 MCP 服务:
echo     - 工作目录: %WORKSPACE_DIR%
echo     - 监听端口: %LOCAL_PORT%
echo     - 公网地址: %CODING_TOOLS_MCP_SERVER_URL%

%PYTHON_EXEC% -m coding_tools_mcp.server --workspace "%WORKSPACE_DIR%" --host %LOCAL_HOST% --port %LOCAL_PORT% --oauth-mode --permission-mode dangerous --dangerously-fake-readonly-annotations --shell-env-inherit all

pause
