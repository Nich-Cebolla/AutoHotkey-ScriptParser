

class Ahk {

    class Component {

        class Class extends Ahk.Component.Variable {
            Init(Match) {
                this.Indent := Match.Len['indent']
                this.Extends := Match['super']
            }

            __Add(Component, Collection) {
                if Collection.Has(Component.Name) {
                    loop {
                        if !Collection.Has(Name := Component.Name '-' A_Index) {
                            break
                        }
                    }
                    Collection.Set(Name, Component)
                    Component.DefineProp('AltName', { Value: Name })
                } else {
                    Collection.Set(Component.Name, Component)
                }
            }
            __AddInstanceMethod(Component) => this.__Add(Component, this.InstanceMethod)
            __AddInstanceProperty(Component) => this.__Add(Component, this.InstanceProperty)
            __AddStaticMethod(Component) => this.__Add(Component, this.StaticMethod)
            __AddStaticProperty(Component) => this.__Add(Component, this.StaticProperty)
            __Call(Name, Params) {
                if HasMethod(this, '__' Name) {
                    this.DefineProp(StrReplace(Name, 'Add', ''), { Value: Ahk.Component.Class.%StrReplace(Name, 'Add', '') 'Collection'%() })
                    this.DefineProp(Name, Ahk.Component.Class.Prototype.GetOwnPropDesc('__' Name))
                    this.%Name%(Params[1])
                } else {
                    throw PropertyError('The object does not have a method with that name.', -1, 'Name: ' Name '; Type(obj) == ' Type(this))
                }
            }

            class InstanceMethodCollection extends MapEx {
            }
            class InstancePropertyCollection extends MapEx {
            }
            class StaticMethodCollection extends MapEx {
            }
            class StaticPropertyCollection extends MapEx {
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

                _Proc(Name) {
                    if Match['arrow'] {
                        Match := ContinuationSection(
                            StrPtr(this.Script.Content)
                          , Match.Pos['text']
                          , Match['arrow'] ? '=>' : ':='
                        )
                    }
                    if Name == 'Get' {
                        this.Script.Stack.In(this.Script, Name, Match, this.Script.CollectionList[SPC_GETTER].Constructor)
                    } else {
                        this.Script.Stack.In(this.Script, Name, Match, this.Script.CollectionList[SPC_SETTER].Constructor)
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
                if this.Prototype.__Class == 'Ahk.Component.Method' {
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

        class Jsdoc extends ComponentBase {

        }

        class CommentSingleLine extends ComponentBase {

        }

        class CommentMultiLine extends ComponentBase {
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

        ; ; &x
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

