
class ParseStack extends Array {
    __New(BaseObj) {
        ObjSetBase(this.Active := { }, BaseObj)
        this.ContextMap := ParseStack.ContextMap()
        this.NextClass := this.ActiveClass := this.PreviousMatch := ''
        this.ClassList := []
        this.PosEnd := this.Pos := this.Line := 1
    }
    Add(Name, Pos, PosEnd, ParentContext) {
        Constructor := this.Constructor
        return Constructor(Name, Pos, PosEnd, ParentContext)
    }
    BuildScopeMap() {
        this.ScopeMap := ParseStack.ScopeMap()
        this.PosList.Capacity := this.ContextMap.Count
        for Pos, Context in this.ContextMap {
            this.PosList.Push(Pos)
        }
    }
    GetContext(Pos) {
        i := 0
        for _Pos in this.PosList {
            Context := this.ContextMap[_Pos]
            if Context.Pos < Pos && Context.PosEnd > Pos {
                c := Context
            } else if Context.Pos > pos {
                break
            }
        }
        return c ?? ''
    }
    In(Script, Name, Match, ComponentConstructor, Pos?, Line?) {
        this.Push(this.Active)
        if !IsSet(Pos) {
            Pos := this.Pos
        }
        if !IsSet(Line) {
            Line := this.Line
        }
        ; Get line count between the current position and the beginning of the definition
        StrReplace(SubStr(Script.Content, Pos, Match.Pos['body'] - Pos), Script.LineEnding, , , &linecount)
        ; Calculate start line for the definition statement
        LineStart := Line + linecount
        ; Calculate start column for the definition statement
        ColStart := Match.Pos['text'] - Match.Pos
        ; Get line count of definition statement
        StrReplace(Match['body'], Script.LineEnding, , , &linecount)
        ; Calculate end line for the definition statement
        LineEnd := LineStart + linecount
        ; Calculate end column.
        if LineEnd == LineStart {
            ColEnd := ColStart + Match.Len['text']
        } else {
            ColEnd := Match.Len['text'] - InStr(Match['text'], Script.LineEnding, , , -1)
        }
        ; Create the next stack context object
        Constructor := this.Constructor
        this.Active := Constructor(Name, Match.Pos['text'], Match.Pos['text'] + Match.Len['text'], this[-1])
        ; Create the component object
        Component := ComponentConstructor(
            LineStart
          , ColStart
          , LineEnd
          , ColEnd
          , Match.Pos['text']
          , Match.Len['text']
          , this
          ,
          ,
          , Match.Pos['body']
          , Match.Len['body']
        )
        ; Set the component to the context. We use the `idu` to prevent a reference cycle.
        this.Active.ComponentIdu := Component.idu
        ; Add the component as a child to its parent
        if this.Depth > 1 {
            this[-1].Component.AddChild(Component)
        } else if this.Depth == 1 {
            if Script.GlobalCollection.AddToCategoryEx(Component.NameCollection, &(Name := this.Active.Path), Component) {
                Component.DefineProp('AltName', { Value: Name })
            }
        }
        if Component.IndexCollection == SPC_CLASS {
            this.ClassList.Push(this.ActiveClass)
            this.ActiveClass := Component
            this.Active.IsClass := true
        } else {
            this.Active.IsClass := false
        }
        return Component
    }
    Out() {
        this.ContextMap.Set(this.Active.Pos, this.Active)
        if this.Active.IsClass {
            this.ActiveClass := this.ClassList.Pop()
        }
        this.Active := this.Pop()
    }
    SetComponent(Component) {
        this.Active.__Component := Component
        this.Active.ComponentIdu := Component.idu
        if this.Depth > 1 {
            this[-1].__Component.AddChild(Component)
        }
        if Component.IndexCollection == SPC_CLASS {
            this.ClassList.Push(this.ActiveClass)
            this.ActiveClass := Component
            this.Active.IsClass := true
        } else {
            this.Active.IsClass := false
        }
    }

    Depth => this.Length
    Len => this.PosEnd - this.Pos

    class ContextMap extends MapEx {

    }

    class ScopeMap extends MapEx {

    }

    class Context {
        static Call(Name, Pos, PosEnd, ParentContext) {
            ObjSetBase(context := { Name: Name, Pos: Pos, PosEnd: PosEnd }, ParentContext)
            return context
        }

        GetPath() {
            if this.Pos == 1 {
                return ''
            }
            s := this.Name
            b := this
            loop {
                b := b.Base
                if b.Pos == 1 {
                    break
                }
                s := b.Name '.' s
            }
            return s
        }

        Component => this.Script.ComponentList.Get(this.ComponentIdu)
        Length => this.PosEnd - this.Pos
        Path => this.GetPath()

        static __New() {
            if this.Prototype.__Class == 'ParseStack.Context' {
                this.Prototype.DefineProp('PosEnd', { Value: '' })
            }
        }
    }
}
