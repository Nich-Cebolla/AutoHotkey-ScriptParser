
; https://github.com/Nich-Cebolla/Stringify-ahk/blob/main/Object.Prototype.StringifyA.ahk
#include <Object.Prototype.StringifyA_V1.0.0>


class DevConfig {
    static PathIn := 'test-content\test-content-GetPropsInfo.ahk'
    , PathOut := A_MyDocuments '\test-ScriptParser-output.json'

    , Title := 'ScriptParser.Dev'
    , MarginX := 10
    , MarginY := 10
    , FontSize := 11
    , FontStandard := 'Aptos,Segoe UI,Roboto'
    , FontMono := 'Mono,Ubuntu Mono,Chivo Mono'
    , Methods := {
        Pos: { X: 10, Y: 10 }
      , ParamEditWidth: 60
    }
    , LVScripts := {
        Pos: {
            X: this.Methods.Pos.X
          , Y: { Control: '.Methods[-1].Button', Which: 'y', Add: 'h', AddMargin: true, Offset: 15 }
        }
      , Headers: ['Name', 'Path']
      , Opt: 'Checked'
      , W: 400
      , R: 5
    }
    , EditResults := {
        Pos: {
            X: { Control: '.LVScripts', Which: 'x', Add: 'w', AddMargin: true, Offset: 15 }
          , Y: { Control: '.LVScripts', Which: 'y' }
        }
      , W: 500
      , R:

    }
}
