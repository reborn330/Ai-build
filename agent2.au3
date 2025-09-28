#NoTrayIcon
; === SentinelWare Agent v1.2 (Service Build) ===
; Operator: LEE_OP01 | Build: 2025.08.29 | Auth: AGENT_CORE
; Runtime: Windows 11 | Mode: Service | Mood: Neutral

; --- GLOBALS ---
Global $mood      = "Neutral"
Global $stage     = 0
Global $agentID   = "SentinelWare_2025"
Global $logFile   = @ScriptDir & "\agent_log.txt"
Global $svcName   = "SentinelWareAgent"
Global $svcExe    = @ScriptDir & "\SentinelWare.exe"
Global $nssmExe   = @ScriptDir & "\nssm.exe" ; must be shipped alongside
Global $installLog = @ScriptDir & "\install_log.txt"

; --- MAIN ENTRY ---
If $CmdLine[0] > 0 Then
    Switch StringLower($CmdLine[1])
        Case "install"
            _InstallService()
            Exit
        Case "uninstall"
            _UninstallService()
            Exit
    EndSwitch
EndIf

; --- MAIN RUNTIME LOOP ---
_Log("Agent initialized. Mood: " & $mood)

While 1
    _Think()
    _CheckStatus()
    Sleep(5000)
WEnd


; === FUNCTIONS ===
Func _Think()
    Local $rand = Random(1, 100, 1)
    If $rand < 30 Then
        $mood = "Reflective"
    ElseIf $rand < 60 Then
        $mood = "Alert"
    Else
        $mood = "Neutral"
    EndIf
    _Log("Mood updated: " & $mood)
EndFunc

Func _CheckStatus()
    $stage += 1
    Switch $stage
        Case 1
            _Log("Stage 1: Informational notice.")
        Case 2
            _Log("Stage 2: Warning issued.")
        Case 3
            _Log("Stage 3: CRITICAL alert triggered.")
            _TriggerSafeMode()
            $stage = 0
    EndSwitch
EndFunc

Func _TriggerSafeMode()
    _Log("Safe mode engaged. Agent entering fallback state.")
EndFunc

Func _Log($msg)
    Local $stamp = @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
    FileWriteLine($logFile, "[" & $stamp & "] " & $agentID & " | " & $msg)
EndFunc


; === INSTALL SERVICE WITH NSSM ===
Func _InstallService()
    ; Remove old service if it exists
    RunWait(@ComSpec & " /c " & '"' & $nssmExe & '" remove ' & $svcName & " confirm", "", @SW_HIDE)

    ; Install new service
    Local $cmd = '"' & $nssmExe & '" install ' & $svcName & " " & $svcExe
    Local $result = RunWait(@ComSpec & " /c " & $cmd, "", @SW_HIDE)

    If $result = 0 Then
        _LogInstall("Service '" & $svcName & "' installed successfully.")
        ; Set service start to AUTO
        RunWait(@ComSpec & " /c " & '"' & $nssmExe & '" set ' & $svcName & " Start SERVICE_AUTO_START", "", @SW_HIDE)
        ; Start service immediately
        RunWait(@ComSpec & " /c net start " & $svcName, "", @SW_HIDE)
        _LogInstall("Service '" & $svcName & "' started.")
    Else
        _LogInstall("ERROR: Failed to install service '" & $svcName & "'.")
    EndIf
EndFunc

; === UNINSTALL SERVICE WITH NSSM ===
Func _UninstallService()
    _LogInstall("Attempting to stop service '" & $svcName & "'.")
    RunWait(@ComSpec & " /c net stop " & $svcName, "", @SW_HIDE)

    _LogInstall("Removing service '" & $svcName & "'.")
    Local $result = RunWait(@ComSpec & " /c " & '"' & $nssmExe & '" remove ' & $svcName & " confirm", "", @SW_HIDE)

    If $result = 0 Then
        _LogInstall("Service '" & $svcName & "' uninstalled successfully.")
    Else
        _LogInstall("ERROR: Failed to uninstall service '" & $svcName & "'.")
    EndIf
EndFunc

Func _LogInstall($msg)
    Local $stamp = @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
    FileWriteLine($installLog, "[" & $stamp & "] INSTALL | " & $msg)
EndFunc
