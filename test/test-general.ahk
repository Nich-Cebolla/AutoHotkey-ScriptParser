
#include ..\src\venv.ahk

if !A_IsCompiled && A_LineFile == A_ScriptFullPath {
    test()
}

class test {
    static Path := 'test-content\test-content-GetPropsInfo.ahk'
    , PathOut := A_Temp '\test-ScriptParser-output.json'

    static AddProblem(Fn, Line, Msg, Obj?) {
        this.Problems.Push({ Fn: Fn, Line: Line, Message: Msg, Obj: Obj ?? unset })
    }
    static Call(WriteProblems := false) {
        this.Problems := []
        this.Position()
        result := this.TextFull(WriteProblems)
        this.Components()

        if this.Problems.Length {
            OutputDebug(A_ScriptName ' : complete with ' this.Problems.Length ' problems.`n')
            if WriteProblems {
                this.WriteOutProblems(result)
                Run(this.PathOut)
            } else {
                OutputDebug(this.GetProblems() '`n')
            }
        } else {
            OutputDebug(A_ScriptName ' : complete.`n')
        }
    }
    static Components() {
        Script := this.GetScript()
    }
    static EstablishControls() {
        this.GetContent(&Content)
        (Controls := this.Controls := []).Capacity := 20
        Controls.Push(
            { Name: 'GetPropsInfo param hint', Collection: 'Jsdoc', Item: 'GetPropsInfo.Jsdoc', Control: _Get('/\*\*[\w\W]+?\*/'), NoBody: true }
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
            if !RegExMatch(Content, Pattern, &match) {
                throw Error('Match failed.')
            }
            return match
        }
    }
    static GetContent(&Content) {
        Content := FileRead(this.Path)
    }
    static GetDiffs(&Expected, &Actual, Script) {
        MaxLineSearch := 3
        Diffs := []
        splita := StrSplit(Actual, Script.EndOfLine)
        splite := StrSplit(Expected, Script.EndOfLine)
        Diffs.Capacity := splita.Length
        EqualCount := splita.Length == splite.Length
        la := eol := 1
        loop {
            if splita[la] == splite[eol] {
                Diffs.Push({ Result: 0, LineActual: la, LineExpected: eol, Text: splita[la] })
                la++
                eol++
            } else {
                if !_Seek() {
                    Diffs.Push({ Result: 2, LineActual: la, LineExpected: eol, Actual: splita[la], Expected: splite[eol] })
                    la++
                    eol++
                }
            }
        }
        _Seek() {
            templa := la
            loop MaxLineSearch {
                if splita[++templa] == splite[eol] {
                    missing := []
                    loop templa - la {
                        missing.Push(splita[++la])
                    }
                    Diffs.Push({ Result: 1, LineActual: la, LineExpected: eol, Text: splita[la], Missing: missing })
                    la++
                    eol++
                    return 1
                }
            }
        }
        return Diffs
    }
    static GetProblems() {
        s := ''
        i := '    '
        n := 0
        for problem in this.Problems {
            s .= 'Problem ' A_Index '`n'
            _Proc(problem)
        }

        return s

        _Proc(obj) {
            ++n
            for prop, val in obj.OwnProps() {
                loop n {
                    s .= i
                }
                s .= prop
                if IsObject(val) {
                    s .= ' :: `n'
                    _Proc(val)
                } else {
                    s .=  ': ' val '`n'
                }
            }
            --n
        }
    }
    static GetScript() {
        Script := this.Script := ScriptParser({ Path: this.Path, DeferProcess: true })
        Script.RemoveStringsAndComments()
        Script.ParseClass()
        return Script
    }
    static Position() {
        this.EstablishControls()
        Script := this.GetScript()
        Script.AssociateComments()
        Script.__CollectionList[SPC_JSDOC].__Process()
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
                this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.Pos (' Component.Pos ') !== obj.Control.Pos (' obj.Control.Pos ')', { Text: Component.Text, Control: obj.Control[0], Obj: obj })
            }
            if Component.Length !== obj.Control.Len {
                this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.Length (' Component.Length ') !== obj.Control.Len (' obj.Control.Len ')', { Text: Component.Text, Control: obj.Control[0], Obj: obj })
            }
            if !obj.HasOwnProp('NoBody') {
                if Component.PosBody !== obj.Control.Pos['body'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.PosBody (' Component.PosBody ') !== obj.Control.Pos[`'body`'] (' obj.Control.Pos['body'] ')', { Text: Component.Text, Control: obj.Control[0], Obj: obj })
                }
                if Component.LenBody !== obj.Control.Len['body'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.LenBody (' Component.LenBody ') !== obj.Control.Len[`'body`'] (' obj.Control.Len['body'] ')', { Text: Component.Text, Control: obj.Control[0], Obj: obj })
                }
            }
            OutputDebug('Position is done. Problems: ' this.Problems.Length '`n')

            return

            _Special1(obj) {
                Component := Script.GetCollection(obj.Collection).Get(obj.Item)
                Setter := Component.Children['Setter'][obj.Item '.Set']
                Getter := Component.Children['Getter'][obj.Item '.Get']
                if Getter.Pos !== obj.Control.Pos['get'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Getter.Pos (' Getter.Pos ') !== obj.Control.Pos[`'get`'] (' obj.Control.Pos['get'] ')', { Text: Component.Text, Control: obj.Control[0], Obj: obj })
                }
                if Getter.PosEnd !== obj.Control.Pos['get'] + obj.Control.Len['get'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Getter.PosEnd (' Getter.PosEnd ') !== obj.Control.Pos[`'get`'] + obj.Control.Len[`'get`'] (' obj.Control.Pos['get'] + obj.Control.Len['get'] ')', { Text: Component.Text, Control: obj.Control[0], Obj: obj })
                }
                if Setter.Pos !== obj.Control.Pos['set'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Setter.Pos (' Setter.Pos ') !== obj.Control.Pos[`'set`'] (' obj.Control.Pos['set'] ')', { Text: Component.Text, Control: obj.Control[0], Obj: obj })
                }
                if Setter.PosBody !== obj.Control.Pos['setbody'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Setter.PosBody (' Setter.PosBody ') !== obj.Control.Pos[`'setbody`'] (' obj.Control.Pos['setbody'] ')', { Text: Component.Text, Control: obj.Control[0], Obj: obj })
                }
                if Setter.PosEnd !== obj.Control.Pos['set'] + obj.Control.Len['set'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Setter.PosEnd (' Setter.PosEnd ') !== obj.Control.Pos + obj.Control.Len (' obj.Control.Pos + obj.Control.Len ')', { Text: Component.Text, Control: obj.Control[0], Obj: obj })
                }
            }

            _Special2(obj) {
                Component := Script.GetCollection(obj.Collection).Get(obj.Item)
                if Component.Pos !== obj.Control.Pos {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.Pos (' Component.Pos ') !== obj.Control.Pos (' obj.Control.Pos ')', { Text: Component.Text, Control: obj.Control[0], Obj: obj })
                }
                if Component.Length !== obj.Control.Len {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.Length (' Component.Length ') !== obj.Control.Len (' obj.Control.Len ')', { Text: Component.Text, Control: obj.Control[0], Obj: obj })
                }
                if Component.PosBody !== obj.Control.Pos['body'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.PosBody (' Component.PosBody ') !== obj.Control.Pos[`'body`'] (' obj.Control.Pos['body'] ')', { Text: Component.Text, Control: obj.Control[0], Obj: obj })
                }
                if Component.LenBody !== obj.Control.Len['body'] {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.LenBody (' Component.LenBody ') !== obj.Control.Len[`'body`'] (' obj.Control.Len['body'] ')', { Text: Component.Text, Control: obj.Control[0], Obj: obj })
                }
                if Component.Extends !== 'Map' {
                    this.AddProblem(A_ThisFunc, A_LineNumber, 'Component.Extends (' Component.Extends ') !== "Map"', { Text: Component.Text, Control: obj.Control[0], Obj: obj })
                }
            }
        }
    }
    static TextFull(WriteProblems := false) {
        Script := this.GetScript()
        this.GetContent(&Content)
        if (txt := Script.Text) !== Content {
            if WriteProblems {
                f := FileOpen(this.PathOut, 'w')
                f.Write(txt '`n`n`n')
                f.Close()
            }
            this.AddProblem(A_ThisFunc, A_LineNumber, 'Script.Text !== Content', { LenTextFull: StrLen(txt), LenContent: StrLen(Content), Diffs: this.GetDiffs(&Content, &txt, Script) })
            OutputDebug('TextFull is done. Problem: Script.Text !== Content`n')
            return 1
        } else {
            OutputDebug('TextFull is done. Problems: 0`n')
            return 0
        }
    }
    static WriteOutProblems(append := false) {
        f := FileOpen(this.PathOut, append ? 'a' : 'w')
        f.Write(this.GetProblems())
        f.Close()
    }
    static WriteOut(Str) {
        f := FileOpen(this.PathOut, 'w')
        f.Write(Str)
        f.Close()
    }
}
