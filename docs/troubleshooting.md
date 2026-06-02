# Troubleshooting

## Win + Q does not open Click to Do

Check:

```powershell
Get-Process AutoHotkey* -ErrorAction SilentlyContinue
Get-ScheduledTask Artemis_CTD_Start,Artemis_CTD_Watchdog
Test-Path "$env:LOCALAPPDATA\ArtemisClickToDo\WinQ-ClickToDo-OnDemand.ahk"
```

Try:

```powershell
schtasks.exe /Run /TN "Artemis_CTD_Start"
Get-Content "$env:LOCALAPPDATA\ArtemisClickToDo\start.log" -Tail 50
```

If AutoHotkey is missing, rerun `install.ps1` as administrator.

## WorkloadsSessionHost stays alive

Check:

```powershell
Get-Process WorkloadsSessionHost,WorkloadsSessionManager,AIXHost,ClickToDo -ErrorAction SilentlyContinue
Get-Service WSAIFabricSvc
Get-Content "$env:LOCALAPPDATA\ArtemisClickToDo\watchdog.log" -Tail 100
```

Try:

```powershell
Remove-Item "$env:LOCALAPPDATA\ArtemisClickToDo\ctd_open.flag" -ErrorAction SilentlyContinue
Stop-Process -Name WorkloadsSessionHost,WorkloadsSessionManager,AIXHost,ClickToDo -Force -ErrorAction SilentlyContinue
sc.exe stop WSAIFabricSvc
sc.exe config WSAIFabricSvc start= disabled
```

## Watchdog is not running

Check:

```powershell
Get-ScheduledTask Artemis_CTD_Watchdog
Get-Process powershell -IncludeUserName | Where-Object { $_.UserName -eq "$env:USERDOMAIN\$env:USERNAME" }
Get-Content "$env:LOCALAPPDATA\ArtemisClickToDo\watchdog.log" -Tail 50
```

Try:

```powershell
schtasks.exe /Run /TN "Artemis_CTD_Watchdog"
```

If the task state is not `Ready`, uninstall and reinstall from an elevated PowerShell window.

## AutoHotkey is not running

Check:

```powershell
Get-Process AutoHotkey* -ErrorAction SilentlyContinue
Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
```

Try:

```powershell
& "$env:LOCALAPPDATA\ArtemisClickToDo\AutoHotkey.exe" "$env:LOCALAPPDATA\ArtemisClickToDo\WinQ-ClickToDo-OnDemand.ahk"
```

If the executable path is different, rerun `install.ps1` so the launcher can rediscover AutoHotkey v2.

## Scheduled tasks are not Ready

Check:

```powershell
Get-ScheduledTask Artemis_CTD_Start,Artemis_CTD_Watchdog | Select-Object TaskName,State,Author
```

Try:

```powershell
Unregister-ScheduledTask -TaskName Artemis_CTD_Start -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName Artemis_CTD_Watchdog -Confirm:$false -ErrorAction SilentlyContinue
.\install.ps1
```

## WSAIFabricSvc keeps coming back

Check:

```powershell
Get-Service WSAIFabricSvc
Get-Content "$env:LOCALAPPDATA\ArtemisClickToDo\start.log" -Tail 50
Get-Content "$env:LOCALAPPDATA\ArtemisClickToDo\watchdog.log" -Tail 100
```

Notes:

- A Windows update or a different Windows AI workload package may be restarting the service.
- Some systems may relaunch the backend immediately if Click to Do or a related workflow remains open.
- On managed PCs, service recovery or policy can override the local setting.
