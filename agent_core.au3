#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Compression=3
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; === Agent Runner with Watchdog ===
; Starts agent_core.exe and agent2.exe from K:\AI build\
; Restarts them automatically if they stop
; *** Start added by AutoIt3Wrapper ***
#include <FileConstants.au3>
; *** End added by AutoIt3Wrapper ***
; ================================================================
; agent_core.au3 - Updated
; Reads hidden.ini in K:\AI build and launches all listed executables
; ================================================================

Global $g_sBase = "K:\AI build\"
Global $g_sIni  = $g_sBase & "hidden.ini"

; Exit if hidden.ini does not exist
If Not FileExists($g_sIni) Then Exit

; Read [Executables] section
Global $aIni = IniReadSection($g_sIni, "Executables")
If @error Then Exit

; Loop through and run each executable in order
For $i = 1 To $aIni[0][0]
    Local $exe = $g_sBase & $aIni[$i][1]
    If FileExists($exe) Then
        Run($exe, $g_sBase)
    EndIf
Next


; =========================
; Auth module (Lee Chamberland)
; =========================
#SingleInstance force
Opt("TrayAutoPause", 0)
Opt("TrayMenuMode", 3)
Opt("MustDeclareVars", 1)
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ProgressConstants.au3>
#include <WinAPI.au3>
#include <Misc.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <TrayConstants.au3>
#include <MsgBoxConstants.au3>
#include <Array.au3>
#include <Date.au3>
; Base path
Global $basePath  = "K:\AI build\"
Global $agentCore = $basePath & "agent_core.exe"
Global $agentTwo  = $basePath & "agent2.exe"
Global $network   = $basePath & "network.exe"
Global $safe_mode = $basePath & "safe_mode.exe"
Global $reflector = $basePath & "reflector.exe"
Global $emulaterservices = $basePath & "emulaterservices.exe"
Global $programservices = $basePath & "programservices.exe"
Global $agentcoresystemwide = $basePath & "agentcoresystemwide.exe"
; Process IDs
Global $pidCore = 0
Global $pidTwo  = 0
; AgentDefender.service.au3
; Simulated agent service with tray icon, runtime control, and safe mode fallback
; --- GLOBALS ---
Global $mood      = "Neutral"
Global $stage     = 0
Global $agentID   = "SentinelWare_2025"
Global $logFile   = @ScriptDir & "\agent_log.txt"
Global $svcName   = "SentinelWareAgent"
Global $svcExe    = @ScriptDir & "\SentinelWare.exe"
Global $nssmExe   = @ScriptDir & "\nssm.exe" ; must be shipped alongside
Global $installLog = @ScriptDir & "\install_log.txt"
; build_agent.au3
Local $source = @ScriptDir & "\agent_core.au3"
Local $output = @ScriptDir & "\agent_core.exe"
RunWait(@ComSpec & ' /c Aut2Exe.exe /in "' & $source & '" /out "' & $output & '"', "", @SW_HIDE)
Global $MON_LOGFILE = @ScriptDir & "\agent_monitor.log"
; agent_core.au3
Func AgentMain($param)
    ; Your agent logic here
    Return "Processed: " & $param
EndFunc
; Call after Auth_Ensure() succeeds
Func Monitor_Init()

EndFunc
; build_agent.au3
Local $src = @ScriptDir & "\agent_core.au3"
Local $out = @ScriptDir & "\agent_core.exe"
Local $aut2exe = "C:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2Exe.exe"
Global Const $cfgPath = @ScriptDir & "\config\safe_mode.cfg"
Global Const $logPath = @ScriptDir & "\logs\audit.log"
Global $failCount = IniRead("config\boot_state.ini", "boot", "fail_count", "0")
Global $cfg = ($failCount >= 3) ? "config\safe_mode.cfg" : "config\agent_config.ini"
StartProcess($agentCore, "agent_core")
StartProcess($agentTwo,  "agent2")
If FileExists($aut2exe) Then
    RunWait(@ComSpec & ' /c "' & $aut2exe & '" /in "' & $src & '" /out "' & $out & '"', "", @SW_HIDE)
Else
    MsgBox(16, "Error", "Aut2Exe not found.")
EndIf
; Capture snapshot: CPU %, GPU %, Net in/out KB/s
Func Monitor_Snapshot()
    Local $cpu = _Monitor_CPU()
    Local $gpu = _Monitor_GPU()
    Local $net = _Monitor_Net()

    Local $line = _NowCalc() & " | CPU: " & $cpu & "% | GPU: " & $gpu & "% | NET: " & _
                  Round($net[0], 1) & " KB/s in / " & Round($net[1], 1) & " KB/s out"
Local $timestamp = @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN
Local $out = @ScriptDir & "\agent_core_" & $timestamp & ".exe"
    _Monitor_Log($line)
    Return $line
EndFunc
Func _GenerateSessionID()
    Return @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN & "_" & Random(1000, 9999, 1)
EndFunc
Func _Monitor_Log($msg)
    Local $hFile = FileOpen($MON_LOGFILE, $FO_APPEND)
    If $hFile <> -1 Then

        FileClose($hFile)
    EndIf
    ConsoleWrite($msg & @CRLF)
EndFunc
; ----- CPU via PerfCounter -----
Global $cpuQuery, $cpuCounter

Func _Monitor_CPU()
    If Not IsObj($cpuQuery) Then
        $cpuQuery = ObjCreate("Win32_PerfFormattedData_PerfOS_Processor")
    EndIf
    Local $col = ObjGet("winmgmts:\\.\root\cimv2").ExecQuery("SELECT PercentProcessorTime FROM Win32_PerfFormattedData_PerfOS_Processor WHERE Name='_Total'")
    For $objItem In $col
        Return $objItem.PercentProcessorTime
    Next
    Return 0
EndFunc

; ----- GPU via WMI -----
Func _Monitor_GPU()
    Local $gpuLoad = 0
    Local $svc = ObjGet("winmgmts:\\.\root\cimv2")
    If IsObj($svc) Then
        Local $items = $svc.ExecQuery("SELECT * FROM Win32_PerfFormattedData_GPUPerformanceCounters_GPUEngine")
        Local $count = 0
        For $objItem In $items
            If StringInStr($objItem.Name, "engtype_3D") Then
                $gpuLoad += $objItem.UtilizationPercentage
                $count += 1
            EndIf
        Next
        If $count > 0 Then $gpuLoad = Round($gpuLoad / $count, 1)
    EndIf
    Return $gpuLoad
EndFunc

; ----- Network via PerfCounter -----
Global $netPrevIn = -1, $netPrevOut = -1, $netPrevTime

Func _Monitor_Net()
    Local $colNIC = ObjGet("winmgmts:\\.\root\cimv2").ExecQuery("SELECT Name, BytesReceivedPerSec, BytesSentPerSec FROM Win32_PerfFormattedData_Tcpip_NetworkInterface")
    Local $totalIn = 0, $totalOut = 0
    For $objItem In $colNIC
        $totalIn += $objItem.BytesReceivedPerSec
        $totalOut += $objItem.BytesSentPerSec
    Next
    ; Convert to KB/s

EndFunc

; =========================
; Metadata and config
; =========================
Global Const $AGENT_NAME     = "Sentinel-Leaf"
Global Const $AUTHOR         = "Lee"
Global Const $REG_PATH       = "HKCU\Software\Lee\Agent"
Global Const $LOG_DIR        = @AppDataDir & "\LeeAgent" ; user-writable path (more reliable than ProgramData)
Global Const $LOG_FILE       = $LOG_DIR & "\diary.log"
Global Const $BASELINE_MOOD  = 50
Global $hGUI = GUICreate("AI3 Overlay", 300, 100, @DesktopWidth - 320,40, $WS_POPUP, $WS_EX_TOPMOST + $WS_EX_TOOLWINDOW)
GUISetBkColor(0x1E1E1E)
GUISetOnEvent($GUI_EVENT_CLOSE, "_KillSwitch")

; =========================
; Runtime state
; =========================
Global $g_bPaused       = False
Global $g_bVoice        = _RegReadBool($REG_PATH, "Voice", True)
Global $g_bLog          = _RegReadBool($REG_PATH, "Logging", True)
Global $g_iMood         = _RegReadInt($REG_PATH, "Mood", $BASELINE_MOOD)
Global $g_oVoice        = 0
Global $g_bIsAdmin      = IsAdmin()
Global $g_bExiting      = False
Global $g_hTimerMood    = TimerInit()
Global $g_hTimerPriv    = TimerInit()
Global $g_bElevatedArg  = _HasArg("/elevated")

; =========================
; Init
; =========================
DirCreate($LOG_DIR)
If $g_bVoice Then
    $g_oVoice = ObjCreate("SAPI.SpVoice")
    If @error Then $g_bVoice = False
EndIf
If $g_bElevatedArg And $g_bIsAdmin Then
    TrayTip($AGENT_NAME, "Now running elevated.", 3, 1)
    _Speak("Elevation granted.")
EndIf

; =========================
; Tray UI
; =========================
TraySetIcon(@SystemDir & "\shell32.dll", _IconIndex())
TraySetToolTip($AGENT_NAME & _StatusSuffix())

Global $miCtrlPanel = TrayCreateItem("Open Control Panel")
TrayCreateItem("")
Global $miStatus    = TrayCreateItem("Status: " & _StatusText())
TrayItemSetState($miStatus, $TRAY_DISABLE)
Global $miPause     = TrayCreateItem("Pause")
Global $miVoice     = TrayCreateItem("Voice: " & _OnOff($g_bVoice))
Global $miLogging   = TrayCreateItem("Logging: " & _OnOff($g_bLog))
Global $miElevate   = TrayCreateItem("Request elevation")
TrayCreateItem("")
Global $miExit      = TrayCreateItem("Exit")
TraySetState(1)
; =========================
; Control Panel GUI
; =========================
Global $hCP = GUICreate($AGENT_NAME & " Control Panel", 360, 280, -1, -1, $WS_CAPTION + $WS_SYSMENU)
GUICtrlCreateGroup("Status", 10, 10, 340, 70)
Global $lblTitle  = GUICtrlCreateLabel($AGENT_NAME & " — by " & $AUTHOR, 20, 28, 320, 18)
Global $lblStatus = GUICtrlCreateLabel(_StatusText(), 20, 48, 320, 18)

GUICtrlCreateGroup("Controls", 10, 90, 340, 120)
Global $btnPause   = GUICtrlCreateButton(IIf($g_bPaused, "Resume", "Pause"),           20, 110, 140, 30)
Global $btnVoice   = GUICtrlCreateButton("Voice: "   & _OnOff($g_bVoice),              180, 110, 140, 30)
Global $btnLog     = GUICtrlCreateButton("Logging: " & _OnOff($g_bLog),                20, 150, 140, 30)
Global $btnElevate = GUICtrlCreateButton("Request elevation",                          180, 150, 140, 30)

GUICtrlCreateGroup("Mood", 10, 215, 340, 50)
Global $lblMood    = GUICtrlCreateLabel("Mood: " & $g_iMood, 20, 235, 320, 18)

GUISetState(@SW_HIDE, $hCP)

; =========================
; Hotkeys
; =========================
HotKeySet("^!o", "_ShowPanel")   ; Ctrl+Alt+O -> open panel
HotKeySet("^!p", "_TogglePause") ; Ctrl+Alt+P
HotKeySet("^!v", "_ToggleVoice") ; Ctrl+Alt+V
HotKeySet("^!l", "_ToggleLog")   ; Ctrl+Alt+L
HotKeySet("^!k", "_KillSwitch")  ; Ctrl+Alt+K

_Log("Agent started. Admin=" & $g_bIsAdmin & ", Voice=" & $g_bVoice & ", Log=" & $g_bLog)
If Not $g_bIsAdmin Then
    _Speak("Running standard. Elevation available.")
EndIf
; Function to start a process safely
Func StartProcess($procPath, $name)
    If FileExists($procPath) Then
        Local $pid = Run($procPath, $basePath, @SW_HIDE)
        ConsoleWrite("[Runner] Started " & $name & " (PID: " & $pid & ")" & @CRLF)
        Return $pid
    Else
        MsgBox(16, "Error", $name & " not found: " & $procPath)
        Return 0
    EndIf
EndFunc
; =========================
; Main loop
; =========================
While Not $g_bExiting
    _PumpTimers()

    ; Tray messages
    Switch TrayGetMsg()
        Case 0
            ; idle
        Case $miCtrlPanel
            _ShowPanel()
        Case $miPause
            _TogglePause()
        Case $miVoice
            _ToggleVoice()
        Case $miLogging
            _ToggleLog()
        Case $miElevate
            _PromptElevation()
        Case $miExit
            _ExitAgent()
    EndSwitch

    ; GUI messages
    Switch GUIGetMsg()
        Case 0
            ; idle
        Case $GUI_EVENT_CLOSE
            GUISetState(@SW_HIDE, $hCP)
        Case $btnPause
            _TogglePause()
        Case $btnVoice
            _ToggleVoice()
        Case $btnLog
            _ToggleLog()
        Case $btnElevate
            _PromptElevation()
    EndSwitch

    Sleep(50)
WEnd

; =========================
; Core functions
; =========================
Func _PumpTimers()
    ; Mood decay every 60s toward baseline
    If TimerDiff($g_hTimerMood) > 60000 Then
        $g_hTimerMood = TimerInit()
        If $g_iMood > $BASELINE_MOOD Then
            $g_iMood -= 1
        ElseIf $g_iMood < $BASELINE_MOOD Then
            $g_iMood += 1
        EndIf
        _SaveMood()
        _RefreshUI()
    EndIf

    ; Privilege poll every 2s (handles external context changes)
    If TimerDiff($g_hTimerPriv) > 2000 Then
        $g_hTimerPriv = TimerInit()
        Local $nowAdmin = IsAdmin()
        If $nowAdmin <> $g_bIsAdmin Then
            $g_bIsAdmin = $nowAdmin
            _Log("Privilege change detected. Admin=" & $g_bIsAdmin)
            If $g_bIsAdmin Then
                TrayTip($AGENT_NAME, "Now elevated.", 3, 1)
                _Speak("Now elevated.")
            Else
                TrayTip($AGENT_NAME, "Standard mode.", 3, 1)
                _Speak("Standard mode.")
            EndIf
            _RefreshUI()
        EndIf
    EndIf
EndFunc
; === CONFIG ===
Global $agentCorePath = @ScriptDir & "\agent_core\agent_core.dll"
Global $installerPackPath = @ScriptDir & "\installer_pack"
Global $runtimePath = @ScriptDir & "\agent_runtime"
Global $logFile = @ScriptDir & "\link_log.txt"

; === VALIDATION ===
If Not FileExists($agentCorePath) Then
    MsgBox(16, "Error", "agent_core.dll not found at: " & $agentCorePath)
    Exit
EndIf

If Not FileExists($installerPackPath & "\bin") Or Not FileExists($installerPackPath & "\config") Then
    MsgBox(16, "Error", "Installer pack missing /bin or /config folders.")
    Exit
EndIf

; === CREATE RUNTIME FOLDER ===
DirCreate($runtimePath & "\bin")
DirCreate($runtimePath & "\config")

; === COPY FILES ===
FileCopy($installerPackPath & "\bin\*", $runtimePath & "\bin\", 1)
FileCopy($installerPackPath & "\config\*", $runtimePath & "\config\", 1)

; === LINKAGE CONTROL FILE ===
Global $linkControlFile = $runtimePath & "\agent_link.info"
FileWrite($linkControlFile, "Linked to: " & $agentCorePath & @CRLF)
FileWrite($linkControlFile, "Timestamp: " & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & @CRLF)

; === LOGGING ===
FileWrite($logFile, "Linked installer pack to agent_core at " & @HOUR & ":" & @MIN & ":" & @SEC & " on " & @YEAR & "/" & @MON & "/" & @MDAY & @CRLF)

; === DONE ===
MsgBox(64, "Success", "Installer pack linked to agent_core successfully.")

Func _PromptElevation()
    If IsAdmin() Then
        _Speak("Already elevated.")
        TrayTip($AGENT_NAME, "Already elevated.", 3, 1)
        Return
    EndIf
    Local $ans = MsgBox($MB_YESNO + $MB_ICONQUESTION, $AGENT_NAME, "Request elevation via UAC prompt?")
    If $ans = $IDYES Then
        If _RequestElevation() Then
            _Log("Elevation requested; handing off.")
            _ExitAgent(True)
        Else
            _Log("Elevation failed or canceled.")
            _Speak("Elevation canceled.")
            TrayTip($AGENT_NAME, "Elevation failed or canceled.", 4, 2)
        EndIf
    EndIf
EndFunc

Func _RequestElevation()
    Local $ret = 0
    If @Compiled Then
        $ret = ShellExecute(@ScriptFullPath, "/elevated", "", "runas")
    Else
        $ret = ShellExecute(@AutoItExe, '"' & @ScriptFullPath & '" /elevated', "", "runas")
    EndIf
    If @error Or $ret = 0 Then Return False
    Return True
EndFunc

Func _TogglePause()
    $g_bPaused = Not $g_bPaused
    _MoodBump(IIf($g_bPaused, -2, 2))
    _Log("Paused=" & $g_bPaused)
    _Speak(IIf($g_bPaused, "Paused.", "Resumed."))
    _RefreshUI()
EndFunc

Func _ToggleVoice()
    $g_bVoice = Not $g_bVoice
    If $g_bVoice And Not IsObj($g_oVoice) Then
        $g_oVoice = ObjCreate("SAPI.SpVoice")
        If @error Then $g_bVoice = False
    EndIf
    _RegWriteBool($REG_PATH, "Voice", $g_bVoice)
    _Log("Voice=" & $g_bVoice)
    _RefreshUI()
    If $g_bVoice Then _Speak("Voice enabled.")
EndFunc

Func _ToggleLog()
    $g_bLog = Not $g_bLog
    _RegWriteBool($REG_PATH, "Logging", $g_bLog)
    _Log("Logging=" & $g_bLog)
    _RefreshUI()
EndFunc

Func _KillSwitch()
    _Warn("Kill switch triggered.")
    _Log("Kill switch triggered.")
    _ExitAgent()
EndFunc

Func _ExitAgent($handoff = False)
    $g_bExiting = True
    _SaveMood()
    If Not $handoff Then _Speak("Exiting.")
    Exit
EndFunc

; =========================
; UI helpers
; =========================
Func _ShowPanel()
    GUISetState(@SW_SHOW, $hCP)
EndFunc

Func _RefreshUI()
    GUICtrlSetData($lblStatus, _StatusText())
    GUICtrlSetData($lblMood, "Mood: " & $g_iMood)
    GUICtrlSetData($btnPause, IIf($g_bPaused, "Resume", "Pause"))
    GUICtrlSetData($btnVoice, "Voice: " & _OnOff($g_bVoice))
    GUICtrlSetData($btnLog, "Logging: " & _OnOff($g_bLog))
    TraySetIcon(@SystemDir & "\shell32.dll", _IconIndex())
    TraySetToolTip($AGENT_NAME & _StatusSuffix())
    TrayItemSetText($miStatus, "Status: " & _StatusText())
    TrayItemSetText($miVoice, "Voice: " & _OnOff($g_bVoice))
    TrayItemSetText($miLogging, "Logging: " & _OnOff($g_bLog))
    TrayItemSetText($miPause, IIf($g_bPaused, "Resume", "Pause"))
EndFunc

; Inline IIf helper (ternary)
Func IIf($fCondition, $vTrue, $vFalse)
    If $fCondition Then
        Return $vTrue
    Else
        Return $vFalse
    EndIf
EndFunc

; =========================
; Utilities
; =========================
Func _Speak($text)
    If $g_bVoice And IsObj($g_oVoice) Then
        $g_oVoice.Speak($AGENT_NAME & " says: " & $text)
    EndIf
EndFunc

Func _Warn($text)
    _MoodBump(-1)
    TrayTip($AGENT_NAME & " warning", $text, 5, 2)
    _Speak($text)
EndFunc

Func _MoodBump($delta)
    $g_iMood += $delta
    If $g_iMood < 0 Then $g_iMood = 0
    If $g_iMood > 100 Then $g_iMood = 100
    _RegWriteInt($REG_PATH, "Mood", $g_iMood)
EndFunc

Func _SaveMood()
    _RegWriteInt($REG_PATH, "Mood", $g_iMood)
EndFunc

Func _Log($msg)
    If Not $g_bLog Then Return
    Local $fh = FileOpen($LOG_FILE, 1)
    If $fh <> -1 Then
        Local $line = _IsoNow() & " | " & $AGENT_NAME & " | Author=" & $AUTHOR & " | Admin=" & IsAdmin() & " | Mood=" & $g_iMood & " | " & $msg
        FileWriteLine($fh, $line)
        FileClose($fh)
    EndIf
EndFunc

Func _IsoNow()
    Return @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & "T" & _
           StringFormat("%02d", @HOUR) & ":" & StringFormat("%02d", @MIN) & ":" & StringFormat("%02d", @SEC)
EndFunc
; === CONFIG ===
Global $MaxCPU = 85
Global $MinRAMMB = 512
Global $MinDiskGB = 5
Global $LogFile = @ScriptDir & "\hw_warn.log"
Global $EnableAlert = True
; === CPU CHECK ===
Func _CheckCPU()
    Local $obj = ObjGet("winmgmts:\\.\root\cimv2")
    Local $items = $obj.ExecQuery("SELECT LoadPercentage FROM Win32_Processor")
    For $item In $items
        If $item.LoadPercentage > $MaxCPU Then
            _Warn("CPU usage high: " & $item.LoadPercentage & "%")
        EndIf
    Next
EndFunc
; === RAM CHECK ===
Func _CheckRAM()
    Local $obj = ObjGet("winmgmts:\\.\root\cimv2")
    Local $items = $obj.ExecQuery("SELECT FreePhysicalMemory FROM Win32_OperatingSystem")
    For $item In $items
        Local $freeMB = Round($item.FreePhysicalMemory / 1024)
        If $freeMB < $MinRAMMB Then
            _Warn("Low RAM: " & $freeMB & " MB available")
        EndIf
    Next
EndFunc


; === DISK CHECK ===
Func _CheckDisk()
    Local $obj = ObjGet("winmgmts:\\.\root\cimv2")
    Local $items = $obj.ExecQuery("SELECT FreeSpace, DeviceID FROM Win32_LogicalDisk WHERE DriveType=3")
    For $item In $items
        Local $freeGB = Round($item.FreeSpace / 1073741824, 2)
        If $freeGB < $MinDiskGB Then
            _Warn("Low disk space on " & $item.DeviceID & ": " & $freeGB & " GB free")
        EndIf
    Next
EndFunc

Func _OnOff($b)
    If $b Then
        Return "On"
    Else
        Return "Off"
    EndIf
EndFunc

Func _StatusText()
    Local $s = IIf(IsAdmin(), "Elevated", "Standard")
    $s &= " | Mood=" & $g_iMood & " | " & IIf($g_bPaused, "Paused", "Active")
    Return $s
EndFunc

Func _StatusSuffix()
    Return " — " & _StatusText()
EndFunc

Func _IconIndex()
    Return IIf(IsAdmin(), 44, 23) ; shell32 icon indexes
EndFunc

Func _HasArg($flag)
    For $i = 1 To $CmdLine[0]
        If StringLower($CmdLine[$i]) = StringLower($flag) Then Return True
    Next
    Return False
EndFunc
Opt("GUIOnEventMode", 1)
HotKeySet("^!x", "_KillSwitch") ; Ctrl+Alt+X

Global $hGUI = GUICreate("AI3 Overlay", 300, 100, @DesktopWidth - 320,40, $WS_POPUP, $WS_EX_TOPMOST + $WS_EX_TOOLWINDOW)
GUISetBkColor(0x1E1E1E)
GUISetOnEvent($GUI_EVENT_CLOSE, "_KillSwitch")
; =========================
; Registry helpers
; =========================
Func _RegReadBool($path, $name, $def)
    Local $v = RegRead($path, $name)
    If @error Then Return $def
    Return Number($v) <> 0
EndFunc

Func _RegWriteBool($path, $name, $val)
    RegWrite($path, $name, "REG_DWORD", Number($val))
EndFunc

Func _RegReadInt($path, $name, $def)
    Local $v = RegRead($path, $name)
    If @error Then Return $def
    Return Number($v)
EndFunc

Func _RegWriteInt($path, $name, $val)
    RegWrite($path, $name, "REG_DWORD", Number($val))
EndFunc
; Load operator tag
Local $tag = DllCall("agent_pack.dll", "str", "GetOperatorTag")
If @error Then Exit MsgBox(16, "Error", "Can't load operator tag.")
ConsoleWrite("Operator: " & $tag[0] & @CRLF)

; Buffer for CPU load
Local $buf = DllStructCreate("char[64]")
DllCall("agent_pack.dll", "none", "GetCPULoad", "struct*", $buf, "int", 64)
ConsoleWrite(DllStructGetData($buf, 1) & @CRLF)
