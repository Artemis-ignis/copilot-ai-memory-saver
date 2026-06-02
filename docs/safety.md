# Safety

## What this project does

- Keeps `Win + Q` usable for Click to Do.
- Starts `WSAIFabricSvc` only when `Win + Q` is invoked.
- Monitors idle time with `%LOCALAPPDATA%\ArtemisClickToDo\ctd_open.flag`.
- Stops and disables `WSAIFabricSvc` after the Click to Do session goes idle.
- Cleans up the main related processes: `ClickToDo.exe`, `AIXHost.exe`, `WorkloadsSessionHost.exe`, `WorkloadsSessionManager.exe`.

## What this project does not do

- It does not uninstall `WindowsWorkload.*` packages.
- It does not patch `System32`, `WindowsApps`, or other system binaries.
- It does not disable `WSearch`, `SearchHost.exe`, or `SearchIndexer.exe`.
- It does not turn on a `DisableClickToDo` policy by default.
- It does not attempt to stop every AutoHotkey script on the machine.
- It does not guarantee a fixed amount of memory savings on every system.

## Use with care

- Use caution on work, school, or otherwise managed devices.
- Windows updates may change the internal behavior of Click to Do, Windows AI Fabric, or related process names.
- If another tool depends on the same service or processes, you may need to tune the delay window instead of using the default 30 seconds.

## Rollback

- Run `.\uninstall.ps1` to remove the scheduled tasks, startup shortcut, and local runtime files.
- Run `.\uninstall.ps1 -RestoreWindowsAI` if you want to return `WSAIFabricSvc` to `Automatic` and start it immediately.
