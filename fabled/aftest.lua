--[[
    File: other/fabled leg/eneMac.lua
    Updates:
      - Movement: use direct CFrame stepping (teleport) instead of tweening
      - GUI: 2x2 grid for four toggle buttons
      - GUI: prevent status clipping by using a ScrollingFrame for content
      - Header buttons: fixed open/close toggle and delete with confirm overlay
      - Collapse: animate Content frame (no leftover gray background)
      - Draggable: header drags the whole GUI
      - Keep: IgnoreGuiInset, safety toggle + low HP%, noclip during travel
      - Autofarm gating: when Autofarm is ON, wait until solo and dungeonStarted=false, then auto StartDungeon and proceed
]]

-- Synapse/Exploit file functions (assumed)
local writefile = writefile
local readfile = readfile
local isfile = isfile
local makefolder = makefolder
local isfolder = isfolder

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

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
    orbitEnabled = false,
    safetyEnabled = false,
    lowHealthThreshold = 0.45, -- fraction 0..1
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

local function bindCharacter(char)
    character = char
    humanoid = character:WaitForChild("Humanoid")
    root = character:WaitForChild("HumanoidRootPart")
end

bindCharacter(player.Character or player.CharacterAdded:Wait())
player.CharacterAdded:Connect(function(char)
    bindCharacter(char)
    task.delay(0.2, function()
        -- stabilization later if needed
    end)
end)

-- Helper: toggle collisions for all character BaseParts
local function setCharacterCanCollide(value)
    if not character then return end
    for _, d in ipairs(character:GetDescendants()) do
        if d:IsA("BasePart") then
            d.CanCollide = value
        end
    end
end

-- ============================ GUI ==============================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutofarmGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.DisplayOrder = 999999
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "Root"
frame.Size = UDim2.new(0, 320, 0, 420)
frame.Position = UDim2.new(0, 20, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.BackgroundTransparency = 1
frame.Active = true
frame.Parent = screenGui

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 36)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
header.BorderSizePixel = 0
header.Parent = frame

local headerPad = Instance.new("UIPadding")
headerPad.PaddingLeft = UDim.new(0, 10)
headerPad.PaddingRight = UDim.new(0, 10)
headerPad.Parent = header

local headerInner = Instance.new("Frame")
headerInner.Name = "HeaderInner"
headerInner.BackgroundTransparency = 1
headerInner.Size = UDim2.new(1, 0, 1, 0)
headerInner.Parent = header

local headerHL = Instance.new("UIListLayout")
headerHL.FillDirection = Enum.FillDirection.Horizontal
headerHL.HorizontalAlignment = Enum.HorizontalAlignment.Left
headerHL.VerticalAlignment = Enum.VerticalAlignment.Center
headerHL.Padding = UDim.new(0, 6)
headerHL.Parent = headerInner

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Text = "Autofarm Controls"
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Size = UDim2.new(1, -150, 1, 0)
title.Parent = headerInner

local btnCluster = Instance.new("Frame")
btnCluster.Name = "BtnCluster"
btnCluster.BackgroundTransparency = 1
btnCluster.Size = UDim2.new(0, 140, 1, 0)
btnCluster.Parent = headerInner

local clusterLayout = Instance.new("UIListLayout")
clusterLayout.FillDirection = Enum.FillDirection.Horizontal
clusterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
clusterLayout.VerticalAlignment = Enum.VerticalAlignment.Center
clusterLayout.Padding = UDim.new(0, 6)
clusterLayout.Parent = btnCluster

local openCloseBtn = Instance.new("TextButton")
openCloseBtn.Name = "Toggle"
openCloseBtn.Size = UDim2.new(0, 28, 0, 28)
openCloseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
openCloseBtn.Text = "-"
openCloseBtn.TextColor3 = Color3.new(1,1,1)
openCloseBtn.Font = Enum.Font.SourceSansBold
openCloseBtn.TextSize = 20
openCloseBtn.AutoButtonColor = true
openCloseBtn.Parent = btnCluster

local deleteBtn = Instance.new("TextButton")
deleteBtn.Name = "Delete"
deleteBtn.Size = UDim2.new(0, 90, 0, 28)
deleteBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 60)
deleteBtn.Text = "Delete"
deleteBtn.TextColor3 = Color3.new(1,1,1)
deleteBtn.Font = Enum.Font.SourceSansBold
deleteBtn.TextSize = 18
deleteBtn.AutoButtonColor = true
deleteBtn.Parent = btnCluster

-- Content container
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, 0, 1, -36)
content.Position = UDim2.new(0, 0, 0, 36)
content.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
content.BorderSizePixel = 0
content.Parent = frame

local contentPad = Instance.new("UIPadding")
contentPad.PaddingTop = UDim.new(0, 8)
contentPad.PaddingBottom = UDim.new(0, 8)
contentPad.PaddingLeft = UDim.new(0, 10)
contentPad.PaddingRight = UDim.new(0, 10)
contentPad.Parent = content

-- Scrollable area to avoid status clipping
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "ScrollArea"
scroll.BackgroundTransparency = 1
scroll.Size = UDim2.new(1, 0, 1, 0)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 6
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.BorderSizePixel = 0
scroll.Parent = content

local list = Instance.new("UIListLayout")
list.FillDirection = Enum.FillDirection.Vertical
list.HorizontalAlignment = Enum.HorizontalAlignment.Left
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, 8)
list.Parent = scroll

-- Helper add separator
local function addSeparator(order, text)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 16
    lbl.Text = text
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.LayoutOrder = order or 0
    lbl.Parent = scroll
end

-- Builders
local function makeRowLabelInput(labelText, valueText, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 25)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order or 0
    row.Parent = scroll

    local rowLayout = Instance.new("UIListLayout")
    rowLayout.FillDirection = Enum.FillDirection.Horizontal
    rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    rowLayout.Padding = UDim.new(0, 8)
    rowLayout.Parent = row

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -90, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = labelText
    l.TextColor3 = Color3.fromRGB(200, 200, 200)
    l.Font = Enum.Font.SourceSans
    l.TextSize = 16
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = row

    local t = Instance.new("TextBox")
    t.Size = UDim2.new(0, 80, 1, 0)
    t.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    t.Text = valueText
    t.TextColor3 = Color3.new(1,1,1)
    t.Font = Enum.Font.SourceSans
    t.TextSize = 16
    t.ClearTextOnFocus = false
    t.Parent = row

    return l, t
end

-- State from config
local autofarmActive = config.autofarmActive
local autospellActive = config.autospellActive
local heightAboveEnemy = config.heightAboveEnemy
local orbitRadius = config.orbitRadius
local orbitSpeed = config.orbitSpeed
local orbitEnabled = config.orbitEnabled
local safetyEnabled = config.safetyEnabled
local lowHealthThreshold = config.lowHealthThreshold

-- Controls
local order = 1
addSeparator(order, "Toggles"); order += 1

-- 2x2 grid for four toggle buttons
local controlsGrid = Instance.new("Frame")
controlsGrid.Name = "ControlsGrid"
controlsGrid.BackgroundTransparency = 1
controlsGrid.Size = UDim2.new(1, 0, 0, 2 * 36 + 8) -- 2 rows * 36 height + padding
controlsGrid.LayoutOrder = order; order += 1
controlsGrid.Parent = scroll

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0.5, -4, 0, 36) -- 2 columns, small gap
gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = controlsGrid

local function gridButton(text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 140, 0, 36) -- size driven by grid CellSize anyway
    b.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.SourceSans
    b.TextSize = 18
    b.Parent = controlsGrid
    return b
end

local autofarmToggle = gridButton("Autofarm: " .. (autofarmActive and "ON" or "OFF"))
local autospellToggle = gridButton("Autospell: " .. (autospellActive and "ON" or "OFF"))
local orbitToggle = gridButton("Orbit: " .. (orbitEnabled and "ON" or "OFF"))
local safetyToggle = gridButton("Safety Platform: " .. (safetyEnabled and "ON" or "OFF"))

addSeparator(order, "Settings"); order += 1
local _, heightBox = makeRowLabelInput("Height Above Enemy:", tostring(heightAboveEnemy), order) order += 1
local _, radiusBox = makeRowLabelInput("Orbit Radius:", tostring(orbitRadius), order) order += 1
local _, speedBox  = makeRowLabelInput("Orbit Speed:", tostring(orbitSpeed), order) order += 1
local _, lowHPBox  = makeRowLabelInput("Low Health %:", tostring(math.floor((lowHealthThreshold or 0.45)*100)), order) order += 1

-- Status
addSeparator(order, "Status"); order += 1
local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "Info"
infoLabel.Size = UDim2.new(1, 0, 0, 0)
infoLabel.AutomaticSize = Enum.AutomaticSize.Y
infoLabel.BackgroundTransparency = 1
infoLabel.TextWrapped = true
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
infoLabel.Font = Enum.Font.SourceSans
infoLabel.TextSize = 16
infoLabel.LayoutOrder = order; order += 1
infoLabel.Parent = scroll

local healthLabel = Instance.new("TextLabel")
healthLabel.Name = "Health"
healthLabel.Size = UDim2.new(1, 0, 0, 0)
healthLabel.AutomaticSize = Enum.AutomaticSize.Y
healthLabel.BackgroundTransparency = 1
healthLabel.TextXAlignment = Enum.TextXAlignment.Left
healthLabel.TextWrapped = true
healthLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
healthLabel.Font = Enum.Font.SourceSansBold
healthLabel.TextSize = 16
healthLabel.LayoutOrder = order
healthLabel.Parent = scroll

-- ==================== Confirm Overlay =====================
local function createConfirmOverlay(parent, message, onYes, onNo)
    local overlay = Instance.new("Frame")
    overlay.Name = "ConfirmOverlay"
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.35
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 100
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Visible = true
    overlay.Parent = parent

    local modal = Instance.new("Frame")
    modal.Name = "Modal"
    modal.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    modal.Size = UDim2.new(0, 230, 0, 120)
    modal.Position = UDim2.new(0.5, -115, 0.5, -60)
    modal.BorderSizePixel = 0
    modal.ZIndex = 101
    modal.Parent = overlay

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 12)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.Parent = modal

    local vlist = Instance.new("UIListLayout")
    vlist.FillDirection = Enum.FillDirection.Vertical
    vlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
    vlist.VerticalAlignment = Enum.VerticalAlignment.Top
    vlist.Padding = UDim.new(0, 10)
    vlist.Parent = modal

    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, 0, 0, 60)
    msg.BackgroundTransparency = 1
    msg.Text = message or "Are you sure you want to delete the GUI?"
    msg.TextColor3 = Color3.new(1,1,1)
    msg.Font = Enum.Font.SourceSansBold
    msg.TextSize = 18
    msg.TextWrapped = true
    msg.ZIndex = 102
    msg.Parent = modal

    local btnRow = Instance.new("Frame")
    btnRow.Size = UDim2.new(1, 0, 0, 34)
    btnRow.BackgroundTransparency = 1
    btnRow.ZIndex = 102
    btnRow.Parent = modal

    local hlist = Instance.new("UIListLayout")
    hlist.FillDirection = Enum.FillDirection.Horizontal
    hlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
    hlist.VerticalAlignment = Enum.VerticalAlignment.Center
    hlist.Padding = UDim.new(0, 12)
    hlist.Parent = btnRow

    local yesBtn = Instance.new("TextButton")
    yesBtn.Size = UDim2.new(0, 80, 1, 0)
    yesBtn.BackgroundColor3 = Color3.fromRGB(70, 140, 70)
    yesBtn.Text = "Yes"
    yesBtn.TextColor3 = Color3.new(1,1,1)
    yesBtn.Font = Enum.Font.SourceSansBold
    yesBtn.TextSize = 18
    yesBtn.ZIndex = 103
    yesBtn.Parent = btnRow

    local noBtn = Instance.new("TextButton")
    noBtn.Size = UDim2.new(0, 80, 1, 0)
    noBtn.BackgroundColor3 = Color3.fromRGB(140, 70, 70)
    noBtn.Text = "No"
    noBtn.TextColor3 = Color3.new(1,1,1)
    noBtn.Font = Enum.Font.SourceSansBold
    noBtn.TextSize = 18
    noBtn.ZIndex = 103
    noBtn.Parent = btnRow

    yesBtn.MouseButton1Click:Connect(function()
        if onYes then pcall(onYes) end
        overlay:Destroy()
    end)
    noBtn.MouseButton1Click:Connect(function()
        if onNo then pcall(onNo) end
        overlay:Destroy()
    end)

    return overlay
end

-- ==================== Collapse/Expand and Drag =====================
local guiOpen = true
local CONTENT_OPEN_SIZE = UDim2.new(1, 0, 1, -36)
local CONTENT_CLOSED_SIZE = UDim2.new(1, 0, 0, 0)
local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function setGuiOpen(open)
    guiOpen = open
    openCloseBtn.Text = open and "-" or "+"
    if open then
        scroll.Visible = true
    end
    local tw = TweenService:Create(content, TWEEN_INFO, { Size = open and CONTENT_OPEN_SIZE or CONTENT_CLOSED_SIZE })
    tw:Play()
    tw.Completed:Wait()
    if not open then
        scroll.Visible = false
    end
end

setGuiOpen(true)

openCloseBtn.MouseButton1Click:Connect(function()
    setGuiOpen(not guiOpen)
end)

deleteBtn.MouseButton1Click:Connect(function()
    createConfirmOverlay(screenGui, "Delete this GUI?", function()
        screenGui:Destroy()
    end, function() end)
end)

-- Draggable header to move the Root frame
do
    local dragging = false
    local dragStart, startPos

    local function beginDrag(input)
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end

    local function updateDrag(input)
        if not dragging then return end
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            beginDrag(input)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            updateDrag(input)
        end
    end)
end

-- ==================== Anti-Fling Utilities =====================
local function deflingStabilize()
    if not root or not humanoid then return end
    humanoid.PlatformStand = false
end

-- ==================== Dungeon Auto-Start (Solo gating) =====================
local function isSinglePlayer() return #Players:GetPlayers() == 1 end

-- Wait for solo + workspace.dungeonStarted == false; then FireServer("StartDungeon") once.
-- If dungeon already started, return immediately. If conditions break (multiplayer/off), return false.
local function waitForSoloAndStartDungeonIfNeeded()
    local RS = game:GetService("ReplicatedStorage")
    local startRemote = RS:FindFirstChild("StartDungeon") or RS:WaitForChild("StartDungeon", 5)
    local dungeonStarted = Workspace:FindFirstChild("dungeonStarted") or Workspace:WaitForChild("dungeonStarted", 5)
    if not startRemote or not dungeonStarted then
        return false
    end

    -- Proceed immediately if already started
    if dungeonStarted.Value == true then
        return true
    end

    -- Wait for solo + false; then fire once
    while true do
        if not autofarmActive then
            return false
        end
        if not isSinglePlayer() then
            return false
        end
        if dungeonStarted.Value == false then
            pcall(function() startRemote:FireServer() end)
            -- Optionally wait for it to flip to true
            local t0 = os.clock()
            while os.clock() - t0 < 3 do
                if not autofarmActive or not isSinglePlayer() then
                    return false
                end
                if dungeonStarted.Value == true then
                    return true
                end
                task.wait(0.1)
            end
            -- Even if it hasn't flipped yet, proceed; loop will continue working
            return true
        end
        task.wait(0.1)
    end
end

-- ==================== Movement / Traveling =====================
local Travel = {
    SnapDist = 2.0,
    StepDist = 25,     -- teleport step distance
    StepDelay = 0.015, -- delay between steps for smoothness
}

local function cframeStepTravel(targetPos, faceDown)
    if not root then return end
    setCharacterCanCollide(false)
    local function cleanup() setCharacterCanCollide(true) end

    local ok, err = pcall(function()
        local function moveOnce(toPos)
            local look = faceDown and (toPos + Vector3.new(0, -1, 0)) or (toPos + Vector3.new(0, 0, -1))
            root.CFrame = CFrame.new(toPos, look)
            root.AssemblyLinearVelocity = Vector3.new()
            root.AssemblyAngularVelocity = Vector3.new()
        end

        local pos = root.Position
        local dir = (targetPos - pos)
        local dist = dir.Magnitude
        if dist <= Travel.SnapDist then
            moveOnce(targetPos)
            return
        end
        dir = dir.Unit
        local steps = math.ceil(dist / Travel.StepDist)
        for i = 1, steps do
            local stepTarget
            if i < steps then
                stepTarget = pos + dir * (i * Travel.StepDist)
                stepTarget = Vector3.new(stepTarget.X, targetPos.Y, stepTarget.Z)
            else
                stepTarget = targetPos
            end
            moveOnce(stepTarget)
            task.wait(Travel.StepDelay)
        end
    end)
    cleanup()
    if not ok then warn("cframeStepTravel error:", err) end
end

local function karateTravelTo(targetPos, hover)
    cframeStepTravel(targetPos, hover)
end

-- ===================== Enemy/Combat Logic ======================
local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:WaitForChild("Enemies")

local function isValidEnemy(m)
    if not m or not m.Parent then return false end
    if m.Parent ~= enemiesFolder then return false end
    local h = m:FindFirstChild("Humanoid")
    local hrp = m:FindFirstChild("HumanoidRootPart")
    if not h or not hrp then return false end
    if h.Health <= 0 then return false end
    return true
end

local function getAliveEnemies()
    local alive = {}
    for _, m in ipairs(enemiesFolder:GetChildren()) do
        if isValidEnemy(m) then table.insert(alive, m) end
    end
    return alive
end

local function getNearestEnemy(fromPos)
    local nearest, dmin = nil, math.huge
    for _, e in ipairs(getAliveEnemies()) do
        local hrp = e.HumanoidRootPart
        local d = (fromPos - hrp.Position).Magnitude
        if d < dmin then dmin, nearest = d, e end
    end
    return nearest
end

-- ===================== Health and Platform =====================
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
    root.CFrame = CFrame.new(above)
    root.AssemblyLinearVelocity = Vector3.new()
end

local function shouldPauseForHealth()
    if not safetyEnabled then return false end
    if not humanoid or humanoid.MaxHealth == 0 then return false end
    return humanoid.Health / humanoid.MaxHealth < (lowHealthThreshold or 0.45)
end

local function shouldResumeForHealth()
    if not humanoid or humanoid.MaxHealth == 0 then return true end
    local resumeThreshold = math.max((lowHealthThreshold or 0.45) + 0.05, 0.10)
    return humanoid.Health / humanoid.MaxHealth > resumeThreshold
end

-- ========================= Behavior ============================
local SPELLS = {"Q", "E"}

local function hoverTopDown(enemy, height)
    while isValidEnemy(enemy) do
        if not autofarmActive then break end
        if not humanoid or not root then break end
        local targetPos = enemy.HumanoidRootPart.Position + Vector3.new(0, height, 0)
        cframeStepTravel(targetPos, true)
        task.wait(0.02)
    end
end

local function orbitAroundEnemy(enemy, height, radius, speed)
    if not root then return end
    local angle = math.random() * math.pi * 2
    while isValidEnemy(enemy) do
        if not autofarmActive then break end
        if not root then break end
        local base = enemy.HumanoidRootPart.Position
        angle += speed * 0.02
        local offset = Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
        local targetPos = base + offset
        cframeStepTravel(targetPos, false)
        -- face the enemy
        root.CFrame = CFrame.new(root.Position, base)
        task.wait(0.02)
    end
end

-- ======================= GUI Interaction =======================

local function refreshButtons()
    local enabledColor = Color3.fromRGB(50, 100, 50)
    local disabledColor = Color3.fromRGB(100, 50, 50)
    autofarmToggle.BackgroundColor3 = autofarmActive and enabledColor or disabledColor
    autospellToggle.BackgroundColor3 = autospellActive and Color3.fromRGB(50, 50, 100) or disabledColor
    orbitToggle.BackgroundColor3 = orbitEnabled and enabledColor or disabledColor
    safetyToggle.BackgroundColor3 = safetyEnabled and enabledColor or disabledColor

    autofarmToggle.Text = "Autofarm: " .. (autofarmActive and "ON" or "OFF")
    autospellToggle.Text = "Autospell: " .. (autospellActive and "ON" or "OFF")
    orbitToggle.Text = "Orbit: " .. (orbitEnabled and "ON" or "OFF")
    safetyToggle.Text = "Safety Platform: " .. (safetyEnabled and "ON" or "OFF")
end
refreshButtons()

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
    setBtn(safetyToggle, allow)
    heightBox.TextEditable = allow
    radiusBox.TextEditable = allow
    speedBox.TextEditable = allow
    lowHPBox.TextEditable = allow
end

local function enforceSinglePlayer()
    if isSinglePlayer() then
        healthLabel.Text = ""
        lockControls(false)
    else
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
    if not autofarmActive then deflingStabilize() end
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
safetyToggle.MouseButton1Click:Connect(function()
    if not isSinglePlayer() then return end
    safetyEnabled = not safetyEnabled
    config.safetyEnabled = safetyEnabled
    saveConfig(config)
    refreshButtons()
end)

heightBox.FocusLost:Connect(function()
    if not isSinglePlayer() then heightBox.Text = tostring(heightAboveEnemy) return end
    local v = tonumber(heightBox.Text)
    if v and v >= 0 then
        heightAboveEnemy = v
        config.heightAboveEnemy = v
        saveConfig(config)
    end
    heightBox.Text = tostring(heightAboveEnemy)
end)
radiusBox.FocusLost:Connect(function()
    if not isSinglePlayer() then radiusBox.Text = tostring(orbitRadius) return end
    local v = tonumber(radiusBox.Text)
    if v and v >= 1 then
        orbitRadius = v
        config.orbitRadius = v
        saveConfig(config)
    end
    radiusBox.Text = tostring(orbitRadius)
end)
speedBox.FocusLost:Connect(function()
    if not isSinglePlayer() then speedBox.Text = tostring(orbitSpeed) return end
    local v = tonumber(speedBox.Text)
    if v and v > 0 then
        orbitSpeed = v
        config.orbitSpeed = v
        saveConfig(config)
    end
    speedBox.Text = tostring(orbitSpeed)
end)
lowHPBox.FocusLost:Connect(function()
    if not isSinglePlayer() then lowHPBox.Text = tostring(math.floor((lowHealthThreshold or 0.45)*100)) return end
    local v = tonumber(lowHPBox.Text)
    if v then
        v = math.clamp(math.floor(v + 0.5), 1, 99)
        lowHealthThreshold = v / 100
        config.lowHealthThreshold = lowHealthThreshold
        saveConfig(config)
    end
    lowHPBox.Text = tostring(math.floor((lowHealthThreshold or 0.45)*100))
end)

-- ========================= Main Loops ==========================
local currentTarget
local lastTargetName
local pausedForHealth = false

local RETARGET_IF_TOO_FAR = false
local RETARGET_DISTANCE = 250
local NEARBY_BETTER_DISTANCE = 50

local function maybeAcquireTarget()
    if not root then return nil end
    return getNearestEnemy(root.Position)
end

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
                -- Ensure dungeon meets the condition: if not started and solo, start it, then proceed.
                local okToProceed = waitForSoloAndStartDungeonIfNeeded()
                if not okToProceed then
                    task.wait(0.3)
                else
                    if not isValidEnemy(currentTarget) then
                        currentTarget = maybeAcquireTarget()
                    else
                        if RETARGET_IF_TOO_FAR and currentTarget then
                            local d = (root.Position - currentTarget.HumanoidRootPart.Position).Magnitude
                            if d > RETARGET_DISTANCE then
                                local alt = maybeAcquireTarget()
                                if alt and (root.Position - alt.HumanoidRootPart.Position).Magnitude < NEARBY_BETTER_DISTANCE then
                                    currentTarget = alt
                                end
                            end
                        end
                    end

                    local enemy = currentTarget
                    if isValidEnemy(enemy) then
                        lastTargetName = enemy.Name
                        local goal = enemy.HumanoidRootPart.Position + Vector3.new(0, heightAboveEnemy, 0)
                        karateTravelTo(goal, true)

                        if isValidEnemy(enemy) and autofarmActive and not pausedForHealth then
                            if orbitEnabled then
                                orbitAroundEnemy(enemy, heightAboveEnemy, orbitRadius, orbitSpeed)
                            else
                                hoverTopDown(enemy, heightAboveEnemy)
                            end
                        end
                    else
                        task.wait(0.3)
                    end
                end
             else
                task.wait(0.4)
            end
        end

        local name = lastTargetName or ((isValidEnemy(currentTarget) and currentTarget.Name) or "None")
        infoLabel.Text = string.format(
            "Target: %s\nAutofarm: %s | Autospell: %s | Orbit: %s | Safety: %s\nHeight:%d  Radius:%d  Speed:%.2f  LowHP:%d%%",
            name,
            autofarmActive and "ON" or "OFF",
            autospellActive and "ON" or "OFF",
            orbitEnabled and "ON" or "OFF",
            safetyEnabled and "ON" or "OFF",
            heightAboveEnemy, orbitRadius, orbitSpeed, math.floor((lowHealthThreshold or 0.45) * 100 + 0.5)
        )
    end
end)

task.spawn(function()
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("useSpell")
    while true do
        if autospellActive and remote and isSinglePlayer() and not pausedForHealth then
            for _, key in ipairs(SPELLS) do
                if not autospellActive or pausedForHealth then break end
                pcall(function() remote:FireServer(key) end)
                task.wait(0.1)
            end
        else
            task.wait(0.2)
        end
    end
end)

player.CharacterAdded:Connect(function()
    task.delay(0.2, deflingStabilize)
end)
