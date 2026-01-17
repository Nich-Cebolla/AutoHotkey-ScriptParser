
ScriptParser_SetConstants(force := false) {
    global
    if IsSet(ScriptParser_constants_set) && !force {
        return
    }

    local recursive_curly := '(?<body>\{([^{}]++|(?&body))*\})'
    , params_round := '(?<params>\((?<inner>(?:[^()]++|(?&params))*)\))'
    , params_square := '(?<params>\[(?<inner>(?:[^\][]++|(?&params))*)\])?'
    , ahk_valid_chars := '(?:[\p{L}_0-9]|[^\x00-\x7F\x80-\x9F])'
    , ahk_valid_chars_no_digits := '(?:[\p{L}_]|[^\x00-\x7F\x80-\x9F])'
    , arrow := '(?<arrow>=>)'
    , body := '(?<body>.+)'
    , indent := '(?<=[\r\n]|^)(?<indent>[ \t]*)'

    /**
     * @var - This can be added to the beginning of any pattern to include it as a callable subpattern.
     * For more information, open {@link https://www.pcre.org/pcre.txt} then ctrl+f search for
     * "Defining subpatterns for use by reference only".
     */
    , quote := (
        '(?(DEFINE)'
            '(?<quote>'
                '(?<!``)'
                '(?:````)*+'
                '(?<skip>["`'])'
                '(?<text>.*?)'
                '(?<!``)'
                '(?:````)*+'
                '\g{skip}'
            ')'
        ')'
    )
    , accessor := (
        'iJ)'
        indent
        '(?<text>'
            '{1}et\s*'
            '(?:'
                recursive_curly
            '|'
                arrow
                body
            ')'
        ')'
    )
    , name := '(?<name>' ahk_valid_chars_no_digits ahk_valid_chars '*+)'
    , recursive_curly_quote := quote '(?<body>\{((?&quote)|[^{}"`']++|(?&body))*\})'
    , next_line := (
        '(?:[ \t]*\R'
        '(?<line>'
            indent
            '(?:'
                'class[ \t]+'
                '(?<class>' ahk_valid_chars_no_digits ahk_valid_chars '*+)'
                '(?:'
                    '[ \t]*extends[ \t]+'
                    '(?<super>' ahk_valid_chars_no_digits ahk_valid_chars '*+(?:\.' ahk_valid_chars_no_digits ahk_valid_chars '*+)*+)'
                ')?'
                '\s*\{'
            '|'
                '(?<static>static[ \t]+)?'
                name
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

    ; Property accessor
    SPP_ACCESSOR_GET := Format(accessor, 'G')
    SPP_ACCESSOR_SET := Format(accessor, 'S')

    ; Recursive pattern that matches with a bracket pair with any number of nested bracket pairs,
    ; skipping quoted strings so the string content does not disrupt the match.
    SPP_BRACKET_ROUND := quote '(?<body>\(((?&quote)|[^()"`']++|(?&body))*\))'
    SPP_BRACKET_SQUARE := quote '(?<body>\[((?&quote)|[^[\]"`']++|(?&body))*\])'

    /**
     * @var - Parses code that is a class definition.
     */
    SPP_CLASS := (
        'i)'
        indent
        '(?<text>'
            'class\s++'
            name
            '(?:'
                '\s++extends\s++'
                '(?<super>' ahk_valid_chars_no_digits ahk_valid_chars '*+(?:\.' ahk_valid_chars_no_digits ahk_valid_chars '*+)*+)'
            ')?'
            '\s*+'
            recursive_curly
        ')'
    )
    SPP_FUNCTION := (
        'iJ)'
        quote
        indent
        '(?<text>'
            name
            '(?:'
                params_round
                '(*MARK:func)'
            '|'
                params_square
            ')'
            '\s*'
            '(?:'
                recursive_curly
            '|'
                arrow
                body
            ')'
        ')'
    )

; Not in use yet
/*
    SPP_GLOBAL := (
        'iJ)'
        quote
        indent
        '(?:'
            '(?<text>'
                name
                '(?:'
                    params_round
                    '(*MARK:func)'
                '|'
                    params_square
                ')'
                '\s*'
                '(?:'
                    recursive_curly
                '|'
                    arrow
                    body
                ')'
            ')'
        '|'
            ; hotkeys
            '(?<key>[^\r\n:]+)'
            '`::'
            '(?:'
                '\s*(?<hkbody>\{([^{}]++|(?&hkbody))*\})'
            '|'
                '.+'
                '(*MARK:call)'
            ')'
        ')'
    )

    SPP_HOTKEY_KEYS := '[<>]?[!^#+](*MARK:mod)|\w+'
    SPP_HOTKEY_OPTION := '[*~$]'
    SPP_HOTKEY_ALT_TAB := '(?:Shift)?AltTab(?:(?:And)?Menu(?:Dismiss)?)?'
    ; other keys - &
    SPP_HOTKEY := (
        indent
    )

*/

    SPP_PROPERTY := (
        'iJ)'
        indent
        '(?<text>'
            '(?<static>static\s+)?'
            name
            '(?:'
                params_round
                '(*MARK:func)'
            '|'
                params_square
            ')'
            '\s*'
            '(?:'
                recursive_curly
            '|'
                '(?:'
                    '(?<assign>:=)'
                '|'
                    arrow
                ')'
                body
            ')'
        ')'
    )

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

    SPP_QUOTE_CONSECUTIVE_DOUBLE := '(?<=^|[\s=(:[!&%,*])""'
    SPP_QUOTE_CONSECUTIVE_SINGLE := '(?<=^|[\s=(:[!&%,*])`'`''

    SPP_REMOVE_COMMENT_BLOCK := (
        '(*MARK:SPC_COMMENTBLOCK)'
        '(?<=[\r\n]|^)'
        '(?<text>'
            '(?<indent>[ \t]*);.*'
            '(?:\R\g{indent};.*)+'
        ')'
        next_line
    )

    SPP_REMOVE_COMMENT_JSDOC := (
        indent
        '(*MARK:SPC_JSDOC)'
        '(?<text>'
            '/\*\*'
            '(?<comment>[\w\W]+?)'
            '\*/'
        ')'
        next_line
    )

    SPP_REMOVE_COMMENT_MULTI := (
        indent
        '(*MARK:SPC_COMMENTMULTILINE)'
        '(?<text>'
            '/\*\s*'
            '(?<comment>[\w\W]+?)'
            '\R[ \t]*\*/'
        ')'
        next_line
    )

    SPP_REMOVE_COMMENT_SINGLE := (
        indent
        '(?:(?<lead>.+?)[ \t]+)?'
        '(*MARK:SPC_COMMENTSINGLELINE)'
        '(?<text>'
            ';[ \t]*'
            '(?<comment>.*)'
        ')'
        next_line
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
        next_line
    )

    /**
     * @var - Parses a replacement string into its parts.
     */
    SPP_REPLACEMENT := '{1}(?<collection>\d+){1}(?<index>\d+)'

    local i := 0

    SPC_CLASS := ++i
    SPC_COMMENTBLOCK := ++i
    SPC_COMMENTMULTILINE := ++i
    SPC_COMMENTSINGLELINE := ++i
    SPC_FUNCTION := ++i
    SPC_GETTER := ++i
    SPC_INSTANCEMETHOD := ++i
    SPC_INSTANCEPROPERTY := ++i
    SPC_JSDOC := ++i
    SPC_SETTER := ++i
    SPC_STATICMETHOD := ++i
    SPC_STATICPROPERTY := ++i
    SPC_STRING := ++i
    SPC_COMMENT := ++i
    SPC_METHOD := ++i
    SPC_PROPERTY := ++i
    SPC_VARIABLE := ++i
    SPC_END := i

    ScriptParser_constants_set := true
}
