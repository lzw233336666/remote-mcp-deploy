# ==============================================================================
# mcp_watchdog_windows.ps1
# Windows 24/7 看门狗与故障自愈守护脚本 (监控本地 MCP 服务端口活性、DevTunnel 隧道状态与 30 天自动续期)
# ==============================================================================

$ErrorActionPreference = "SilentlyContinue"

# 基础参数配置 (可根据实际情况修改)
$Port = 28770
$DevTunnelName = "<YOUR_DEVTUNNEL_NAME>" # 例如 pace-local-e
$StartScript = "$PSScriptRoot\start_mcp_windows.bat"
$LogFile = "$PSScriptRoot\mcp_watchdog_windows.log"

function Log-Msg([string]$msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] $msg"
    Write-Output $line
    Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
}

Log-Msg "=== Windows MCP 24/7 Watchdog 守护已启动 ==="
$lastExpirationCheck = [DateTime]::MinValue

while ($true) {
    try {
        # 1. 检查本地 MCP 服务端口状态 (监听与 HTTP 401/200 探测)
        $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
        $mcpHealthy = $false
        if ($conn) {
            try {
                $req = [System.Net.WebRequest]::Create("http://127.0.0.1:$Port/mcp")
                $req.Timeout = 2000
                $resp = $req.GetResponse()
                $resp.Close()
                $mcpHealthy = $true
            } catch [System.Net.WebException] {
                # 401 Unauthorized 表示服务正常运行并等待认证
                if ($_.Response -and ($_.Response.StatusCode -eq 401 -or $_.Response.StatusCode -eq 200)) {
                    $mcpHealthy = $true
                }
            } catch {}
        }

        if (!$mcpHealthy) {
            Log-Msg "[HEAL] 端口 $Port 未响应，正在触发自动拉起: $StartScript"
            if ($conn) { Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue }
            Start-Sleep -Milliseconds 500
            
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$StartScript`"" -WindowStyle Hidden
            Log-Msg "[INFO] MCP 服务已通过后台进程重新启动"
        }

        # 2. 检查 DevTunnel 隧道进程状态 (如果配置了隧道名)
        if ($DevTunnelName -and $DevTunnelName -ne "<YOUR_DEVTUNNEL_NAME>") {
            $tunnelHostProc = Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like "*host $DevTunnelName*" }
            if (!$tunnelHostProc) {
                Log-Msg "[HEAL] devtunnel host $DevTunnelName 进程丢失，正在启动..."
                Start-Process -FilePath "devtunnel" -ArgumentList "host $DevTunnelName" -WindowStyle Hidden
                Log-Msg "[INFO] devtunnel host $DevTunnelName 已拉起"
            }

            # 3. 每 12 小时自动为 DevTunnel 续期 30 天有效期 (防止到期被微软服务器注销)
            if ((Get-Date) -gt $lastExpirationCheck.AddHours(12)) {
                Log-Msg "[MAINT] 正在自动延期 DevTunnel 30 天有效期..."
                devtunnel update $DevTunnelName -e 30d 2>$null
                $lastExpirationCheck = Get-Date
            }
        }

        # 4. 日志轮转 (超过 5MB 自动归档)
        if (Test-Path $LogFile) {
            $item = Get-Item $LogFile
            if ($item.Length -gt 5MB) {
                Move-Item -Path $LogFile -Destination "$LogFile.old" -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {
        Log-Msg "[ERR] 守护主循环异常: $_"
    }

    Start-Sleep -Seconds 15
}
