local user_input_service = game:GetService("UserInputService")
local http_service = game:GetService("HttpService")
local local_player = game.Players.LocalPlayer
local gui_parent = gethui and gethui() or game:GetService("CoreGui")

local old_gui = gui_parent:FindFirstChild("TDSGui")
if old_gui then old_gui:Destroy() end

local CONFIG_FILE = "ADS_Config.json"

_G.AutoMercenary = _G.AutoMercenary or false
_G.PathDistance = _G.PathDistance or 0
_G.SellFarms = _G.SellFarms or false
_G.SellFarmsWave = _G.SellFarmsWave or 39

local function save_settings()
    local data = {
        AutoSkip = _G.AutoSkip,
        AutoPickups = _G.AutoPickups,
        AutoChain = _G.AutoChain,
        AutoDJ = _G.AutoDJ,
        AntiLag = _G.AntiLag,
        ClaimRewards = _G.ClaimRewards,
        SendWebhook = _G.SendWebhook,
        WebhookURL = _G.WebhookURL,
        AutoMercenary = _G.AutoMercenary,
        PathDistance = _G.PathDistance,
        SellFarms = _G.SellFarms,
        SellFarmsWave = _G.SellFarmsWave
    }
    writefile(CONFIG_FILE, http_service:JSONEncode(data))
end

local function load_settings()
    local default = {
        AutoSkip = false,
        AutoPickups = false,
        AutoChain = false,
        AutoDJ = false,
        AntiLag = false,
        ClaimRewards = false,
        SendWebhook = false,
        WebhookURL = "",
        AutoMercenary = false,
        PathDistance = 0,
        SellFarms = false,
        SellFarmsWave = 13
    }
    if isfile(CONFIG_FILE) then
        local success, decoded = pcall(function()
            return http_service:JSONDecode(readfile(CONFIG_FILE))
        end)
        if success then
            for k, v in pairs(decoded) do
                _G[k] = v
            end
            return
        end
    end
    for k, v in pairs(default) do
        _G[k] = v
    end
end

load_settings()

local tds_gui = Instance.new("ScreenGui")
tds_gui.Name = "TDSGui"
tds_gui.Parent = gui_parent
tds_gui.ResetOnSpawn = false
tds_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local main_frame = Instance.new("Frame")
main_frame.Name = "MainFrame"
main_frame.Parent = tds_gui
main_frame.Size = UDim2.new(0, 380, 0, 380)
main_frame.Position = UDim2.new(0.5, -190, 0.5, -190)
main_frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
main_frame.BorderSizePixel = 0
main_frame.Active = true
main_frame.ClipsDescendants = true

Instance.new("UICorner", main_frame).CornerRadius = UDim.new(0, 10)
local main_stroke = Instance.new("UIStroke", main_frame)
main_stroke.Color = Color3.fromRGB(55, 55, 65)
main_stroke.Thickness = 1.5
main_stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local header_frame = Instance.new("Frame", main_frame)
header_frame.Size = UDim2.new(1, 0, 0, 45)
header_frame.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
header_frame.BorderSizePixel = 0
Instance.new("UICorner", header_frame).CornerRadius = UDim.new(0, 10)

local header_mask = Instance.new("Frame", header_frame)
header_mask.Size = UDim2.new(1, 0, 0, 10)
header_mask.Position = UDim2.new(0, 0, 1, -10)
header_mask.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
header_mask.BorderSizePixel = 0

local title_label = Instance.new("TextLabel", header_frame)
title_label.Size = UDim2.new(1, -90, 1, 0)
title_label.Position = UDim2.new(0, 15, 0, 0)
title_label.Text = "AFK Defense Simulator"
title_label.TextColor3 = Color3.fromRGB(255, 255, 255)
title_label.BackgroundTransparency = 1
title_label.Font = Enum.Font.GothamBold
title_label.TextSize = 14
title_label.TextXAlignment = Enum.TextXAlignment.Left

local min_btn = Instance.new("TextButton", header_frame)
min_btn.Size = UDim2.new(0, 24, 0, 24)
min_btn.Position = UDim2.new(1, -35, 0.5, -12)
min_btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
min_btn.Text = "-"
min_btn.TextColor3 = Color3.fromRGB(255, 255, 255)
min_btn.Font = Enum.Font.GothamBold
min_btn.TextSize = 18
Instance.new("UICorner", min_btn).CornerRadius = UDim.new(0, 6)

local open_button = Instance.new("TextButton", tds_gui)
open_button.Size = UDim2.new(0, 100, 0, 30)
open_button.Position = UDim2.new(0.5, -50, 0, 10)
open_button.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
open_button.Text = "OPEN MENU"
open_button.TextColor3 = Color3.fromRGB(255, 255, 255)
open_button.Font = Enum.Font.GothamBold
open_button.TextSize = 12
open_button.Visible = false
Instance.new("UICorner", open_button).CornerRadius = UDim.new(0, 6)

local function toggle_gui()
    local is_visible = main_frame.Visible
    main_frame.Visible = not is_visible
    open_button.Visible = is_visible
end

min_btn.MouseButton1Click:Connect(toggle_gui)
open_button.MouseButton1Click:Connect(toggle_gui)

local tab_bar = Instance.new("Frame", main_frame)
tab_bar.Size = UDim2.new(1, 0, 0, 30)
tab_bar.Position = UDim2.new(0, 0, 0, 45)
tab_bar.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
tab_bar.BorderSizePixel = 0

local tab_layout = Instance.new("UIListLayout", tab_bar)
tab_layout.FillDirection = Enum.FillDirection.Horizontal

local function create_tab_btn(name)
    local btn = Instance.new("TextButton", tab_bar)
    btn.Size = UDim2.new(0.333, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(150, 150, 160)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    return btn
end

local logger_btn = create_tab_btn("LOGGER")
local main_tab_btn = create_tab_btn("MAIN")
local misc_tab_btn = create_tab_btn("MISC")

local content_holder = Instance.new("Frame", main_frame)
content_holder.Size = UDim2.new(1, 0, 1, -110)
content_holder.Position = UDim2.new(0, 0, 0, 75)
content_holder.BackgroundTransparency = 1

local function create_page()
    local page = Instance.new("ScrollingFrame", content_holder)
    page.Size = UDim2.new(1, -24, 1, -10)
    page.Position = UDim2.new(0, 12, 0, 5)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.Visible = false
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    return page
end

local logger_page = create_page()
local main_page = create_page()
local misc_page = create_page()

local function create_toggle(display_name, global_var, parent)
    local toggle_bg = Instance.new("Frame", parent)
    toggle_bg.Size = UDim2.new(1, 0, 0, 35)
    toggle_bg.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    Instance.new("UICorner", toggle_bg).CornerRadius = UDim.new(0, 6)
    
    local label = Instance.new("TextLabel", toggle_bg)
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = display_name
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton", toggle_bg)
    btn.Size = UDim2.new(0, 38, 0, 20)
    btn.Position = UDim2.new(1, -48, 0.5, -10)
    btn.BackgroundColor3 = _G[global_var] and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(60, 60, 70)
    btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    
    local circle = Instance.new("Frame", btn)
    circle.Size = UDim2.new(0, 14, 0, 14)
    circle.Position = _G[global_var] and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    
    btn.MouseButton1Click:Connect(function()
        _G[global_var] = not _G[global_var]
        btn.BackgroundColor3 = _G[global_var] and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(60, 60, 70)
        circle:TweenPosition(_G[global_var] and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7), "Out", "Quad", 0.15, true)
        save_settings()
    end)
    return toggle_bg
end

local function create_toggle_with_input(display_name, toggle_var, input_var, parent)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 35)
    container.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = display_name
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", container)
    box.Size = UDim2.new(0, 75, 0, 22)
    box.Position = UDim2.new(1, -130, 0.5, -11)
    box.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    box.Text = "Wave: " .. tostring(_G[input_var])
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 10
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    local box_stroke = Instance.new("UIStroke", box)
    box_stroke.Color = Color3.fromRGB(55, 55, 65)
    box_stroke.Thickness = 1

    box.Focused:Connect(function()
        box.Text = ""
    end)

    box.FocusLost:Connect(function(enterPressed)
        local val = tonumber(box.Text:match("%d+"))
        if val then
            _G[input_var] = val
            save_settings()
        end
        box.Text = "Wave: " .. tostring(_G[input_var])
    end)

    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(0, 38, 0, 20)
    btn.Position = UDim2.new(1, -48, 0.5, -10)
    btn.BackgroundColor3 = _G[toggle_var] and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(60, 60, 70)
    btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    
    local circle = Instance.new("Frame", btn)
    circle.Size = UDim2.new(0, 14, 0, 14)
    circle.Position = _G[toggle_var] and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

    btn.MouseButton1Click:Connect(function()
        _G[toggle_var] = not _G[toggle_var]
        btn.BackgroundColor3 = _G[toggle_var] and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(60, 60, 70)
        circle:TweenPosition(_G[toggle_var] and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7), "Out", "Quad", 0.15, true)
        save_settings()
    end)
end

local function create_slider(display_name, global_var, min, max, parent)
    local slider_bg = Instance.new("Frame", parent)
    slider_bg.Size = UDim2.new(1, 0, 0, 50)
    slider_bg.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    Instance.new("UICorner", slider_bg).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel", slider_bg)
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 12, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = display_name .. ": " .. tostring(_G[global_var])
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left

    local slide_bar = Instance.new("Frame", slider_bg)
    slide_bar.Size = UDim2.new(1, -24, 0, 4)
    slide_bar.Position = UDim2.new(0, 12, 0, 35)
    slide_bar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    Instance.new("UICorner", slide_bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", slide_bar)
    fill.Size = UDim2.new((_G[global_var] - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", slide_bar)
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new((_G[global_var] - min) / (max - min), -6, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function move_knob(input)
        local pos = math.clamp((input.Position.X - slide_bar.AbsolutePosition.X) / slide_bar.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * pos)
        _G[global_var] = value
        label.Text = display_name .. ": " .. tostring(value)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        knob.Position = UDim2.new(pos, -6, 0.5, -6)
        save_settings()
    end

    local sliding = false
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true end
    end)
    user_input_service.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
    user_input_service.InputChanged:Connect(function(input)
        if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            move_knob(input)
        end
    end)
end

create_toggle("Auto Skip Waves", "AutoSkip", main_page)
create_toggle("Auto Chain", "AutoChain", main_page)
create_toggle("Auto DJ Booth", "AutoDJ", main_page)
create_toggle("Auto Mercenary Base", "AutoMercenary", main_page)
create_toggle_with_input("Sell Farms", "SellFarms", "SellFarmsWave", main_page)
create_slider("Path Distance", "PathDistance", 0, 300, main_page)

create_toggle("Enable Anti-Lag", "AntiLag", misc_page)
create_toggle("Auto Collect Pickups", "AutoPickups", misc_page)
create_toggle("Claim Rewards", "ClaimRewards", misc_page)
create_toggle("Send Discord Webhook", "SendWebhook", misc_page)

local webhook_container = Instance.new("Frame", misc_page)
webhook_container.Size = UDim2.new(1, 0, 0, 60)
webhook_container.BackgroundTransparency = 1
local webhook_label = Instance.new("TextLabel", webhook_container)
webhook_label.Size = UDim2.new(1, 0, 0, 20); webhook_label.Text = "WEBHOOK URL"; webhook_label.TextColor3 = Color3.fromRGB(150, 150, 160); webhook_label.Font = Enum.Font.GothamBold; webhook_label.TextSize = 10; webhook_label.BackgroundTransparency = 1; webhook_label.TextXAlignment = Enum.TextXAlignment.Left
local webhook_box = Instance.new("TextBox", webhook_container)
webhook_box.Size = UDim2.new(1, 0, 0, 35); webhook_box.Position = UDim2.new(0, 0, 0, 22); webhook_box.BackgroundColor3 = Color3.fromRGB(15, 15, 18); webhook_box.PlaceholderText = "Paste Discord Webhook Link..."; webhook_box.Text = _G.WebhookURL; webhook_box.TextColor3 = Color3.fromRGB(255, 255, 255); webhook_box.Font = Enum.Font.Gotham; webhook_box.TextSize = 11; Instance.new("UICorner", webhook_box).CornerRadius = UDim.new(0, 6)
webhook_box.FocusLost:Connect(function() _G.WebhookURL = webhook_box.Text; save_settings() end)

local function SwitchTab(tabName)
    logger_page.Visible = (tabName == "LOGGER"); main_page.Visible = (tabName == "MAIN"); misc_page.Visible = (tabName == "MISC")
    logger_btn.TextColor3 = (tabName == "LOGGER") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
    main_tab_btn.TextColor3 = (tabName == "MAIN") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
    misc_tab_btn.TextColor3 = (tabName == "MISC") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
end
logger_btn.MouseButton1Click:Connect(function() SwitchTab("LOGGER") end)
main_tab_btn.MouseButton1Click:Connect(function() SwitchTab("MAIN") end)
misc_tab_btn.MouseButton1Click:Connect(function() SwitchTab("MISC") end)
SwitchTab("LOGGER")

local log_container_ui = Instance.new("Frame", logger_page)
log_container_ui.Size = UDim2.new(1, 0, 1, 0); log_container_ui.BackgroundColor3 = Color3.fromRGB(15, 15, 18); Instance.new("UICorner", log_container_ui).CornerRadius = UDim.new(0, 8)
local console_scrolling = Instance.new("ScrollingFrame", log_container_ui)
console_scrolling.Size = UDim2.new(1, -10, 1, -10); console_scrolling.Position = UDim2.new(0, 5, 0, 5); console_scrolling.BackgroundTransparency = 1; console_scrolling.ScrollBarThickness = 2; console_scrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UIListLayout", console_scrolling).Padding = UDim.new(0, 4)

local footer_frame = Instance.new("Frame", main_frame)
footer_frame.Size = UDim2.new(1, 0, 0, 35); footer_frame.Position = UDim2.new(0, 0, 1, -35); footer_frame.BackgroundTransparency = 1
local status_text = Instance.new("TextLabel", footer_frame); status_text.Size = UDim2.new(0.5, -15, 1, 0); status_text.Position = UDim2.new(0, 15, 0, 0); status_text.BackgroundTransparency = 1; status_text.Text = "● <font color='#00ff96'>Idle</font>"; status_text.TextColor3 = Color3.fromRGB(200, 200, 200); status_text.Font = Enum.Font.GothamMedium; status_text.RichText = true; status_text.TextSize = 11; status_text.TextXAlignment = Enum.TextXAlignment.Left
local clock_label = Instance.new("TextLabel", footer_frame); clock_label.Size = UDim2.new(0.5, -15, 1, 0); clock_label.Position = UDim2.new(0.5, 0, 0, 0); clock_label.BackgroundTransparency = 1; clock_label.Text = "TIME: 00:00:00"; clock_label.TextColor3 = Color3.fromRGB(120, 120, 130); clock_label.Font = Enum.Font.GothamBold; clock_label.TextSize = 10; clock_label.TextXAlignment = Enum.TextXAlignment.Right

local resize_btn = Instance.new("ImageButton", main_frame)
resize_btn.Size = UDim2.new(0, 16, 0, 16); resize_btn.Position = UDim2.new(1, -18, 1, -18); resize_btn.BackgroundTransparency = 1; resize_btn.Image = "rbxassetid://12750017154"; resize_btn.ZIndex = 5

local run_service = game:GetService("RunService")
local dragging, resizing = false, false
local drag_start, start_pos, target_pos = nil, nil, main_frame.Position
local resize_start_pos, start_size

header_frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; drag_start = input.Position; start_pos = main_frame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)

resize_btn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = true; resize_start_pos = input.Position; start_size = main_frame.Size
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then resizing = false end end)
    end
end)

user_input_service.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - drag_start
        target_pos = UDim2.new(start_pos.X.Scale, start_pos.X.Offset + delta.X, start_pos.Y.Scale, start_pos.Y.Offset + delta.Y)
    elseif resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - resize_start_pos
        main_frame.Size = UDim2.new(0, math.max(300, start_size.X.Offset + delta.X), 0, math.max(200, start_size.Y.Offset + delta.Y))
    end
end)

run_service.RenderStepped:Connect(function() main_frame.Position = main_frame.Position:Lerp(target_pos, 0.25) end)

local session_start = tick()
task.spawn(function()
    while task.wait(1) do
        local elapsed = tick() - session_start
        local h, m, s = math.floor(elapsed / 3600), math.floor((elapsed % 3600) / 60), math.floor(elapsed % 60)
        clock_label.Text = string.format("TIME: %02d:%02d:%02d", h, m, s)
    end
end)

shared.AutoStratGUI = {
    Console = console_scrolling,
    Status = function(new_status) status_text.Text = "● <font color='#00ff96'>" .. tostring(new_status) .. "</font>" end
}
