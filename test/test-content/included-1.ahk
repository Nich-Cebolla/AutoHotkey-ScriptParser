
#include included-2.ahk
#include included-3.ahk

class MyClass1 {
    /**
     * @param {Type} param1 - info
     * @param {Type} [param2] - info
     * @returns {Type}
     */
    static Method(param1, param2 := "value") {

    }
    static Property {
        Get {
        }
        Set {
        }
    }
    /**
     * @classdesc - MyClass info...
     * @param {Type} [params] - info
     */
    __New(params*) {

    }
    ; details about Property
    Property := "Value"
}
