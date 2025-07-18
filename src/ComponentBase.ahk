
class ComponentBase {
    __New(LineStart, ColStart, LineEnd, ColEnd, Pos, Len, Stack?, Match?, NameComponent?, PosBody?, LenBody?, IsRemoved := false) {
        this.LineStart := LineStart
        this.ColStart := ColStart
        this.LineEnd := LineEnd
        this.ColEnd := ColEnd
        this.Pos := Pos
        this.Length := Len
        this.DefineProp('PosEnd', { Value: Pos + Len })
        this.Script.ComponentList.Add(this)
        if Isset(Stack) {
            this.Stack := Stack.Active
            if this.IndexCollection == SPC_INSTANCEMETHOD {
                Path := this.Stack.Path
                this.DefineProp('Name', { Value: SubStr(Path, 1, InStr(Path, '.')) 'Prototype.' SubStr(Path, InStr(Path, '.') + 1) })
            } else {
                this.DefineProp('Name', { Get: (Self) => Self.Stack.Path })
            }
            this.Stack.ComponentIdu := this.idu
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
        if HasMethod(this, 'Init') {
            this.Init(Match)
        }
        if IsRemoved {
            this.DefineProp('Removed', { Value: GetRemovedComponent(this, Match) })
        }
        this.Collection.Add(this)
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

    ; 'AltName', 'Children', 'LenBody',  'ParentIdu', 'Name', 'Removed', 'Stack' are defined on the base as empty string values.
    ; `AltName` is overridden in cases where multiple components share the same name and are
    ; in the same collection.
    ; `Params` is overridden if the component represents a function or property that has parameters.
    ; `ParentIdu` is overridden if the component is a child of another.
    ; `Removed` is overridden if the component's text is removed from the content.
    ; `IndexCollection`, `NameCollection`, and `Script` are defined on the base with significant values.
    ; The following are defined elsewhere:
    ; `Children`, `ColEnd`, `ColStart`, `LenBody`, `Length`, `LineEnd`, `LineStart`, `Pos`, `PosBody`,
    ; `PosEnd`, `Name`, `Stack`.
    ; `idc`, `idr`, and `idu` are identifiers defined when the component is added to a collection:
    ; `idc` - The identifier that is specific to the collection object.
    ; `idr` - The identifier that is used for removed components.
    ; `idu` - A general identifier used by all components.
    ; Components that are comments have additional property `TextComment` which returns the text
    ; without any comment operators and joined by a substring.
    ; Components that are paired with a jsdoc comment using `ScriptParser.Prototype.JsdocAssociate`
    ; have a property `Jsdoc` which is the component object for the jsdoc comment.

    Collection => this.Script.CollectionList[this.IndexCollection]
    Jsdoc {
        Get => this.__Jsdoc ? this.Script.ComponentList.Get(this.__Jsdoc) : ''
        Set {
            if IsObject(Value) {
                this.__Jsdoc := Value.idu
            } else {
                this.__Jsdoc := Value
            }
        }
    }
    Parent => this.ParentIdu ? this.Script.ComponentList.Get(this.ParentIdu) : ''
    JsdocParent {
        Get => this.__JsdocParent ? this.Script.ComponentList.Get(this.__JsdocParent) : ''
        Set {
            if IsObject(Value) {
                this.__JsdocParent := Value.idu
            } else {
                this.__JsdocParent := Value
            }
        }
    }
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
            for Prop in ['AltName', 'Children', 'LenBody',  'ParentIdu', 'Name', 'Removed', 'Stack'
            , '__Jsdoc', '__JsdocParent'] {
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
