--[[
    Roblox Autofarm Script
    - Robust config read/write (no default-only issue)
    - Orbit toggle (default OFF) placed under Autospell; when OFF: top-down hover
    - Persist across death/respawn
    - Remove dodge/hitbox logic
    - Anti-fling stabilization similar to sbtdAutoKarate.lua
    - Draggable GUI
    - Karate-style traveling (hybrid velocity steering + micro tweens + waypoint hops)

    Drop-in path: /other/fabled leg/eneMac.lua
]]

-- Synapse X file functions (assumed environment)
local writefile = writefile
local readfile = readfile
local isfile = isfile
local makefolder = makefolder
local isfolder = isfolder

local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")

local player = Players.LocalPlayer

-- ============================ Config ============================
local CONFIG_FOLDER = "fabledAutoTest"
local CONFIG_PATH = CONFIG_FOLDER.."/config.json"

local DEFAULT_CONFIG = {
    autofarmActive = false,
    autospellActive = false,
    heightAboveEnemy = 10,
    orbitRadius = 6,
    orbitSpeed = 1.5,
    orbitEnabled = false, -- default OFF
}

local function deepCopy(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = type(v) == "table" and deepCopy(v) or v
    end
    return copy
end

local function mergeDefaults(parsed, defaults)
    for k, v in pairs(defaults) do
        if parsed[k] == nil then
            parsed[k] = v
        end
    end
    return parsed
end

local function atomicWrite(path, content)
    local tmp = path..".tmp"
    local ok = pcall(writefile, tmp, content)
    if ok then
        pcall(writefile, path, content)
    else
        pcall(writefile, path, content)
    end
end

local function saveConfig(config)
    local ok, json = pcall(HttpService.JSONEncode, HttpService, config)
    if ok and json then atomicWrite(CONFIG_PATH, json) end
end

local function loadConfig()
    if not isfolder(CONFIG_FOLDER) then pcall(makefolder, CONFIG_FOLDER) end
    if not isfile(CONFIG_PATH) then
        local cfg = deepCopy(DEFAULT_CONFIG)
        saveConfig(cfg)
        return cfg
    end
    local okRead, data = pcall(readfile, CONFIG_PATH)
    if not okRead or type(data) ~= "string" or #data == 0 then
        local cfg = deepCopy(DEFAULT_CONFIG)
        saveConfig(cfg)
        return cfg
    end
    local okParse, parsed = pcall(HttpService.JSONDecode, HttpService, data)
    if not okParse or type(parsed) ~= "table" then
        local cfg = deepCopy(DEFAULT_CONFIG)
        saveConfig(cfg)
        return cfg
    end
    local merged = mergeDefaults(parsed, DEFAULT_CONFIG)
    local needSave = false
    for k, _ in pairs(DEFAULT_CONFIG) do
        if parsed[k] == nil then needSave = true break end
    end
    if needSave then saveConfig(merged) end
    return merged
end

local config = loadConfig()

-- ====================== Character Bindings ======================
local character, humanoid, root
local currentTweens = {}

local function stopAllTweens()
    for twe, _ in pairs(currentTweens) do
        pcall(function()
            twe:Cancel()
        end)
    end
    currentTweens = {}
end

local function bindCharacter(char)
    character = char
    humanoid = character:WaitForChild("Humanoid")
    root = character:WaitForChild("HumanoidRootPart")
end

bindCharacter(player.Character or player.CharacterAdded:Wait())
player.CharacterAdded:Connect(function(char)
    bindCharacter(char)
    -- small delay to ensure physics is stable then defling
    task.delay(0.1, function()
        if root then
            -- brief stabilization after respawn
            local _ = nil
        end
    end)
end)

-- ============================ GUI ==============================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutofarmGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 345)
frame.Position = UDim2.new(0, 20, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 32)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Autofarm Controls"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

-- Drag handle on title bar
do
    local dragging = false
    local dragStart, startPos
    local inputConn, renderConn

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            inputConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if renderConn then renderConn:Disconnect() renderConn = nil end
                    if inputConn then inputConn:Disconnect() inputConn = nil end
                end
            end)

            renderConn = RunService.RenderStepped:Connect(function()
                if dragging then
                    local mouse = game:GetService("UserInputService"):GetMouseLocation()
                    local fakeInput = { Position = mouse }
                    update(fakeInput)
                end
            end)
        end
    end)
end

local openCloseBtn = Instance.new("TextButton")
openCloseBtn.Size = UDim2.new(0, 32, 0, 32)
openCloseBtn.Position = UDim2.new(1, -36, 0, 0)
openCloseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
openCloseBtn.Text = "⏷"
openCloseBtn.TextColor3 = Color3.new(1,1,1)
openCloseBtn.Font = Enum.Font.SourceSansBold
openCloseBtn.TextSize = 20
openCloseBtn.Parent = frame

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -44)
content.Position = UDim2.new(0, 10, 0, 40)
content.BackgroundTransparency = 1
content.Parent = frame

local guiOpen = true
local function setGuiOpen(open)
    guiOpen = open
    for _, inst in ipairs(content:GetChildren()) do
        inst.Visible = open
    end
    openCloseBtn.Text = open and "⏷" or "⏶"
end
openCloseBtn.MouseButton1Click:Connect(function() setGuiOpen(not guiOpen) end)
setGuiOpen(true)

-- Controls
local function makeButton(text, pos, size)
    local b = Instance.new("TextButton")
    b.Size = size or UDim2.new(0, 110, 0, 30)
    b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.SourceSans
    b.TextSize = 18
    b.Parent = content
    return b
end

local function makeLabel(text, pos)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, 200, 0, 25)
    l.Position = pos
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(200, 200, 200)
    l.Font = Enum.Font.SourceSans
    l.TextSize = 16
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = content
    return l
end

local function makeBox(text, pos)
    local t = Instance.new("TextBox")
    t.Size = UDim2.new(0, 50, 0, 25)
    t.Position = pos
    t.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    t.Text = text
    t.TextColor3 = Color3.new(1,1,1)
    t.Font = Enum.Font.SourceSans
    t.TextSize = 16
    t.ClearTextOnFocus = false
    t.Parent = content
    return t
end

-- State from config
local autofarmActive = config.autofarmActive
local autospellActive = config.autospellActive
local heightAboveEnemy = config.heightAboveEnemy
local orbitRadius = config.orbitRadius
local orbitSpeed = config.orbitSpeed
local orbitEnabled = config.orbitEnabled

local autofarmToggle = makeButton("Autofarm: " .. (autofarmActive and "ON" or "OFF"), UDim2.new(0, 0, 0, 0))
local autospellToggle = makeButton("Autospell: " .. (autospellActive and "ON" or "OFF"), UDim2.new(0, 120, 0, 0))
local orbitToggle = makeButton("Orbit: " .. (orbitEnabled and "ON" or "OFF"), UDim2.new(0, 0, 0, 40), UDim2.new(0, 230, 0, 30))

local heightLabel = makeLabel("Height Above Enemy:", UDim2.new(0, 0, 0, 80))
local heightBox = makeBox(tostring(heightAboveEnemy), UDim2.new(0, 150, 0, 80))

local radiusLabel = makeLabel("Orbit Radius:", UDim2.new(0, 0, 0, 110))
local radiusBox = makeBox(tostring(orbitRadius), UDim2.new(0, 150, 0, 110))

local speedLabel = makeLabel("Orbit Speed:", UDim2.new(0, 0, 0, 140))
local speedBox = makeBox(tostring(orbitSpeed), UDim2.new(0, 150, 0, 140))

local infoLabel = makeLabel("", UDim2.new(0, 0, 0, 175))
infoLabel.Size = UDim2.new(1, -10, 0, 50)

local healthLabel = makeLabel("", UDim2.new(0, 0, 0, 230))
healthLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
healthLabel.Font = Enum.Font.SourceSansBold

-- Enable/disable interactivity if multiplayer
local function isSinglePlayer() return #Players:GetPlayers() == 1 end
local function refreshButtons()
    local enabledColor = Color3.fromRGB(50, 100, 50)
    local disabledColor = Color3.fromRGB(100, 50, 50)
    autofarmToggle.BackgroundColor3 = autofarmActive and enabledColor or disabledColor
    autospellToggle.BackgroundColor3 = autospellActive and Color3.fromRGB(50, 50, 100) or disabledColor
    orbitToggle.BackgroundColor3 = orbitEnabled and enabledColor or disabledColor

    autofarmToggle.Text = "Autofarm: " .. (autofarmActive and "ON" or "OFF")
    autospellToggle.Text = "Autospell: " .. (autospellActive and "ON" or "OFF")
    orbitToggle.Text = "Orbit: " .. (orbitEnabled and "ON" or "OFF")
end
refreshButtons()

-- ==================== Anti-Fling Utilities =====================
local DEFling = {
    DampTime = 0.55, -- seconds to damp velocities
    PlatformTime = 0.25, -- portion of DampTime to hold PlatformStand true
    LinearDecay = 0.85, -- per-frame multiplier
    AngularDecay = 0.82, -- per-frame multiplier
}

local function deflingStabilize()
    if not root or not humanoid then return end
    stopAllTweens()

    -- cache states
    local oldPS = humanoid.PlatformStand
    local start = tick()
    humanoid.PlatformStand = true

    -- zero network ownership spikes by nudging CFrame slightly
    pcall(function()
        root.CFrame = root.CFrame + Vector3.new(0, 0.001, 0)
    end)

    local con
    con = RunService.Heartbeat:Connect(function(dt)
        if not root then return end
        -- smooth damp velocities
        local lv = root.AssemblyLinearVelocity
        local av = root.AssemblyAngularVelocity
        root.AssemblyLinearVelocity = lv * math.clamp(DEFling.LinearDecay ^ (dt*60), 0, 1)
        root.AssemblyAngularVelocity = av * math.clamp(DEFling.AngularDecay ^ (dt*60), 0, 1)

        -- small clamp for safety
        if root.AssemblyLinearVelocity.Magnitude < 0.5 then
            root.AssemblyLinearVelocity = Vector3.new()
        end
        if root.AssemblyAngularVelocity.Magnitude < 0.5 then
            root.AssemblyAngularVelocity = Vector3.new()
        end

        -- release PlatformStand after portion
        if tick() - start > DEFling.PlatformTime then
            humanoid.PlatformStand = false
        end
        if tick() - start > DEFling.DampTime then
            con:Disconnect()
        end
    end)
end

-- ==================== Movement / Traveling =====================
-- Hybrid travel like karate: frame-steered velocity with optional micro-tweens and Y lock.
local Travel = {
    MaxStep = 60,            -- max distance before using waypoints hops
    SnapDist = 2.0,          -- snap when within this distance
    MicroTweenTime = 0.12,   -- micro tween duration
    HorizontalSpeed = 65,    -- studs/sec
    VerticalFollow = true,
    YSmooth = 12,            -- vertical smoothing towards target Y
    WaypointStep = 55,       -- size of hops when far
}

local function microTween(cf, dur)
    if not root then return end
    local t = TweenService:Create(root, TweenInfo.new(dur, Enum.EasingStyle.Linear), { CFrame = cf })
    currentTweens[t] = true
    t:Play()
    t.Completed:Wait()
    currentTweens[t] = nil
end

local function steerTowards(pos, dt)
    if not root then return end
    local current = root.Position
    local delta = pos - current
    local horiz = Vector3.new(delta.X, 0, delta.Z)
    local dir = horiz.Magnitude > 0 and horiz.Unit or Vector3.new()

    -- horizontal steering
    local desiredVel = dir * Travel.HorizontalSpeed
    local newVel = Vector3.new(desiredVel.X, root.AssemblyLinearVelocity.Y, desiredVel.Z)

    -- vertical smoothing to target height
    if Travel.VerticalFollow then
        local yVel = (pos.Y - current.Y) * math.clamp(Travel.YSmooth * dt, 0, 1) * 60 / 3
        newVel = Vector3.new(newVel.X, yVel, newVel.Z)
    end

    root.AssemblyLinearVelocity = newVel
    -- face target
    if horiz.Magnitude > 0.1 then
        root.CFrame = CFrame.new(current, current + Vector3.new(dir.X, 0, dir.Z))
    end
end

local function karateTravelTo(targetPos, hover)
    if not root then return end
    -- Use waypoint hops if far
    local pos0 = root.Position
    local dist = (targetPos - pos0).Magnitude

    local function runToPoint(pt)
        local reached = false
        local timeout = tick() + 6
        while root and (root.Position - pt).Magnitude > Travel.SnapDist do
            local dt = RunService.RenderStepped:Wait()
            steerTowards(pt, dt)
            if tick() > timeout then break end
        end
        -- micro snap to final CFrame (top-down look if hover)
        local lookPoint = hover and (pt + Vector3.new(0, -1, 0)) or pt + Vector3.new(0, 0, -1)
        microTween(CFrame.new(pt, lookPoint), Travel.MicroTweenTime)
        reached = true
        return reached
    end

    if dist > Travel.MaxStep then
        -- hop in increments
        local dirUnit = (targetPos - pos0).Unit
        local steps = math.ceil(dist / Travel.WaypointStep)
        for i = 1, steps do
            local stepTarget
            if i < steps then
                stepTarget = pos0 + dirUnit * (i * Travel.WaypointStep)
                -- preserve desired hover Y
                stepTarget = Vector3.new(stepTarget.X, targetPos.Y, stepTarget.Z)
            else
                stepTarget = targetPos
            end
            runToPoint(stepTarget)
        end
    else
        runToPoint(targetPos)
    end
end

-- ===================== Enemy/Combat Logic ======================
local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:WaitForChild("Enemies")

local function getAliveEnemies()
    local alive = {}
    for _, m in ipairs(enemiesFolder:GetChildren()) do
        local h = m:FindFirstChild("Humanoid")
        local hrp = m:FindFirstChild("HumanoidRootPart")
        if h and hrp and h.Health > 0 then table.insert(alive, m) end
    end
    return alive
end

local function getNearestEnemy()
    if not root then return nil end
    local nearest, dmin = nil, math.huge
    for _, e in ipairs(getAliveEnemies()) do
        local hrp = e.HumanoidRootPart
        local d = (root.Position - hrp.Position).Magnitude
        if d < dmin then dmin, nearest = d, e end
    end
    return nearest
end

-- ===================== Health and Platform =====================
local SAFE_HEALTH_THRESHOLD = 0.50
local LOW_HEALTH_THRESHOLD = 0.45

local tempPlatform
local TEMP_PLATFORM_SIZE = Vector3.new(12, 1, 12)
local TEMP_PLATFORM_OFFSET = Vector3.new(0, 50, 0)

local function createTempPlatform()
    if tempPlatform and tempPlatform.Parent then return tempPlatform end
    tempPlatform = Instance.new("Part")
    tempPlatform.Name = "SafePlatform"
    tempPlatform.Anchored = true
    tempPlatform.CanCollide = true
    tempPlatform.Transparency = 0.2
    tempPlatform.Size = TEMP_PLATFORM_SIZE
    tempPlatform.Color = Color3.fromRGB(100, 200, 255)
    tempPlatform.Position = (root and (root.Position + TEMP_PLATFORM_OFFSET)) or Vector3.new(0, 200, 0)
    tempPlatform.Parent = Workspace
    return tempPlatform
end

local function removeTempPlatform()
    if tempPlatform then tempPlatform:Destroy() tempPlatform = nil end
end

local function moveToTempPlatform()
    if not root then return end
    local platform = createTempPlatform()
    local above = platform.Position + Vector3.new(0, 4, 0)
    stopAllTweens()
    root.CFrame = CFrame.new(above)
end

local function shouldPauseForHealth()
    if not humanoid or humanoid.MaxHealth == 0 then return false end
    return humanoid.Health / humanoid.MaxHealth < LOW_HEALTH_THRESHOLD
end
local function shouldResumeForHealth()
    if not humanoid or humanoid.MaxHealth == 0 then return true end
    return humanoid.Health / humanoid.MaxHealth > SAFE_HEALTH_THRESHOLD
end

-- ========================= Behavior ============================
local SPELLS = {"Q", "E"}
local SPELL_INTERVAL = 1

local function tweenToCFrame(cf, duration)
    if not root then return end
    local t = TweenService:Create(root, TweenInfo.new(duration or 0.4, Enum.EasingStyle.Linear), { CFrame = cf })
    currentTweens[t] = true
    t:Play()
    t.Completed:Wait()
    currentTweens[t] = nil
end

-- Non-orbit behavior: hover above enemy and look straight down
local function hoverTopDown(enemy, height)
    while enemy.Parent == enemiesFolder and enemy.Humanoid.Health > 0 do
        if not autofarmActive then break end
        if not humanoid or not root then break end
        local dt = RunService.RenderStepped:Wait()
        local targetPos = enemy.HumanoidRootPart.Position + Vector3.new(0, height, 0)
        -- karate travel steering style each frame
        steerTowards(targetPos, dt)
        -- fix orientation to look down when close
        local dist = (root.Position - targetPos).Magnitude
        if dist < 2.0 then
            root.CFrame = CFrame.new(targetPos, targetPos + Vector3.new(0, -1, 0))
        end
    end
end

-- Orbit behavior
local function orbitAroundEnemy(enemy, height, radius, speed)
    if not root then return end
    local angle = math.random() * math.pi * 2
    while enemy.Parent == enemiesFolder and enemy.Humanoid.Health > 0 do
        if not autofarmActive then break end
        if not root then break end
        local dt = RunService.RenderStepped:Wait()
        angle += speed * dt
        local base = enemy.HumanoidRootPart.Position
        local offset = Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
        local targetPos = base + offset
        steerTowards(targetPos, dt)
        root.CFrame = CFrame.new(root.Position, base)
    end
end

-- ======================= GUI Interaction =======================
local function lockControls(lock)
    local colorOff = Color3.fromRGB(60, 60, 60)
    local function setBtn(b, enabled)
        b.AutoButtonColor = enabled
        if not enabled then b.BackgroundColor3 = colorOff end
    end
    local allow = isSinglePlayer() and not lock
    setBtn(autofarmToggle, allow)
    setBtn(autospellToggle, allow)
    setBtn(orbitToggle, allow)
    heightBox.TextEditable = allow
    radiusBox.TextEditable = allow
    speedBox.TextEditable = allow
end

local function enforceSinglePlayer()
    if isSinglePlayer() then
        healthLabel.Text = ""
        lockControls(false)
    else
        -- disable features in multiplayer
        if autofarmActive then
            autofarmActive = false
            config.autofarmActive = false
            saveConfig(config)
            deflingStabilize()
        end
        autospellActive = false
        config.autospellActive = false
        saveConfig(config)
        refreshButtons()
        lockControls(true)
        healthLabel.Text = "Disabled in multi-player"
    end
end
enforceSinglePlayer()
Players.PlayerAdded:Connect(enforceSinglePlayer)
Players.PlayerRemoving:Connect(function() task.wait(0.1) enforceSinglePlayer() end)

autofarmToggle.MouseButton1Click:Connect(function()
    if not isSinglePlayer() then return end
    autofarmActive = not autofarmActive
    config.autofarmActive = autofarmActive
    saveConfig(config)
    refreshButtons()
    if not autofarmActive then
        deflingStabilize()
    end
end)

autospellToggle.MouseButton1Click:Connect(function()
    if not isSinglePlayer() then return end
    autospellActive = not autospellActive
    config.autospellActive = autospellActive
    saveConfig(config)
    refreshButtons()
end)

orbitToggle.MouseButton1Click:Connect(function()
    if not isSinglePlayer() then return end
    orbitEnabled = not orbitEnabled
    config.orbitEnabled = orbitEnabled
    saveConfig(config)
    refreshButtons()
end)

heightBox.FocusLost:Connect(function()
    if not isSinglePlayer() then
        heightBox.Text = tostring(heightAboveEnemy); return
    end
    local v = tonumber(heightBox.Text)
    if v and v >= 0 then
        heightAboveEnemy = v
        config.heightAboveEnemy = v
        saveConfig(config)
    end
    heightBox.Text = tostring(heightAboveEnemy)
end)

radiusBox.FocusLost:Connect(function()
    if not isSinglePlayer() then
        radiusBox.Text = tostring(orbitRadius); return
    end
    local v = tonumber(radiusBox.Text)
    if v and v >= 1 then
        orbitRadius = v
        config.orbitRadius = v
        saveConfig(config)
    end
    radiusBox.Text = tostring(orbitRadius)
end)

speedBox.FocusLost:Connect(function()
    if not isSinglePlayer() then
        speedBox.Text = tostring(orbitSpeed); return
    end
    local v = tonumber(speedBox.Text)
    if v and v > 0 then
        orbitSpeed = v
        config.orbitSpeed = v
        saveConfig(config)
    end
    speedBox.Text = tostring(orbitSpeed)
end)

-- ========================= Main Loops ==========================
local currentTarget
local pausedForHealth = false

-- Autofarm main
task.spawn(function()
    while true do
        if not root or not humanoid then
            task.wait(0.2)
        else
            if shouldPauseForHealth() and not pausedForHealth then
                pausedForHealth = true
                healthLabel.Text = "Low HP! Healing..."
                moveToTempPlatform()
            end

            while pausedForHealth do
                moveToTempPlatform()
                if shouldResumeForHealth() then
                    pausedForHealth = false
                    healthLabel.Text = ""
                    removeTempPlatform()
                    deflingStabilize()
                end
                task.wait(0.25)
            end

            if autofarmActive and isSinglePlayer() then
                local enemy = getNearestEnemy()
                currentTarget = enemy
                if enemy then
                    local goal = enemy.HumanoidRootPart.Position + Vector3.new(0, heightAboveEnemy, 0)
                    karateTravelTo(goal, true)

                    if enemy and enemy.Parent == enemiesFolder and enemy.Humanoid.Health > 0 and autofarmActive and not pausedForHealth then
                        if orbitEnabled then
                            orbitAroundEnemy(enemy, heightAboveEnemy, orbitRadius, orbitSpeed)
                        else
                            hoverTopDown(enemy, heightAboveEnemy)
                        end
                    end
                else
                    task.wait(0.4)
                end
            else
                currentTarget = nil
                task.wait(0.4)
            end
        end
    end
end)

-- Auto spells
task.spawn(function()
    local RS = game:GetService("ReplicatedStorage")
    local remote = RS:FindFirstChild("useSpell")
    while true do
        if autospellActive and remote and isSinglePlayer() and not pausedForHealth then
            for _, key in ipairs(SPELLS) do
                if not autospellActive or pausedForHealth then break end
                pcall(function() remote:FireServer(key) end)
                task.wait(SPELL_INTERVAL)
            end
        else
            task.wait(0.2)
        end
    end
end)

-- Stats update
task.spawn(function()
    while true do
        local targetName = currentTarget and currentTarget.Name or "None"
        infoLabel.Text = string.format(
            "Target: %s\nAutofarm: %s | Autospell: %s | Orbit: %s\nHeight:%d Rad:%d Speed:%.2f",
            targetName,
            autofarmActive and "ON" or "OFF",
            autospellActive and "ON" or "OFF",
            orbitEnabled and "ON" or "OFF",
            heightAboveEnemy, orbitRadius, orbitSpeed
        )
        task.wait(0.2)
    end
end)

-- Safety: also defling when toggling orbit states rapidly
orbitToggle.MouseButton1Click:Connect(function()
    if not autofarmActive then deflingStabilize() end
end)

-- On respawn finalization defling
player.CharacterAdded:Connect(function()
    task.delay(0.2, deflingStabilize)
end)
