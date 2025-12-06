
class ScriptParser_Collection {
    __New(ScriptParserObj) {
        this.IdScriptParser := ScriptParserObj.IdScriptParser
    }
    Class => this.Script.CollectionList[SPC_CLASS]
    CommentBlock => this.Script.CollectionList[SPC_CommentBlock]
    CommentMultiLine => this.Script.CollectionList[SPC_CommentMultiLine]
    CommentSingleLine => this.Script.CollectionList[SPC_CommentSingleLine]
    Function => this.Script.CollectionList[SPC_Function]
    Getter => this.Script.CollectionList[SPC_Getter]
    InstanceMethod => this.Script.CollectionList[SPC_InstanceMethod]
    InstanceProperty => this.Script.CollectionList[SPC_InstanceProperty]
    Jsdoc => this.Script.CollectionList[SPC_Jsdoc]
    RemovedCommentBlock => this.Script.RemovedCollection.Get('CommentBlock')
    RemovedCommentMultiLine => this.Script.RemovedCollection.Get('CommentMultiLine')
    RemovedCommentSingleLine => this.Script.RemovedCollection.Get('CommentSingleLine')
    RemovedJsdoc => this.Script.RemovedCollection.Get('Jsdoc')
    RemovedString => this.Script.RemovedCollection.Get('String')
    Script => ScriptParser.Collection.Get(this.IdScriptParser)
    Setter => this.Script.CollectionList[SPC_Setter]
    StaticMethod => this.Script.CollectionList[SPC_StaticMethod]
    StaticProperty => this.Script.CollectionList[SPC_StaticProperty]
    String => this.Script.CollectionList[SPC_String]
}
