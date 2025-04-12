/*
    Github: https://github.com/Nich-Cebolla/AutoHotkey-QuickFind
    Author: Nich-Cebolla
    Version: 1.2.0
    License: MIT
*/

class QuickFind {
    static __New() {
        if this.Prototype.__Class == 'QuickFind' {
            this.WordValueCache := Map()
            this.WordValueCache.CaseSense := false
        }
    }

    ;@region Call
    /**
     * @description - Searches an array for the index which contains the first value that satisfies
     * the condition relative to the input value. This function has these characteristics:
     * - The array is assumed to be in order of value.
     * - The array may have unset indices as long as every set index is in order.
     * - Items may be objects - set `ValueCallback` to return the item value.
     * @example
        MyArr := [ { prop: 1 }, { prop: 22 }, { prop: 1776 } ]
        AccessorFunc(Item, *) {
            return Item.prop
        }
        MsgBox(QuickFind(MyArr, 22, , , , , AccessorFunc)) ; 2
     * @
     * - `QuickFind` determines the search direction internally to allow you to make a decision based
     * on whether you want to find the next greatest or next lowest value. If search direction is
     * relevant to your script or function, the direction is defined as:
     *   - When `Condition` is ">" or ">=", the search direction is the the same as the direction of ascent
     * (the search direction is the same as the direction values increase).
     *   - When `Condition` is "<" or "<=", the search direction is the inverse of the direction of ascent
     * (the search direction is the same as the direction values decrease).
     *   - If every set index within the array contains the same value, and that value
     * satisfies the condition, and at least one set index falls between `IndexStart` and `IndexEnd`,
     * then the function defaults to returning the first set index between `IndexStart` and `IndexEnd`
     * from left-to-right.
     * @param {Array} Arr - The array to search.
     * @param {Number|Object} Value - The value to search for. This value may be an object as long
     * as its numerical value can be returned by the `ValueCallback` function. This is not required
     * to be an object when the items in the array are objects; it can be either an object or number.
     * If `ValueCallback` accepts more than just the object as a parameter
     * ({@link QuickFind.Call~ValueCallback}) then it is recommended to pass `Value` as a number, or
     * make the second and third parameters of the callback optional.
     * @param {VarRef} [OutValue] - A variable that will receive the value at the found index.
     * @param {String} [Condition='>='] - The inequality symbol indicating what condition satisfies
     * the search. Valid values are:
     * - ">": `QuickFind` returns the index of the first value greater than the input value.
     * - ">=": `QuickFind` returns the index of the first value greater than or equal to the input value.
     * - "<": `QuickFind` returns the index of the first value less than the input value.
     * - "<=": `QuickFind` returns the index of the first value less than or equal to the input value.
     * @param {Number} [IndexStart=1] - The index to start the search at.
     * @param {Number} [IndexEnd] - The index to end the search at. If not provided, the length of the
     * array is used.
     * @param {Func} [ValueCallback] - A function that returns the item's numeric value.
     * The function can accept up to three parameters, in this order. If not using one of the
     * parameters, be sure to include the necessary `*` symbol to avoid a runtime error.
     * - The current item being evaluated.
     * - The item's index.
     * - The input array.
     * @example
       ; Assume for some reason I have an array that, on the odd indices contains an item with a
       ; property `Prop`, and on the even indices contains an item with a key `key`.
       MyArr := [ { Prop: 1 }, Map('key', 22), { Prop: 55 }, Map('key', 55), { Prop: 1776 } ]
       ; I don't need the array object for my function to accomplish it's task, so I put `*` to
       ; ignore that parameter.
        AccessorFunc(Item, Index, *) {
            if Mod(Index, 2) {
                return Item.Prop
            } else {
                return Item['key']
            }
        }
        ; I could also accomplish the same thing like this
        AccessorFuncBetter(Item, *) {
            if Type(Item) == 'Map' {
                return Item['key']
            } else {
                return Item.Prop
            }
        }
     * @
     * @returns {Integer} - The index of the first value that satisfies the condition.
     */
    static Call(Arr, Value, &OutValue?, Condition := '>=', IndexStart := 1, IndexEnd?, ValueCallback?) {
        if !Arr.Length {
            throw Error('The array is empty.', -1)
        }
        if !IsSet(IndexEnd) {
            IndexEnd := Arr.Length
        }
        if IndexEnd <= IndexStart {
            throw Error('The end index is less than or equal to the start index.'
            , -1, 'IndexEnd: ' IndexEnd '`tIndexStart: ' IndexStart)
        }

        ;@region Compare fn
        if IsSet(ValueCallback) {
            Compare_GT := _Compare_GT_2
            Compare_GTE := _Compare_GTE_2
            Compare_LT := _Compare_LT_2
            Compare_LTE := _Compare_LTE_2
            Compare_EQ := _Compare_EQ_2
            if IsObject(Value) {
                Value := ValueCallback(Value)
            }
            GetValue := () => ValueCallback(Arr[i], i, Arr)
        } else {
            Compare_GT := _Compare_GT_1
            Compare_GTE := _Compare_GTE_1
            Compare_LT := _Compare_LT_1
            Compare_LTE := _Compare_LTE_1
            Compare_EQ := _Compare_EQ_1
            GetValue := () => Arr[i]
        }
        ;@endregion

        ;@region Get Left-Right
        ; This block starts to identify the sort direction, and also sets `Left` and `Right` in the
        ; process.
        i := IndexStart
        ; No return value indicates the array had no set indices between IndexStart and IndexEnd.
        if !_GetNearest_L2R() {
            throw Error('The indices within the input range are all unset.', -1)
        }
        LeftV := GetValue()
        Left := i
        i := IndexEnd
        ; This will always return 1 because we know that there is at least one value in the input range.
        _GetNearest_R2L()
        RightV := GetValue()
        Right := i
        ;@endregion

        ;@region 1 Unique val
        ; This block handles conditions where there is only one unique value between `IndexStart`
        ; and `IndexEnd`.
        if RightV == LeftV {
            ; First, we validate `Value`. We might be able to skip the whole process if `Value` is
            ; out of range. We can also prepare the return value so we don't need to re-check
            ; `Condition`. The return value will be a function of the sort direction.
            switch Condition {
                case '>':
                    if LeftV <= Value {
                        return
                    }
                    Result := (BaseDirection) => BaseDirection == 1 ? Right : Left
                case '>=':
                    if LeftV < Value {
                        return
                    }
                    Result := (BaseDirection) => BaseDirection == 1 ? Right : Left
                case '<':
                    if LeftV >= Value {
                        return
                    }
                    Result := (BaseDirection) => BaseDirection == 1 ? Left : Right
                case '<=':
                    if LeftV > Value {
                        return
                    }
                    Result := (BaseDirection) => BaseDirection == 1 ? Left : Right
            }
            ; `Value` satisfies the condition at this point. If `Right == Left`, then there is only
            ; one set index and we can return that.
            if Right == Left {
                OutValue := Arr[Right]
                return Right
            }
            ; At this point, we know `Value` is valid and there are multiple indices with `Value`.
            ; Therefore, we must know the sort direction so we know whether to return `Left` or
            ; `Right`.
            i := 0
            while !Arr.Has(++i) {
                continue
            }
            LeftV := GetValue()
            i := Arr.Length + 1
            while !Arr.Has(--i) {
                continue
            }
            RightV := GetValue()
            if LeftV == RightV {
                ; Default to `Left` because there is no sort direction.
                OutValue := Arr[Left]
                return Left
            } else if RightV > LeftV {
                OutValue := Arr[Result(-1)]
                return Result(-1)
            } else {
                OutValue := Arr[Result(1)]
                return Result(1)
            }
        }
        ;@endregion

        ;@region Condition
        switch Condition {

            ;@region case >=
            case '>=':
                Condition := Compare_GTE
                AltCondition := Compare_LT
                HandleEqualValues := _HandleEqualValues_EQ
                EQ := true
                if RightV > LeftV {
                    if Value > RightV {
                        ; `Value` is out of range.
                        return
                    }
                    HEV_Direction := -1
                    Sequence_GT := _Sequence_GT_A_2
                    Sequence_LT := _Sequence_GT_A_1
                    Compare_Loop := Compare_LT
                } else {
                    if Value > LeftV {
                        ; `Value` is out of range.
                        return
                    }
                    HEV_Direction := 1
                    Sequence_GT := _Sequence_GT_D_2
                    Sequence_LT := _Sequence_GT_D_1
                    Compare_Loop := Compare_GT
                }
            ;@endregion

            ;@region case >
            case '>':
                Condition := Compare_GT
                AltCondition := Compare_LTE
                HandleEqualValues := _HandleEqualValues_NEQ
                EQ := false
                if RightV > LeftV {
                    if Value >= RightV {
                        ; `Value` is out of range.
                        return
                    }
                    HEV_Direction := 1
                    Sequence_GT := _Sequence_GT_A_2
                    Sequence_LT := _Sequence_GT_A_1
                    Compare_Loop := Compare_LT
                } else {
                    if Value >= LeftV {
                        ; `Value` is out of range.
                        return
                    }
                    HEV_Direction := -1
                    Sequence_GT := _Sequence_GT_D_2
                    Sequence_LT := _Sequence_GT_D_1
                    Compare_Loop := Compare_GT
                }
            ;@endregion

            ;@region case <=
            case '<=':
                Condition := Compare_LTE
                AltCondition := Compare_GT
                HandleEqualValues := _HandleEqualValues_EQ
                EQ := true
                if RightV > LeftV {
                    if Value < LeftV {
                        ; `Value` is out of range.
                        return
                    }
                    HEV_Direction := 1
                    Sequence_GT := _Sequence_LT_A_2
                    Sequence_LT := _Sequence_LT_A_1
                    Compare_Loop := Compare_LT
                } else {
                    if Value < RightV {
                        ; `Value` is out of range.
                        return
                    }
                    HEV_Direction := -1
                    Sequence_GT := _Sequence_LT_D_2
                    Sequence_LT := _Sequence_LT_D_1
                    Compare_Loop := Compare_GT
                }
            ;@endregion

            ;@region case <
            case '<':
                Condition := Compare_LT
                AltCondition := Compare_GTE
                HandleEqualValues := _HandleEqualValues_NEQ
                EQ := false
                if RightV > LeftV {
                    if Value <= LeftV {
                        ; `Value` is out of range.
                        return
                    }
                    HEV_Direction := -1
                    Sequence_GT := _Sequence_LT_A_2
                    Sequence_LT := _Sequence_LT_A_1
                    Compare_Loop := Compare_LT
                } else {
                    if Value <= RightV {
                        ; `Value` is out of range.
                        return
                    }
                    HEV_Direction := 1
                    Sequence_GT := _Sequence_LT_D_2
                    Sequence_LT := _Sequence_LT_D_1
                    Compare_Loop := Compare_GT
                }
            ;@endregion

            default: throw ValueError('Invalid condition.', -1, Condition)
        }
        ;@endregion

        StopBinary := 0
        R := IndexEnd - IndexStart + 1
        loop 100 {
            if R * 0.5 ** (StopBinary + 1) * 14 <= 27 {
                break
            }
            StopBinary++
        }

        ;@region Process
        loop StopBinary {
            i := Right - Ceil((Right - Left) * 0.5)
            while !Arr.Has(i) {
                if i + 1 > IndexEnd {
                    while !Arr.Has(--i) {
                        continue
                    }
                    if Compare_GT() {
                        return Sequence_GT()
                    } else {
                        return Sequence_LT()
                    }
                } else {
                    i++
                }
            }
            if Compare_EQ() {
                return HandleEqualValues()
            }
            if Compare_Loop() {
                Left := i
            } else {
                Right := i
            }
        }
        ; If we go the entire loop without landing on an equal value, then we search sequentially
        ; from `i`.
        if Compare_EQ() {
            return HandleEqualValues()
        } else if Compare_GT() {
            return Sequence_GT()
        } else {
            return Sequence_LT()
        }
        ;@endregion

        _Compare_GTE_1() => Arr[i] >= Value
        _Compare_GTE_2() => ValueCallback(Arr[i], i, Arr) >= Value
        _Compare_GT_1() => Arr[i] > Value
        _Compare_GT_2() => ValueCallback(Arr[i], i, Arr) > Value
        _Compare_LTE_1() => Arr[i] <= Value
        _Compare_LTE_2() => ValueCallback(Arr[i], i, Arr) <= Value
        _Compare_LT_1() => Arr[i] < Value
        _Compare_LT_2() => ValueCallback(Arr[i], i, Arr) < Value
        _Compare_EQ_1() => Arr[i] == Value
        _Compare_EQ_2() => ValueCallback(Arr[i], i, Arr) == Value

        ;@region Sequence
        /**
         * @description - Used when:
         * - `!Compare_GT()`
         * - Ascent == 1
         * - > or >=
         */
        _Sequence_GT_A_1() {
            ; If `Value` > <current value>, and if GT, then we must search toward `Value`
            ; until we hit an equal or greater value. If we hit an equal value and if ET, we return
            ; that. If not ET, then we keep going until we find a greater value. Since we have
            ; already set `Condition` to check for the correct condition, we just need to check
            ; `Condition`.
            loop IndexEnd - i {
                if Arr.Has(++i) {
                    if Condition() {
                        OutValue := Arr[i]
                        return i
                    }
                }
            }
            OutValue := Arr[i]
            return i
        }
        /**
         * @description - Used when:
         * - `!Compare_GT()`
         * - Ascent == -1
         * - > or >=
         */
        _Sequence_GT_D_1() {
            ; Same as above but in the opposite direction.
            loop i - IndexStart {
                if Arr.Has(--i) {
                    if Condition() {
                        OutValue := Arr[i]
                        return i
                    }
                }
            }
            OutValue := Arr[i]
            return i
        }
        /**
         * @description - Used when:
         * - `Compare_GT()`
         * - Ascent == 1
         * - > or >=
         */
        _Sequence_GT_A_2() {
            ; If `Value` < <current value> and if GT, then we are already at an index that
            ; satisfies the condition, but we do not know for sure that it is the first index.
            ; So we must search toward `Value` until finding an index that does not
            ; satisfy the condition. In this case we search agains the direction of ascent.
            Previous := i
            loop i - IndexStart {
                if Arr.Has(--i) {
                    if AltCondition() {
                        if EQ && Compare_EQ() {
                            return HandleEqualValues()
                        } else {
                            OutValue := Arr[Previous]
                            return Previous
                        }
                    } else {
                        Previous := i
                    }
                }
            }
            OutValue := Arr[Previous]
            return Previous
        }
        /**
         * @description - Used when:
         * - `Compare_GT()`
         * - Ascent == -1
         * - > or >=
         */
        _Sequence_GT_D_2() {
            ; Same as above but opposite direction.
            Previous := i
            loop IndexEnd - i {
                if Arr.Has(++i) {
                    if AltCondition() {
                        if EQ && Compare_EQ() {
                            return HandleEqualValues()
                        } else {
                            OutValue := Arr[Previous]
                            return Previous
                        }
                    } else {
                        Previous := i
                    }
                }
            }
            OutValue := Arr[Previous]
            return Previous
        }
        /**
         * @description - Used when:
         * - `!Compare_GT()`
         * - Ascent == 1
         * - < or <=
         */
        _Sequence_LT_A_1() {
            ; If `Value` > <current value> and if not GT, then we are already at an index that
            ; satisfies the condition, but we do not know for sure that it is the first index.
            ; So we must search toward `Value` until finding an index that does not
            ; satisfy the condition. If we run into an equal value, and if EQ, then we can
            ; pass control over to `HandleEqualValues` because it will do the rest. If not EQ,
            ; then we can ignore equality because we just need `AltCondition` to return true.
            Previous := i
            loop IndexEnd - i {
                if Arr.Has(++i) {
                    if AltCondition() {
                        if EQ && Compare_EQ() {
                            return HandleEqualValues()
                        } else {
                            OutValue := Arr[Previous]
                            return Previous
                        }
                    } else {
                        Previous := i
                    }
                }
            }
            OutValue := Arr[Previous]
            return Previous
        }
        /**
         * @description - Used when:
         * - `!Compare_GT()`
         * - Ascent == -1
         * - < or <=
         */
        _Sequence_LT_D_1() {
            ; Same as above but opposite direction.
            Previous := i
            loop i - IndexStart {
                if Arr.Has(--i) {
                    if AltCondition() {
                        if EQ && Compare_EQ() {
                            return HandleEqualValues()
                        } else {
                            OutValue := Arr[Previous]
                            return Previous
                        }
                    } else {
                        Previous := i
                    }
                }
            }
            OutValue := Arr[Previous]
            return Previous
        }
        /**
         * @description - Used when:
         * - `Compare_GT()`
         * - Ascent == 1
         * - < or <=
         */
        _Sequence_LT_A_2() {
            ; If `Value` < <current value>, and if not GT, then we must go opposite of the
            ; direction of ascent until `Condition` returns true.
            loop i - IndexStart {
                if Arr.Has(--i) {
                    if Condition() {
                        OutValue := Arr[i]
                        return i
                    }
                }
            }
            OutValue := Arr[i]
            return i
        }
        /**
         * @description - Used when:
         * - `Compare_GT()`
         * - Ascent == -1
         * - < or <=
         */
        _Sequence_LT_D_2() {
            ; Same as above but opposite direction.
            loop IndexEnd - i {
                if Arr.Has(++i) {
                    if Condition() {
                        OutValue := Arr[i]
                        return i
                    }
                }
            }
            OutValue := Arr[i]
            return i
        }
        ;@endregion

        ; This function is used when equality is included in the condition.
        _HandleEqualValues_EQ() {
            ; We are able to prepare for this function beforehand by understanding what direction
            ; we must search in order to find the correct index to return. Since equality is included,
            ; we must search in the opposite direction we otherwise would have, then return the
            ; index that is previous to the first index which contains a value that is NOT equivalent
            ; to `Value`.
            ; Consider an array:
            ; -500 -499 -498 -497 -497 -497 -496 -495 -494
            ; `Value := -497`
            ; If GT, then the correct index is 4 because it is the first index to contain a value
            ; that meets the condition in the search direction, so to find it we must search
            ; <DirectionofAscent> * -1 (-1 in the example) then return 4 when we get to 3.
            ; If LT, then the correct index is 6, so we must do the opposite. Specifically,
            ; we must search <DirectionofAscent> (1 in the example) then return 6 when we get to 7.
            /**
             * @example
                if GT {
                    HEV_Direction := BaseDirection == 1 ? -1 : 1
                } else {
                    HEV_Direction := BaseDirection == 1 ? 1 : -1
                }
             * @
             */
            if HEV_Direction > 0 {
                i--
                LoopCount := IndexEnd - i
            } else {
                i++
                LoopCount := i - IndexStart
            }
            loop LoopCount {
                i += HEV_Direction
                if Arr.Has(i) {
                    if !Compare_EQ() {
                        break
                    }
                    Previous := i
                }
            }
            OutValue := Arr[Previous]
            return Previous
        }
        ; This function is used when equality is not included in the condition.
        _HandleEqualValues_NEQ() {
            ; When equality is not included, the process is different. When GT, we no longer invert
            ; the direction of ascent. We are interested in the first index that contains a value
            ; which meets the condition in the same direction as the direction of ascent. When LT,
            ; we are interested in the first index that contains a value which meets the condition
            ; in the opposite direction of the direction of ascent.
            ; Consider an array:
            ; -500 -499 -498 -497 -497 -497 -496 -495 -494
            ; `Value := -497`
            ; If GT, then the correct index is 7 because it is the first index to contain a value
            ; that meets the condition in the search direction, so to find it we must search
            ; <DirectionofAscent> (1 in the example) then return 7 when we get to 7.
            ; If LT, then the correct index is 3, so we must do the opposite. Specifically,
            ; we must search <DirectionofAscent> * -1 (-1 in the example) then return 3 when we get to 3.
            /**
             * @example
                if GT {
                    HEV_Direction := BaseDirection == 1 ? 1 : -1
                } else {
                    HEV_Direction := BaseDirection == 1 ? -1 : 1
                }
             * @
             */
            loop HEV_Direction > 0 ? IndexEnd - i + 1 : i {
                i += HEV_Direction
                if Arr.Has(i) {
                    if !Compare_EQ() {
                        break
                    }
                }
            }
            if Arr.Has(i) {
                OutValue := Arr[i]
                return i
            }
        }
        _GetNearest_L2R() {
            loop IndexEnd - i + 1 {
                if Arr.Has(i) {
                    return 1
                }
                i++
            }
        }
        _GetNearest_R2L() {
            loop i - IndexStart + 1 {
                if Arr.Has(i) {
                    return 1
                }
                i--
            }
        }
    }
    ;@endregion


    ;@region Equality
    /**
     * @description - Performs a binary search on an array to find one or more indices that contain
     * the input value. This function has these characteristics:
     * - The array is assumed to be in order of value.
     * - The array may have unset indices as long as every set index is in order.
     * - Items may be objects - set `ValueCallback` to return the item value.
     * @example
        MyArr := [ { prop: 1 }, { prop: 22 }, { prop: 1776 } ]
        AccessorFunc(Item, *) {
            return Item.prop
        }
        MsgBox(QuickFind.Equality(MyArr, 22, , , , AccessorFunc)) ; 2
     * @
     * - The search direction is always left-to-right. If there are multiple indices with the
     * input value, the index returned by the function will be the lowest index, and the index
     * assigned to `OutLastIndex` will be the highest index.
     * @param {Array} Arr - The array to search.
     * @param {Number|Object} Value - The value to search for. This value may be an object as long
     * as its numerical value can be returned by the `ValueCallback` function. This is not required
     * to be an object when the items in the array are objects; it can be either an object or number.
     * @param {VarRef} [OutLastIndex] - If there are multiple indices containing the input value,
     * `QuickFind.Equality` assigns to this variable the last index which contains the input value.
     * If there is one index containing the input value, `OutLastIndex` will be the same as the return
     * value.
     * @param {Number} [IndexStart=1] - The index to start the search at.
     * @param {Number} [IndexEnd] - The index to end the search at. If not provided, the length of the
     * array is used.
     * @param {Func} [ValueCallback] - The function that returns the item's numeric value.
     * The function can accept up to three parameters, in this order:
     * - The current item being evaluated.
     * - The item's index.
     * - The input array.
     * @returns {Integer} - The index of the first value that satisfies the condition.
     */
    static Equality(Arr, Value, &OutLastIndex?, IndexStart := 1, IndexEnd?, ValueCallback?) {
        local i, ItemValue, GetNearest, Result
        if !Arr.Length {
            throw Error('The array is empty.', -1)
        }
        if !IsSet(IndexEnd) {
            IndexEnd := Arr.Length
        }
        if IndexEnd <= IndexStart {
            throw Error('The end index is less than or equal to the start index.'
            , -1, 'IndexEnd: ' IndexEnd '; IndexStart: ' IndexStart)
        }
        StopBinary := 0
        R := IndexEnd - IndexStart + 1
        loop 100 {
            if R * 0.5 ** (StopBinary + 1) * 14 <= 27 {
                break
            }
            StopBinary++
        }
        if IsSet(ValueCallback) {
            Compare := _Compare2
            CompareGT := _CompareGT2
            if IsObject(Value) {
                Value := ValueCallback(Value)
            }
        } else {
            Compare := _Compare1
            CompareGT := _CompareGT1
        }
        loop StopBinary {
            if !Arr.Has(i := IndexEnd - Ceil((IndexEnd - IndexStart) * 0.5)) {
                if !_GetNearest() {
                    return
                }
            }
            if Compare() {
                Start := Result := OutLastIndex := i
                loop i - IndexStart + 1 {
                    if Arr.Has(--i) {
                        if Compare() {
                            Result := i
                        } else {
                            break
                        }
                    }
                }
                i := Start
                loop IndexEnd - i + 1 {
                    if Arr.Has(++i) {
                        if Compare() {
                            OutLastIndex := i
                        } else {
                            break
                        }
                    }
                }
                return Result
            } else if CompareGT() {
                IndexStart := i
            } else {
                IndexEnd := i
            }
        }
        i := IndexStart - 1
        loop IndexEnd - i {
            if Arr.Has(++i) && Compare() {
                Result := OutLastIndex := i
                loop IndexEnd - i {
                    if Arr.Has(++i) {
                        if Compare() {
                            OutLastIndex := i
                        } else {
                            break
                        }
                    }
                }
                break
            }
        }
        return Result ?? ''

        _Compare1() => Value == Arr[i]
        _Compare2() => Value == ValueCallback(Arr[i], i, Arr)
        _CompareGT1() => Value > Arr[i]
        _CompareGT2() => Value > ValueCallback(Arr[i], i, Arr)
        _GetNearest() {
            Start := i
            loop IndexEnd - i + 1 {
                if Arr.Has(++i) {
                    return 1
                }
            }
            i := Start
            loop i - IndexStart + 1 {
                if Arr.Has(--i) {
                    return 1
                }
            }
        }
    }
    ;@endregion


    ;@region WordValue
    /**
     * @description - A function that's compatible with `QuickFind` that can be used to search
     * an array that is sorted alphabetically for an input word. This has (a degree of) accuracy up
     * to 10 characters. Any characters past 10 are ignored. To use this with `QuickFind`, you want
     * to create a `BoundFunc` using `ObjBindMethod. Here's how:
     * @example
        GetWordValue := ObjBindMethod(QuickFind, 'GetWordValue', true) ; true to use cache
        ; or
        GetWordValue := ObjBindMethod(QuickFind, 'GetWordValue', false) ; false to not use cache
     * @
     * @param {Boolean} [UseCache=true] - When true, word values are cached and recalled from the
     * cache. When false, word values are always calculated.
     * @param {String} Word - The input word.
     * @returns {Float} - A number that can be used for various sorting operations.
     */
    static GetWordValue(UseCache, Word, *) {
        static Cache := QuickFind.WordValueCache
        local n := 0
        if UseCache {
            if Cache.Has(Word) {
                return Cache.Get(Word)
            }
            _Process()
            Cache.Set(Word, n)
        } else {
            _Process()
        }
        return n

        _Process() {
            for c in StrSplit(StrUpper(Word)) {
                if Ord(c) >= 123
                    n += (Ord(c) - 58) / 68 ** A_Index
                else
                    n += (Ord(c) - 32) / 68 ** A_Index
                if A_Index >= 10 ; Accuracy is completely lost around 10 characters.
                    break
            }
        }
    }
    ;@endregion


    /**
     * @property {Map} QuickFind.WordValueCache - A cache used by `GetWordValue`. This gets
     * overridden at runtime.
     */
    static WordValueCache := ''


    ;@region Func
    class Func {


        ;@region Call
        /**
         * @description - Initializes the needed values that are initialized at the start of
         * `QuickFind`, then returns a closure that can be called repeadly to search the input
         * array. This will perform slightly better compared to calling `QuickFind` multiple times
         * for the same input array.
         * - The array does not need to have the same values in it each time the function is called,
         * but these conditions must be true for the function to return the expected result:
         *   - The array must be sorted in the same direction as it was when the function object
         * was created.
         *   - The array cannot be a shorter length than `IndexEnd`.
         *   - The array could be longer than `IndexEnd`, but any values past `IndexEnd` are
         * ignored.
         * - The reference count for the input array is incremented by 1. If you need to dispose
         * the array, you will have to call `Dispose` on this object to get rid of that reference.
         * Calling the function after `Dispose` results in an error.
         * - The function parameters are:
         *   - **Value** - The value to search for.
         *   - **OutValue** - A variable that will receive the value at the found index.
         * @example
            Arr := [1, 5, 12, 19, 44, 101, 209, 209, 230, 1991]
            Finder := QuickFind.Func(Arr)
            Index := Finder(12, &Value)
            MsgBox(Index) ; 3
            MsgBox(Value) ; 12
            ; Do more work
            ; When finished
            Finder.Dispose()
            Index := Finder(44, &Value) ; Error: This object has been disposed.
         * @
         * @param {Array} Arr - The array to search.
         * @param {String} [Condition='>='] - The inequality symbol indicating what condition satisfies
         * the search. Valid values are:
         * - ">": `QuickFind` returns the index of the first value greater than the input value.
         * - ">=": `QuickFind` returns the index of the first value greater than or equal to the input value.
         * - "<": `QuickFind` returns the index of the first value less than the input value.
         * - "<=": `QuickFind` returns the index of the first value less than or equal to the input value.
         * @param {Number} [IndexStart=1] - The index to start the search at.
         * @param {Number} [IndexEnd] - The index to end the search at. If not provided, the length of the
         * array is used.
         * @param {Func} [ValueCallback] - A function that returns the item's numeric value.
         * The function can accept up to three parameters, in this order. If not using one of the
         * parameters, be sure to include the necessary `*` symbol to avoid a runtime error.
         * - The current item being evaluated.
         * - The item's index.
         * - The input array.
         * @example
           ; Assume for some reason I have an array that, on the odd indices contains an item with a
           ; property `Prop`, and on the even indices contains an item with a key `key`.
           MyArr := [ { Prop: 1 }, Map('key', 22), { Prop: 55 }, Map('key', 55), { Prop: 1776 } ]
           ; I don't need the array object for my function to accomplish it's task, so I put `*` to
           ; ignore that parameter.
            AccessorFunc(Item, Index, *) {
                if Mod(Index, 2) {
                    return Item.Prop
                } else {
                    return Item['key']
                }
            }
            ; I could also accomplish the same thing like this
            AccessorFuncBetter(Item, *) {
                if Type(Item) == 'Map' {
                    return Item['key']
                } else {
                    return Item.Prop
                }
            }
         * @
         * @returns {Integer} - The index of the first value that satisfies the condition.
         */
        static Call(Arr, Condition := '>=', IndexStart := 1, IndexEnd?, ValueCallback?) {
            if !Arr.Length {
                throw Error('The array is empty.', -1)
            }
            if !IsSet(IndexEnd) {
                IndexEnd := Arr.Length
            }
            if IndexEnd <= IndexStart {
                throw Error('The end index is less than or equal to the start index.'
                , -1, 'IndexEnd: ' IndexEnd '`tIndexStart: ' IndexStart)
            }
            Fn := {}
            Fn.DefineProp('Call', { Call: _GetClosure(Arr) })
            Fn.ObjPtr := ObjPtr(Arr)
            ObjSetBase(Fn, QuickFind.Func.Prototype)
            ObjAddRef(ObjPtr(Arr))
            return Fn

            _GetClosure(Arr) {
                local InputValue, Left, Right, _OutValue

                ;@region Compare fn
                if IsSet(ValueCallback) {
                    Compare_GT := _Compare_GT_2
                    Compare_GTE := _Compare_GTE_2
                    Compare_LT := _Compare_LT_2
                    Compare_LTE := _Compare_LTE_2
                    Compare_EQ := _Compare_EQ_2
                    GetValue := () => ValueCallback(Arr[i], i, Arr)
                } else {
                    Compare_GT := _Compare_GT_1
                    Compare_GTE := _Compare_GTE_1
                    Compare_LT := _Compare_LT_1
                    Compare_LTE := _Compare_LTE_1
                    Compare_EQ := _Compare_EQ_1
                    GetValue := () => Arr[i]
                }
                ;@endregion

                ;@region Sort direction
                i := 1
                ; No return value indicates the array had no set indices between IndexStart and IndexEnd.
                if !_GetNearest_L2R() {
                    throw Error('The indices within the input range are all unset.', -1)
                }
                LeftV := GetValue()
                i := Arr.Length
                ; This will always return 1 because we know that there is at least one value in the input range.
                _GetNearest_R2L()
                RightV := GetValue()
                ; We must be able to identify the sort direction.
                if RightV == LeftV {
                    throw ValueError('``QuickFind.Func`` is not set up to handle arrays with only'
                    ' one unique value. Call ``QuickFind`` instead.', -1)
                }
                ;@endregion

                ;@region Condition
                switch Condition {

                    ;@region case >=
                    case '>=':
                        Condition := Compare_GTE
                        AltCondition := Compare_LT
                        HandleEqualValues := _HandleEqualValues_EQ
                        EQ := true
                        if RightV > LeftV {
                            ShortCircuit := () => InputValue > RightV
                            GetV := _GetRightV
                            HEV_Direction := -1
                            Sequence_GT := _Sequence_GT_A_2
                            Sequence_LT := _Sequence_GT_A_1
                            Compare_Loop := Compare_LT
                        } else {
                            ShortCircuit := () =>  InputValue > LeftV
                            GetV := _GetLeftV
                            HEV_Direction := 1
                            Sequence_GT := _Sequence_GT_D_2
                            Sequence_LT := _Sequence_GT_D_1
                            Compare_Loop := Compare_GT
                        }
                    ;@endregion

                    ;@region case >
                    case '>':
                        Condition := Compare_GT
                        AltCondition := Compare_LTE
                        HandleEqualValues := _HandleEqualValues_NEQ
                        EQ := false
                        if RightV > LeftV {
                            ShortCircuit := () => InputValue >= RightV
                            GetV := _GetRightV
                            HEV_Direction := 1
                            Sequence_GT := _Sequence_GT_A_2
                            Sequence_LT := _Sequence_GT_A_1
                            Compare_Loop := Compare_LT
                        } else {
                            ShortCircuit := () => InputValue >= LeftV
                            GetV := _GetLeftV
                            HEV_Direction := -1
                            Sequence_GT := _Sequence_GT_D_2
                            Sequence_LT := _Sequence_GT_D_1
                            Compare_Loop := Compare_GT
                        }
                    ;@endregion

                    ;@region case <=
                    case '<=':
                        Condition := Compare_LTE
                        AltCondition := Compare_GT
                        HandleEqualValues := _HandleEqualValues_EQ
                        EQ := true
                        if RightV > LeftV {
                            ShortCircuit := () => InputValue < LeftV
                            GetV := _GetLeftV
                            HEV_Direction := 1
                            Sequence_GT := _Sequence_LT_A_2
                            Sequence_LT := _Sequence_LT_A_1
                            Compare_Loop := Compare_LT
                        } else {
                            ShortCircuit := () => InputValue < RightV
                            GetV := _GetRightV
                            HEV_Direction := -1
                            Sequence_GT := _Sequence_LT_D_2
                            Sequence_LT := _Sequence_LT_D_1
                            Compare_Loop := Compare_GT
                        }
                    ;@endregion

                    ;@region case <
                    case '<':
                        Condition := Compare_LT
                        AltCondition := Compare_GTE
                        HandleEqualValues := _HandleEqualValues_NEQ
                        EQ := false
                        if RightV > LeftV {
                            ShortCircuit := () => InputValue <= LeftV
                            GetV := _GetLeftV
                            HEV_Direction := -1
                            Sequence_GT := _Sequence_LT_A_2
                            Sequence_LT := _Sequence_LT_A_1
                            Compare_Loop := Compare_LT
                        } else {
                            ShortCircuit := () => InputValue <= RightV
                            GetV := _GetRightV
                            HEV_Direction := 1
                            Sequence_GT := _Sequence_LT_D_2
                            Sequence_LT := _Sequence_LT_D_1
                            Compare_Loop := Compare_GT
                        }
                    ;@endregion

                    default: throw ValueError('Invalid condition.', -1, Condition)
                }
                ;@endregion

                StopBinary := 0
                R := IndexEnd - IndexStart + 1
                loop 100 {
                    if R * 0.5 ** (StopBinary + 1) * 14 <= 27 {
                        break
                    }
                    StopBinary++
                }

                ; These are no longer needed
                Arr := R := i := LeftV := RightV := InputValue := unset

                return Call

                Call(Self, Value, &OutValue) {
                    local RightV, LeftV
                    Arr := ObjFromPtrAddRef(Self.ObjPtr)
                    InputValue := IsObject(Value) ? GetValue(InputValue) : Value
                    ; Some parts of the function depend the assumption that `Value` does not lie
                    ; outside the possible input range of values. We only need one of `LeftV` or
                    ; `RightV` to accomplish this.
                    GetV()
                    if ShortCircuit() {
                        return
                    }
                    Left := IndexStart
                    Right := IndexEnd

                    loop StopBinary {
                        i := Right - Ceil((Right - Left) * 0.5)
                        while !Arr.Has(i) {
                            if i + 1 > IndexEnd {
                                while !Arr.Has(--i) {
                                    continue
                                }
                                if Compare_GT() {
                                    Result := Sequence_GT()
                                    OutValue := _OutValue
                                    return Result
                                } else {
                                    Result := Sequence_LT()
                                    OutValue := _OutValue
                                    return Result
                                }
                            } else {
                                i++
                            }
                        }
                        if Compare_EQ() {
                            Result := HandleEqualValues()
                            OutValue := _OutValue
                            return Result
                        }
                        if Compare_Loop() {
                            Left := i
                        } else {
                            Right := i
                        }
                    }
                    ; If we go the entire loop without landing on an equal value, then we search
                    ; sequentially from `i`.
                    if Compare_EQ() {
                        Result :=  HandleEqualValues()
                    } else if Compare_GT() {
                        Result :=  Sequence_GT()
                    } else {
                        Result :=  Sequence_LT()
                    }
                    OutValue := _OutValue
                    return Result
                }

                _Compare_GTE_1() => Arr[i] >= InputValue
                _Compare_GTE_2() => ValueCallback(Arr[i], i, Arr) >= InputValue
                _Compare_GT_1() => Arr[i] > InputValue
                _Compare_GT_2() => ValueCallback(Arr[i], i, Arr) > InputValue
                _Compare_LTE_1() => Arr[i] <= InputValue
                _Compare_LTE_2() => ValueCallback(Arr[i], i, Arr) <= InputValue
                _Compare_LT_1() => Arr[i] < InputValue
                _Compare_LT_2() => ValueCallback(Arr[i], i, Arr) < InputValue
                _Compare_EQ_1() => Arr[i] == InputValue
                _Compare_EQ_2() => ValueCallback(Arr[i], i, Arr) == InputValue

                ;@region Sequence
                /**
                 * @description - Used when:
                 * - `!Compare_GT()`
                 * - Ascent == 1
                 * - > or >=
                 */
                _Sequence_GT_A_1() {
                    ; If `Value` > <current value>, and if GT, then we must search toward `Value`
                    ; until we hit an equal or greater value. If we hit an equal value and if ET, we return
                    ; that. If not ET, then we keep going until we find a greater value. Since we have
                    ; already set `Condition` to check for the correct condition, we just need to check
                    ; `Condition`.
                    loop IndexEnd - i {
                        if Arr.Has(++i) {
                            if Condition() {
                                _OutValue := Arr[i]
                                return i
                            }
                        }
                    }
                    _OutValue := Arr[i]
                    return i
                }
                /**
                 * @description - Used when:
                 * - `!Compare_GT()`
                 * - Ascent == -1
                 * - > or >=
                 */
                _Sequence_GT_D_1() {
                    ; Same as above but in the opposite direction.
                    loop i - IndexStart {
                        if Arr.Has(--i) {
                            if Condition() {
                                _OutValue := Arr[i]
                                return i
                            }
                        }
                    }
                    _OutValue := Arr[i]
                    return i
                }
                /**
                 * @description - Used when:
                 * - `Compare_GT()`
                 * - Ascent == 1
                 * - > or >=
                 */
                _Sequence_GT_A_2() {
                    ; If `Value` < <current value> and if GT, then we are already at an index that
                    ; satisfies the condition, but we do not know for sure that it is the first index.
                    ; So we must search toward `Value` until finding an index that does not
                    ; satisfy the condition. In this case we search agains the direction of ascent.
                    Previous := i
                    loop i - IndexStart {
                        if Arr.Has(--i) {
                            if AltCondition() {
                                if EQ && Compare_EQ() {
                                    return HandleEqualValues()
                                } else {
                                    _OutValue := Arr[Previous]
                                    return Previous
                                }
                            } else {
                                Previous := i
                            }
                        }
                    }
                    _OutValue := Arr[Previous]
                    return Previous
                }
                /**
                 * @description - Used when:
                 * - `Compare_GT()`
                 * - Ascent == -1
                 * - > or >=
                 */
                _Sequence_GT_D_2() {
                    ; Same as above but opposite direction.
                    Previous := i
                    loop IndexEnd - i {
                        if Arr.Has(++i) {
                            if AltCondition() {
                                if EQ && Compare_EQ() {
                                    return HandleEqualValues()
                                } else {
                                    _OutValue := Arr[Previous]
                                    return Previous
                                }
                            } else {
                                Previous := i
                            }
                        }
                    }
                    _OutValue := Arr[Previous]
                    return Previous
                }
                /**
                 * @description - Used when:
                 * - `!Compare_GT()`
                 * - Ascent == 1
                 * - < or <=
                 */
                _Sequence_LT_A_1() {
                    ; If `Value` > <current value> and if not GT, then we are already at an index that
                    ; satisfies the condition, but we do not know for sure that it is the first index.
                    ; So we must search toward `Value` until finding an index that does not
                    ; satisfy the condition. If we run into an equal value, and if EQ, then we can
                    ; pass control over to `HandleEqualValues` because it will do the rest. If not EQ,
                    ; then we can ignore equality because we just need `AltCondition` to return true.
                    Previous := i
                    loop IndexEnd - i {
                        if Arr.Has(++i) {
                            if AltCondition() {
                                if EQ && Compare_EQ() {
                                    return HandleEqualValues()
                                } else {
                                    _OutValue := Arr[Previous]
                                    return Previous
                                }
                            } else {
                                Previous := i
                            }
                        }
                    }
                    _OutValue := Arr[Previous]
                    return Previous
                }
                /**
                 * @description - Used when:
                 * - `!Compare_GT()`
                 * - Ascent == -1
                 * - < or <=
                 */
                _Sequence_LT_D_1() {
                    ; Same as above but opposite direction.
                    Previous := i
                    loop i - IndexStart {
                        if Arr.Has(--i) {
                            if AltCondition() {
                                if EQ && Compare_EQ() {
                                    return HandleEqualValues()
                                } else {
                                    _OutValue := Arr[Previous]
                                    return Previous
                                }
                            } else {
                                Previous := i
                            }
                        }
                    }
                    _OutValue := Arr[Previous]
                    return Previous
                }
                /**
                 * @description - Used when:
                 * - `Compare_GT()`
                 * - Ascent == 1
                 * - < or <=
                 */
                _Sequence_LT_A_2() {
                    ; If `Value` < <current value>, and if not GT, then we must go opposite of the
                    ; direction of ascent until `Condition` returns true.
                    loop i - IndexStart {
                        if Arr.Has(--i) {
                            if Condition() {
                                _OutValue := Arr[i]
                                return i
                            }
                        }
                    }
                    _OutValue := Arr[i]
                    return i
                }
                /**
                 * @description - Used when:
                 * - `Compare_GT()`
                 * - Ascent == -1
                 * - < or <=
                 */
                _Sequence_LT_D_2() {
                    ; Same as above but opposite direction.
                    loop IndexEnd - i {
                        if Arr.Has(++i) {
                            if Condition() {
                                _OutValue := Arr[i]
                                return i
                            }
                        }
                    }
                    _OutValue := Arr[i]
                    return i
                }
                ;@endregion
                ; This function is used when equality is included in the condition.
                _HandleEqualValues_EQ() {
                    ; We are able to prepare for this function beforehand by understanding what direction
                    ; we must search in order to find the correct index to return. Since equality is included,
                    ; we must search in the opposite direction we otherwise would have, then return the
                    ; index that is previous to the first index which contains a value that is NOT equivalent
                    ; to `Value`.
                    ; Consider an array:
                    ; -500 -499 -498 -497 -497 -497 -496 -495 -494
                    ; `Value := -497`
                    ; If GT, then the correct index is 4 because it is the first index to contain a value
                    ; that meets the condition in the search direction, so to find it we must search
                    ; <DirectionofAscent> * -1 (-1 in the example) then return 4 when we get to 3.
                    ; If LT, then the correct index is 6, so we must do the opposite. Specifically,
                    ; we must search <DirectionofAscent> (1 in the example) then return 6 when we get to 7.
                    /**
                     * @example
                        if GT {
                            HEV_Direction := BaseDirection == 1 ? -1 : 1
                        } else {
                            HEV_Direction := BaseDirection == 1 ? 1 : -1
                        }
                    * @
                    */
                    if HEV_Direction > 0 {
                        i--
                        LoopCount := IndexEnd - i
                    } else {
                        i++
                        LoopCount := i - IndexStart
                    }
                    loop LoopCount {
                        i += HEV_Direction
                        if Arr.Has(i) {
                            if !Compare_EQ() {
                                break
                            }
                            Previous := i
                        }
                    }
                    _OutValue := Arr[Previous]
                    return Previous
                }
                ; This function is used when equality is not included in the condition.
                _HandleEqualValues_NEQ() {
                    ; When equality is not included, the process is different. When GT, we no longer invert
                    ; the direction of ascent. We are interested in the first index that contains a value
                    ; which meets the condition in the same direction as the direction of ascent. When LT,
                    ; we are interested in the first index that contains a value which meets the condition
                    ; in the opposite direction of the direction of ascent.
                    ; Consider an array:
                    ; -500 -499 -498 -497 -497 -497 -496 -495 -494
                    ; `Value := -497`
                    ; If GT, then the correct index is 7 because it is the first index to contain a value
                    ; that meets the condition in the search direction, so to find it we must search
                    ; <DirectionofAscent> (1 in the example) then return 7 when we get to 7.
                    ; If LT, then the correct index is 3, so we must do the opposite. Specifically,
                    ; we must search <DirectionofAscent> * -1 (-1 in the example) then return 3 when we get to 3.
                    /**
                     * @example
                        if GT {
                            HEV_Direction := BaseDirection == 1 ? 1 : -1
                        } else {
                            HEV_Direction := BaseDirection == 1 ? -1 : 1
                        }
                    * @
                    */
                    loop HEV_Direction > 0 ? IndexEnd - i + 1 : i {
                        i += HEV_Direction
                        if Arr.Has(i) {
                            if !Compare_EQ() {
                                break
                            }
                        }
                    }
                    if Arr.Has(i) {
                        _OutValue := Arr[i]
                        return i
                    }
                }
                _GetLeftV() {
                    i := IndexStart
                    if !_GetNearest_L2R() {
                        throw Error('The indices within the input range are all unset.', -1)
                    }
                    LeftV := GetValue()
                }
                _GetRightV() {
                    i := IndexEnd
                    if !_GetNearest_R2L() {
                        throw Error('The indices within the input range are all unset.', -1)
                    }
                    RightV := GetValue()
                }
                _GetNearest_L2R() {
                    loop IndexEnd - i + 1 {
                        if Arr.Has(i) {
                            return 1
                        }
                        i++
                    }
                }
                _GetNearest_R2L() {
                    loop i - IndexStart + 1 {
                        if Arr.Has(i) {
                            return 1
                        }
                        i--
                    }
                }
            }
        }
        ;@endregion


        ;@region Prototype
        /**
         * @description - Calls `QuickFind` using the preset values. See the parameter descriptions
         * above `QuickFind.Call` for full details of the parameters.
         * @param {Number|Object} Value - The value to search for.
         * @param {VarRef} [OutValue] - A variable that will receive the value at the found index.
         * @returns {Integer} - The index of the value that satisfies the condition.
         */
        Call(Value, &OutValue?) {
            ; This is overridden by the constructor.
        }

        /**
         * @description - Releases the reference to the array. Calling the function after `Dispose`
         * results in an error.
         */
        Dispose() {
            Ptr := this.ObjPtr
            this.DeleteProp('ObjPtr')
            ObjRelease(Ptr)
            this.DefineProp('Call', { Call: ThrowError })
            ThrowError(*) {
                err := Error('This object has been disposed.', -2)
                err.What := Type(this) '.Prototype.Call'
                throw err
            }
        }
        ;@endregion
    }
    ;@endregion
}
