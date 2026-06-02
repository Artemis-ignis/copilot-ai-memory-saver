# Copilot AI Memory Saver

> Win+Q는 살리고, Copilot AI 메모리 상주는 끊습니다.

[![플랫폼](https://img.shields.io/badge/platform-Windows%2011%20Copilot%2B-0A84FF)](#요구-사항)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE)](#설치)
[![AutoHotkey](https://img.shields.io/badge/AutoHotkey-v2-334455)](#설치)
[![라이선스: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Copilot AI Memory Saver는 Windows 11에서 `Win + Q / Click to Do / 수행하려면 클릭`은 그대로 유지하면서, `WSAIFabricSvc`, `WorkloadsSessionHost`, `AIXHost` 같은 Copilot+ 관련 백엔드가 평소에 메모리에 상주하지 않도록 만드는 유틸리티입니다.

이 저장소는 `WindowsWorkload.*` 패키지를 삭제하지 않고, `System32`나 `WindowsApps`를 수정하지 않으며, Windows Search를 끄지 않습니다. 목표는 기능 삭제가 아니라 **온디맨드 실행**입니다.

## 한눈에 보기

- `Win + Q`는 그대로 유지
- Click to Do를 열 때만 Windows AI Fabric 잠깐 시작
- 유휴 시간이 지나면 `ClickToDo.exe`, `AIXHost.exe`, `WorkloadsSessionHost.exe`, `WorkloadsSessionManager.exe` 정리
- 정리 후 `WSAIFabricSvc`를 다시 `Stopped / Disabled` 상태로 복귀
- 설치, 일시 중지, 재개, 완전 삭제 경로를 모두 문서화

## 스크린샷

![정리 전 작업 관리자](docs/screenshots/before-task-manager.png)
![정리 후 작업 관리자](docs/screenshots/after-task-manager.png)

## 빠른 설치

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\install.ps1
```

이 두 줄이 기본 설치 경로입니다. 이 폴더에서 **관리자 권한 Windows PowerShell**로 실행하면 됩니다.

## 전 / 사용 중 / 후

| 상태 | 대상 프로세스 수 | 대상 메모리 | WSAIFabricSvc | 작업 관리자 체감 |
| --- | ---: | ---: | --- | --- |
| 정리 전 | 6 | 최대 5,789.2 MB | Running | 메모리 약 44% |
| Win+Q 사용 중 | 6 | 일시적으로 증가 | 온디맨드 실행 | 일시적 증가 |
| Watchdog 정리 후 | 0-1 잔여 핸들 | 94 MB | Stopped / Disabled | 메모리 약 26% |

실측 회수 메모리: `5,695.2 MB`  
대상 프로세스 기준 감소율: `98.4%`  
32 GB 전체 RAM 기준 대략: `17.4%`

참고로, 비정상 상주 사례에서는 `WorkloadsSessionHost` 10개가 약 `7.9 GB`를 점유한 경우도 있었습니다. 이는 32 GB 기준 약 `24%`입니다. 다만 이 저장소는 모든 장치에서 같은 절감량을 보장하지 않으며, 어디까지나 실측 사례를 기반으로 설명합니다.

## 이런 검색어로 들어오셨다면

`WorkloadsSessionHost high memory`, `WSAIFabricSvc using RAM`, `Windows AI Fabric disable`, `Copilot AI memory usage`, `Copilot+ PC memory bloat`, `disable Copilot but keep Win+Q`, `Click to Do memory usage` 같은 검색으로 들어오셨다면 이 프로젝트가 맞습니다.

## 요구 사항

- `Click to Do`가 이미 존재하는 Windows 11 환경
- Copilot+ / Windows AI workload 관련 구성 요소가 이미 설치된 상태
- Windows PowerShell 5.1 이상
- 설치/삭제 시 관리자 권한 PowerShell
- AutoHotkey v2
  - 없으면 `install.ps1`가 `winget`으로 설치를 시도합니다

## 설치되는 항목

`install.ps1`는 아래를 구성합니다.

- `%LOCALAPPDATA%\ArtemisClickToDo\Start-ClickToDo-Backend.ps1`
- `%LOCALAPPDATA%\ArtemisClickToDo\Watchdog-ClickToDo-Cleanup.ps1`
- `%LOCALAPPDATA%\ArtemisClickToDo\WinQ-ClickToDo-OnDemand.ahk`
- `%LOCALAPPDATA%\ArtemisClickToDo\AutoHotkey.exe`
- 예약 작업 `Artemis_CTD_Start`
- 예약 작업 `Artemis_CTD_Watchdog`
- 시작프로그램 바로가기 `Artemis WinQ ClickToDo.lnk`

## 설치

이 저장소 폴더에서 **Windows PowerShell 관리자 권한**으로 아래를 실행하세요.

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\install.ps1
```

설치 스크립트가 하는 일:

1. 관리자 권한을 확인합니다.
2. AutoHotkey v2를 확인하고, 없으면 `winget`으로 설치를 시도합니다.
3. 런타임 파일을 `%LOCALAPPDATA%\ArtemisClickToDo`로 복사합니다.
4. 예전 `Artemis_CTD_Start`, `Artemis_CTD_Cleanup`, `Artemis_CTD_Watchdog` 작업이 있으면 제거합니다.
5. 현재 떠 있는 Click to Do 관련 프로세스를 먼저 정리합니다.
6. `WSAIFabricSvc`를 `Disabled`로 바꾸고 중지합니다.
7. 시작 작업과 Watchdog 예약 작업을 등록합니다.
8. AutoHotkey 시작프로그램 바로가기를 만듭니다.
9. Watchdog와 Win+Q 런처를 즉시 실행합니다.

## 사용 방법

설치 후 흐름은 단순합니다.

1. `Win + Q`를 누릅니다.
2. Click to Do가 평소처럼 열립니다.
3. 사용이 끝나면 Watchdog가 기본 `30초`를 기다립니다.
4. 유휴 시간이 지나면 관련 프로세스를 정리하고 `WSAIFabricSvc`를 다시 꺼둡니다.

전체 흐름 설명: [docs/how-it-works.md](docs/how-it-works.md)

## 삭제 없이 잠깐 멈추기

완전히 지우지 않고 기능만 잠깐 멈추고 싶다면:

```powershell
schtasks.exe /End /TN "Artemis_CTD_Watchdog"
Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match "^AutoHotkey" -and $_.CommandLine -match "WinQ-ClickToDo-OnDemand.ahk"
} | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force
}
```

현재 떠 있는 백엔드 상태까지 바로 정리하려면:

```powershell
Remove-Item "$env:LOCALAPPDATA\ArtemisClickToDo\ctd_open.flag" -ErrorAction SilentlyContinue
taskkill.exe /F /T /IM ClickToDo.exe
taskkill.exe /F /T /IM AIXHost.exe
taskkill.exe /F /T /IM WorkloadsSessionHost.exe
taskkill.exe /F /T /IM WorkloadsSessionManager.exe
sc.exe stop WSAIFabricSvc
sc.exe config WSAIFabricSvc start= disabled
```

## 다시 켜기

재설치 없이 다시 활성화하려면:

```powershell
Start-Process "$env:LOCALAPPDATA\ArtemisClickToDo\AutoHotkey.exe" -ArgumentList "`"$env:LOCALAPPDATA\ArtemisClickToDo\WinQ-ClickToDo-OnDemand.ahk`""
schtasks.exe /Run /TN "Artemis_CTD_Watchdog"
```

## 완전 삭제

시작프로그램, 예약 작업, 런타임 폴더, AutoHotkey 런처를 제거합니다.

```powershell
.\uninstall.ps1
```

Windows AI Fabric을 `Automatic`으로 되돌리고 즉시 시작까지 원하면:

```powershell
.\uninstall.ps1 -RestoreWindowsAI
```

## 정상 동작 확인

서비스와 예약 작업 상태 확인:

```powershell
Get-Service WSAIFabricSvc
Get-ScheduledTask Artemis_CTD_Start,Artemis_CTD_Watchdog
```

로그 확인:

```powershell
Get-Content "$env:LOCALAPPDATA\ArtemisClickToDo\start.log" -Tail 50
Get-Content "$env:LOCALAPPDATA\ArtemisClickToDo\watchdog.log" -Tail 50
```

대상 프로세스 메모리 확인:

```powershell
Get-Process WorkloadsSessionHost,WorkloadsSessionManager,AIXHost,ClickToDo -ErrorAction SilentlyContinue |
Select-Object Id,ProcessName,@{Name="RAM_MB";Expression={[math]::Round($_.WorkingSet64/1MB,1)}} |
Format-Table -Auto
```

## 왜 그냥 Click to Do를 꺼버리지 않나요?

Click to Do 자체는 유용할 수 있기 때문입니다. 문제는 뒤에서 도는 Windows AI workload가 사용이 끝난 뒤에도 메모리에 남아 있는 경우가 있다는 점입니다. 이 저장소는 `Win + Q`는 살리고, 백엔드는 필요할 때만 켜는 쪽을 선택합니다.

## 안전 메모

- `WindowsWorkload.*` 패키지를 삭제하지 않습니다
- `System32`, `WindowsApps` 파일을 수정하지 않습니다
- `WSearch`, `SearchHost.exe`, `SearchIndexer.exe`는 건드리지 않습니다
- `DisableClickToDo` 정책을 기본으로 켜지 않습니다
- 사용자 PC의 다른 AutoHotkey 스크립트를 무차별 종료하지 않습니다
- 이 프로젝트가 설치한 런처와 Click to Do 관련 프로세스만 대상으로 합니다

자세한 설명: [docs/safety.md](docs/safety.md)

## 문제 해결

- `Win + Q`가 열리지 않을 때: [docs/troubleshooting.md#win--q-does-not-open-click-to-do](docs/troubleshooting.md#win--q-does-not-open-click-to-do)
- `WorkloadsSessionHost`가 계속 남아 있을 때: [docs/troubleshooting.md#workloadssessionhost-stays-alive](docs/troubleshooting.md#workloadssessionhost-stays-alive)
- Watchdog가 실행 중이 아닐 때: [docs/troubleshooting.md#watchdog-is-not-running](docs/troubleshooting.md#watchdog-is-not-running)
- AutoHotkey가 실행되지 않을 때: [docs/troubleshooting.md#autohotkey-is-not-running](docs/troubleshooting.md#autohotkey-is-not-running)
- 예약 작업이 `Ready`가 아닐 때: [docs/troubleshooting.md#scheduled-tasks-are-not-ready](docs/troubleshooting.md#scheduled-tasks-are-not-ready)
- `WSAIFabricSvc`가 다시 살아날 때: [docs/troubleshooting.md#wsaifabricsvc-keeps-coming-back](docs/troubleshooting.md#wsaifabricsvc-keeps-coming-back)

## 벤치마크

테스트 환경: `Windows 11 Copilot+ PC`, `32 GB RAM`

| 항목 | 값 |
| --- | ---: |
| Win+Q 사용 중 대상 프로세스 최대 메모리 | 5,789.2 MB |
| 정리 후 메모리 | 94 MB |
| 실측 회수 메모리 | 5,695.2 MB |
| 대상 프로세스 기준 감소율 | 98.4% |
| 32 GB 전체 RAM 대비 추정 절감 | 17.4% |
| 작업 관리자 전체 메모리 표시 | 44% -> 26% |

상세 수치와 재측정 명령: [docs/benchmark.md](docs/benchmark.md)

## 알려진 한계

- Windows 업데이트로 서비스명, 프로세스명, Click to Do 시작 흐름이 바뀔 수 있습니다.
- 회사/학교 관리 PC에서는 서비스 제어, 예약 작업, 시작프로그램 등록이 막힐 수 있습니다.
- 메모리 절감량은 하드웨어, Windows 빌드, `WindowsWorkload` 구성, 비정상 상주 여부에 따라 달라집니다.
- 이 저장소는 Click to Do가 이미 있는 시스템을 전제로 하며, Click to Do 자체를 설치해주지는 않습니다.

## GitHub 저장소 설명 초안

Win+Q / Click to Do는 유지하면서, Windows AI Fabric, WorkloadsSessionHost, AIXHost, Copilot+ 관련 프로세스가 유휴 시 메모리에 상주하지 않게 만드는 Windows 11 유틸리티.

## 추천 GitHub Topics

`windows-11`, `copilot`, `copilot-ai`, `copilot-plus`, `windows-ai`, `windows-ai-fabric`, `click-to-do`, `workloadssessionhost`, `wsaifabricsvc`, `memory-saver`, `debloat`, `powershell`, `autohotkey`

## 릴리즈 노트 초안

- `Win + Q`를 유지하는 AutoHotkey v2 런처 추가
- `WSAIFabricSvc` 온디맨드 시작 흐름 추가
- `ClickToDo.exe`, `AIXHost.exe`, `WorkloadsSessionHost.exe`, `WorkloadsSessionManager.exe` Watchdog 정리 흐름 추가
- 완전 삭제와 Windows AI 복원 경로 추가
- 한영 문서, 문제 해결, 안전 메모, 벤치마크 문서 추가
