
--[[
    Roblox Autofarm Script with GUI, Toggles, Height Setting, Orbit, and Persistent Config
    - Tweens above and orbits around the enemy at configurable height/radius/speed
    - Always faces the enemy while orbiting
    - GUI for stats, toggles, height, orbit radius/speed, and open/close button
    - Persistent config using Synapse X's makefolder/readfile/writefile
    Place as a LocalScript (e.g., StarterPlayerScripts)
--]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local enemiesFolder = workspace:WaitForChild("Enemies")
local remainingEnemies = enemiesFolder:WaitForChild("remainingEnemies")

-- Synapse config
local CONFIG_FOLDER = "fabledAutoTest"
local CONFIG_FILE = CONFIG_FOLDER .. "/config.json"

local function synSafe(f, ...)
    local ok, res = pcall(f, ...)
    return ok and res or nil
end

local function loadConfig()
    synSafe(makefolder, CONFIG_FOLDER)
    local default = {
        autofarmActive = true,
        autospellActive = true,
        heightAboveEnemy = 10,
        orbitRadius = 6,
        orbitSpeed = 1.5, -- radians/sec
    }
    local data = synSafe(readfile, CONFIG_FILE)
    if data then
        local ok, decoded = pcall(function() return game:GetService("HttpService"):JSONDecode(data) end)
        if ok and type(decoded) == "table" then
            for k, v in pairs(default) do
                if decoded[k] == nil then decoded[k] = v end
            end
            return decoded
        end
    end
    synSafe(writefile, CONFIG_FILE, game:GetService("HttpService"):JSONEncode(default))
    return default
end

local function saveConfig(cfg)
    synSafe(writefile, CONFIG_FILE, game:GetService("HttpService"):JSONEncode(cfg))
end

local config = loadConfig()
local autofarmActive = config.autofarmActive
local autospellActive = config.autospellActive
local heightAboveEnemy = config.heightAboveEnemy
local orbitRadius = config.orbitRadius
local orbitSpeed = config.orbitSpeed

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutofarmGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 270, 0, 260)
frame.Position = UDim2.new(0, 20, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Autofarm Controls"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.Parent = frame

local autofarmToggle = Instance.new("TextButton")
autofarmToggle.Size = UDim2.new(0, 110, 0, 30)
autofarmToggle.Position = UDim2.new(0, 10, 0, 40)
autofarmToggle.BackgroundColor3 = autofarmActive and Color3.fromRGB(50, 100, 50) or Color3.fromRGB(100, 50, 50)
autofarmToggle.Text = "Autofarm: " .. (autofarmActive and "ON" or "OFF")
autofarmToggle.TextColor3 = Color3.new(1,1,1)
autofarmToggle.Font = Enum.Font.SourceSans
autofarmToggle.TextSize = 18
autofarmToggle.Parent = frame

local autospellToggle = Instance.new("TextButton")
autospellToggle.Size = UDim2.new(0, 110, 0, 30)
autospellToggle.Position = UDim2.new(0, 130, 0, 40)
autospellToggle.BackgroundColor3 = autospellActive and Color3.fromRGB(50, 50, 100) or Color3.fromRGB(100, 50, 50)
autospellToggle.Text = "Autospell: " .. (autospellActive and "ON" or "OFF")
autospellToggle.TextColor3 = Color3.new(1,1,1)
autospellToggle.Font = Enum.Font.SourceSans
autospellToggle.TextSize = 18
autospellToggle.Parent = frame

local heightLabel = Instance.new("TextLabel")
heightLabel.Size = UDim2.new(0, 120, 0, 25)
heightLabel.Position = UDim2.new(0, 10, 0, 80)
heightLabel.BackgroundTransparency = 1
heightLabel.Text = "Height Above Enemy:"
heightLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
heightLabel.Font = Enum.Font.SourceSans
heightLabel.TextSize = 16
heightLabel.TextXAlignment = Enum.TextXAlignment.Left
heightLabel.Parent = frame

local heightBox = Instance.new("TextBox")
heightBox.Size = UDim2.new(0, 50, 0, 25)
heightBox.Position = UDim2.new(0, 140, 0, 80)
heightBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
heightBox.Text = tostring(heightAboveEnemy)
heightBox.TextColor3 = Color3.new(1,1,1)
heightBox.Font = Enum.Font.SourceSans
heightBox.TextSize = 16
heightBox.ClearTextOnFocus = false
heightBox.Parent = frame

local orbitRadiusLabel = Instance.new("TextLabel")
orbitRadiusLabel.Size = UDim2.new(0, 120, 0, 25)
orbitRadiusLabel.Position = UDim2.new(0, 10, 0, 110)
orbitRadiusLabel.BackgroundTransparency = 1
orbitRadiusLabel.Text = "Orbit Radius:"
orbitRadiusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
orbitRadiusLabel.Font = Enum.Font.SourceSans
orbitRadiusLabel.TextSize = 16
orbitRadiusLabel.TextXAlignment = Enum.TextXAlignment.Left
orbitRadiusLabel.Parent = frame

local orbitRadiusBox = Instance.new("TextBox")
orbitRadiusBox.Size = UDim2.new(0, 50, 0, 25)
orbitRadiusBox.Position = UDim2.new(0, 140, 0, 110)
orbitRadiusBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
orbitRadiusBox.Text = tostring(orbitRadius)
orbitRadiusBox.TextColor3 = Color3.new(1,1,1)
orbitRadiusBox.Font = Enum.Font.SourceSans
orbitRadiusBox.TextSize = 16
orbitRadiusBox.ClearTextOnFocus = false
orbitRadiusBox.Parent = frame

local orbitSpeedLabel = Instance.new("TextLabel")
orbitSpeedLabel.Size = UDim2.new(0, 120, 0, 25)
orbitSpeedLabel.Position = UDim2.new(0, 10, 0, 140)
orbitSpeedLabel.BackgroundTransparency = 1
orbitSpeedLabel.Text = "Orbit Speed:"
orbitSpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
orbitSpeedLabel.Font = Enum.Font.SourceSans
orbitSpeedLabel.TextSize = 16
orbitSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
orbitSpeedLabel.Parent = frame

local orbitSpeedBox = Instance.new("TextBox")
orbitSpeedBox.Size = UDim2.new(0, 50, 0, 25)
orbitSpeedBox.Position = UDim2.new(0, 140, 0, 140)
orbitSpeedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
orbitSpeedBox.Text = tostring(orbitSpeed)
orbitSpeedBox.TextColor3 = Color3.new(1,1,1)
orbitSpeedBox.Font = Enum.Font.SourceSans
orbitSpeedBox.TextSize = 16
orbitSpeedBox.ClearTextOnFocus = false
orbitSpeedBox.Parent = frame

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, -20, 0, 60)
statsLabel.Position = UDim2.new(0, 10, 0, 175)
statsLabel.BackgroundTransparency = 1
statsLabel.Text = ""
statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statsLabel.Font = Enum.Font.SourceSans
statsLabel.TextSize = 16
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.TextWrapped = true
statsLabel.Parent = frame

-- Open/Close GUI Button (right side)
local openCloseBtn = Instance.new("TextButton")
openCloseBtn.Size = UDim2.new(0, 40, 0, 40)
openCloseBtn.Position = UDim2.new(1, -50, 0, 10)
openCloseBtn.AnchorPoint = Vector2.new(0, 0)
openCloseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
openCloseBtn.Text = "⏷"
openCloseBtn.TextColor3 = Color3.new(1,1,1)
openCloseBtn.Font = Enum.Font.SourceSansBold
openCloseBtn.TextSize = 28
openCloseBtn.Parent = screenGui

local guiOpen = true
local function setGuiOpen(open)
    guiOpen = open
    frame.Visible = open
    openCloseBtn.Text = open and "⏷" or "⏶"
end
setGuiOpen(true)
openCloseBtn.MouseButton1Click:Connect(function()
    setGuiOpen(not guiOpen)
end)

-- GUI Logic
autofarmToggle.MouseButton1Click:Connect(function()
    autofarmActive = not autofarmActive
    autofarmToggle.Text = "Autofarm: " .. (autofarmActive and "ON" or "OFF")
    autofarmToggle.BackgroundColor3 = autofarmActive and Color3.fromRGB(50, 100, 50) or Color3.fromRGB(100, 50, 50)
    config.autofarmActive = autofarmActive
    saveConfig(config)
end)

autospellToggle.MouseButton1Click:Connect(function()
    autospellActive = not autospellActive
    autospellToggle.Text = "Autospell: " .. (autospellActive and "ON" or "OFF")
    autospellToggle.BackgroundColor3 = autospellActive and Color3.fromRGB(50, 50, 100) or Color3.fromRGB(100, 50, 50)
    config.autospellActive = autospellActive
    saveConfig(config)
end)

heightBox.FocusLost:Connect(function(enterPressed)
    local val = tonumber(heightBox.Text)
    if val and val >= 0 then
        heightAboveEnemy = val
        config.heightAboveEnemy = val
        saveConfig(config)
        heightBox.Text = tostring(val)
    else
        heightBox.Text = tostring(heightAboveEnemy)
    end
end)

orbitRadiusBox.FocusLost:Connect(function(enterPressed)
    local val = tonumber(orbitRadiusBox.Text)
    if val and val >= 0 then
        orbitRadius = val
        config.orbitRadius = val
        saveConfig(config)
        orbitRadiusBox.Text = tostring(val)
    else
        orbitRadiusBox.Text = tostring(orbitRadius)
    end
end)

orbitSpeedBox.FocusLost:Connect(function(enterPressed)
    local val = tonumber(orbitSpeedBox.Text)
    if val and val > 0 then
        orbitSpeed = val
        config.orbitSpeed = val
        saveConfig(config)
        orbitSpeedBox.Text = tostring(val)
    else
        orbitSpeedBox.Text = tostring(orbitSpeed)
    end
end)

-- Helper functions
local function getAliveEnemies()
    local alive = {}
    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") then
            if enemy.Humanoid.Health > 0 then
                table.insert(alive, enemy)
            end
        end
    end
    return alive
end

local function getNearestEnemy()
    local alive = getAliveEnemies()
    local nearest, minDist = nil, math.huge
    for _, enemy in ipairs(alive) do
        local dist = (humanoidRootPart.Position - enemy.HumanoidRootPart.Position).Magnitude
        if dist < minDist then
            minDist = dist
            nearest = enemy
        end
    end
    return nearest
end

-- Orbiting logic
local orbiting = false
local orbitAngle = 0
local currentTarget = nil

local function orbitAboveEnemy(enemy, height, radius, speed)
    orbiting = true
    orbitAngle = math.random() * math.pi * 2 -- randomize start angle
    while enemy.Parent == enemiesFolder and enemy.Humanoid.Health > 0 and autofarmActive and currentTarget == enemy do
        -- Calculate orbit position
        orbitAngle = orbitAngle + speed * RunService.RenderStepped:Wait()
        local enemyPos = enemy.HumanoidRootPart.Position
        local offset = Vector3.new(
            math.cos(orbitAngle) * radius,
            height,
            math.sin(orbitAngle) * radius
        )
        local targetPos = enemyPos + offset
        -- Face the enemy
        local lookAt = CFrame.new(targetPos, enemyPos)
        humanoidRootPart.CFrame = lookAt
    end
    orbiting = false
end

-- Autofarm loop
spawn(function()
    while true do
        if autofarmActive and remainingEnemies.Value > 0 then
            local enemy = getNearestEnemy()
            currentTarget = enemy
            if enemy then
                -- Tween above enemy to start orbit
                local enemyPos = enemy.HumanoidRootPart.Position
                local startPos = enemyPos + Vector3.new(0, heightAboveEnemy, orbitRadius)
                local goal = {CFrame = CFrame.new(startPos, enemyPos)}
                local tween = TweenService:Create(
                    humanoidRootPart,
                    TweenInfo.new(0.5, Enum.EasingStyle.Linear),
                    goal
                )
                tween:Play()
                tween.Completed:Wait()
                -- Orbit and face enemy
                orbitAboveEnemy(enemy, heightAboveEnemy, orbitRadius, orbitSpeed)
            else
                wait(0.5)
            end
        else
            currentTarget = nil
            wait(0.5)
        end
    end
end)

-- Auto spell loop
local SPELLS = {"Q", "E"}
local SPELL_INTERVAL = 1
spawn(function()
    while true do
        if autospellActive then
            for _, spell in ipairs(SPELLS) do
                if autospellActive then
                    ReplicatedStorage:WaitForChild("useSpell"):FireServer(spell)
                end
                wait(SPELL_INTERVAL)
            end
        else
            wait(0.2)
        end
    end
end)

-- Stats update loop
spawn(function()
    while true do
        local targetName = currentTarget and currentTarget.Name or "None"
        statsLabel.Text = string.format(
            "Target: %s\nRemaining Enemies: %d\nAutofarm: %s\nAutospell: %s\nHeight: %d\nOrbit Radius: %.1f\nOrbit Speed: %.2f",
            targetName,
            remainingEnemies.Value,
            autofarmActive and "ON" or "OFF",
            autospellActive and "ON" or "OFF",
            heightAboveEnemy,
            orbitRadius,
            orbitSpeed
        )
        wait(0.2)
    end
end)

-- Remove old H keybind logic (now handled by open/close button)
