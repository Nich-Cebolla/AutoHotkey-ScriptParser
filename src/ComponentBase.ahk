
class ComponentBase {
    __New(LineStart, ColStart, LineEnd, ColEnd, Pos, Len, Stack?, RemovedMatch?, NameComponent?, PosBody?, LenBody?, Params?) {
        if IsSet(Stack) {
            if Stack.HasOwnProp('Active') {
                if InStr(Stack.Active.Path, 'GetFunc') {
                    sleep 1
                }
            } else {
                if InStr(Stack.Path, 'GetFunc') {
                    sleep 1
                }
            }
        }
        this.LineStart := LineStart
        this.ColStart := ColStart
        this.LineEnd := LineEnd
        this.ColEnd := ColEnd
        this.Pos := Pos
        this.Length := Len
        this.DefineProp('PosEnd', { Value: Pos + Len })
        if Isset(Stack) {
            this.Stack := Stack.HasOwnProp('Active') ? Stack.Active : Stack
            this.DefineProp('Name', { Get: (Self) => Self.Stack.Path })
            if Stack.HasOwnProp('ActiveClass') && !Stack.ActiveClass && this.IndexCollection !== SPC_CLASS {
                if this.Script.GlobalCollection.AddToCategoryEx(this.NameCollection, &(Name := this.Stack.Path), this) {
                    this.DefineProp('AltName', { Value: Name })
                }
            }
        } else if IsSet(NameComponent) {
            this.Name := NameComponent
        } else {
            this.DefineProp('Name', { Get: (Self) => Self.idu })
        }
        if IsSet(PosBody) {
            this.PosBody := PosBody
        }
        if IsSet(LenBody) {
            this.LenBody := LenBody
        }
        this.Script.ComponentList.Add(this)
        this.Collection.Add(this)
        if IsSet(RemovedMatch) {
            this.DefineProp('Removed', { Value: GetRemovedComponent(this, RemovedMatch) })
        }
        ; `Init` must be overridden by the inheritor.
        if IsSet(Params) {
            this.Init(Params)
        }
    }

    AddChild(Component) {
        if !this.HasOwnProp('Children') {
            this.Children := ChildNodeCollection(false)
            this.ChildList := ChildNodeList()
        }
        Component.ParentIdu := this.idu
        this.ChildList.Push(Component)
        if this.Children.AddToCategoryEx(Component.NameCollection, &(Name := Component.Name), Component) {
            Component.AltName := Name
        }
    }

    Init(*) {
        throw PropertyError('This method must be overridden by the inheritor.', -1, A_ThisFunc)
    }

    ; `IndexCollection`, `NameCollection` and `Script` are defined on the base

    Collection => this.Script.CollectionList[this.IndexCollection]

    Parent => this.Script.ComponentList.Get(this.ParentIdu)
    Path => this.Stack.Path
    FullPath => this.Path ? this.Path '.' this.Name : this.Name
    PosEnd => this.Pos + this.Length

    Text => this.Script.Text[this.Pos, this.Length]
    TextFull => this.Script.TextFull[this.Pos, this.Length]
    TextBody => this.PosBody ? this.Script.Text[this.PosBody, this.LenBody] : ''
    TextBodyFull => this.PosBody ? this.Script.TextFull[this.PosBody, this.Lenbody] : ''
    TextRemoved => this.Removed ? this.Removed.Match['text'] : ''
    TextReplacement => this.Removed ? this.Removed.Replacement : ''


    static __New() {
        if this.Prototype.__Class == 'ComponentBase' {
            Proto := this.Prototype
            for Prop in ['Removed', 'Name', 'Stack', 'LenBody', 'AltName'] {
                Proto.DefineProp(Prop, { Value: '' })
            }
        }
    }
}


GetRemovedComponent(Component, Match) {
    Script := Component.Script
    rc := {
        IndexRemoved: Script.RemovedCollection.AddToCategory(Component)
      , Match: Match
      , ComponentIdu: Component.idu
    }
    if StrLen(Component.IndexCollection rc.IndexRemoved) + 2 <= Match.Len['text'] {
        ObjSetBase(rc, RemovedComponent.Prototype)
    } else {
        ObjSetBase(rc, RemovedShortComponent.Prototype)
        rc.IndexRemovedShort := Script.RemovedCollection.AddToShortCollection(Component, &Char)
        rc.ShortChar := Char
    }
    rc.SetReplacement(Script, Component.IndexCollection)
    Script.Content := StrReplace(Script.Content, Match['text'], rc.Replacement, true, , 1)
    return rc
}

class RemovedShortComponent extends RemovedComponentBase {
    SetReplacement(Script, *) {
        this.Replacement := this.ShortChar this.IndexRemovedShort
        this.__SetReplacementShared(Script)
    }
}

class RemovedComponent extends RemovedComponentBase {
    SetReplacement(Script, IndexCollection) {
        this.Replacement := Chr(0xFFFC) IndexCollection Chr(0xFFFC) this.IndexRemoved
        this.__SetReplacementShared(Script)
    }
}

class RemovedComponentBase {
    __SetReplacementShared(Script) {
        over := StrLen(this.Replacement)
        le := Script.LineEnding
        if InStr(this.Match['text'], le) {
            leLen := StrLen(le)
            for line in StrSplit(this.Match['text'], le) {
                if over > 0 {
                    this.Replacement .= Script.__FillerReplacement[StrLen(line) - over]
                    over -= StrLen(line)
                } else {
                    this.Replacement .= Script.__FillerReplacement[StrLen(line)]
                }
                this.Replacement .= le
            }
            this.Replacement := SubStr(this.Replacement, 1, StrLen(this.Replacement) - leLen)
        } else {
            this.Replacement .= Script.__FillerReplacement[this.Match.Len['text'] - over]
        }
    }
    Text => this.Match['text']
}

class ChildNodeCollection extends MapEx {
}

class ChildNodeList extends Array {

}
