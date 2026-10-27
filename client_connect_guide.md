# Web AI (Gemini & ChatGPT) 客户端连接配置指南

本文档指导如何在不同电脑或网页端 AI（Google Gemini 与 OpenAI ChatGPT）中，将远程部署的 GPU / Linux 服务器作为 MCP 工具集连接接入。

---

## 一、通用连接凭证清单

在连接前，请从服务端的 `config.env` 中获取以下连接参数（以下均为模板占位符，请填入实际值）：

| 参数项 | 说明 | 示例 / 填写内容 |
| :--- | :--- | :--- |
| **MCP 服务器网址** | 穿透隧道分配的 HTTPS 网址 | `https://<YOUR_TUNNEL_NAME>-<PORT>.<REGION>.devtunnels.ms` *(或 `.../mcp`)* |
| **客户端 ID** | OAuth Client ID | `<YOUR_CLIENT_ID>` *(例如 `nfHyRokxtNzAlrEvMXX29sKF6W30VMOR`)* |
| **客户端密钥** | OAuth Client Secret | `<YOUR_CLIENT_SECRET>` *(例如 `149g6CD2n9UlnGnprlJG1OR64mOkefYYWJecM6BNkL0`)* |
| **授权登录密码** | 弹窗中验证的凭据 | `<YOUR_SECURE_AUTH_PASSWORD>` |

---

## 二、Google Gemini Web 端接入操作指南

### 1. 添加连接器
1. 打开浏览器访问：[Gemini 连接器管理页面 (gemini.google.com/customize/connectors)](https://gemini.google.com/customize/connectors)。
2. 点击右上角 **「+ 自定义」**（或「连接到 MCP 服务器」/「Connect to an MCP server」）。
3. **MCP 服务器网址**：填入 `https://<YOUR_TUNNEL_NAME>-<PORT>.<REGION>.devtunnels.ms`。
4. 点击展开下方 **「其他设置 (Additional settings)」**：
   - **客户端 ID**：填入 `<YOUR_CLIENT_ID>`。
   - **客户端密钥**：填入 `<YOUR_CLIENT_SECRET>`。
5. 点击 **「下一步 (Next)」**。
6. 在弹出的授权登录页面中：
   - 输入你设置的 **授权登录密码**。
   - 点击 **「Authorize」**（或「同意并继续」），页面关闭并提示关联成功。

### 2. 避免常见错误的关键规范
> [!IMPORTANT]
> **必须开启【+ 新对话】**：
> 关联成功后，**切勿在旧的聊天窗口中直接测试**。Gemini 会在对话创建时锁定当期的工具实例 ID，旧对话无法识别新绑定的连接器，必须点击左上角开启一个全新对话！
> 
> **模型选择排查**：
> 如果输入框右下角显示的是实验性分支（如 `Argon 高点`），部分测试模型尚未接通生产环境工具调度，请将其切换为主力模型（如 `Gemini Advanced` / `Gemini 1.5 Pro` / `Gemini 2.0 Flash`）。

### 3. 会话调用测试
在新对话中输入以下指令测试：
```text
@<你的应用标识名> 请帮我执行 pwd 并查看 GPU 显卡状态 (nvidia-smi)
```
Gemini 将自动调用 `exec_command`，并在几百毫秒内返回服务器工作目录与显卡显存信息。

---

## 三、OpenAI ChatGPT Web 端接入操作指南

### 1. 添加连接器
1. 打开 ChatGPT 网页端，点击左下角头像 -> **设置 (Settings)** -> **连接的应用 / 开发人员模式 (Connected Apps / Developer Mode)**。
2. 选择 **「添加 MCP / 操作 (Add Action / MCP Server)」**。
3. 填入服务端点：
   - **MCP Endpoint URL**: `https://<YOUR_TUNNEL_NAME>-<PORT>.<REGION>.devtunnels.ms/mcp`
4. 认证方式选择 **OAuth**：
   - **Client ID**: `<YOUR_CLIENT_ID>`
   - **Client Secret**: `<YOUR_CLIENT_SECRET>`
   - **Authorization URL**: `https://<YOUR_TUNNEL_NAME>-<PORT>.<REGION>.devtunnels.ms/oauth/authorize`
   - **Token URL**: `https://<YOUR_TUNNEL_NAME>-<PORT>.<REGION>.devtunnels.ms/oauth/token`
5. 点击授权，在弹窗输入密码并保存。

### 2. 会话调用测试
在 ChatGPT 对话窗口中发送：
```text
请调用工具查看当前目录下有哪些文件，并运行 pwd
```

---

## 四、本地 Claude Desktop 客户端接入（可选）

如果其他电脑安装了 Claude Desktop，可以在 `claude_desktop_config.json` 中以 SSE 模式直接接入：

```json
{
  "mcpServers": {
    "remote-gpu-server": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote-client",
        "https://<YOUR_TUNNEL_NAME>-<PORT>.<REGION>.devtunnels.ms/mcp",
        "--header",
        "Authorization: Bearer <YOUR_STATIC_OR_OAUTH_TOKEN>"
      ]
    }
  }
}
```
