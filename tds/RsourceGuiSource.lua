local user_input_service = game:GetService("UserInputService")
local http_service = game:GetService("HttpService")
local local_player = game.Players.LocalPlayer
local gui_parent = gethui and gethui() or game:GetService("CoreGui")

local old_gui = gui_parent:FindFirstChild("TDSGui")
if old_gui then old_gui:Destroy() end

local CONFIG_FILE = "ADS_Config.json"

local function save_settings()
    local data = {
        AutoSkip = _G.AutoSkip,
        AutoPickups = _G.AutoPickups,
        AutoChain = _G.AutoChain,
        AutoDJ = _G.AutoDJ,
        AntiLag = _G.AntiLag,
        ClaimRewards = _G.ClaimRewards,
        SendWebhook = _G.SendWebhook,
        WebhookURL = _G.WebhookURL
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
        WebhookURL = ""
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
main_frame.Size = UDim2.new(0, 380, 0, 320)
main_frame.Position = UDim2.new(0.5, -190, 0.5, -160)
main_frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
main_frame.BorderSizePixel = 0
main_frame.Active = true

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
title_label.Size = UDim2.new(1, -50, 1, 0)
title_label.Position = UDim2.new(0, 15, 0, 0)
title_label.Text = "AFK Defense Simulator --> discord.gg/autostrat"
title_label.TextColor3 = Color3.fromRGB(255, 255, 255)
title_label.BackgroundTransparency = 1
title_label.Font = Enum.Font.GothamBold
title_label.TextSize = 15
title_label.TextXAlignment = Enum.TextXAlignment.Left

local tab_bar = Instance.new("Frame", main_frame)
tab_bar.Size = UDim2.new(1, 0, 0, 30)
tab_bar.Position = UDim2.new(0, 0, 0, 45)
tab_bar.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
tab_bar.BorderSizePixel = 0

local tab_layout = Instance.new("UIListLayout", tab_bar)
tab_layout.FillDirection = Enum.FillDirection.Horizontal

local function create_tab_btn(name, order)
    local btn = Instance.new("TextButton", tab_bar)
    btn.Size = UDim2.new(0.5, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = name
    btn.TextColor3 = order == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    return btn
end

local logger_btn = create_tab_btn("LOGGER", 1)
local settings_btn = create_tab_btn("SETTINGS", 2)

local content_holder = Instance.new("Frame", main_frame)
content_holder.Size = UDim2.new(1, 0, 1, -110)
content_holder.Position = UDim2.new(0, 0, 0, 75)
content_holder.BackgroundTransparency = 1

local logger_page = Instance.new("Frame", content_holder)
logger_page.Size = UDim2.new(1, 0, 1, 0)
logger_page.BackgroundTransparency = 1

local log_container = Instance.new("Frame", logger_page)
log_container.Size = UDim2.new(1, -24, 1, -10)
log_container.Position = UDim2.new(0, 12, 0, 5)
log_container.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
Instance.new("UICorner", log_container).CornerRadius = UDim.new(0, 8)

local console_scrolling = Instance.new("ScrollingFrame", log_container)
console_scrolling.Size = UDim2.new(1, -10, 1, -10)
console_scrolling.Position = UDim2.new(0, 5, 0, 5)
console_scrolling.BackgroundTransparency = 1
console_scrolling.BorderSizePixel = 0
console_scrolling.ScrollBarThickness = 2
console_scrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
Instance.new("UIListLayout", console_scrolling).Padding = UDim.new(0, 4)

local settings_page = Instance.new("Frame", content_holder)
settings_page.Size = UDim2.new(1, 0, 1, 0)
settings_page.BackgroundTransparency = 1
settings_page.Visible = false

local settings_scrolling = Instance.new("ScrollingFrame", settings_page)
settings_scrolling.Size = UDim2.new(1, -24, 1, -10)
settings_scrolling.Position = UDim2.new(0, 12, 0, 5)
settings_scrolling.BackgroundTransparency = 1
settings_scrolling.BorderSizePixel = 0
settings_scrolling.ScrollBarThickness = 2
settings_scrolling.CanvasSize = UDim2.new(0, 0, 0, 400)
local set_layout = Instance.new("UIListLayout", settings_scrolling)
set_layout.Padding = UDim.new(0, 6)
set_layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function create_toggle(display_name, global_var)
    local toggle_bg = Instance.new("Frame", settings_scrolling)
    toggle_bg.Size = UDim2.new(1, -10, 0, 35)
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
end

create_toggle("Auto Skip Waves", "AutoSkip")
create_toggle("Auto Collect Pickups", "AutoPickups")
create_toggle("Auto Chain", "AutoChain")
create_toggle("Auto DJ Booth", "AutoDJ")
create_toggle("Enable Anti-Lag", "AntiLag")
create_toggle("Claim Rewards", "ClaimRewards")
create_toggle("Send Discord Webhook", "SendWebhook")

local webhook_container = Instance.new("Frame", settings_scrolling)
webhook_container.Size = UDim2.new(1, -10, 0, 60)
webhook_container.BackgroundTransparency = 1

local webhook_label = Instance.new("TextLabel", webhook_container)
webhook_label.Size = UDim2.new(1, 0, 0, 20)
webhook_label.Text = "WEBHOOK URL"
webhook_label.TextColor3 = Color3.fromRGB(150, 150, 160)
webhook_label.Font = Enum.Font.GothamBold
webhook_label.TextSize = 10
webhook_label.BackgroundTransparency = 1
webhook_label.TextXAlignment = Enum.TextXAlignment.Left

local webhook_box = Instance.new("TextBox", webhook_container)
webhook_box.Size = UDim2.new(1, 0, 0, 35)
webhook_box.Position = UDim2.new(0, 0, 0, 22)
webhook_box.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
webhook_box.PlaceholderText = "Paste Discord Webhook Link..."
webhook_box.Text = _G.WebhookURL -- LOADED VALUE
webhook_box.TextColor3 = Color3.fromRGB(255, 255, 255)
webhook_box.Font = Enum.Font.Gotham
webhook_box.TextSize = 11
webhook_box.ClipsDescendants = true
Instance.new("UICorner", webhook_box).CornerRadius = UDim.new(0, 6)

webhook_box.FocusLost:Connect(function() 
    _G.WebhookURL = webhook_box.Text 
    save_settings()
end)

local function SwitchTab(tabName)
    if tabName == "LOGGER" then
        logger_page.Visible = true
        settings_page.Visible = false
        logger_btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        settings_btn.TextColor3 = Color3.fromRGB(150, 150, 160)
    else
        logger_page.Visible = false
        settings_page.Visible = true
        logger_btn.TextColor3 = Color3.fromRGB(150, 150, 160)
        settings_btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

logger_btn.MouseButton1Click:Connect(function() SwitchTab("LOGGER") end)
settings_btn.MouseButton1Click:Connect(function() SwitchTab("SETTINGS") end)

local footer_frame = Instance.new("Frame", main_frame)
footer_frame.Size = UDim2.new(1, 0, 0, 35)
footer_frame.Position = UDim2.new(0, 0, 1, -35)
footer_frame.BackgroundTransparency = 1

local status_text = Instance.new("TextLabel", footer_frame)
status_text.Size = UDim2.new(0.5, -15, 1, 0)
status_text.Position = UDim2.new(0, 15, 0, 0)
status_text.BackgroundTransparency = 1
status_text.Text = "● <font color='#00ff96'>Idle</font>"
status_text.TextColor3 = Color3.fromRGB(200, 200, 200)
status_text.Font = Enum.Font.GothamMedium
status_text.RichText = true
status_text.TextSize = 11
status_text.TextXAlignment = Enum.TextXAlignment.Left

local clock_label = Instance.new("TextLabel", footer_frame)
clock_label.Size = UDim2.new(0.5, -15, 1, 0)
clock_label.Position = UDim2.new(0.5, 0, 0, 0)
clock_label.BackgroundTransparency = 1
clock_label.Text = "TIME: 00:00:00"
clock_label.TextColor3 = Color3.fromRGB(120, 120, 130)
clock_label.Font = Enum.Font.GothamBold
clock_label.TextSize = 10
clock_label.TextXAlignment = Enum.TextXAlignment.Right

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

open_button.MouseButton1Click:Connect(toggle_gui)

local minimize_button = Instance.new("TextButton", header_frame)
minimize_button.Size = UDim2.new(0, 24, 0, 24)
minimize_button.Position = UDim2.new(1, -35, 0.5, -12)
minimize_button.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
minimize_button.Text = "-"
minimize_button.TextColor3 = Color3.fromRGB(255, 255, 255)
minimize_button.Font = Enum.Font.GothamBold
minimize_button.TextSize = 18
Instance.new("UICorner", minimize_button).CornerRadius = UDim.new(1, 0)
minimize_button.MouseButton1Click:Connect(toggle_gui)

local run_service = game:GetService("RunService")

local dragging = false
local drag_start
local start_pos
local target_pos = main_frame.Position

header_frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        drag_start = input.Position
        start_pos = main_frame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

user_input_service.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - drag_start
        target_pos = UDim2.new(
            start_pos.X.Scale,
            start_pos.X.Offset + delta.X,
            start_pos.Y.Scale,
            start_pos.Y.Offset + delta.Y
        )
    end
end)

run_service.RenderStepped:Connect(function()
    main_frame.Position = main_frame.Position:Lerp(target_pos, 0.25)
end)

user_input_service.InputBegan:Connect(function(input, processed)
    if not processed and (input.KeyCode == Enum.KeyCode.Delete or input.KeyCode == Enum.KeyCode.LeftAlt) then
        toggle_gui()
    end
end)

local session_start = tick()
task.spawn(function()
    while task.wait(1) do
        if not tds_gui.Parent then break end
        local elapsed = tick() - session_start
        local h, m, s = math.floor(elapsed / 3600), math.floor((elapsed % 3600) / 60), math.floor(elapsed % 60)
        clock_label.Text = string.format("TIME: %02d:%02d:%02d", h, m, s)
    end
end)

shared.AutoStratGUI = {
    Console = console_scrolling,
    Status = function(new_status)
        status_text.Text = "● <font color='#00ff96'>" .. tostring(new_status) .. "</font>"
    end
}
