; AgentCoreDefenderService.au3
; Emulates a service-like agent with logging and safe mode fallback (no tray icon)

#include <Date.au3>
#include <FileConstants.au3>

Global Const $ServiceName = "AgentCoreDefenderService"
Global Const $LogPath = @ScriptDir & "\logs\" & $ServiceName & "_log.txt"
Global Const $SafeModeFlag = @ScriptDir & "\config\safe_mode.flag"
Global $Running = True

; Create necessary directories
If Not FileExists(@ScriptDir & "\logs") Then DirCreate(@ScriptDir & "\logs")
If Not FileExists(@ScriptDir & "\config") Then DirCreate(@ScriptDir & "\config")

; Write initial log
_Log("[" & _NowTime() & "] " & $ServiceName & " started.")

; Main service loop
While $Running
    ; Check for safe mode trigger
    If FileExists($SafeModeFlag) Then
        _Log("[" & _NowTime() & "] Safe mode flag detected.")
        ; Add any safe mode actions here
        FileDelete($SafeModeFlag)
    EndIf

    ; Example heartbeat log (optional)
    ; _Log("[" & _NowTime() & "] Service heartbeat.")

    Sleep(1000) ; simulate service heartbeat
WEnd

_Log("[" & _NowTime() & "] " & $ServiceName & " stopped.")
Exit

; ===============================
; Logging function
Func _Log($msg)
    FileWriteLine($LogPath, $msg)
EndFunc
