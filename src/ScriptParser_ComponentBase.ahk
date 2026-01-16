
class ScriptParser_ComponentBase {
    static __New() {
        this.DeleteProp('__New')
        Proto := this.Prototype
        for Prop in ['AltName', 'Children', 'LenBody',  '__ParentIdu', 'Name', '__Removed', '__Stack'
        , 'HasJsdoc', '__Comment', '__CommentParent', 'PosBody', 'Path'] {
            Proto.DefineProp(Prop, { Value: '' })
        }
    }
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
            this.__Stack := Stack.Active
            if this.IndexCollection == SPC_INSTANCEMETHOD {
                Path := this.__Stack.Path
                this.DefineProp('Name', { Value: SubStr(Path, 1, InStr(Path, '.', , , -1)) 'Prototype.' SubStr(Path, InStr(Path, '.', , , -1) + 1) })
            } else {
                this.DefineProp('Name', { Get: (Self) => Self.__Stack.Path })
            }
            this.__Stack.__ComponentIdu := this.__idu
            this.Path := Stack.Active.Path
        } else if IsSet(NameComponent) {
            this.Name := NameComponent
        } else {
            switch this.IndexCollection {
                case SPC_JSDOC: this.DefineProp('Name', { Get: ScriptParser_GetJsdocName })
                case SPC_COMMENTBLOCK
                , SPC_COMMENTSINGLELINE
                , SPC_COMMENTMULTILINE: this.DefineProp('Name', { Get: (Self) => Self.TextComment ' - ' Self.__idu })
                default: this.DefineProp('Name', { Get: (Self) => Self.Text ' - ' Self.__idu })
            }
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
            this.DefineProp('__Removed', { Value: ScriptParser_GetRemovedComponent(this, Match) })
        }
        this.Collection.Add(this)
    }

    AddChild(Component) {
        ; I structure some methods like this for optimization reasons. If there is a condition that
        ; only needs to be checked once, we can check the condition, override the method with a
        ; function that does not check the condition, then call the method.
        if !this.HasOwnProp('Children') {
            this.Children := ScriptParser_ChildCollection(false)
        }
        this.DefineProp('AddChild', { Call: _AddChild })
        this.AddChild(Component)
        _AddChild(Self, Component) {
            Component.__ParentIdu := this.__idu
            if this.Children.AddToCategoryEx(Component.NameCollection, &(Name := Component.Name), Component) {
                Component.DefineProp('AltName', { Value: Name })
            }
        }
    }

    GetOwnText() {
        Text := this.__Text
        if this.HasOwnProp('Children') {
            for Child in this.Children.ToArray2() {
                if Child.PosBody {
                    Text := StrReplace(Text, Child.____TextBody, '')
                }
            }
        }
        return Text
    }

    GetOwnTextFull() {
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

    /**
     * @description - This is only intended to be used for components that are not class components.
     */
    __AssociateRemovedComponents() {
        Text := this.__Text
        RemovedCollection := this.Script.RemovedCollection
        Pos := 1
        loop {
            if !RegExMatch(Text, this.Script.__ReplacementPattern, &Match, Pos) {
                break
            }
            this.AddChild(RemovedCollection.Get(this.Script.GetCollectionName(Match['collection']))[Match['index']])
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

    Collection => this.Script.__CollectionList[this.IndexCollection]
    Comment {
        Get => this.__Comment ? this.Script.ComponentList.Get(this.__Comment) : ''
        Set {
            if IsObject(Value) {
                this.__Comment := Value.__idu
            } else {
                this.__Comment := Value
            }
        }
    }
    CommentParent {
        Get => this.__CommentParent ? this.Script.ComponentList.Get(this.__CommentParent) : ''
        Set {
            if IsObject(Value) {
                this.__CommentParent := Value.__idu
            } else {
                this.__CommentParent := Value
            }
        }
    }
    Match => this.__Removed ? this.__Removed.Match : ''
    Parent => this.__ParentIdu ? this.Script.ComponentList.Get(this.__ParentIdu) : ''
    PosEnd => this.Pos + this.Length
    Script => ScriptParser.Collection.Get(this.IdScriptParser)
    Text => this.Script.Text[this.Pos, this.Length]
    TextBody => this.PosBody ? this.Script.Text[this.PosBody, this.Lenbody] : ''
    TextOwn => this.GetOwnTextFull()
    __Text => this.Script.__Text[this.Pos, this.Length]
    __TextBody => this.PosBody ? this.Script.__Text[this.PosBody, this.LenBody] : ''
    __TextOwn => this.GetOwnText()
}

ScriptParser_GetRemovedComponent(Component, Match) {
    Script := Component.Script
    rc := {
        IndexRemoved: Script.RemovedCollection.AddToCategory(Component)
      , Match: Match
      , __ComponentIdu: Component.__idu
    }
    if StrLen(Component.IndexCollection rc.IndexRemoved) + 2 <= Match.Len['text'] {
        ObjSetBase(rc, ScriptParser_RemovedComponent.Prototype)
        rc.SetReplacement(Script, Component.IndexCollection)
    } else if Match.Len['text'] = 1 {
        ObjSetBase(rc, ScriptParser_RemovedShortComponent.Prototype)
        rc.IndexRemovedShort := Script.RemovedCollection.AddToShortCollection(Component, Match, &Char)
        rc.Replacement := rc.ShortChar := Char
    } else {
        ObjSetBase(rc, ScriptParser_RemovedShortComponent.Prototype)
        rc.IndexRemovedShort := Script.RemovedCollection.AddToShortCollection(Component, Match, &Char)
        rc.ShortChar := Char
        rc.SetReplacement(Script, Component.IndexCollection)
    }
    Script.__Content := StrReplace(Script.__Content, Match['text'], rc.Replacement, true, , 1)
    return rc
}

class ScriptParser_RemovedShortComponent extends ScriptParser_RemovedComponentBase {
    SetReplacement(Script, *) {
        this.Replacement := this.ShortChar this.IndexRemovedShort
        this.__SetReplacementShared(Script)
    }
}

class ScriptParser_RemovedComponent extends ScriptParser_RemovedComponentBase {
    SetReplacement(Script, IndexCollection) {
        this.Replacement := Script.__ReplacementChar IndexCollection Script.__ReplacementChar this.IndexRemoved
        this.__SetReplacementShared(Script)
    }
}

class ScriptParser_RemovedComponentBase {
    __SetReplacementShared(Script) {
        over := StrLen(this.Replacement)
        eol := Script.EndOfLine
        if InStr(this.Match['text'], eol) {
            leLen := StrLen(eol)
            for line in StrSplit(this.Match['text'], eol) {
                if over > 0 {
                    if StrLen(line) >= over {
                        this.Replacement .= Script.__FillerReplacement[StrLen(line) - over]
                    }
                    over -= StrLen(line)
                } else {
                    this.Replacement .= Script.__FillerReplacement[StrLen(line)]
                }
                this.Replacement .= eol
            }
            this.Replacement := SubStr(this.Replacement, 1, StrLen(this.Replacement) - leLen)
        } else {
            this.Replacement .= Script.__FillerReplacement[this.Match.Len['text'] - over]
        }
    }
    Text => this.Match['text']
}
