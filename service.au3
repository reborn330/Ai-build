; AI_Build_Server.au3
; AutoIt v3 script — installs itself as a service using nssm (preferred) or creates a scheduled task fallback.
; Place compiled EXE in K:\aibuild and (optionally) place nssm.exe in K:\aibuild\nssm.exe
; Usage:
;   AI_Build_Server.exe Install    -> installs service (requires admin UAC)
;   AI_Build_Server.exe Uninstall  -> removes service (requires admin)
;   AI_Build_Server.exe Start      -> start service (if installed via nssm)
;   AI_Build_Server.exe Stop       -> stop service (if installed via nssm)
;   AI_Build_Server.exe Run        -> run foreground (for debugging)
;   (no param)                     -> run in normal mode (if launched by service manager / nssm it will enter service loop)

#NoTrayIcon
Opt("TrayMenuMode", 0)
AutoItSetOption("WinTitleMatchMode", 2)

Global $sServiceName    = "AI_Build_Server"
Global $sServiceDisplay = "AI Build Server"
Global $sWorkDir        = "K:\aibuild"
Global $sLogFile        = $sWorkDir & "\ai_build_server.log"
Global $sNssmPath       = $sWorkDir & "\nssm.exe"
Global $sExePath        = @ScriptFullPath
Global $hMutex

; Ensure work dir exists
If Not FileExists($sWorkDir) Then DirCreate($sWorkDir)

; Single instance via mutex
$hMutex = _CreateMutex($sServiceName)
If @error Then
    ; Another instance is running. Exit.
    _Log("Another instance detected. Exiting.")
    Exit
EndIf

; Command-line handler
Switch StringLower($CmdLine[0])
    Case 1
        Local $cmd = StringLower($CmdLine[1])
        Switch $cmd
            Case "install"
                _RequireAdminAndRerun("Install")
                InstallService()
                Exit
            Case "uninstall"
                _RequireAdminAndRerun("Uninstall")
                UninstallService()
                Exit
            Case "start"
                _RequireAdminAndRerun("Start")
                ServiceStart()
                Exit
            Case "stop"
                _RequireAdminAndRerun("Stop")
                ServiceStop()
                Exit
            Case "run"
                _Log("Running in foreground (debug mode).")
                ServiceMain()
                Exit
            Case Else
                ; unknown command - fall through to run
        EndSwitch
EndSwitch

; If we reach here — run normal service loop (used when nssm runs the exe)
ServiceMain()


; ============================
; =  Functions / Subroutines =
; ============================

Func ServiceMain()
    _Log("Service main starting. WorkDir: " & $sWorkDir)
    ; Ensure working directory
    FileChangeDir($sWorkDir)

    ; Sample service loop: monitor K:\aibuild for new files, keep alive
    Local $iLoop = 0
    While 1
        $iLoop += 1
        ; Example action: every 5 seconds check for ".task" files and log them.
        _WatchForTasks()
        ; You can put whatever server logic you need here (start subprocesses, watch child processes, etc.)
        Sleep(5000)
        ; Graceful shutdown check: if a file "stop.service" exists, stop loop (helps for graceful uninstall)
        If FileExists($sWorkDir & "\stop.service") Then
            _Log("stop.service marker detected — exiting service loop.")
            FileDelete($sWorkDir & "\stop.service")
            ExitLoop
        EndIf
    WEnd
    _Log("Service main exiting.")
EndFunc   ;==>ServiceMain

Func InstallService()
    _Log("InstallService: started.")
    If FileExists($sNssmPath) Then
        _Log("Found nssm at " & $sNssmPath & " — using nssm to install service.")
        ; Install using nssm: nssm install <service> <path-to-exe>
        Local $sCmd = '"' & $sNssmPath & '" install "' & $sServiceName & '" "' & $sExePath & '"'
        RunWait(@ComSpec & " /c " & $sCmd, "", @SW_HIDE)
        ; Set display name and AppDirectory
        RunWait(@ComSpec & " /c " & '"' & $sNssmPath & '" set "' & $sServiceName & '" DisplayName "' & $sServiceDisplay & '"', "", @SW_HIDE)
        RunWait(@ComSpec & " /c " & '"' & $sNssmPath & '" set "' & $sServiceName & '" AppDirectory "' & $sWorkDir & '"', "", @SW_HIDE)
        ; Set automatic start
        RunWait(@ComSpec & " /c " & '"' & $sNssmPath & '" set "' & $sServiceName & '" Start SERVICE_AUTO_START', "", @SW_HIDE)
        ; Start the service
        RunWait(@ComSpec & " /c " & '"' & $sNssmPath & '" start "' & $sServiceName & '"', "", @SW_HIDE)
        _Log("Service installed and started via nssm as: " & $sServiceName)
    Else
        _Log("nssm not found at " & $sNssmPath & " — using scheduled task fallback.")
        ; Fallback: create a scheduled task running at system startup as SYSTEM
        Local $sTaskName = $sServiceName & "_task"
        Local $sCreate = 'schtasks /Create /RU "SYSTEM" /SC ONSTART /RL HIGHEST /TN "' & $sTaskName & '" /TR "' & $sExePath & '" /F'
        RunWait(@ComSpec & " /c " & $sCreate, "", @SW_HIDE)
        _Log("Scheduled task created: " & $sTaskName)
    EndIf
EndFunc   ;==>InstallService

Func UninstallService()
    _Log("UninstallService: started.")
    If FileExists($sNssmPath) Then
        _Log("Found nssm — stopping and removing service.")
        RunWait(@ComSpec & " /c " & '"' & $sNssmPath & '" stop "' & $sServiceName & '"', "", @SW_HIDE)
        RunWait(@ComSpec & " /c " & '"' & $sNssmPath & '" remove "' & $sServiceName & '" confirm', "", @SW_HIDE)
        _Log("Service removed via nssm.")
    Else
        ; Remove scheduled task fallback
        Local $sTaskName = $sServiceName & "_task"
        RunWait(@ComSpec & " /c " & 'schtasks /Delete /TN "' & $sTaskName & '" /F', "", @SW_HIDE)
        _Log("Scheduled task removed: " & $sTaskName)
    EndIf
EndFunc   ;==>UninstallService

Func ServiceStart()
    If FileExists($sNssmPath) Then
        RunWait(@ComSpec & " /c " & '"' & $sNssmPath & '" start "' & $sServiceName & '"', "", @SW_HIDE)
        _Log("Requested nssm to start service.")
    Else
        _Log("Cannot start service: nssm not found. Use schtasks or manual start.")
    EndIf
EndFunc   ;==>ServiceStart

Func ServiceStop()
    If FileExists($sNssmPath) Then
        RunWait(@ComSpec & " /c " & '"' & $sNssmPath & '" stop "' & $sServiceName & '"', "", @SW_HIDE)
        _Log("Requested nssm to stop service.")
    Else
        _Log("Cannot stop service: nssm not found.")
    EndIf
EndFunc   ;==>ServiceStop

Func _WatchForTasks()
    Local $aFiles = _FileListToArray($sWorkDir, "*.task", 1)
    If @error = 0 Then Return
    For $i = 1 To $aFiles[0]
        Local $sFile = $sWorkDir & "\" & $aFiles[$i]
        _Log("Processing task file: " & $sFile)
        ; Example: read and log then delete
        Local $sContent = FileRead($sFile)
        _Log("Task content: " & StringLeft($sContent, 100))
        FileDelete($sFile)
    Next
EndFunc   ;==>_WatchForTasks

Func _Log($sMsg)
    Local $sTime = "[" & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] "
    Local $sLine = $sTime & $sMsg & @CRLF
    ; Ensure log folder exists
    If Not FileExists($sLogFile) Then
        Local $h = FileOpen($sLogFile, 2)
        If $h <> -1 Then FileClose($h)
    EndIf
    FileWrite($sLogFile, $sLine)
EndFunc   ;==>_Log

; =======================
; =  Helper functions   =
; =======================

Func _CreateMutex($sName)
    ; Create a mutex object to ensure single instance.
    Local $tRet = DllCall("kernel32.dll", "handle", "CreateMutexW", "ptr", 0, "int", 0, "wstr", $sName)
    If @error Or Not IsHWnd($tRet[0]) Then
        SetError(1)
        Return 0
    EndIf
    Return $tRet[0]
EndFunc   ;==>_CreateMutex

Func _RequireAdminAndRerun($sParam)
    ; If not admin, re-run this EXE elevated with the same argument
    If Not IsAdmin() Then
        _Log("Elevation required for: " & $sParam & " — re-launching elevated.")
        ShellExecute($sExePath, $sParam, "", "runas")
        Exit
    EndIf
EndFunc   ;==>_RequireAdminAndRerun

Func _FileListToArray($sPath, $sPattern = "*.*", $iFlag = 0)
    ; Wrapper for FileFind*
    Local $sFull = $sPath & "\" & $sPattern
    Local $hSearch = FileFindFirstFile($sFull)
    If $hSearch = -1 Then
        SetError(1)
        Return 0
    EndIf
    Local $aList[1] = [0]
    Local $sFile
    While 1
        $sFile = FileFindNextFile($hSearch)
        If @error Then ExitLoop
        If $iFlag = 1 Then
            If StringLeft($sFile, 1) = "." Then ContinueLoop
        EndIf
        ReDim $aList[UBound($aList) + 1]
        $aList[0] += 1
        $aList[$aList[0]] = $sFile
    WEnd
    FileClose($hSearch)
    Return $aList
EndFunc   ;==>_FileListToArray
