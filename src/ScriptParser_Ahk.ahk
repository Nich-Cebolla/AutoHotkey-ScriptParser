

class ScriptParser_Ahk {

    class Component {

        class Class extends ScriptParser_Ahk.Component.Variable {
            Init(Match) {
                this.Indent := Match.Len['indent']
                this.Extends := Match['super']
            }

            static __New() {
                this.DeleteProp('__New')
                Proto := this.Prototype
                for Prop in ['InstanceMethods', 'InstanceProperties', 'StaticMethods', 'StaticProperties'] {
                    Proto.DefineProp(Prop, { Value: '' })
                }
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
                if Match['arrow'] {
                    this.Arrow := true
                }
                if Match['static'] {
                    this.Static := true
                }
                if !Match['arrow'] && !Match['assign'] {
                    if RegExMatch(s := SubStr(this.Script.Text, 1, this.PosEnd), SPP_ACCESSOR_GET, &Match, this.Pos) {
                        _Proc('Get')
                    }
                    if RegExMatch(s, SPP_ACCESSOR_SET, &Match, this.Pos) {
                        _Proc('Set')
                    }
                }
                if !this.Static {
                    if this.Arrow || (this.Children && (this.Children.Has('Getter') || this.Children.Has('Setter'))) {
                        Path := this.Name
                        this.DefineProp('Name', { Value: SubStr(Path, 1, InStr(Path, '.')) 'Prototype.' SubStr(Path, InStr(Path, '.', , , -1) + 1) })
                    }
                }

                _Proc(Name) {
                    if Match['arrow'] {
                        CS := ScriptParser_ContinuationSection(
                            StrPtr(this.Script.Content)
                          , Match.Pos['text']
                          , Match['arrow'] ? '=>' : ':='
                        )
                    } else {
                        CS := Match
                    }
                    if Name == 'Get' {
                        this.Script.Stack.In(this.Script, Name, CS, this.Script.CollectionList[SPC_GETTER].Constructor, Match)
                    } else {
                        this.Script.Stack.In(this.Script, Name, CS, this.Script.CollectionList[SPC_SETTER].Constructor, Match)
                    }
                    this.Script.Stack.Out()
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
                if Match['inner'] {
                    this.Params := ScriptParser_ParamsList(Match['inner'])
                }
                if Match['arrow'] {
                    this.Arrow := true
                }
            }
            GetParams(Match) {
                if Match.inner {
                    this.Params := ScriptParser_ParamsList(Match['inner'])
                }
            }
        }

        class Jsdoc extends ScriptParser_Ahk.Component.Comment {

            GetCommentText(JoinChar := '`r`n') {
                return RegExReplace(this.Removed.Match['comment'], '\R?[ \t]*?\* ?', JoinChar)
            }
            Parse(EndOfLine := '`r`n') {
                if this.HasOwnProp('Tags') {
                    return this.Tags.ToString(EndOfLine)
                } else {
                    tags := this.Tags := ScriptParser_JsdocTagsCollection()
                    lines := StrSplit(RegExReplace(this.TextOwnFull, '\R', '`n'), '`n', '`s`t')
                    i := 1

                }
            }
        }

        class CommentSingleLine extends ScriptParser_Ahk.Component.Comment {

            GetCommentText() {
                return this.Removed.Match['comment']
            }
            TextComment => this.GetCommentText()
        }

        class CommentBlock extends ScriptParser_Ahk.Component.Comment {

            GetCommentText(JoinChar := '`r`n') {
                return RegExReplace(this.TextFull, '\R?.*?(?<=\s|^);[ \t]*', JoinChar)
            }
        }

        class CommentMultiLine extends ScriptParser_Ahk.Component.Comment {

            GetCommentText(JoinChar := '`r`n') {
                return RegExReplace(this.Removed.Match['comment'], '\R?[ \t]*', JoinChar)
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
