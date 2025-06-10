
; Make a copy of this document and place it in your project directory

; Use the config object to define your options. `ScriptParser` will pick up on `ScriptParserConfig`
; automatically; you don't need to pass it as a parameter.

; If you intend to parse multiple scripts at the same time, you can define the options in two ways:
; - Don't use a class object, and just pass individual objects with the options for each script
; to the only parameter.
; or
; - Use `ScriptParserConfig` to define the options that will be shared by each instance, and pass
; the options that will be unique to each as individual objects to the parameter.

; Adjust the #include statement to point to the `VENV.ahk` file.
#include VENV.ahk


class ScriptParserConfig {

    ; Primary configuration options ================================================================
    static Name := 'Dev'
    static PathIn := '..\..\AutoHotkey-LibV2\inheritance\GetPropsInfo.ahk'
    ; , PathIn := '..\..\UIA_Viewer\UIA.ahk'
    static Capacity := unset
    ; , StandardizeLineEnding := '`n'


    ; Minor configuration options ==================================================================

    ; Sets the capacity for the "Removed" collection
    static Capacity_Removed := unset
    ; `Ahk` is the only supported language at the moment.
    static Language := unset

    ; Replacement characters -----------------------------------------------------------------------

    ; The following options define various replacement characters that `ScriptParser` uses to
    ; remove strings and comments from the text. They can be any character that has no significance
    ; in AHK's syntax nor in your code. For example, "@" has no meaning in AHK syntax and so would
    ; be an appropriate replacement character if you never use Jsdoc-style comments (which use "@").
    ; I chose the numbers below because they represent non-language characters and so are unlikely
    ; to be used in a code file. If the script you are parsing contains any of these characters,
    ; there's no harm in changing these characters. These options must be the unicode code point for
    ; the character. Use the `Ord` function if you have trouble finding a character code. E.g.
    ; `MsgBox(Ord(char))`. These options cannot be changed by passing an object to `ScriptParser` for
    ; now. Changing these options will change the value of some global variables that `ScriptParser`
    ; uses, meaning any subsequently parsed scripts will also be parsed using the updated values. I
    ; haven't written a way to easily change the values back yet.

    /** @todo - Address the global variable limitation */

    /**
     * @property ScriptParserConfig.ReplacementChar -
     * Defines the character which is used as the "replacement character", a general indicator that
     * a block of text has been replaced with replacement text.
     */
    static ReplacementChar := unset

    /**
     * @property ScriptParserConfig.Quote_ConsecutiveDouble -
     * Defines the character which is used to replace consecutive double quotes
     */
    static Quote_ConsecutiveDouble := unset

    /**
     * @property ScriptParserConfig.Quote_ConsecutiveSingle -
     * Defines the character which is used to replace consecutive single quotes
     */
    static Quote_ConsecutiveSingle := unset

    /**
     * @property ScriptParserConfig.ShortCollection_StartCode -
     * Defines the first character which is used to replace short strings.
     * - Up to 99 strings can be replaced for any single "ShortCollection" character, so `ScriptParser`
     * uses a range of characters.
     * - As `ScriptParser` works its way through the range, it will always check the script
     * if it contains a character. If it does, it will skip that character.
     * - A string is a "short string" if `StrLen(Component.IndexCollection rc.IndexRemoved) + 2 <= Match.Len['text']`
     * returns 1. This expression is used in the function `GetRemovedComponents` which is located
     * in "ComponentBase.ahk".
     * - It is okay if this range overlaps with `ScriptParseConfig.Quote_ConsecutiveDouble` and
     * `ScriptParserConfig.Quote_ConsecutiveSingle`, but not with `ScriptParserConfig.ReplacementChar`.
     */
    static ShortCollection_StartCode := unset

    /**
     * @property ScriptParserConfig.ShortCollection_EndCode -
     * Defines the last character `ScriptParser` will use to replace short strings. If the number
     * of short strings in a script exceeds
     * 99 * (ScriptParserConfig.R_ShortCollection_EndCode - ScriptParserConfig.R_ShortCollection_StartCode)
     * `ScriptParser` will throw an error.
     */
    static ShortCollection_EndCode := unset

    static __New() {
        if this.Prototype.__Class == 'ScriptParserConfig' {
            ObjSetBase(this, SP_Config.Default)
        }
    }
}
