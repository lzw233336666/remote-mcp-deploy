' ==============================================================================
' mcp_watchdog_windows.vbs - 无黑窗口后台静默启动看门狗
' 将本文件的快捷方式放入 Windows 开机启动文件夹 (Win+R 输入 shell:startup) 即可实现开机无感静默守护
' ==============================================================================

Set WshShell = CreateObject("WScript.Shell")
strCurDir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
WshShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & strCurDir & "\mcp_watchdog_windows.ps1""", 0, False
