$ErrorActionPreference = 'SilentlyContinue'

$BaseDir = Join-Path $env:LOCALAPPDATA 'ArtemisClickToDo'
$FlagFile = Join-Path $BaseDir 'ctd_open.flag'
$LogFile = Join-Path $BaseDir 'watchdog.log'
$DelaySeconds = 30
$TargetNames = @(
    'ClickToDo',
    'AIXHost',
    'WorkloadsSessionHost',
    'WorkloadsSessionManager'
)

New-Item -ItemType Directory -Path $BaseDir -Force | Out-Null

function Write-WatchdogLog {
    param([string]$Message)
    Add-Content -Path $LogFile -Value ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message)
}

function Stop-TargetsByTaskKill {
    foreach ($name in $TargetNames) {
        taskkill.exe /F /T /IM ($name + '.exe') 2>$null | Out-Null
    }
}

function Get-RelatedProcesses {
    $namePattern = 'ClickToDo|AIXHost|WorkloadsSessionHost|WorkloadsSessionManager'
    $textPattern = 'Click to Do|수행하려면 클릭|WorkloadsSessionHost|WorkloadsSessionManager'

    Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -match $namePattern -or
        $_.Description -match $textPattern -or
        $_.MainWindowTitle -match $textPattern
    }
}

function Invoke-CtdCleanup {
    Write-WatchdogLog 'cleanup start'

    sc.exe config WSAIFabricSvc start= disabled | Out-Null
    sc.exe stop WSAIFabricSvc | Out-Null

    Stop-TargetsByTaskKill
    Start-Sleep -Seconds 2
    Stop-TargetsByTaskKill

    Get-RelatedProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $FlagFile -Force -ErrorAction SilentlyContinue

    $remaining = Get-RelatedProcesses | Select-Object -ExpandProperty ProcessName -ErrorAction SilentlyContinue
    if ($remaining) {
        Write-WatchdogLog ('cleanup done; remaining: {0}' -f (($remaining | Sort-Object -Unique) -join ', '))
    }
    else {
        Write-WatchdogLog 'cleanup done; no related process left'
    }
}

Write-WatchdogLog ('watchdog start; delay={0}s' -f $DelaySeconds)

while ($true) {
    try {
        if (Test-Path -LiteralPath $FlagFile) {
            $flagAge = ((Get-Date) - (Get-Item -LiteralPath $FlagFile).LastWriteTime).TotalSeconds
            if ($flagAge -ge $DelaySeconds) {
                Invoke-CtdCleanup
            }
        }
    }
    catch {
        Write-WatchdogLog ("loop error: {0}" -f $_.Exception.Message)
    }

    Start-Sleep -Seconds 3
}
