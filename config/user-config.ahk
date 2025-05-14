
class ScriptParserConfig {
    static Name := 'Dev'
    , PathIn := '..\..\AutoHotkey-LibV2\inheritance\GetPropsInfo.ahk'
    ; , PathIn := '..\..\UIA_Viewer\UIA.ahk'
    , Language := Ahk
    , Capacity := 20000
    ; , StandardizeLineEnding := '`n'


    ; Minor configuration options
    , Capacity_Removed := 1000

    static __New() {
        if this.Prototype.__Class == 'ScriptParserConfig' {
            ObjSetBase(this, SP_Config.Default)
        }
    }
}
