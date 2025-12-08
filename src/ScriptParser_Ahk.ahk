

class ScriptParser_Ahk {

    class Component {

        class Class extends ScriptParser_Ahk.Component.Variable {
            Init(Match) {
                this.Indent := Match.Len['indent']
                this.Extends := Match['super']
            }
        }

        class StaticMethod extends ScriptParser_Ahk.Component.Method {
        }

        class InstanceMethod extends ScriptParser_Ahk.Component.Method {
        }

        class Method extends ScriptParser_Ahk.Component.Function {
            Init(Match) {
                if Match['static'] {
                    this.Static := true
                }
                if Match['arrow'] {
                    this.Arrow := true
                }
            }
        }

        class StaticProperty extends ScriptParser_Ahk.Component.Property {

        }

        class InstanceProperty extends ScriptParser_Ahk.Component.Property {

        }

        class Property extends ScriptParser_Ahk.Component.Function {
            static __New() {
                this.DeleteProp('__New')
                this.Prototype.DefineProp('Get', { Value: false })
                this.Prototype.DefineProp('Set', { Value: false })
            }

            Init(Match) {
                if Match['static'] {
                    this.Static := true
                }
                if Match['arrow'] {
                    this.Arrow := true
                    this.Get := true
                    this.Script.__Stack.In(this.Script, 'Get', Match, this.Script.__CollectionList[SPC_GETTER].__Constructor, Match)
                    this.Script.__Stack.Out()
                } else if !Match['assign'] {
                    if RegExMatch(s := SubStr(this.Script.__Text, 1, this.PosEnd), SPP_ACCESSOR_GET, &Match, this.Pos) {
                        _Proc('Get')
                    }
                    if RegExMatch(s, SPP_ACCESSOR_SET, &Match, this.Pos) {
                        _Proc('Set')
                    }
                }
                if !this.Static {
                    if this.Arrow || (this.Children && (this.Children.Has('Getter') || this.Children.Has('Setter'))) {
                        Path := this.Name
                        this.DefineProp('Name', { Value: SubStr(Path, 1, InStr(Path, '.', , , -1)) 'Prototype.' SubStr(Path, InStr(Path, '.', , , -1) + 1) })
                    }
                }

                return

                _Proc(Name) {
                    if Match['arrow'] {
                        CS := ScriptParser_ContinuationSection(
                            StrPtr(this.Script.__Content)
                          , Match.Pos['text']
                          , Match['arrow'] ? '=>' : ':='
                        )
                    } else {
                        CS := Match
                    }
                    if Name == 'Get' {
                        this.Get := true
                        this.Script.__Stack.In(this.Script, Name, CS, this.Script.__CollectionList[SPC_GETTER].__Constructor, Match)
                    } else {
                        this.Set := true
                        this.Script.__Stack.In(this.Script, Name, CS, this.Script.__CollectionList[SPC_SETTER].__Constructor, Match)
                    }
                    this.Script.__Stack.Out()
                }
            }
        }

        class Getter extends ScriptParser_Ahk.Component.Function {
            Init(Match) {
                if Match['arrow'] {
                    this.Arrow := true
                }
            }
        }

        class Setter extends ScriptParser_Ahk.Component.Function {
            Init(Match) {
                if Match['arrow'] {
                    this.Arrow := true
                }
            }
        }

        class Function extends ScriptParser_Ahk.Component.Variable {
            static __New() {
                this.DeleteProp('__New')
                this.Prototype.DefineProp('Arrow', { Value: false })
                this.Prototype.DefineProp('Static', { Value: false })
                this.Prototype.DefineProp('Params', { Value: '' })
            }
            Init(Match) {
                this.GetParams(Match)
                if Match['arrow'] {
                    this.Arrow := true
                }
            }
            GetParams(Match) {
                if Match.inner {
                    if InStr(this.__Class, 'Property') {
                        if !RegExMatch(this.Text, SPP_BRACKET_SQUARE, &MatchBracket) {
                            throw Error('Failed to match with bracket pattern.')
                        }
                    } else if !RegExMatch(this.Text, SPP_BRACKET_ROUND, &MatchBracket) {
                        throw Error('Failed to match with bracket pattern.')
                    }
                    this.Params := ScriptParser_ParamsList(SubStr(MatchBracket[0], 2, -1))
                }
            }
        }

        class Jsdoc extends ScriptParser_Ahk.Component.Comment {

            GetCommentText(JoinChar := '`r`n') {
                return Trim(RegExReplace(this.Match['comment'], '\R?[ \t]*?\* ?', JoinChar), '`r`n')
            }
        }

        class CommentSingleLine extends ScriptParser_Ahk.Component.Comment {

            GetCommentText() {
                return this.Match['comment']
            }
            TextComment => this.GetCommentText()
        }

        class CommentBlock extends ScriptParser_Ahk.Component.Comment {

            GetCommentText(JoinChar := '`r`n') {
                return Trim(RegExReplace(RegExReplace(this.Text, '^[ \t]*;[ \t]*', ''), '\R[ \t]*;[ \t]*', JoinChar), '`r`n')
            }
        }

        class CommentMultiLine extends ScriptParser_Ahk.Component.Comment {

            GetCommentText(JoinChar := '`r`n') {
                return Trim(RegExReplace(this.Match['comment'], '\R[ \t]*', JoinChar), '`r`n')
            }
        }

        class Comment extends ScriptParser_ComponentBase {
            GetCommentText(*) {
                throw Error('This method must be overridden by the inheritor.', , A_ThisFunc)
            }
            TextComment[JoinChar := '`r`n'] => this.GetCommentText(JoinChar)
        }

        class String extends ScriptParser_ComponentBase {
        }

        class Variable extends ScriptParser_ComponentBase {
        }
    }

    static __ThrowInvalidParamCount(Extra) {
        throw ValueError('Invalid number of parameters.', -2, Extra)
    }
    static __GetPath() => A_LineFile
}
