# ScriptParser

A class that parses AutoHotkey (AHK) code into usable data objects.

# Introduction

`ScriptParser` parses AHK code into data objects representing the following types of components:

- Classes
- Global functions
- Static methods
- Instance methods
- Static properties
- Instance properties
- Property getters
- Property setters
- Comment blocks (multiple consecutive lines of `; notation comments)
- Multi-line comments (/* */ notation comments)
- Single line comments (`; notation comments)
- JSDoc comments (/** */ notation comments)
- Strings

For example, say I have the following script:

```ahk
class MyClass {
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

MyFunc(param1, param2, params*) {

}
```

When I create the `ScriptParser` object, I will have access to data objects that provide me with
information about `MyClass`, `MyClass.Method`, `MyClass.Property`, `MyClass.Property.Get`,
`MyClass.Property.Set`, `MyClass.Prototype.__New`, `MyClass.Property` (instance property), `MyFunc`,
and the three comments. The kinds of information available are:
- Full text of the component.
- Character position details, such as start and end position, start and end line, and start and end
  character column number.
- Child components.
- For functions and methods, details about parameters.
- Comments are associated with the code directly beneath them.

Assume the above code is saved to file "MyScript.ahk"...
```ahk
#include <ScriptParser>

sp := ScriptParser({ Path: "MyScript.ahk" })
collection := sp.Collection
_myScript := collection.Class.Get("MyClass")
OutputDebug(_myScript.Text "`n") ; Prints the entire MyClass text
_myMethod := _myScript.Children.Get("StaticMethod").Get("Method")
params := _myMethod.Params
OutputDebug(params[1].Symbol "`n") ; param1
OutputDebug(params[2].DefaultValue "`n") ; "value"
OutputDebug(_myMethod.Comment.TextComment "`n") ; @param {Type} param1 - info
                                                ; @param {Type} [param2] - info
                                                ; @returns {Type}
OutputDebug(_myMethod.TextBody "`n") ; Prints the body of MyMethod (text between curly braces)
```

# Use cases

I wrote `ScriptParser` as the foundation of another tool that will build documentation for my scripts
by parsing the code and comments. That is in the works, but `ScriptParser` itself is complete and
functional.

Some other ideas might be:
- Reflective processing, code that evaluates conditions as a function of the code itself
- A tool that replaces function calls with the function code itself (to avoid the high overhead cost
  of function calls in AHK)
- Grabbing text to display in tooltips (for example, as part of a developer tool)
- Dynamic execution of code in an external process using a function like [ExecScript](https://www.autohotkey.com/docs/v2/lib/Run.htm#ExecScript)

If you make a tool that features `ScriptParser` and if you would like your tool to be hosted in the
"extensions" folder in this repository, please submit a pull request with your script added to the
folder.

If you would like to add a link to your script that features `ScriptParser` in the [Community tools](#community-tools)
section, please submit a pull request with your link added.

# Quick start

The following is a brief introduction intended to share enough information for you to make use
of this library. Run the [demo script](#demo) to visually explore the properties and items accessible
from `ScriptParser` objects.

1. Clone the repository.
  ```cmd
  git clone https://github.com/Nich-Cebolla/AutoHotkey-ScriptParser
  ```

2. Make a copy of the cloned repository and work with the copy. This is to avoid a situation where
  pulling an update breaks our scripts; by using a separate copy we can give ourselves time to review
  updates before updating the active copy.
  ```cmd
  xcopy AutoHotkey-ScriptParser AutoHotkey-ScriptParser-Active /I /E
  ```

3. Add a file ScriptParser.ahk to your [lib folder](https://www.autohotkey.com/docs/v2/Scripts.htm#lib).
  In the file is a single statement.
    ```ahk
    #include C:\path\to\AutoHotkey-ScriptParser-Active\src\VENV.ahk
    ```

4. Include the library in your script.
  ```ahk
  #include <ScriptParser>
  ```

5. Use the object
  ```ahk
  #include <ScriptParser>

  sp := ScriptParser({ Path: "MyScript.ahk" })
  ```

# Demo

The demo script launches a gui window with a tree-view control that displays the properties and items
accessible from a `ScriptParser` object. Since making use of `ScriptParser` requires accessing
deeply nested objects, I thought it would be helpful to have a visual aide to keep open while writing
code that uses the class. To use, input the path to your script in the `Demo("path")` function call,
and run the script.

## The demo gui

The root node represents the `ScriptParser` object. Expanding the node reveals the primary
properties of the object.

<img src="images\scriptparser-1-gui.png" style="width:50%;">

### The collection object

The `ScriptParser_Collection` object set to property "Collection" will be your primary entrypoint
to the class' functionality. There are 14 collections.

<img src="images\scriptparser-2-collection.png" style="width:50%;">

### Nodes

Each node represents a property, or an item returned by the enumerator. Since collection objects are
`Map` objects, we see their items as key - value pairs. The tree-view is recursive
and dynamic; nodes are generated when you expand the parent node, and all object values are expandable
(unless an object has no properties or items).

<img src="images\scriptparser-3-nodes.png" style="width:50%;">

### Component objects

Here is a look at the component object for the [UIA](https://github.com/Descolada/UIA-v2) class.

<img src="images\scriptparser-4-component.png" style="width:50%;">

### Children

If we expand the "Children" node, we can see what kinds of children `UIA` has.

<img src="images\scriptparser-5-children.png" style="width:50%;">

For example, expanding "StaticMethod" reveals a list of component objects for each static method
of the `UIA` class.

<img src="images\scriptparser-6-staticmethod.png" style="width:50%;">

### Context menu

Don't forget to check out the context menu, which has many useful actions:

<img src="images\scriptparser-7-contextmenu.png" style="width:50%;">

# Community tools

Be the first to submit a tool!

# Options

This is a list and description of the available options to pass to `ScriptParser.Prototype.__New`.

If there is a default value, the format for the option is:
- **{ Type }** [ `Options.<Name> = <default value>` ] - *description*

If there is not a default value, the format for the option is:
- **{ Type }** [ `Options.<Name>` ] - *description*

Only one of `Options.Content` or `Options.Path` need to be set. If `Options.Path` is set, `Options.Content`
is ignored.

- **{ String }** [ `Options.Content` ] - The script's code as string.
- **{ Boolean }** [ `Options.DeferProcess = false` ] - If true, `ScriptParser.Prototype.Process`
  is not called; your code must call it to begin the parsing process.
- **{ String }** [ `Options.Encoding` ] - The encoding of the file at `Options.Path`.
- **{ String }** [ `Options.EndOfLine` ] - The end of line character(s) used in the script. If unset,
  `ScriptParser` will detect the correct character(s) to use. If unset and if there are mixed line
  endings, `ScriptParser` throws an error. You can use
  `` FileAppend(RegExReplace(FileRead(path), "\R", "`n"), "temp-path.ahk") `` to standardize line endings.
- **{ ScriptParser_GetIncluded }** [ `Options.Included` ] - If you would like `ScriptParser` to recursively
  process the scripts associated with the `#include` statements in the script, set `Options.Included`
  with an instance of [ScriptParser_GetIncluded](#scriptparser_getincluded). The `ScriptParser` objects
  for each script will be accessible from a map object set to property "IncludedCollection".
- **{ String }** [ `Options.Path` ] - The path to the script.

# The ScriptParser object

The following is a list of properties and short description of the primary properties accessible from
a `ScriptParser` object.

|Property name|Type of collection|
|-|-|
|Collection|A `ScriptParser_Collection` object. Your code can access each type of collection from this property.|
|ComponentList|A map object containining every component that was parsed, in the order in which they were parsed.|
|GlobalCollection|A map object containing collection objects containing class and function component objects.|
|IncludedCollection|If `Options.Included` was set, "IncludedCollection" will be set with a map object where the key is the file path and the value is the `ScriptParser` object for each included file.|
|Length|The script's character length|
|RemovedCollection|A collection object containing collection objects containing component objects associated with strings and comments|
|Text|The script's full text|


# The "Collection" property

The main property you will work with will be "Collection", which returns a
[ScriptParser_Collection](https://github.com/Nich-Cebolla/AutoHotkey-ScriptParser/blob/main/src/ScriptParser_Collection.ahk)
object. There are 14 collections, each representing a type of component that `ScriptParser` processes.

|Property name|Type of collection|
|-|-|
|Class|Class definitions.|
|CommentBlock|Two or more consecutive lines containing only comments with semicolon ( ; ) notation and with the same level of indentation.|
|CommentMultiLine|Comments using /* */ notation.|
|CommentSingleLine|Comments using semicolon notation.|
|Function|Global function definitions. `ScriptParser` is currently unable to parse functions defined within an expression, and nested functions.|
|Getter|Property getter definitions within the body of a class property definition.|
|Included|The `ScriptParser` objects created from `#include` statements in the script. See [ScriptParser_GetIncluded](#scriptparser_getincluded).|
|InstanceMethod|Instance method definitions within the body of a class definition.|
|InstanceProperty|Instance property definitions within the body of a class definition.|
|Jsdoc|Comments using JSDoc notation ( /** */ ).|
|Setter|Property setter definitions within the body of a class property definition.|
|StaticMethod|Static method definitions within the body of a class definition.|
|StaticProperty|Static property definitions within the body of a class definition.|
|String|Quoted strings.|

# The component object

A component is a discrete part of your script. The following are properties component objects. If a
property does not have a value, it returns an empty string, so you do not need to use `HasProp` to
test for the presence of a property prior to accessing the property.

|Property name|Accessible from|Type|What the property value represents|
|-|-|-|-|
|AltName|All|**{ String }**|If multiple components have the same name, all subsequent component objects will have a number appended to the name, and "AltName" is set with the original name.|
|Arrow|Function, Getter, InstanceMethod, InstanceProperty, Setter, StaticMethod, StaticProperty|**{ Boolean }**|Returns 1 if the definition uses the arrow ( => ) operator.|
|Children|All|**{ Map }**|If the component has child components, "Children" is a collection of collection objects, and the child component objects are accessible from the collections.|
|ColEnd|All|**{ Integer }**|The column index of the last character of the component's text.|
|ColStart|All|**{ Integer }**|The column index of the first character of the component's text.|
|Comment|Class, Function, Getter, InstanceMethod, InstanceProperty, StaticMethod, StaticProperty, Setter|**{ ScriptParser_Ahk.Component }**|For component objects that are associated with a function, class, method, or property, if there is a comment immediately above the component's text, "Comment" returns the comment component object.|
|CommentParent|CommentBlock, CommentMultiLine, CommentSingleLine, Jsdoc|**{ ScriptParser_Ahk.Component }**|This is the property analagous to "Comment" above, but for the comment's object. Returns the associated function, class, method, or property component object.|
|Extends|Class|**{ String }**|Returns the string length in characters of the full text of the component.|
|Get|InstanceProperty, StaticProperty|**{ Boolean }**|Returns 1 if the property has a getter.|
|HasJsdoc|Class, Function, Getter, InstanceMethod, InstanceProperty, StaticMethod, StaticProperty, Setter|**{ Boolean }**|If there is a JSDoc comment immediately above the component, "HasJsdoc" returns 1. The "Comment" property returns the component object.|
|LenBody|Class, Function, Getter, InstanceMethod, InstanceProperty, StaticMethod, StaticProperty, Setter|**{ Integer }**|For components that have a body (code in-between curly braces or code after an arrow operator), "LenBody" returns the string length in characters of just the body.|
|Length|All|**{ Integer }**|Returns the string length in characters of the full text of the component.|
|LineEnd|All|**{ Integer }**|Returns the line number on which the component's text ends.|
|LineStart|All|**{ Integer }**|Returns the line number on which the component's text begins.|
|Match|CommentBlock, CommentMultiLine, CommentSingleLine, Jsdoc|**{ RegExMatchInfo }**|If the component is associated with a string or comment, the "Match" property returns the `RegExMatchInfo` object created when parsing. There are various subcapture groups which you can see by expanding the "Enum" node of the "Match" property node.|
|Name|All|**{ String }**|Returns the name of the component.|
|NameCollection|All|**{ String }**|Returns the name of the collection of which the component is part.|
|Params|Function, InstanceMethod, InstanceProperty, StaticMethod, StaticProperty|**{ Array }**| If the function, property, or method has parameters, "Params" returns a list of parameter objects.
|Parent|All|**{ ScriptParser_Ahk.Component }**|If the component is a child component, "Parent" returns the parent component object.|
|Path|All|**{ String }**|Returns the object path for the component.|
|Pos|All|**{ Integer }**|Returns the character position of the start of the component's text.|
|PosBody|Class, Function, Getter, InstanceMethod, InstanceProperty, StaticMethod, StaticProperty, Setter|**{ Integer }**|For components that have a body (code in-between curly braces or code after an arrow operator), "PosBody" returns returns the character position of the start of the component's text body.|
|PosEnd|All|**{ Integer }**|Returns the character position of the end of the component's text.|
|Set|InstanceProperty, StaticProperty|**{ Boolean }**|Returns 1 if the property has a setter.|
|Static|InstanceMethod, InstanceProperty, StaticMethod, StaticProperty|**{ Boolean }**|Returns 1 if the method or property has the `Static` keyword.|
|Text|All|**{ String }**|Returns the original text for the component.|
|TextBody|Class, Function, Getter, InstanceMethod, InstanceProperty, StaticMethod, StaticProperty, Setter|**{ String }**|For components that have a body (code in-between curly braces or code after an arrow operator), "TextBody" returns returns the text between the curly braces.|
|TextComment|CommentBlock, CommentMultiLine, CommentSingleLine, Jsdoc|**{ String }**|If the component object is associated with a commment, "TextComment" returns the comment's original text with the comment operators and any leading indentation removed. Each individual line of the comment is separated by crlf.|
|TextOwn|Class, Function, Getter, InstanceMethod, InstanceProperty, StaticMethod, StaticProperty, Setter|**{ String }**|If the component has children, "TextOwn" returns only the text that is directly associated with the component; child text is removed.|

# Parameters

Regarding class methods, dynamic properties, and global functions, `ScriptParser`
creates an object for each parameter. Parameter objects have the following properties:

|Property name|What the property value represents|
|-|-|
|Default|Returns 1 if there is a default value.|
|DefaultValue|If "Default" is 1, returns the default value text.|
|Optional|Returns 1 if the parameter has the ? operator or a default value.|
|Symbol|Returns the symbol of the parameter.|
|Variadic|Returns 1 if the paremeter has the * operator.|
|VarRef|Returns 1 if the parameter has the & operator.|

# Dynamic properties

In addition to the properties common to all component objects, dynamic properties
will have one or both of "Getter" and "Setter" children. If the dynamic property
has a getter and/or setter, the "Get" and/or "Set" property will return 1,
respectively. The getter or setter component objects are accessible from
the "Children" property.

# Strings

All quoted strings are removed from the text before parsing, and they are replaced by replacement
identifiers. When you access a "Text" property, the identifiers are swapped with the actual text,
so the original text is returned.

The string component objects will all have a property "Match" which returns
the `RegExMatchInfo` object produced when the string was parsed.
The "string" item of the match object returns the text without external quotation
characters.

# Comments

Comments are divided into four types, "CommentBlock", "CommentMultiLine",
"CommentSingleLine", and "Jsdoc". When the comment is parsed, the next line
underneath the comment is included in the match. `ScriptParser` uses this to
associate the comment with what is underneath it. If the line underneath it is
associated with a component object, and if the component is a function, method, property, or class,
the comment object will have a property "CommentParent" which will return the object for the line
underneath the comment, and the object for the line underneath the comment will have a property
"Comment" which will return the comment object. If the comment is a JSDoc comment, the object for
the line underneath the comment will also have a property "HasJsdoc" with a value of 1.

# ScriptParser_GetIncluded

Reads a file and identifies each #include or #IncludeAgain statement. Resolves the path to
each included file. This is adapted from
[GetIncludedFile.ahk](https://github.com/Nich-Cebolla/AutoHotkey-LibV2/blob/main/GetIncludedFile.ahk).

Assign an instance of `ScriptParser_GetIncluded` to `Options.Included`, and `ScriptParser` will
recursively process each #included script. The `ScriptParser` objects are accessible from the
"IncludedCollection" property of the `ScriptParser` object, (e.g. `ScriptParserObj.IncludedCollection`),
or the "Included" property of the `ScriptParser_Collection` object (e.g. `ScriptParser_CollectionObj.Included`).

## Parameters

- **{ String }** `Path` - The path to the file to analyze. If a relative path is provided, it
  is assumed to be relative to the current working directory.
- **{ Boolean }** [ `Recursive = true` ] - If true, recursively processes all included files.
  If a file is encountered more than once, a `ScriptParser_GetIncluded.File` object is generated
  for that encounter but the file does not get processed again.
- **{ String }**  [ `ScriptDir = ""` ] - The path to the local library as described in the
  [documentation](https://www.autohotkey.com/docs/v2/Scripts.htm#lib). This would be
  the equivalent of `A_ScriptDir "\lib"` when the script is actually running. Since this function
  is likely to be used outside of the script's context, the local library must be provided if it
  is to be included in the search.
- **{ String }**  [ `AhkExeDir = ""` ] - The path to the standard library as described in the
  [documentation](https://www.autohotkey.com/docs/v2/Scripts.htm#lib). This would be the
  equivalent of `A_AhkPath "\lib"` when the script is actually running. Since this function is
  likely to be used outside of the script's context, the standard library must be provided if it
  is to be included in the search.
- **{ String }**  [ `Encoding` ] - The file encoding to use when reading the files.

# Changelog

- **2025-12-08** v1.0.0
  - Released v1.0.0.
