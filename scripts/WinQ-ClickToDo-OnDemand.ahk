#Requires AutoHotkey v2.0
#SingleInstance Force

global BaseDir := EnvGet("LOCALAPPDATA") "\ArtemisClickToDo"
global FlagFile := BaseDir "\ctd_open.flag"
global LogFile := BaseDir "\ahk.log"
global IsForwarding := false

WriteLog(message) {
    global BaseDir, LogFile
    try {
        DirCreate(BaseDir)
        FileAppend("[" A_Now "] " message "`n", LogFile, "UTF-8")
    }
}

ForwardWinQ() {
    global IsForwarding
    if (IsForwarding) {
        return
    }

    IsForwarding := true
    try {
        Hotkey "#q", "Off"
        Send "#q"
        Sleep 300
    } catch as err {
        WriteLog("forward error: " err.Message)
    } finally {
        Hotkey "#q", "On"
        IsForwarding := false
    }
}

#q:: {
    global BaseDir, FlagFile

    try {
        DirCreate(BaseDir)
        try FileDelete(FlagFile)
        FileAppend(A_Now, FlagFile, "UTF-8")
        Run('schtasks.exe /Run /TN "Artemis_CTD_Start"', , "Hide")
        KeyWait "LWin"
        KeyWait "RWin"
        Sleep 800
    } catch as err {
        WriteLog("launcher error: " err.Message)
    }

    ForwardWinQ()
}
