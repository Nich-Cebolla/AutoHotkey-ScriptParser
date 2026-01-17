
class ScriptParser_ParamsList extends Array {
    /**
     * @class - Parses the parameters of a function definition.
     * @param {String} Str - The string that contains the parameters.
     * @returns {ScriptParser_ParamsList} - An array of `ScriptParser_ParamsList.Param` objects with properties
     * { Optional, Default, Symbol, Variadic, VarRef }.
     */
    __New(Str) {
        Brackets := ['{', '}', '[', ']', '(', ')']
        , Replacement := Chr(0xFFFD)
        Index := 0
        Replaced := []
        if SubStr(Str, 1, 1) == '(' {
            Str := SubStr(Str, 2, -1)
        }
        ; Extract all quoted strings and replace them with a unique identifier that will not interfere with pattern matching.
        while RegExMatch(Str, '(?<=[\s=:,&(.[?]|^)([`"`'])[\w\W]*?(?<!``)(?:````)*+\g{-1}', &Match) {
            Replaced.Push(Match)
            Str := StrReplace(Str, Match[0], _GetReplacement(), , , 1)
        }
        ; Extract bracketed text
        loop 3 {
            while RegExMatch(Str, Format('\{1}([^{1}\{2}]++|(?R))*\{2}', Brackets[A_Index * 2 - 1], Brackets[A_Index * 2]), &Match) {
                Replaced.Push(Match)
                Str := StrReplace(Str, Match[0], _GetReplacement(), , , 1)
            }
        }
        Split := StrSplit(Str, ',')
        this.Capacity := Split.Length
        for P in Split {
            _p := ScriptParser_ParamsList.Param(P)
            this.Push(_p)
            if _p.DefaultValue {
                while RegExMatch(_p.DefaultValue, Replacement '(\d+)' Replacement, &Match) {
                    _p.DefaultValue := StrReplace(_p.DefaultValue, Match[0], Trim(Replaced[Match[1]][0], '`s`t`r`n'))
                }
            }
            while RegExMatch(_p.Symbol, Replacement '(\d+)' Replacement, &Match) {
                _p.Symbol := StrReplace(_p.Symbol, Match[0], Trim(Replaced[Match[1]][0], '`s`t`r`n'))
            }
        }

        return

        _GetReplacement() {
            return Replacement (++Index) Replacement
        }
    }

    class Param {
        static __New() {
            this.DeleteProp('__New')
            Proto := this.Prototype
            for Prop in ['Optional', 'Default', 'Variadic', 'VarRef', 'DefaultValue'] {
                Proto.DefineProp(Prop, { Value: '' })
            }
        }
        __New(Str) {
            if pos := InStr(Str, ':=') {
                this.Optional := true
                this.Default := true
                this.Symbol := Trim(SubStr(Str, 1, pos - 1), '`s`t`r`n')
                this.DefaultValue := Trim(SubStr(Str, pos + 2), '`s`t`r`n')
            } else if InStr(Str, '?') {
                this.Optional := true
                this.Symbol := Trim(SubStr(Str, 1, InStr(Str, '?') - 1), '`s`t`r`n')
            } else if InStr(Str, '*') {
                this.Variadic := this.Optional := true
                this.Symbol := Trim(SubStr(Str, 1, InStr(Str, '*') - 1), '`s`t`r`n')
            } else {
                this.Symbol := Trim(Str, '`s`t`r`n')
            }
            if InStr(this.Symbol, '&') {
                this.VarRef := true
                this.Symbol := LTrim(this.Symbol, '&')
            }
        }
    }
}
