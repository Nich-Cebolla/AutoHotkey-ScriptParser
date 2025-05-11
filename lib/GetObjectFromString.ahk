
/**
 * @description - Converts a string path to an object reference. The object at the input path must
 * exist in the current scope of the function call.
 * @param {String} Str - The object path.
 * @param {Object} [InitialObj] - If set, the object path will be parsed as a property / item of
 * this object.
 * @returns {Object} - The object reference.
 * @example
 *
 *  Obj := {
 *      Prop1: [1, 2, Map(
 *              'key1', 'value1',
 *              'key2', {prop2: 2, prop3: [3, 4]}
 *          )
 *      ]
 *  }
 *  Path := 'obj.prop1[3]["key2"].prop3'
 *  ObjReference := GetObjectFromString(Path)
 *  OutputDebug(ObjReference[2]) ; 4
 * @
 * This is compatible with class references.
 * @example
 *
 *  class Test {
 *      class NestedClass {
 *          InstanceProp {
 *              Get{
 *                  return ['Val1', { Prop: 'Hello, world!' }]
 *              }
 *          }
 *      }
 *  }
 *  Path := 'Test.NestedClass.Prototype.InstanceProp[2]'
 *  Obj := GetObjectFromString(Path)
 *  OutputDebug(Obj.Prop) ; Hello, world!
 * @
 * Using an initial object.
 * @example
 *  Obj := {
 *      Prop1: [1, 2, Map(
 *              'key1', 'value1',
 *              'key2', {prop2: 2, prop3: [3, 4]}
 *          )
 *      ]
 *  }
 *  Path := '[3]["key2"].prop3'
 *  Arr := Obj.Prop1
 *  InnerArr := GetObjectFromString(Path, Arr)
 *  OutputDebug(InnerArr[2]) ; 4
 * @
 *
 */
GetObjectFromString(Str, InitialObj?) {
    static Pattern := '(?<=\.)[\w_\d]+(?COnProp)|\[\s*\K-?\d+(?COnIndex)|\[\s*(?<quote>[`'"])(?<key>.*?)(?<!``)(?:````)*\g{quote}(?COnKey)'
    if IsSet(InitialObj) {
        NewObj := InitialObj
        Pos := 1
    } else {
        RegExMatch(Str, '^[\w\d_]+', &InitialSegment)
        Pos := InitialSegment.Pos + InitialSegment.Len
        NewObj := %InitialSegment[0]%
    }
    while RegExMatch(Str, Pattern, &Match, Pos)
        Pos := Match.Pos + Match.Len

    return NewObj

    OnProp(Match, *) {
        NewObj := NewObj.%Match[0]%
    }
    OnIndex(Match, *) {
        NewObj := NewObj[Number(Match[0])]
    }
    OnKey(Match, *) {
        NewObj := NewObj[Match['key']]
    }
}
