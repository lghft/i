
--[[
    Roblox Autofarm Script with GUI, Toggles, Height, and Orbit Radius Setting
    - Tweens above the enemy at configurable height
    - Orbits (rotates) around the enemy while facing it when close, with configurable radius
    - Pauses autofarm and teleports to a temp platform if HP < 45%, resumes at > 90%
    - GUI for stats, toggles, height, and orbit radius input
    - Open/close button on right side of screen (no H keybind)
    - Only works if there is exactly 1 player in the game (auto disables otherwise)
    - Persists settings in Synapse config file: /fabledAutoTest/config.json
    Place as a LocalScript (e.g., StarterPlayerScripts)
--]]

-- Synapse X file functions
local writefile = writefile
local readfile = readfile
local isfile = isfile
local makefolder = makefolder
local isfolder = isfolder

local CONFIG_FOLDER = "fabledAutoTest"
local CONFIG_PATH = CONFIG_FOLDER.."/config.json"

local DEFAULT_CONFIG = {
    autofarmActive = false,
    autospellActive = false,
    heightAboveEnemy = 10,
    orbitRadius = 6
}

local function deepCopy(tbl)
    local copy = {}
    for k,v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function saveConfig(config)
    local json = game:GetService("HttpService"):JSONEncode(config)
    writefile(CONFIG_PATH, json)
end

local function loadConfig()
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
    if not isfile(CONFIG_PATH) then
        saveConfig(DEFAULT_CONFIG)
        return deepCopy(DEFAULT_CONFIG)
    end
    local ok, data = pcall(readfile, CONFIG_PATH)
    if not ok or not data then
        saveConfig(DEFAULT_CONFIG)
        return deepCopy(DEFAULT_CONFIG)
    end
    local ok2, parsed = pcall(function()
        return game:GetService("HttpService"):JSONDecode(data)
    end)
    if not ok2 or type(parsed) ~= "table" then
        saveConfig(DEFAULT_CONFIG)
        return deepCopy(DEFAULT_CONFIG)
    end
    -- Fill in missing keys
    for k,v in pairs(DEFAULT_CONFIG) do
        if parsed[k] == nil then
            parsed[k] = v
        end
    end
    return parsed
end

-- Load config at start
local config = loadConfig()

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Enemy search now uses all enemyFolder folders under workspace.dungeon
local dungeon = workspace:WaitForChild("dungeon")

local SPELLS = {"Q", "E"}
local SPELL_INTERVAL = 1 -- seconds between spell casts
local TELEPORT_TIME = 0.5 -- seconds for tween teleport

-- Orbit settings
local ORBIT_SPEED = 1.5 -- radians/sec
local ORBIT_DISTANCE_THRESHOLD = 1.5 -- how close before orbit starts

-- Health thresholds
local SAFE_HEALTH_THRESHOLD = 0.50
local LOW_HEALTH_THRESHOLD = 0.45

-- Temp platform settings
local TEMP_PLATFORM_SIZE = Vector3.new(12, 1, 12)
local TEMP_PLATFORM_OFFSET = Vector3.new(0, 50, 0) -- 50 studs above current position

-- State (from config)
local autofarmActive = config.autofarmActive
local autospellActive = config.autospellActive
local heightAboveEnemy = config.heightAboveEnemy
local orbitRadius = config.orbitRadius

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutofarmGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 260)
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

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, -20, 0, 60)
statsLabel.Position = UDim2.new(0, 10, 0, 150)
statsLabel.BackgroundTransparency = 1
statsLabel.Text = ""
statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statsLabel.Font = Enum.Font.SourceSans
statsLabel.TextSize = 16
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.TextWrapped = true
statsLabel.Parent = frame

local healthStatusLabel = Instance.new("TextLabel")
healthStatusLabel.Size = UDim2.new(1, -20, 0, 20)
healthStatusLabel.Position = UDim2.new(0, 10, 0, 215)
healthStatusLabel.BackgroundTransparency = 1
healthStatusLabel.Text = ""
healthStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
healthStatusLabel.Font = Enum.Font.SourceSansBold
healthStatusLabel.TextSize = 16
healthStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
healthStatusLabel.Parent = frame

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

-- Player count restriction logic
local function isSinglePlayer()
    return #Players:GetPlayers() == 1
end

local function setTogglesInteractable(state)
    autofarmToggle.AutoButtonColor = state
    autofarmToggle.BackgroundColor3 = (autofarmActive and state) and Color3.fromRGB(50, 100, 50)
        or (state and Color3.fromRGB(100, 50, 50) or Color3.fromRGB(60, 60, 60))
    autospellToggle.AutoButtonColor = state
    autospellToggle.BackgroundColor3 = (autospellActive and state) and Color3.fromRGB(50, 50, 100)
        or (state and Color3.fromRGB(100, 50, 50) or Color3.fromRGB(60, 60, 60))
    autofarmToggle.Text = "Autofarm: " .. (autofarmActive and "ON" or "OFF")
    autospellToggle.Text = "Autospell: " .. (autospellActive and "ON" or "OFF")
end

local function setTextboxesInteractable(state)
    heightBox.TextEditable = state
    heightBox.BackgroundColor3 = state and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(60, 60, 60)
    orbitRadiusBox.TextEditable = state
    orbitRadiusBox.BackgroundColor3 = state and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(60, 60, 60)
end

local function enforceSinglePlayer()
    if isSinglePlayer() then
        setTogglesInteractable(true)
        setTextboxesInteractable(true)
        healthStatusLabel.Text = ""
    else
        -- Auto-disable toggles and lock them
        autofarmActive = false
        autospellActive = false
        setTogglesInteractable(false)
        setTextboxesInteractable(false)
        healthStatusLabel.Text = "Disabled: More than 1 player in game!"
        -- Save config with toggles off
        config.autofarmActive = false
        config.autospellActive = false
        saveConfig(config)
    end
end

-- Initial enforce
enforceSinglePlayer()

-- Listen for player join/leave
Players.PlayerAdded:Connect(enforceSinglePlayer)
Players.PlayerRemoving:Connect(function()
    -- Delay to allow player list to update
    wait(0.1)
    enforceSinglePlayer()
end)

-- GUI Logic
autofarmToggle.MouseButton1Click:Connect(function()
    if not isSinglePlayer() then return end
    autofarmActive = not autofarmActive
    autofarmToggle.Text = "Autofarm: " .. (autofarmActive and "ON" or "OFF")
    autofarmToggle.BackgroundColor3 = autofarmActive and Color3.fromRGB(50, 100, 50) or Color3.fromRGB(100, 50, 50)
    config.autofarmActive = autofarmActive
    saveConfig(config)
end)

autospellToggle.MouseButton1Click:Connect(function()
    if not isSinglePlayer() then return end
    autospellActive = not autospellActive
    autospellToggle.Text = "Autospell: " .. (autospellActive and "ON" or "OFF")
    autospellToggle.BackgroundColor3 = autospellActive and Color3.fromRGB(50, 50, 100) or Color3.fromRGB(100, 50, 50)
    config.autospellActive = autospellActive
    saveConfig(config)
end)

heightBox.FocusLost:Connect(function(enterPressed)
    if not isSinglePlayer() then
        heightBox.Text = tostring(heightAboveEnemy)
        return
    end
    local val = tonumber(heightBox.Text)
    if val and val >= 0 then
        heightAboveEnemy = val
        heightBox.Text = tostring(val)
        config.heightAboveEnemy = val
        saveConfig(config)
    else
        heightBox.Text = tostring(heightAboveEnemy)
    end
end)

orbitRadiusBox.FocusLost:Connect(function(enterPressed)
    if not isSinglePlayer() then
        orbitRadiusBox.Text = tostring(orbitRadius)
        return
    end
    local val = tonumber(orbitRadiusBox.Text)
    if val and val >= 1 then
        orbitRadius = val
        orbitRadiusBox.Text = tostring(val)
        config.orbitRadius = val
        saveConfig(config)
    else
        orbitRadiusBox.Text = tostring(orbitRadius)
    end
end)

-- Enemy search helpers (NEW)
local function isEnemyAlive(enemy)
    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function getAliveEnemies()
    local alive = {}
    for _, folder in pairs(dungeon:GetDescendants()) do
        if folder.Name == "enemyFolder" then
            for _, enemy in pairs(folder:GetChildren()) do
                if enemy:IsA("Model") and isEnemyAlive(enemy) and enemy:FindFirstChild("HumanoidRootPart") then
                    table.insert(alive, enemy)
                end
            end
        end
    end
    return alive
end

local function getNearestEnemy()
    local alive = getAliveEnemies()
    local nearest, minDist = nil, math.huge
    local characterPivot = humanoidRootPart.Position
    for _, enemy in ipairs(alive) do
        local enemyPivot = enemy:FindFirstChild("HumanoidRootPart").Position
        local dist = (characterPivot - enemyPivot).Magnitude
        if dist < minDist then
            minDist = dist
            nearest = enemy
        end
    end
    return nearest
end

local function tweenAboveEnemy(enemy, height)
    humanoidRootPart.Anchored = false -- Unanchor before tweening
    local goal = {}
    local enemyPos = enemy:FindFirstChild("HumanoidRootPart").Position
    goal.CFrame = CFrame.new(enemyPos + Vector3.new(0, height, 0))
    local tween = TweenService:Create(
        humanoidRootPart,
        TweenInfo.new(TELEPORT_TIME, Enum.EasingStyle.Linear),
        goal
    )
    tween:Play()
    tween.Completed:Wait()
end

-- Orbit logic with anchoring for stability
local function orbitAroundEnemy(enemy, height, radius, speed)
    humanoidRootPart.Anchored = true -- Anchor for stable orbit
    local angle = math.random() * math.pi * 2
    while enemy.Parent and isEnemyAlive(enemy) and autofarmActive do
        if humanoid.Health / humanoid.MaxHealth < LOW_HEALTH_THRESHOLD then
            break
        end
        local dt = RunService.RenderStepped:Wait()
        angle = angle + speed * dt
        local enemyPos = enemy:FindFirstChild("HumanoidRootPart").Position
        local offset = Vector3.new(
            math.cos(angle) * radius,
            height,
            math.sin(angle) * radius
        )
        local targetPos = enemyPos + offset
        humanoidRootPart.CFrame = CFrame.new(targetPos, enemyPos)
    end
    humanoidRootPart.Anchored = false -- Unanchor after orbit
end

-- Temp platform logic
local tempPlatform = nil
local function createTempPlatform()
    if tempPlatform and tempPlatform.Parent then return tempPlatform end
    tempPlatform = Instance.new("Part")
    tempPlatform.Name = "SafePlatform"
    tempPlatform.Size = TEMP_PLATFORM_SIZE
    tempPlatform.Anchored = true
    tempPlatform.CanCollide = true
    tempPlatform.Transparency = 0.2
    tempPlatform.Color = Color3.fromRGB(100, 200, 255)
    tempPlatform.Position = humanoidRootPart.Position + TEMP_PLATFORM_OFFSET
    tempPlatform.Parent = workspace
    return tempPlatform
end

local function removeTempPlatform()
    if tempPlatform and tempPlatform.Parent then
        tempPlatform:Destroy()
        tempPlatform = nil
    end
end

local function moveToTempPlatform()
    humanoidRootPart.Anchored = false -- Unanchor before teleporting
    local platform = createTempPlatform()
    local above = platform.Position + Vector3.new(0, 4, 0)
    humanoidRootPart.CFrame = CFrame.new(above)
end

-- Health monitor and autofarm pause/resume
local autofarmPausedForHealth = false

local function shouldPauseForHealth()
    return humanoid.Health / humanoid.MaxHealth < LOW_HEALTH_THRESHOLD
end

local function shouldResumeForHealth()
    return humanoid.Health / humanoid.MaxHealth > SAFE_HEALTH_THRESHOLD
end

-- Autofarm loop
local currentTarget = nil
spawn(function()
    while true do
        -- Health check
        if shouldPauseForHealth() and not autofarmPausedForHealth then
            autofarmPausedForHealth = true
            healthStatusLabel.Text = "Low HP! Waiting to heal..."
            moveToTempPlatform()
        end

        while autofarmPausedForHealth do
            moveToTempPlatform()
            if shouldResumeForHealth() then
                autofarmPausedForHealth = false
                healthStatusLabel.Text = ""
                removeTempPlatform()
            end
            wait(0.5)
        end

        if autofarmActive and isSinglePlayer() then
            local enemy = getNearestEnemy()
            currentTarget = enemy
            if enemy then
                tweenAboveEnemy(enemy, heightAboveEnemy)
                while enemy.Parent and isEnemyAlive(enemy) and autofarmActive and not autofarmPausedForHealth and isSinglePlayer() do
                    if shouldPauseForHealth() then
                        autofarmPausedForHealth = true
                        healthStatusLabel.Text = "Low HP! Waiting to heal..."
                        moveToTempPlatform()
                        break
                    end
                    local enemyPos = enemy:FindFirstChild("HumanoidRootPart").Position + Vector3.new(0, heightAboveEnemy, 0)
                    local dist = (humanoidRootPart.Position - enemyPos).Magnitude
                    if dist <= ORBIT_DISTANCE_THRESHOLD then
                        break
                    end
                    local goal = {}
                    goal.CFrame = CFrame.new(enemyPos)
                    TweenService:Create(
                        humanoidRootPart,
                        TweenInfo.new(0.2, Enum.EasingStyle.Linear),
                        goal
                    ):Play()
                    wait(0.2)
                end
                if enemy.Parent and isEnemyAlive(enemy) and autofarmActive and not autofarmPausedForHealth and isSinglePlayer() then
                    orbitAroundEnemy(enemy, heightAboveEnemy, orbitRadius, ORBIT_SPEED)
                end
            else
                wait(0.5)
            end
        else
            currentTarget = nil
            wait(0.5)
        end
    end
end)

-- Stats update loop
spawn(function()
    while true do
        local targetName = currentTarget and currentTarget.Name or "None"
        statsLabel.Text = string.format(
            "Target: %s\nAutofarm: %s\nAutospell: %s\nHeight: %d\nOrbit Radius: %d",
            targetName,
            autofarmActive and "ON" or "OFF",
            autospellActive and "ON" or "OFF",
            heightAboveEnemy,
            orbitRadius
        )
        wait(0.2)
    end
end)
