--[[
    Roblox Autofarm Script with Synapse File Config and GUI Toggle Button
    - Uses Synapse X's makefolder, readfile, writefile for config persistence
    - Config stored in workspace/fabledAutoTest/config.json
    - GUI open/close button on right side of screen (no keybind)
    - Smooth above-enemy tweening, smart dodge, and full GUI/config system
    Place as a LocalScript (e.g., StarterPlayerScripts)
--]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local enemiesFolder = workspace:WaitForChild("Enemies")
local remainingEnemies = enemiesFolder:WaitForChild("remainingEnemies")

local SPELLS = {"Q", "E"}
local SPELL_INTERVAL = 1 -- seconds between spell casts
local TELEPORT_TIME = 0.5 -- seconds for tween teleport
local EVADE_BUFFER = 3 -- studs to move outside the indicator's bounds

-- Synapse config path
local CONFIG_FOLDER = "fabledAutoTest"
local CONFIG_PATH = CONFIG_FOLDER.."/config.json"

-- Synapse file helpers
local function ensureFolder()
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
end

local function saveConfigFile(tbl)
    ensureFolder()
    writefile(CONFIG_PATH, HttpService:JSONEncode(tbl))
end

local function loadConfigFile()
    ensureFolder()
    if isfile(CONFIG_PATH) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_PATH))
        end)
        if ok and type(data) == "table" then
            return data
        end
    end
    return nil
end

-- Config system (persistent via file)
local defaultConfig = {
    autofarmActive = true,
    autospellActive = true,
    heightAboveEnemy = 10,
}
local config = table.clone(defaultConfig)

local function saveConfig()
    saveConfigFile(config)
end

local function loadConfig()
    local loaded = loadConfigFile()
    if loaded then
        for k, v in pairs(defaultConfig) do
            if loaded[k] ~= nil then
                config[k] = loaded[k]
            end
        end
    end
end

local function resetConfig()
    for k, v in pairs(defaultConfig) do
        config[k] = v
    end
    saveConfig()
end

loadConfig()

-- State
local autofarmActive = config.autofarmActive
local autospellActive = config.autospellActive
local heightAboveEnemy = config.heightAboveEnemy
local evading = false

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
frame.Visible = true
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

local saveButton = Instance.new("TextButton")
saveButton.Size = UDim2.new(0, 70, 0, 25)
saveButton.Position = UDim2.new(0, 10, 0, 115)
saveButton.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
saveButton.Text = "Save"
saveButton.TextColor3 = Color3.new(1,1,1)
saveButton.Font = Enum.Font.SourceSans
saveButton.TextSize = 16
saveButton.Parent = frame

local loadButton = Instance.new("TextButton")
loadButton.Size = UDim2.new(0, 70, 0, 25)
loadButton.Position = UDim2.new(0, 90, 0, 115)
loadButton.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
loadButton.Text = "Load"
loadButton.TextColor3 = Color3.new(1,1,1)
loadButton.Font = Enum.Font.SourceSans
loadButton.TextSize = 16
loadButton.Parent = frame

local resetButton = Instance.new("TextButton")
resetButton.Size = UDim2.new(0, 70, 0, 25)
resetButton.Position = UDim2.new(0, 170, 0, 115)
resetButton.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
resetButton.Text = "Reset"
resetButton.TextColor3 = Color3.new(1,1,1)
resetButton.Font = Enum.Font.SourceSans
resetButton.TextSize = 16
resetButton.Parent = frame

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, -20, 0, 90)
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

-- Open/Close Button (right side)
local openCloseButton = Instance.new("TextButton")
openCloseButton.Size = UDim2.new(0, 40, 0, 40)
openCloseButton.Position = UDim2.new(1, -50, 0.5, -20)
openCloseButton.AnchorPoint = Vector2.new(0, 0.5)
openCloseButton.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
openCloseButton.Text = "≡"
openCloseButton.TextColor3 = Color3.new(1,1,1)
openCloseButton.Font = Enum.Font.SourceSansBold
openCloseButton.TextSize = 28
openCloseButton.Parent = screenGui

-- Place open/close button on right side of screen (fixed)
openCloseButton.Position = UDim2.new(1, -50, 0.5, -20)
openCloseButton.AnchorPoint = Vector2.new(0, 0.5)

openCloseButton.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

-- GUI Logic
autofarmToggle.MouseButton1Click:Connect(function()
    autofarmActive = not autofarmActive
    config.autofarmActive = autofarmActive
    autofarmToggle.Text = "Autofarm: " .. (autofarmActive and "ON" or "OFF")
    autofarmToggle.BackgroundColor3 = autofarmActive and Color3.fromRGB(50, 100, 50) or Color3.fromRGB(100, 50, 50)
end)

autospellToggle.MouseButton1Click:Connect(function()
    autospellActive = not autospellActive
    config.autospellActive = autospellActive
    autospellToggle.Text = "Autospell: " .. (autospellActive and "ON" or "OFF")
    autospellToggle.BackgroundColor3 = autospellActive and Color3.fromRGB(50, 50, 100) or Color3.fromRGB(100, 50, 50)
end)

heightBox.FocusLost:Connect(function(enterPressed)
    local val = tonumber(heightBox.Text)
    if val and val >= 0 then
        heightAboveEnemy = val
        config.heightAboveEnemy = val
        heightBox.Text = tostring(val)
    else
        heightBox.Text = tostring(heightAboveEnemy)
    end
end)

saveButton.MouseButton1Click:Connect(function()
    saveConfig()
end)

loadButton.MouseButton1Click:Connect(function()
    loadConfig()
    autofarmActive = config.autofarmActive
    autospellActive = config.autospellActive
    heightAboveEnemy = config.heightAboveEnemy
    autofarmToggle.Text = "Autofarm: " .. (autofarmActive and "ON" or "OFF")
    autofarmToggle.BackgroundColor3 = autofarmActive and Color3.fromRGB(50, 100, 50) or Color3.fromRGB(100, 50, 50)
    autospellToggle.Text = "Autospell: " .. (autospellActive and "ON" or "OFF")
    autospellToggle.BackgroundColor3 = autospellActive and Color3.fromRGB(50, 50, 100) or Color3.fromRGB(100, 50, 50)
    heightBox.Text = tostring(heightAboveEnemy)
end)

resetButton.MouseButton1Click:Connect(function()
    resetConfig()
    autofarmActive = config.autofarmActive
    autospellActive = config.autospellActive
    heightAboveEnemy = config.heightAboveEnemy
    autofarmToggle.Text = "Autofarm: " .. (autofarmActive and "ON" or "OFF")
    autofarmToggle.BackgroundColor3 = autofarmActive and Color3.fromRGB(50, 100, 50) or Color3.fromRGB(100, 50, 50)
    autospellToggle.Text = "Autospell: " .. (autospellActive and "ON" or "OFF")
    autospellToggle.BackgroundColor3 = autospellActive and Color3.fromRGB(50, 50, 100) or Color3.fromRGB(100, 50, 50)
    heightBox.Text = tostring(heightAboveEnemy)
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

-- Smoothly tween above enemy only if position changes significantly
local smoothTween = nil
local lastTargetPos = nil
local function smoothTweenAboveEnemy(enemy, height)
    if not enemy or not enemy:FindFirstChild("HumanoidRootPart") then return end
    local enemyPos = enemy.HumanoidRootPart.Position
    local targetPos = enemyPos + Vector3.new(0, height, 0)
    if lastTargetPos and (targetPos - lastTargetPos).Magnitude < 0.2 then
        -- Already close enough, don't retween
        return
    end
    lastTargetPos = targetPos
    if smoothTween then
        smoothTween:Cancel()
    end
    local goal = {CFrame = CFrame.new(targetPos)}
    smoothTween = TweenService:Create(
        humanoidRootPart,
        TweenInfo.new(TELEPORT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        goal
    )
    smoothTween:Play()
end

-- Find all attack indicators (MeshParts) under all enemies
local function getAllAttackIndicators()
    local indicators = {}
    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        if enemy:IsA("Model") then
            for _, part in ipairs(enemy:GetChildren()) do
                if part:IsA("MeshPart") and part.Name:lower():find("indicator") then
                    table.insert(indicators, part)
                end
            end
        end
    end
    return indicators
end

-- Check if two parts' bounding boxes overlap
local function isTouching(partA, partB)
    if not (partA and partB) then return false end
    local aMin = partA.Position - (partA.Size / 2)
    local aMax = partA.Position + (partA.Size / 2)
    local bMin = partB.Position - (partB.Size / 2)
    local bMax = partB.Position + (partB.Size / 2)
    return (aMin.X <= bMax.X and aMax.X >= bMin.X) and
           (aMin.Y <= bMax.Y and aMax.Y >= bMin.Y) and
           (aMin.Z <= bMax.Z and aMax.Z >= bMin.Z)
end

-- Find the closest overlapping indicator
local function getOverlappingIndicator()
    local indicators = getAllAttackIndicators()
    for _, indicator in ipairs(indicators) do
        if isTouching(humanoidRootPart, indicator) then
            return indicator
        end
    end
    return nil
end

-- Smart dodge: Move outside the indicator's bounds based on its CFrame/Size
local function tweenSmartDodge(indicator)
    if not (indicator and humanoidRootPart) then return end
    local playerPos = humanoidRootPart.Position
    local indicatorCFrame = indicator.CFrame
    local indicatorSize = indicator.Size

    -- Convert player position to indicator's object space
    local relative = indicatorCFrame:PointToObjectSpace(playerPos)
    -- Find which axis (X, Y, Z) is most outside the indicator's bounds
    local halfSize = indicatorSize / 2
    local axes = {"X", "Y", "Z"}
    local maxDist = 0
    local axisToDodge = "X"
    for _, axis in ipairs(axes) do
        local dist = math.abs(relative[axis]) - halfSize[axis]
        if dist < 0 then -- inside the bounds
            dist = -dist
        end
        if dist > maxDist then
            maxDist = dist
            axisToDodge = axis
        end
    end

    -- Move along the axis we are deepest inside, in the direction out of the indicator
    local dodgeVector = Vector3.new(0,0,0)
    if axisToDodge == "X" then
        local dir = (relative.X >= 0) and 1 or -1
        dodgeVector = Vector3.new((halfSize.X + EVADE_BUFFER) * dir, relative.Y, relative.Z)
    elseif axisToDodge == "Y" then
        local dir = (relative.Y >= 0) and 1 or -1
        dodgeVector = Vector3.new(relative.X, (halfSize.Y + EVADE_BUFFER) * dir, relative.Z)
    elseif axisToDodge == "Z" then
        local dir = (relative.Z >= 0) and 1 or -1
        dodgeVector = Vector3.new(relative.X, relative.Y, (halfSize.Z + EVADE_BUFFER) * dir)
    end

    -- Convert back to world space
    local safeWorldPos = indicatorCFrame:PointToWorldSpace(dodgeVector)
    -- Keep player's Y if dodging horizontally, or keep X/Z if dodging vertically
    if axisToDodge ~= "Y" then
        safeWorldPos = Vector3.new(safeWorldPos.X, playerPos.Y, safeWorldPos.Z)
    end

    if smoothTween then
        smoothTween:Cancel()
    end
    local goal = {CFrame = CFrame.new(safeWorldPos)}
    smoothTween = TweenService:Create(
        humanoidRootPart,
        TweenInfo.new(0.3, Enum.EasingStyle.Linear),
        goal
    )
    smoothTween:Play()
    smoothTween.Completed:Wait()
end

-- Autofarm loop with smart evasion and smooth above-enemy tweening
local currentTarget = nil
spawn(function()
    while true do
        if autofarmActive and remainingEnemies.Value > 0 then
            local enemy = getNearestEnemy()
            currentTarget = enemy
            if enemy then
                -- Move above enemy
                smoothTweenAboveEnemy(enemy, heightAboveEnemy)
                -- Stay above enemy while alive
                while enemy.Parent == enemiesFolder and enemy.Humanoid.Health > 0 and autofarmActive do
                    -- Evasion check
                    local indicator = getOverlappingIndicator()
                    if indicator then
                        evading = true
                        tweenSmartDodge(indicator)
                        -- Wait until not touching any indicator
                        repeat
                            wait(0.1)
                            indicator = getOverlappingIndicator()
                        until not indicator
                        evading = false
                        -- After evading, retween above enemy
                        smoothTweenAboveEnemy(enemy, heightAboveEnemy)
                    else
                        smoothTweenAboveEnemy(enemy, heightAboveEnemy)
                        wait(0.1)
                    end
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

-- Auto spell loop
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
            "Target: %s\nRemaining Enemies: %d\nAutofarm: %s\nAutospell: %s\nHeight: %d\nEvading: %s",
            targetName,
            remainingEnemies.Value,
            autofarmActive and "ON" or "OFF",
            autospellActive and "ON" or "OFF",
            heightAboveEnemy,
            evading and "YES" or "NO"
        )
        wait(0.2)
    end
end)
