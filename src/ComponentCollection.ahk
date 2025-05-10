
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
}

class RemovedCollection extends MapEx {
    __New(Script) {
        this.CaseSense := false
        this.Default := ''
        this.ConsecutiveDoubleQuotes := this.ConsecutiveSingleQuotes := 0
        this.__Index := 90000000 - 1
        this.__MaxIndex := 91000000
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
        if ++this.__Index >= this.__MaxIndex {
            throw Error('Number of components have exceeded the maximum.', -1
            , 'Component: RemovedComponent; Count: ' this.__Index)
        }
        return this.__Index
    }

    class ShortCollection extends Map {
        static __New() {
            if this.Prototype.__Class == 'RemovedCollection.ShortCollection' {
                this.Prototype.DefineProp('__CharStartIndex', { Value: 0x2000 })
                this.Prototype.DefineProp('__CharMaxIndex', { Value: 0xFB04 })
            }
        }
        __New(Script) {
            this.__CharIndex := this.__CharStartIndex
            this.__AdjustCharIndex(Script)
            this.Set(Chr(this.__CharIndex), [])
        }
        Push(Component, &Char) {
            Arr := this.Get(Chr(this.__CharIndex))
            if Arr.Length > 98 {
                this.__CharIndex++
                this.__AdjustCharIndex(Component.Script)
                this.Set(Chr(this.__CharIndex), Arr := [])
            }
            Arr.Push(Component)
            Char := Chr(this.__CharIndex)
            return Arr.Length
        }
        __AdjustCharIndex(Script) {
            while InStr(Script.Content, Chr(this.__CharIndex)) {
                this.__CharIndex++
                if this.__CharIndex > this.__CharMaxIndex {
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
