
--[[
    Roblox Macro Recorder/Player (Navy Sleek UI, Autoplay, Gregg Detection)
    - Records player position and MoveDirection
    - Saves/loads macros as JSON files (Synapse X read/write)
    - Stores macros in Workspace/DqmacTest/Macros
    - Sleek, navy/blue GUI: record/play, macro list, textbox, create button, exit button, autoplay toggle
    - Config file for selected macro and autoplay
    - Gregg detection: pauses macro and teleports to Gregg, resumes when Gregg is dead
    - Loads even if only 1 player in the server
    - Teleports player in front of Gregg (not just above) when detected
    - Macro playback only occurs when timeLeftGui.Enabled is true (no toggle)
--]]

repeat wait(6) until game:IsLoaded()
local Players = game:GetService("Players")
while #Players:GetPlayers() < 1 do wait() end
local LocalPlayer = Players.LocalPlayer
repeat wait() until LocalPlayer and LocalPlayer.Character
wait(16)
-- Synapse X file helpers
local FOLDER = "DqmacTest"
local MACRO_FOLDER = FOLDER.."/Macros"
local CONFIG_FILE = FOLDER.."/config.json"

if not isfolder(FOLDER) then makefolder(FOLDER) end
if not isfolder(MACRO_FOLDER) then makefolder(MACRO_FOLDER) end

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Config
local config = {
    selectedMacro = nil,
    autoplay = false,
    windowPos = {x = 0.5, y = 0.5},
    isPlaying = false
}
if isfile(CONFIG_FILE) then
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
    if ok and type(data) == "table" then
        for k,v in pairs(data) do config[k] = v end
    end
end
local function saveConfig()
    writefile(CONFIG_FILE, HttpService:JSONEncode(config))
end

-- Vector3 serialization
local function v3tbl(v)
    return {x = v.X, y = v.Y, z = v.Z}
end
local function tblv3(t)
    return Vector3.new(t.x, t.y, t.z)
end

-- Sleek Navy/Blue UI Colors
local colors = {
    bg = Color3.fromRGB(18, 28, 48),
    panel = Color3.fromRGB(28, 38, 68),
    accent = Color3.fromRGB(0, 120, 255),
    accent2 = Color3.fromRGB(0, 180, 140),
    accent3 = Color3.fromRGB(255, 80, 80),
    text = Color3.fromRGB(220, 230, 245),
    textDim = Color3.fromRGB(120, 140, 170),
    border = Color3.fromRGB(30, 40, 60),
    btn = Color3.fromRGB(24, 34, 54),
    btnHover = Color3.fromRGB(34, 54, 84),
    btnActive = Color3.fromRGB(0, 120, 255),
    toggleOn = Color3.fromRGB(0, 180, 140),
    toggleOff = Color3.fromRGB(40, 50, 70),
    exitBright = Color3.fromRGB(255, 90, 120)
}

local ARIMO = Enum.Font.Arimo

-- GUI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "DqmacMacroGui"
gui.IgnoreGuiInset = true

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 400, 0, 440)
frame.Position = UDim2.new(config.windowPos.x, -200, config.windowPos.y, -220)
frame.BackgroundColor3 = colors.bg
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = false
frame.AnchorPoint = Vector2.new(0.5, 0.5)

local frameCorner = Instance.new("UICorner", frame)
frameCorner.CornerRadius = UDim.new(0, 16)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -48, 0, 44)
title.Position = UDim2.new(0, 16, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Macro Recorder/Player"
title.TextColor3 = colors.text
title.Font = ARIMO
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left

-- Exit button
local exitBtn = Instance.new("TextButton", frame)
exitBtn.Size = UDim2.new(0, 32, 0, 32)
exitBtn.Position = UDim2.new(1, -44, 0, 10)
exitBtn.BackgroundColor3 = colors.btn
exitBtn.Text = "✖"
exitBtn.TextColor3 = colors.exitBright
exitBtn.Font = ARIMO
exitBtn.TextSize = 22
exitBtn.ZIndex = 2
exitBtn.AutoButtonColor = false
exitBtn.BorderSizePixel = 0
local exitCorner = Instance.new("UICorner", exitBtn)
exitCorner.CornerRadius = UDim.new(1, 0)
exitBtn.MouseEnter:Connect(function()
    exitBtn.BackgroundColor3 = colors.btnHover
    exitBtn.TextColor3 = Color3.fromRGB(255, 120, 160)
end)
exitBtn.MouseLeave:Connect(function()
    exitBtn.BackgroundColor3 = colors.btn
    exitBtn.TextColor3 = colors.exitBright
end)

-- Macro List
local macroPanel = Instance.new("Frame", frame)
macroPanel.Size = UDim2.new(0.5, -18, 1, -80)
macroPanel.Position = UDim2.new(0, 16, 0, 56)
macroPanel.BackgroundColor3 = colors.panel
macroPanel.BorderSizePixel = 0
macroPanel.ClipsDescendants = true
local macroPanelCorner = Instance.new("UICorner", macroPanel)
macroPanelCorner.CornerRadius = UDim.new(0, 10)

local macroList = Instance.new("ScrollingFrame", macroPanel)
macroList.Size = UDim2.new(1, 0, 1, -10)
macroList.Position = UDim2.new(0, 0, 0, 6)
macroList.BackgroundTransparency = 1
macroList.BorderSizePixel = 0
macroList.ScrollBarThickness = 5
macroList.CanvasSize = UDim2.new(0,0,0,0)
macroList.AutomaticCanvasSize = Enum.AutomaticSize.Y

local listLayout = Instance.new("UIListLayout", macroList)
listLayout.Padding = UDim.new(0, 4)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Macro creation
local macroNameBox = Instance.new("TextBox", frame)
macroNameBox.Size = UDim2.new(0.5, -28, 0, 36)
macroNameBox.Position = UDim2.new(0.5, 24, 0, 56)
macroNameBox.PlaceholderText = "Macro name..."
macroNameBox.BackgroundColor3 = colors.panel
macroNameBox.TextColor3 = colors.text
macroNameBox.Font = ARIMO
macroNameBox.TextSize = 15
macroNameBox.BorderSizePixel = 0
local macroNameBoxCorner = Instance.new("UICorner", macroNameBox)
macroNameBoxCorner.CornerRadius = UDim.new(0, 8)

local createBtn = Instance.new("TextButton", frame)
createBtn.Size = UDim2.new(0.5, -28, 0, 36)
createBtn.Position = UDim2.new(0.5, 24, 0, 100)
createBtn.Text = "Create Macro"
createBtn.BackgroundColor3 = colors.accent2
createBtn.TextColor3 = Color3.new(1,1,1)
createBtn.Font = ARIMO
createBtn.TextSize = 15
createBtn.BorderSizePixel = 0
local createBtnCorner = Instance.new("UICorner", createBtn)
createBtnCorner.CornerRadius = UDim.new(0, 8)
createBtn.AutoButtonColor = false
createBtn.MouseEnter:Connect(function() createBtn.BackgroundColor3 = colors.btnHover end)
createBtn.MouseLeave:Connect(function() createBtn.BackgroundColor3 = colors.accent2 end)

-- Record/Play buttons
local buttonWidth, buttonHeight, buttonGap = 172, 44, 12
local recordBtn = Instance.new("TextButton", frame)
recordBtn.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
recordBtn.Position = UDim2.new(0.5, 24, 1, -buttonHeight*2-buttonGap-24)
recordBtn.Text = "⏺ Record"
recordBtn.BackgroundColor3 = colors.accent3
recordBtn.TextColor3 = Color3.new(1,1,1)
recordBtn.Font = ARIMO
recordBtn.TextSize = 18
recordBtn.BorderSizePixel = 0
local recordBtnCorner = Instance.new("UICorner", recordBtn)
recordBtnCorner.CornerRadius = UDim.new(0, 8)
recordBtn.AutoButtonColor = false
recordBtn.MouseEnter:Connect(function() recordBtn.BackgroundColor3 = colors.btnHover end)
recordBtn.MouseLeave:Connect(function() recordBtn.BackgroundColor3 = colors.accent3 end)

local playBtn = Instance.new("TextButton", frame)
playBtn.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
playBtn.Position = UDim2.new(0.5, 24, 1, -buttonHeight-24)
playBtn.Text = "▶ Play"
playBtn.BackgroundColor3 = colors.accent2
playBtn.TextColor3 = Color3.new(1,1,1)
playBtn.Font = ARIMO
playBtn.TextSize = 18
playBtn.BorderSizePixel = 0
local playBtnCorner = Instance.new("UICorner", playBtn)
playBtnCorner.CornerRadius = UDim.new(0, 8)
playBtn.AutoButtonColor = false
playBtn.MouseEnter:Connect(function() playBtn.BackgroundColor3 = colors.btnHover end)
playBtn.MouseLeave:Connect(function() playBtn.BackgroundColor3 = colors.accent2 end)

-- Draggable GUI
local dragging = false
local dragStart, startPos
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and input.Position.Y-frame.AbsolutePosition.Y < 44 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
        frame.Position = newPos
        config.windowPos = {
            x = (frame.Position.X.Scale + frame.Position.X.Offset / frame.Parent.AbsoluteSize.X),
            y = (frame.Position.Y.Scale + frame.Position.Y.Offset / frame.Parent.AbsoluteSize.Y)
        }
        saveConfig()
    end
end)

-- Macro file management
local function listMacros()
    local files = {}
    for _,f in ipairs(listfiles(MACRO_FOLDER)) do
        local name = f:match("[/\\]([^/\\]+)%.json$")
        if name then table.insert(files, name) end
    end
    table.sort(files)
    return files
end

local selectedMacro = config.selectedMacro
local function refreshMacroList()
    for _,c in ipairs(macroList:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    for _,name in ipairs(listMacros()) do
        local btn = Instance.new("TextButton", macroList)
        btn.Size = UDim2.new(0, math.floor(macroList.AbsoluteSize.X * 0.85), 0, 32)
        btn.Text = name
        btn.BackgroundColor3 = (name == selectedMacro) and colors.accent or colors.btn
        btn.TextColor3 = (name == selectedMacro) and Color3.new(1,1,1) or colors.text
        btn.Font = ARIMO
        btn.TextSize = 15
        btn.BorderSizePixel = 0
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 6)
        btn.AutoButtonColor = false
        btn.LayoutOrder = _
        btn.AnchorPoint = Vector2.new(0.5, 0)
        btn.Position = UDim2.new(0.5, 0, 0, 0)
        btn.MouseEnter:Connect(function()
            if name ~= selectedMacro then btn.BackgroundColor3 = colors.btnHover end
        end)
        btn.MouseLeave:Connect(function()
            if name ~= selectedMacro then btn.BackgroundColor3 = colors.btn end
        end)
        btn.MouseButton1Click:Connect(function()
            if selectedMacro == name then
                selectedMacro = nil
                config.selectedMacro = nil
            else
                selectedMacro = name
                config.selectedMacro = name
            end
            saveConfig()
            refreshMacroList()
        end)
    end
end

refreshMacroList()

-- Gregg detection helpers
local function isEnemyAlive(enemy)
    local hum = enemy:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function findGregg()
    local dungeon = workspace:FindFirstChild("dungeon")
    if not dungeon then return nil end
    for _, descendant in ipairs(dungeon:GetDescendants()) do
        if descendant.Name == "enemyFolder" then
            for _, enemy in ipairs(descendant:GetChildren()) do
                if enemy:IsA("Model") and enemy.Name == "Gregg" and isEnemyAlive(enemy) then
                    return enemy
                end
            end
        end
    end
    return nil
end

local isRecording, isPlaying = false, false
local currentRecording, recordingStart, recordConn
local playConn, playIndex, playStart, playData

local isPausedForGregg = false
local function keepTeleportingToGregg(gregg)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local greggHRP = gregg and gregg:FindFirstChild("HumanoidRootPart")
    if not hrp or not greggHRP then return end
    local teleporting = true
    coroutine.wrap(function()
        while teleporting and gregg and isEnemyAlive(gregg) and isPlaying do
            local offset = greggHRP.CFrame.LookVector * 4 + Vector3.new(0, 2, 0)
            hrp.CFrame = greggHRP.CFrame + offset
            wait(0.2)
            hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            greggHRP = gregg and gregg:FindFirstChild("HumanoidRootPart")
            if not hrp or not greggHRP then break end
        end
    end)()
end

local function canPlayMacro()
    -- Only play if timeLeftGui exists and is enabled
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local timeLeftGui = playerGui and playerGui:FindFirstChild("timeLeftGui")
    return timeLeftGui and timeLeftGui.Enabled
end

local function startMacroPlayback()
    if isPlaying then return end
    if not selectedMacro then return end
    if not canPlayMacro() then
        playBtn.Text = "▶ Play"
        playBtn.BackgroundColor3 = colors.accent2
        return
    end

    local file = MACRO_FOLDER.."/"..selectedMacro..".json"
    if not isfile(file) then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(file)) end)
    if not ok or type(data) ~= "table" or #data == 0 then return end
    isPlaying = true
    config.isPlaying = true
    saveConfig()
    playData = data
    playIndex = 1
    playStart = tick()
    playBtn.Text = "⏹ Stop"
    playBtn.BackgroundColor3 = colors.btnActive
    isPausedForGregg = false

    playConn = RunService.Heartbeat:Connect(function()
        if not isPlaying then if playConn then playConn:Disconnect() end return end

        -- Gregg detection and pause logic
        if not isPausedForGregg then
            local gregg = findGregg()
            if gregg then
                isPausedForGregg = true
                keepTeleportingToGregg(gregg)
                playBtn.Text = "⏸ Paused (Gregg)"
                playBtn.BackgroundColor3 = colors.accent
                coroutine.wrap(function()
                    while gregg and isEnemyAlive(gregg) and isPlaying do
                        wait(0.5)
                    end
                    if isPlaying then
                        isPausedForGregg = false
                        playBtn.Text = "⏹ Stop"
                        playBtn.BackgroundColor3 = colors.btnActive
                    end
                end)()
                return
            end
        end

        if isPausedForGregg then
            return
        end

        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local now = tick() - playStart
        while playIndex < #playData and playData[playIndex+1].time <= now do
            playIndex = playIndex + 1
        end
        local frame = playData[playIndex]
        if not frame then
            isPlaying = false
            config.isPlaying = false
            saveConfig()
            playBtn.Text = "▶ Play"
            playBtn.BackgroundColor3 = colors.accent2
            playConn:Disconnect()
            return
        end
        char.HumanoidRootPart.CFrame = CFrame.new(tblv3(frame.position))
        char.Humanoid:Move(tblv3(frame.moveDirection))
        if playIndex == #playData then
            isPlaying = false
            config.isPlaying = false
            saveConfig()
            playBtn.Text = "▶ Play"
            playBtn.BackgroundColor3 = colors.accent2
            playConn:Disconnect()
        end
    end)
end

playBtn.MouseButton1Click:Connect(function()
    if isPlaying then
        isPlaying = false
        config.isPlaying = false
        saveConfig()
        if playConn then playConn:Disconnect() end
        playBtn.Text = "▶ Play"
        playBtn.BackgroundColor3 = colors.accent2
        return
    end
    startMacroPlayback()
end)

createBtn.MouseButton1Click:Connect(function()
    local name = macroNameBox.Text:gsub("[^%w_%-]", "")
    if name == "" then return end
    local file = MACRO_FOLDER.."/"..name..".json"
    if not isfile(file) then
        writefile(file, "[]")
        selectedMacro = name
        config.selectedMacro = name
        saveConfig()
        refreshMacroList()
    end
end)

exitBtn.MouseButton1Click:Connect(function()
    config.isPlaying = isPlaying
    saveConfig()
    if isPlaying and playConn then
        isPlaying = false
        playConn:Disconnect()
    end
    if isRecording and recordConn then
        isRecording = false
        recordConn:Disconnect()
    end
    gui:Destroy()
end)

-- Autoplay on script load if enabled and isPlaying is true, but only if timeLeftGui.Enabled is true
coroutine.wrap(function()
    if config.autoplay and config.selectedMacro and config.isPlaying then
        -- Wait for PlayerGui and timeLeftGui to exist and be enabled
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local timeLeftGui = playerGui and playerGui:FindFirstChild("timeLeftGui")
        local waited = 0
        while (not timeLeftGui or not timeLeftGui.Enabled) and waited < 30 do
            wait(0.5)
            waited = waited + 0.5
            playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            timeLeftGui = playerGui and playerGui:FindFirstChild("timeLeftGui")
        end
        if timeLeftGui and timeLeftGui.Enabled then
            startMacroPlayback()
        end
    end
end)()
