
--[[
    Roblox Autofarm Script with GUI, Toggles, and Height Setting
    - Tweens above the enemy at configurable height
    - Orbits (rotates) around the enemy while facing it when close
    - Pauses autofarm and teleports to a temp platform if HP < 45%, resumes at > 90%
    - GUI for stats, toggles, and height input
    - Open/close button on right side of screen (no H keybind)
    Place as a LocalScript (e.g., StarterPlayerScripts)
--]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local enemiesFolder = workspace:WaitForChild("Enemies")
local remainingEnemies = enemiesFolder:WaitForChild("remainingEnemies")

local SPELLS = {"Q", "E"}
local SPELL_INTERVAL = 1 -- seconds between spell casts
local TELEPORT_TIME = 0.5 -- seconds for tween teleport

-- Orbit settings
local ORBIT_RADIUS = 6
local ORBIT_SPEED = 1.5 -- radians/sec
local ORBIT_DISTANCE_THRESHOLD = 1.5 -- how close before orbit starts

-- Health thresholds
local SAFE_HEALTH_THRESHOLD = 0.50
local LOW_HEALTH_THRESHOLD = 0.45

-- Temp platform settings
local TEMP_PLATFORM_SIZE = Vector3.new(12, 1, 12)
local TEMP_PLATFORM_OFFSET = Vector3.new(0, 50, 0) -- 50 studs above current position

-- State
local autofarmActive = false -- Default OFF
local autospellActive = false -- Default OFF
local heightAboveEnemy = 10

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutofarmGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 220)
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
autofarmToggle.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
autofarmToggle.Text = "Autofarm: OFF"
autofarmToggle.TextColor3 = Color3.new(1,1,1)
autofarmToggle.Font = Enum.Font.SourceSans
autofarmToggle.TextSize = 18
autofarmToggle.Parent = frame

local autospellToggle = Instance.new("TextButton")
autospellToggle.Size = UDim2.new(0, 110, 0, 30)
autospellToggle.Position = UDim2.new(0, 130, 0, 40)
autospellToggle.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
autospellToggle.Text = "Autospell: OFF"
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

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, -20, 0, 60)
statsLabel.Position = UDim2.new(0, 10, 0, 120)
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
healthStatusLabel.Position = UDim2.new(0, 10, 0, 185)
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

-- GUI Logic
autofarmToggle.MouseButton1Click:Connect(function()
    autofarmActive = not autofarmActive
    autofarmToggle.Text = "Autofarm: " .. (autofarmActive and "ON" or "OFF")
    autofarmToggle.BackgroundColor3 = autofarmActive and Color3.fromRGB(50, 100, 50) or Color3.fromRGB(100, 50, 50)
end)

autospellToggle.MouseButton1Click:Connect(function()
    autospellActive = not autospellActive
    autospellToggle.Text = "Autospell: " .. (autospellActive and "ON" or "OFF")
    autospellToggle.BackgroundColor3 = autospellActive and Color3.fromRGB(50, 50, 100) or Color3.fromRGB(100, 50, 50)
end)

heightBox.FocusLost:Connect(function(enterPressed)
    local val = tonumber(heightBox.Text)
    if val and val >= 0 then
        heightAboveEnemy = val
        heightBox.Text = tostring(val)
    else
        heightBox.Text = tostring(heightAboveEnemy)
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

local function tweenAboveEnemy(enemy, height)
    local goal = {}
    local enemyPos = enemy.HumanoidRootPart.Position
    goal.CFrame = CFrame.new(enemyPos + Vector3.new(0, height, 0))
    local tween = TweenService:Create(
        humanoidRootPart,
        TweenInfo.new(TELEPORT_TIME, Enum.EasingStyle.Linear),
        goal
    )
    tween:Play()
    tween.Completed:Wait()
end

-- Orbit logic
local function orbitAroundEnemy(enemy, height, radius, speed)
    local angle = math.random() * math.pi * 2
    while enemy.Parent == enemiesFolder and enemy.Humanoid.Health > 0 and autofarmActive do
        -- Health check inside orbit
        if humanoid.Health / humanoid.MaxHealth < LOW_HEALTH_THRESHOLD then
            break
        end
        local dt = RunService.RenderStepped:Wait()
        angle = angle + speed * dt
        local enemyPos = enemy.HumanoidRootPart.Position
        local offset = Vector3.new(
            math.cos(angle) * radius,
            height,
            math.sin(angle) * radius
        )
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
            -- Stay on platform and wait for heal
            moveToTempPlatform()
            if shouldResumeForHealth() then
                autofarmPausedForHealth = false
                healthStatusLabel.Text = ""
                removeTempPlatform()
            end
            wait(0.5)
        end

        if autofarmActive and remainingEnemies.Value > 0 then
            local enemy = getNearestEnemy()
            currentTarget = enemy
            if enemy then
                -- Move above enemy
                tweenAboveEnemy(enemy, heightAboveEnemy)
                -- Wait until close enough to start orbit
                while enemy.Parent == enemiesFolder and enemy.Humanoid.Health > 0 and autofarmActive and not autofarmPausedForHealth do
                    -- Health check inside loop
                    if shouldPauseForHealth() then
                        autofarmPausedForHealth = true
                        healthStatusLabel.Text = "Low HP! Waiting to heal..."
                        moveToTempPlatform()
                        break
                    end
                    local enemyPos = enemy.HumanoidRootPart.Position + Vector3.new(0, heightAboveEnemy, 0)
                    local dist = (humanoidRootPart.Position - enemyPos).Magnitude
                    if dist <= ORBIT_DISTANCE_THRESHOLD then
                        break
                    end
                    -- Keep position above enemy until close
                    local goal = {}
                    goal.CFrame = CFrame.new(enemyPos)
                    TweenService:Create(
                        humanoidRootPart,
                        TweenInfo.new(0.2, Enum.EasingStyle.Linear),
                        goal
                    ):Play()
                    wait(0.2)
                end
                -- Orbit around enemy while facing it
                if enemy.Parent == enemiesFolder and enemy.Humanoid.Health > 0 and autofarmActive and not autofarmPausedForHealth then
                    orbitAroundEnemy(enemy, heightAboveEnemy, ORBIT_RADIUS, ORBIT_SPEED)
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
        if autospellActive and not autofarmPausedForHealth then
            for _, spell in ipairs(SPELLS) do
                if autospellActive and not autofarmPausedForHealth then
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
            "Target: %s\nRemaining Enemies: %d\nAutofarm: %s\nAutospell: %s\nHeight: %d",
            targetName,
            remainingEnemies.Value,
            autofarmActive and "ON" or "OFF",
            autospellActive and "ON" or "OFF",
            heightAboveEnemy
        )
        wait(0.2)
    end
end)
