
#include ..\src\VENV.ahk

test_included_files()

class test_included_files {
    static Call() {
        path := 'test-content\included-1.ahk'
        options := {
            Path: path
          , Included: ScriptParser_GetIncluded(path)
        }
        sp := ScriptParser(options)
        if sp.IncludedCollection.Count != 3 {
            throw Error('Invalid count.')
        }
        for path, _sp in sp.IncludedCollection {
            collection := _sp.Collection
            _class := collection.Class
            cls := _class.Get('MyClass' A_Index)
            if cls.Children.Count != 4 {
                throw Error('Invalid count.')
            }
            for name, _collection in cls.Children {
                if _collection.Count != 1 {
                    throw Error('Invalid count.')
                }
            }
        }
    }
}
