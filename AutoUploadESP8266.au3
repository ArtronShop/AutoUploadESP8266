#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icon\espressif.ico
#AutoIt3Wrapper_Outfile=AutoUploadESP8266_x86.exe
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiStatusBar.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <File.au3>
#include <Array.au3>
#include <EditConstants.au3>
#Include <GUIEdit.au3>
#Include <ScrollBarConstants.au3>
#include 'CommMG.au3'

Local $sportSetError, $hTimer = TimerInit()

Global $configFile = ".\config.ini"
Global $isStart = False
Global $resOpen = 0
Global $port
Global $PortConnected = False, $lastPortConnected = False

If Not FileExists($configFile) Then
	FileWrite($configFile, "")
EndIf

$listAllFile = _FileListToArray(".\firmware", "*")
$listFirmware = ""
For $index = 1 To UBound($listAllFile) - 1
	If FileGetAttrib($listAllFile[$index]) <> "D" Then
		If $listFirmware <> "" Then $listFirmware = $listFirmware & "|"
		$listFirmware = $listFirmware & $listAllFile[$index]
	EndIf
Next

$esptool = IniRead($configFile, "Upload", "esptool", ".\bin\esptool.exe")
$parameters = IniRead($configFile, "Upload", "parameters", "-vv -cd nodemcu -cb {speed} -cp {port} -ca 0x00000 -cf {firmware}")
$upload_speed = IniRead($configFile, "Upload", "speed", "921600")
$upload_firmware = IniRead($configFile, "Upload", "firmware", $listAllFile[1])

#Region ### START Koda GUI section ### Form=C:\Users\Max\Dropbox\Autoit\AutoUploadESP8266\AutoUploadESP8266.kxf
$Win = GUICreate("AutoUploadESP8266", 578, 397, -1, -1)
$Group1 = GUICtrlCreateGroup("Config", 8, 8, 377, 137)
$Label1 = GUICtrlCreateLabel("esptool", 24, 28, 38, 17)
$esptoolInp = GUICtrlCreateInput($esptool, 72, 24, 257, 21)
$selectEsptoolPathBtn = GUICtrlCreateButton("...", 336, 24, 35, 21)
$Label2 = GUICtrlCreateLabel("Upload Speed", 24, 92, 72, 17)
$speedCombo = GUICtrlCreateCombo("", 24, 112, 89, 25, BitOR($CBS_DROPDOWNLIST,$CBS_AUTOHSCROLL))
GUICtrlSetData(-1, "921600|512000|256000|115200", $upload_speed)
$Label3 = GUICtrlCreateLabel("Firmware", 232, 92, 46, 17)
$firmwareCombo = GUICtrlCreateCombo("", 232, 112, 137, 25, BitOR($CBS_DROPDOWNLIST,$CBS_AUTOHSCROLL))
GUICtrlSetData(-1, $listFirmware, $upload_firmware)
$Label4 = GUICtrlCreateLabel("Parameters", 24, 60, 57, 17)
$parametersInp = GUICtrlCreateInput($parameters, 88, 56, 281, 21)
$Label5 = GUICtrlCreateLabel("Port", 128, 92, 23, 17)
$portCombo = GUICtrlCreateCombo("", 128, 112, 89, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
GUICtrlCreateGroup("", -99, -99, 1, 1)
$Group2 = GUICtrlCreateGroup("Start / Stop", 392, 8, 177, 137)
$start_stopBtn = GUICtrlCreateButton("Start !", 408, 32, 145, 97)
GUICtrlSetFont(-1, 18, 400, 0, "MS Sans Serif")
GUICtrlCreateGroup("", -99, -99, 1, 1)
$Group3 = GUICtrlCreateGroup("Log", 8, 160, 225, 209)
$Log = GUICtrlCreateEdit("", 16, 184, 209, 177)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$Group4 = GUICtrlCreateGroup("Serial", 240, 160, 329, 209)
$Serial = GUICtrlCreateEdit("", 248, 184, 313, 177)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$StatusBar = _GUICtrlStatusBar_Create($Win)
Local $aParts[2] = [200, 150]
_GUICtrlStatusBar_SetParts($StatusBar, $aParts)
_GUICtrlStatusBar_SetText($StatusBar, "Dev By IOXhop (www.ioxhop.com)", 1)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###


Global $PortList = _ComGetPortNames()
If Not @error = 1 Then
	updatePortCombo($PortList)
EndIf

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit

		Case $selectEsptoolPathBtn
			$selectPath = FileOpenDialog("Select esptool.exe", "", "esptool (esptool.exe)")
			If Not @error Then GUICtrlSetData($esptoolInp, $selectPath)

		Case $start_stopBtn
			If Not $isStart Then
				$esptool = GUICtrlRead($esptoolInp)
				$parameters = GUICtrlRead($parametersInp)
				$speed = GUICtrlRead($speedCombo)
				$port = GUICtrlRead($portCombo)
				$firmware = GUICtrlRead($firmwareCombo)
				If $port <> "" Then
					$isStart = True
					Start()
				Else
					MsgBox(16, "Error", "Please select port.")
				EndIf
			Else
				$isStart = False
				Stop()
			EndIf

	EndSwitch
	If TimerDiff($hTimer) >= 50 Then
		$hTimer = TimerInit()
		If $isStart Then
			Local $sComPort = _ComGetPortNames($port)
			If @error Then
				$PortConnected = False
			Else
				$PortConnected = True
			EndIf
		Else
			$nowPortList = _ComGetPortNames()
			If _ArrayToString($nowPortList) <> _ArrayToString($PortList) Then
				updatePortCombo($nowPortList)
			EndIf
			$PortList = $nowPortList
		EndIf
		If $isStart And $lastPortConnected Then
			$str = _CommGetString()
			If Not @error  And $str <> "" Then
				Local $iEnd = StringLen(GUICtrlRead($Serial))
				_GUICtrlEdit_SetSel($Serial, $iEnd, $iEnd)
				_GUICtrlEdit_Scroll($Serial, $SB_SCROLLCARET)
				GUICtrlSetData($Serial, $str, 1)
			EndIf
			If @error Then
				_GUICtrlStatusBar_SetText($StatusBar, "Serial read error !", 0)
			EndIf
		EndIf
		If $isStart And $PortConnected = False And $lastPortConnected = True Then
			_GUICtrlStatusBar_SetText($StatusBar, "Wait port reconnect", 0)
			$lastPortConnected = False
		EndIf
		If $isStart And $PortConnected = True And $lastPortConnected = False Then
			Start()
		EndIf
	EndIf
WEnd

Func Start()
	GUICtrlSetData($start_stopBtn, "Stop !")
	GUICtrlSetState($esptoolInp, $GUI_DISABLE)
	GUICtrlSetState($parametersInp, $GUI_DISABLE)
	GUICtrlSetState($speedCombo, $GUI_DISABLE)
	GUICtrlSetState($portCombo, $GUI_DISABLE)
	GUICtrlSetState($firmwareCombo, $GUI_DISABLE)

	GUICtrlSetData($Log, "")
	GUICtrlSetData($Serial, "")

	$parameters = StringReplace($parameters, "{speed}", $speed)
	$parameters = StringReplace($parameters, "{port}", $port)
	$parameters = StringReplace($parameters, "{firmware}", @ScriptDir & "\firmware\" & $firmware)

	Local $cmd = _PathFull($esptool) & " " & $parameters

	Local $iPID = Run($cmd, "", @SW_HIDE, $STDOUT_CHILD)
;~ 	ProcessWaitClose($iPID)
	_GUICtrlStatusBar_SetText($StatusBar, "Wait upload firmware via esptool")
	While ProcessExists($iPID)
		Local $sOutput = StdoutRead($iPID, False, False)
		If @error Then ExitLoop
		If $sOutput <> "" Then
			Local $iEnd = StringLen(GUICtrlRead($Log))
			_GUICtrlEdit_SetSel($Log, $iEnd, $iEnd)
			_GUICtrlEdit_Scroll($Log, $SB_SCROLLCARET)
			GUICtrlSetData($Log, $sOutput, 1)
		EndIf
	WEnd
	Sleep(100) ; wait esptool close port
	$resOpen = _CommSetPort(StringReplace($port, 'COM', ''), $sportSetError, "115200")
	If $resOpen = 0 Then
		_GUICtrlStatusBar_SetText($StatusBar, "Serial fali (can't open " & $port & ")", 0)
	Else
		_GUICtrlStatusBar_SetText($StatusBar, "Serial listen", 0)
	EndIf
	$lastPortConnected = True
EndFunc

Func Stop()
	GUICtrlSetData($start_stopBtn, "Start !")
	GUICtrlSetState($esptoolInp, $GUI_ENABLE)
	GUICtrlSetState($parametersInp, $GUI_ENABLE)
	GUICtrlSetState($speedCombo, $GUI_ENABLE)
	GUICtrlSetState($portCombo, $GUI_ENABLE)
	GUICtrlSetState($firmwareCombo, $GUI_ENABLE)

	If $lastPortConnected Then _CommClosePort()
	$lastPortConnected = False
	_GUICtrlStatusBar_SetText($StatusBar, "Stop !", 0)
EndFunc

Func updatePortCombo($PortList)
	Global $listPort = ""
	For $index = 0 To UBound($PortList) - 1
		If $listPort <> "" Then $listPort = $listPort & "|"
		$listPort = $listPort & $PortList[$index][0]
	Next
	If $listPort <> "" Then
		GUICtrlSetData($portCombo, $listPort, $PortList[0][0])
	Else
		GUICtrlSetData($portCombo, "", "")
	EndIf
EndFunc