# Security Policy

## Supported Versions

This repository is a small Windows utility, not a long-lived packaged product with multiple maintained release branches.

Security fixes, trust clarifications, and documentation updates are applied to the current `main` branch.

## What This Project Changes

This project intentionally changes only user-local runtime state needed to make Click to Do run on demand:

- registers scheduled tasks under the current user
- creates a startup shortcut for the local AutoHotkey launcher
- copies runtime scripts into `%LOCALAPPDATA%\ArtemisClickToDo`
- starts, stops, and changes the startup mode of `WSAIFabricSvc`
- terminates the documented Click to Do process chain after idle timeout

## What This Project Does Not Do

- It does not remove `WindowsWorkload.*` packages.
- It does not patch `System32`, `WindowsApps`, or other system binaries.
- It does not disable `WSearch`, `SearchHost.exe`, or `SearchIndexer.exe`.
- It does not enable `DisableClickToDo` policy by default.
- It does not collect telemetry or send usage data.
- It does not bundle secrets, tokens, or credentials in the repository.

## Trust Notes

- `install.ps1` and `uninstall.ps1` require Administrator PowerShell because they control a Windows service and scheduled tasks.
- `install.ps1` may call `winget` to install AutoHotkey v2 if it is missing.
- Windows updates may change the names or behavior of Click to Do related components.
- Managed work or school devices may block service control, startup registration, or scheduled-task changes.

## Reporting a Security Concern

If you find a security issue, unexpected destructive behavior, or a privilege boundary problem:

1. Do not post secrets, tokens, or private machine details in a public issue.
2. Open a GitHub issue with a minimal reproduction if the report is safe to disclose publicly.
3. If the issue contains sensitive local details, first redact:
   - usernames
   - machine names
   - paths that reveal personal information
   - organization-specific policy details
4. Include:
   - Windows version and build
   - whether the machine is personal or managed
   - exact command used
   - expected behavior
   - actual behavior
   - relevant log excerpts from `%LOCALAPPDATA%\ArtemisClickToDo\start.log` and `watchdog.log`

## Safe Review Checklist

Before running the scripts yourself, review:

- [README.md](README.md)
- [README.ko.md](README.ko.md)
- [docs/safety.md](docs/safety.md)
- [install.ps1](install.ps1)
- [uninstall.ps1](uninstall.ps1)
- [scripts/Watchdog-ClickToDo-Cleanup.ps1](scripts/Watchdog-ClickToDo-Cleanup.ps1)
