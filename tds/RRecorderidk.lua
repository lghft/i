local workspace_service = game:GetService("Workspace")
local players = game:GetService("Players")
local player = players.LocalPlayer
local player_gui = player:WaitForChild("PlayerGui")
local user_input_service = game:GetService("UserInputService")

local file_name = "Strat.txt"
local placement_count = 0
local last_action_time = tick()
local towers_list = {} 
_G.record_strat = false

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
resizer_frame.Name = "resizer_frame"
resizer_frame.Size = UDim2.new(0, 20, 0, 20)
resizer_frame.Position = UDim2.new(1, -20, 1, -20)
resizer_frame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
resizer_frame.BackgroundTransparency = 0.5
local resizer_corner = Instance.new("UICorner", resizer_frame)
resizer_corner.CornerRadius = UDim.new(1, 0)

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
        local new_size_x = mouse_pos.X - frame_pos.X
        local new_size_y = mouse_pos.Y - frame_pos.Y
        main_frame.Size = UDim2.new(0, math.max(200, new_size_x), 0, math.max(150, new_size_y))
    end
end)

user_input_service.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        is_resizing = false
    end
end)

local title_label = Instance.new("TextLabel", main_frame)
title_label.Name = "title_label"
title_label.Size = UDim2.new(1, -50, 0, 30)
title_label.Position = UDim2.new(0, 10, 0, 5)
title_label.Text = "Strat Recorder"
title_label.TextColor3 = Color3.new(1, 1, 1)
title_label.BackgroundTransparency = 1
title_label.Font = Enum.Font.GothamBold
title_label.TextSize = 18
title_label.TextXAlignment = Enum.TextXAlignment.Left

local close_btn = Instance.new("TextButton", main_frame)
close_btn.Name = "close_btn"
close_btn.Size = UDim2.new(0, 30, 0, 30)
close_btn.Position = UDim2.new(1, -35, 0, 5)
close_btn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
close_btn.Text = "×"
close_btn.TextColor3 = Color3.fromRGB(255, 100, 100)
close_btn.TextSize = 20
Instance.new("UICorner", close_btn)

local log_box = Instance.new("ScrollingFrame", main_frame)
log_box.Name = "log_box"
log_box.Size = UDim2.new(0.9, 0, 0.6, 0)
log_box.Position = UDim2.new(0.05, 0, 0.15, 0)
log_box.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
log_box.ScrollBarThickness = 4
log_box.CanvasSize = UDim2.new(0, 0, 0, 0)

local log_layout = Instance.new("UIListLayout", log_box)
log_layout.Padding = UDim.new(0, 2)

local start_btn = Instance.new("TextButton", main_frame)
start_btn.Name = "start_btn"
start_btn.Size = UDim2.new(0.42, 0, 0.12, 0)
start_btn.Position = UDim2.new(0.05, 0, 0.82, 0)
start_btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
start_btn.Text = "START"
start_btn.Font = Enum.Font.GothamBold
start_btn.TextColor3 = Color3.new(1, 1, 1)
start_btn.TextScaled = true
Instance.new("UICorner", start_btn)

local stop_btn = Instance.new("TextButton", main_frame)
stop_btn.Name = "stop_btn"
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
    log_item.Name = "log_item"
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
    local current_time = tick()
    local time_diff = current_time - last_action_time
    last_action_time = current_time
    
    local wait_line = string.format("task.wait(%.2f)\n", time_diff)
    if appendfile then
        appendfile(file_name, wait_line .. command_str .. "\n")
    end
end

workspace_service.Towers.ChildAdded:Connect(function(tower)
    if not _G.record_strat then return end
    task.wait(0.1) 
    placement_count = placement_count + 1
    towers_list[tower] = placement_count
    tower.Name = tostring(placement_count) 
end)

local old_namecall
old_namecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if _G.record_strat and (method == "InvokeServer" or method == "FireServer") then
        local action_name = tostring(args[2]) 

        -- PLACE
        if action_name:find("Pl") and action_name:find("ce") then
            local tower_type = tostring(args[4])
            local place_data = args[3]
            
            if type(place_data) == "table" and place_data.Position then
                local pos = place_data.Position
                record_action(string.format("TDS:Place(\"%s\", %.2f, %.2f, %.2f)", tower_type, pos.X, pos.Y, pos.Z))
                task.spawn(function() add_log("placed: " .. tower_type) end)
            end

        -- UPGRADE
        elseif action_name == "Upgrade" then
            local action_data = args[4]
            if action_data and action_data.Troop then
                local tower_id = towers_list[action_data.Troop]
                if tower_id then
                    record_action(string.format("TDS:Upgrade(%d)", tower_id))
                    task.spawn(function() add_log("upgraded: " .. tostring(tower_id)) end)
                end
            end

        -- SELL
        elseif action_name == "Sell" then
            local action_data = args[3]
            if action_data and action_data.Troop then
                local tower_id = towers_list[action_data.Troop]
                if tower_id then
                    record_action(string.format("TDS:Sell(%d)", tower_id))
                    task.spawn(function() 
                        add_log("sold: " .. tostring(tower_id))
                        towers_list[action_data.Troop] = nil 
                    end)
                end
            end

        -- ABILITIES
        elseif action_name == "Abilities" then
            local action_data = args[4]
            if action_data and type(action_data) == "table" then
                local ability_name = action_data.Name or "Unknown"
                local troop_instance = action_data.Troop
                local tower_id = towers_list[troop_instance] or "Unknown"
                
                local data_table = action_data.Data or {}
                local formatted_data = "{"
                for k, v in pairs(data_table) do
                    formatted_data = formatted_data .. string.format("[%s] = %s, ", tostring(k), tostring(v))
                end
                formatted_data = formatted_data:gsub(", $", "") .. "}"

                record_action(string.format("TDS:Ability(%s, \"%s\", %s)", 
                    tostring(tower_id), 
                    ability_name, 
                    formatted_data
                ))

                task.spawn(function()
                    add_log(string.format("Ability: %s (ID %s)", ability_name, tostring(tower_id)))
                end)
            end

        -- TARGET
        elseif action_name == "Target" then
            local action_data = args[4]
            print("asgas")
            
            if type(action_data) == "table" and action_data.Target then
                local target_value = tostring(action_data.Target)
                local troop_instance = action_data.Troop
                local tower_id = towers_list[troop_instance] or "Unknown"

                record_action(string.format("TDS:SetTarget(%s, \"%s\")", 
                    tostring(tower_id), 
                    target_value
                ))

                task.spawn(function()
                    add_log(string.format("set targeting: tower %s to %s", tostring(tower_id), target_value))
                end)
            end

        -- OPTION
        elseif action_name == "Option" or action_name == "Target" then
            local action_data = args[4]
            
            if type(action_data) == "table" and action_data.Troop then
                local tower_id = towers_list[action_data.Troop] or "Unknown"
                
                local primary_val = action_data.Value or action_data.Target or "Unknown"
                local opt_name = action_data.Name or "Targeting"

                record_action(string.format("TDS:SetOption(%s, \"%s\", \"%s\")", 
                    tostring(tower_id), 
                    tostring(opt_name), 
                    tostring(primary_val)
                ))

                task.spawn(function()
                    add_log(string.format("set option: tower %s value %s to %s", tostring(tower_id), opt_name, primary_val))
                end)
            end

        elseif action_name == "Skip" then
            record_action(string.format("TDS:VoteSkip()", tower_id))
            task.spawn(function() add_log("skipped wave: " .. tostring(tower_id)) end)
        end
    end

    return old_namecall(self, ...)
end)

start_btn.MouseButton1Click:Connect(function()
    _G.record_strat = true
    placement_count = 0
    towers_list = {}
    last_action_time = tick()
    
    for _, child in ipairs(log_box:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
    
    add_log("--- recording started ---")
    if writefile then 
        writefile(file_name, "-- strat recorded\n\n") 
    end
end)

stop_btn.MouseButton1Click:Connect(function()
    _G.record_strat = false
    add_log("--- recording stopped ---")
end)

close_btn.MouseButton1Click:Connect(function()
    _G.record_strat = false
    screen_gui:Destroy()
end)

add_log("recorder Ready")
