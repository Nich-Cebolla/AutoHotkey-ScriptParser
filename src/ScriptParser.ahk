

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
        ToCollectionsObj := ['Class', 'CommentMultiline', 'CommentSingleline', 'Function', 'Getter', 'InstanceMethod'
        , 'InstanceProperty', 'Jsdoc', 'Setter', 'StaticMethod', 'StaticProperty', 'String']
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
        loop 100 {
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
        ObjSetBase(this.__StackContextBase := { Script: this, Name: '', Pos: 1, PosEnd: StrLen(this.Content), IsClass: false }, ParseStack.Context.Prototype)
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
        global
        try {
            index := %'SPC_' name%
        } catch {
            index := this.CollectionIndex.Get(Name)
        }
        return this.CollectionList[index]
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

    ParseClass2() {
        nl := 1
        le := this.LineEnding
        Stack := this.Stack
        ClassConstructor := this.CollectionList[SPC_CLASS].Constructor
        StaticMethodConstructor := this.CollectionList[SPC_STATICMETHOD].Constructor
        InstanceMethodConstructor := this.CollectionList[SPC_INSTANCEMETHOD].Constructor
        StaticPropertyConstructor := this.CollectionList[SPC_STATICPROPERTY].Constructor
        InstancePropertyConstructor := this.CollectionList[SPC_INSTANCEPROPERTY].Constructor
        FunctionConstructor := this.CollectionList[SPC_FUNCTION].Constructor
        _Recurse(this.Content)

        return

        _Recurse(Text) {
            Pos := 1
            loop {
                if !RegExMatch(Text, SPP_CLASS, &Match, Pos) {
                    break
                }
                if InStr(Match[0], 'class PropsInfoItem') {
                    sleep 1
                }
                StrReplace(SubStr(Text, Pos, Match.Pos - Pos), le, , , &linecount)
                LineStart := nl + linecount
                ColStart := Match.Pos['text'] - Match.Pos
                StrReplace(Match['text'], le, , , &linecount)
                LineEnd := LineStart + linecount
                if LineEnd == LineStart {
                    ColEnd := ColStart + Match.Len['text']
                } else {
                    ColEnd := Match.Len['text'] - InStr(Match['text'], le, , , -1)
                }
                _Proc(Pos, Match.Pos)
                nl := LineStart
                Stack.In(Match['name'], Match.Pos['text'], Match.Pos['body'] + Stack.Active.RecursiveOffset - 1)
                Stack.SetComponent(ClassConstructor(LineStart, ColStart, LineEnd, ColEnd, Stack.Active.Pos
                , Match.Len['text'], Stack, , , Match.Pos['body'] + Stack.Active.Base.RecursiveOffset, Match.Len['body'], Match))
                Pos := Match.Pos + Match.Len - 1
                if _Recurse(Match['body']) {
                    if StrLen(RTrim(this.Content, '`s`t`r`n')) - Match.Pos['body'] > 4 {
                        _Proc(Match.Pos['body'], StrLen(this.Content))
                    }
                }
            }
            if Stack.Depth {
                Stack.Out()
            } else {
                return 1
            }

            _Proc(PosStart, PosEnd) {
                if Stack.Active.IsClass {
                    _Text := SubStr(Text, PosStart, PosEnd - PosStart)
                    _Pos := 1
                    loop {
                        if !RegExMatch(_Text, SPP_PROPERTY, &_Match, _Pos) {
                            break
                        }
                        StrReplace(SubStr(_Text, _Pos, _Match.Pos - _Pos), le, , , &linecount)
                        _LineStart := nl += linecount
                        _ColStart := _Match.Pos['text'] - _Match.Pos
                        if _Match['arrow'] || _Match['assign'] {
                            ParseContinuationSection(&_Text, _Match.Pos['text'], _Match['arrow'] ? '=>' : ':='
                            , &PosEnd, &Body, &LenBody, &FullStatement, &LenFullStatement)
                        } else {
                            FullStatement := _Match['text']
                            LenFullStatement := _Match.Len['text']
                            LenBody := _Match.Len['body']
                        }
                        StrReplace(FullStatement, le, , , &linecount)
                        _LineEnd := nl += linecount
                        if _LineEnd == _LineStart {
                            _ColEnd := _ColStart + LenFullStatement
                        } else {
                            _ColEnd := LenFullStatement - InStr(FullStatement, le, , , -1)
                        }
                        ClassComponent := Stack.ActiveClass
                        Stack.In(_Match['name'], _Match.Pos['text'], _Match.Pos['body'] + Stack.Active.RecursiveOffset)
                        if _Match.Mark == 'func' {
                            if _Match['static'] {
                                _constructor := StaticMethodConstructor
                            } else {
                                _constructor := InstanceMethodConstructor
                            }
                        } else {
                            if _Match['static'] {
                                _constructor := StaticPropertyConstructor
                            } else {
                                _constructor := InstancePropertyConstructor
                            }
                        }
                        Stack.SetComponent(_constructor(_LineStart, _ColStart
                        , _LineEnd, _ColEnd, Stack.Active.Pos, LenFullStatement, Stack
                        , , , _Match.Pos['body'] + Stack.Active.Base.RecursiveOffset, LenBody
                        , [_Match, ClassComponent]))
                        _Pos := _Match.Pos['text'] + LenFullStatement
                        Stack.Out()
                    }
                } else {
                    _Text := SubStr(Text, PosStart, PosEnd - PosStart)
                    _Pos := 1
                    loop {
                        if !RegExMatch(_Text, SPP_FUNCTION, &_Match, _Pos) {
                            break
                        }
                        StrReplace(SubStr(_Text, _Pos, _Match.Pos - _Pos), le, , , &linecount)
                        _LineStart := nl += linecount
                        _ColStart := _Match.Pos['text'] - _Match.Pos
                        if _Match['arrow'] {
                            ParseContinuationSection(&_Text, _Match.Pos['text'], _Match['arrow'] ? '=>' : ':='
                            , &PosEnd, &Body, &LenBody, &FullStatement, &LenFullStatement)
                        } else {
                            FullStatement := _Match['text']
                            LenFullStatement := _Match.Len['text']
                            LenBody := _Match.Len['body']
                        }
                        StrReplace(FullStatement, le, , , &linecount)
                        _LineEnd := nl += linecount
                        if _LineEnd == _LineStart {
                            _ColEnd := _ColStart + LenFullStatement
                        } else {
                            _ColEnd := LenFullStatement - InStr(FullStatement, le, , , -1)
                        }
                        Stack.In(_Match['name'], _Match.Pos['text'], _Match.Pos['body'] + Stack.Active.RecursiveOffset)
                        Stack.SetComponent(FunctionConstructor(_LineStart, _ColStart
                        , _LineEnd, _ColEnd, Stack.Active.Pos, LenFullStatement, Stack
                        , , , _Match.Pos['body'] + Stack.Active.Base.RecursiveOffset, LenBody, _Match))
                        _Pos := _Match.Pos['text'] + LenFullStatement
                        Stack.Out()
                    }
                }
            }
        }
    }

    ParseClass() {
        le := this.LineEnding
        Stack := this.Stack
        Stack.nl := Stack.Pos := 1
        ClassConstructor := this.CollectionList[SPC_CLASS].Constructor
        StaticMethodConstructor := this.CollectionList[SPC_STATICMETHOD].Constructor
        InstanceMethodConstructor := this.CollectionList[SPC_INSTANCEMETHOD].Constructor
        StaticPropertyConstructor := this.CollectionList[SPC_STATICPROPERTY].Constructor
        InstancePropertyConstructor := this.CollectionList[SPC_INSTANCEPROPERTY].Constructor
        FunctionConstructor := this.CollectionList[SPC_FUNCTION].Constructor
        if !RegExMatch(this.Content, SPP_CLASS, &Match) {
            Stack.PosEnd := StrLen(this.Content)
            _Proc()
            return
        }
        Stack.PosEnd := Match.Pos
        Stack.NextClass := Match
        loop {
            ; if InStr(Match[0], 'class PropsInfoItem') {
            ;     sleep 1
            ; }
            if Stack.PosEnd - Stack.Pos > 4 {
                _Proc()
            }
            StrReplace(SubStr(this.Content, Stack.Pos, Match.Pos['body'] - Stack.Pos), le, , , &linecount)
            LineStart := Stack.nl + linecount
            ColStart := Match.Pos['text'] - Match.Pos
            StrReplace(Match['text'], le, , , &linecount)
            LineEnd := LineStart + linecount
            if LineEnd == LineStart {
                ColEnd := ColStart + Match.Len['text']
            } else {
                ColEnd := Match.Len['text'] - InStr(Match['text'], le, , , -1)
            }
            ; Stack.nl := LineStart
            while Stack.ActiveClass && Stack.NextClass.Pos > Stack.ActiveClass.PosEnd {
                Stack.Out()
            }
            Stack.In(Match['name'], Match.Pos['text'], Match.Pos + Match.Len)
            Stack.SetComponent(ClassConstructor(
                LineStart
              , ColStart
              , LineEnd
              , ColEnd
              , Match.Pos['text']
              , Match.Len['text']
              , Stack
              ,
              ,
              , Match.Pos['body']
              , Match.Len['body']
              , Match
            ))
            Stack.Pos := Match.Pos['body']
            if RegExMatch(this.Content, SPP_CLASS, &Match, Stack.Pos) {
                Stack.NextClass := Match
                if Match.Pos > Stack.ActiveClass.PosEnd {
                    Stack.PosEnd := Stack.ActiveClass.PosEnd
                    _Proc()
                    Stack.Out()
                }
                Stack.PosEnd := Match.Pos
            } else {
                Stack.PosEnd := Stack.ActiveClass.PosEnd
                _Proc()
                Stack.Out()
                if StrLen(RTrim(this.Content, '`r`n`s`t')) - Stack.Pos > 4 {
                    Stack.PosEnd := StrLen(this.Content)
                    _Proc()
                }
                break
            }
        }

        return

        _Proc() {
            if Stack.Active.IsClass {
                loop {
                    if !RegExMatch(this.Content, SPP_PROPERTY, &_Match, Stack.Pos) {
                        break
                    }
                    if _Match.Pos > Stack.PosEnd {
                        return
                    }
                    StrReplace(SubStr(this.Content, Stack.Pos, _Match.Pos - Stack.Pos), le, , , &linecount)
                    _LineStart := Stack.nl += linecount
                    _ColStart := _Match.Pos['text'] - _Match.Pos
                    if _Match['arrow'] || _Match['assign'] {
                        Offset := _Match.Pos['text']
                        ParseContinuationSection(
                            &(Text := SubStr(this.Content, Offset, Stack.PosEnd - Offset))
                          , 1
                          , _Match['arrow'] ? '=>' : ':='
                          , &PosEnd, &Body, &LenBody, &FullStatement, &LenFullStatement
                        )
                    } else {
                        FullStatement := _Match['text']
                        LenFullStatement := _Match.Len['text']
                        LenBody := _Match.Len['body']
                    }
                    StrReplace(FullStatement, le, , , &linecount)
                    _LineEnd := Stack.nl += linecount
                    if _LineEnd == _LineStart {
                        _ColEnd := _ColStart + LenFullStatement
                    } else {
                        _ColEnd := LenFullStatement - InStr(FullStatement, le, , , -1)
                    }
                    Stack.In(_Match['name'], _Match.Pos['text'], _Match.Pos['text'] + _Match.Len['text'])
                    if _Match.Mark == 'func' {
                        if _Match['static'] {
                            _constructor := StaticMethodConstructor
                        } else {
                            _constructor := InstanceMethodConstructor
                        }
                    } else {
                        if _Match['static'] {
                            _constructor := StaticPropertyConstructor
                        } else {
                            _constructor := InstancePropertyConstructor
                        }
                    }
                    Stack.SetComponent(
                        _constructor(
                            _LineStart
                          , _ColStart
                          , _LineEnd
                          , _ColEnd
                          , _Match.Pos['text']
                          , LenFullStatement
                          , Stack
                          ,
                          ,
                          , _Match.Pos['body']
                          , LenBody
                          , [_Match, Stack.ActiveClass]
                    ))
                    Stack.Pos := _Match.Pos['text'] + LenFullStatement
                    Stack.Out()
                }
            } else {
                loop {
                    if !RegExMatch(this.Content, SPP_PROPERTY, &_Match, Stack.Pos) {
                        return
                    }
                    if _Match.Pos > Stack.PosEnd {
                        return
                    }
                    StrReplace(SubStr(this.Content, Stack.Pos, _Match.Pos - Stack.Pos), le, , , &linecount)
                    _LineStart := Stack.nl += linecount
                    _ColStart := _Match.Pos['text'] - _Match.Pos
                    if _Match['arrow'] {
                        Offset := _Match.Pos['text']
                        ParseContinuationSection(
                            &(Text := SubStr(this.Content, Offset, Stack.PosEnd - Offset))
                          , 1
                          , '=>'
                          , &PosEnd, &Body, &LenBody, &FullStatement, &LenFullStatement
                        )
                    } else {
                        FullStatement := _Match['text']
                        LenFullStatement := _Match.Len['text']
                        LenBody := _Match.Len['body']
                    }
                    StrReplace(FullStatement, le, , , &linecount)
                    _LineEnd := Stack.nl += linecount
                    if _LineEnd == _LineStart {
                        _ColEnd := _ColStart + LenFullStatement
                    } else {
                        _ColEnd := LenFullStatement - InStr(FullStatement, le, , , -1)
                    }
                    Stack.In(_Match['name'], _Match.Pos['text'], _Match.Pos['text'] + _Match.Len['text'])
                    Stack.SetComponent(
                        FunctionConstructor(
                            _LineStart
                          , _ColStart
                          , _LineEnd
                          , _ColEnd
                          , _Match.Pos['text']
                          , LenFullStatement
                          , Stack
                          ,
                          ,
                          , _Match.Pos['body']
                          , LenBody
                          , _Match
                    ))
                    Stack.Pos := _Match.Pos['text'] + LenFullStatement
                    Stack.Out()
                }
            }
        }
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
     * parentheses. This is mostly to indicate whether its a function or property, but you can also
     * use the position of the character for some tasks.
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

