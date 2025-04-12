#Include ScriptAnalyzer_InternalConfig.ahk

class ScriptAnalyzer {
    static __New() {
        if this.Prototype.__Class == 'ScriptAnalyzer' {
            this.__Item := MapEx()
            this.__Item.CaseSense := ScriptAnalyzer_InternalConfig.ScriptAnalyzerCollectionCaseSense
        }
    }

    ;@region Constructor
    __New(Config?) {
        Config := this.Config := ScriptAnalyzer.Configuration(Config ?? {})
        if !Config.NameScript {
            Config.NameScript := ScriptAnalyzer.GetIndex()
        }
        this.Prototypes := MapEx()
        this.NameScript := Config.NameScript
        this.PrepareText()
        for NameCollection in Config.Components {
            this.DefineProp(NameCollection, { Value: Collection(this.Name, NameCollection
            , Type(Constructor) == 'String' ? GetObjectFromString(Constructor, Config.ComponentsWith || unset) : Constructor) })
        }
        this.Mapper := ScriptAnalyzer.Mapper(this.Name)
    }
    ;@endregion

    ;@region StaticMethods
    static GetIndex() {
        return ++this.__Index
    }

    static GetReplacement(NameCollection, IndexComponent, &OutLenReplacement?) {
        Replacement := SA_Replacement '-' NameCollection '-' IndexComponent '-' SA_Replacement
        OutLenReplacement := StrLen(Replacement)
        return Replacement
    }

    static ParseReplacement(ReplacementObj, &OutCollection?, &OutIndex?) {
        if !RegExMatch(ReplacementObj.Replacement, SA_Pattern_Replacement, &MatchReplacement) {
            throw SA_Error(ValueError(), A_ThisFunc, A_LineFile, A_LineNumber, 'Invalid replacement text.'
            , ReplacementObj.Replacement)
        }
        OutCollection := MatchReplacement['collection']
        OutIndex := MatchReplacement['index']
        return MatchReplacement
    }

    static GetPath(Script, Path) {
        return StrReplace(StrReplace(StrReplace(Path, '%l%', Script.Config.Language)
        , '%n%', Script.Config.Name), '%t%', FormatTime(A_Now, Script.Config.TimestampFormat))
    }

    static Get(Name) => this.__Item.Get(Name)
    static Delete(Name) => this.__Item.Delete(Name)
    static Set(Name, Value) => this.__Item.Set(Name, Value)
    static Clear() => this.__Item.Clear()
    static Clone() => this.__Item.Clone()
    static Has(Name) => this.__Item.Has(Name)
    static __Enum(VarCount) => this.__Item.__Enum(VarCount)
    ;@endregion

    ;@region StaticProps
    static __Index := 0
    static Index {
        Get => this.__Index
        Set => this.__Index := Value
    }
    static Count => this.__Item.Count
    static Capacity {
        Get => this.__Item.Capacity
        Set => this.__Item.Capacity := Value
    }
    static CaseSense => this.__Item.CaseSense
    static Default {
        Get => this.__Item.Default
        Set => this.__Item.Default := Value
    }
    ;@endregion

    ;@region Inst.Methods



    PrepareText() {
        this.__Value := FileRead(this.Path, this.Encoding)
        this.LenOriginal := StrLen(this.__Value)
        this.__Value := RegExReplace(this.__Value, '(?<=\s|^)`'`'', ScriptAnalyzer.GetReplacement('String', 1))
        this.__Value := RegExReplace(this.__Value, '(?<=\s|^)""', ScriptAnalyzer.GetReplacement('String', 2), &CountDoubleQuote)

        ; Remove consecutive pairs of quotes
    }
    ;@endregion

    ;@region Inst.Props

    ;@endregion

    ;@region Config
    /**
     * @class
     * @description - Handles the input configuration.
     */
    class Configuration {
        static Default := {
            PathFileScript: ''
          , PathFileScriptCleaned: ''
          , PathUserData: ''
          , PathOutCleanFile: '%l%_%n%_%t%_cleaned-script.txt'
          , PathOutJson: '%l%_%n%_%t%.json'
          , Encoding: ''
          , Language: 'Ahk'
          , NameScript: ''
          , TimestampFormat: 'yyyy-MM-dd_HH-mm-ss'

        }

        /**
         * @description - Sets the base object such that the values are used in this priority order:
         * - 1: The input object.
         * - 2: The configuration object (if present).
         * - 3: The default object.
         * @param {Object} Configuration - The input object.
         * @return {Object} - The same input object.
         */
        static Call(Configuration) {
            if IsSet(ScriptAnalyzerConfig) {
                ObjSetBase(ScriptAnalyzerConfig, ScriptAnalyzer.Configuration.Default)
                ObjSetBase(Configuration, ScriptAnalyzerConfig)
            } else {
                ObjSetBase(Configuration, ScriptAnalyzer.Configuration.Default)
            }
            return Configuration
        }
    }
    ;@endregion

    ;@region Base
    class Base {
        Script => ScriptAnalyzer.Get(this.Parent)
    }
    ;@endregion
}
