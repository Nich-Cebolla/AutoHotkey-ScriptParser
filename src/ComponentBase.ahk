
class ComponentBase {
    __New(LineStart, ColStart, LineEnd, ColEnd, Pos, Len, Stack?, RemovedMatch?, NameComponent?, PosBody?, LenBody?) {
        this.LineStart := LineStart
        this.ColStart := ColStart
        this.LineEnd := LineEnd
        this.ColEnd := ColEnd
        this.Pos := Pos
        this.Length := Len
        this.DefineProp('PosEnd', { Value: Pos + Len })
        if Isset(Stack) {
            this.Stack := Stack.Active
            this.DefineProp('Name', { Get: (Self) => Self.Stack.Path })
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
    }

    AddChild(Component) {
        ; I structure some methods like this for optimization reasons. If there is a condition that
        ; only needs to be checked once, we can check the condition, override the method with a
        ; function that does not check the condition, then call the method.
        if !this.HasOwnProp('Children') {
            this.Children := ChildNodeCollection(false)
        }
        this.DefineProp('AddChild', { Call: _AddChild })
        this.AddChild(Component)
        _AddChild(Self, Component) {
            Component.ParentIdu := this.idu
            if this.Children.AddToCategoryEx(Component.NameCollection, &(Name := Component.Name), Component) {
                Component.DefineProp('AltName', { Value: Name })
            }
        }
    }

    GetOwnText() {
        Text := this.Text
        if this.HasOwnProp('Children') {
            for Child in this.Children.ToArray2() {
                if Child.PosBody {
                    Text := StrReplace(Text, Child.TextBody, '')
                }
            }
        }
        return Text
    }

    GetOwnTextFull() {
        Text := this.TextFull
        if this.HasOwnProp('Children') {
            for Child in this.Children.ToArray2() {
                if Child.PosBody {
                    Text := StrReplace(Text, Child.TextBodyFull, '')
                }
            }
        }
        return Text
    }

    Init(*) {
        throw PropertyError('This method must be overridden by the inheritor.', -1, A_ThisFunc)
    }

    /**
     * @description - This is only intended to be used for components that are not class components.
     */
    __AssociateRemovedComponents() {
        Text := this.Text
        RemovedCollection := this.Script.RemovedCollection
        Pos := 1
        loop {
            if !RegExMatch(Text, SPP_REPLACEMENT, &Match, Pos) {
                break
            }
            this.AddChild(RemovedCollection.Get(this.Script.NameCollection[Match['collection']])[Match['index']])
            Pos := Match.Pos + Match.Len
        }
        ShortCollection := RemovedCollection.ShortCollection
        Index := ShortCollection.__CharStartCode
        EndIndex := ShortCollection.__CharCode
        Pos := 1
        loop {
            if RegExMatch(Text, Chr(Index) '(\d+)', &Match, Pos) {
                this.AddChild(ShortCollection.Get(Chr(Index))[Match[1]])
                Pos := Match.Pos + Match.Len
            } else {
                if ++Index > EndIndex {
                    break
                }
                Pos := 1
            }
        }
    }

    ; `AltName`, `IndexCollection`, `NameCollection`, `ParentIdu`, `Removed`, and `Script` are
    ; defined on the base.
    ; The following are defined elsewhere:
    ; `Name`, `Children`, `Length`, `Pos`, `PosEnd`, `PosBody`, `LenBody`, `LineStart`, `LineEnd`,
    ; `ColStart`, `ColEnd`, `Stack`.
    ; `AltName` is overridden in cases where multiple components share the same name and are
    ; in the same collection.
    ; `ParentIdu` is overridden if the component is a child of another.
    ; `Removed` is overridden if the component's text is removed from the content.
    ; Components that are comments have additional property `TextComment`.

    Collection => this.Script.CollectionList[this.IndexCollection]

    Parent => this.ParentIdu ? this.Script.ComponentList.Get(this.ParentIdu) : ''
    Path => this.Stack.Path
    PosEnd => this.Pos + this.Length

    Text => this.Script.Text[this.Pos, this.Length]
    TextBody => this.PosBody ? this.Script.Text[this.PosBody, this.LenBody] : ''
    TextBodyFull => this.PosBody ? this.Script.TextFull[this.PosBody, this.Lenbody] : ''
    TextFull => this.Script.TextFull[this.Pos, this.Length]
    TextOwn => this.GetOwnText()
    TextOwnFull => this.GetOwnTextFull()
    TextRemoved => this.Removed ? this.Removed.Match['text'] : ''
    TextReplacement => this.Removed ? this.Removed.Replacement : ''


    static __New() {
        if this.Prototype.__Class == 'ComponentBase' {
            Proto := this.Prototype
            for Prop in ['AltName', 'LenBody',  'ParentIdu', 'Name', 'Removed', 'Stack'] {
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
    if Component.IndexCollection == SPC_JSDOC {

    }
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
