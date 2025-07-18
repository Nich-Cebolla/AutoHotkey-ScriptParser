

class Ahk {

    class Component {

        class Class extends Ahk.Component.Variable {
            Init(Match) {
                this.Indent := Match.Len['indent']
                this.Extends := Match['super']
            }

            static __New() {
                if this.Prototype.__Class == 'Ahk.Component.Class' {
                    Proto := this.Prototype
                    for Prop in ['InstanceMethods', 'InstanceProperties', 'StaticMethods', 'StaticProperties'] {
                        Proto.DefineProp(Prop, { Value: '' })
                    }
                }
            }
        }

        class StaticMethod extends Ahk.Component.Method {
        }

        class InstanceMethod extends Ahk.Component.Method {
        }

        class Method extends Ahk.Component.Function {
            Init(Match) {
                if Match['static'] {
                    this.Static := true
                }
                if Match['arrow'] {
                    this.Arrow := true
                }
            }
        }

        class StaticProperty extends Ahk.Component.Property {

        }

        class InstanceProperty extends Ahk.Component.Property {

        }

        class Property extends Ahk.Component.Function {
            static __New() {
                if this.Prototype.__Class == 'Ahk.Component.Property' {
                    this.Prototype.DefineProp('Get', { Value: false })
                    this.Prototype.DefineProp('Set', { Value: false })
                }
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
                        CS := ContinuationSection(
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

        class Getter extends Ahk.Component.Function {
            Init(Match) {
                if Match['arrow'] {
                    this.Arrow := true
                }
            }
        }

        class Setter extends Ahk.Component.Function {
            Init(Match) {
                if Match['arrow'] {
                    this.Arrow := true
                }
            }
        }

        class Function extends Ahk.Component.Variable {
            static __New() {
                if this.Prototype.__Class == 'Ahk.Component.Function' {
                    this.Prototype.DefineProp('Arrow', { Value: false })
                    this.Prototype.DefineProp('Static', { Value: false })
                    this.Prototype.DefineProp('Params', { Value: '' })
                }
            }
            Init(Match) {
                if Match['inner'] {
                    this.Params := ParamsList(Match['inner'])
                }
                if Match['arrow'] {
                    this.Arrow := true
                }
            }
            GetParams(Match) {
                if Match.inner {
                    this.Params := ParamsList(Match['inner'])
                }
            }
        }

        class Jsdoc extends Ahk.Component.Comment {

            GetCommentText(JoinChar := '`r`n') {
                return RegExReplace(this.Removed.Match['comment'], '\R?[ \t]*?\* ?', JoinChar)
            }
        }

        class CommentSingleLine extends Ahk.Component.Comment {

            GetCommentText() {
                return this.Removed.Match['comment']
            }
            TextComment => this.GetCommentText()
        }

        class CommentBlock extends Ahk.Component.Comment {

            GetCommentText(JoinChar := '`r`n') {
                return RegExReplace(this.TextFull, '\R?.*?(?<=\s|^);[ \t]*', JoinChar)
            }
        }

        class CommentMultiLine extends Ahk.Component.Comment {

            GetCommentText(JoinChar := '`r`n') {
                return RegExReplace(this.Removed.Match['comment'], '\R?[ \t]*', JoinChar)
            }
        }

        class Comment extends ComponentBase {
            GetCommentText(*) {
                throw Error('This method must be overridden by the inheritor.', -1, A_ThisFunc)
            }
            TextComment[JoinChar := '`r`n'] => this.GetCommentText(JoinChar)
        }

        class String extends ComponentBase {
        }

        ; class Expression extends ComponentBase {
        ; }

        class Variable extends ComponentBase {
        }

        ; class Symbol extends ComponentBase {
        ; }

        ; class Value extends ComponentBase {
        ; }

        ; class Object extends Ahk.Component.Variable {
        ; }

        ; class EmptyString extends ComponentBase {
        ; }

        ; class Boolean extends ComponentBase {
        ; }

        ; class Integer extends ComponentBase {
        ; }

        ; class Hex extends ComponentBase {
        ; }

        ; class Float extends ComponentBase {
        ; }

        ; class SubExpression extends ComponentBase {
        ; }

        ; class Operator extends ComponentBase {
        ; }

        ; class E extends ComponentBase {
        ; }

        ; ; %Expr%
        ; class Deref extends ComponentBase {
        ; }

        ; ; &
        ; class Reference extends ComponentBase {
        ; }

        ; ; Var ?? Alternative
        ; class OrMaybe extends ComponentBase {
        ; }

        ; ; Obj.Prop
        ; class MemberAccess extends ComponentBase {
        ; }

        ; ; Var?
        ; class Maybe extends ComponentBase {
        ; }
    }

    static __ThrowInvalidParamCount(Extra) {
        throw ValueError('Invalid number of parameters.', -2, Extra)
    }
    static __GetPath() => A_LineFile
}

