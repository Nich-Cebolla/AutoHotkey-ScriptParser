
class ScriptParser_ComponentCollectionIndex extends ScriptParser_MapEx {
    __New(Count) {
        this.CaseSense := false
        this.Default := ''
        this.Capacity := Count
    }
}

class ScriptParser_ComponentCollectionList extends Array {
    __New(Count) {
        this.Length := Count
    }
}

class ScriptParser_ComponentCollection extends ScriptParser_MapEx {
    static __New() {
        this.DeleteProp('__New')
        this.Prototype.__ComponentBase := ''
    }
    __New(ComponentBase) {
        this.CaseSense := false
        this.Default := ''
        this.__ComponentBase := ComponentBase
        this.__ComponentIndex := Number(ComponentBase.IndexCollection '000000') - 1
        this.__MaxComponentIndex := Number((ComponentBase.IndexCollection + 1) '000000')
    }
    Add(Component) {
        this.Set(Component.Name, Component)
        Component.__idc := this.GetIndex()
    }
    GetIndex() {
        if ++this.__ComponentIndex >= this.__MaxComponentIndex {
            throw Error('Number of components have exceeded the maximum.')
        }
        return this.__ComponentIndex
    }

    NameCollection => this.__ComponentBase ? this.__ComponentBase.NameCollection : ''
    IndexCollection => this.__ComponentBase ? this.__ComponentBase.IndexCollection : ''
}

class ScriptParser_ComponentList extends ScriptParser_MapEx {
    __New() {
        this.__ComponentIndex := 100000000 - 1
    }
    Add(Component) {
        Component.__idu := this.GetIndex()
        this.Set(Component.__idu, Component)
    }
    GetIndex() {
        return ++this.__ComponentIndex
    }
    ToArray() {
        Result := []
        Result.Capacity := this.Count
        for n, Component in this {
            Result.Push(Component)
        }
        return Result
    }
}

class ScriptParser_RemovedCollection extends ScriptParser_MapEx {
    __New(Script) {
        this.CaseSense := false
        this.Default := ''
        this.ConsecutiveDoubleQuotes := this.ConsecutiveSingleQuotes := 0
        this.__Index := 90000000 - 1
        this.__MaxCode := 91000000
        this.ShortCollection := ScriptParser_RemovedCollection.ShortCollection(Script)
    }

    AddToCategory(Component) {
        if !this.Has(Component.NameCollection) {
            this.Set(Component.NameCollection, [])
        }
        Component.__idr := this.GetIndex()
        Arr := this.Get(Component.NameCollection)
        Arr.Push(Component)
        return Arr.Length
    }
    AddToShortCollection(Component, Match, &Char) {
        return this.ShortCollection.Add(Component, Match, &Char)
    }
    GetIndex() {
        if ++this.__Index >= this.__MaxCode {
            throw Error('Number of components have exceeded the maximum.',
            , 'Component: RemovedComponent; Count: ' this.__Index)
        }
        return this.__Index
    }

    class ShortCollection extends Map {
        static __New() {
            this.DeleteProp('__New')
            this.Prototype.DefineProp('__CharMaxCode', { Value: 0xFB04 })
        }
        __New(Script) {
            this.__CharStartCode := this.__CharCode := Script.__ConsecutiveSingleReplacement + 1
            this.__AdjustCharCode(Script)
            this.Set(Chr(this.__CharCode), [])
        }
        Add(Component, Match, &Char) {
            if Match.Len['text'] = 1 {
                if !this.Has(Chr(Component.Script.__LoneSemicolonReplacement)) {
                    this.Set(Chr(Component.Script.__LoneSemicolonReplacement), [])
                }
                Arr := this.Get(Chr(Component.Script.__LoneSemicolonReplacement))
                Arr.Push(Component)
                Char := Chr(Component.Script.__LoneSemicolonReplacement)
            } else {
                Arr := this.Get(Chr(this.__CharCode))
                if Arr.Length > 98 {
                    this.__CharCode++
                    this.__AdjustCharCode(Component.Script)
                    this.Set(Chr(this.__CharCode), Arr := [])
                }
                Arr.Push(Component)
                Char := Chr(this.__CharCode)
            }
            return Arr.Length
        }
        __AdjustCharCode(Script) {
            while InStr(Script.__Content, Chr(this.__CharCode)) {
                this.__CharCode++
                if this.__CharCode > this.__CharMaxCode {
                    throw Error('``ScriptParser`` ran out of characters used to identify short removed strings.')
                }
            }
        }
    }

}

class ScriptParser_GlobalCollection extends ScriptParser_MapEx {
    __New() {
        this.CaseSense := false
        this.Default := ''
    }
}

class ScriptParser_ChildCollection extends ScriptParser_MapEx {
    ToArray(Include?, Exclude?) {
        Result := []
        if IsSet(Include) {
            for s in StrSplit(Include, ',', '`s`t') {
                if s && this.Has(s) {
                    Result.Capacity += this.Get(s).Capacity
                    for Name, Component in this.Get(s) {
                        Result.Push(Component)
                    }
                }
            }
        } else if IsSet(Exclude) {
            Exclude := ',' Exclude ','
            for Name, Collection in this {
                if InStr(Exclude, ',' Name ',') {
                    continue
                }
                Result.Capacity += Collection.Capacity
                for Name, Component in Collection {
                    Result.Push(Component)
                }
            }
        } else {
            for Name, Collection in this {
                Result.Capacity += Collection.Capacity
                for Name, Component in Collection {
                    Result.Push(Component)
                }
            }
        }
        return Result
    }
    ToArray2(Exclude?) {
        Result := []
        if IsSet(Exclude) {
            Exclude := ',' Exclude ',Jsdoc,CommentSingleLine,CommentMultiLine,String,'
        } else {
            Exclude := ',Jsdoc,CommentSingleLine,CommentMultiLine,String,'
        }
        for Name, Collection in this {
            if InStr(Exclude, ',' Name ',') {
                continue
            }
            Result.Capacity += Collection.Capacity
            for Name, Component in Collection {
                Result.Push(Component)
            }
        }
        return Result
    }
}

class ScriptParser_JsdocCollection extends ScriptParser_ComponentCollection {
    static __New() {
        this.DeleteProp('__New')
        this.Prototype.General := ''
    }
    __New(ComponentBase) {
        super.__New(ComponentBase)
        this.__TempList := []
        this.General := []
    }
    Add(Component) {
        this.__TempList.Push(Component)
    }
    __Process() {
        for component in this.__TempList {
            Component.__idc := this.GetIndex()
            this.Set(Component.Name, Component)
            Match := Component.__Removed.Match
            if Match['class'] {
                Name := Match['class']
                if this.AddToCategoryEx('Class', &Name, Component) {
                    Component.DefineProp('AltName', { Value: Name })
                }
            } else if Match['name'] && Component.CommentParent {
                switch Component.CommentParent.IndexCollection {
                    case SPC_INSTANCEMETHOD: category := 'InstanceMethod'
                    case SPC_INSTANCEPROPERTY: category := 'InstanceProperty'
                    case SPC_SETTER, SPC_GETTER:
                        switch Component.CommentParent.Parent.IndexCollection {
                            case SPC_INSTANCEPROPERTY: category := 'InstanceProperty'
                            case SPC_STATICPROPERTY: category := 'StaticProperty'
                        }
                    case SPC_STATICMETHOD: category := 'StaticMethod'
                    case SPC_STATICPROPERTY: category := 'StaticProperty'
                    case SPC_FUNCTION: category := 'Function'
                }
                Name := Component.CommentParent.Path '.Jsdoc'
                if this.AddToCategoryEx(category, &Name, Component) {
                    Component.DefineProp('AltName', { Value: Name })
                }
            } else {
                this.General.Push(Component)
            }
        }
        if !this.General.Length {
            this.DeleteProp('General')
        }
        this.DeleteProp('__TempList')
    }

    AddToCategoryEx(Key, &Name, Value) {
        if !this.HasOwnProp(Key) {
            this.DefineProp(Key, { Value: ScriptParser_MapEx() })
        }
        M := this.%Key%
        if M.Has(Name) {
            temp := Name '-'
            i := 1
            while M.Has(temp A_Index) {
                i := A_Index
            }
            M.Set(temp i, Value)
            Name := temp i
            return 1
        } else {
            M.Set(Name, Value)
        }
    }
}

class ScriptParser_IncludedCollection extends Map {
    __New() {
        this.CaseSense := false
    }
}
