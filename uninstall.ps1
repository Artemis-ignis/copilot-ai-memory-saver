[CmdletBinding()]
param(
    [switch]$RestoreWindowsAI
)

$ErrorActionPreference = 'Stop'

Set-StrictMode -Version 2.0

$BaseDir = Join-Path $env:LOCALAPPDATA 'ArtemisClickToDo'
$StartupLnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'Artemis WinQ ClickToDo.lnk'
$TaskNames = @('Artemis_CTD_Start', 'Artemis_CTD_Cleanup', 'Artemis_CTD_Watchdog')

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Stop-ArtemisAutoHotkey {
    $baseNeedle = [Regex]::Escape($BaseDir)
    $scriptNeedle = [Regex]::Escape('WinQ-ClickToDo-OnDemand.ahk')
    $processes = Get-CimInstance Win32_Process -Filter "Name = 'AutoHotkey.exe' OR Name = 'AutoHotkey64.exe' OR Name = 'AutoHotkeyUX.exe'" -ErrorAction SilentlyContinue

    foreach ($process in @($processes)) {
        $commandLine = [string]$process.CommandLine
        if ($commandLine -match $baseNeedle -or $commandLine -match $scriptNeedle) {
            Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
        }
    }
}

if (-not (Test-IsAdministrator)) {
    throw '관리자 권한 PowerShell 5.1 창에서 uninstall.ps1을 실행해야 합니다.'
}

foreach ($taskName in $TaskNames) {
    schtasks.exe /End /TN $taskName 2>$null | Out-Null
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
}

Stop-ArtemisAutoHotkey

Remove-Item -LiteralPath $StartupLnk -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $BaseDir -Recurse -Force -ErrorAction SilentlyContinue

taskkill.exe /F /T /IM ClickToDo.exe 2>$null | Out-Null
taskkill.exe /F /T /IM AIXHost.exe 2>$null | Out-Null
taskkill.exe /F /T /IM WorkloadsSessionHost.exe 2>$null | Out-Null
taskkill.exe /F /T /IM WorkloadsSessionManager.exe 2>$null | Out-Null

if ($RestoreWindowsAI) {
    sc.exe config WSAIFabricSvc start= auto | Out-Null
    sc.exe start WSAIFabricSvc | Out-Null
}
else {
    sc.exe stop WSAIFabricSvc | Out-Null
    sc.exe config WSAIFabricSvc start= disabled | Out-Null
}

Write-Host ''
Get-Service WSAIFabricSvc -ErrorAction SilentlyContinue | Format-List Name, Status, StartType
Write-Host '삭제가 끝났습니다.'
