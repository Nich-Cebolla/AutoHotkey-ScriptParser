
/**
 * @description - Constructs a new class based off an existing class and prototype.
 * @param {*} Prototype - The object to use as the new class's prototype.
 * @param {String} [Name] - The name of the new class. This gets assigned to `Prototype.__Class`.
 * @param {Function} [Constructor] - An optional constructor function that is assigned to
 * `NewClassObj.Prototype.__New`. When set, this function is called for each new instance. When
 * unset, the constructor function associated with `Prototype.__Class` is called.
 */
ScriptParser_ClassFactory(Prototype, Name?, Constructor?) {
    Cls := Class()
    Cls.Base := GetObjectFromString(Prototype.__Class)
    Cls.Prototype := Prototype
    if IsSet(Name) {
        Prototype.__Class := Name
    }
    if IsSet(Constructor) {
        Cls.Prototype.DefineProp('__New', { Call: Constructor })
    }
    return Cls

    GetObjectFromString(Path) {
        Split := StrSplit(Path, '.')
        if !IsSet(%Split[1]%)
            return
        OutObj := %Split[1]%
        i := 1
        while ++i <= Split.Length {
            if !OutObj.HasOwnProp(Split[i])
                return
            OutObj := OutObj.%Split[i]%
        }
        return OutObj
    }

}

ScriptParser_QuickSort(Arr, CompareFn := (a, b) => a - b, ArrSizeThreshold := 17, PivotCandidates := 7) {
    if Arr.Length <= ArrSizeThreshold {
        if Arr.Length == 1
            return Arr
        else if Arr.Length == 2 {
            if CompareFn(Arr[1], Arr[2]) > 0
                return [Arr[2], Arr[1]]
            return Arr
        }
        _InsertionSort(Arr, CompareFn)
        return Arr
    }
    if PivotCandidates > 1 && Arr.Length > PivotCandidates {
        Candidates := [], Candidates.Length := PivotCandidates
        Loop PivotCandidates
            Candidates[A_Index] := Random(1, Arr.Length)
        _SortPivotCandidates()
        pivot := Arr.RemoveAt(Candidates[Round(PivotCandidates / 2, 0)])
    } else
        pivot := Arr.Pop()
    Left := [], Right := [], Left.Capacity := Right.Capacity := Arr.Length
    for Item in Arr {
        if CompareFn(Item, pivot) < 0
            Left.Push(Item)
        else
            Right.Push(Item)
    }
    Left.Capacity := Left.Length, Right.Capacity := Right.Length
    Result := ScriptParser_QuickSort(Left, CompareFn, ArrSizeThreshold, PivotCandidates)
    Result.Push(Pivot, ScriptParser_QuickSort(Right, CompareFn, ArrSizeThreshold, PivotCandidates)*)
    return Result

    _InsertionSort(Arr, CompareFn) {
        i := 1
        loop Arr.Length - 1 {
            Current := Arr[++i]
            j := i - 1
            loop j {
                if CompareFn(Arr[j], Current) < 0
                    break
                Arr[j + 1] := Arr[j--]
            }
            Arr[j + 1] := Current
        }
    }
    _SortPivotCandidates() {
        i := 1
        loop Candidates.Length - 1 {
            Current := Candidates[++i]
            j := i - 1
            loop j {
                if CompareFn(Arr[j], Arr[Current]) < 0
                    break
                Candidates[j + 1] := Candidates[j--]
            }
            Candidates[j + 1] := Current
        }
    }
}
