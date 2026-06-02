# How It Works

`Copilot AI Memory Saver` keeps `Win + Q` usable while pushing the heavy Click to Do backend into an on-demand lifecycle.

## End-to-End Flow

1. `install.ps1` copies the scripts into `%LOCALAPPDATA%\ArtemisClickToDo`.
2. The installer registers:
   - `Artemis_CTD_Start`: manual scheduled task, highest privileges, current user
   - `Artemis_CTD_Watchdog`: logon scheduled task, highest privileges, current user
   - Startup shortcut for `WinQ-ClickToDo-OnDemand.ahk`
3. The installer stops and disables `WSAIFabricSvc`, and clears stale Click to Do / Windows AI processes.
4. On each login, the watchdog starts hidden and waits in a low-CPU 3-second loop.
5. When you press `Win + Q`, AutoHotkey:
   - updates `ctd_open.flag`
   - runs `schtasks.exe /Run /TN "Artemis_CTD_Start"`
   - waits for the Windows key release
   - forwards the real `Win + Q` to Windows
6. `Artemis_CTD_Start` switches `WSAIFabricSvc` to demand start, starts it, waits 2 seconds, then exits.
7. Click to Do opens normally.
8. After `ctd_open.flag` has been idle for 30 seconds, the watchdog:
   - disables and stops `WSAIFabricSvc`
   - kills `ClickToDo.exe`
   - kills `AIXHost.exe`
   - kills `WorkloadsSessionHost.exe`
   - kills `WorkloadsSessionManager.exe`
   - retries the kill sequence once after 2 seconds
   - removes the flag

## Text Diagram

```text
[User presses Win+Q]
        |
        v
[AutoHotkey launcher]
        |
        +--> write ctd_open.flag
        +--> run Artemis_CTD_Start
        +--> forward real Win+Q
                    |
                    v
              [Click to Do opens]

[Artemis_CTD_Start]
        |
        +--> sc.exe config WSAIFabricSvc start= demand
        +--> sc.exe start WSAIFabricSvc
        +--> sleep 2 seconds

[Artemis_CTD_Watchdog]
        |
        +--> loop every 3 seconds
        +--> if flag idle >= 30 seconds:
                - taskkill ClickToDo / AIXHost / WorkloadsSessionHost / WorkloadsSessionManager
                - stop + disable WSAIFabricSvc
                - retry after 2 seconds
                - delete flag
```

## Why the watchdog exists

An older one-shot cleanup task can miss lingering child processes or race with the Click to Do shutdown path. The watchdog avoids that by observing the flag continuously and cleaning up only after the interaction has gone idle.

## Files involved

- `install.ps1`
- `uninstall.ps1`
- `scripts/Start-ClickToDo-Backend.ps1`
- `scripts/Watchdog-ClickToDo-Cleanup.ps1`
- `scripts/WinQ-ClickToDo-OnDemand.ahk`
