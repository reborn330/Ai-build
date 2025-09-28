#include <Array.au3>
#include <File.au3>
#include <Date.au3>
#include <MsgBoxConstants.au3>

Global Const $cfgPath = @ScriptDir & "\config\safe_mode.cfg"
Global Const $logPath = @ScriptDir & "\logs\audit.log"

; Load and parse INI config
Func LoadSafeConfig()
    If Not FileExists($cfgPath) Then
        Log("ERROR: safe_mode.cfg not found.")
        Exit 1
    EndIf

    Local $mode = IniRead($cfgPath, "agent", "mode", "undefined")
    If $mode <> "safe" Then
        Log("ERROR: Config mode is not 'safe'. Aborting.")
        Exit 1
    EndIf

    Log("Booting agent_core in SAFE MODE...")
    Log("Config version: " & IniRead($cfgPath, "agent", "version", "unknown"))
    Log("Operator ID: " & IniRead($cfgPath, "auth", "operator_id", "none"))
    Log("Portable mode: " & IniRead($cfgPath, "agent", "portable", "false"))

    ; Load modules
    If IniRead($cfgPath, "modules", "enable_core", "false") = "true" Then
        Log("Core module enabled.")
        ; Simulate core startup
        Sleep(500)
    EndIf

    If IniRead($cfgPath, "modules", "enable_overlay", "false") = "true" Then
        Log("Overlay module enabled.")
        ; Simulate overlay startup
        Sleep(300)
    EndIf

    Log("SAFE MODE boot complete.")
EndFunc

; Entry point
LoadSafeConfig()