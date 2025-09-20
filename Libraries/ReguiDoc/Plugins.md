# Creating windows

Following the steps in the [Installing page](https://depso.gitbook.io/regui/getting-started/installing), once you have installed ReGui, you can begin to create your first window!

By default, ReGui parents windows into `ReGui.Container.Windows` . The container parent is automatically tested. For example if ReGui had CoreGui permissions, the container would be parented to the **CoreGUI.**&#x20;

If you would like to speicifcally parent the Container, define `ContainerParent` with the Parent in the ReGui:Init call

{% tabs %}
{% tab title="Window" %}

```lua
local Window = ReGui:Window({
	Title = "Hello world!",
	Size = UDim2.fromOffset(300, 200)
}) --> Canvas & WindowClass

Window:Label({Text="Hello, world!"})
Window:Button({
	Text = "Save",
	Callback = function()
		MySaveFunction()
	end,
})
Window:InputText({Label="string"})
Window:SliderFloat({Label = "float", Minimum = 0.0, Maximum = 1.0})
```

{% endtab %}

{% tab title="Window with tabs" %}

```lua
local Window = ReGui:TabsWindow({
	Title = "Tabs window demo!",
	Size = UDim2.fromOffset(300, 200)
}) --> TabSelector & WindowClass

local Names = {"Avocado", "Broccoli", "Cucumber"}

for _, Name in next, Names do
	--// Create tab
	local Tab = Window:CreateTab({Name=Name}) --> Canvas
	Tab:Label({
		Text = `This is the {Name} tab!`
	})
end
```

{% endtab %}
{% endtabs %}

<table data-view="cards"><thead><tr><th></th><th data-hidden data-card-cover data-type="files"></th></tr></thead><tbody><tr><td>TabsWindow</td><td><a href="https://1061433021-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FbNfMkmxWyR6N5SCXKR8U%2Fuploads%2Ft0uw6jVugaHkCDhAfRr0%2F%7B2903FCC8-41EC-43E3-AAE4-C7CA4753B22B%7D.png?alt=media&#x26;token=f07fe4e8-352f-4b92-9ec4-11020191b0df">{2903FCC8-41EC-43E3-AAE4-C7CA4753B22B}.png</a></td></tr><tr><td>Window</td><td><a href="https://1061433021-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FbNfMkmxWyR6N5SCXKR8U%2Fuploads%2FbIFBUVnlmfVHQiTh2gUi%2Fimage.png?alt=media&#x26;token=c3db8bb1-8e1d-473c-9f44-f23fc5f60abc">image.png</a></td></tr></tbody></table>

# Custom elements

### DefineElement

```lua
-- This will be defined in the Elements class accessible by a Canvas
-- Or by ReGui.Elements:ElementName() but this method will not have theming
ReGui:DefineElement("ElementName", {
	-- These are the base values for the Config
	Base = {
		RichText = true,
		TextWrapped = true
	},
	--(OPTIONAL) This is the coloring infomation the theme system will use
	ColorData = {
		["ColorStyle Name"] = {
			TextColor3 = "ErrorText",
			FontFace = "TextFont",
		},
	},
	--(OPTIONAL) These values will be set in the base theme
	ThemeTags = {
		["ThemeTag"] = Color3.fromRGB(255, 69, 69),
		["CoolFont"] = Font.fromName("Ubuntu"),
	},
	--[[ This is the generation function for the element
	 self is the canvas class
	 Config is the configuration with overwrites to the Base config
	]]--
	Create = function(self, Config: Label)
		-- This MUST either return:
		  -- GuiObject
		  -- Class, GuiObject
	end,
})
```

### Basic TextLabel example:

<pre class="language-lua"><code class="lang-lua"><strong>ReGui:DefineElement("PurpleText", { --// Method name
</strong>	Base = { --// Configuration base
		IsBigText = true
	},
	Create = function(self, Config)
		local IsBigText = Config.IsBigText -- true
		
		local Label = Instance.new("TextLabel")
		Label.TextSize = IsBigText and 30 or 14

		--// Must return: Instance or Table, Instance
		return Label
	end,
})
</code></pre>

### Using other elements as a base:

This is the code used for generating the **ProgressBar** element using the **Slider** element as a base

```lua
ReGui:DefineElement("ProgressBar", {
	Base = {
		Progress = true,
		ReadOnly = true,
		MinValue = 0,
		MaxValue = 100,
		Format = "% i%%"
	},
	Create = function(self, Config)
		function Config:SetPercentage(Value: number)
			Config:SetValue(Value)
		end

		return self:SliderBase(Config)
	end,
})
```

# Custom flags

When ReGui generates an element such as a Label from invoking Canvas:Label, it will check if the flag is a property or a global flag. If it is a global flag it will call the defined function but if it's a property such as `Size` it will be set as a property to the element as it is not a global flag

Examples of some built-in flags are: `Icon`, `Border`, and `Ratio`

```typescript
type Data = {
	Object: Instance,
	Class: table,
	WindowClass: table? --// May not exist in some cases
}
```

### Basic flag example for visibility:

```lua
ReGui:DefineGlobalFlag({
	Properties = {"Hidden"}, --// These are trigger strings in the element flags
	Callback = function(Data, Object, Value)
		Object.Visible = not Value
	end
})
```

# Custom themes

Themes use the `DarkTheme` configuration as the base and any defined theme will act as overwrites to this configuration

### Accents

ReGui comes with built-in accent colors that can be used for coloring. As seen in the source [here](https://github.com/depthso/Dear-ReGui/blob/1a0fb5a32aaf991c9061f8f12b980e3eb30a3c9a/ReGui.lua#L43)

```lua
ReGui.Accent = {
	--// ReGui acent colors
	Light = Color3.fromRGB(60, 150, 250),
	Dark = Color3.fromRGB(29, 66, 115),
	White = Color3.fromRGB(240, 240, 240),
	Gray = Color3.fromRGB(127, 126, 129),
	Black = Color3.fromRGB(15, 19, 24),
	Yellow = Color3.fromRGB(217, 180, 62),
	Orange = Color3.fromRGB(234, 157, 57),
	Green = Color3.fromRGB(130, 188, 91),
	Red = Color3.fromRGB(255, 69, 69),
```

***

### Creating a theme

For this example, we'll create a basic pink theme

#### View the full theme configuration here:

{% @github-files/github-code-block url="<https://github.com/depthso/Dear-ReGui/blob/e8e4105de400edeaae45c5b00edd49150b23c594/ReGui.lua#L162C3-L226C39>" %}

```lua
ReGui:DefineTheme("Pink Theme", {
	Text = Color3.fromRGB(200, 180, 200),
	WindowBg = Color3.fromRGB(35, 30, 35),
	TitleBarBg = Color3.fromRGB(35, 30, 35),
	TitleBarBgActive = Color3.fromRGB(50, 45, 50),
	Border = Color3.fromRGB(50, 45, 50),
	ResizeGrab = Color3.fromRGB(50, 45, 50),
})
```

### Usage in a Window

Now to use the theme we have just created, set the `Theme`flag to the name of the theme we have created - `RedTheme`

```lua
local Window = ReGui:Window({
	Title = "My theme demo",
	Theme = "Pink Theme",
	Size = UDim2.fromOffset(300, 200)
})

Window:Label({
	Text = "Hello, world!"
})
```

