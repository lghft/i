local players = game:GetService("Players")
local player = players.LocalPlayer
local player_gui = player:WaitForChild("PlayerGui")
local user_input_service = game:GetService("UserInputService")
local replicated_storage = game:GetService("ReplicatedStorage")
local http_service = game:GetService("HttpService")

local file_name = "Strat.txt"
_G.record_strat = false

local spawned_towers = {}
local tower_count = 0

local screen_gui = Instance.new("ScreenGui")
screen_gui.Name = "strat_recorder_ui"
screen_gui.ResetOnSpawn = false
screen_gui.Parent = player_gui

local main_frame = Instance.new("Frame", screen_gui)
main_frame.Name = "main_frame"
main_frame.Size = UDim2.new(0, 300, 0, 400)
main_frame.Position = UDim2.new(0.35, 0, 0.3, 0)
main_frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
main_frame.Active = true
main_frame.Draggable = true

local ui_corner = Instance.new("UICorner", main_frame)
ui_corner.CornerRadius = UDim.new(0, 8)

local resizer_frame = Instance.new("Frame", main_frame)
resizer_frame.Size = UDim2.new(0, 20, 0, 20)
resizer_frame.Position = UDim2.new(1, -20, 1, -20)
resizer_frame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
resizer_frame.BackgroundTransparency = 0.5
Instance.new("UICorner", resizer_frame).CornerRadius = UDim.new(1, 0)

local is_resizing = false
resizer_frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        is_resizing = true
    end
end)

user_input_service.InputChanged:Connect(function(input)
    if is_resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local mouse_pos = input.Position
        local frame_pos = main_frame.AbsolutePosition
        main_frame.Size = UDim2.new(0, math.max(200, mouse_pos.X - frame_pos.X), 0, math.max(150, mouse_pos.Y - frame_pos.Y))
    end
end)

user_input_service.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        is_resizing = false
    end
end)

local title_label = Instance.new("TextLabel", main_frame)
title_label.Size = UDim2.new(1, -50, 0, 30)
title_label.Position = UDim2.new(0, 10, 0, 5)
title_label.Text = "Strat Recorder"
title_label.TextColor3 = Color3.new(1, 1, 1)
title_label.BackgroundTransparency = 1
title_label.Font = Enum.Font.GothamBold
title_label.TextSize = 18
title_label.TextXAlignment = Enum.TextXAlignment.Left

local close_btn = Instance.new("TextButton", main_frame)
close_btn.Size = UDim2.new(0, 30, 0, 30)
close_btn.Position = UDim2.new(1, -35, 0, 5)
close_btn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
close_btn.Text = "×"
close_btn.TextColor3 = Color3.fromRGB(255, 100, 100)
close_btn.TextSize = 20
Instance.new("UICorner", close_btn)

local log_box = Instance.new("ScrollingFrame", main_frame)
log_box.Size = UDim2.new(0.9, 0, 0.6, 0)
log_box.Position = UDim2.new(0.05, 0, 0.15, 0)
log_box.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
log_box.ScrollBarThickness = 4
local log_layout = Instance.new("UIListLayout", log_box)

local start_btn = Instance.new("TextButton", main_frame)
start_btn.Size = UDim2.new(0.42, 0, 0.12, 0)
start_btn.Position = UDim2.new(0.05, 0, 0.82, 0)
start_btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
start_btn.Text = "START"
start_btn.Font = Enum.Font.GothamBold
start_btn.TextColor3 = Color3.new(1, 1, 1)
start_btn.TextScaled = true
Instance.new("UICorner", start_btn)

local stop_btn = Instance.new("TextButton", main_frame)
stop_btn.Size = UDim2.new(0.42, 0, 0.12, 0)
stop_btn.Position = UDim2.new(0.53, 0, 0.82, 0)
stop_btn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
stop_btn.Text = "STOP"
stop_btn.Font = Enum.Font.GothamBold
stop_btn.TextColor3 = Color3.new(1, 1, 1)
stop_btn.TextScaled = true
Instance.new("UICorner", stop_btn)

local function add_log(msg)
    local log_item = Instance.new("TextLabel", log_box)
    log_item.Size = UDim2.new(1, -10, 0, 18)
    log_item.BackgroundTransparency = 1
    log_item.TextColor3 = Color3.fromRGB(200, 200, 200)
    log_item.Text = "> " .. msg
    log_item.Font = Enum.Font.Code
    log_item.TextSize = 10
    log_item.TextXAlignment = Enum.TextXAlignment.Left
    
    log_box.CanvasSize = UDim2.new(0, 0, 0, log_layout.AbsoluteContentSize.Y)
    log_box.CanvasPosition = Vector2.new(0, log_box.CanvasSize.Y.Offset)
end

local function record_action(command_str)
    if not _G.record_strat then return end
    if appendfile then
        appendfile(file_name, command_str .. "\n")
    end
end

start_btn.MouseButton1Click:Connect(function()
    local current_mode = "Unknown"
    local current_map = "Unknown"
    
    local state_folder = replicated_storage:FindFirstChild("State")
    if state_folder then
        current_mode = state_folder.Difficulty.Value
        current_map = state_folder.Map.Value
    end

    local tower1, tower2, tower3, tower4, tower5 = "None", "None", "None", "None", "None"
    local current_modifiers = "" 
    local state_replicators = replicated_storage:FindFirstChild("StateReplicators")

    if state_replicators then
        for _, folder in ipairs(state_replicators:GetChildren()) do
            if folder.Name == "PlayerReplicator" and folder:GetAttribute("UserId") == player.UserId then
                local equipped = folder:GetAttribute("EquippedTowers")
                if type(equipped) == "string" then
                    local cleaned_json = equipped:match("%[.*%]") 
                    
                    local success, tower_table = pcall(function()
                        return http_service:JSONDecode(cleaned_json)
                    end)

                    if success and type(tower_table) == "table" then
                        tower1 = tower_table[1] or "None"
                        tower2 = tower_table[2] or "None"
                        tower3 = tower_table[3] or "None"
                        tower4 = tower_table[4] or "None"
                        tower5 = tower_table[5] or "None"
                    end
                end
            end

            if folder.Name == "ModifierReplicator" then
                local raw_votes = folder:GetAttribute("Votes")
                if type(raw_votes) == "string" then
                    local cleaned_json = raw_votes:match("{.*}") 
                    
                    local success, mod_table = pcall(function()
                        return http_service:JSONDecode(cleaned_json)
                    end)

                    if success and type(mod_table) == "table" then
                        local mods = {}
                        for mod_name, _ in pairs(mod_table) do
                            table.insert(mods, mod_name .. " = true")
                        end
                        current_modifiers = table.concat(mods, ", ")
                    end
                end
            end
        end
    end

    _G.record_strat = true
    for _, child in ipairs(log_box:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end

        add_log("Mode: " .. current_mode)
    add_log("Map: " .. current_map)
    add_log("Towers: " .. tower1 .. ", " .. tower2)
    add_log(tower3 .. ", " .. tower4 .. ", " .. tower5)
    
    add_log("--- Recording Started ---")
    
    if writefile then 
        local config_header = string.format([[
local TDS = loadstring(game:HttpGet("https://raw.githubusercontent.com/DuxiiT/auto-strat/refs/heads/main/Library.lua"))()

TDS:Loadout("%s", "%s", "%s", "%s", "%s")
TDS:Mode("%s")
TDS:GameInfo("%s", {%s})

]], tower1, tower2, tower3, tower4, tower5, current_mode, current_map, current_modifiers)

        writefile(file_name, config_header)
    end
end)

stop_btn.MouseButton1Click:Connect(function()
    _G.record_strat = false
    tower_count = 0
    spawned_towers = {}
    add_log("--- Recording Saved, Check your workspace\nfolder for a .txt called Strat.txt! ---")
end)

close_btn.MouseButton1Click:Connect(function()
    _G.record_strat = false
    tower_count = 0
    spawned_towers = {}
    screen_gui:Destroy()
end)

local towers_folder = workspace:WaitForChild("Towers")

towers_folder.ChildAdded:Connect(function(tower)
    if not _G.record_strat then return end
    
    local replicator = tower:WaitForChild("TowerReplicator", 5)
    if not replicator then return end

    local owner_id = replicator:GetAttribute("OwnerId")
    if owner_id and owner_id ~= player.UserId then return end

    tower_count = tower_count + 1
    local my_index = tower_count
    spawned_towers[tower] = my_index

    local tower_name = replicator:GetAttribute("Name") or tower.Name
    local raw_pos = replicator:GetAttribute("Position")
    
    local pos_x, pos_y, pos_z
    if typeof(raw_pos) == "Vector3" then
        pos_x, pos_y, pos_z = raw_pos.X, raw_pos.Y, raw_pos.Z
    else
        local p = tower:GetPivot().Position
        pos_x, pos_y, pos_z = p.X, p.Y, p.Z
    end
    
    local command = string.format('TDS:Place("%s", %.3f, %.3f, %.3f)', tower_name, pos_x, pos_y, pos_z)
    record_action(command)
    add_log("Placed " .. tower_name .. " (Index: " .. my_index .. ")")

    replicator:GetAttributeChangedSignal("Upgrade"):Connect(function()
        if not _G.record_strat then return end
        record_action(string.format('TDS:Upgrade(%d)', my_index))
        add_log("Upgraded Tower " .. my_index)
    end)
end)

towers_folder.ChildRemoved:Connect(function(tower)
    if not _G.record_strat then return end
    
    local my_index = spawned_towers[tower]
    if my_index then
        record_action(string.format('TDS:Sell(%d)', my_index))
        add_log("Sold Tower " .. my_index)
        
        spawned_towers[tower] = nil
    end
end)

add_log("Recorder Ready")
