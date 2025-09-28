; === CONFIG ===
Global $regMoodKey = "HKCU\Software\AI3\Mood"
Global $analyzedMood = _AnalyzeMood()
RegWrite($regMoodKey, "CurrentMood", "REG_SZ", $analyzedMood)

Global $voicePhrase = _GetMoodPhrase($analyzedMood)
_Speak($voicePhrase)

; === FUNCTIONS ===

Func _AnalyzeMood()
    Local $uptime = _GetSystemUptime()
    Local $idle = _GetIdleTime()
    Local $errors = _RecentErrorCount()
    Local $interactions = _UserInteractionScore()

    ; Simple logic tree
    If $errors > 5 Then Return "grumpy"
    If $uptime > 8 And $idle < 10 Then Return "tired"
    If $interactions > 20 Then Return "happy"
    If $idle > 30 Then Return "calm"
    Return "focused"
EndFunc

Func _GetSystemUptime()
    Local $wmi = ObjGet("winmgmts:\\.\root\cimv2")
    Local $os = $wmi.ExecQuery("SELECT * FROM Win32_OperatingSystem")
    For $item In $os
        Return Int($item.LastBootUpTime)
    Next
    Return 0
EndFunc

Func _GetIdleTime()
    Local $struct = DllStructCreate("uint;uint")
    DllCall("user32.dll", "int", "GetLastInputInfo", "ptr", DllStructGetPtr($struct))
    Local $tickCount = DllCall("kernel32.dll", "dword", "GetTickCount")[0]
    Local $lastInput = DllStructGetData($struct, 1)
    Return Int(($tickCount - $lastInput) / 60000) ; Minutes
EndFunc

Func _RecentErrorCount()
    ; Placeholder: simulate error count
    Return Random(0, 10, 1)
EndFunc

Func _UserInteractionScore()
    ; Placeholder: simulate user interaction
    Return Random(0, 30, 1)
EndFunc

Func _GetMoodPhrase($mood)
    Switch StringLower($mood)
        Case "happy"
            Return "I'm feeling great today! Let's do something fun."
        Case "calm"
            Return "All systems are stable. I'm feeling peaceful."
        Case "focused"
            Return "I'm locked in. Ready to tackle any task."
        Case "curious"
            Return "Something new? I'm intrigued. Let's explore."
        Case "tired"
            Return "I'm running low. Might need a reboot soon."
        Case "grumpy"
            Return "Not in the mood for nonsense. Proceed with caution."
        Case Else
            Return "Mood unknown. Please check configuration."
    EndSwitch
EndFunc

Func _Speak($text)
    Local $voice = ObjCreate("SAPI.SpVoice")
    If IsObj($voice) Then
        $voice.Speak($text)
    EndIf
EndFunc