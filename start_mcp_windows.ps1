# ==============================================================================
# start_mcp_windows.ps1 - Windows 本地/工作站 MCP 服务 PowerShell 启动脚本
# ==============================================================================

$WorkspaceDir = "E:/"
$LocalPort = 28770
$LocalHost = "127.0.0.1"
$ServerUrl = "https://<YOUR_TUNNEL_NAME>-28770.<REGION>.devtunnels.ms"

$env:CODING_TOOLS_MCP_SERVER_URL = $ServerUrl
$env:CODING_TOOLS_MCP_OAUTH_PASSWORD = "pace_mcp_password"
$env:CODING_TOOLS_MCP_OAUTH_TOKEN_SECRET = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
$env:CODING_TOOLS_MCP_OAUTH_TOKEN_TTL = "604800"
$env:CODING_TOOLS_MCP_OAUTH_CLIENT_ID = "nfHyRokxtNzAlrEvMXX29sKF6W30VMOR"
$env:CODING_TOOLS_MCP_OAUTH_CLIENT_SECRET = "149g6CD2n9UlnGnprlJG1OR64mOkefYYWJecM6BNkL0"
$env:CODING_TOOLS_MCP_OAUTH_REDIRECT_URIS = "https://gemini.google.com/auth/callback,https://gemini.google.com/oauth/callback,https://gemini.google.com/callback,https://gemini.google.com,http://127.0.0.1/callback,https://localhost/callback,https://chatgpt.com,https://chat.openai.com"
$env:CODING_TOOLS_MCP_ALLOWED_ORIGINS = "https://gemini.google.com,https://chatgpt.com,https://chat.openai.com,$ServerUrl"
$env:CODING_TOOLS_MCP_EXPOSE_TOOLS = "list_dir,exec_command,read_file,apply_patch"

Write-Host "[*] 启动 Windows 本地 MCP 服务: Port $LocalPort, Workspace $WorkspaceDir"
python.exe -m coding_tools_mcp.server --workspace "$WorkspaceDir" --host $LocalHost --port $LocalPort --oauth-mode --permission-mode dangerous --dangerously-fake-readonly-annotations --shell-env-inherit all
