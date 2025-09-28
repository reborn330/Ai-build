; Reflector.au3 – Script introspection module for AI3
Global $g_Reflector_LogPath = @ScriptDir & "\Reflector.log"
Global $g_Reflector_ShowGUI = True

Func Reflector_Init()
    FileDelete($g_Reflector_LogPath)
    Reflector_Log("=== Reflector Initialized ===")
    Reflector_ScanFunctions()
    Reflector_ScanGlobals()
    If $g_Reflector_ShowGUI Then Reflector_GUI()
EndFunc

Func Reflector_Log($msg)
    FileWriteLine($g_Reflector_LogPath, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $msg)
EndFunc

Func Reflector_ScanFunctions()
    Local $lines = FileReadToArray(@ScriptFullPath)
    For $i = 0 To UBound($lines) - 1
        If StringRegExp($lines[$i], "^\s*Func\s+(\w+)", 1) Then
            Local $funcName = StringRegExpReplace($lines[$i], "^\s*Func\s+(\w+).*", "$1")
            Reflector_Log("Function Found: " & $funcName)
        EndIf
    Next
EndFunc

Func Reflector_ScanGlobals()
    Local $lines = FileReadToArray(@ScriptFullPath)
    For $i = 0 To UBound($lines) - 1
        If StringRegExp($lines[$i], "^\s*Global\s+\$(\w+)", 1) Then
            Local $varName = StringRegExpReplace($lines[$i], "^\s*Global\s+\$(\w+).*", "$1")
            Reflector_Log("Global Variable: $" & $varName)
        EndIf
    Next
EndFunc

Func Reflector_GUI()
    GUICreate("Script Reflector", 400, 300)
    Local $edit = GUICtrlCreateEdit(FileRead($g_Reflector_LogPath), 10, 10, 380, 280)
    GUISetState()
    While 1
        Switch GUIGetMsg()
            Case -3 ; $GUI_EVENT_CLOSE
                ExitLoop
        EndSwitch
    WEnd
EndFunc