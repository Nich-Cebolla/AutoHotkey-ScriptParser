
    /**
     * @class
     * @description - Handles the input config.
     */
class SP_Config {
    static Default := {
        Name: ''
      , PathIn: ''
      , Encoding: ''
      , Capacity: 1000
      , StandardizeLineEnding: false

        ; Minor configuration options
      , Config_Removed: 1000
      , ReplacementChar: Chr(0xFFFD)
    }

    /**
     * @description - Sets the base object such that the values are used in this priority order:
     * - 1: The input object.
     * - 2: The configuration object (if present).
     * - 3: The default object.
     * @param {Object} Config - The input object.
     * @return {Object} - The same input object.
     */
    static Call(Config) {
        if IsSet(ScriptParserConfig) {
            ObjSetBase(Config, ScriptParserConfig)
        } else {
            ObjSetBase(Config, SP_Config.Default)
        }
        return Config
    }
}
