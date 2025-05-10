
; config
#include define.ahk
#include internal-config.ahk
#include user-config.ahk
#include enum.ahk


; lib
#include ..\lib
; #include GetMatchingBrace.ahk
; #include GetObjectFromString.ahk
#include ParseContinuationSection.ahk
#include MapEx.ahk
#include Object.Prototype.Stringify.ahk
; #include ParseJson.ahk
; #include QuickFind.ahk
; #include QuickSort.ahk
#include utilities.ahk
; #include DecodeUnicodeEscapeSequence.ahk
#include FillStr.ahk
; #include Get.ahk
#include ClassFactory.ahk
#include ParamsList.ahk

; src
#include ..\src
#include ScriptParser.ahk
#include Node.ahk
#include Stack.ahk
#include Ahk.ahk
#include ComponentCollection.ahk
#include ComponentBase.ahk

s := ScriptParser()
s.RemoveStringsAndComments()
; f := FileOpen('test-output.txt', 'w')
; f.Write(s.Content)
; f.Close()
s.ParseClass()

sleep 1
