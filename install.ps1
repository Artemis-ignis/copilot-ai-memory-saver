[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Set-StrictMode -Version 2.0

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptSourceDir = Join-Path $ProjectRoot 'scripts'
$BaseDir = Join-Path $env:LOCALAPPDATA 'ArtemisClickToDo'
$StartPs1 = Join-Path $BaseDir 'Start-ClickToDo-Backend.ps1'
$WatchdogPs1 = Join-Path $BaseDir 'Watchdog-ClickToDo-Cleanup.ps1'
$HotkeyAhk = Join-Path $BaseDir 'WinQ-ClickToDo-OnDemand.ahk'
$FlagFile = Join-Path $BaseDir 'ctd_open.flag'
$StartupLnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'Artemis WinQ ClickToDo.lnk'
$LocalAhkExe = Join-Path $BaseDir 'AutoHotkey.exe'

$TaskStart = 'Artemis_CTD_Start'
$TaskCleanup = 'Artemis_CTD_Cleanup'
$TaskWatchdog = 'Artemis_CTD_Watchdog'
$KillTargets = @(
    'ClickToDo.exe',
    'AIXHost.exe',
    'WorkloadsSessionHost.exe',
    'WorkloadsSessionManager.exe'
)

function Write-Step {
    param([string]$Message)
    Write-Host "`n[$Message]"
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Find-AutoHotkeyV2 {
    $candidates = @(
        (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey64.exe'),
        (Join-Path $env:ProgramFiles 'AutoHotkey\AutoHotkey64.exe'),
        (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey.exe'),
        (Join-Path $env:ProgramFiles 'AutoHotkey\AutoHotkey.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'AutoHotkey\v2\AutoHotkey64.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'AutoHotkey\AutoHotkey64.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'AutoHotkey\v2\AutoHotkey.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'AutoHotkey\AutoHotkey.exe')
    ) | Where-Object { $_ }

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    $command = Get-Command AutoHotkey64.exe, AutoHotkey.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) {
        return $command.Source
    }

    return $null
}

function Install-AutoHotkeyIfMissing {
    $path = Find-AutoHotkeyV2
    if ($path) {
        return $path
    }

    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        throw 'AutoHotkey v2가 설치되어 있지 않고 winget.exe도 찾을 수 없습니다. AutoHotkey v2를 먼저 설치한 뒤 다시 실행하세요.'
    }

    Write-Host 'AutoHotkey v2가 없어 winget으로 설치를 시도합니다...'
    & winget.exe install --id AutoHotkey.AutoHotkey -e --accept-source-agreements --accept-package-agreements

    $path = Find-AutoHotkeyV2
    if (-not $path) {
        throw 'AutoHotkey v2 설치 확인에 실패했습니다. 설치 후 다시 실행하세요.'
    }

    return $path
}

function Stop-ArtemisAutoHotkey {
    $scriptNeedle = 'WinQ-ClickToDo-OnDemand.ahk'
    $baseNeedle = [Regex]::Escape($BaseDir)

    $processes = Get-CimInstance Win32_Process -Filter "Name = 'AutoHotkey.exe' OR Name = 'AutoHotkey64.exe' OR Name = 'AutoHotkeyUX.exe'" -ErrorAction SilentlyContinue
    foreach ($process in @($processes)) {
        $commandLine = [string]$process.CommandLine
        if ($commandLine -match [Regex]::Escape($scriptNeedle) -or $commandLine -match $baseNeedle) {
            Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
        }
    }
}

function Remove-ArtemisScheduledTask {
    param([string]$TaskName)

    schtasks.exe /End /TN $TaskName 2>$null | Out-Null
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
}

function Stop-TargetProcesses {
    foreach ($target in $KillTargets) {
        taskkill.exe /F /T /IM $target 2>$null | Out-Null
    }
}

function Copy-ProjectFiles {
    New-Item -ItemType Directory -Path $BaseDir -Force | Out-Null

    $requiredFiles = @(
        'Start-ClickToDo-Backend.ps1',
        'Watchdog-ClickToDo-Cleanup.ps1',
        'WinQ-ClickToDo-OnDemand.ahk'
    )

    foreach ($fileName in $requiredFiles) {
        $sourcePath = Join-Path $ScriptSourceDir $fileName
        if (-not (Test-Path $sourcePath)) {
            throw "필수 파일을 찾을 수 없습니다: $sourcePath"
        }

        Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $BaseDir $fileName) -Force
    }
}

function Register-ArtemisTasks {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Highest

    $startAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$StartPs1`""
    $watchdogAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$WatchdogPs1`""

    $startSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 3)
    $watchdogSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero)
    $watchdogTrigger = New-ScheduledTaskTrigger -AtLogOn

    Register-ScheduledTask -TaskName $TaskStart -Action $startAction -Principal $principal -Settings $startSettings -Description 'Click to Do backend start' -Force | Out-Null
    Register-ScheduledTask -TaskName $TaskWatchdog -Action $watchdogAction -Trigger $watchdogTrigger -Principal $principal -Settings $watchdogSettings -Description 'Click to Do watchdog cleanup' -Force | Out-Null
}

function New-ArtemisStartupShortcut {
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($StartupLnk)
    $shortcut.TargetPath = $LocalAhkExe
    $shortcut.Arguments = "`"$HotkeyAhk`""
    $shortcut.WorkingDirectory = $BaseDir
    $shortcut.IconLocation = "$LocalAhkExe,0"
    $shortcut.Save()
}

function Show-FinalStatus {
    Write-Step '최종 상태 확인'

    Start-Sleep -Seconds 2

    Get-Service WSAIFabricSvc -ErrorAction SilentlyContinue | Format-List Name, Status, StartType

    Get-ScheduledTask $TaskStart, $TaskWatchdog -ErrorAction SilentlyContinue |
        Select-Object TaskName, State |
        Format-Table -AutoSize

    Get-Process AutoHotkey, AutoHotkey64, AutoHotkeyUX -ErrorAction SilentlyContinue |
        Select-Object Id, ProcessName, Path |
        Format-Table -AutoSize

    Get-Process WorkloadsSessionHost, WorkloadsSessionManager, ClickToDo, AIXHost -ErrorAction SilentlyContinue |
        Select-Object Id, ProcessName, @{Name = 'RAM_MB'; Expression = { [Math]::Round($_.WorkingSet64 / 1MB, 1) }} |
        Format-Table -AutoSize
}

if (-not (Test-IsAdministrator)) {
    throw '관리자 권한 PowerShell 5.1 창에서 install.ps1을 실행해야 합니다.'
}

if ($PSVersionTable.PSVersion.Major -lt 5) {
    throw 'Windows PowerShell 5.1 이상이 필요합니다.'
}

Write-Step 'AutoHotkey v2 확인'
$ahkSource = Install-AutoHotkeyIfMissing

Write-Step '기존 예약 작업 제거'
Remove-ArtemisScheduledTask -TaskName $TaskStart
Remove-ArtemisScheduledTask -TaskName $TaskCleanup
Remove-ArtemisScheduledTask -TaskName $TaskWatchdog

Write-Step '기존 Artemis AutoHotkey 종료'
Stop-ArtemisAutoHotkey

Write-Step '로컬 런타임 파일 배치'
Copy-ProjectFiles
Copy-Item -LiteralPath $ahkSource -Destination $LocalAhkExe -Force

Write-Step '현재 떠 있는 Click to Do / Workloads 정리'
sc.exe config WSAIFabricSvc start= disabled | Out-Null
sc.exe stop WSAIFabricSvc | Out-Null
Stop-TargetProcesses
Start-Sleep -Seconds 2
Stop-TargetProcesses
Remove-Item -LiteralPath $FlagFile -Force -ErrorAction SilentlyContinue

Write-Step '예약 작업 등록'
Register-ArtemisTasks

Write-Step '시작프로그램 바로가기 생성'
New-ArtemisStartupShortcut

Write-Step 'Watchdog와 AutoHotkey 즉시 실행'
Start-Process -FilePath $LocalAhkExe -ArgumentList "`"$HotkeyAhk`"" -WorkingDirectory $BaseDir -WindowStyle Hidden
schtasks.exe /Run /TN $TaskWatchdog | Out-Null

Show-FinalStatus

Write-Host "`n설치가 끝났습니다. 이제 Win+Q 사용 후 기본 30초가 지나면 Watchdog가 자동 정리합니다."
