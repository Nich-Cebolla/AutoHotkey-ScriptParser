
class ScriptParser_Stack extends Array {
    __New(BaseObj) {
        this.Active := BaseObj
        this.ContextMap := ScriptParser_Stack.ContextMap()
        this.ActiveClass :=this.NextClass := ''
        this.ClassList := []
        this.PosEnd := this.Pos := this.Line := 1
    }
    Add(Name, Pos, PosEnd, ParentContext) {
        Constructor := this.Constructor
        return Constructor(Name, Pos, PosEnd, ParentContext)
    }
    BuildScopeMap() {
        this.ScopeMap := ScriptParser_Stack.ScopeMap()
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
    In(Script, Name, CS, ComponentConstructor, Match, Pos?, Line?) {
        this.Push(this.Active)
        if !IsSet(Pos) {
            Pos := this.Pos
        }
        if !IsSet(Line) {
            Line := this.Line
        }
        ; Get line count between the current position and the beginning of the definition
        StrReplace(SubStr(Script.Content, Pos, CS.Pos['text'] - Pos), Script.EndOfLine, , , &linecount)
        ; Calculate start line for the definition statement
        LineStart := Line + linecount
        ; Calculate start column for the definition statement
        ColStart := CS.Pos['text'] - CS.Pos
        ; Get line count of definition statement
        StrReplace(CS['text'], Script.EndOfLine, , , &linecount)
        ; Calculate end line for the definition statement
        LineEnd := LineStart + linecount
        ; Calculate end column
        if LineEnd == LineStart {
            ColEnd := ColStart + CS.Len['text']
        } else {
            ColEnd := CS.Len['text'] - InStr(CS['text'], Script.EndOfLine, , , -1)
        }
        ; Create the context object
        this.Active := this.Constructor.Call(Name, CS.Pos['text'], CS.Pos['text'] + CS.Len['text'], this[-1])
        ; Create the component object
        Component := ComponentConstructor(
            LineStart
          , ColStart
          , LineEnd
          , ColEnd
          , CS.Pos['text']
          , CS.Len['text']
          , this
          , Match
          ,
          , CS.Pos['body']
          , CS.Len['body']
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
        ; If the new component is a class component
        if Component.IndexCollection == SPC_CLASS {
            ; Push current class into stack
            this.ClassList.Push(this.ActiveClass)
            ; Set active class
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

    class ContextMap extends ScriptParser_MapEx {

    }

    class ScopeMap extends ScriptParser_MapEx {

    }

    class Context {
        static Call(Name, Pos, PosEnd, ParentContext) {
            ObjSetBase(context := {
                Bounds: []
              , Depth: ParentContext.Depth + 1
              , Name: Name
              , Pos: Pos
              , PosEnd: PosEnd
            }, ParentContext)
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
        Script => ScriptParser.Collection.Get(this.IdScriptParser)

        static __New() {
            this.DeleteProp('__New')
            this.Prototype.DefineProp('PosEnd', { Value: '' })
        }
    }
}
