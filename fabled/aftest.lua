--[[
    Roblox Autofarm Script with GUI and robust config
    - Fixes config file reading (preserves existing values, fills missing keys, avoids overwriting on read errors)
    - Adds Orbit toggle (default OFF). When OFF: hover above enemy and look down (top-down). When ON: orbit around enemy.
    - Keeps autofarm and autospell running across death/respawn by re-binding character parts.
    - Removed dodging logic related to Hitbox/indicator entirely.

    Synapse config path: /fabledAutoTest/config.json
    Place as a LocalScript (e.g., StarterPlayerScripts)
--]]

-- Synapse X file functions
local writefile = writefile
local readfile = readfile
local isfile = isfile
local makefolder = makefolder
local isfolder = isfolder

local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local CONFIG_FOLDER = "fabledAutoTest"
local CONFIG_PATH = CONFIG_FOLDER.."/config.json"

local DEFAULT_CONFIG = {
    autofarmActive = false,
    autospellActive = false,
    heightAboveEnemy = 10,
    orbitRadius = 6,
    orbitSpeed = 1.5,
    orbitEnabled = false, -- new option
}

local function deepCopy(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = type(v) == "table" and deepCopy(v) or v
    end
    return copy
end

local function mergeDefaults(parsed, defaults)
    -- Merge defaults into parsed in-place for missing keys only.
    for k, v in pairs(defaults) do
        if parsed[k] == nil then
            parsed[k] = v
        end
    end
    return parsed
end

local function atomicWrite(path, content)
    -- Best-effort atomic save: write to temp then replace
    local tmp = path..".tmp"
    local ok1, err1 = pcall(writefile, tmp, content)
    if ok1 then
        -- overwrite real file
        pcall(writefile, path, content)
    else
        -- fallback to direct write
        pcall(writefile, path, content)
    end
end

local function saveConfig(config)
    local ok, json = pcall(function()
        return HttpService:JSONEncode(config)
    end)
    if ok and json then
        atomicWrite(CONFIG_PATH, json)
    end
end

local function loadConfig()
    if not isfolder(CONFIG_FOLDER) then
        pcall(makefolder, CONFIG_FOLDER)
    end

    if not isfile(CONFIG_PATH) then
        local cfg = deepCopy(DEFAULT_CONFIG)
        saveConfig(cfg)
        return cfg
    end

    local okRead, data = pcall(readfile, CONFIG_PATH)
    if not okRead or type(data) ~= "string" or #data == 0 then
        -- Do not overwrite user's bad file immediately; use defaults in-memory and save a merged fixed file
        local cfg = deepCopy(DEFAULT_CONFIG)
        saveConfig(cfg)
        return cfg
    end

    local okParse, parsed = pcall(function()
        return HttpService:JSONDecode(data)
    end)

    if not okParse or type(parsed) ~= "table" then
        -- Keep user's file content by creating a fixed default config alongside (but overwrite to get script working)
        local cfg = deepCopy(DEFAULT_CONFIG)
        saveConfig(cfg)
        return cfg
    end

    -- Merge missing keys without clobbering existing ones
    local merged = mergeDefaults(parsed, DEFAULT_CONFIG)

    -- Save back only if something changed (missing keys were filled)
    local needSave = false
    for k, v in pairs(DEFAULT_CONFIG) do
        if parsed[k] == nil then
            needSave = true
            break
        end
    end
    if needSave then
        saveConfig(merged)
    end

    return merged
end

-- Load config at start
local config = loadConfig()

-- Services/objects that depend on character; we will rebind on respawn
local character
local humanoid
local humanoidRootPart

local function bindCharacter(char)
    character = char
    humanoid = character:WaitForChild("Humanoid")
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end

-- Initial bind (handles if character not ready yet)
bindCharacter(player.Character or player.CharacterAdded:Wait())

-- Rebind on respawn and keep loops running
player.CharacterAdded:Connect(function(char)
    bindCharacter(char)
end)

-- Game objects
local enemiesFolder = Workspace:WaitForChild("Enemies")

-- Spells
local SPELLS = {"Q", "E"}
local SPELL_INTERVAL = 1 -- seconds between spell casts
local TELEPORT_TIME = 0.5 -- seconds for tween teleport

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
local orbitSpeed = config.orbitSpeed
local orbitEnabled = config.orbitEnabled -- new

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutofarmGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 335)
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

-- Orbit toggle (placed under Autospell as requested)
local orbitToggle = Instance.new("TextButton")
orbitToggle.Size = UDim2.new(0, 230, 0, 30)
orbitToggle.Position = UDim2.new(0, 10, 0, 80)
orbitToggle.BackgroundColor3 = orbitEnabled and Color3.fromRGB(50, 100, 50) or Color3.fromRGB(100, 50, 50)
orbitToggle.Text = "Orbit: " .. (orbitEnabled and "ON" or "OFF")
orbitToggle.TextColor3 = Color3.new(1,1,1)
orbitToggle.Font = Enum.Font.SourceSans
orbitToggle.TextSize = 18
orbitToggle.Parent = frame

local heightLabel = Instance.new("TextLabel")
heightLabel.Size = UDim2.new(0, 120, 0, 25)
heightLabel.Position = UDim2.new(0, 10, 0, 120)
heightLabel.BackgroundTransparency = 1
heightLabel.Text = "Height Above Enemy:"
heightLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
heightLabel.Font = Enum.Font.SourceSans
heightLabel.TextSize = 16
heightLabel.TextXAlignment = Enum.TextXAlignment.Left
heightLabel.Parent = frame

local heightBox = Instance.new("TextBox")
heightBox.Size = UDim2.new(0, 50, 0, 25)
heightBox.Position = UDim2.new(0, 140, 0, 120)
heightBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
heightBox.Text = tostring(heightAboveEnemy)
heightBox.TextColor3 = Color3.new(1,1,1)
heightBox.Font = Enum.Font.SourceSans
heightBox.TextSize = 16
heightBox.ClearTextOnFocus = false
heightBox.Parent = frame

local orbitRadiusLabel = Instance.new("TextLabel")
orbitRadiusLabel.Size = UDim2.new(0, 120, 0, 25)
orbitRadiusLabel.Position = UDim2.new(0, 10, 0, 150)
orbitRadiusLabel.BackgroundTransparency = 1
orbitRadiusLabel.Text = "Orbit Radius:"
orbitRadiusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
orbitRadiusLabel.Font = Enum.Font.SourceSans
orbitRadiusLabel.TextSize = 16
orbitRadiusLabel.TextXAlignment = Enum.TextXAlignment.Left
orbitRadiusLabel.Parent = frame

local orbitRadiusBox = Instance.new("TextBox")
orbitRadiusBox.Size = UDim2.new(0, 50, 0, 25)
orbitRadiusBox.Position = UDim2.new(0, 140, 0, 150)
orbitRadiusBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
orbitRadiusBox.Text = tostring(orbitRadius)
orbitRadiusBox.TextColor3 = Color3.new(1,1,1)
orbitRadiusBox.Font = Enum.Font.SourceSans
orbitRadiusBox.TextSize = 16
orbitRadiusBox.ClearTextOnFocus = false
orbitRadiusBox.Parent = frame

-- Orbit Speed Label and Box
local orbitSpeedLabel = Instance.new("TextLabel")
orbitSpeedLabel.Size = UDim2.new(0, 120, 0, 25)
orbitSpeedLabel.Position = UDim2.new(0, 10, 0, 180)
orbitSpeedLabel.BackgroundTransparency = 1
orbitSpeedLabel.Text = "Orbit Speed:"
orbitSpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
orbitSpeedLabel.Font = Enum.Font.SourceSans
orbitSpeedLabel.TextSize = 16
orbitSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
orbitSpeedLabel.Parent = frame

local orbitSpeedBox = Instance.new("TextBox")
orbitSpeedBox.Size = UDim2.new(0, 50, 0, 25)
orbitSpeedBox.Position = UDim2.new(0, 140, 0, 180)
orbitSpeedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
orbitSpeedBox.Text = tostring(orbitSpeed)
orbitSpeedBox.TextColor3 = Color3.new(1,1,1)
orbitSpeedBox.Font = Enum.Font.SourceSans
orbitSpeedBox.TextSize = 16
orbitSpeedBox.ClearTextOnFocus = false
orbitSpeedBox.Parent = frame

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, -20, 0, 60)
statsLabel.Position = UDim2.new(0, 10, 0, 215)
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
healthStatusLabel.Position = UDim2.new(0, 10, 0, 285)
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
    orbitToggle.AutoButtonColor = state
    orbitToggle.BackgroundColor3 = (orbitEnabled and state) and Color3.fromRGB(50, 100, 50)
        or (state and Color3.fromRGB(100, 50, 50) or Color3.fromRGB(60, 60, 60))

    autofarmToggle.Text = "Autofarm: " .. (autofarmActive and "ON" or "OFF")
    autospellToggle.Text = "Autospell: " .. (autospellActive and "ON" or "OFF")
    orbitToggle.Text = "Orbit: " .. (orbitEnabled and "ON" or "OFF")
end

local function setTextboxesInteractable(state)
    heightBox.TextEditable = state
    heightBox.BackgroundColor3 = state and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(60, 60, 60)
    orbitRadiusBox.TextEditable = state
    orbitRadiusBox.BackgroundColor3 = state and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(60, 60, 60)
    orbitSpeedBox.TextEditable = state
    orbitSpeedBox.BackgroundColor3 = state and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(60, 60, 60)
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
    task.wait(0.1)
    enforceSinglePlayer()
end)

-- GUI Logic
autofarmToggle.MouseButton1Click:Connect(function()
    if not isSinglePlayer() then return end
    autofarmActive = not autofarmActive
    config.autofarmActive = autofarmActive
    saveConfig(config)
    setTogglesInteractable(true)
end)

autospellToggle.MouseButton1Click:Connect(function()
    if not isSinglePlayer() then return end
    autospellActive = not autospellActive
    config.autospellActive = autospellActive
    saveConfig(config)
    setTogglesInteractable(true)
end)

orbitToggle.MouseButton1Click:Connect(function()
    if not isSinglePlayer() then return end
    orbitEnabled = not orbitEnabled
    config.orbitEnabled = orbitEnabled
    saveConfig(config)
    setTogglesInteractable(true)
end)

heightBox.FocusLost:Connect(function()
    if not isSinglePlayer() then
        heightBox.Text = tostring(heightAboveEnemy)
        return
    end
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

orbitRadiusBox.FocusLost:Connect(function()
    if not isSinglePlayer() then
        orbitRadiusBox.Text = tostring(orbitRadius)
        return
    end
    local val = tonumber(orbitRadiusBox.Text)
    if val and val >= 1 then
        orbitRadius = val
        config.orbitRadius = val
        saveConfig(config)
        orbitRadiusBox.Text = tostring(val)
    else
        orbitRadiusBox.Text = tostring(orbitRadius)
    end
end)

orbitSpeedBox.FocusLost:Connect(function()
    if not isSinglePlayer() then
        orbitSpeedBox.Text = tostring(orbitSpeed)
        return
    end
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
    if not humanoidRootPart then return nil end
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

local function tweenToCFrame(cf, duration)
    if not humanoidRootPart then return end
    humanoidRootPart.Anchored = false
    local tween = TweenService:Create(
        humanoidRootPart,
        TweenInfo.new(duration or TELEPORT_TIME, Enum.EasingStyle.Linear),
        { CFrame = cf }
    )
    tween:Play()
    tween.Completed:Wait()
end

local function tweenAboveEnemy(enemy, height)
    local enemyPos = enemy.HumanoidRootPart.Position
    local cf = CFrame.new(enemyPos + Vector3.new(0, height, 0))
    tweenToCFrame(cf, TELEPORT_TIME)
end

-- Non-orbit behavior: hold above enemy and face downwards
local function hoverTopDown(enemy, height)
    -- We do not anchor permanently; just gently correct position and orientation
    while enemy.Parent == enemiesFolder and enemy.Humanoid.Health > 0 do
        if not autofarmActive then break end
        if not humanoid or not humanoidRootPart then break end
        -- Health pause handled outside
        local enemyPos = enemy.HumanoidRootPart.Position + Vector3.new(0, height, 0)
        -- Face straight downward (top-down look) while keeping position above enemy
        -- Construct CFrame that looks downward; we can keep XZ orientation stable by using -Y vector
        local lookDown = Vector3.new(0, -1, 0)
        local currentPos = humanoidRootPart.Position
        local moveNeeded = (currentPos - enemyPos).Magnitude > 1.5
        if moveNeeded then
            tweenToCFrame(CFrame.new(enemyPos, enemyPos + lookDown), 0.2)
        else
            -- Just adjust orientation to look down
            humanoidRootPart.CFrame = CFrame.new(enemyPos, enemyPos + lookDown)
        end
        RunService.RenderStepped:Wait()
    end
end

-- Orbit logic
local function orbitAroundEnemy(enemy, height, radius, speed)
    if not humanoidRootPart then return end
    local angle = math.random() * math.pi * 2
    while enemy.Parent == enemiesFolder and enemy.Humanoid.Health > 0 do
        if not autofarmActive then break end
        if not humanoid or not humanoidRootPart then break end
        local dt = RunService.RenderStepped:Wait()
        angle = angle + speed * dt
        local enemyPos = enemy.HumanoidRootPart.Position
        local offset = Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
        local targetPos = enemyPos + offset
        humanoidRootPart.CFrame = CFrame.new(targetPos, enemyPos)
    end
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
    tempPlatform.Position = humanoidRootPart and (humanoidRootPart.Position + TEMP_PLATFORM_OFFSET) or Vector3.new(0, 200, 0)
    tempPlatform.Parent = Workspace
    return tempPlatform
end

local function removeTempPlatform()
    if tempPlatform and tempPlatform.Parent then
        tempPlatform:Destroy()
        tempPlatform = nil
    end
end

local function moveToTempPlatform()
    if not humanoidRootPart then return end
    local platform = createTempPlatform()
    local above = platform.Position + Vector3.new(0, 4, 0)
    humanoidRootPart.Anchored = false
    humanoidRootPart.CFrame = CFrame.new(above)
end

-- Health monitor flags
local autofarmPausedForHealth = false

local function shouldPauseForHealth()
    if not humanoid or not humanoid.MaxHealth or humanoid.MaxHealth == 0 then return false end
    return humanoid.Health / humanoid.MaxHealth < LOW_HEALTH_THRESHOLD
end

local function shouldResumeForHealth()
    if not humanoid or not humanoid.MaxHealth or humanoid.MaxHealth == 0 then return true end
    return humanoid.Health / humanoid.MaxHealth > SAFE_HEALTH_THRESHOLD
end

-- Autofarm loop
local currentTarget = nil
task.spawn(function()
    while true do
        -- Rebind guards (in case character became nil between respawns)
        if not character or not character.Parent then
            -- Wait for character added handled via event; small delay to avoid busy loop
            task.wait(0.2)
        end

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
            task.wait(0.5)
        end

        if autofarmActive and isSinglePlayer() then
            local enemy = getNearestEnemy()
            currentTarget = enemy
            if enemy and humanoidRootPart then
                tweenAboveEnemy(enemy, heightAboveEnemy)
                -- gently approach above point
                while enemy.Parent == enemiesFolder and enemy.Humanoid.Health > 0 and autofarmActive and not autofarmPausedForHealth and isSinglePlayer() do
                    if shouldPauseForHealth() then
                        autofarmPausedForHealth = true
                        healthStatusLabel.Text = "Low HP! Waiting to heal..."
                        moveToTempPlatform()
                        break
                    end
                    if not humanoidRootPart then break end
                    local targetPos = enemy.HumanoidRootPart.Position + Vector3.new(0, heightAboveEnemy, 0)
                    local dist = (humanoidRootPart.Position - targetPos).Magnitude
                    if dist <= 1.5 then
                        break
                    end
                    tweenToCFrame(CFrame.new(targetPos), 0.2)
                    task.wait(0.2)
                end

                if enemy.Parent == enemiesFolder and enemy.Humanoid.Health > 0 and autofarmActive and not autofarmPausedForHealth and isSinglePlayer() then
                    if orbitEnabled then
                        orbitAroundEnemy(enemy, heightAboveEnemy, orbitRadius, orbitSpeed)
                    else
                        hoverTopDown(enemy, heightAboveEnemy)
                    end
                end
            else
                task.wait(0.5)
            end
        else
            currentTarget = nil
            task.wait(0.5)
        end
    end
end)

-- Auto spell loop (persists across respawn)
task.spawn(function()
    while true do
        if autospellActive and not autofarmPausedForHealth and isSinglePlayer() then
            for _, spell in ipairs(SPELLS) do
                if autospellActive and not autofarmPausedForHealth and isSinglePlayer() then
                    pcall(function()
                        ReplicatedStorage:WaitForChild("useSpell"):FireServer(spell)
                    end)
                end
                task.wait(SPELL_INTERVAL)
            end
        else
            task.wait(0.2)
        end
    end
end)

-- Stats update loop
task.spawn(function()
    while true do
        local targetName = currentTarget and currentTarget.Name or "None"
        statsLabel.Text = string.format(
            "Target: %s\nAutofarm: %s\nAutospell: %s\nOrbit: %s\nHeight: %d\nOrbit Radius: %d\nOrbit Speed: %.2f",
            targetName,
            autofarmActive and "ON" or "OFF",
            autospellActive and "ON" or "OFF",
            orbitEnabled and "ON" or "OFF",
            heightAboveEnemy,
            orbitRadius,
            orbitSpeed
        )
        task.wait(0.2)
    end
end)
