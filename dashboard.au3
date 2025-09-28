; ================================================================
; Simple AI Build Dashboard - Manual Launch Only, Hide Paths
; ================================================================

#include <GUIConstantsEx.au3>
#include <GuiListView.au3>
#include <GuiStatusBar.au3>

Global $g_sBase = "C:\Program Files (x86)\AI Build\"
Global $g_sIni  = $g_sBase & "hidden.ini"

; === Load executables from hidden.ini ===
Global $aIni = IniReadSection($g_sIni, "Executables")
If @error Then
    MsgBox(16, "Error", "hidden.ini not found or invalid")
    Exit
EndIf

; Build array [exeName | fullPath]
Global $aExeList[$aIni[0][0]][2]
For $i = 1 To $aIni[0][0]
    $aExeList[$i-1][0] = $aIni[$i][1]        ; Display name only
    $aExeList[$i-1][1] = $g_sBase & $aIni[$i][1] ; Full path used internally
Next

; === GUI ===
Global $hGUI = GUICreate("AI Build Dashboard", 600, 500)
GUISetBkColor(0x1E1E2E, $hGUI)

; ListView (show only names)
Global $idList = GUICtrlCreateListView("Executable", 10, 10, 400, 480, BitOR($LVS_REPORT, $LVS_SHOWSELALWAYS))
_GUICtrlListView_SetColumnWidth($idList, 0, 380)

For $i = 0 To UBound($aExeList)-1
    GUICtrlCreateListViewItem($aExeList[$i][0], $idList)
Next

; Buttons for manual launch
Global $idButtons[UBound($aExeList)]
Local $x = 420, $y = 20, $w = 150, $h = 40, $spacing = 50
For $i = 0 To UBound($aExeList)-1
    $idButtons[$i] = GUICtrlCreateButton($aExeList[$i][0], $x, $y + ($i * $spacing), $w, $h)
Next

; Status bar
Global $hStatus = _GUICtrlStatusBar_Create($hGUI)
_GUICtrlStatusBar_SetSimple($hStatus)
_GUICtrlStatusBar_SetText($hStatus, "Select an executable to launch.")

; Show GUI
GUISetState(@SW_SHOW, $hGUI)

; === Event loop ===
While 1
    Local $msg = GUIGetMsg()
    Switch $msg
        Case $GUI_EVENT_CLOSE
            Exit

        ; ListView double-click launches selected exe
        Case $idList
            If _GUICtrlListView_GetSelectedCount($idList) > 0 Then
                Local $iSel = _GUICtrlListView_GetNextItem($idList)
                If $iSel >= 0 Then _RunExe($aExeList[$iSel][1])
            EndIf

        ; Buttons launch exe
        Case Else
            For $i = 0 To UBound($idButtons)-1
                If $msg = $idButtons[$i] Then _RunExe($aExeList[$i][1])
            Next
    EndSwitch
    Sleep(50)
WEnd

; === Helper function ===
Func _RunExe($sExe)
    _GUICtrlStatusBar_SetText($hStatus, "Launching " & StringTrimLeft($sExe, StringInStr($sExe, "\", 0, -1)))
    If FileExists($sExe) Then
        Run($sExe, $g_sBase)
        _GUICtrlStatusBar_SetText($hStatus, "Success: " & StringTrimLeft($sExe, StringInStr($sExe, "\", 0, -1)))
    Else
        _GUICtrlStatusBar_SetText($hStatus, "Error: " & StringTrimLeft($sExe, StringInStr($sExe, "\", 0, -1)) & " not found")
    EndIf
EndFunc
