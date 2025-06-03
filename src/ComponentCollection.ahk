
class ComponentCollectionIndex extends MapEx {
    __New(Count) {
        this.CaseSense := false
        this.Default := ''
        this.Capacity := Count
    }
}

class ComponentCollectionList extends Array {
    __New(Count) {
        this.Length := Count
    }
}

/**
 * @classdesc - When `ComponentCollection` objects are created, they are added to an array
 * `ScriptParseObj.CollectionList`. The indices used are the `SPC_<collection name>` integers defined
 * in "define.ahk". Each `ComponentCollection` object has a `CollectionObj.Constructor` property
 * which references the constructor for the components. These constructors are also created using
 * `ClassFactory`.
 *
 * For an example of how to add values to a component collection while also removing the text from
 * the content body, see `ScriptParser.Prototype.RemoveStringsAndComments`.
 *
 * For an example of how to add values to a component collection while recursing into the stack,
 * see `ScriptParser.Prototype.ParseClass` or `ScriptParser.Prototype.ParseProperty`.
 * @
 */
class ComponentCollection extends MapEx {
    __New(ComponentBase, Capacity) {
        this.CaseSense := false
        this.Default := ''
        this.ComponentBase := ComponentBase
        this.__ComponentIndex := Number(ComponentBase.IndexCollection '000000') - 1
        this.__MaxComponentIndex := Number((ComponentBase.IndexCollection + 1) '000000')
        this.Capacity := Capacity
    }
    Add(Component) {
        this.Set(Component.Name, Component)
        Component.idc := this.GetIndex()
    }
    GetIndex() {
        if ++this.__ComponentIndex >= this.__MaxComponentIndex {
            throw Error('Number of components have exceeded the maximum.', -1
            , 'Component: ' this.ComponentBase.Name '; Count: ' this.__ComponentIndex)
        }
        return this.__ComponentIndex
    }

    NameCollection => this.ComponentBase.NameCollection
    IndexCollection => this.ComponentBase.IndexCollection
}

class ComponentList extends MapEx {
    __New(Capacity?) {
        this.Capacity := Capacity ?? SP_Config.Default.Capacity
        this.__ComponentIndex := 100000000 - 1
    }
    Add(Component) {
        Component.idu := this.GetIndex()
        this.Set(Component.idu, Component)
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

class RemovedCollection extends MapEx {
    __New(Script) {
        this.CaseSense := false
        this.Default := ''
        this.ConsecutiveDoubleQuotes := this.ConsecutiveSingleQuotes := 0
        this.__Index := 90000000 - 1
        this.__MaxCode := 91000000
        this.Capacity := Script.Config.Capacity
        this.ShortCollection := RemovedCollection.ShortCollection(Script)
    }

    AddToCategory(Component) {
        if !this.Has(Component.NameCollection) {
            this.Set(Component.NameCollection, [])
        }
        Component.idr := this.GetIndex()
        Arr := this.Get(Component.NameCollection)
        Arr.Push(Component)
        return Arr.Length
    }
    AddToShortCollection(Component, &Char) {
        return this.ShortCollection.Push(Component, &Char)
    }
    GetIndex() {
        if ++this.__Index >= this.__MaxCode {
            throw Error('Number of components have exceeded the maximum.', -1
            , 'Component: RemovedComponent; Count: ' this.__Index)
        }
        return this.__Index
    }

    class ShortCollection extends Map {
        static __New() {
            if this.Prototype.__Class == 'RemovedCollection.ShortCollection' {
                this.Prototype.DefineProp('__CharStartCode', { Value: 0x2000 })
                this.Prototype.DefineProp('__CharMaxCode', { Value: 0xFB04 })
            }
        }
        __New(Script) {
            this.__CharCode := this.__CharStartCode
            this.__AdjustCharCode(Script)
            this.Set(Chr(this.__CharCode), [])
        }
        Push(Component, &Char) {
            Arr := this.Get(Chr(this.__CharCode))
            if Arr.Length > 98 {
                this.__CharCode++
                this.__AdjustCharCode(Component.Script)
                this.Set(Chr(this.__CharCode), Arr := [])
            }
            Arr.Push(Component)
            Char := Chr(this.__CharCode)
            return Arr.Length
        }
        __AdjustCharCode(Script) {
            while InStr(Script.Content, Chr(this.__CharCode)) {
                this.__CharCode++
                if this.__CharCode > this.__CharMaxCode {
                    throw Error('``ScriptParser`` ran out of characters used to identify short removed strings.', -1)
                }
            }
        }
    }

}

class ConstructorCollection extends MapEx {
    __New(Count) {
        this.CaseSense := false
        this.Default := ''
        this.Capacity := Count
    }
}

class GlobalCollection extends MapEx {
    __New(Capacity) {
        this.CaseSense := false
        this.Default := ''
        this.Capacity := Capacity
    }
}

class ChildNodeCollection extends MapEx {
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

    static __New() {
        if this.Prototype.__Class == 'ChildNodeCollection' {
            Proto := this.Prototype
            Proto.DefineProp('ConsecutiveDoubleQuotes', { Value: 0 })
            Proto.DefineProp('ConsecutiveSingleQuotes', { Value: 0 })
        }
    }
}

class JsdocCollection extends ComponentCollection {
    Add(Component) {
        Component.idc := this.GetIndex()
        this.Set(Component.Name, Component)
        Match := Component.Removed.Match
        if Match['class'] {
            Name := Match['class']
            if this.AddToCategoryEx('Class', &Name, Component) {
                Component.DefineProp('AltName', { Value: Name })
            }
        } else if Match['name'] {
            Name := Match['name']
            if this.AddToCategoryEx((Match['static'] ? 'Static_' : '') (Match['func'] ? 'Func' : 'Property'), &Name, Component) {
                Component.DefineProp('AltName', { Value: Name })
            }
        }
    }

    AddToCategoryEx(Key, &Name, Value) {
        if !this.HasOwnProp(Key) {
            this.DefineProp(Key, { Value: MapEx() })
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
