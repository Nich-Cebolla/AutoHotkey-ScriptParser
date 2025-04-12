
#Include ..\lib\MapEx.ahk
#Include ..\lib\HandleContinuation.ahk
#Include ..\lib\FillStr.ahk
#Include ..\lib\QuickSort.ahk
#Include ..\lib\QuickFind.ahk
#Include ..\lib\ParseJson.ahk
#Include ..\lib\Object.Prototype.Stringify.ahk
#Include ..\lib\DecodeUnicodeEscapeSequence.ahk
#Include ..\lib\GetObjectFromString.ahk
#Include ..\lib\Get.ahk

; Source files
#Include ScriptAnalyzer.ahk


SA_Replacement := Chr(0xFFFC)           ; Object replacement char

SA_FillerNl := FillStr('`r`n')
SA_FillerS := FillStr('`s')

/** Patterns */

/** @var - Parses a replacement string into its parts. */
SA_Pattern_Replacement := SA_Replacement '-(?<collection>[\w_]+)-(?<index>\d+)-' SA_Replacement

/** @var - Parses code that assigns a value to a symbol. */
SA_Pattern_Assign := (
    'im)'
    '^(?<indent>[ \t]*+)'
    '(?:'
        '(?<keyword>static|global|local)'
        '\s++'
    ')?'
    '(?<name>[a-zA-Z0-9_]++)'
    '\s*+'
    '(?<assign>[:+\-*/.|&^><?]{1,2}=)'
    '\s*+'
    '(?<body>.+)'
)

/** @var - Parses code that assigns a value to an object property. */
SA_Pattern_AssignProperty := (
    'im)'
    '^(<indent>[ \t]*+)'
    '(?:'
        '(?<static>static)'
        '\s+'
    ')?'
    '(?<name>[a-zA-Z0-9_]++)'
    '\s*+'
    '(?<assign>:=)'
    '\s*+'
    '(?<body>.+)'
)

/** @var - Parses code that is a class definition. */
SA_Pattern_Class := (
    'im)'
    '^(?<indent>[ \t]*)'
    'class\s++'
    '(?<name>[a-zA-Z0-9_]++)'
    '(?:'
        '\s++extends\s++'
        '(?<super>[a-zA-Z0-9_.]++)'
    ')?'
    '\s*+'
    '(?<body>\{([^{}]++|(?&body))*\})'
)

/** @var - This can be added to the beginning of any pattern to include it as a callable pattern
 * within the greater pattern. https://www.pcre.org/pcre.txt search for "Defining subpatterns
 * for use by reference only"
 */
SA_Pattern_DefineQuote := (
    '(?(DEFINE)'
        '(?<quote>'
            '(?<!``)(?:````)*+'
            '([`"`'])'
            '(?<text>.*?)'
            '(?<!``)(?:````)*+'
            '\g{-2}'
        ')'
    ')'
)

/**
 * @var -
 * The `SA_Pattern_Class` pattern above essentially matches with the bracketed text following a class
 * definition statement. If the code within the brackets contains a quoted string that contains a
 * curly brace, the match may be disrupted.
 * Generally I recommend removing strings from the code prior to parsing; the cleaned code
 * can be saved to a separate file and reused to significantly improve load times, and so it
 * is a good way to handle this.
 * <br>
 * In case removing the strings from the code isn't viable or ideal, `SA_Pattern_Class_InclQuote`
 * addresses the aforementioned problem. It utilizes the subpattern `SA_Pattern_DefineQuote`. The
 * modifications included in this pattern cause the PCRE engine to skip over any brackets contained
 * within quoted strings, so they don't disrupt the match. However, this does not handle continuation
 * sections as described here:
 * {@link https://www.autohotkey.com/docs/v2/Scripts.htm#continuation-section}.
 * These must still be removed or handled in some other way.
 * This also does not handle comments, which should be removed or handled in some other way.
 */
SA_Pattern_Class_InclQuote := (
    'im)'
    SA_Pattern_DefineQuote ; Include the definition
    '^(?<indent>[ \t]*)'
    'class\s+'
    '(?<name>[a-zA-Z0-9_]+)'
    '(?:'
        '\s+extends\s+'
        '(?<super>[a-zA-Z0-9_.]+)'
    ')?'
    '\s*'
    '(?<body>\{((?&quote)|[^"`'{}]++|(?&body))*\})' ; Note the modifications to this line
)

SA_Pattern_Comment := '/\*(?<comment>[\w\W]+?)\*/'

SA_Pattern_CommentLine := '\s;.*'

SA_Pattern_ContinuationSection := (
    '(?(DEFINE)(?<singleline>\s*;.*))'
    '(?(DEFINE)(?<multiline>\s*/\*[\w\W]*?\*/))'
    '(?<=[\s=:,&(.[?])(?<quote>[`'"])'
    '(?<comment>'
        '(?&singleline)'
        '|'
        '(?&multiline)'
    ')*'
    '\s*+\('
    '(?<text>[\w\W]*?)'
    '\R[ \t]*+\).*?\g{quote}(?<tail>.*)'
)

SA_Pattern_RemoveStrings := (
    'J)(?<Remove>'
        '/\*[\w\W]+?\*/[ \t]*(?=\R|$)(*MARK:comment)'
    '|'
        '(?<=\s|^);.*(?=\R|$)(*MARK:comment)'
    '|'
        '(?<!``)(?:````)*+'
        '([`"`'])'
        '[\w\W]*?'
        '(?<!``)(?:````)*+'
        '\g{-1}(*MARK:string)'
    '|'
        '([`'"])'
        '\s*+'
        '(?:;.*\R|\s*+/\*[\w\W]*\*/[ \t]*+)*+'
        '\s*+\('
        '[\w\W]*?'
        '\R[ \t]*+\).*?\g{-1}(*MARK:string)'
    ')'
)

SA_Pattern_Function := (
    'iJm)'
    '^[ \t]*'
    '(?<static>static\s+)?'
    '(?<name>[a-zA-Z0-9_]+)'
    '(?<params>\(([^()]++|(?&params))*\))'
    '\s*'
    '(?:'
        '(*MARK:bracket)(?<body>\{([^\{\}]++|(?&body))*\})'
        '|'
        '(*MARK:arrow)(?<body>\s*=>.+)'
    ')'
)

Stage2 := (
    '(?<preceding>[^\r\n{}]+[^\s{}]\s*+)(\{(?:[^}{]++|(?-1))*\})'
)

Property := (
    'iJm)'
    '^(?<indent>[ \t]*)'
    '(?<static>static\s+)?'
    '(?<name>[a-zA-Z0-9_]+)'
    '(?:'
        '(?<params>\((?<inner>([^()]++|(?&params))*)\))(*MARK:func)'
        '|'
        '(?<params>\[(?<inner>(?:[^\][]++|(?&params))*)\])?'
    ')'
    '\s*'
    '(?:'
        '(?<body>\{([^{}]++|(?&body))*\})'
        '|'
        '(?:'
            '(?<assign>:=)'
            '|'
            '(?<arrow>=>)'
        ')'
        '(?<body>.+)'
    ')'
)

; Format the bracket with "get" or "set"
/** @example
 * Pattern := Format(Ahk.Pattern.Accessor, 'get')
 * @
 */
Accessor := (
    'iJm)'
    '^(?<indent>[ \t]*)'
    '{}\s++'
    '(?<name>[a-zA-Z0-9_]++)'
    '\s*'
    '(?:'
        '(?<bracket>\{([^}{]++|(?&bracket))*\})'
        '|'
        '(?<arrow>=>)'
        '(?<body>.+)'
    ')'
)

BracketCurly := '(\{(?:[^}{]++|(?-1))*\})'
BracketCurlyC := '(\{(?COnOpen)(?:[^}{]++|(?-1))*\}(?COnClose))'
BracketRound := '(\((?:[^)(]++|(?-1))*\))'
BracketRoundC := '(\((?COnOpen)(?:[^)(]++|(?-1))*\)(?COnClose))'
BracketSquare := '(\[(?:[^\][]++|(?-1))*\])'
BracketSquareC := '(\[(?COnOpen)(?:[^\][]++|(?-1))*\](?COnClose))'

Quote := (
    's)'
    '(?<!``)(?:````)*+'
    '(?<quote>[`"`'])'
    '(?<text>.*?)'
    '(?<!``)(?:````)*+'
    '\g{quote}'
)


class ScriptAnalyzer_InternalConfig {
    static Components := [ 'Class', 'Comment', 'String', 'StaticMethod', 'InstanceMethod'
    , 'StaticProperty', 'InstanceProperty', 'Function', 'Variable', 'Expression'
    , 'SubExpression', 'Operator']

    static ClassList := [ ]

    , ScriptAnalyzerCollectionCaseSense := false
}
