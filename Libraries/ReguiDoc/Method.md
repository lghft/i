# ReGui functions

**ReGui:SetWindowFocusesEnabled(Enabled: boolean)**

* Determines whether Window focuses should update

**ReGui:GetFocusedWindow(): WindowClass?**

* Returns the Window with an active focus

**ReGui:SetFocusedWindow(WindowClass: table?)**

* Sets the currently focused window

**ReGui:WindowCanFocus(WindowClass: table): boolean**

* Checks if the Window can be brought into focus

**ReGui:GetDictSize(Dict: table): number**

* Returns the number of items in a dict

**ReGui:GetAnimationData(Object: GuiObject): table**

* Returns the connected animaion data to the Object

**ReGui:SetAnimationsEnabled(Enabled: boolean)**

* Globally set whether animations are enabled&#x20;

**ReGui:SetAnimation(Object: GuiObject, Reference: (string|table), Listener: GuiObject?)**

* Set the animation for the Object from the Reference argument
* Reference is looked up in the ReGui.Animations dict
* If a Listener is provided, it will listen to events like MouseHover otherwise it will use the Object

**ReGui:GetChildOfClass(Object: GuiObject, ClassName: string): GuiObject**

* Returns a child instance with a matching ClassName otherwise it will create one

**ReGui:StackWindows()**

* Position Windows in a cascade

**ReGui:MergeMetatables(First, Second)**

* Merge two metatables together
* This also accounts for setting values (\_\_newindex)

**ReGui:GetElementFlags(Object: GuiObject): table?**

* Returns the flags connected with the Object
* Internally, Object is the raw element object

**ReGui:IsMouseEvent(Input: InputObject, IgnoreMovement: boolean)**

* Checks if the passed InputObject is a mouse event

**ReGui:SetItemTooltip(Parent: GuiObject, Render: (Elements) -> ...any)**

* Set the tooltip for an object.
* Render will be called with the tooltip canvas

**ReGui:GetMouseLocation(): (number, number)**

* Returns an X and Y number for the location of the mouse

**ReGui:GetThemeKey(Theme: (string|table), Key: string)**

* Looks up the theme and retrieves the key value

**ReGui:CheckConfig(Source: table, Base: table, Call: boolean?, IgnoreKeys: table?)**

* Compares the values in Source to the values in Base and adds the missing keys/values from Base if they are nil or missing
* If Call is true, Base values should be functions used when Source is missing the key or value as they will be called to return the value

**ReGui:GetScreenSize(): Vector2**

* Returns a Vector2 of the ViewportSize&#x20;

**ReGui:IsConsoleDevice(): boolean**

* Checks if there is a GamePad connected

**ReGui:IsMobileDevice(): boolean**

* Checks if there is a touchscreen

**ReGui:GetVersion(): string**

* Returns the ReGui version number string

**ReGui:IsDoubleClick(TickRange: number): boolean**

* Checks if the range should be considered a double click

**ReGui:Warn(...)**

* Prints a concatinated warn message from passed arguments

**ReGui:Concat(Table, Separator: " ")**

* An improved table.concat function

**ReGui:SetProperties(Object: Instance, Properties: table)**

* Apply properties from a dictionary and without producing errors if they cannot be applied

**ReGui:ApplyFlags(**{
\
&#x20; Object: Instance,
\
&#x20; Class: table,
\
&#x20; WindowClass: table?
\
**})**

* Like :**SetProperties**, this function checks **ReGui.Flags** for a function connected to that property key. Custom flags are [documented here](https://depso.gitbook.io/regui/plugins/custom-flags)
* Class is the properties table

**ReGui:InsertPrefab(Name: string, Properties): GuiObject**

* Returns a copy of an object from the prefabs folder that matches the name


# Canvas functions

<table><thead><tr><th width="284.5">Function</th><th width="131">Return type</th><th>Description</th></tr></thead><tbody><tr><td>:ClearChildElements</td><td></td><td>Destroys all child elements</td></tr><tr><td>:GetChildElements</td><td>Array (table)</td><td>Returns an array of elements in the Canvas</td></tr><tr><td>:GetObject</td><td>Instance</td><td>Returns the real Object</td></tr><tr><td>:TagElements(Objects: ObjectTable)</td><td></td><td>Same as Window:TagElements</td></tr><tr><td>:SetElementFocused(Object: GuiObject, Data)</td><td></td><td>Disables interaction with all other elements when the object is focused</td></tr><tr><td>:Remove</td><td></td><td>Destroys the Canvas and all child elements</td></tr></tbody></table>


# Configuration saving

ReGui does not have a built-in file system interface. Therefore, you will need to create your own to handle the Ini service. Enabling JsonEncode will return a string which should be used for the save file content

**ReGui:DumpIni(JsonEncode: boolean?): (table|string)**

* Returns the table or json string of the Ini settings

**ReGui:LoadIni(NewSettings: (table|string), JsonEncoded: boolean?)**

* Loads the Ini into the Elements

**ReGui:AddIniFlag(Flag: string, Element)**

* Manually declare an Element for a IniFlag
* This is done automatically when an Element is created if the flags contain **IniFlag**

**ReGui:LoadIniIntoElement(Element, Values: table)**

* Loads the values from the Value table into the Element
* This function is used by :**LoadIni**
* Passed values will be checked in the ValueFunctions dict to check whether it should invoke a function, e.g :SetValue is required for Value
