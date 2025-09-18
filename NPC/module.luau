local G2L = {};
local core

if game:FindFirstChildOfClass("CoreGui") then
	if gethui then
		core = gethui()
	else
		core = game:GetService("CoreGui")
	end
else
	core = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

-- StarterGui.ScreenGui
G2L["1"] = Instance.new("ScreenGui", core);
G2L["1"]["IgnoreGuiInset"] = true;
G2L["1"]["DisplayOrder"] = 5;
G2L["1"]["ScreenInsets"] = Enum.ScreenInsets.None;
G2L["1"]["ClipToDeviceSafeArea"] = false;
G2L["1"]["ResetOnSpawn"] = false;


-- StarterGui.ScreenGui.Frame
G2L["2"] = Instance.new("Frame", G2L["1"]);
G2L["2"]["BorderSizePixel"] = 0;
G2L["2"]["BackgroundColor3"] = Color3.fromRGB(43, 43, 43);
G2L["2"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
G2L["2"]["Size"] = UDim2.new(0.59473, 0, 0.65244, 0);
G2L["2"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
G2L["2"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);


-- StarterGui.ScreenGui.Frame.UICorner
G2L["3"] = Instance.new("UICorner", G2L["2"]);
G2L["3"]["CornerRadius"] = UDim.new(0.03, 0);


-- StarterGui.ScreenGui.Frame.bar
G2L["4"] = Instance.new("Frame", G2L["2"]);
G2L["4"]["BorderSizePixel"] = 0;
G2L["4"]["BackgroundColor3"] = Color3.fromRGB(76, 76, 76);
G2L["4"]["Size"] = UDim2.new(0.91561, 0, 0.07477, 0);
G2L["4"]["Position"] = UDim2.new(0.01, 0, 0.019, 0);
G2L["4"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["4"]["Name"] = [[bar]];


-- StarterGui.ScreenGui.Frame.bar.UICorner
G2L["5"] = Instance.new("UICorner", G2L["4"]);
G2L["5"]["CornerRadius"] = UDim.new(0.25, 0);


-- StarterGui.ScreenGui.Frame.bar.icon
G2L["6"] = Instance.new("ImageLabel", G2L["4"]);
G2L["6"]["BorderSizePixel"] = 0;
G2L["6"]["ScaleType"] = Enum.ScaleType.Fit;
G2L["6"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["6"]["Image"] = [[rbxassetid://96581271712752]];
G2L["6"]["Size"] = UDim2.new(0.05581, 0, 1, 0);
G2L["6"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["6"]["BackgroundTransparency"] = 1;
G2L["6"]["Name"] = [[icon]];


-- StarterGui.ScreenGui.Frame.bar.TextLabel
G2L["7"] = Instance.new("TextLabel", G2L["4"]);
G2L["7"]["BorderSizePixel"] = 0;
G2L["7"]["TextSize"] = 18;
G2L["7"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["7"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["7"]["FontFace"] = Font.new([[rbxasset://fonts/families/Roboto.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["7"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
G2L["7"]["BackgroundTransparency"] = 1;
G2L["7"]["RichText"] = true;
G2L["7"]["Size"] = UDim2.new(0.91475, 0, 1, 0);
G2L["7"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["7"]["Text"] = [[<b>npc panel |  @Im_Patrick Youtube</b>]];
G2L["7"]["Position"] = UDim2.new(0.07674, 0, 0, 0);


-- StarterGui.ScreenGui.Frame.main
G2L["8"] = Instance.new("Frame", G2L["2"]);
G2L["8"]["BorderSizePixel"] = 0;
G2L["8"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["8"]["ClipsDescendants"] = true;
G2L["8"]["Size"] = UDim2.new(0.42982, 0, 0.85358, 0);
G2L["8"]["Position"] = UDim2.new(0.56118, 0, 0.12461, 0);
G2L["8"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["8"]["Name"] = [[main]];


-- StarterGui.ScreenGui.Frame.main.UICorner
G2L["9"] = Instance.new("UICorner", G2L["8"]);
G2L["9"]["CornerRadius"] = UDim.new(0.03, 0);


-- StarterGui.ScreenGui.Frame.main.UIGradient
G2L["a"] = Instance.new("UIGradient", G2L["8"]);
G2L["a"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(51, 51, 51)),ColorSequenceKeypoint.new(0.407, Color3.fromRGB(68, 68, 68)),ColorSequenceKeypoint.new(0.564, Color3.fromRGB(73, 73, 73)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(51, 51, 51))};


-- StarterGui.ScreenGui.Frame.main.TextLabel
G2L["b"] = Instance.new("TextLabel", G2L["8"]);
G2L["b"]["TextWrapped"] = true;
G2L["b"]["BorderSizePixel"] = 0;
G2L["b"]["TextSize"] = 14;
G2L["b"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["b"]["TextScaled"] = true;
G2L["b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["b"]["FontFace"] = Font.new([[rbxasset://fonts/families/JosefinSans.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["b"]["TextColor3"] = Color3.fromRGB(223, 223, 223);
G2L["b"]["BackgroundTransparency"] = 1;
G2L["b"]["Size"] = UDim2.new(0.2945, 0, 0.05474, 0);
G2L["b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["b"]["Text"] = [[main]];
G2L["b"]["Position"] = UDim2.new(0.03927, 0, 0.02555, 0);


-- StarterGui.ScreenGui.Frame.main.TextLabel.UITextSizeConstraint
G2L["c"] = Instance.new("UITextSizeConstraint", G2L["b"]);
G2L["c"]["MaxTextSize"] = 14;


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame
G2L["d"] = Instance.new("ScrollingFrame", G2L["8"]);
G2L["d"]["Active"] = true;
G2L["d"]["ScrollingDirection"] = Enum.ScrollingDirection.Y;
G2L["d"]["BorderSizePixel"] = 0;
G2L["d"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["d"]["AutomaticCanvasSize"] = Enum.AutomaticSize.Y;
G2L["d"]["Size"] = UDim2.new(0.92768, 0, 0.87591, 0);
G2L["d"]["ScrollBarImageColor3"] = Color3.fromRGB(0, 0, 0);
G2L["d"]["Position"] = UDim2.new(0.03436, 0, 0.09124, 0);
G2L["d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["d"]["ScrollBarThickness"] = 0;
G2L["d"]["BackgroundTransparency"] = 1;


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.UIListLayout
G2L["e"] = Instance.new("UIListLayout", G2L["d"]);
G2L["e"]["Padding"] = UDim.new(0.02, 0);
G2L["e"]["SortOrder"] = Enum.SortOrder.LayoutOrder;


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.button
G2L["f"] = Instance.new("Frame", G2L["d"]);
G2L["f"]["BorderSizePixel"] = 0;
G2L["f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["f"]["Size"] = UDim2.new(1, 0, 0.2645, 0);
G2L["f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["f"]["Name"] = [[button]];


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.button.UIGradient
G2L["10"] = Instance.new("UIGradient", G2L["f"]);
G2L["10"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(36, 36, 36)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(32, 32, 32))};


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.button.UICorner
G2L["11"] = Instance.new("UICorner", G2L["f"]);
G2L["11"]["CornerRadius"] = UDim.new(0.08, 0);


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.button.title
G2L["12"] = Instance.new("TextLabel", G2L["f"]);
G2L["12"]["TextWrapped"] = true;
G2L["12"]["BorderSizePixel"] = 0;
G2L["12"]["TextSize"] = 12;
G2L["12"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["12"]["TextScaled"] = true;
G2L["12"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["12"]["FontFace"] = Font.new([[rbxasset://fonts/families/RobotoCondensed.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
G2L["12"]["TextColor3"] = Color3.fromRGB(255, 220, 213);
G2L["12"]["BackgroundTransparency"] = 1;
G2L["12"]["RichText"] = true;
G2L["12"]["Size"] = UDim2.new(0.74074, 0, 0.23334, 0);
G2L["12"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["12"]["Text"] = [[title]];
G2L["12"]["Name"] = [[title]];
G2L["12"]["Position"] = UDim2.new(0.042, 0, 0.05, 0);


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.button.title.UITextSizeConstraint
G2L["13"] = Instance.new("UITextSizeConstraint", G2L["12"]);
G2L["13"]["MaxTextSize"] = 12;


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.button.des
G2L["14"] = Instance.new("TextLabel", G2L["f"]);
G2L["14"]["TextWrapped"] = true;
G2L["14"]["BorderSizePixel"] = 0;
G2L["14"]["TextSize"] = 12;
G2L["14"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["14"]["TextTransparency"] = 0.23;
G2L["14"]["TextYAlignment"] = Enum.TextYAlignment.Top;
G2L["14"]["TextScaled"] = true;
G2L["14"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["14"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["14"]["TextColor3"] = Color3.fromRGB(210, 210, 210);
G2L["14"]["BackgroundTransparency"] = 1;
G2L["14"]["RichText"] = true;
G2L["14"]["Size"] = UDim2.new(0.74074, 0, 0.57437, 0);
G2L["14"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["14"]["Text"] = [[description is like this so yeah this is right hmm right]];
G2L["14"]["Name"] = [[des]];
G2L["14"]["Position"] = UDim2.new(0.04233, 0, 0.28334, 0);


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.button.des.UITextSizeConstraint
G2L["15"] = Instance.new("UITextSizeConstraint", G2L["14"]);
G2L["15"]["MaxTextSize"] = 12;


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.button.click
G2L["16"] = Instance.new("ImageButton", G2L["f"]);
G2L["16"]["BorderSizePixel"] = 0;
G2L["16"]["ImageTransparency"] = 1;
G2L["16"]["BackgroundTransparency"] = 1;
-- [ERROR] cannot convert ImageContent, please report to "https://github.com/uniquadev/GuiToLuaConverter/issues"
G2L["16"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["16"]["Image"] = [[rbxasset://textures/ui/GuiImagePlaceholder.png]];
G2L["16"]["Size"] = UDim2.new(1, 0, 0.99244, 0);
G2L["16"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["16"]["Name"] = [[click]];


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.button.UIStroke
G2L["17"] = Instance.new("UIStroke", G2L["f"]);
G2L["17"]["Thickness"] = 0;
G2L["17"]["Color"] = Color3.fromRGB(255, 255, 255);


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.toggle
G2L["18"] = Instance.new("Frame", G2L["d"]);
G2L["18"]["BorderSizePixel"] = 0;
G2L["18"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["18"]["Size"] = UDim2.new(1, 0, 0.2645, 0);
G2L["18"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["18"]["Name"] = [[toggle]];


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.toggle.UIGradient
G2L["19"] = Instance.new("UIGradient", G2L["18"]);
G2L["19"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(36, 36, 36)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(32, 32, 32))};


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.toggle.UICorner
G2L["1a"] = Instance.new("UICorner", G2L["18"]);
G2L["1a"]["CornerRadius"] = UDim.new(0.08, 0);


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.toggle.title
G2L["1b"] = Instance.new("TextLabel", G2L["18"]);
G2L["1b"]["TextWrapped"] = true;
G2L["1b"]["BorderSizePixel"] = 0;
G2L["1b"]["TextSize"] = 12;
G2L["1b"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["1b"]["TextScaled"] = true;
G2L["1b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["1b"]["FontFace"] = Font.new([[rbxasset://fonts/families/RobotoCondensed.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
G2L["1b"]["TextColor3"] = Color3.fromRGB(255, 220, 213);
G2L["1b"]["BackgroundTransparency"] = 1;
G2L["1b"]["RichText"] = true;
G2L["1b"]["Size"] = UDim2.new(0.74074, 0, 0.23334, 0);
G2L["1b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["1b"]["Text"] = [[title]];
G2L["1b"]["Name"] = [[title]];
G2L["1b"]["Position"] = UDim2.new(0.042, 0, 0.05, 0);


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.toggle.title.UITextSizeConstraint
G2L["1c"] = Instance.new("UITextSizeConstraint", G2L["1b"]);
G2L["1c"]["MaxTextSize"] = 12;


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.toggle.des
G2L["1d"] = Instance.new("TextLabel", G2L["18"]);
G2L["1d"]["TextWrapped"] = true;
G2L["1d"]["BorderSizePixel"] = 0;
G2L["1d"]["TextSize"] = 12;
G2L["1d"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["1d"]["TextTransparency"] = 0.23;
G2L["1d"]["TextYAlignment"] = Enum.TextYAlignment.Top;
G2L["1d"]["TextScaled"] = true;
G2L["1d"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["1d"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["1d"]["TextColor3"] = Color3.fromRGB(210, 210, 210);
G2L["1d"]["BackgroundTransparency"] = 1;
G2L["1d"]["RichText"] = true;
G2L["1d"]["Size"] = UDim2.new(0.74074, 0, 0.57437, 0);
G2L["1d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["1d"]["Text"] = [[description is like this so yeah this is right hmm right]];
G2L["1d"]["Name"] = [[des]];
G2L["1d"]["Position"] = UDim2.new(0.04233, 0, 0.28334, 0);


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.toggle.des.UITextSizeConstraint
G2L["1e"] = Instance.new("UITextSizeConstraint", G2L["1d"]);
G2L["1e"]["MaxTextSize"] = 12;


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.toggle.toggle
G2L["1f"] = Instance.new("Frame", G2L["18"]);
G2L["1f"]["BorderSizePixel"] = 0;
G2L["1f"]["BackgroundColor3"] = Color3.fromRGB(189, 0, 0);
G2L["1f"]["Size"] = UDim2.new(0.13228, 0, 0.39382, 0);
G2L["1f"]["Position"] = UDim2.new(0.8254, 0, 0.2678, 0);
G2L["1f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["1f"]["Name"] = [[toggle]];


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.toggle.toggle.UICorner
G2L["20"] = Instance.new("UICorner", G2L["1f"]);
G2L["20"]["CornerRadius"] = UDim.new(0.2, 0);


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.toggle.click
G2L["21"] = Instance.new("ImageButton", G2L["18"]);
G2L["21"]["BorderSizePixel"] = 0;
G2L["21"]["ImageTransparency"] = 1;
G2L["21"]["BackgroundTransparency"] = 1;
-- [ERROR] cannot convert ImageContent, please report to "https://github.com/uniquadev/GuiToLuaConverter/issues"
G2L["21"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["21"]["ZIndex"] = 2;
G2L["21"]["Image"] = [[rbxasset://textures/ui/GuiImagePlaceholder.png]];
G2L["21"]["Size"] = UDim2.new(1, 0, 0.99244, 0);
G2L["21"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["21"]["Name"] = [[click]];


-- StarterGui.ScreenGui.Frame.main.ScrollingFrame.toggle.UIStroke
G2L["22"] = Instance.new("UIStroke", G2L["18"]);
G2L["22"]["Thickness"] = 0;
G2L["22"]["Color"] = Color3.fromRGB(255, 255, 255);


-- StarterGui.ScreenGui.Frame.main.shading
G2L["23"] = Instance.new("ImageLabel", G2L["8"]);
G2L["23"]["ZIndex"] = 3;
G2L["23"]["BorderSizePixel"] = 0;
G2L["23"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["23"]["ImageTransparency"] = 0.26;
-- [ERROR] cannot convert ImageContent, please report to "https://github.com/uniquadev/GuiToLuaConverter/issues"
G2L["23"]["ImageColor3"] = Color3.fromRGB(41, 41, 41);
G2L["23"]["Image"] = [[rbxassetid://4654143143]];
G2L["23"]["Size"] = UDim2.new(2.14495, 0, 1.51095, 0);
G2L["23"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["23"]["BackgroundTransparency"] = 1;
G2L["23"]["Name"] = [[shading]];
G2L["23"]["Position"] = UDim2.new(-0.60973, 0, 0.50717, 0);


-- StarterGui.ScreenGui.Frame.extra
G2L["24"] = Instance.new("Frame", G2L["2"]);
G2L["24"]["BorderSizePixel"] = 0;
G2L["24"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["24"]["ClipsDescendants"] = true;
G2L["24"]["Size"] = UDim2.new(0.53586, 0, 0.46417, 0);
G2L["24"]["Position"] = UDim2.new(0.00844, 0, 0.51402, 0);
G2L["24"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["24"]["Name"] = [[extra]];


-- StarterGui.ScreenGui.Frame.extra.UICorner
G2L["25"] = Instance.new("UICorner", G2L["24"]);
G2L["25"]["CornerRadius"] = UDim.new(0.03, 0);


-- StarterGui.ScreenGui.Frame.extra.TextLabel
G2L["26"] = Instance.new("TextLabel", G2L["24"]);
G2L["26"]["TextWrapped"] = true;
G2L["26"]["BorderSizePixel"] = 0;
G2L["26"]["TextSize"] = 14;
G2L["26"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["26"]["TextScaled"] = true;
G2L["26"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["26"]["FontFace"] = Font.new([[rbxasset://fonts/families/JosefinSans.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["26"]["TextColor3"] = Color3.fromRGB(223, 223, 223);
G2L["26"]["BackgroundTransparency"] = 1;
G2L["26"]["Size"] = UDim2.new(0.2945, 0, 0.06817, 0);
G2L["26"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["26"]["Text"] = [[extra]];
G2L["26"]["Position"] = UDim2.new(0.03927, 0, 0.02555, 0);


-- StarterGui.ScreenGui.Frame.extra.TextLabel.UITextSizeConstraint
G2L["27"] = Instance.new("UITextSizeConstraint", G2L["26"]);
G2L["27"]["MaxTextSize"] = 14;


-- StarterGui.ScreenGui.Frame.extra.ScrollingFrame
G2L["28"] = Instance.new("ScrollingFrame", G2L["24"]);
G2L["28"]["Active"] = true;
G2L["28"]["ScrollingDirection"] = Enum.ScrollingDirection.X;
G2L["28"]["BorderSizePixel"] = 0;
G2L["28"]["CanvasSize"] = UDim2.new(2, 0, 0, 0);
G2L["28"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["28"]["AutomaticCanvasSize"] = Enum.AutomaticSize.X;
G2L["28"]["Size"] = UDim2.new(0.95669, 0, 0.80537, 0);
G2L["28"]["ScrollBarImageColor3"] = Color3.fromRGB(0, 0, 0);
G2L["28"]["Position"] = UDim2.new(0.01575, 0, 0.14765, 0);
G2L["28"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["28"]["ScrollBarThickness"] = 0;
G2L["28"]["BackgroundTransparency"] = 1;


-- StarterGui.ScreenGui.Frame.extra.ScrollingFrame.button
G2L["29"] = Instance.new("Frame", G2L["28"]);
G2L["29"]["BorderSizePixel"] = 0;
G2L["29"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["29"]["Size"] = UDim2.new(0.5, 0, 1, 0);
G2L["29"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["29"]["Name"] = [[button]];


-- StarterGui.ScreenGui.Frame.extra.ScrollingFrame.button.UIGradient
G2L["2a"] = Instance.new("UIGradient", G2L["29"]);
G2L["2a"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(36, 36, 36)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(25, 25, 25))};


-- StarterGui.ScreenGui.Frame.extra.ScrollingFrame.button.UICorner
G2L["2b"] = Instance.new("UICorner", G2L["29"]);
G2L["2b"]["CornerRadius"] = UDim.new(0.05, 0);


-- StarterGui.ScreenGui.Frame.extra.ScrollingFrame.button.TextLabel
G2L["2c"] = Instance.new("TextLabel", G2L["29"]);
G2L["2c"]["TextWrapped"] = true;
G2L["2c"]["BorderSizePixel"] = 0;
G2L["2c"]["TextSize"] = 14;
G2L["2c"]["TextStrokeColor3"] = Color3.fromRGB(206, 254, 255);
G2L["2c"]["TextScaled"] = true;
G2L["2c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["2c"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
G2L["2c"]["TextColor3"] = Color3.fromRGB(206, 254, 255);
G2L["2c"]["BackgroundTransparency"] = 1;
G2L["2c"]["Size"] = UDim2.new(0.996, 0, 0.11183, 0);
G2L["2c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["2c"]["Text"] = [[title]];
G2L["2c"]["Position"] = UDim2.new(0, 0, 0.02317, 0);


-- StarterGui.ScreenGui.Frame.extra.ScrollingFrame.button.TextLabel.UITextSizeConstraint
G2L["2d"] = Instance.new("UITextSizeConstraint", G2L["2c"]);
G2L["2d"]["MaxTextSize"] = 14;


-- StarterGui.ScreenGui.Frame.extra.ScrollingFrame.button.Frame
G2L["2e"] = Instance.new("Frame", G2L["29"]);
G2L["2e"]["BorderSizePixel"] = 0;
G2L["2e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["2e"]["Size"] = UDim2.new(0.89712, 0, 0.80833, 0);
G2L["2e"]["Position"] = UDim2.new(0.04938, 0, 0.13333, 0);
G2L["2e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);


-- StarterGui.ScreenGui.Frame.extra.ScrollingFrame.button.Frame.UICorner
G2L["2f"] = Instance.new("UICorner", G2L["2e"]);
G2L["2f"]["CornerRadius"] = UDim.new(0.05, 0);


-- StarterGui.ScreenGui.Frame.extra.ScrollingFrame.button.Frame.UIGradient
G2L["30"] = Instance.new("UIGradient", G2L["2e"]);
G2L["30"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(108, 108, 108)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(76, 76, 76))};


-- StarterGui.ScreenGui.Frame.extra.ScrollingFrame.button.Frame.ImageButton
G2L["31"] = Instance.new("ImageButton", G2L["2e"]);
G2L["31"]["BorderSizePixel"] = 0;
G2L["31"]["ScaleType"] = Enum.ScaleType.Fit;
G2L["31"]["BackgroundTransparency"] = 1;
-- [ERROR] cannot convert ImageContent, please report to "https://github.com/uniquadev/GuiToLuaConverter/issues"
G2L["31"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["31"]["Image"] = [[http://www.roblox.com/asset/?id=6022668955]];
G2L["31"]["Size"] = UDim2.new(1, 0, 1, 0);
G2L["31"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);


-- StarterGui.ScreenGui.Frame.extra.ScrollingFrame.UIListLayout
G2L["32"] = Instance.new("UIListLayout", G2L["28"]);
G2L["32"]["Padding"] = UDim.new(0.03, 0);
G2L["32"]["SortOrder"] = Enum.SortOrder.LayoutOrder;
G2L["32"]["FillDirection"] = Enum.FillDirection.Horizontal;


-- StarterGui.ScreenGui.Frame.extra.ScrollingFrame.toggle
G2L["33"] = Instance.new("Frame", G2L["28"]);
G2L["33"]["BorderSizePixel"] = 0;
G2L["33"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["33"]["Size"] = UDim2.new(0.5, 0, 1, 0);
G2L["33"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["33"]["Name"] = [[toggle]];


-- StarterGui.ScreenGui.Frame.extra.ScrollingFrame.toggle.UIGradient
G2L["34"] = Instance.new("UIGradient", G2L["33"]);
G2L["34"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(36, 36, 36)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(25, 25, 25))};


-- StarterGui.ScreenGui.Frame.extra.ScrollingFrame.toggle.UICorner
G2L["35"] = Instance.new("UICorner", G2L["33"]);
G2L["35"]["CornerRadius"] = UDim.new(0.05, 0);


-- StarterGui.ScreenGui.Frame.extra.ScrollingFrame.toggle.TextLabel
G2L["36"] = Instance.new("TextLabel", G2L["33"]);
G2L["36"]["TextWrapped"] = true;
G2L["36"]["BorderSizePixel"] = 0;
G2L["36"]["TextSize"] = 14;
G2L["36"]["TextStrokeColor3"] = Color3.fromRGB(206, 254, 255);
G2L["36"]["TextScaled"] = true;
G2L["36"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["36"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
G2L["36"]["TextColor3"] = Color3.fromRGB(206, 254, 255);
G2L["36"]["BackgroundTransparency"] = 1;
G2L["36"]["Size"] = UDim2.new(0.996, 0, 0.11183, 0);
G2L["36"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["36"]["Text"] = [[title]];
G2L["36"]["Position"] = UDim2.new(0, 0, 0.02317, 0);


-- StarterGui.ScreenGui.Frame.extra.ScrollingFrame.toggle.TextLabel.UITextSizeConstraint
G2L["37"] = Instance.new("UITextSizeConstraint", G2L["36"]);
G2L["37"]["MaxTextSize"] = 14;


-- StarterGui.ScreenGui.Frame.extra.ScrollingFrame.toggle.Frame
G2L["38"] = Instance.new("Frame", G2L["33"]);
G2L["38"]["BorderSizePixel"] = 0;
G2L["38"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["38"]["Size"] = UDim2.new(0.89712, 0, 0.80833, 0);
G2L["38"]["Position"] = UDim2.new(0.04938, 0, 0.13333, 0);
G2L["38"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);


-- StarterGui.ScreenGui.Frame.extra.ScrollingFrame.toggle.Frame.UICorner
G2L["39"] = Instance.new("UICorner", G2L["38"]);
G2L["39"]["CornerRadius"] = UDim.new(0.05, 0);


-- StarterGui.ScreenGui.Frame.extra.ScrollingFrame.toggle.Frame.UIGradient
G2L["3a"] = Instance.new("UIGradient", G2L["38"]);
G2L["3a"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(108, 108, 108)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(76, 76, 76))};


-- StarterGui.ScreenGui.Frame.extra.ScrollingFrame.toggle.Frame.ImageButton
G2L["3b"] = Instance.new("ImageButton", G2L["38"]);
G2L["3b"]["BorderSizePixel"] = 0;
G2L["3b"]["ScaleType"] = Enum.ScaleType.Fit;
G2L["3b"]["BackgroundTransparency"] = 1;
-- [ERROR] cannot convert ImageContent, please report to "https://github.com/uniquadev/GuiToLuaConverter/issues"
G2L["3b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["3b"]["Image"] = [[http://www.roblox.com/asset/?id=106604037379103]];
G2L["3b"]["Size"] = UDim2.new(1, 0, 1, 0);
G2L["3b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);


-- StarterGui.ScreenGui.Frame.extra.UIGradient
G2L["3c"] = Instance.new("UIGradient", G2L["24"]);
G2L["3c"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(51, 51, 51)),ColorSequenceKeypoint.new(0.407, Color3.fromRGB(48, 48, 48)),ColorSequenceKeypoint.new(0.564, Color3.fromRGB(45, 45, 45)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(51, 51, 51))};


-- StarterGui.ScreenGui.Frame.extra.shading
G2L["3d"] = Instance.new("ImageLabel", G2L["24"]);
G2L["3d"]["ZIndex"] = 3;
G2L["3d"]["BorderSizePixel"] = 0;
G2L["3d"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["3d"]["ImageTransparency"] = 0.26;
-- [ERROR] cannot convert ImageContent, please report to "https://github.com/uniquadev/GuiToLuaConverter/issues"
G2L["3d"]["ImageColor3"] = Color3.fromRGB(41, 41, 41);
G2L["3d"]["Image"] = [[rbxassetid://4654143143]];
G2L["3d"]["Size"] = UDim2.new(2.14495, 0, 2.09194, 0);
G2L["3d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["3d"]["BackgroundTransparency"] = 1;
G2L["3d"]["Name"] = [[shading]];
G2L["3d"]["Position"] = UDim2.new(0.49263, 0, -0.55705, 0);


-- StarterGui.ScreenGui.Frame.disable
G2L["3e"] = Instance.new("Frame", G2L["2"]);
G2L["3e"]["BorderSizePixel"] = 0;
G2L["3e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["3e"]["Size"] = UDim2.new(0.26582, 0, 0.36449, 0);
G2L["3e"]["Position"] = UDim2.new(0.00844, 0, 0.12461, 0);
G2L["3e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["3e"]["Name"] = [[disable]];


-- StarterGui.ScreenGui.Frame.disable.UICorner
G2L["3f"] = Instance.new("UICorner", G2L["3e"]);
G2L["3f"]["CornerRadius"] = UDim.new(0.03, 0);


-- StarterGui.ScreenGui.Frame.disable.TextLabel
G2L["40"] = Instance.new("TextLabel", G2L["3e"]);
G2L["40"]["TextWrapped"] = true;
G2L["40"]["BorderSizePixel"] = 0;
G2L["40"]["TextSize"] = 14;
G2L["40"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["40"]["TextScaled"] = true;
G2L["40"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["40"]["FontFace"] = Font.new([[rbxasset://fonts/families/JosefinSans.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["40"]["TextColor3"] = Color3.fromRGB(223, 223, 223);
G2L["40"]["BackgroundTransparency"] = 1;
G2L["40"]["Size"] = UDim2.new(0.73895, 0, 0.10603, 0);
G2L["40"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["40"]["Text"] = [[disable main]];
G2L["40"]["Position"] = UDim2.new(0.03927, 0, 0.02555, 0);


-- StarterGui.ScreenGui.Frame.disable.TextLabel.UITextSizeConstraint
G2L["41"] = Instance.new("UITextSizeConstraint", G2L["40"]);
G2L["41"]["MaxTextSize"] = 14;


-- StarterGui.ScreenGui.Frame.disable.Frame
G2L["42"] = Instance.new("Frame", G2L["3e"]);
G2L["42"]["BorderSizePixel"] = 0;
G2L["42"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["42"]["Size"] = UDim2.new(0.90518, 0, 0.76068, 0);
G2L["42"]["Position"] = UDim2.new(0.03927, 0, 0.18803, 0);
G2L["42"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);


-- StarterGui.ScreenGui.Frame.disable.Frame.UICorner
G2L["43"] = Instance.new("UICorner", G2L["42"]);
G2L["43"]["CornerRadius"] = UDim.new(0.07, 0);


-- StarterGui.ScreenGui.Frame.disable.Frame.UIGradient
G2L["44"] = Instance.new("UIGradient", G2L["42"]);
G2L["44"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(108, 108, 108)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(76, 76, 76))};


-- StarterGui.ScreenGui.Frame.disable.Frame.des
G2L["45"] = Instance.new("TextLabel", G2L["42"]);
G2L["45"]["TextWrapped"] = true;
G2L["45"]["BorderSizePixel"] = 0;
G2L["45"]["TextSize"] = 12;
G2L["45"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["45"]["TextTransparency"] = 0.11;
G2L["45"]["TextScaled"] = true;
G2L["45"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["45"]["FontFace"] = Font.new([[rbxasset://fonts/families/Arial.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["45"]["TextColor3"] = Color3.fromRGB(233, 233, 233);
G2L["45"]["BackgroundTransparency"] = 1;
G2L["45"]["Size"] = UDim2.new(0.94693, 0, 0.22472, 0);
G2L["45"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["45"]["Text"] = [[disable click to control npc]];
G2L["45"]["Name"] = [[des]];
G2L["45"]["Position"] = UDim2.new(0.04407, 0, 0.06742, 0);


-- StarterGui.ScreenGui.Frame.disable.Frame.togheader
G2L["46"] = Instance.new("Frame", G2L["42"]);
G2L["46"]["BorderSizePixel"] = 0;
G2L["46"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["46"]["Size"] = UDim2.new(0.89433, 0, 0.50562, 0);
G2L["46"]["Position"] = UDim2.new(0.04407, 0, 0.41573, 0);
G2L["46"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["46"]["Name"] = [[togheader]];


-- StarterGui.ScreenGui.Frame.disable.Frame.togheader.UIGradient
G2L["47"] = Instance.new("UIGradient", G2L["46"]);
G2L["47"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(46, 46, 46)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(21, 21, 21))};


-- StarterGui.ScreenGui.Frame.disable.Frame.togheader.UICorner
G2L["48"] = Instance.new("UICorner", G2L["46"]);
G2L["48"]["CornerRadius"] = UDim.new(0.2, 0);


-- StarterGui.ScreenGui.Frame.disable.Frame.togheader.off
G2L["49"] = Instance.new("Frame", G2L["46"]);
G2L["49"]["Visible"] = false;
G2L["49"]["BorderSizePixel"] = 0;
G2L["49"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["49"]["Size"] = UDim2.new(0.44118, 0, 1, 0);
G2L["49"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["49"]["Name"] = [[off]];


-- StarterGui.ScreenGui.Frame.disable.Frame.togheader.togglebutton
G2L["4a"] = Instance.new("ImageButton", G2L["46"]);
G2L["4a"]["BorderSizePixel"] = 0;
G2L["4a"]["ImageTransparency"] = 1;
-- [ERROR] cannot convert ImageContent, please report to "https://github.com/uniquadev/GuiToLuaConverter/issues"
G2L["4a"]["BackgroundColor3"] = Color3.fromRGB(0, 255, 0);
G2L["4a"]["Image"] = [[rbxasset://textures/ui/GuiImagePlaceholder.png]];
G2L["4a"]["Size"] = UDim2.new(0.441, 0, 1, 0);
G2L["4a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["4a"]["Name"] = [[togglebutton]];
G2L["4a"]["Position"] = UDim2.new(0.55882, 0, 0, 0);


-- StarterGui.ScreenGui.Frame.disable.Frame.togheader.togglebutton.UICorner
G2L["4b"] = Instance.new("UICorner", G2L["4a"]);
G2L["4b"]["CornerRadius"] = UDim.new(0.2, 0);


-- StarterGui.ScreenGui.Frame.disable.Frame.togheader.on
G2L["4c"] = Instance.new("Frame", G2L["46"]);
G2L["4c"]["Visible"] = false;
G2L["4c"]["BorderSizePixel"] = 0;
G2L["4c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["4c"]["Size"] = UDim2.new(0.44118, 0, 1, 0);
G2L["4c"]["Position"] = UDim2.new(0.55882, 0, 0, 0);
G2L["4c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["4c"]["Name"] = [[on]];


-- StarterGui.ScreenGui.Frame.disable.UIGradient
G2L["4d"] = Instance.new("UIGradient", G2L["3e"]);
G2L["4d"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(41, 41, 41)),ColorSequenceKeypoint.new(0.360, Color3.fromRGB(51, 51, 51)),ColorSequenceKeypoint.new(0.479, Color3.fromRGB(51, 51, 51)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(49, 49, 49))};


-- StarterGui.ScreenGui.Frame.UIAspectRatioConstraint
G2L["4e"] = Instance.new("UIAspectRatioConstraint", G2L["2"]);
G2L["4e"]["AspectRatio"] = 1.47664;


-- StarterGui.ScreenGui.Frame.shadow
G2L["4f"] = Instance.new("ImageLabel", G2L["2"]);
G2L["4f"]["ZIndex"] = -2;
G2L["4f"]["BorderSizePixel"] = 0;
G2L["4f"]["SliceCenter"] = Rect.new(0, 0, 1, 1);
G2L["4f"]["SliceScale"] = 4;
G2L["4f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["4f"]["ImageTransparency"] = 0.47;
-- [ERROR] cannot convert ImageContent, please report to "https://github.com/uniquadev/GuiToLuaConverter/issues"
G2L["4f"]["ImageColor3"] = Color3.fromRGB(0, 0, 0);
G2L["4f"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
G2L["4f"]["Image"] = [[rbxassetid://4654143143]];
G2L["4f"]["Size"] = UDim2.new(1.649, 0, 1.633, 0);
G2L["4f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["4f"]["BackgroundTransparency"] = 1;
G2L["4f"]["Name"] = [[shadow]];
G2L["4f"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);


-- StarterGui.ScreenGui.Frame.minimize
G2L["50"] = Instance.new("Frame", G2L["2"]);
G2L["50"]["BorderSizePixel"] = 0;
G2L["50"]["BackgroundColor3"] = Color3.fromRGB(76, 76, 76);
G2L["50"]["Size"] = UDim2.new(0.051, 0, 0.075, 0);
G2L["50"]["Position"] = UDim2.new(0.94, 0, 0.019, 0);
G2L["50"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["50"]["Name"] = [[minimize]];


-- StarterGui.ScreenGui.Frame.minimize.UICorner
G2L["51"] = Instance.new("UICorner", G2L["50"]);
G2L["51"]["CornerRadius"] = UDim.new(0.25, 0);


-- StarterGui.ScreenGui.Frame.minimize.button
G2L["52"] = Instance.new("ImageButton", G2L["50"]);
G2L["52"]["BorderSizePixel"] = 0;
G2L["52"]["BackgroundTransparency"] = 1;
-- [ERROR] cannot convert ImageContent, please report to "https://github.com/uniquadev/GuiToLuaConverter/issues"
G2L["52"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["52"]["Image"] = [[http://www.roblox.com/asset/?id=6026568240]];
G2L["52"]["Size"] = UDim2.new(1, 0, 1, 0);
G2L["52"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["52"]["Name"] = [[button]];


-- StarterGui.ScreenGui.Frame.network
G2L["53"] = Instance.new("Frame", G2L["2"]);
G2L["53"]["BorderSizePixel"] = 0;
G2L["53"]["BackgroundColor3"] = Color3.fromRGB(51, 51, 51);
G2L["53"]["Size"] = UDim2.new(0.25316, 0, 0.36449, 0);
G2L["53"]["Position"] = UDim2.new(0.29114, 0, 0.12461, 0);
G2L["53"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["53"]["Name"] = [[network]];


-- StarterGui.ScreenGui.Frame.network.UICorner
G2L["54"] = Instance.new("UICorner", G2L["53"]);
G2L["54"]["CornerRadius"] = UDim.new(0.03, 0);


-- StarterGui.ScreenGui.Frame.network.TextLabel
G2L["55"] = Instance.new("TextLabel", G2L["53"]);
G2L["55"]["TextWrapped"] = true;
G2L["55"]["BorderSizePixel"] = 0;
G2L["55"]["TextSize"] = 14;
G2L["55"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["55"]["TextScaled"] = true;
G2L["55"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["55"]["FontFace"] = Font.new([[rbxasset://fonts/families/JosefinSans.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["55"]["TextColor3"] = Color3.fromRGB(223, 223, 223);
G2L["55"]["BackgroundTransparency"] = 1;
G2L["55"]["Size"] = UDim2.new(0.73895, 0, 0.10603, 0);
G2L["55"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["55"]["Text"] = [[network owners]];
G2L["55"]["Position"] = UDim2.new(0.03927, 0, 0.02555, 0);


-- StarterGui.ScreenGui.Frame.network.TextLabel.UITextSizeConstraint
G2L["56"] = Instance.new("UITextSizeConstraint", G2L["55"]);
G2L["56"]["MaxTextSize"] = 14;


-- StarterGui.ScreenGui.Frame.network.Frame
G2L["57"] = Instance.new("Frame", G2L["53"]);
G2L["57"]["BorderSizePixel"] = 0;
G2L["57"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["57"]["Size"] = UDim2.new(0.90518, 0, 0.76068, 0);
G2L["57"]["Position"] = UDim2.new(0.03927, 0, 0.18803, 0);
G2L["57"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);


-- StarterGui.ScreenGui.Frame.network.Frame.UICorner
G2L["58"] = Instance.new("UICorner", G2L["57"]);
G2L["58"]["CornerRadius"] = UDim.new(0.07, 0);


-- StarterGui.ScreenGui.Frame.network.Frame.UIGradient
G2L["59"] = Instance.new("UIGradient", G2L["57"]);
G2L["59"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(108, 108, 108)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(76, 76, 76))};


-- StarterGui.ScreenGui.Frame.network.Frame.des
G2L["5a"] = Instance.new("TextLabel", G2L["57"]);
G2L["5a"]["TextWrapped"] = true;
G2L["5a"]["BorderSizePixel"] = 0;
G2L["5a"]["TextSize"] = 12;
G2L["5a"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["5a"]["TextTransparency"] = 0.11;
G2L["5a"]["TextScaled"] = true;
G2L["5a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["5a"]["FontFace"] = Font.new([[rbxasset://fonts/families/Arial.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["5a"]["TextColor3"] = Color3.fromRGB(233, 233, 233);
G2L["5a"]["BackgroundTransparency"] = 1;
G2L["5a"]["Size"] = UDim2.new(0.94693, 0, 0.22472, 0);
G2L["5a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["5a"]["Text"] = [[show network ownership of npc with your network ownership]];
G2L["5a"]["Name"] = [[des]];
G2L["5a"]["Position"] = UDim2.new(0.04407, 0, 0.06742, 0);


-- StarterGui.ScreenGui.Frame.network.Frame.togheader
G2L["5b"] = Instance.new("Frame", G2L["57"]);
G2L["5b"]["BorderSizePixel"] = 0;
G2L["5b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["5b"]["Size"] = UDim2.new(0.89433, 0, 0.50562, 0);
G2L["5b"]["Position"] = UDim2.new(0.04407, 0, 0.41573, 0);
G2L["5b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["5b"]["Name"] = [[togheader]];


-- StarterGui.ScreenGui.Frame.network.Frame.togheader.UIGradient
G2L["5c"] = Instance.new("UIGradient", G2L["5b"]);
G2L["5c"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(46, 46, 46)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(21, 21, 21))};


-- StarterGui.ScreenGui.Frame.network.Frame.togheader.UICorner
G2L["5d"] = Instance.new("UICorner", G2L["5b"]);
G2L["5d"]["CornerRadius"] = UDim.new(0.2, 0);


-- StarterGui.ScreenGui.Frame.network.Frame.togheader.off
G2L["5e"] = Instance.new("Frame", G2L["5b"]);
G2L["5e"]["Visible"] = false;
G2L["5e"]["BorderSizePixel"] = 0;
G2L["5e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["5e"]["Size"] = UDim2.new(0.44118, 0, 1, 0);
G2L["5e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["5e"]["Name"] = [[off]];


-- StarterGui.ScreenGui.Frame.network.Frame.togheader.togglebutton
G2L["5f"] = Instance.new("ImageButton", G2L["5b"]);
G2L["5f"]["BorderSizePixel"] = 0;
G2L["5f"]["ImageTransparency"] = 1;
G2L["5f"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
G2L["5f"]["Image"] = [[rbxasset://textures/ui/GuiImagePlaceholder.png]];
G2L["5f"]["Size"] = UDim2.new(0.441, 0, 1, 0);
G2L["5f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["5f"]["Name"] = [[togglebutton]];
G2L["5f"]["Position"] = UDim2.new(-0.00735, 0, 0, 0);


-- StarterGui.ScreenGui.Frame.network.Frame.togheader.togglebutton.UICorner
G2L["60"] = Instance.new("UICorner", G2L["5f"]);
G2L["60"]["CornerRadius"] = UDim.new(0.2, 0);


-- StarterGui.ScreenGui.Frame.network.Frame.togheader.on
G2L["61"] = Instance.new("Frame", G2L["5b"]);
G2L["61"]["Visible"] = false;
G2L["61"]["BorderSizePixel"] = 0;
G2L["61"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["61"]["Size"] = UDim2.new(0.44118, 0, 1, 0);
G2L["61"]["Position"] = UDim2.new(0.55882, 0, 0, 0);
G2L["61"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["61"]["Name"] = [[on]];


-- StarterGui.ScreenGui.Frame.UIScale
G2L["62"] = Instance.new("UIScale", G2L["2"]);



-- StarterGui.ScreenGui.Frame.UIDragDetector
G2L["63"] = Instance.new("UIDragDetector", G2L["2"]);



-- StarterGui.ScreenGui.icon
G2L["64"] = Instance.new("Frame", G2L["1"]);
G2L["64"]["Visible"] = false;
G2L["64"]["BorderSizePixel"] = 0;
G2L["64"]["BackgroundColor3"] = Color3.fromRGB(46, 46, 46);
G2L["64"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
G2L["64"]["Size"] = UDim2.new(0.06274, 0, 0.10163, 0);
G2L["64"]["Position"] = UDim2.new(0.144, 0, 0.24, 0);
G2L["64"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["64"]["Name"] = [[icon]];
G2L["64"]["BackgroundTransparency"] = 0.4;


-- StarterGui.ScreenGui.icon.UICorner
G2L["65"] = Instance.new("UICorner", G2L["64"]);
G2L["65"]["CornerRadius"] = UDim.new(1, 0);


-- StarterGui.ScreenGui.icon.ImageButton
G2L["66"] = Instance.new("ImageButton", G2L["64"]);
G2L["66"]["BorderSizePixel"] = 0;
G2L["66"]["ScaleType"] = Enum.ScaleType.Fit;
G2L["66"]["BackgroundTransparency"] = 1;
G2L["66"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["66"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
G2L["66"]["Image"] = [[rbxassetid://96581271712752]];
G2L["66"]["Size"] = UDim2.new(0.78, 0, 0.7184, 0);
G2L["66"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["66"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);


-- StarterGui.ScreenGui.icon.UIAspectRatioConstraint
G2L["67"] = Instance.new("UIAspectRatioConstraint", G2L["64"]);



-- StarterGui.ScreenGui.icon.UIScale
G2L["68"] = Instance.new("UIScale", G2L["64"]);



-- StarterGui.ScreenGui.icon.UIDragDetector
G2L["69"] = Instance.new("UIDragDetector", G2L["64"]);
G2L["69"]["DragSpace"] = Enum.UIDragDetectorDragSpace.LayerCollector;
-- [ERROR] cannot convert ReferenceUIInstance, please report to "https://github.com/uniquadev/GuiToLuaConverter/issues"


-- StarterGui.ScreenGui.intro
G2L["6a"] = Instance.new("Frame", G2L["1"]);
G2L["6a"]["Visible"] = false;
G2L["6a"]["BorderSizePixel"] = 0;
G2L["6a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["6a"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
G2L["6a"]["Size"] = UDim2.new(0.25094, 0, 0.4065, 0);
G2L["6a"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
G2L["6a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["6a"]["Name"] = [[intro]];


-- StarterGui.ScreenGui.intro.UIAspectRatioConstraint
G2L["6b"] = Instance.new("UIAspectRatioConstraint", G2L["6a"]);



-- StarterGui.ScreenGui.intro.UIGradient
G2L["6c"] = Instance.new("UIGradient", G2L["6a"]);
G2L["6c"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(49, 49, 49)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(23, 23, 23))};


-- StarterGui.ScreenGui.intro.UICorner
G2L["6d"] = Instance.new("UICorner", G2L["6a"]);
G2L["6d"]["CornerRadius"] = UDim.new(0.03, 0);


-- StarterGui.ScreenGui.intro.icon
G2L["6e"] = Instance.new("ImageLabel", G2L["6a"]);
G2L["6e"]["BorderSizePixel"] = 0;
G2L["6e"]["ScaleType"] = Enum.ScaleType.Fit;
G2L["6e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["6e"]["Image"] = [[rbxassetid://96581271712752]];
G2L["6e"]["Size"] = UDim2.new(0.5, 0, 0.5, 0);
G2L["6e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["6e"]["BackgroundTransparency"] = 1;
G2L["6e"]["Name"] = [[icon]];
G2L["6e"]["Position"] = UDim2.new(0.25, 0, 0.09, 0);


-- StarterGui.ScreenGui.intro.title
G2L["6f"] = Instance.new("TextLabel", G2L["6a"]);
G2L["6f"]["TextWrapped"] = true;
G2L["6f"]["BorderSizePixel"] = 0;
G2L["6f"]["TextSize"] = 14;
G2L["6f"]["TextScaled"] = true;
G2L["6f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["6f"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
G2L["6f"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
G2L["6f"]["BackgroundTransparency"] = 1;
G2L["6f"]["Size"] = UDim2.new(0.61, 0, 0.115, 0);
G2L["6f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["6f"]["Text"] = [[Im_Patrick npc panel]];
G2L["6f"]["Name"] = [[title]];
G2L["6f"]["Position"] = UDim2.new(0.195, 0, 0.59, 0);


-- StarterGui.ScreenGui.intro.title.UITextSizeConstraint
G2L["70"] = Instance.new("UITextSizeConstraint", G2L["6f"]);
G2L["70"]["MaxTextSize"] = 14;


-- StarterGui.ScreenGui.intro.UIScale
G2L["71"] = Instance.new("UIScale", G2L["6a"]);



-- StarterGui.ScreenGui.dark
G2L["72"] = Instance.new("Frame", G2L["1"]);
G2L["72"]["Visible"] = false;
G2L["72"]["ZIndex"] = -10;
G2L["72"]["BorderSizePixel"] = 0;
G2L["72"]["BackgroundColor3"] = Color3.fromRGB(5, 5, 5);
G2L["72"]["Size"] = UDim2.new(1, 0, 1, 0);
G2L["72"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["72"]["Name"] = [[dark]];
G2L["72"]["BackgroundTransparency"] = 0.65;


-- StarterGui.ScreenGui.StringValue
G2L["73"] = Instance.new("StringValue", G2L["1"]);



local script = G2L["73"];
local gui = script.Parent

local frame = gui.Frame
local dark = gui.dark
local intro = gui.intro
local icon = gui.icon

local main = frame.main
local bar = frame.bar
local extra = frame.extra
local disable = frame.disable
local minimize = frame.minimize
local network = frame.network

local intro_icon = intro.icon
local intro_title = intro.title

local icon_image = icon.ImageButton

local main_scrollingframe = main.ScrollingFrame
local extra_scrollingframe = extra.ScrollingFrame

local minimize_button = minimize.button

local main_button = main_scrollingframe.button:Clone()
local main_toggle = main_scrollingframe.toggle:Clone()

local extra_buton = extra_scrollingframe.button:Clone()
local extra_toggle = extra_scrollingframe.toggle:Clone()

main_scrollingframe.button:Destroy()
main_scrollingframe.toggle:Destroy()

extra_scrollingframe.button:Destroy()
extra_scrollingframe.toggle:Destroy()

local lighting = game:GetService("Lighting")
local tweenservice = game:GetService("TweenService")

local fast = TweenInfo.new(.5, Enum.EasingStyle.Exponential)
local medium = TweenInfo.new(.67)
local slow = TweenInfo.new(.8)

function partowner(part)
	return part.ReceiveAge == 0
end

clicknpc = true
disable.Frame.togheader.togglebutton.MouseButton1Click:Connect(function()
	task.spawn(function()
		clicknpc = not clicknpc
		tweenservice:Create(disable.Frame.togheader.togglebutton, fast, {Position = clicknpc and disable.Frame.togheader.on.Position or disable.Frame.togheader.off.Position, BackgroundColor3 = clicknpc and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(212, 0, 0)}):Play()
	end)
end)

networkvis = false
network.Frame.togheader.togglebutton.MouseButton1Click:Connect(function()
	task.spawn(function()
		networkvis = not networkvis
		settings().Physics.AreOwnersShown = networkvis
		tweenservice:Create(network.Frame.togheader.togglebutton, fast, {Position = networkvis and network.Frame.togheader.on.Position or network.Frame.togheader.off.Position, BackgroundColor3 = networkvis and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(212, 0, 0)}):Play()
	end)
end)

local minimizebool
local minim = function()
	minimizebool = not minimizebool
	if minimizebool then
		icon.Visible = true
		icon.UIScale.Scale = 0
		tweenservice:Create(frame.UIScale, fast, {Scale = 0}):Play()
		tweenservice:Create(icon.UIScale, fast, {Scale = 1}):Play()
		task.wait(.6)
		frame.Visible = false
	else
		frame.Visible = true
		tweenservice:Create(frame.UIScale, fast, {Scale = 1}):Play()
		tweenservice:Create(icon.UIScale, fast, {Scale = 0}):Play()
		task.wait(.6)
		icon.Visible = false
	end
end

minimize_button.MouseButton1Click:Connect(function()
	minim()
end)

icon_image.MouseButton1Click:Connect(function()
	minim()
end)

local intro = function()
	dark.Visible = true
	dark.BackgroundTransparency = 1
	intro_icon.ImageTransparency = 1
	intro_title.TextTransparency = 1
	intro.UIScale.Scale = 0
	intro.BackgroundTransparency = 1
	frame.UIScale.Scale = 0
	intro.Visible = true

	local blur = Instance.new("BlurEffect")
	blur.Name = "intro"
	blur.Size = 0
	blur.Parent = lighting

	tweenservice:Create(blur, slow, {Size = 24}):Play()

	tweenservice:Create(dark, slow, {BackgroundTransparency = 0.65}):Play()
	task.wait(.21)
	tweenservice:Create(intro, medium, {BackgroundTransparency = 0}):Play()
	tweenservice:Create(intro.UIScale, medium, {Scale = 1}):Play()
	task.wait(.2)
	tweenservice:Create(intro_icon, medium, {ImageTransparency = 0}):Play()
	task.wait(.4)
	tweenservice:Create(intro_title, medium, {TextTransparency = 0}):Play()
	task.wait(5)
	tweenservice:Create(blur, slow, {Size = 0}):Play()
	tweenservice:Create(intro, medium, {BackgroundTransparency = 1}):Play()
	tweenservice:Create(intro.UIScale, medium, {Scale = 0}):Play()
	task.wait(.3)
	tweenservice:Create(dark, slow, {BackgroundTransparency = 1}):Play()
	task.wait(.6)
	tweenservice:Create(frame.UIScale, medium, {Scale = 1}):Play()
	blur:Destroy()
end

local create = function()
	local create = {}

	function create:mainbutton(title : TextLabel, description : TextLabel, func)
		local buttonsample = main_button:Clone()
		buttonsample.Parent = main_scrollingframe

		buttonsample.title.Text = title or "error"
		buttonsample.des.Text = description or "error"

		buttonsample.click.MouseButton1Click:Connect(function()
			if func then
				task.spawn(function()
					tweenservice:Create(buttonsample.UIStroke, TweenInfo.new(0.1), {Thickness = 1}):Play()
					task.wait(.2)
					tweenservice:Create(buttonsample.UIStroke, TweenInfo.new(0.1), {Thickness = 0}):Play()

				end)
				local _,err = pcall(func)
				if err then
					error(err)
				end
			end
		end)

		return buttonsample
	end

	function create:maintoggle(title : TextLabel, description : TextLabel, func)
		local togglesample = main_toggle:Clone()
		local addition = {}
		togglesample.Parent = main_scrollingframe

		togglesample.title.Text = title or "error"
		togglesample.des.Text = description or "error"

		local toggle = false
		togglesample.click.MouseButton1Click:Connect(function()
			toggle = not toggle
			if func then
				task.spawn(function()
					tweenservice:Create(togglesample.toggle, TweenInfo.new(.2), {BackgroundColor3 = toggle and Color3.fromRGB(26, 255, 0) or Color3.fromRGB(188, 0, 0)}):Play()
					tweenservice:Create(togglesample.UIStroke, TweenInfo.new(.1), {Thickness = 1}):Play()
					task.wait(.2)
					tweenservice:Create(togglesample.UIStroke, TweenInfo.new(.1), {Thickness = 0}):Play()
				end)
				local _,err = pcall(func, toggle)
				if err then
					error(err)
				end
			end
		end)

		function addition:swich(bool)
			toggle = bool
			tweenservice:Create(togglesample.toggle, TweenInfo.new(.2), {BackroundColor3 = toggle and Color3.fromRGB(26, 255, 0) or Color3.fromRGB(188, 0, 0)}):Play()
		end

		return addition
	end

	function create:extrabutton(title : TextLabel, func)
		local buttonsample = extra_buton:Clone()
		buttonsample.Parent = extra_scrollingframe
		buttonsample.TextLabel.Text = title or "error"

		buttonsample.Frame.ImageButton.MouseButton1Click:Connect(function()
			if func then
				task.spawn(function()
					tweenservice:Create(buttonsample.Frame.ImageButton, TweenInfo.new(0.2), {ImageColor3 = Color3.fromRGB(0, 213, 255)}):Play()
					task.wait(.2)
					tweenservice:Create(buttonsample.Frame.ImageButton, TweenInfo.new(0.2), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
				end)
				local _,err = pcall(func)
				if err then
					error(err)
				end
			end
		end)
	end

	function create:extratoggle(title :TextLabel, func)
		local togglesample = extra_toggle:Clone()
		local addition = {}
		togglesample.Parent = extra_scrollingframe
		togglesample.TextLabel.Text = title or "error"

		local toggle = false
		togglesample.Frame.ImageButton.MouseButton1Click:Connect(function()
			toggle = not toggle
			if func then
				task.spawn(function()
					tweenservice:Create(togglesample.Frame.ImageButton, TweenInfo.new(.2), {ImageColor3 = toggle and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(232, 232, 232)}):Play()
				end)

				local _,err = pcall(func, toggle)
				if err then
					error(err)
				end
			end
		end)
	end

	return create
end



intro()

return {create = create,  G2L = G2L["1"]}
