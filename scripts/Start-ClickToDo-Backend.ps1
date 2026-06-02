$ErrorActionPreference = 'SilentlyContinue'

$BaseDir = Join-Path $env:LOCALAPPDATA 'ArtemisClickToDo'
$LogFile = Join-Path $BaseDir 'start.log'

New-Item -ItemType Directory -Path $BaseDir -Force | Out-Null

function Write-StartLog {
    param([string]$Message)
    Add-Content -Path $LogFile -Value ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message)
}

try {
    Write-StartLog 'backend start'
    sc.exe config WSAIFabricSvc start= demand | Out-Null
    sc.exe start WSAIFabricSvc | Out-Null
    Start-Sleep -Seconds 2
    Write-StartLog 'backend ready'
}
catch {
    Write-StartLog ("backend error: {0}" -f $_.Exception.Message)
}
