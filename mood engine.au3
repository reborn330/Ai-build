#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <WinAPI.au3>

Global Const $g_sXMLPath = @ScriptDir & "\HWMonitorReport.xml"
Global Const $g_nRefreshSec = 2
Global Const $g_barWidth = 200
Global Const $g_barHeight = 12

Global $hGUI, $barCPU, $barGPU, $lblCPU, $lblGPU

; ?? Create transparent HUD
$hGUI = GUICreate("", $g_barWidth + 60, 80, @DesktopWidth - $g_barWidth - 80, 40, $WS_POPUP, BitOR($WS_EX_TOPMOST, $WS_EX_TOOLWINDOW, $WS_EX_LAYERED))
GUISetBkColor(0x000000)
WinSetTrans($hGUI, "", 180)

GUICtrlCreateLabel("CPU", 10, 10, 30)
$barCPU = GUICtrlCreateGraphic(50, 10, $g_barWidth, $g_barHeight)
GUICtrlSetBkColor($barCPU, 0x444444)
$lblCPU = GUICtrlCreateLabel("", 50, 25, 100)

GUICtrlCreateLabel("GPU", 10, 45, 30)
$barGPU = GUICtrlCreateGraphic(50, 45, $g_barWidth, $g_barHeight)
GUICtrlSetBkColor($barGPU, 0x444444)
$lblGPU = GUICtrlCreateLabel("", 50, 60, 100)

GUISetState(@SW_SHOW)

; ?? Update Loop
While 1
    Local $cpu = Number(GetSensor("CPU Package"))
    Local $gpu = Number(GetSensor("GPU Core"))

    UpdateBar($barCPU, $cpu, 100)
    GUICtrlSetData($lblCPU, $cpu & "°C")

    UpdateBar($barGPU, $gpu, 100)
    GUICtrlSetData($lblGPU, $gpu & "°C")

    Sleep($g_nRefreshSec * 1000)
WEnd

; ?? Sensor Reader
Func GetSensor($name)
    If Not FileExists($g_sXMLPath) Then Return 0
    Local $xml = FileRead($g_sXMLPath)
    Local $pattern = '<Sensor><Name>' & $name & '</Name><Value>([\d\.]+)</Value>'
    Local $match = StringRegExp($xml, $pattern, 1)
    If @error Or UBound($match) = 0 Then Return 0
    Return Number($match[0])
EndFunc

; ?? Bar Renderer
Func UpdateBar($ctrlID, $value, $max)
    Local $percent = Min(100, Round(($value / $max) * 100))
    Local $width = Round(($percent / 100) * $g_barWidth)

    GUICtrlSetGraphic($ctrlID, $GUI_GR_CLEAR)
    GUICtrlSetGraphic($ctrlID, $GUI_GR_COLOR, GetBarColor($value))
    GUICtrlSetGraphic($ctrlID, $GUI_GR_RECT, 0, 0, $width, $g_barHeight)
EndFunc

; ?? Color Logic
Func GetBarColor($temp)
    If $temp < 60 Then Return 0x00FF00 ; green
    If $temp < 75 Then Return 0xFFFF00 ; yellow
    Return 0xFF0000 ; red
EndFunc