
ScriptParser_SetConstants(force := false) {
    global
    if IsSet(ScriptParser_constants_set) && !force {
        return
    }

    /** @var - Parses a replacement string into its parts. */
    SPP_REPLACEMENT := '{1}(?<collection>\d+){1}(?<index>\d+)'

    SPP_QUOTE_CONSECUTIVE_DOUBLE := '(?<=^|[\s=(:[!&%,*])""'
    SPP_QUOTE_CONSECUTIVE_SINGLE := '(?<=^|[\s=(:[!&%,*])`'`''

    SPP_AHK_VALID_CHARS := '(?:[\p{L}_0-9]|[^\x00-\x7F\x80-\x9F])'
    SPP_AHK_VALID_CHARS_NODIGITS := '(?:[\p{L}_]|[^\x00-\x7F\x80-\x9F])'

    /** @var - Parses code that is a class definition. */
    SPP_CLASS := (
        'im)'
        '^(?<indent>[ \t]*)'
        '(?<text>'
            'class\s++'
            '(?<name>' SPP_AHK_VALID_CHARS_NODIGITS SPP_AHK_VALID_CHARS '*+)'
            '(?:'
                '\s++extends\s++'
                '(?<super>' SPP_AHK_VALID_CHARS_NODIGITS SPP_AHK_VALID_CHARS '*+(?:\.' SPP_AHK_VALID_CHARS_NODIGITS SPP_AHK_VALID_CHARS '*+)*+)'
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

    SPP_PARAMS := (
        'im)'
        SPP_DEFINE_QUOTE ; Include the definition
        '(?<body>\(((?&quote)|[^"`')(]++|(?&body))*\))'
    )

    SPP_PROPERTY := (
        'iJm)'
        '^(?<indent>[ \t]*)'
        '(?<text>'
            '(?<static>static\s+)?'
            '(?<name>' SPP_AHK_VALID_CHARS_NODIGITS SPP_AHK_VALID_CHARS '*+)'
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
                '(?<body>.*)'
            ')'
        ')'
    )

    SPP_FUNCTION := (
        'iJm)'
        '^(?<indent>[ \t]*)'
        '(?<text>'
            '(?<static>static\s+)?'
            '(?<name>' SPP_AHK_VALID_CHARS_NODIGITS SPP_AHK_VALID_CHARS '*+)'
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
                '(?<arrow>=>)'
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

    SPP_BRACKET_SQUARE := '(?(DEFINE)(?<quote>(?<!``)(?:````)*+(?<skip>["`']).*?(?<!``)(?:````)*+\g{skip}))(?<body>\[((?&quote)|[^[\]"`']++|(?&body))*\])'
    SPP_BRACKET_ROUND := '(?(DEFINE)(?<quote>(?<!``)(?:````)*+(?<skip>["`']).*?(?<!``)(?:````)*+\g{skip}))(?<body>\(((?&quote)|[^()"`']++|(?&body))*\))'

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
            '\s*\('
            '(?<body>[\w\W]*?)'
            '\R[ \t]*\).*?\g{quote}'
        ')'
        '(?<tail>.*)'
    )

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
        SPP_NEXT_LINE
    )

    SPP_REMOVE_COMMENT_SINGLE := (
        '(?<=[\r\n]|^)'
        '(?<indent>[ \t]*)'
        '(?:(?<lead>.+?)[ \t]+)?'
        '(*MARK:SPC_COMMENTSINGLELINE)'
        '(?<text>'
            ';[ \t]*'
            '(?<comment>.*)'
        ')'
        SPP_NEXT_LINE
    )

    SPP_REMOVE_COMMENT_BLOCK := (
        '(*MARK:SPC_COMMENTBLOCK)'
        '(?<=[\r\n]|^)'
        '(?<text>'
            '(?<indent>[ \t]*);.*'
            '(?:\R\g{indent};.*){1,}'
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
        SPP_NEXT_LINE
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
        SPP_NEXT_LINE
    )
    local auto := ScriptParser_Auto()

    SPC_CLASS := auto()
    SPC_COMMENTBLOCK := auto()
    SPC_COMMENTMULTILINE := auto()
    SPC_COMMENTSINGLELINE := auto()
    SPC_FUNCTION := auto()
    SPC_GETTER := auto()
    SPC_INSTANCEMETHOD := auto()
    SPC_INSTANCEPROPERTY := auto()
    SPC_JSDOC := auto()
    SPC_SETTER := auto()
    SPC_STATICMETHOD := auto()
    SPC_STATICPROPERTY := auto()
    SPC_STRING := auto()
    SPC_COMMENT := auto()
    SPC_METHOD := auto()
    SPC_PROPERTY := auto()
    SPC_VARIABLE := auto()

    ScriptParser_constants_set := true
}
