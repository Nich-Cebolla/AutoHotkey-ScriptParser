
/**
 * @classdesc - Parses an AHK script into its components.
 */
class ScriptParser {
    static __New() {
        this.DeleteProp('__New')
        this.Collection := Map()
        this.Collection.CaseSense := false
    }
    static __Add(obj) {
        this.Collection.Set(obj.IdScriptParser, obj)
        ObjRelease(ObjPtr(obj))
    }
    static __GetUid() {
        loop 100 {
            n := Random(1, 4294967295)
            if !this.Collection.Has(n) {
                return n
            }
        }
        throw Error('Failed to produce a unique id.')
    }
    /**
     * @description -
     * @class
     * @param {Object|ScriptParser.Options} Options - An object with zero or more options
     * as property : value pairs, or a {@link ScriptParser.Options} object.
     */
    __New(Options) {
        this.IdScriptParser := ScriptParser.__GetUid()
        ScriptParser.__Add(this)
        Options := this.Options := ScriptParser.Options(Options ?? {})
        this.Collection := ScriptParser_Collection(this)
        if IsSet(Path) {
            this.Content := FileRead(Path, this.Encoding || unset)
        } else if IsSet(Content) {
            this.Content := Content
        } else if Options.Path {
            this.Content := FileRead(this.Path, this.Encoding || unset)
        } else if Options.Content {
            this.Content := Options.Content
        } else {
            throw Error('``ScriptParser`` requires either a content string or file path.')
        }
        n := 0x2000
        this.__FillerReplacement := ScriptParser_FillStr(Chr(_GetOrd()))
        this.__LoneSemicolonReplacement := _GetOrd()
        this.__ConsecutiveDoubleReplacement := _GetOrd()
        this.__ConsecutiveSingleReplacement := _GetOrd()
        if Options.EndOfLine {
            this.Content := RegExReplace(this.Content, '\R', Options.EndOfLine)
            this.EndOfLine := Options.EndOfLine
        } else {
            ; Get line endings.
            StrReplace(this.Content, '`n', , , &countlf)
            StrReplace(this.Content, '`r', , , &countcr)
            if countcr {
                if countlf {
                    if countcr == countlf {
                        RegExMatch(this.Content, '\R', &mEndOfLine)
                        this.EndOfLine := mEndOfLine[0]
                    } else {
                        throw Error('The script content has mixed line endings.')
                    }
                } else {
                    this.EndOfLine := '`r'
                }
            } else if countlf {
                this.EndOfLine := '`n'
            } else {
                this.EndOfLine := ''
            }
        }
        ; `Script.CollectionIndex` is a map with name : index pairs. The indices are associated
        ; with `Script.CollectionList` items. To get an item by name: `Script.CollectionList[Script.CollectionIndex.Get(Name)]`.
        CollectionIndex := this.CollectionIndex := ScriptParser_ComponentCollectionIndex(ObjOwnPropCount(ScriptParser_Ahk.Component))
        CollectionList := this.CollectionList := ScriptParser_ComponentCollectionList(ObjOwnPropCount(ScriptParser_Ahk.Component))
        Component := ScriptParser_Ahk.Component
        ; `ScriptParser_ComponentBaseBase` is the base for component objects.
        ScriptParser_ComponentBaseBase := this.__ScriptParser_ComponentBaseBase := { IdScriptParser: this.IdScriptParser }
        ObjSetBase(ScriptParser_ComponentBaseBase, ScriptParser_ComponentBase.Prototype)
        BaseObjects := Map()
        BaseObjects.CaseSense := false
        BaseObjects.Set('ScriptParser_ComponentBase', ScriptParser_ComponentBaseBase)
        LangContent := FileRead(ScriptParser_Ahk.__GetPath())
        Pending := []
        ToCollectionsObj := ['Class', 'CommentBlock', 'CommentMultiline', 'CommentSingleline'
        , 'Function', 'Getter', 'InstanceMethod', 'InstanceProperty', 'Jsdoc', 'Setter', 'StaticMethod'
        , 'StaticProperty', 'String']
        for Prop in Component.OwnProps() {
            _component := Component.%Prop%
            if _component is Class {
                ; To recreate the inheritance chains for each of the components' prototypes, this
                ; reads the content in the language file and identifies the superclass for each
                ; component class, then assigns the correct base.
                if !RegExMatch(LangContent, 'i)class[ \t]+' Prop '[ \t]+extends[ \t]+(?<super>[\w.]+)', &Match) {
                    throw Error('Failed to match the collection`'s class definition statement.')
                }
                ; The index values are defined in "define.ahk".
                index := %'SPC_' Prop%
                B := { NameCollection: Prop, IndexCollection: index }
                split := StrSplit(Match['super'], '.')
                if BaseObjects.Has(split[-1]) {
                    ObjSetBase(B, BaseObjects.Get(split[-1]))
                    _Proc(&Prop)
                } else {
                    Pending.Push({ Split: split, B: B, Component: _component })
                }
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
        this.ComponentList := ScriptParser_ComponentList()
        this.RemovedCollection := ScriptParser_RemovedCollection(this)
        ; `StackContextBase` is the base for `ScriptParser_Stack.Context` objects.
        this.__StackContextBase := {
            Bounds: [ { Start: 1 } ]
          , Depth: 0
          , IsClass: false
          , Name: ''
          , Pos: 1
          , PosEnd: StrLen(this.Content)
          , IdScriptParser: this.IdScriptParser
        }
        ObjSetBase(this.__StackContextBase, ScriptParser_Stack.Context.Prototype)
        this.Stack := ScriptParser_Stack(this.__StackContextBase)
        this.Stack.Constructor := ScriptParser_ClassFactory(this.__StackContextBase)
        this.Length := StrLen(this.Content)
        this.GlobalCollection := ScriptParser_GlobalCollection()
        if !Options.DeferProcess {
            this.Process()
        }

        return

        _GetOrd() {
            loop {
                if InStr(this.Content, Chr(n)) {
                    ++n
                } else {
                    return n
                }
            }
        }
        _Proc(&Prop) {
            ; `B` is the base object for components in this collection.
            BaseObjects.Set(Prop, B)
            ; Get props from prototype.
            _Proto := _component.Prototype
            for _Prop in _Proto.OwnProps() {
                B.DefineProp(_Prop, _Proto.GetOwnPropDesc(_Prop))
            }
            flag := 0
            for _prop in ToCollectionsObj {
                if Prop = _prop {
                    ToCollectionsObj.RemoveAt(A_Index)
                    flag := 1
                    break
                }
            }
            if flag {
                if index == SPC_JSDOC {
                    CollectionList[index] := ScriptParser_JsdocCollection(B)
                } else {
                    CollectionList[index] := ScriptParser_ComponentCollection(B)
                }
                CollectionIndex.Set(Prop, index)
                CollectionList[index].Constructor := ScriptParser_ClassFactory(B, Prop)
            }
        }
    }
    Cleanup() {
        for prop in [ '__FillerReplacement', '__ScriptParser_ComponentBaseBase', '__StackContextBase'
        , 'Stack' ] {
            if this.HasOwnProp(prop) {
                this.DeleteProp(prop)
            }
        }
    }
    /**
     * @description - Returns a collections object.
     * @param {String} Name - The name of the collection. The following values are currently in use:
     * "Class", "CommentMultiLine", "CommentSingleLine", "Function", "Getter", "InstanceMethod",
     * "InstanceProperty", "Jsdoc", "Setter", "StaticMethod", "StaticProperty", "String".
     * @returns {ScriptParser.ScriptParser_ComponentCollection} - The collection object. Collection objects
     * are map objects with additional properties and methods.
     */
    GetCollection(Name) {
        return this.CollectionList[this.CollectionIndex.Get(Name)]
    }
    /**
     * @description - Returns text from the script, with strings and comments still removed from
     * the text.
     * @param {Integer} [PosStart=1] - The character start position.
     * @param {Integer} [Len] - The number of characters to include.
     * @returns {String}
     */
    GetText(PosStart := 1, Len?) {
        return SubStr(this.Content, PosStart, Len ?? unset)
    }
    /**
     * @description - Returns the original, unmodified text from the script.
     * @param {Integer} [PosStart=1] - The character start position.
     * @param {Integer} [Len] - The number of characters to include.
     * @returns {String}
     */
    GetTextFull(PosStart := 1, Len?) {
        Text := SubStr(this.Content, PosStart, Len ?? unset)
        Pos := 1
        RemovedCollection := this.RemovedCollection
        loop {
            if !RegExMatch(Text, SPP_REPLACEMENT, &Match, Pos) {
                break
            }
            rc := RemovedCollection.Get(this.NameCollection[Match['collection']])[Match['index']].__Removed
            Text := StrReplace(Text, rc.Replacement, rc.Text)
            Pos := Match.Pos + Match.Len
        }
        ShortCollection := RemovedCollection.ShortCollection
        Index := ShortCollection.__CharStartCode
        EndIndex := ShortCollection.__CharCode
        Pos := 1
        loop {
            if RegExMatch(Text, Chr(Index) '(\d+)', &Match, Pos) {
                rc := ShortCollection.Get(Chr(Index))[Match[1]].__Removed
                Text := StrReplace(Text, rc.Replacement, rc.Text)
                Pos := Match.Pos + Match.Len
            } else {
                if ++Index > EndIndex {
                    break
                }
                Pos := 1
            }
        }
        return StrReplace(StrReplace(Text, Chr(this.__ConsecutiveDoubleReplacement) Chr(this.__ConsecutiveDoubleReplacement), '""')
        , Chr(this.__ConsecutiveSingleReplacement) Chr(this.__ConsecutiveSingleReplacement), "''")
    }
    AssociateComments() {
        listComponent := ScriptParser_QuickSort(this.ComponentList.ToArray(), (a, b) => a.LineStart - b.LineStart)
        i := 0
        loop  {
            if ++i > listComponent.Length {
                break
            }
            switch listComponent[i].IndexCollection {
                case SPC_JSDOC, SPC_COMMENTBLOCK, SPC_COMMENTMULTILINE, SPC_COMMENTSINGLELINE:
                    Component := listComponent[i]
                default:
                    if IsSet(Component) && listComponent[i].LineStart - 1 == Component.LineEnd {
                        Component.__CommentParent := listComponent[i].idu
                        listComponent[i].__Comment := Component.idu
                        if Component.IndexCollection = SPC_JSDOC {
                            listComponent[i].HasJsdoc := true
                        }
                    }
            }
        }
    }
    /**
     * @description - The primary parsing function. For most scripts, this must be called after
     * `ScriptParser.Prototype.RemoveStringsAndComments` to work correctly.
     */
    ParseClass() {
        eol := this.EndOfLine
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
        LastIndex := this.ComponentList.__ComponentIndex

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
            Component := Stack.In(this, Match['name'], Match, ClassConstructor, Match)
            ; Handle initialization tasks that are specific to a component type
            ; Component.Init(Match)
            ; The previous lines have already determined that there are no more property or function
            ; definitions between the current position and the class definition, so we move the
            ; position to beginning of the class definition to prevent `RegExMatch` from matching
            ; with the same class definition. This moves it to right before the end of the first line.
            Stack.Pos := InStr(Match['text'], eol) - 1 + Match.Pos['text']
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
                    ; Exit the class definition
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
                ; Exit any remaining class definitions
                while Stack.ClassList.Length {
                    Stack.Out()
                }
                ; If there is more content in the global scope, parse it
                if StrLen(RTrim(this.Content, '`r`n`s`t')) - Stack.PosEnd > 0 {
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
            LastIndex := this.ComponentList.__ComponentIndex
            ; How the constructor is identified varies depending on the scope
            Callback := Stack.Active.IsClass ? _GetConstructorClassActive : _GetConstructorGlobal
            ; Only check the text up to `Stack.PosEnd`
            Text := SubStr(this.Content, 1, Stack.PosEnd)
            loop {
                ; If there's no more function / property definitions
                if !RegExMatch(Text, SPP_PROPERTY, &_Match, Stack.Pos) {
                    break
                }
                ; Assignment and arrow operators can potentially be followed by a continuation section.
                ; `ScriptParser_ContinuationSection` will identify and concatenate a continuation section.
                if _Match['arrow'] || _Match.assign {
                    CS := ScriptParser_ContinuationSection(
                        StrPtr(this.Content)
                      , _Match.Pos['text']
                      , _Match['arrow'] ? '=>' : ':='
                    )
                } else {
                    CS := _Match
                }
                ; Create the context object
                Component := Stack.In(this, _Match['name'], CS, Callback(), _Match)
                Component.__AssociateRemovedComponents()
                ; Handle initialization tasks that are specific to a component type
                ; Component.Init(_Match)
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
            for N, str in Self {
                if N = Name {
                    return Self[Name]
                }
            }
            return false
        }
    }
    /**
     * @description - `ScriptParser.Prototype.RemoveStringsAndComments` removes quoted strings and
     * comments from the content. A component is created for each item that is removed from the text.
     * The components are not associated with a context initially.
     *
     * The match objects have additional subcapture groups which you can use to analyze the content
     * that was removed. All matches have the following:
     * - **text**: The text that was removed from the content.
     *
     * Quoted strings:
     * - **string**: The text content of the quoted string, without the encompassing quote characters.
     *
     * Continuation sections:
     * - **comment**: The last comment between the open quote character and the open bracket character,
     *   if any are present.
     * - **quote**: The open quote character.
     * - **body**: The text content between the open bracket and the close bracket, i.e. the continuation
     *   section's string value before the indentation is removed.
     * - **tail**: Any code that is on the same line as the close bracket, after the close quote character.
     *
     * Jsdoc comments and multi-line comments:
     * - **comment**: The content of the comment without the comment operator and without surrounding
     *   whitespace.
     *
     * Single-line comments:
     * - **comment**: If the single-line comment is a standalone comment (i.e. not part of a comment
     *   block consisting of consecutive lines of comments without code and each line having the same
     *   level of indentation), then the match will also have a `comment` subcapture group containing
     *   the content of the comment without the comment operator and without leading whitespace.
     *
     * - **indent**: The space and tab characters that occurs on the same line as a comment (or the
     *   first line of a comment block) before any character that is not a space or tab.
     * - **lead**: The characters following the indentation but before the comment operator.
     *
     * All types of comments:
     * - **line**: The next line following the comment, included so the comment can be paired with
     *   whatever it is describing. If the next line of text is a class definition, these subgroups
     *   are used:
     *   - **class**: The class name. This will always be present.
     *   - **super**: If the class has the `extends` keyword, this subgroup will contain the name of
     *     the superclass. If the next line of text is a class method, property, or function
     *     definition, these subgroups are used:
     *     - **name**: The name of the method, property, or function. This will always be present.
     *     - **static**: The `static` keyword, if present.
     *     - **func**: If it is a function definition, then this subgroup will contain the open
     *       parentheses. This is mostly to indicate whether its a function or property.
     *     - **prop**: If it is a property definition, then this subgroup will contain the first
     *       character following the property name.
     */
    RemoveStringsAndComments() {
        global SPP_REMOVE_CONTINUATION, SPP_REMOVE_LOOP, SPP_REMOVE_COMMENT_BLOCK, SPP_REMOVE_COMMENT_SINGLE
        eol := this.EndOfLine
        ; Remove consecutive quotes
        this.Content := RegExReplace(this.Content, SPP_QUOTE_CONSECUTIVE_DOUBLE, Chr(this.__ConsecutiveDoubleReplacement) Chr(this.__ConsecutiveDoubleReplacement), &DoubleCount)
        this.Content := RegExReplace(this.Content, SPP_QUOTE_CONSECUTIVE_SINGLE, Chr(this.__ConsecutiveSingleReplacement) Chr(this.__ConsecutiveSingleReplacement), &SingleCount)
        this.RemovedCollection.ConsecutiveDoubleQuotes := DoubleCount
        this.RemovedCollection.ConsecutiveSingleQuotes := SingleCount
        ; Remove continuation sections.
        _Process(&SPP_REMOVE_CONTINUATION)
        ; Remove comment blocks
        _Process(&SPP_REMOVE_COMMENT_BLOCK)
        ; Remove single line comments
        _Process(&SPP_REMOVE_COMMENT_SINGLE)
        ; Remove other quoted strings and comments
        _Process(&SPP_REMOVE_LOOP)

        return

        _Process(&Pattern) {
            Pos := 1
            nl := 1
            leLen := StrLen(this.EndOfLine)
            ActiveComment := ''
            ; This is the procedure flow for removing content and adding a value to a collection
            loop {
                if !RegExMatch(this.Content, 'JS)' Pattern, &Match, Pos) {
                    break
                }
                ; Get line count of the segment leading up to the match
                StrReplace(SubStr(this.Content, Pos, Match.Pos - Pos), eol, , , &linecount)
                ; Calculate line start
                LineStart := nl += linecount
                ; Calculate col start
                ColStart := Match.Pos['text'] - Match.Pos
                ; Get line count of the text that will be removed
                StrReplace(Match['text'], eol, , , &linecount)
                ; Calculate line end
                LineEnd := nl += linecount
                ; Calculate col end
                if LineEnd == LineStart {
                    ColEnd := ColStart + Match.Len['text']
                } else {
                    ColEnd := Match.Len['text'] - InStr(Match['text'], eol, , , -1)
                }
                ; Adjust pos
                Pos := Match.Pos['text'] + Match.Len['text']
                ; Get constructor. The `Mark` value is the symbol `SPC_<collection name>`.
                Constructor := this.CollectionList[%Match.Mark%].Constructor
                ; Call constructor. The constructor handles the rest.
                Constructor(LineStart, ColStart, LineEnd, ColEnd, Match.Pos['text'], Match.Len['text'], , Match, , , , true)
            }
        }
    }
    Process() {
        this.RemoveStringsAndComments()
        this.ParseClass()
        this.AssociateComments()
        this.Cleanup()
    }
    __Delete() {
        ObjPtrAddRef(this)
        if ScriptParser.Collection.Has(this.IdScriptParser) {
            ScriptParser.Collection.Delete(this.IdScriptParser)
        }
    }

    Encoding {
        Get => this.Options.Encoding
        Set => this.Options.Encoding := Value
    }
    NameCollection[IndexCollection] => this.CollectionList[IndexCollection].NameCollection
    Path {
        Get => this.Options.Path
        Set => this.Options.Path := Value
    }
    Text[PosStart := 1, Len?] => SubStr(this.Content, PosStart, Len ?? unset)
    TextFull[PosStart := 1, Len?] => this.GetTextFull(PosStart, Len ?? unset)

    class Options {
        static __New() {
            this.DeleteProp('__New')
            proto := this.Prototype
            proto.Content := ''
            proto.DeferProcess := false
            proto.Encoding := ''
            proto.EndOfLine := ''
            proto.Path := ''
        }

        __New(options?) {
            if IsSet(options) {
                for prop in ScriptParser.Options.Prototype.OwnProps() {
                    if HasProp(options, prop) {
                        this.%prop% := options.%prop%
                    }
                }
                if this.HasOwnProp('__Class') {
                    this.DeleteProp('__Class')
                }
            }
        }
    }
}
