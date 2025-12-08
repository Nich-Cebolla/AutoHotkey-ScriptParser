
class ScriptParser_Collection {
    __New(ScriptParserObj) {
        this.IdScriptParser := ScriptParserObj.IdScriptParser
    }
    Class => this.Script.__CollectionList[SPC_CLASS]
    CommentBlock => this.Script.__CollectionList[SPC_CommentBlock]
    CommentMultiLine => this.Script.__CollectionList[SPC_CommentMultiLine]
    CommentSingleLine => this.Script.__CollectionList[SPC_CommentSingleLine]
    Function => this.Script.__CollectionList[SPC_Function]
    Getter => this.Script.__CollectionList[SPC_Getter]
    Included => this.Script.IncludedCollection
    InstanceMethod => this.Script.__CollectionList[SPC_InstanceMethod]
    InstanceProperty => this.Script.__CollectionList[SPC_InstanceProperty]
    Jsdoc => this.Script.__CollectionList[SPC_Jsdoc]
    Script => ScriptParser.Collection.Get(this.IdScriptParser)
    Setter => this.Script.__CollectionList[SPC_Setter]
    StaticMethod => this.Script.__CollectionList[SPC_StaticMethod]
    StaticProperty => this.Script.__CollectionList[SPC_StaticProperty]
    String => this.Script.__CollectionList[SPC_String]
}
