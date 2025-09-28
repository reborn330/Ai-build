; ================================================================
; AutoLauncher.au3 - agent_core.exe first, then all other EXEs
; ================================================================

Global $g_sBase = "E:\Ai Build\"              ; Folder containing EXEs
Global $g_sIni  = $g_sBase & "hidden.ini"    ; Full path to hidden.ini
Global $g_sPrimary = $g_sBase & "agent_core.exe" ; Primary executable

; === Launch agent_core.exe first ===
If Not ProcessExists("agent_core.exe") Then
    If FileExists($g_sPrimary) Then
        Run($g_sPrimary, $g_sBase)
        ConsoleWrite("Launched: agent_core.exe" & @CRLF)
    Else
        ConsoleWrite("Error: agent_core.exe not found" & @CRLF)
    EndIf
Else
    ConsoleWrite("Skipped (already running): agent_core.exe" & @CRLF)
EndIf

; === Load executables from hidden.ini ===
Global $aIni = IniReadSection($g_sIni, "Executables")
If @error Then
    MsgBox(16, "Error", "hidden.ini not found or invalid: " & $g_sIni)
    Exit
EndIf

; === Launch all other EXEs ===
For $i = 1 To $aIni[0][0]
    Local $sExeName = $aIni[$i][1]

    ; Skip agent_core.exe since already handled
    If $sExeName = "agent_core.exe" Then ContinueLoop

    Local $sExePath = $g_sBase & $sExeName

    ; Skip if already running
    If ProcessExists($sExeName) Then
        ConsoleWrite("Skipped (already running): " & $sExeName & @CRLF)
        ContinueLoop
    EndIf

    ; Launch if exists
    If FileExists($sExePath) Then
        Run($sExePath, $g_sBase)
        ConsoleWrite("Launched: " & $sExeName & @CRLF)
    Else
        ConsoleWrite("Error (not found): " & $sExeName & @CRLF)
    EndIf
Next

Exit
