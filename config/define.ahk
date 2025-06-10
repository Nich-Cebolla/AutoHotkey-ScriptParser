
/** @var - The replacement character used when substituting a string. */
SP_REPLACEMENT := Chr(0xFFFC) ; Replacement char

/** Patterns */

/** @var - Parses a replacement string into its parts. */
SPP_REPLACEMENT := SP_REPLACEMENT '(?<collection>\d+)' SP_REPLACEMENT '(?<index>\d+)'

SPR_QUOTE_CONSECUTIVEDOUBLE := Chr(0x2000) Chr(0x2000)
SPR_QUOTE_CONSECUTIVESINGLE := Chr(0x2001) Chr(0x2001)


/** @var - Parses code that assigns a value to a symbol. */
SPP_ASSIGN := (
    'im)'
    '^(?<indent>[ \t]*+)'
    '(?<text>'
        '(?:'
            '(?<keyword>static|global|local)'
            '\s++'
        ')?'
        '(?<name>[a-zA-Z0-9_]++)'
        '\s*+'
        '(?<assign>[:+\-*/.|&^><?]{1,2}=)'
        '\s*+'
        '(?<body>.+)'
    ')'
)

/** @var - Parses code that assigns a value to an object property within a class definition. */
SPP_ASSIGN_PROPERTY := (
    'im)'
    '^(<indent>[ \t]*+)'
    '(?<text>'
        '(?:'
            '(?<static>static)'
            '\s+'
        ')?'
        '(?<name>[a-zA-Z0-9_]++)'
        '\s*+'
        '(?<assign>:=)'
        '\s*+'
        '(?<body>.+)'
    ')'
)

/** @var - Parses code that is a class definition. */
SPP_CLASS := (
    'im)'
    '^(?<indent>[ \t]*)'
    '(?<text>'
        'class\s++'
        '(?<name>[a-zA-Z0-9_]++)'
        '(?:'
            '\s++extends\s++'
            '(?<super>[a-zA-Z0-9_.]++)'
        ')?'
        '\s*+'
        '(?<body>\{([^{}]++|(?&body))*\})'
    ')'
)

/** @var - This can be added to the beginning of any pattern to include it as a callable pattern
 * within the greater pattern. https://www.pcre.org/pcre.txt search for "Defining subpatterns
 * for use by reference only"
 */
SPP_DEFINE_QUOTE := (
    '(?(DEFINE)'
        '(?<quote>'
            '(?<!``)'
            '(?:````)*+'
            '([`"`'])'
            '(?<text>.*?)'
            '(?<!``)'
            '(?:````)*+'
            '\g{-2}'
        ')'
    ')'
)

/**
 * @var -
 * The `SPP_Class` pattern above essentially matches with the bracketed text following a class
 * definition statement. If the code within the brackets contains a quoted string that contains a
 * curly brace, the match may be disrupted.
 * Generally I recommend removing strings from the code prior to parsing; the cleaned code
 * can be saved to a separate file and reused to significantly improve load times, and so it
 * is a good way to handle this.
 *
 * In case removing the strings from the code isn't viable or ideal, `SPP_CLASS_INCLQUOTE`
 * addresses the aforementioned problem. It utilizes the subpattern `SPP_DEFINE_QUOTE`. The
 * modifications included in this pattern cause the PCRE engine to skip over any brackets contained
 * within quoted strings, so they don't disrupt the match. However, this does not handle continuation
 * sections as described here:
 * {@link https://www.autohotkey.com/docs/v2/Scripts.htm#continuation-section}.
 * These must still be removed or handled in some other way.
 * This also does not handle comments, which should be removed or handled in some other way.
 */
SPP_CLASS_INCLQUOTE := (
    'im)'
    SPP_DEFINE_QUOTE ; Include the definition
    '^(?<indent>[ \t]*)'
    '(?<text>'
        'class\s+'
        '(?<name>[a-zA-Z0-9_]+)'
        '(?:'
            '\s+extends\s+'
            '(?<super>[a-zA-Z0-9_.]+)'
        ')?'
        '\s*'
        '(?<body>\{((?&quote)|[^"`'{}]++|(?&body))*\})' ; Note the modifications to this line
    ')'
)

; SPP_COMMENT := '/\*(?<text>[\w\W]+?)\*/'

; SPP_COMMENTLINE := '\s;.*'

; SPP_CONTINUATIONSECTION := (
;     '(?(DEFINE)(?<singleline>\s*;.*))'
;     '(?(DEFINE)(?<multiline>\s*/\*[\w\W]*?\*/))'
;     '(?<=[\s=:,&(.[?]|^)(?<quote>[`'"])'
;     '(?<comment>'
;         '(?&singleline)'
;         '|'
;         '(?&multiline)'
;     ')*'
;     '\s*+\('
;     '(?<text>[\w\W]*?)'
;     '\R[ \t]*+\).*?\g{quote}(?<tail>.*)'
; )

; SPP_REMOVESTRINGS := (
;     'J)(?<Remove>'
;         '/\*[\w\W]+?\*/[ \t]*(?=\R|$)(*MARK:comment)'
;     '|'
;         '(?<=\s|^);.*(?=\R|$)(*MARK:comment)'
;     '|'
;         '(?<!``)(?:````)*+'
;         '([`"`'])'
;         '[\w\W]*?'
;         '(?<!``)(?:````)*+'
;         '\g{-1}(*MARK:string)'
;     '|'
;         '([`'"])'
;         '\s*+'
;         '(?:;.*\R|\s*+/\*[\w\W]*\*/[ \t]*+)*+'
;         '\s*+\('
;         '[\w\W]*?'
;         '\R[ \t]*+\).*?\g{-1}(*MARK:string)'
;     ')'
; )

SPP_FUNCTION := (
    'J)'
    '(?<=[\r\n]|^)[ \t]*?'
    '(?<text>'
        '(?<name>[a-zA-Z0-9_]+)'
        '(?<params>\((?<inner>([^()]++|(?&params))*)\))'
        '\s*'
        '(?:'
            '(?<body>\{([^\{\}]++|(?&body))*\})'
        '|'
            '(?<arrow>=>)'
            '(?<body>.+)'
        ')'
    ')'
)

SPP_PROPERTY := (
    'iJm)'
    '^(?<indent>[ \t]*)'
    '(?<text>'
        '(?<static>static\s+)?'
        '(?<name>[a-zA-Z0-9_]+)'
        '(?:'
            '(?<params>\((?<inner>([^()]++|(?&params))*)\))'
            '(*MARK:func)'
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
    ')'
)

; Property accessor
SPP_ACCESSOR_GET := (
    'iJm)'
    '^(?<indent>[ \t]*)'
    '(?<text>'
        'Get\s*'
        '(?:'
            '(?<body>\{([^}{]++|(?&body))*\})'
        '|'
            '(?<arrow>=>)'
            '(?<body>.+)'
        ')'
    ')'
)
SPP_ACCESSOR_SET := (
    'iJm)'
    '^(?<indent>[ \t]*)'
    '(?<text>'
        'Set\s*'
        '(?:'
            '(?<body>\{([^}{]++|(?&body))*\})'
        '|'
            '(?<arrow>=>)'
            '(?<body>.+)'
        ')'
    ')'
)

SPP_BRACKET_CURLY := '(\{(?:[^}{]++|(?-1))*\})'
SPP_BRACKET_CURLYC := '(\{(?COnOpen)(?:[^}{]++|(?-1))*\}(?COnClose))'
SPP_BRACKET_ROUND := '(\((?:[^)(]++|(?-1))*\))'
SPP_BRACKET_ROUNDC := '(\((?COnOpen)(?:[^)(]++|(?-1))*\)(?COnClose))'
SPP_BRACKET_SQUARE := '(\[(?:[^\][]++|(?-1))*\])'
SPP_BRACKET_SQUAREC := '(\[(?COnOpen)(?:[^\][]++|(?-1))*\](?COnClose))'

SPP_QUOTE := (
    's)'
    '(?<!``)'
    '(?:````)*+'
    '(?<quote>[`"`'])'
    '(?<text>.*?)'
    '(?<!``)'
    '(?:````)*+'
    '\g{quote}'
)

SPP_QUOTE_CONSECUTIVE_DOUBLE := '(?<=^|[\s=([!&%,*])""'
SPP_QUOTE_CONSECUTIVE_SINGLE := '(?<=^|[\s=([!&%,*])`'`''

SPP_REMOVE_CONTINUATION := (
    '(?(DEFINE)(?<singleline>\s*;.*))'
    '(?(DEFINE)(?<multiline>\s*/\*[\w\W]*?\*/))'
    '(?<=[\r\n]).*?'
    '(*MARK:SPC_STRING)'
    '(?<text>'
        '(?<=[\s=:,&(.[?]|^)'
        '(?<quote>[`'"])'
        '(?<comment>'
            '(?&singleline)'
        '|'
            '(?&multiline)'
        ')*'
        '\s*+\('
        '(?<body>[\w\W]*?)'
        '\R[ \t]*+\).*?\g{quote}'
    ')'
    '(?<tail>.*)'
)
; SPP_DEFINE_LINE := (
;     '(?(DEFINE)(?<line>'
;         '(?<indent>[ \t]*)'
;         '(?:'
;             'class[ \t]+'
;             '(?<class>[a-zA-Z0-9_]+)'
;             '(?:'
;                 '[ \t]*extends[ \t]+'
;                 '(?<super>[a-zA-Z0-9_.]+)'
;             ')?'
;             '\s*\{'
;         '|'
;             '(?<static>static[ \t]+)?'
;             '(?<name>[\w\d_]+)'
;             '(?:'
;                 '(?<func>\()'
;             '|'
;                 '(?<prop>[^(])'
;             ')'
;             '.*'
;         '|'
;             '.*'
;         ')'
;     '))'
; )
; SPP_INCLUDE_LINE := '[ \t]*\R(?&line)?'
SPP_NEXT_LINE := (
    '(?:[ \t]*\R'
    '(?<line>'
        '(?<indent>[ \t]*)'
        '(?:'
            'class[ \t]+'
            '(?<class>[a-zA-Z0-9_]+)'
            '(?:'
                '[ \t]*extends[ \t]+'
                '(?<super>[a-zA-Z0-9_.]+)'
            ')?'
            '\s*\{'
        '|'
            '(?<static>static[ \t]+)?'
            '(?<name>[\w\d_]+)'
            '(?:'
                '(?<func>\()'
            '|'
                '(?<prop>[^(])'
            ')'
            '.*'
        '|'
            '.*'
        ')'
    '))?'
)
SPP_REMOVE_COMMENT_MULTI := (
    '(?<indent>(?<=[\r\n]|^)[ \t]*)'
    '(*MARK:SPC_COMMENTMULTILINE)'
    '(?<text>'
        '/\*\s*'
        '(?<comment>[\w\W]+?)'
        '\R[ \t]*\*/'
    ')'
)
SPP_REMOVE_COMMENT_SINGLE := (
    '(?<indent>(?<=[\r\n]|^)[ \t]*)'
    '(?<lead>[^; \t].*)?'
    '(*MARK:SPC_COMMENTSINGLELINE)'
    '(?<text>'
        '(?<=\s|^)'
        ';[ \t]*'
        '(?<comment>.*)'
    ')'
    SPP_NEXT_LINE
)
SPP_REMOVE_COMMENT_BLOCK := (
    '(*MARK:SPC_COMMENTBLOCK)'
    '(?<=[\r\n]|^)'
    '(?<text>'
        '(?:'
            '(?<indent>[ \t]*)'
            ';.*\R\g{indent}'
        '){2,}'
    ')'
    SPP_NEXT_LINE
)
SPP_REMOVE_COMMENT_JSDOC := (
    '(?<indent>(?<=[\r\n]|^)[ \t]*)'
    '(*MARK:SPC_JSDOC)'
    '(?<text>'
        '/\*\*'
        '(?<comment>[\w\W]+?)'
        '\*/'
    ')'
)
SPP_REMOVE_STRING := (
    '(*MARK:SPC_STRING)'
    '(?<text>'
        '(?<=[\s=:,&(.[?]|^)'
        '([`"`'])'
        '(?<string>.*?)'
        '(?<!``)'
        '(?:````)*'
        '\g{-2}'
    ')'
)
SPP_REMOVE_LOOP := (
    '(?:'
        SPP_REMOVE_STRING
        '|' SPP_REMOVE_COMMENT_JSDOC
        '|' SPP_REMOVE_COMMENT_MULTI
    ')'
    SPP_NEXT_LINE
)

