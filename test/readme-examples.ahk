
#include ..\src\VENV.ahk

ReadmeExamples()

class ReadmeExamples {
    static Call() {
        this.MyScript()
    }
    static MyScript() {
        sp := ScriptParser({ Path: "test-content\MyScript.ahk" })
        collection := sp.Collection
        _myScript := collection.Class.Get('MyClass')
        OutputDebug(_myScript.TextFull "`n") ; Prints the entire MyClass text
        _myMethod := _myScript.Children.Get("StaticMethod").Get("Method")
        params := _myMethod.Params
        OutputDebug(params[1].Symbol "`n") ; param1
        OutputDebug(params[2].DefaultValue "`n") ; "value"
        OutputDebug(_myMethod.Comment.TextComment "`n") ; @param {Type} param1 - info
                                                        ; @param {Type} [param2] - info
                                                        ; @returns {Type}
        OutputDebug(_myMethod.TextBodyFull "`n") ; Prints the body of MyMethod (text between curly braces)
    }
}
