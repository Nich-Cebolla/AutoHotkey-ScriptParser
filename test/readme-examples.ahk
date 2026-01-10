
#include ..\src\VENV.ahk

if !A_IsCompiled && A_ScriptFullPath == A_LineFile {
    ReadmeExamples()
}

class ReadmeExamples {
    static Call() {
        this.MyScript()
    }
    static MyScript() {
        path := A_Temp '\ScriptParser-readme-example.ahk'
        f := FileOpen(path, 'w')
        f.Write('
        (
        class MyClass {
            /**
             * @param {Type} param1 - info
             * @param {Type} [param2] - info
             * @returns {Type}
             */
            static Method(param1, param2 := "value") {

            }
            static Property {
                Get {
                }
                Set {
                }
            }
            /**
             * @classdesc - MyClass info...
             * @param {Type} [params] - info
             */
            __New(params*) {

            }
            ; details about Property
            Property := "Value"
        }

        MyFunc(param1, param2, params*) {

        }
        )')
        f.Close()

        script := ScriptParser({ Path: path })
        collection := script.Collection
        _myClass := collection.Class.Get('MyClass')
        OutputDebug(_myClass.Text '`n') ; Prints the entire MyClass text
        _method := _myClass.Children.Get('StaticMethod').Get('Method')
        params := _method.Params
        OutputDebug(params[1].Symbol '`n') ; param1
        OutputDebug(params[2].DefaultValue '`n') ; "value"
        OutputDebug(_method.Comment.TextComment '`n')   ; @param {Type} param1 - info
                                                        ; @param {Type} [param2] - info
                                                        ; @returns {Type}
        OutputDebug(_method.TextBody '`n') ; Prints the body of MyClass.Method (text between curly braces)
        if FileExist(path) {
            FileDelete(path)
        }
    }
}
