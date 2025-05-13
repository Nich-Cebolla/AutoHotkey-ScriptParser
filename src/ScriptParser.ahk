

class ScriptParser {
    __New(Config?) {
        Config := this.Config := SP_Config(Config ?? {})
        this.Content := FileRead(this.PathIn, this.Encoding || unset)
        if Config.StandardizeLineEnding {
            this.Content := RegExReplace(this.Content, '\R', Config.StandardizeLineEnding)
            this.LineEnding := Config.StandardizeLineEnding
        } else {
            ; Get line endings.
            StrReplace(this.Content, '`n', , , &countlf)
            StrReplace(this.Content, '`r', , , &countcr)
            if countcr {
                if countlf {
                    if countcr == countlf {
                        RegExMatch(this.Content, '\R', &mlineending)
                        this.LineEnding := mlineending[0]
                    } else {
                        throw Error('The script content has mixed line endings.', -1)
                    }
                } else {
                    this.LineEnding := '`r'
                }
            } else if countlf {
                this.LineEnding := '`n'
            } else {
                this.LineEnding := ''
            }
        }
        ; `Script.CollectionIndex` is a map with name : index pairs. The indices are associated
        ; with `Script.CollectionList` items. To get an item by name: `Script.CollectionList[Script.CollectionIndex.Get(Name)]`.
        CollectionIndex := this.CollectionIndex := ComponentCollectionIndex(ObjOwnPropCount(Ahk.Component))
        CollectionList := this.CollectionList := ComponentCollectionList(ObjOwnPropCount(Ahk.Component))
        Component := this.Config.Language.Component
        ; `ComponentBaseBase` is the base for component objects.
        ObjSetBase(ComponentBaseBase := this.__ComponentBaseBase := { Script: this }, ComponentBase.Prototype)
        BaseObjects := Map()
        BaseObjects.CaseSense := false
        BaseObjects.Set('ComponentBase', ComponentBaseBase)
        LangContent := FileRead(this.Config.Language.__GetPath())
        Pending := []
        ToCollectionsObj := ['Class', 'CommentMultiline', 'CommentSingleline', 'Function', 'Getter'
        , 'InstanceMethod', 'InstanceProperty', 'Jsdoc', 'Setter', 'StaticMethod', 'StaticProperty'
        , 'String']
        for Prop in Component.OwnProps() {
            _component := Component.%Prop%
            if _component is Class {
                ; To recreate the inheritance chains for each of the components' prototypes, this
                ; reads the content in the language file and identifies the superclass for each
                ; component class, then assigns the correct base.
                if !RegExMatch(LangContent, 'i)class[ \t]+' Prop '[ \t]+extends[ \t]+(?<super>[\w.]+)', &Match) {
                    throw Error('Failed to match the collection`'s class definition statement.', -1)
                }
                ; The index values are defined in "define.ahk".
                index := %'SPC_' Prop%
                B := { NameCollection: Prop, IndexCollection: index }
                split := StrSplit(Match['super'], '.')
                if BaseObjects.Has(split[-1]) {
                    ObjSetBase(B, BaseObjects.Get(split[-1]))
                } else {
                    Pending.Push({ Split: split, B: B, Component: _component })
                    continue
                }
                _Proc(&Prop)
            }
        }
        i := 0
        loop 100 { ; 100 is arbitrary
            if !Pending.Length {
                break
            }
            if ++i > Pending.Length {
                i := 1
            }
            if BaseObjects.Has(Pending[i].Split[-1]) {
                O := Pending.RemoveAt(i)
                B := O.B
                ObjSetBase(B, BaseObjects.Get(O.Split[-1]))
                i--
                Prop := B.NameCollection
                index := B.IndexCollection
                _component := O.Component
                _Proc(&Prop)
            }
        }
        i := CollectionList.Length + 1
        loop CollectionList.Length {
            if CollectionList.Has(--i) {
                break
            }
        }
        CollectionList.Length := i
        this.ComponentList := ComponentList(Config.Capacity)
        this.RemovedCollection := RemovedCollection(this)
        this.__FillerReplacement := FillStr(this.Config.ReplacementChar)
        ; `StackContextBase` is the base for `ParseStack.Context` objects.
        ObjSetBase(this.__StackContextBase := {
            Bounds: [{ Start: 1 }]
          , Depth: 0
          , IsClass: false
          , Name: ''
          , Pos: 1
          , PosEnd: StrLen(this.Content)
          , Script: this
        }, ParseStack.Context.Prototype)
        this.Stack := ParseStack(this.__StackContextBase)
        this.Stack.Constructor := ClassFactory(this.__StackContextBase)
        this.Length := StrLen(this.Content)
        this.GlobalCollection := GlobalCollection(this.Config.Capacity)

        _Proc(&Prop) {
            ; `B` is the base object for components in this collection.
            BaseObjects.Set(Prop, B)
            ; Get props from prototype.
            _Proto := _component.Prototype
            for _Prop in _Proto.OwnProps() {
                B.DefineProp(_Prop, _Proto.GetOwnPropDesc(_Prop))
            }
            ; This is temporary; when I expand the script all collections will be used. But for now
            ; most of them are not in use.
            flag := 0
            for _prop in ToCollectionsObj {
                if Prop = _prop {
                    ToCollectionsObj.RemoveAt(A_Index)
                    flag := 1
                    break
                }
            }
            if flag {
                CollectionList[index] := ComponentCollection(B, Config.Capacity)
                CollectionIndex.Set(Prop, index)
                ; Set `ComponentCollectionObj.Constructor`.
                CollectionList[index].Constructor := ClassFactory(B, Prop)
            }
        }
    }

    Dispose() {
        this.__ComponentBaseBase.DeleteProp('Script')
        this.DeleteProp('__ComponentBaseBase')
        this.__StackContextBase.DeleteProp('Script')
        this.DeleteProp('__StackContextBase')
    }

    GetCollection(Name) {
        return this.CollectionList[this.CollectionIndex.Get(Name)]
    }

    GetText(PosStart := 1, Len?) {
        return SubStr(this.Content, PosStart, Len ?? unset)
    }

    GetTextFull(PosStart := 1, Len?) {
        Text := SubStr(this.Content, PosStart, Len ?? unset)
        Pos := 1
        _removedCollection := this.RemovedCollection
        loop {
            if !RegExMatch(Text, SPP_REPLACEMENT, &Match, Pos) {
                break
            }
            rc := _removedCollection.Get(this.NameCollection[Match['collection']])[Match['index']].Removed
            Text := StrReplace(Text, rc.Replacement, rc.Text)
            Pos := Match.Pos + Match.Len
        }
        ShortCollection := _removedCollection.ShortCollection
        index := ShortCollection.__CharStartIndex
        EndIndex := ShortCollection.__CharIndex
        Pos := 1
        loop {
            if RegExMatch(Text, Chr(Index) '(\d+)', &Match, Pos) {
                rc := ShortCollection.Get(Chr(Index))[Match[1]].Removed
                Text := StrReplace(Text, rc.Replacement, rc.Text)
                Pos := Match.Pos + Match.Len
            } else {
                if ++index > EndIndex {
                    break
                }
                Pos := 1
            }
        }
        return StrReplace(StrReplace(Text, SPR_QUOTE_CONSECUTIVEDOUBLE, '""'), SPR_QUOTE_CONSECUTIVESINGLE, "''")
    }

    ParseClass() {
        le := this.LineEnding
        Stack := this.Stack
        Stack.Line := Stack.Pos := 1
        ClassConstructor := this.CollectionList[SPC_CLASS].Constructor
        StaticMethodConstructor := this.CollectionList[SPC_STATICMETHOD].Constructor
        InstanceMethodConstructor := this.CollectionList[SPC_INSTANCEMETHOD].Constructor
        StaticPropertyConstructor := this.CollectionList[SPC_STATICPROPERTY].Constructor
        InstancePropertyConstructor := this.CollectionList[SPC_INSTANCEPROPERTY].Constructor
        FunctionConstructor := this.CollectionList[SPC_FUNCTION].Constructor
        ; Save the method if it already exists.
        if RegExMatchInfo.Prototype.HasMethod('__Get') {
            TempGetter := RegExMatchInfo.Prototype.__Get
        }
        ; To prevent an error when attempting to check if there was a specific subcapture group.
        RegExMatchInfo.Prototype.DefineProp('__Get', { Call: _REMIGetHelper })
        ; If there are no class definitions in the content, parse functions in the global scope
        if !RegExMatch(this.Content, SPP_CLASS, &Match) {
            Stack.PosEnd := StrLen(this.Content)
            _Proc()
            return
        }
        Stack.PosEnd := Match.Pos
        Stack.NextClass := Match

        ; This is the primary parse loop. This function parses the following nodes:
        ; - Class definitions
        ;   - Property and method definitions
        ; - Global named function definitions that do not occur within an expression
        loop {
            ; Parse the content in-between class definitions
            if Stack.PosEnd - Stack.Pos > 0 {
                _Proc()
            }
            ; Exit any active class scopes that will close before the beginning of the next class definition
            while Stack.ActiveClass && Stack.NextClass.Pos > Stack.ActiveClass.PosEnd {
                Stack.Out()
            }
            ; Enter into the scope
            Component := Stack.In(this, Match['name'], Match, ClassConstructor)
            ; Handle initialization tasks that are specific to a component type
            Component.Init(Match)
            ; The previous lines have already determined that there are no more property or function
            ; definitions between the current position and the class definition, so we move the
            ; position to beginning of the class definition to prevent `RegExMatch` from matching
            ; with the same class definition. This moves it to right before the end of the first line.
            Stack.Pos := InStr(Match['text'], le) - 1 + Match.Pos['text']
            ; Adjust the line count as well
            Stack.Line := Stack.ActiveClass.LineStart
            ; Find next class definition
            if RegExMatch(this.Content, SPP_CLASS, &Match, Stack.Pos) {
                ; Set next class definition
                Stack.NextClass := Match
                ; If the next class definition occurs outside of the current class definition
                if Match.Pos > Stack.ActiveClass.PosEnd {
                    ; Parse the content up to the end of the current class definition
                    Stack.PosEnd := Stack.ActiveClass.PosEnd
                    _Proc()
                    ; Exit the scope
                    Stack.Out()
                }
                ; Set the end position to the beginning of the next class definition
                Stack.PosEnd := Match.Pos
            ; If there are no more class definitions
            } else {
                ; Set the end position to the end of the current class definition
                Stack.PosEnd := Stack.ActiveClass.PosEnd
                ; Parse the content
                _Proc()
                ; Exit the definition
                Stack.Out()
                ; If there is more content in the global scope, parse it
                if StrLen(RTrim(this.Content, '`r`n`s`t')) - Stack.Pos > 0 {
                    Stack.PosEnd := StrLen(this.Content)
                    _Proc()
                }
                break
            }
        }

        if IsSet(TempGetter) {
            RegExMatchInfo.Prototype.DefineProp('__Get', { Call: TempGetter })
        } else {
            RegExMatchInfo.Prototype.DeleteProp('__Get')
        }

        return

        _Proc() {
            local _Match
            ; How the constructor is identified varies depending on the scope
            Callback := Stack.Active.IsClass ? _GetConstructorClassActive : _GetConstructorGlobal
            loop {
                ; If there's no more function / property definitions
                if !RegExMatch(this.Content, SPP_PROPERTY, &_Match, Stack.Pos) {
                    break
                }
                ; If the next function / property definition occurs outside of the current class definition
                if _Match.Pos > Stack.PosEnd {
                    return
                }
                ; Assignment and arrow operators can potentially be followed by a continuation section.
                ; `ContinuationSection` will identify and concatenate a continuation section.
                if _Match['arrow'] || _Match.assign {
                    CS := ContinuationSection(
                        StrPtr(this.Content)
                      , _Match.Pos['text']
                      , _Match['arrow'] ? '=>' : ':='
                    )
                } else {
                    CS := _Match
                }
                ; Create the context object
                Component := Stack.In(this, _Match['name'], CS, Callback())
                ; Handle initialization tasks that are specific to a component type
                Component.Init(_Match)
                ; Parse function / property accessor parameters if present
                Component.GetParams(_Match)
                ; Move the position
                Stack.Pos := _Match.Pos['text'] + _Match.Len['text']
                ; Exit the function / property scope
                Stack.Out()
                ; Adjust the line count to the end of the function / property definition
                Stack.Line := Component.LineEnd
            }

            _GetConstructorClassActive() {
                if _Match.Mark == 'func' {
                    if _Match['static'] {
                        return StaticMethodConstructor
                    } else {
                        return InstanceMethodConstructor
                    }
                } else {
                    if _Match['static'] {
                        return StaticPropertyConstructor
                    } else {
                        return InstancePropertyConstructor
                    }
                }
            }
            _GetConstructorGlobal() => FunctionConstructor
        }

        _REMIGetHelper(Self, Name, *) {
            if Name = 'assign' || Name = 'inner' {
                return false
            }
            throw PropertyError('Property does not exist on the object.', -1, Name)
        }

        ; Parsing nested functions is complicated and will require a tokenizer and a more advanced
        ; context stack. I'm holding off on that for now.
        ; _Recurse(PosEnd) {
        ;     local _Match
        ;     ; We use the text up to the end of the current definition
        ;     , Text := SubStr(this.Content, Stack.Pos, PosEnd)
        ;     loop {
        ;         ; If there's no more function / property definitions
        ;         if !RegExMatch(Text, SPP_FUNCTION, &_Match, Stack.Pos) {
        ;             break
        ;         }
        ;         ; Arrow operators can potentially be followed by a continuation section.
        ;         ; `ContinuationSection` will identify and concatenate a continuation section.
        ;         if _Match['arrow'] {
        ;             CS := ContinuationSection(
        ;                 StrPtr(Text)
        ;               , _Match.Pos['text']
        ;               , '=>'
        ;             )
        ;         } else {
        ;             CS := _Match
        ;         }
        ;         ; Create the context object. Anonymous functions get the name '()'
        ;         Component := Stack.In(this, _Match['name'] || '()', CS, FunctionConstructor)
        ;         ; Handle initialization tasks that are specific to a component type
        ;         Component.Init(_Match)
        ;         ; Parse function / property accessor parameters if present
        ;         Component.GetParams(_Match)
        ;         ; Move the position
        ;         Stack.Pos := _Match.Pos['text']
        ;         ; Recurse into the definition
        ;         _Recurse(_Match.Pos['text'] + _Match.Len['text'])
        ;         ; Move the position
        ;         Stack.Pos := _Match.Pos['text'] + _Match.Len['text']
        ;         ; Exit the function / property scope
        ;         Stack.Out()
        ;         ; Adjust the line count to the end of the function / property definition
        ;         Stack.Line := Component.LineEnd
        ;     }
        ; }
    }

    /**
     * @description - `ScriptParser.Prototype.RemoveStringsAndComments` removes quoted strings and
     * comments from the content. A component is created for each item that is removed from the text.
     * The components are not associated with a stack initially; to identify the components' position
     * in the stack, call `ScriptParser.Prototype.SetRemovedComponentStack`.
     *
     * The match objects have additional subcapture groups which you can use to analyze the content
     * that was removed. All matches have the following:
     * - **text**: The text that was removed from the content.
     *
     * Continuation sections:
     * - **comment**: The last comment between the open quote character and the open bracket character,
     * if any are present.
     * - **quote**: The open quote character.
     * - **body**: The text content between the open bracket and the close bracket, i.e. the continuation
     * section's string value.
     * - **tail**: Any code that is on the same line as the close bracket, after the close quote character.
     *
     * Single line comments:
     * - **comment**: The content of the comment without the semicolon character and without leading
     * whitespace.
     *
     * Multi-line comments:
     * - **comment**: The content of the comment without the the open and closing operators
     * (/ * and * /) and without the surrounding whitespace.
     *
     * Jsdoc comments:
     * - **comment**: The content of the comment without the open and closing operators (/ * * and * /)
     * and without the surrounding whitespace.
     * - **line**: The next line following the comment, included so the comment can be paired with
     * whatever it is describing. If the next line of text is a class definition, these subgroups
     * are used:
     *   - **class**: The class name. This will always be present.
     *   - **super**: If the class has the `extends` keyword, this subgroup will contain the name of
     * the superclass.
     * If the next line of text is a class method, property, or function definition, these subgroups
     * are used:
     *   - **name**: The name of the method, property, or function. This will always be present.
     *   - **static**: The `static` keyword, if present.
     *   - **func**: If it is a function definition, then this subgroup will contain the open
     * parentheses. This is mostly to indicate whether its a function or property.
     *   - **prop**: If it is a property definition, then this subgroup will contain the first character
     * following the property name.
     *
     * Quoted strings:
     * - **string**: The text content of the quoted string, without the encompassing quote characters.
     */
    RemoveStringsAndComments() {
        global SPP_REMOVE_CONTINUATION, SPP_REMOVE_LOOP
        le := this.LineEnding
        ; Remove consecutive quotes
        this.Content := RegExReplace(this.Content, SPP_QUOTE_CONSECUTIVEDOUBLE, SPR_QUOTE_CONSECUTIVEDOUBLE, &DoubleCount)
        this.Content := RegExReplace(this.Content, SPP_QUOTE_CONSECUTIVESINGLE, SPR_QUOTE_CONSECUTIVESINGLE, &SingleCount)
        this.RemovedCollection.ConsecutiveDoubleQuotes := DoubleCount
        this.RemovedCollection.ConsecutiveSingleQuotes := SingleCount
        ; Remove continuation sections.
        _Process(&SPP_REMOVE_CONTINUATION)
        ; Remove other quotes and comments.
        _Process(&SPP_REMOVE_LOOP)

        return

        _Process(&Pattern) {
            Pos := 1
            nl := 1
            ; This is the procedure flow for removing content and adding a value to a collection
            loop {
                if !RegExMatch(this.Content, Pattern, &Match, Pos) {
                    break
                }
                ; Get line count of the segment leading up to the match
                StrReplace(SubStr(this.Content, Pos, Match.Pos - Pos), le, , , &linecount)
                ; Calculate line start
                LineStart := nl += linecount
                ; Calculate col start
                ColStart := Match.Pos['text'] - Match.Pos
                ; Get line count of the text that will be removed
                StrReplace(Match['text'], le, , , &linecount)
                ; Calculate line end
                LineEnd := nl += (linecount || 0)
                ; Calculate col end
                if LineEnd == LineStart {
                    ColEnd := ColStart + Match.Len['text']
                } else {
                    ColEnd := Match.Len['text'] - InStr(Match['text'], le, , , -1)
                }
                ; Adjust pos
                Pos := Match.Pos['text'] + Match.Len['text']
                ; Get constructor. The `Mark` value is the symbol `SPC_<collection name>` as string
                Constructor := this.CollectionList[%Match.Mark%].Constructor
                ; Call constructor. The constructor handles the rest.
                Constructor(LineStart, ColStart, LineEnd, ColEnd, Match.Pos['text'], Match.Len['text'], , Match)
            }
        }
    }

    Encoding => this.Config.Encoding
    Name => this.Config.Name
    NameCollection[IndexCollection] => this.CollectionList[IndexCollection].NameCollection
    PathIn => this.Config.PathIn
    Text[PosStart := 1, Len?] => SubStr(this.Content, PosStart, Len ?? unset)
    TextFull[PosStart := 1, Len?] => this.GetTextFull(PosStart, Len ?? unset)

}

