local times = 1
local h = 6
local event = game:GetService("ReplicatedStorage").RemoteFunction
local Mouse = game.Players.LocalPlayer:GetMouse()
local RunService = game:GetService("RunService")

local function fetchTroops()
    local t = {}
    for i,v in next, game:GetService("ReplicatedStorage").RemoteFunction:InvokeServer("Session", "Search", "Inventory.Troops") do
        if v.Equipped then
            table.insert(t, i)
        end
    end
    return t
end

local troops = fetchTroops()
local upgradeTroop = troops[1]

local function getOwnerId(tower)
    local rep = tower:FindFirstChild("TowerReplicator")
    if rep then
        local id = rep:GetAttribute("OwnerId")
        if id then return id end
    end
    local owner = tower:FindFirstChild("Owner")
    if owner then return owner.Value end
    return nil
end

local function getTowerType(tower)
    local rep = tower:FindFirstChild("TowerReplicator")
    if rep then
        return rep:GetAttribute("Name")
    end
    return nil
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deeeity/mercury-lib/master/src.lua"))()

local gui = Library:create{
    Theme = Library.Themes.Serika
}

local tab = gui:tab{
    Icon = "rbxassetid://6034996695",
    Name = "Main"
}

local stackMode = false
local stackSphere = nil

tab:toggle({
    Name = "Stack Mode",
    StartingText = "Disabled",
    Description = "Toggle visual placing mode",
    Callback = function(v)
        stackMode = v
        if not v and stackSphere then
            stackSphere:Destroy()
            stackSphere = nil
        end
    end
})

tab:slider({
    Name = "Amount",
    Default = 1,
    Min = 1,
    Max = 15,
    Callback = function(v)
        times = v
    end
})

tab:slider({
    Name = "Height",
    Default = 6,
    Min = -8,
    Max = 120,
    Callback = function(v)
        h = v
    end
})

local SetTowerDropdown = tab:dropdown({
    Name = "Set Tower",
    StartingText = upgradeTroop or "Select Tower",
    Items = troops,
    Callback = function(v)
        upgradeTroop = v
    end
})

tab:button({
    Name = "Refresh Towers",
    Callback = function()
        troops = fetchTroops()
        SetTowerDropdown:Clear()
        task.wait(0.5) -- Wait for Clear tween/callback to finish
        SetTowerDropdown:AddItems(troops)
    end
})

tab:button({
    Name = "Upgrade All",
    Callback = function()
        for i,v in pairs(game.Workspace.Towers:GetChildren()) do
            if getOwnerId(v) == game.Players.LocalPlayer.UserId then
                event:InvokeServer("Troops","Upgrade","Set",{["Troop"] = v})
                wait()
            end
        end
    end
})

tab:button({
    Name = "Upgrade Troop",
    Callback = function()
        for i,v in pairs(game.Workspace.Towers:GetChildren()) do
            if getOwnerId(v) == game.Players.LocalPlayer.UserId and getTowerType(v) == upgradeTroop then
                event:InvokeServer("Troops","Upgrade","Set",{["Troop"] = v})
                wait()
            end
        end
    end
})

tab:button({
    Name = "Sell All (DANGER)",
    Caption = "DANGER ZONE",
    Callback = function()
        for i,v in pairs(game.Workspace.Towers:GetChildren()) do
            if getOwnerId(v) == game.Players.LocalPlayer.UserId then
                event:InvokeServer("Troops","Sell",{["Troop"] = v})
                wait()
            end
        end
    end
})

tab:button({
    Name = "Sell All Farms",
    Callback = function()
        for i,v in pairs(game.Workspace.Towers:GetChildren()) do
            if getOwnerId(v) == game.Players.LocalPlayer.UserId and getTowerType(v) == "Farm" then
                event:InvokeServer("Troops","Sell",{["Troop"] = v})
                wait()
            end
        end
    end
})

RunService.RenderStepped:Connect(function()
    if stackMode then
        if not stackSphere then
            stackSphere = Instance.new("Part")
            stackSphere.Shape = Enum.PartType.Ball
            stackSphere.Size = Vector3.new(1, 1, 1)
            stackSphere.Color = Color3.fromRGB(0, 255, 0)
            stackSphere.Transparency = 0.5
            stackSphere.Anchored = true
            stackSphere.CanCollide = false
            stackSphere.Material = Enum.Material.Neon
            stackSphere.Parent = game.Workspace
            Mouse.TargetFilter = stackSphere
        end
        
        local hit = Mouse.Hit
        if hit then
             stackSphere.Position = hit.Position
        end
    elseif stackSphere then
        stackSphere:Destroy()
        stackSphere = nil
    end
end)

Mouse.Button1Down:Connect(function()
    if stackMode and stackSphere then
        local basePos = stackSphere.Position
        
        spawn(function()
             for i = 1, times do
                local newPos = Vector3.new(basePos.X, basePos.Y + (h * i), basePos.Z)
                -- Using the specific unicode remote call found in the original code
                event:InvokeServer("Troops", "Pl\208\176ce", {Rotation = CFrame.new(), Position = newPos}, upgradeTroop)
                wait(0.2)
            end
        end)
    end
end)

-- Mobile Support: Toggle UI Button
local UserInputService = game:GetService("UserInputService")
if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MercuryMobileToggle"
    ScreenGui.Parent = game:GetService("CoreGui")

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Name = "ToggleButton"
    ToggleBtn.Parent = ScreenGui
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    ToggleBtn.Position = UDim2.new(1, -140, 1, -60)
    ToggleBtn.Size = UDim2.new(0, 120, 0, 40)
    ToggleBtn.Font = Enum.Font.SourceSansBold
    ToggleBtn.Text = "Toggle UI"
    ToggleBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
    ToggleBtn.TextSize = 18
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.AutoButtonColor = true
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = ToggleBtn
    
    ToggleBtn.MouseButton1Click:Connect(function()
        Library:show(not Library.Toggled)
    end)
end

-- Toggle UI with Left Control
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.LeftControl then
        Library:show(not Library.Toggled)
    end
end)
