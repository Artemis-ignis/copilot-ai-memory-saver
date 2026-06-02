# Benchmark

The numbers below come from a measured run on a `32 GB RAM Windows 11 Copilot+ PC`.

## Measured Result

| Metric | Value |
| --- | ---: |
| Peak target-process memory during Win+Q usage | 5,789.2 MB |
| Target-process memory after watchdog cleanup | 94 MB |
| Reclaimed memory | 5,695.2 MB |
| Reduction vs target processes | 98.4% |
| Approximate reduction vs full 32 GB RAM | 17.4% |
| Task Manager overall memory view | 44% -> 26% |

## Outlier Reference

One abnormal idle case showed about `7.9 GB` held by `10` `WorkloadsSessionHost` processes. On a 32 GB machine, that is roughly `24%` of total RAM. Treat that as a real-world example, not a guarantee.

## Repeatable Measurement Snippet

Use this PowerShell snippet before and after running `Win + Q` and before/after watchdog cleanup.

```powershell
$TargetNames = 'ClickToDo','AIXHost','WorkloadsSessionHost','WorkloadsSessionManager'

$Processes = Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $TargetNames -contains $_.ProcessName
}

$TotalBytes = ($Processes | Measure-Object -Property WorkingSet64 -Sum).Sum
$TotalMegabytes = [Math]::Round(($TotalBytes / 1MB), 1)

[pscustomobject]@{
    Timestamp        = Get-Date
    ProcessCount     = @($Processes).Count
    TotalWorkingSetMB = $TotalMegabytes
    ProcessNames     = ($Processes.ProcessName -join ', ')
}
```

## Screenshot Guidance

Place before/after Task Manager screenshots and optional GIF captures in `docs/screenshots/` so the README can show real visual evidence.
