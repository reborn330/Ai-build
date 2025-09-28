#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
Opt("TrayIconHide", 1)

; === Prevent Sleep, Display Timeout, and Idle ===
Global Const $ES_CONTINUOUS = 0x80000000
Global Const $ES_SYSTEM_REQUIRED = 0x00000001
Global Const $ES_DISPLAY_REQUIRED = 0x00000002

DllCall("kernel32.dll", "int", "SetThreadExecutionState", "int", _
    BitOR($ES_CONTINUOUS, $ES_SYSTEM_REQUIRED, $ES_DISPLAY_REQUIRED))

; === Define Critical Services to Monitor ===
Global $aServices[5] = ["Spooler", "wuauserv", "WinDefend", "BITS", "EventLog"]

; === Define Critical Processes to Keep Alive ===
Global $aProcesses[3] = ["explorer.exe", "svchost.exe", "services.exe"]

; === Log File for Audit Trail ===
Global $sLog = @ScriptDir & "\system_guard.log"
FileWrite($sLog, @CRLF & "=== System Guard Started: " & @YEAR & "/" & @MON & "/" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & " ===" & @CRLF)

While 1
    ; === Heartbeat Log ===
    FileWrite($sLog, @HOUR & ":" & @MIN & ":" & @SEC & " - System awake" & @CRLF)

    ; === Service Watchdog ===
    For $i = 0 To UBound($aServices) - 1
        Local $sStatus = RunWait(@ComSpec & " /c sc query " & $aServices[$i] & " | findstr /C:""RUNNING""", "", @SW_HIDE)
        If $sStatus <> 0 Then
            FileWrite($sLog, "Restarting service: " & $aServices[$i] & @CRLF)
            RunWait(@ComSpec & " /c net start " & $aServices[$i], "", @SW_HIDE)
        EndIf
    Next

    ; === Process Watchdog ===
    For $j = 0 To UBound($aProcesses) - 1
        If ProcessExists($aProcesses[$j]) = 0 Then
            FileWrite($sLog, "Critical process missing: " & $aProcesses[$j] & @CRLF)
            ; Optional: Trigger alert or restart logic here
        EndIf
    Next

    Sleep(180000) ; Check every 3 minutes
WEnd