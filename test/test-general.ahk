#include ..\config\VENV.ahk
#include <Stringify>
#include <QuickSort_V1.0.0>


test()


class test {
    static PathIn := 'test-content\test-content-text-values.ahk'
    , PathOut := A_MyDocuments '\test-ScriptParser-output.json'
    , PathOutRecreate := A_MyDocuments '\test-ScriptParser-output-recreate.ahk'

    static Call() {
        this.Problems := []
        this.Position()
        OutputDebug('`nPosition is done. Problems: ' this.Problems.Length)
        ; this.RecreateFile()

        if this.Problems.Length {
            this.WriteOutProblems()
        } else {
            this.WriteOut('No problems.')
        }
    }

    static Position() {
        this.EstablishControls()
        Script := this.Script := ScriptParser({ PathIn: this.PathIn })
        Script.RemoveStringsAndComments()
        Script.ParseClass()
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

            _Special1(obj) {
                Component := Script.GetCollection(obj.Collection).Get(obj.Item)
                Setter := Component.Set
                if Component.Get.Pos !== obj.Control.Pos['get'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.Get.Pos (' Component.Get.Pos ') !== obj.Control.Pos[`'get`'] (' obj.Control.Pos['get'] ')', { Text: Component.TextFull, Control: obj.Control[0], Obj: obj })
                }
                if Component.Get.PosEnd !== obj.Control.Pos['get'] + obj.Control.Len['get'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.Get.PosEnd (' Component.Get.PosEnd ') !== obj.Control.Pos[`'get`'] + obj.Control.Len[`'get`'] (' obj.Control.Pos['get'] + obj.Control.Len['get'] ')', { Text: Component.TextFull, Control: obj.Control[0], Obj: obj })
                }
                if Component.Set.Pos !== obj.Control.Pos['set'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.Set.Pos (' Component.Set.Pos ') !== obj.Control.Pos[`'set`'] (' obj.Control.Pos['set'] ')', { Text: Component.TextFull, Control: obj.Control[0], Obj: obj })
                }
                if Component.Set.PosBody !== obj.Control.Pos['setbody'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.Set.PosBody (' Component.Set.PosBody ') !== obj.Control.Pos[`'setbody`'] (' obj.Control.Pos['setbody'] ')', { Text: Component.TextFull, Control: obj.Control[0], Obj: obj })
                }
                if Component.Set.PosEnd !== obj.Control.Pos['set'] + obj.Control.Len['set'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.Set.PosEnd (' Component.Set.PosEnd ') !== obj.Control.Pos + obj.Control.Len (' obj.Control.Pos + obj.Control.Len ')', { Text: Component.TextFull, Control: obj.Control[0], Obj: obj })
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

    static AddProblem(Fn, Line, Msg, Obj?) {
        this.Problems.Push({ Fn: Fn, Line: Line, Message: Msg, Obj: Obj ?? unset })
    }


    static EstablishControls() {
        Content := this.Content := FileRead(this.PathIn)
        (Controls := this.Controls := []).Capacity := 20
        Controls.Push(
            { Name: 'GetPropsInfo param hint', Collection: 'Jsdoc', Item: 1, Control: _GetPattern('/\*\*[\w\W]+?\*/'), NoBody: true }
          , { Name: 'GetPropsInfo function', Collection: 'Function', Item: 'GetPropsInfo', Control: _GetPattern('GetPropsInfo\(.+(?<body>\{[\w\W]+?\R\})') }
          , { Name: 'PropsInfo class', Collection: 'Class', Item: 'PropsInfo', Control: _GetPattern('class PropsInfo (?<body>\{[\w\W]+?\R\})') }
          , {
                Name: 'FilterActive property', Collection: 'InstanceProperty', Item: 'PropsInfo.FilterActive', Special: 1
              , Control: _GetPattern('FilterActive (?<body>\{[\r\n]+ +(?<get>Get.+)[\r\n]+ +(?<set>Set (?<setbody>\{[\w\W]+? {8}\}))[\r\n]+ {4}\})')
            }
          , { Name: 'Proxy_Map', Collection: 'Class', Item: 'PropsInfo.Proxy_Map', Special: 2, Control: _GetPattern('class Proxy_Map extends Map (?<body>\{[\w\W]+?\R {4}\})') }
          , { Name: 'PropsInfoItem', Collection: 'Class', Item: 'PropsInfoItem', Control: _GetPattern('class PropsInfoItem (?<body>\{[\w\W]+?\R\})') }
        )

        for Name in ['FilterAdd', 'Dispose', '__FilterSwitchProps', 'GetFunc', '__SetAlt'] {
            Controls.Push({
                Name: Name, Collection: 'InstanceMethod'
                , Item: (A_Index <= 3 ? 'PropsInfo' : 'PropsInfoItem') '.' Name
                , Control: _GetPattern(' {4}\K' Name '\(.+?(?<body>\{[\w\W]+?\R {4}\})')
            })
        }
        _GetPattern(Pattern) {
            ; OutputDebug('`n' Pattern '`n')
            if !RegExMatch(Content, Pattern, &match) {
                throw Error('Match failed.', -1)
            }
            return match
        }
    }

    static RecreateFile() {
        Script := ScriptParser({ PathIn: this.PathIn })
        Script.RemoveStringsAndComments()
        Script.ParseClass()
        Str := ''
        SortFn := (a, b) => a.Pos - b.Pos
        Arr := []
        Arr.Capacity := Script.ComponentList.Count
        for id, Item in Script.ComponentList {
            Arr.Push(Item)
        }
        Arr := QuickSort(Arr, SortFn)
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
            if (Diff := Item.Pos - PosEnd) > 0 {
                Str .= Script.GetTextFull(PosEnd, Diff)
            } else if Diff < 0 {
                throw Error('Diff < 0', -1)
            }
            if Item.Removed {
                Str .= Item.Removed.Match['text']
            } else {
                Str .= Item.TextFull
            }
            OutputDebug('`n---------------------`n' Str)
        }
        f := FileOpen(this.PathOutRecreate, 'w')
        f.Write(Str)
        f.Close()
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
