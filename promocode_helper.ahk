#include <Gdip_All>
#include <UwpOcr>

#SingleInstance force
#NoEnv
#MaxHotkeysPerInterval 99000000
#HotkeyInterval 99000000
#KeyHistory 0
#InstallKeybdHook
#InstallMouseHook
#UseHook

ListLines Off
Process, Priority, , A
SetTitleMatchMode, 2
SetTitleMatchMode, Fast
SetBatchLines, -1
SetKeyDelay, -1, -1, Play
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetWinDelay, -1
SetControlDelay, -1
SendMode Input
CoordMode, Mouse, Client
CoordMode, Pixel, Client
CoordMode, ToolTip, Screen

FileEncoding, UTF-8

;-------------------------------------------------------------------------------
; global variables
;-------------------------------------------------------------------------------

global LOG_LEVEL := 3 ;current log level
global TRACE     := 1 ;log level
global DEBUG     := 2 ;log level
global INFO      := 3 ;log level
global WARN      := 4 ;log level
global ERROR     := 5 ;log level
global SEVERE    := 6 ;log level

global LOG_FILE              := A_ScriptDir "\log\" SubStr(A_ScriptName, 1, -4) ".log" ;log file
global CAPTURE2TEXT_FILE     := A_ScriptDir "\Capture2Text\Capture2Text.exe" ;capture2text exe file, faster than Capture2Text_CLI.exe
global CAPTURE2TEXT_CFG_FILE := A_ScriptDir "\Capture2Text\tessconfigs-main\configs\lol_code" ;capture2text config file
global TESSERACT_FILE        := A_ProgramFiles "\Tesseract-OCR\tesseract.exe" ;tesseract exe file
global TESSERACT_CFG_FILE    := A_ProgramFiles "\Tesseract-OCR\tessdata\configs\lol_code" ;tesseract config file

global PROPERTIES_FILE := A_ScriptDir "\" SubStr(A_ScriptName, 1, -4) ".properties" ;properties file
global CODE_JUDGE_BG_COLOR := "0xFFFFFC", CODE_JUDGE_X := 622, CODE_JUDGE_Y := 885
global CODE_START_X := 0, CODE_START_Y := 0, CODE_WIDTH := 0, CODE_HEIGHT := 0

;-------------------------------------------------------------------------------
; hotkeys
; Get code background value with ctrl+shift+`
; Get the code background value and coordinate value with ctrl+shift+d and save it in properties
; Copy code to clipboard with ctrl+shift+a, repeat automatically
; Copy to clipboard manually with ctrl+shift+s
;-------------------------------------------------------------------------------

^+p:: ;ctrl+shift+p
{
  initHotkey("Pause")
  Pause
  return
}

^+r:: ;ctrl+shift+r
{
  Reload
  return
}

^+x:: ;ctrl+shift+x
{
  ExitApp
}

^+`:: ;ctrl+shift+`
{
  initHotkey("getPixelColor")
  ;getPixelColor("", "")
  getProperties(getTextFile(PROPERTIES_FILE))
  getPixelColor(CODE_JUDGE_X, CODE_JUDGE_Y)
  return
}

^+z:: ;ctrl+shift+z
{
  initHotkey("test")
  test()
  return
}

^+a:: ;ctrl+shift+a
{
  initHotkey("setCodeAuto")
  color_variation := 16
  getProperties(getTextFile(PROPERTIES_FILE))
  loop {
    ;CODE_JUDGE_X, CODE_JUDGE_Y 적용 불가
    ;if (isColorFromPixel(CODE_JUDGE_X, CODE_JUDGE_Y, CODE_JUDGE_BG_COLOR, color_variation)) {  
    if (isColorFromPixel(622, 885, "0xC3B65D", color_variation)) {
      Sleep, 50 ;code fade in delay
      setTextUwpOcr(CODE_START_X, CODE_START_Y, CODE_WIDTH, CODE_HEIGHT)
      playBeep(1, 7902, 80) ;SUCCEED
      return
    } else {
      Sleep, 100
    }
  }  
}

^+s:: ;ctrl+shift+s
{
  initHotkey("setCodeManual")
  getProperties(getTextFile(PROPERTIES_FILE))
  setTextUwpOcr(CODE_START_X, CODE_START_Y, CODE_WIDTH, CODE_HEIGHT)
  playBeep(1, 7902, 80) ;SUCCEED
  return
}

^+d:: ;ctrl+shift+d
{
  initHotkey("getMouseCursorRect")
  getMouseCursorRect(startX, startY, width, height)
  codeBgColor := getPixelColor(startX, startY)
  outText := "CODE_JUDGE_BG_COLOR=" codeBgColor "`nCODE_JUDGE_X=" startX "`nCODE_JUDGE_Y=" startY "`nCODE_START_X=" startX "`nCODE_START_Y=" startY "`nCODE_WIDTH=" width "`nCODE_HEIGHT=" height
  deleteTextFile(PROPERTIES_FILE)
  setTextFile(outText, PROPERTIES_FILE)  
  playBeep(1, 7902, 80) ;SUCCEED
  return
}

;-------------------------------------------------------------------------------
; init
;-------------------------------------------------------------------------------

init() ;init

init() {
  runAsAdmin()
  removeLogFile(8192)
}

;-------------------------------------------------------------------------------
; test
;-------------------------------------------------------------------------------

test() {
  ;getPixelColor(683, 978)
  ;testSpeed1()
  ;testSpeed2()
  ;testIsCode()
  ;initLolClient()
  ;initLolMarket()
  ;playBeep(1, 7902, 80) ;SUCCEED
  ;playBeep(1, 2489, 80) ;FAILED
  ;clipboard := getTextUwpOcrScreen(CODE_START_X, CODE_START_Y, CODE_WIDTH, CODE_HEIGHT)  
}

testIsCode() {
  loop {
    if (isColorFromPixel(399, 907, "0xFEFDFB", 0)) {
      setLolCodeUwpOcr(CODE_START_X, CODE_START_Y, CODE_WIDTH, CODE_HEIGHT)
      return
    } else {
      Sleep, 100
    }
  }
}

testSpeed1() {
  testStartTime := A_TickCount
  fileSeq := A_Now
  imageFile := A_ScriptDir "\tmp\uwpocr_" fileSeq ".bmp"
  textFile := A_ScriptDir "\tmp\uwpocr_" fileSeq ".txt"
  setCaptureImageFile(CODE_START_X, CODE_START_Y, CODE_WIDTH, CODE_HEIGHT, imageFile)
  lolCode := getTextUwpOcrFile(imageFile)
  setTextFile(lolCode, textFile)
  testEndTime := A_TickCount - testStartTime
  message := "UwpOcr.ocr() " Round(testEndTime) "ms"
  writeLogFile(INFO, A_ThisFunc, A_LineNumber, message)
  showToolTip(DEBUG, message)
}

testSpeed2() {
  testStartTime := A_TickCount
  fileSeq := A_Now
  imageFile := A_ScriptDir "\tmp\uwpocr_" fileSeq ".bmp"
  textFile := A_ScriptDir "\tmp\uwpocr_" fileSeq ".txt"
  lolCode := getTextUwpOcrScreen(CODE_START_X, CODE_START_Y, CODE_WIDTH, CODE_HEIGHT)
  filteredLolCode := filterLolCode(lolCode)
  setCaptureImageFile(CODE_START_X, CODE_START_Y, CODE_WIDTH, CODE_HEIGHT, imageFile)
  setTextFile(lolCode, textFile)
  testEndTime := A_TickCount - testStartTime
  message := "UwpOcr.ocr() " Round(testEndTime) "ms"
  writeLogFile(INFO, A_ThisFunc, A_LineNumber, message)
  showToolTip(DEBUG, message)
}

;-------------------------------------------------------------------------------
; biz functions
;-------------------------------------------------------------------------------

getProperties(outText) {
  if errorlevel
    return
  oProperties := StrSplit(outText, "`n")
  loop, % oProperties.MaxIndex() {
    varName := StrSplit(oProperties[A_Index], "=")[1]
    varValue := StrSplit(oProperties[A_Index], "=")[2]
    switch (varName) {
      case "CODE_JUDGE_BG_COLOR":
        CODE_JUDGE_BG_COLOR := varValue
      case "CODE_JUDGE_X":
        CODE_JUDGE_X := varValue
      case "CODE_JUDGE_Y":
        CODE_JUDGE_Y := varValue
      case "CODE_START_X":
        CODE_START_X := varValue
      case "CODE_START_Y":
        CODE_START_Y := varValue
      case "CODE_WIDTH":
        CODE_WIDTH := varValue
      case "CODE_HEIGHT":
        CODE_HEIGHT := varValue
      default:
    }
  }
}

initLolClient() {
  if WinExist("ahk_exe LeagueClientUx.exe") {
    WinMove, League of Legends, , 1273, 287 ;1024x576
    WinActivate
  } else {
    return
  }
  Send, {Click, 401, 177, Left} ;to cursor
  SendRaw, init ;paste code
}

initLolMarket() {
  if WinExist("LoL 상점 - Chrome") {
    WinMove, LoL 상점 - Chrome, , 996, 78, 1141, 851 ;zoom 300%
    WinActivate
  } else {
    return
  }
  Send, {Click, 127, 610, Left} ;to cursor
  Send, ^{a}
  SendRaw, init ;paste code
}

setLolCodeUwpOcr(startX, startY, width, height) {
  bizStartTime := A_TickCount
  fileSeq := A_Now
  imageFile := A_ScriptDir "\tmp\uwpocr_" fileSeq ".bmp"
  textFile := A_ScriptDir "\tmp\uwpocr_" fileSeq ".txt"
  resultImageFile := A_ScriptDir "\tmp\uwpocr_" fileSeq "_result.bmp"
  setCaptureImageFile(startX, startY, width, height, imageFile)
  lolCode := getTextUwpOcrFile(imageFile)
  filteredLolCode := filterLolCode(lolCode)
  bizEndTime := A_TickCount - bizStartTime
  ;setCodeLolMarket(filteredLolCode, bizEndTime)
  setCodeLolClient(filteredLolCode, bizEndTime)
  setTextFile(lolCode, textFile)
  Sleep, 300
  setCaptureImageFile(1278, 290, 641, 567, resultImageFile)
}

setTextUwpOcr(startX, startY, width, height) {
  bizStartTime := A_TickCount
  fileSeq := A_Now
  sourceFile := A_ScriptDir "\test\source_" fileSeq ".bmp"
  imageFile := A_ScriptDir "\tmp\uwpocr_" fileSeq ".bmp"
  textFile := A_ScriptDir "\tmp\uwpocr_" fileSeq ".txt"
  setCaptureImageFile(startX, startY, width, height, imageFile)
  capturedText := getTextUwpOcrFile(imageFile)
  writeLogFile(DEBUG, A_ThisFunc, A_LineNumber, capturedText)
  bizEndTime := A_TickCount - bizStartTime
  capturedText := filterLolCode(capturedText)
  clipboard := capturedText
  setTextFile(capturedText, textFile)
  setCaptureImageFile(0, 0, A_ScreenWidth, A_ScreenHeight, sourceFile)
}

filterLolCode(lolCode) {
  ;Remove whitespace line breaks
  filteredLolCode := trim(lolCode, "`n`r`t ")
  filteredLolCode := StrReplace(filteredLolCode, A_Space)  
  ;Champion name + 4 digit code format
  ;Converts to 1 when recognized as l among 4-digit numeric codes
  filteredLolCodeLeft := SubStr(filteredLolCode, 1, StrLen(filteredLolCode) - 4)
  filteredLolCodeRight := SubStr(filteredLolCode, StrLen(filteredLolCode) - 3, 4)
  filteredLolCodeRight := StrReplace(filteredLolCodeRight, "l", "1")  
  filteredLolCode := filteredLolCodeLeft filteredLolCodeRight
  ;StringUpper, filteredLolCode, filteredLolCode
  ;filteredLolCode := StrReplace(filteredLolCode, "(R", "KR")
  ;message := "filterLolCode() " filteredLolCode " (" StrLen(filteredLolCode) ")"
  ;writeLogFile(DEBUG, A_ThisFunc, A_LineNumber, message)
  ;showToolTip(DEBUG, message)
  return filteredLolCode
}

setCodeLolClient(code, elapsedTime) {
  clipboard := code
  if WinExist("ahk_exe LeagueClientUx.exe") {
    WinActivate
  } else {
    return
  }
  Send, {Click, 401, 177, Left} ;to cursor
  Send, ^{a}^{v} ;paste code
  Sleep, 40
  isValidCode := false
  ;if (25 == StrLen(code) && (InStr(code, "WW", true) || InStr(code, "KR", true))) { ;global code
  if (25 == StrLen(code) && InStr(code, "KR", true)) {
    isValidCode := true
    Send, {Click, 614, 177, Left} ;enter code
    playBeep(1, 7902, 80) ;SUCCEED
  } else {
    isValidCode := false
    playBeep(1, 2489, 80) ;FAILED
  }
  message := "setCodeLolClient() " (isValidCode ? "SUCCEED" : "FAILED ") " " code " (" StrLen(code) ") " Round(elapsedTime) "ms"
  writeLogFile(WARN, A_ThisFunc, A_LineNumber, message)
  showToolTip(WARN, message)
}

setCodeLolMarket(code, elapsedTime) {
  clipboard := code
  if WinExist("LoL 상점 - Chrome") {
    WinActivate
  } else {
    return
  }
  Send, {Click, 127, 610, Left} ;to cursor
  Send, ^{a}^{v} ;paste code
  isValidCode := false
  ;if (25 == StrLen(code) && (InStr(code, "WW", true) || InStr(code, "KR", true))) { ;global code
  if (25 == StrLen(code) && InStr(code, "KR", true)) {
    isValidCode := true
    Send, {Enter} ;enter code
    playBeep(1, 7902, 80) ;SUCCEED
  } else {
    isValidCode := false
    playBeep(1, 2489, 80) ;FAILED
  }
  message := "setCodeLolMarket() " (isValidCode ? "SUCCEED" : "FAILED ") " " code " (" StrLen(code) ") " Round(elapsedTime) "ms"
  writeLogFile(WARN, A_ThisFunc, A_LineNumber, message)
  showToolTip(WARN, message)
}

;-------------------------------------------------------------------------------
; screen functions
;-------------------------------------------------------------------------------

getTextUwpOcrFile(imageFile) {
  startTime := A_TickCount
  outText := ocrFile(imageFile, "en")
  endTime := A_TickCount - startTime
  message := "UwpOcr.ocr() " Round(endTime) "ms " outText
  writeLogFile(DEBUG, A_ThisFunc, A_LineNumber, message)
  showToolTip(DEBUG, message)
  return outText
}

getTextUwpOcrScreen(startX, startY, width, height) {
  startTime := A_TickCount
  hBitmap := HBitmapFromScreen(startX, startY, width, height)
  pIRandomAccessStream := HBitmapToRandomAccessStream(hBitmap)
  DllCall("DeleteObject", "Ptr", hBitmap)
  outText := ocrStream(pIRandomAccessStream, "en")
  endTime := A_TickCount - startTime
  message := "UwpOcr.ocr() " Round(endTime) "ms"
  writeLogFile(DEBUG, A_ThisFunc, A_LineNumber, message)
  showToolTip(DEBUG, message)
  return outText
}

setFileTesseract(imageFile, textFile) {
  textFileWithoutExt := SubStr(textFile, 1, -4)
  startTime := A_TickCount
  RunWait, %TESSERACT_FILE% "%imageFile%" "%textFileWithoutExt%" --tessdata-dir "%A_ProgramFiles%\Tesseract-OCR\tessdata" -l eng --psm 4--oem 3 "%TESSERACT_CFG_FILE%", , Hide
  endTime := A_TickCount - startTime
  message := "RunWait() Tesseract " Round(endTime) "ms"
  writeLogFile(DEBUG, A_ThisFunc, A_LineNumber, message)
  showToolTip(DEBUG, message)
}

setFileCapture2Text(imageFile, textFile) {
  startTime := A_TickCount
  RunWait, %CAPTURE2TEXT_FILE% --image "%imageFile%" --output-file "%textFile%" --line-breaks --scale-factor 3.5 --tess-config-file "%CAPTURE2TEXT_CFG_FILE%", , Hide
  endTime := A_TickCount - startTime
  message := "RunWait() Capture2Text " Round(endTime) "ms"
  writeLogFile(DEBUG, A_ThisFunc, A_LineNumber, message)
  showToolTip(DEBUG, message)
}

getClipboardCapture2Text(startX, startY, width, height) {
  endX := startX + width
  endY := startY + height
  startTime := A_TickCount
  RunWait, %CAPTURE2TEXT_FILE% --clipboard --screen-rect "%startX% %startY% %endX% %endY%" --line-breaks --scale-factor 3.5 --tess-config-file "%CAPTURE2TEXT_CFG_FILE%", , Hide
  endTime := A_TickCount - startTime
  message := "RunWait() Capture2Text " Round(endTime) "ms"
  writeLogFile(DEBUG, A_ThisFunc, A_LineNumber, message)
  message := "getClipboardCapture2Text() " clipboard " (" StrLen(clipboard) ")"
  writeLogFile(DEBUG, A_ThisFunc, A_LineNumber, message)
  showToolTip(DEBUG, message)
  return clipboard
}

getPixelColor(pixelX, pixelY) {
  if (pixelX = "") || (pixelY = "") {
    MouseGetPos, pixelX, pixelY
  }
  PixelGetColor, color, pixelX, pixelY
  message := "PixelGetColor() " (ErrorLevel = 0 ? "SUCCEED" : "FAILED ") " " pixelX ", " pixelY " " color
  writeLogFile(INFO, A_ThisFunc, A_LineNumber, message)
  showToolTip(INFO, message)
  return color
}

isColorFromPixel(startX, startY, color, variation) {
  endX := startX + 1
  endY :=startY + 1
  PixelSearch, foundX, foundY, startX, startY, endX, endY, color, variation, Fast
  result := ErrorLevel = 0 ? true : false
  message := "PixelSearch() " (result ? "SUCCEED " foundX ", " foundY : "FAILED ") " " color
  writeLogFile(DEBUG, A_ThisFunc, A_LineNumber, message)
  showToolTip(WARN, message)
  if result
    return true
  else
    return false
}

;-------------------------------------------------------------------------------
; file functions
;-------------------------------------------------------------------------------

getTextFile(textFile) {
  FileRead, outText, %textFile%
  message := "FileRead() " (ErrorLevel = 0 ? "SUCCEED" : "FAILED ") " " textFile
  writeLogFile(INFO, A_ThisFunc, A_LineNumber, message)
  message := "getTextFile() " outText " (" StrLen(outText) ")"
  writeLogFile(DEBUG, A_ThisFunc, A_LineNumber, message)
  showToolTip(DEBUG, message)
  return outText
}

setTextFile(outText, textFile) {
  FileAppend, %outText%, %textFile%
  message := "FileAppend() " (ErrorLevel = 0 ? "SUCCEED" : "FAILED ") " " textFile
  writeLogFile(INFO, A_ThisFunc, A_LineNumber, message)
  message := "setTextFile() " outText " (" StrLen(outText) ")"
  writeLogFile(DEBUG, A_ThisFunc, A_LineNumber, message)
  showToolTip(DEBUG, message)
}

deleteTextFile(textFile) {
  FileDelete, %textFile%
  message := "FileDelete() " (ErrorLevel = 0 ? "SUCCEED" : "FAILED ") " " textFile
  writeLogFile(INFO, A_ThisFunc, A_LineNumber, message)
  showToolTip(DEBUG, message)
}

;-------------------------------------------------------------------------------
; common functions
;-------------------------------------------------------------------------------

runAsAdmin() {
  message := "A_IsAdmin " (A_IsAdmin = 1 ? "SUCCEED" : "FAILED ")
  writeLogFile(DEBUG, A_ThisFunc, A_LineNumber, message)
  showToolTip(DEBUG, message)
  if A_IsAdmin
    return
  Run *RunAs "%A_ScriptFullPath%"
  ExitApp
}

writeLogFile(level, functionName, lineNumber, message) {
  if (LOG_LEVEL > level)
    return
  ;write log file
  levelName := ""
  switch (level) {
    case TRACE:
      levelName := "TRACE"
    case DEBUG:
      levelName := "DEBUG"
    case INFO:
      levelName := "INFO "
    case WARN:
      levelName := "WARN "
    case ERROR:
      levelName := "ERROR"
    default:
  }
  FileAppend, % A_YYYY "-" A_MM  "-" A_DD " " A_Hour ":" A_Min ":" A_Sec "." A_MSec " " levelName " " A_ScriptName "." functionName "() Line " lineNumber " " message "`n", %LOG_FILE%
}

removeLogFile(thresholdSize) {
  FileGetSize, fileSize, %LOG_FILE%, K
  message := "FileGetSize() " (ErrorLevel = 0 ? "SUCCEED" : "FAILED ") " " fileSize "KB " LOG_FILE
  writeLogFile(DEBUG, A_ThisFunc, A_LineNumber, message)
  if (fileSize < thresholdSize)
    return
  FileDelete, %LOG_FILE%
  message := "FileDelete() " (ErrorLevel = 0 ? "SUCCEED" : "FAILED ") " " LOG_FILE
  writeLogFile(DEBUG, A_ThisFunc, A_LineNumber, message)
  showToolTip(DEBUG, message)
}

showToolTip(level, message) {
  if (LOG_LEVEL > level)
    return
  ToolTip, %message%, 5, 5
  SetTimer, removeTooltipTimer, -7000
}

removeTooltipTimer:
{
  ToolTip
  return
}

initHotkey(description) {
  if GetKeyState("Ctrl") {
    Send, {Ctrl Up}
    Sleep, 1
  }
  if GetKeyState("Alt") {
    Send, {Alt Up}
    Sleep, 1
  }
  if GetKeyState("Shift") {
    Send, {Shift Up}
    Sleep, 1
  }
  if GetKeyState("LButton") {
    Send, {LButton Up}
    Sleep, 1
  }
  if GetKeyState("RButton") {
    Send, {RButton Up}
    Sleep, 1
  }
  KeyWait, Ctrl
  KeyWait, Alt
  KeyWait, Shift
  Sleep, 20
  showToolTip(INFO, A_ScriptName "." description)
}

;playBeep(1, 7902, 80) ;SUCCEED
;playBeep(1, 2489, 80) ;FAILED
playBeep(times, freq, dur) {
  loop, % times {
    SoundBeep, freq, dur
    Sleep, 10
  }
}

;-------------------------------------------------------------------------------
; library functions
;-------------------------------------------------------------------------------

getMouseCursorRect(ByRef startX, ByRef startY, ByRef width, ByRef height) {
  ;Mask Screen
  Gui, Color, FFFFFF
  Gui +LastFound
  WinSet, Transparent, 50
  Gui, -Caption
  Gui, +AlwaysOnTop
  Gui, Show, x0 y0 h%A_ScreenHeight% w%A_ScreenWidth%, "AutoHotkeySnapshotApp"
  ;Drag Mouse
  CoordMode, Mouse, Screen
  WinGet, hw_frame_m, ID, "AutoHotkeySnapshotApp"
  hdc_frame_m := DllCall( "GetDC", "uint", hw_frame_m)
  KeyWait, LButton, D
  MouseGetPos, scanStartX, scanStartY
  Loop {
    Sleep, 10
    KeyIsDown := GetKeyState("LButton")
    if (KeyIsDown = 1) {
      MouseGetPos, scanX, scanY
      DllCall( "gdi32.dll\Rectangle", "uint", hdc_frame_m, "int", 0, "int", 0, "int", A_ScreenWidth, "int", A_ScreenWidth)
      DllCall( "gdi32.dll\Rectangle", "uint", hdc_frame_m, "int", scanStartX, "int", scanStartY, "int", scanX, "int", scanY)
    } else {
      break
    }
  }
  ;KeyWait, LButton, U
  MouseGetPos, scanEndX, scanEndY
  Gui Destroy
  if (scanStartX < scanEndX) {
    startX := scanStartX
    width := scanEndX - scanStartX
  } else {
    startX := scanEndX
    width := scanStartX - scanEndX
  }
  if (scanStartY < scanEndY) {
    startY := scanStartY
    height := scanEndY - scanStartY
  } else {
    startY := scanEndY
    height := scanStartY - scanEndY
  }
  CoordMode, Mouse, Client
  message := "getMouseCursorRect() " startX ", " startY ", " width ", " height
  writeLogFile(INFO, A_ThisFunc, A_LineNumber, message)
  showToolTip(DEBUG, message)
}

setCaptureImageFile(startX, startY, width, height, fileName) {
  startTime := A_TickCount
  pToken := Gdip_StartUp()
  pArg := startX . "|" . startY . "|" . width . "|" . height
  pBitmap := Gdip_BitmapFromScreen(pArg)
  Gdip_SaveBitmapToFile(pBitmap, fileName)
  Gdip_DisposeImage(pBitmap)
  Gdip_Shutdown(pToken)
  endTime := A_TickCount - startTime
  message := "Gdip_SaveBitmapToFile() " Round(endTime) "ms"
  writeLogFile(DEBUG, A_ThisFunc, A_LineNumber, message)
  message := "setCaptureImageFile() " (ErrorLevel = 0 ? "SUCCEED" : "FAILED ") " " startX ", " startY ", " width ", " height ", " fileName
  writeLogFile(INFO, A_ThisFunc, A_LineNumber, message)
  showToolTip(DEBUG, message)
}
