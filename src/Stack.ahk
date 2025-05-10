
class ParseStack extends Array {
    __New(BaseObj) {
        ObjSetBase(this.Active := { }, BaseObj)
        this.ContextMap := ParseStack.ContextMap()
        this.PosList := []
        this.ActiveClass := ''
        this.ClassList := []
    }
    Add(ParentContext, Name, Pos, RecursiveOffset) {
        Constructor := this.Constructor
        return Constructor(Name, Pos, ParentContext, RecursiveOffset)
    }
    BreakReferenceCycles() {
        for Pos, Context in this.ContextMap {
            Context.DeleteProp('__Component')
        }
    }
    BuildList() {
        this.PosList.Capacity := this.ContextMap.Count
        for Pos in this.ContextMap {
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
    In(Name, Pos, RecursiveOffset) {
        this.Push(this.Active)
        Constructor := this.Constructor
        this.Active := Constructor(Name, Pos, this.Active, RecursiveOffset)
    }
    Out() {
        this.Active.PosEnd := this.Active.__Component.PosEnd
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
    SetComponentInactive(Parent, Context, Component) {
        Context.__Component := Component
        Context.ComponentIdu := Component.idu
        Parent.AddChild(Component)
    }

    Depth => this.Length

    class ContextMap extends MapEx {

    }

    class Context {
        static Call(Name, Pos, ParentContext, RecursiveOffset) {
            ObjSetBase(context := {
                Name: Name
              , Pos: Pos + ParentContext.RecursiveOffset - 1
              , RecursiveOffset: RecursiveOffset
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
        Length => this.PosEnd ? this.PosEnd - this.Pos : ''
        Path => this.GetPath()

        static __New() {
            if this.Prototype.__Class == 'ParseStack.Context' {
                this.Prototype.DefineProp('PosEnd', { Value: '' })
            }
        }
    }
}
