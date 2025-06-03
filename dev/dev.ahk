#include ..\config\VENV.ahk
#include dev-config.ahk
; https://github.com/Nich-Cebolla/Stringify-ahk
#include <Stringify>
; https://github.com/Nich-Cebolla/AutoHotkey-LibV2/blob/main/QuickSort.ahk
#include <QuickSort_V1.0.0>
; https://github.com/Nich-Cebolla/AutoHotkey-LibV2/tree/main/inheritance
#include <Inheritance>
; https://github.com/Nich-Cebolla/AutoHotkey-LibV2/blob/main/Align.ahk
#include <Align>
; https://github.com/Nich-Cebolla/AutoHotkey-LibV2/blob/main/GuiResizer.ahk
#include <GuiResizer>
; https://github.com/Nich-Cebolla/AutoHotkey-LibV2/blob/main/MenuBarConstructor.ahk
#include <MenuBarConstructor>
; https://github.com/Nich-Cebolla/AutoHotkey-LibV2/blob/main/ListViewHelper.ahk
#include <ListViewHelper>
; https://github.com/Nich-Cebolla/AutoHotkey-GetObjectFromString
#include <GetObjectFromString>

CoordMode('Mouse', 'Screen')
CoordMode('Tooltip', 'Screen')

class dev {
    static __New() {
        this.Config := DevConfig
        this.Scripts := Map()
    }

    static Call() {
        Conf := this.Config
        Handler := this.Handler := {
            ThisScript: ts := this.GetThisScript()
        }
        this.Scripts.Set('ThisScript', ts)
        Handler.G := G := Gui('+Resize', Conf.Title, Handler)
        G.SetFont('s' Conf.FontSize)
        G.MarginX := Conf.MarginX
        G.MarginY := Conf.MarginY
        for s in StrSplit(Conf.FontStandard, ',') {
            G.SetFont(, s)
        }

        ; Methods section
        Methods := Handler.Methods := []
        Methods.Capacity := ts.GetCollection('StaticMethod').Capacity
        TextWidth := 0
        pEditWidth := Conf.Methods.ParamEditWidth
        for Name, Component in ts.GetCollection('StaticMethod') {
            Methods.Push(O := {
                Text: G.Add('Text', , Component.Name)
              , Checkbox: G.Add('Checkbox')
            })
            O.Checkbox.Name := 'Chk' Component.Name
            O.Checkbox.OnEvent('Click', 'HClickCheckboxMethod')
            O.Text.Name := 'Txt' Component.Name
            O.Text.GetPos(, , &cw)
            TextWidth := Max(TextWidth, cw)
            if Component.Params {
                es := O.Edits := []
                es.Capacity := Component.Params.Length
                for p in Component.Params {
                    es.Push(G.Add('Edit', 'w' pEditWidth, p.Default))
                    es[-1].Name := 'Param' Component.Name A_Index
                    es[-1].Param := p
                }
            }
            O.Button := G.Add('Button', , 'Call')
            O.Button.OnEvent('Click', 'HClickButtonCall')
        }
        Methods[1].Button.GetPos(, , &btnW, &btnH)
        Methods[1].Checkbox.GetPos(, , &chkW)
        _GetPos(Conf.Methods.Pos, &X, &Y)
        TxtX := X
        ChkX := TxtX + G.MarginX + TextWidth
        BtnX := ChkX + chkW + G.MarginX
        ParamX := BtnX + btnW + G.MaginX
        for O in Methods {
            O.Text.Move(TxtX, Y, TextWidth)
            O.Checkbox.Move(ChkX, Y)
            O.Button.Move(BtnX, Y)
            if O.HasOwnProp('Edits') {
                X := ParamX
                for e in O.Edits {
                    e.Move(X, Y)
                    X += pEditWidth + G.MarginX
                }
            }
            Y += btnH + G.MarginY
        }

        ; Scripts
        ConfLVScripts := this.Config.LVScripts
        _GetPos(ConfLVScripts.Pos, &X, &Y)
        LV := Handler.LVScripts := G.Add('ListView', Format('x{} y{} w{} r{} {} vLVScripts', X, Y, ConfLVScripts.W, ConfLVScripts.R, ConfLVScripts.Opt), ConfLVScripts.Headers)
        LV.Add(, 'ThisScript', A_ScriptFullPath)
        loop ConfLVScripts.Headers.Length {
            LV.ModifyCol(A_Index, 'AutoHdr')
        }
        LV.OnEvent('DoubleClick', 'HDoubleClickListviewScripts')

        ; Results
        ConfEditResults := this.Config.EditResults
        _GetPos(ConfEditResults.Pos, &X, &Y)
        this.Handler.EditResults := G.Add('Edit', Format(

        HClickButtonCall(Ctrl, *) {

        }
        HClickCheckboxMethod(Ctrl, *) {

        }

        ; Menu bar functions
        MFileLoadScript(*) {
            List := FileSelect('M1', A_ScriptDir, 'Select Files')
            if List.Length {
                for Path in List {
                    try {
                        this.GetScript(Path)
                    } catch Error as err {

                    }
                }
            }
        }

        _GetPos(Pos, &X, &Y) {
            if IsNumber(Pos.X) {
                X := Pos.X
            } else {
                X := _Proc(Pos.X)
            }
            if IsNumber(Pos.Y) {
                Y := Pos.Y
            } else {
                Y := _Proc(Pos.Y)
            }

            _Proc(Obj) {
                Ctrl := GetObjectFromString(Obj.Control, this.Handler)
                Ctrl.GetPos(&cx, &cy, &cw, &ch)
                n := %'c' Obj.Which%
                if Obj.HasOwnProp('Add') {
                    n += %'c' Obj.Add%
                }
                if Obj.HasOwnProp('AddMargin') {
                    n += this.Handler.G.Margin%Obj.Which%
                }
                if Obj.HasOwnProp('Offset') {
                    n += Obj.Offset
                }
                return n
            }
        }

    }
    static ConcatComponents() {
        Script := this.GetScript(this.Config.PathIn)
        i := '        '
        s := '{`n' i
        for Name, Index in Script.CollectionIndex {
            p := Name ': [ '
            Part := ''
            for n, c in Script.CollectionList[Index] {
                if StrLen(p) + StrLen(n) + StrLen(i) > 100 {
                    Part .= Trim(p, ', ') '`n'
                    p := ''
                }
                p .= '`'' n '`', '
            }
            s .= Part Trim(p, ', ') ' ]`n'
        }
    }
    static GetScript(Path) {
        Script := ScriptParser({ PathIn: Path })
        Script.RemoveStringsAndComments()
        Script.ParseClass()
        temp := Path
        while this.Scripts.Has(Path) {
            Path := temp '-' A_Index
        }
        this.Scripts.Set(Path, Script)
        this.Handler.LVScripts.Add(, 'Script' this.Scripts.Count, Path)
        return Script
    }
    static GetThisScript() {
        ts := this.ts := ScriptParser({ PathIn: A_ScriptFullPath })
        ts.RemoveStringsAndComments()
        ts.ParseClass()
        return ts
    }

    static ShowTooltip(Msg, Period := -2000) {
        static N := [1,2,3,4,5,6,7]
        z := N.Pop()
        MouseGetPos(&x, &y)
        Tooltip(Msg, x, y, z)
        if Period {
            SetTimer(_End.Bind(z), Period)
        }

        _End(z) {
            ToolTip(,,,z)
            N.Push(z)
        }
    }
}




/**
 * @description - Shows or hides the combobox's dropdown.
 * @param {ComboBox} ComboBox - The ComboBox object to show the dropdown for.
 * @param {Integer} [Value=1] - The value to pass to the `0x014F` message. 1 shows the
 * dropdown, 0 hides it.
 */
GuiCb_ShowDropdown(ComboBox, Value := 1) {
    SendMessage(0x014F, Value, 0, ComboBox.hWnd) ; CB_SHOWDROPDOWN
    return ''
}


/**
 * @description - Sets the minimum number of items to display in the dropdown.
 * @param {ComboBox} ComboBox - The ComboBox object to set the minimum number of items for.
 * @param {Integer} MinVisible - The minimum number of items to display in the dropdown.
 */
GuiCb_SetMinVisible(ComboBox, MinVisible) {
    SendMessage(0x1701, MinVisible, 0, ComboBox.hWnd) ; CB_SETMINVISIBLE
    return ''
}


/**
 * @description - Applies these to the ComboBox control:
 * - `Focus` event opens the dropdown.
 * - `LoseFocus` event closes the dropdown.
 * - Adds methods `AddEx` and `DeleteEx`, which you should use to add / remove items for as long as
 * this function is active. If you don't, your filter will be temporarily out of sync.
 * - `Change` event calls a filter function. The filter function will temporarily remove any items
 * from the combobox that do not contain the string that is within its edit banner. Specifically,
 * this sequence of actions occur:
 *   - Disables the change event handler and sets a timer that repeatedly checks if the text has
 * changed in the edit banner.
 *   - Processes the text that invoked the change event. Any items which do not contain the
 * input text are deleted from the combobox as well as from the array which you pass to the `Arr`
 * parameter (which is set to `ComboBox.__Arr`), and places them in a separate array for filtered
 * items (`ComboBox.__Filter`).
 *   - Repeatedly checks to see if the text has changed every 100 ms, synchronizing the filtered
 * items with any changes to the text.
 *   - When 500ms passes without a change being detected, disables the timer an re-enables the
 * change event handler.
 * @param {ComboBox} ComboBox - The ComboBox object to set the filter on.
 * @param {Array} Arr - The array that contains the words displayed by the combobox. This gets set
 * to `ComboBox.__Arr`.
 * @param {Integer} [MaxVisible=20] - The maximum rows of items to display in the dropdown.
 * @param {Integer} [AddRemove=1] - The value that gets passed to the third parameter of
 * `Gui.Control.Prototype.OnEvent`. Call this function with an `AddRemove` value of 0 to delete
 * the properties associated with the filter and to unset the event handlers.
 */
Cb_SetFilterOnChange(ComboBox, Arr, MaxVisible := 20, AddRemove := 1) {
    if !AddRemove {
        _DisposeFilter()
        return
    }
    ComboBox.OnEvent('Focus', HFocusComboBox, AddRemove)
    ; ComboBox.OnEvent('LoseFocus', HLoseFocusComboBox, AddRemove)
    ComboBox.OnEvent('Change', HChangeComboBox, AddRemove)
    ComboBox.__Arr := Arr
    ComboBox.__Transitory := []
    ComboBox.__Filter := []
    ComboBox.__Transitory.Capacity := ComboBox.__Filter.Capacity := Arr.Length
    ComboBox.__MaxVisible := MaxVisible
    ComboBox.__PreviousText := ''
    ComboBox.DefineProp('AddEx', { Call: AddEx })
    ComboBox.DefineProp('DeleteEx', { Call: DeleteEx })

    return ''

    HChangeComboBox(Ctrl, Item) {
        Time := A_TickCount
        Arr := Ctrl.__Arr
        Transitory := Ctrl.__Transitory
        Filter := Ctrl.__Filter
        Ctrl.OnEvent('Change', HChangeComboBox, 0)
        _Search()

        _Search() {
            loop {
                if Ctrl.__PreviousText == Ctrl.Text {
                    sleep 100
                    if A_TickCount - Time > 500 {
                        break
                    }
                    continue
                }
                if Ctrl.Text {
                    ; If the user added a character, then we only need to filter our current
                    ; filtered list, not the entire list.
                    if Ctrl.Text && (!Ctrl.__PreviousText || (StrLen(Ctrl.Text) > StrLen(Ctrl.__PreviousText) && InStr(Ctrl.Text, Ctrl.__PreviousText) == 1)) {
                        n := 0
                        for Item in Ctrl.__Arr {
                            if !InStr(Item, Ctrl.Text) {
                                Ctrl.__Transitory.Push(A_Index)
                            }
                        }
                        for Index in Ctrl.__Transitory {
                            Ctrl.__Filter.Push(Ctrl.__Arr.RemoveAt(Index - n))
                            Ctrl.Delete(Index - n)
                            n++
                        }
                        Ctrl.__Transitory := []
                        Ctrl.__Transitory.Capacity := Ctrl.__Arr.Capacity
                    } else if Ctrl.Text {
                        i := Ctrl.__Arr.Length
                        List := []
                        List.Capacity := Ctrl.__Arr.Length
                        for Item in Ctrl.__Filter {
                            if InStr(Item, Ctrl.Text) {
                                List.Push(Item)
                                Ctrl.__Arr.Push(Item)
                                Ctrl.__Transitory.Push(A_Index)
                            }
                        }
                        if List.Length {
                            Ctrl.Add(List)
                        }
                        n := 0
                        for Index in Ctrl.__Transitory {
                            Ctrl.__Filter.RemoveAt(Index - n)
                            n++
                        }
                        Ctrl.__Transitory := []
                        Ctrl.__Transitory.Capacity := Ctrl.__Arr.Length
                        loop i {
                            if !InStr(Ctrl.__Arr[A_Index], Ctrl.Text) {
                                Ctrl.__Transitory.Push(A_Index)
                            }
                        }
                        n := 0
                        for Index in Ctrl.__Transitory {
                            Ctrl.__Filter.Push(Ctrl.__Arr.RemoveAt(Index - n))
                            Ctrl.Delete(Index - n)
                            n++
                        }
                        Ctrl.__Transitory := []
                        Ctrl.__Transitory.Capacity := Ctrl.__Arr.Length
                    } else {
                        _ResetFilter(Ctrl)
                    }
                } else {
                    _ResetFilter(Ctrl)
                }
                Ctrl.__PreviousText := Ctrl.Text
                Time := A_TickCount
            }
            Ctrl.OnEvent('Change', HChangeComboBox, 1)
            Time := 0
        }
    }

    HFocusComboBox(Ctrl, *) {
        if !SendMessage(0x0157, 0, 0, Ctrl.hWnd) { ; CB_GETDROPPEDSTATE
            SendMessage(0x014F, 1, 0, Ctrl.hWnd)
        }
    }
    _ResetFilter(Ctrl) {
        Ctrl.Add(Ctrl.__Filter)
        Ctrl.__Arr.Push(Ctrl.__Filter*)
        Ctrl.__Filter := []
        Ctrl.__Filter.Capacity := Ctrl.__Arr.Length
    }
    AddEx(Ctrl, Item) {
        if Ctrl.Text && InStr(Item, Ctrl.Text) {
            Ctrl.__Arr.Push(Item)
            Ctrl.Add([Item])
        } else {
            Ctrl.__Filter.Push(Item)
        }
    }
    DeleteEx(Ctrl, Str) {
        if (Ctrl.Text && InStr(Str, Ctrl.Text)) || !Ctrl.Text {
            for Item in Ctrl.__Arr {
                if Item = Str {
                    Ctrl.__Arr.RemoveAt(A_Index)
                    Ctrl.Delete(A_Index)
                    break
                }
            }
        } else {
            for Item in Ctrl.__Filter {
                if Item = Str {
                    Ctrl.__Filter.RemoveAt(A_Index)
                    break
                }
            }
        }
    }
    _DisposeFilter() {
        for Prop in ['__Arr','__Transitory', '__Filter', '__MaxVisible', 'AddEx', 'DeleteEx'] {
            try {
                ComboBox.DeleteProp(Prop)
            }
        }
        ComboBox.OnEvent('Focus', HFocusComboBox, 0)
        ; ComboBox.OnEvent('LoseFocus', HLoseFocusComboBox, 0)
        ComboBox.OnEvent('Change', HChangeComboBox, 0)
    }
}
