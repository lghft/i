# Installing

### Games

* Download the latest **.rbxm** file from the [releases](https://github.com/depthso/Dear-ReGui/releases).&#x20;
* Drag and drop the File into your game's workspace.&#x20;
* Move the Module into a desired location, such as *ReplicatedStorage*
* You can use the library with a **LocalScript.**

### Executors

* If you face problems with obfuscation, please check you are not using any Type checks in your script as many obfuscators compile to Lua not Luau. The demo window has some type checking so please remove those
* Please use the loadstring rather than bundling with Darklua as it will not compile

{% tabs %}
{% tab title="Games" %}

<pre class="language-lua"><code class="lang-lua">local ReplicatedStorage = game:GetService("ReplicatedStorage")
<strong>local ReGui = require(ReplicatedStorage.ReGui)
</strong></code></pre>

{% endtab %}

{% tab title="Executors" %}

<pre class="language-lua"><code class="lang-lua"><strong>local ReGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua'))()
</strong></code></pre>

{% endtab %}
{% endtabs %}

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
