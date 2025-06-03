#include ..\.dev\user-config.ahk
#include <Stringify>
#include <QuickSort_V1.0.0>


test()


class test {
    static PathIn := 'test-content\test-content-GetPropsInfo.ahk'
    , PathOut := A_MyDocuments '\test-ScriptParser-output.json'
    , PathOutRecreate := A_MyDocuments '\test-ScriptParser-output-recreate.ahk'
    , PathOutTextFull := A_MyDocuments '\test-ScriptParser-output-TextFull.ahk'

    static AddProblem(Fn, Line, Msg, Obj?) {
        this.Problems.Push({ Fn: Fn, Line: Line, Message: Msg, Obj: Obj ?? unset })
    }

    static Call() {
        this.Problems := []
        this.Position()
        this.TextFull()
        this.Components()
        ; RecreateFile is not working
        ; this.RecreateFile()

        if this.Problems.Length {
            this.WriteOutProblems()
        } else {
            ; this.WriteOut('No problems.')
        }
    }

    static Components() {
        Script := this.GetScript()
    }

    static EstablishControls() {
        this.GetContent(&Content)
        (Controls := this.Controls := []).Capacity := 20
        Controls.Push(
            { Name: 'GetPropsInfo param hint', Collection: 'Jsdoc', Item: 1, Control: _Get('/\*\*[\w\W]+?\*/'), NoBody: true }
          , { Name: 'GetPropsInfo function', Collection: 'Function', Item: 'GetPropsInfo', Control: _Get('GetPropsInfo\(.+(?<body>\{[\w\W]+?\R\})') }
          , { Name: 'PropsInfo class', Collection: 'Class', Item: 'PropsInfo', Control: _Get('class PropsInfo (?<body>\{[\w\W]+?\R\})') }
          , {
                Name: 'FilterActive property', Collection: 'InstanceProperty', Item: 'PropsInfo.FilterActive', Special: 1
              , Control: _Get('FilterActive (?<body>\{[\r\n]+ +(?<get>Get.+)[\r\n]+ +(?<set>Set (?<setbody>\{[\w\W]+? {8}\}))[\r\n]+ {4}\})')
            }
          , { Name: 'Proxy_Map', Collection: 'Class', Item: 'PropsInfo.Proxy_Map', Special: 2, Control: _Get('class Proxy_Map extends Map (?<body>\{[\w\W]+?\R {4}\})') }
          , { Name: 'PropsInfoItem', Collection: 'Class', Item: 'PropsInfoItem', Control: _Get('class PropsInfoItem (?<body>\{[\w\W]+?\R\})') }
        )

        for Name in ['FilterAdd', 'Dispose', '__FilterSwitchProps', 'GetFunc', '__SetAlt'] {
            Controls.Push({
                Name: Name, Collection: 'InstanceMethod'
                , Item: (A_Index <= 3 ? 'PropsInfo' : 'PropsInfoItem') '.' Name
                , Control: _Get(' {4}\K' Name '\(.+?(?<body>\{[\w\W]+?\R {4}\})')
            })
        }
        _Get(Pattern) {
            ; OutputDebug('`n' Pattern '`n')
            if !RegExMatch(Content, Pattern, &match) {
                throw Error('Match failed.', -1)
            }
            return match
        }
    }

    static GetContent(&Content) {
        Content := FileRead(this.PathIn)
    }

    static GetDiffs(&Expected, &Actual, Script) {
        MaxLineSearch := 3
        Diffs := []
        splita := StrSplit(Actual, Script.LineEnding)
        splite := StrSplit(Expected, Script.LineEnding)
        Diffs.Capacity := splita.Length
        EqualCount := splita.Length == splite.Length
        la := le := 1
        loop {
            if splita[la] == splite[le] {
                Diffs.Push({ Result: 0, LineActual: la, LineExpected: le, Text: splita[la] })
                la++
                le++
            } else {
                if !_Seek() {
                    Diffs.Push({ Result: 2, LineActual: la, LineExpected: le, Actual: splita[la], Expected: splite[le] })
                la++
                le++
                }
            }
        }
        _Seek() {
            templa := la
            loop MaxLineSearch {
                if splita[++templa] == splite[le] {
                    missing := []
                    loop templa - la {
                        missing.Push(splita[++la])
                    }
                    Diffs.Push({ Result: 1, LineActual: la, LineExpected: le, Text: splita[la], Missing: missing })
                    la++
                    le++
                    return 1
                }
            }
        }
        return Diffs
    }

    static GetScript() {
        Script := this.Script := ScriptParser({ PathIn: this.PathIn })
        Script.RemoveStringsAndComments()
        Script.ParseClass()
        return Script
    }

    static Position() {
        this.EstablishControls()
        Script := this.GetScript()
        Controls := this.Controls
        for obj in Controls {
            if obj.HasOwnProp('Special') {
                switch obj.Special {
                    case 1: _Special1(obj)
                    case 2: _Special2(obj)
                }
                continue
            }
            Collection := Script.GetCollection(obj.Collection)
            if IsNumber(obj.Item) {
                i := 0
                for name, _Component in Collection {
                    if ++i == obj.Item {
                        Component := _Component
                        break
                    }
                }
            } else {
                Component := Collection.Get(obj.Item)
            }
            if Component.Pos !== obj.Control.Pos {
                this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.Pos (' Component.Pos ') !== obj.Control.Pos (' obj.Control.Pos ')', { Text: Component.TextFull, Control: obj.Control[0], Obj: obj })
            }
            if Component.Length !== obj.Control.Len {
                this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.Length (' Component.Length ') !== obj.Control.Len (' obj.Control.Len ')', { Text: Component.TextFull, Control: obj.Control[0], Obj: obj })
            }
            if !obj.HasOwnProp('NoBody') {
                if Component.PosBody !== obj.Control.Pos['body'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.PosBody (' Component.PosBody ') !== obj.Control.Pos[`'body`'] (' obj.Control.Pos['body'] ')', { Text: Component.TextFull, Control: obj.Control[0], Obj: obj })
                }
                if Component.LenBody !== obj.Control.Len['body'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.LenBody (' Component.LenBody ') !== obj.Control.Len[`'body`'] (' obj.Control.Len['body'] ')', { Text: Component.TextFull, Control: obj.Control[0], Obj: obj })
                }
            }
            OutputDebug('`nPosition is done. Problems: ' this.Problems.Length)

            return

            _Special1(obj) {
                Component := Script.GetCollection(obj.Collection).Get(obj.Item)
                Setter := Component.Children['Setter'][obj.Item '.Set']
                Getter := Component.Children['Getter'][obj.Item '.Get']
                if Getter.Pos !== obj.Control.Pos['get'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Getter.Pos (' Getter.Pos ') !== obj.Control.Pos[`'get`'] (' obj.Control.Pos['get'] ')', { Text: Component.TextFull, Control: obj.Control[0], Obj: obj })
                }
                if Getter.PosEnd !== obj.Control.Pos['get'] + obj.Control.Len['get'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Getter.PosEnd (' Getter.PosEnd ') !== obj.Control.Pos[`'get`'] + obj.Control.Len[`'get`'] (' obj.Control.Pos['get'] + obj.Control.Len['get'] ')', { Text: Component.TextFull, Control: obj.Control[0], Obj: obj })
                }
                if Setter.Pos !== obj.Control.Pos['set'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Setter.Pos (' Setter.Pos ') !== obj.Control.Pos[`'set`'] (' obj.Control.Pos['set'] ')', { Text: Component.TextFull, Control: obj.Control[0], Obj: obj })
                }
                if Setter.PosBody !== obj.Control.Pos['setbody'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Setter.PosBody (' Setter.PosBody ') !== obj.Control.Pos[`'setbody`'] (' obj.Control.Pos['setbody'] ')', { Text: Component.TextFull, Control: obj.Control[0], Obj: obj })
                }
                if Setter.PosEnd !== obj.Control.Pos['set'] + obj.Control.Len['set'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Setter.PosEnd (' Setter.PosEnd ') !== obj.Control.Pos + obj.Control.Len (' obj.Control.Pos + obj.Control.Len ')', { Text: Component.TextFull, Control: obj.Control[0], Obj: obj })
                }
            }

            _Special2(obj) {
                Component := Script.GetCollection(obj.Collection).Get(obj.Item)
                if Component.Pos !== obj.Control.Pos {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.Pos (' Component.Pos ') !== obj.Control.Pos (' obj.Control.Pos ')', { Text: Component.TextFull, Control: obj.Control[0], Obj: obj })
                }
                if Component.Length !== obj.Control.Len {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.Length (' Component.Length ') !== obj.Control.Len (' obj.Control.Len ')', { Text: Component.TextFull, Control: obj.Control[0], Obj: obj })
                }
                if Component.PosBody !== obj.Control.Pos['body'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.PosBody (' Component.PosBody ') !== obj.Control.Pos[`'body`'] (' obj.Control.Pos['body'] ')', { Text: Component.TextFull, Control: obj.Control[0], Obj: obj })
                }
                if Component.LenBody !== obj.Control.Len['body'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.LenBody (' Component.LenBody ') !== obj.Control.Len[`'body`'] (' obj.Control.Len['body'] ')', { Text: Component.TextFull, Control: obj.Control[0], Obj: obj })
                }
                if Component.Extends !== 'Map' {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.Extends (' Component.Extends ') !== "Map"', { Text: Component.TextFull, Control: obj.Control[0], Obj: obj })
                }
            }
        }
    }

    static RecreateFile() {
        ; Not currently working
        Script := this.GetScript()
        Str := ''
        Arr := []
        Arr.Capacity := Script.ComponentList.Count
        for id, Item in Script.ComponentList {
            Arr.Push(Item)
        }
        Arr := QuickSort(Arr, (a, b) => a.Pos - b.Pos)
        i := 1
        Item := Arr[i]
        if Item.Removed {
            Str .= Item.Removed.Match['text']
        } else {
            Str .= Item.TextFull
        }
        PosEnd := Item.PosEnd
        loop Arr.Length - 1 {
            Item := Arr[++i]
            if Item.Pos - PosEnd >= 0 {
                Str .= Script.GetTextFull(PosEnd + 1, Item.Pos - PosEnd - 1)
                if Item.Removed {
                    Str .= Item.Removed.Match['text']
                    ; OutputDebug('`n`n---------------------`n'  A_Index '`n' Item.Removed.Match['text'])
                } else {
                    Str .= Item.Text
                    ; OutputDebug('`n`n---------------------`n'  A_Index '`n' Item.TextFull)
                }
                ; OutputDebug('`n`n---------------------`n' A_Index '`n' Script.GetTextFull(PosEnd, Diff))
                PosEnd := Item.PosEnd
            } else {
                if Item.Removed {
                    ; OutputDebug('`n`n---------------------`n' A_Index ' Str:`n' Str)
                    ; OutputDebug('`n`n---------------------`n' A_Index ' Item.Removed.Match["text"]:`n' Item.Removed.Match['text'])
                    ; OutputDebug('`n`n---------------------`n' A_Index ' Item.Text:`n' Item.Text)
                    Str := SubStr(Str, 1, Item.Pos - 1) Item.Removed.Match['text'] SubStr(Str, Item.PosEnd + 1)
                } else {
                    ; OutputDebug('`n`n---------------------`n' A_Index ' Str:`n' Str)
                    ; OutputDebug('`n`n---------------------`n' A_Index ' Item.Text:`n' Item.Text)
                    Str := SubStr(Str, 1, Item.Pos - 1) Item.Text SubStr(Str, Item.PosEnd + 1)
                }
            }
            ; OutputDebug('`n---------------------`n' Str)
        }
        f := FileOpen(this.PathOutRecreate, 'w')
        f.Write(Str)
        f.Close()
    }

    static TextFull() {
        Script := this.GetScript()
        this.GetContent(&Content)
        if (txt := Script.TextFull) !== Content {
            f := FileOpen(this.PathOutTextFull, 'w')
            f.Write(txt)
            f.Close()
            this.AddProblem(A_ThisFunc, A_LineNumber, 'Script.TextFull !== Content', { LenTextFull: StrLen(txt), LenContent: StrLen(Content), Diffs: this.GetDiffs(&Content, &txt, Script) })
            OutputDebug('`nTextFull is done. Problem: Script.TextFull !== Content')
        } else {
            OutputDebug('`nTextFull is done. Problems: 0')
        }
    }

    static WriteOutProblems() {
        f := FileOpen(this.PathOut, 'w')
        f.Write(Stringify(this.Problems))
        f.Close()
    }

    static WriteOut(Str) {
        f := FileOpen(this.PathOut, 'w')
        f.Write(Str)
        f.Close()
    }
}
