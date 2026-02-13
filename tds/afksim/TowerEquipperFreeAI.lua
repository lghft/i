-- Tower list and name resolver
local Towers = {
    "Scout","Sniper","Paintballer","Demoman","Hunter","Soldier","Militant",
    "Freezer","Assassin","Shotgunner","Pyromancer","Ace Pilot","Medic","Farm",
    "Rocketeer","Trapper","Military Base","Crook Boss",
    "Electroshocker","Commander","Warden","Cowboy","DJ Booth","Minigunner",
    "Ranger","Pursuit","Gatling Gun","Turret","Mortar","Mercenary Base",
    "Brawler","Necromancer","Accelerator","Engineer","Hacker",
    "Gladiator","Commando","Slasher","Frost Blaster","Archer","Swarmer",
    "Toxic Gunner","Sledger","Executioner","Elf Camp","Jester","Cryomancer",
    "Hallow Punk","Harvester","Snowballer","Elementalist",
    "Firework Technician","Biologist","Warlock","Spotlight Tech","Mecha Base"
}

local function normalize(s)
    return s:lower():gsub("[^a-z0-9]", "")
end

local Normalized = {}
for _, name in ipairs(Towers) do
    Normalized[#Normalized + 1] = {
        raw = name,
        norm = normalize(name),
        words = name:lower():split(" ")
    }
end

local function resolveTower(input)
    if input == "" then return end
    local n = normalize(input)

    -- Exact match
    for _, t in ipairs(Normalized) do
        if t.norm == n then return t.raw end
    end

    -- Prefix on full name
    for _, t in ipairs(Normalized) do
        if t.norm:sub(1, #n) == n then return t.raw end
    end

    -- Prefix on any word
    for _, t in ipairs(Normalized) do
        for _, w in ipairs(t.words) do
            if w:sub(1, #n) == n then return t.raw end
        end
    end

    -- Substring match (last resort)
    for _, t in ipairs(Normalized) do
        if t.norm:find(n, 1, true) then return t.raw end
    end
end

-- ────────────────────────────────────────────────
-- Main TDS table (now includes the Equip function)
local TDS = {}

-- === TDS:Equip FUNCTION (inserted directly) ===
function TDS:Equip(tower_input)
    -- You must define game_state and remote_func somewhere in your environment
    -- This is a placeholder assumption — replace with your actual variables
    local game_state = "GAME"           -- ← CHANGE / DEFINE THIS
    local remote_func = game:GetService("ReplicatedStorage"):FindFirstChild("Remote")  -- ← CHANGE THIS TO YOUR ACTUAL REMOTE

    if game_state ~= "GAME" then
        return false
    end

    local tower_table = type(tower_input) == "string" and {tower_input} or tower_input
    
    if type(tower_table) ~= "table" then
        warn("Equip: Invalid input - expected string or table")
        return
    end

    print("Equipping tower: " .. tostring(tower_input))

    for _, tower_name in ipairs(tower_table) do
        if tower_name == "" then continue end
        
        local args = {
            "Inventory",
            "Equip",
            "tower",
            tower_name
        }
        
        local success, result = pcall(function()
            return remote_func:InvokeServer(unpack(args))
        end)
        
        if success then
            if result == true or (type(result) == "table" and result.Success) or (typeof(result) == "Instance" and result:IsA("Model")) then
                print("Successfully equipped: " .. tower_name)
            else
                warn("Failed to equip: " .. tower_name .. " → " .. tostring(result))
            end
        else
            warn("Error equipping " .. tower_name .. ": " .. tostring(result))
        end
        
        task.wait(0.5)
    end
end

-- ────────────────────────────────────────────────
-- GUI Setup
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Clean up old GUI
if PlayerGui:FindFirstChild("EquipTowerGUI") then
    PlayerGui.EquipTowerGUI:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EquipTowerGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 110)
frame.Position = UDim2.new(0, 15, 0, 15)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

local title = Instance.new("TextLabel")
title.Text = "Tower Equipper"
title.Size = UDim2.new(1, 0, 0, 34)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(220, 220, 220)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 22
title.Parent = frame

local textbox = Instance.new("TextBox")
textbox.PlaceholderText = "Type tower name → Enter"
textbox.Size = UDim2.new(1, -20, 0, 36)
textbox.Position = UDim2.new(0, 10, 0, 44)
textbox.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
textbox.TextColor3 = Color3.fromRGB(220, 220, 220)
textbox.Font = Enum.Font.SourceSans
textbox.TextSize = 18
textbox.TextEditable = true
textbox.ClearTextOnFocus = false
textbox.Text = ""
textbox.Parent = frame
Instance.new("UICorner", textbox).CornerRadius = UDim.new(0, 6)

-- ────────────────────────────────────────────────
-- Enter key handler
textbox.FocusLost:Connect(function(enterPressed)
    if not enterPressed then return end

    local input = textbox.Text:match("^%s*(.-)%s*$") or ""
    if input == "" then
        textbox.Text = ""
        return
    end

    local tower = resolveTower(input)
    if not tower then
        textbox.Text = "Not found: " .. input
        task.delay(2, function() textbox.Text = "" end)
        return
    end

    textbox.Text = "Equipping " .. tower .. "..."

    local success, err = pcall(function()
        TDS:Equip(tower)
    end)

    if success then
        textbox.Text = "Equipped: " .. tower
    else
        textbox.Text = "Error: " .. (tostring(err):match("[^\n]+") or "failed")
    end

    task.delay(2.8, function()
        textbox.Text = ""
    end)
end)

return TDS
