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

    for _, t in ipairs(Normalized) do
        if t.norm == n then return t.raw end
    end
    for _, t in ipairs(Normalized) do
        if t.norm:sub(1, #n) == n then return t.raw end
    end
    for _, t in ipairs(Normalized) do
        for _, w in ipairs(t.words) do
            if w:sub(1, #n) == n then return t.raw end
        end
    end
end

local TDS = {}
shared.TDS_Table = TDS

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local function waitForGame()
    if PlayerGui:FindFirstChild("GameGui") then return true end
    local conn
    conn = PlayerGui.ChildAdded:Connect(function(c)
        if c.Name == "GameGui" then
            conn:Disconnect()
        end
    end)
    repeat task.wait() until PlayerGui:FindFirstChild("GameGui")
    return true
end

function TDS:Addons()
    if not waitForGame() then return false end

    local ok, code = pcall(game.HttpGet, game,
        "https://api.junkie-development.de/api/v1/luascripts/public/57fe397f76043ce06afad24f07528c9f93e97730930242f57134d0b60a2d250b/download"
    )
    if not ok then return false end

    loadstring(code)()

    local start = os.clock()
    repeat
        if os.clock() - start > 8 then return false end
        task.wait()
    until TDS.Equip

    return true
end

if PlayerGui:FindFirstChild("EquipTowerGUI") then
    PlayerGui.EquipTowerGUI:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EquipTowerGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)

local title = Instance.new("TextLabel")
title.Text = "Tower Equipper"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(230, 230, 230)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.Parent = frame

local textbox = Instance.new("TextBox")
textbox.PlaceholderText = "Loading Key System..."
textbox.Size = UDim2.new(1, -20, 0, 30)
textbox.Position = UDim2.new(0, 10, 0, 40)
textbox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
textbox.TextColor3 = Color3.fromRGB(230, 230, 230)
textbox.Font = Enum.Font.SourceSans
textbox.TextSize = 18
textbox.TextEditable = false
textbox.Text = ""
textbox.Parent = frame
Instance.new("UICorner", textbox).CornerRadius = UDim.new(0, 4)

task.spawn(function()
    if TDS:Addons() then
        textbox.PlaceholderText = "Type tower name..."
        textbox.TextEditable = true
    end
end)

textbox.FocusLost:Connect(function(enterPressed)
    if not enterPressed or not TDS.Equip then return end
    local tower = resolveTower(textbox.Text)
    if tower then
        pcall(TDS.Equip, TDS, tower)
    end
    textbox.Text = ""
end)

return TDS
