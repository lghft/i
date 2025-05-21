-- Macro Recorder/Player with Enhanced Gregg Detection
repeat wait(6) until game:IsLoaded()
wait(16)

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")

-- State Variables
local isRecording = false
local isPlaying = false
local currentRecording = {}
local recordingStartTime = 0
local recordingConnection = nil
local selectedMacro = nil
local stopPlaying = nil
local greggDetected = false
local macroPaused = false
local pauseTime = 0

-- Configuration
local config = {
    manualPlayEnabled = false,
    selectedMacro = nil,
    windowPosition = {x = 0, y = 0.5} -- Left side by default
}

-- Utility Functions
local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function loadConfig()
    if isfile("MacroTesting/config.json") then
        local success, loaded = pcall(function()
            return HttpService:JSONDecode(readfile("MacroTesting/config.json"))
        end)
        if success then
            config = loaded
            config.manualPlayEnabled = config.manualPlayEnabled or false
            config.windowPosition.x = 0 -- Force left side
        end
    end
end

local function saveConfig()
    config.windowPosition.x = 0 -- Lock to left side
    writefile("MacroTesting/config.json", HttpService:JSONEncode(config))
end

-- Setup folders
if not isfolder("MacroTesting") then makefolder("MacroTesting") end
if not isfolder("MacroTesting/Macros") then makefolder("MacroTesting/Macros") end
loadConfig()

-- Prediction System
local Prediction = {
    History = {},
    SampleRate = 0.1,
    PREDICTION_FRAMES = 10
}

local function PredictPosition(enemy, frames)
    if not Prediction.History[enemy] then return enemy:GetPivot().Position end
    local velocity = Vector3.new()
    local samples = math.min(#Prediction.History[enemy], 5)
    
    for i = 1, samples-1 do
        local delta = Prediction.History[enemy][i] - Prediction.History[enemy][i+1]
        velocity = velocity + (delta / Prediction.SampleRate)
    end
    velocity = velocity / samples
    
    return enemy:GetPivot().Position + (velocity * frames * Prediction.SampleRate)
end

local function UpdatePredictionHistory(enemy)
    if not Prediction.History[enemy] then Prediction.History[enemy] = {} end
    table.insert(Prediction.History[enemy], 1, enemy:GetPivot().Position)
    if #Prediction.History[enemy] > 10 then table.remove(Prediction.History[enemy]) end
end

-- Enemy Handling
local function isEnemyAlive(enemy)
    if not enemy:FindFirstChild("HumanoidRootPart") then return false end
    local enemyHumanoid = enemy:FindFirstChild("Humanoid")
    return not (enemyHumanoid and enemyHumanoid.Health <= 0)
end

local function findGregg()
    local dungeon = Workspace:FindFirstChild("dungeon")
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

-- Movement Functions
local function SafeTeleport(position)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
    character.HumanoidRootPart.CFrame = CFrame.new(position)
    return true
end

local function ComputePath(target)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 2
    })
    path:ComputeAsync(LocalPlayer.Character:GetPivot().Position, PredictPosition(target, Prediction.PREDICTION_FRAMES))
    return path
end

local function EnhancedMoveToGregg(gregg)
    if not gregg or not gregg:FindFirstChild("HumanoidRootPart") then return false end
    
    local path = ComputePath(gregg)
    if not path or path.Status ~= Enum.PathStatus.Success then return false end

    for _, waypoint in ipairs(path:GetWaypoints()) do
        if not isEnemyAlive(gregg) then return false end
        
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            SafeTeleport(waypoint.Position + Vector3.new(0, 5, 0))
        else
            SafeTeleport(waypoint.Position)
        end
        
        UpdatePredictionHistory(gregg)
        task.wait(0.1)
    end
    return true
end

-- Recording Functions
local function startRecording()
    print("Starting recording...")
    if isPlaying or isRecording then 
        warn("Cannot start recording - already playing or recording")
        return 
    end
    if not selectedMacro then 
        warn("No macro selected for recording")
        return 
    end
    
    currentRecording = {}
    isRecording = true
    recordingStartTime = tick()
    RecordButton.Text = "⏹ STOP REC"
    RecordButton.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    
    recordingConnection = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
            table.insert(currentRecording, {
                time = tick() - recordingStartTime,
                position = char.HumanoidRootPart.Position,
                moveDirection = char.Humanoid.MoveDirection
            })
        end
    end)
end

local function stopRecording()
    print("Stopping recording...")
    if not isRecording then
        warn("No active recording to stop")
        return
    end
    
    if recordingConnection then
        recordingConnection:Disconnect()
        recordingConnection = nil
    end
    
    isRecording = false
    RecordButton.Text = "⏺ RECORD"
    RecordButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
    
    if #currentRecording > 0 then
        local fileName = "MacroTesting/Macros/"..selectedMacro..".json"
        writefile(fileName, HttpService:JSONEncode(currentRecording))
        refreshMacroList()
    end
end

-- Playback Functions
local function lerpVector3(a, b, alpha)
    return Vector3.new(
        a.X + (b.X - a.X) * alpha,
        a.Y + (b.Y - a.Y) * alpha,
        a.Z + (b.Z - a.Z) * alpha
    )
end

local function startPlaying(manualTrigger, resumeTime)
    if isPlaying or isRecording then return end
    if not selectedMacro then return end
    
    local fileName = "MacroTesting/Macros/"..selectedMacro..".json"
    if not isfile(fileName) then return end
    
    if manualTrigger then
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        local timeLeftGui = playerGui:FindFirstChild("timeLeftGui")
        
        if not timeLeftGui or not timeLeftGui.Enabled then
            PlayButton.Text = "⏳ WAITING..."
            PlayButton.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
            
            local startWait = tick()
            repeat
                wait(0.1)
                timeLeftGui = playerGui:FindFirstChild("timeLeftGui")
            until (timeLeftGui and timeLeftGui.Enabled) or (tick() - startWait > 10)
            
            if not timeLeftGui or not timeLeftGui.Enabled then
                PlayButton.Text = config.manualPlayEnabled and "✅ MANUAL PLAY" or "▶ MANUAL PLAY"
                PlayButton.BackgroundColor3 = config.manualPlayEnabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 60, 60)
                return
            end
        end
    end
    
    local success, macroData = pcall(function()
        return HttpService:JSONDecode(readfile(fileName))
    end)
    
    if not success or not macroData or #macroData == 0 then return end
    
    isPlaying = true
    local playbackStartTime = tick() - (resumeTime or 0)
    local playbackIndex = 1
    PlayButton.Text = "⏹ STOP PLAY"
    PlayButton.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
    
    local connection = RunService.Heartbeat:Connect(function()
        if not isPlaying then
            connection:Disconnect()
            return
        end
        
        local currentTime = tick() - playbackStartTime
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        while playbackIndex <= #macroData and macroData[playbackIndex].time <= currentTime do
            playbackIndex = playbackIndex + 1
        end
        
        if playbackIndex > #macroData then
            isPlaying = false
            PlayButton.Text = config.manualPlayEnabled and "✅ MANUAL PLAY" or "▶ MANUAL PLAY"
            PlayButton.BackgroundColor3 = config.manualPlayEnabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 60, 60)
            return
        end
        
        if playbackIndex > 1 then
            local prevFrame = macroData[playbackIndex - 1]
            local nextFrame = macroData[playbackIndex]
            local alpha = (currentTime - prevFrame.time) / (nextFrame.time - prevFrame.time)
            local position = lerpVector3(
                Vector3.new(prevFrame.position.x, prevFrame.position.y, prevFrame.position.z),
                Vector3.new(nextFrame.position.x, nextFrame.position.y, nextFrame.position.z),
                alpha
            )
            char.HumanoidRootPart.CFrame = CFrame.new(position)
            
            local moveDir = lerpVector3(
                Vector3.new(prevFrame.moveDirection.x, prevFrame.moveDirection.y, prevFrame.moveDirection.z),
                Vector3.new(nextFrame.moveDirection.x, nextFrame.moveDirection.y, nextFrame.moveDirection.z),
                alpha
            )
            char.Humanoid:Move(moveDir)
        end
    end)
    
    stopPlaying = function()
        isPlaying = false
        connection:Disconnect()
        PlayButton.Text = config.manualPlayEnabled and "✅ MANUAL PLAY" or "▶ MANUAL PLAY"
        PlayButton.BackgroundColor3 = config.manualPlayEnabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 60, 60)
    end
end

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MacroGui"
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 450)
MainFrame.Position = UDim2.new(0, 10, config.windowPosition.y, -225)
MainFrame.AnchorPoint = Vector2.new(0, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "MACRO RECORDER (Drag Here)"
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = MainFrame

-- Macro List Container
local ListContainer = Instance.new("Frame")
ListContainer.Size = UDim2.new(1, -20, 0, 250)
ListContainer.Position = UDim2.new(0, 10, 0, 50)
ListContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ListContainer.BorderSizePixel = 0
ListContainer.Parent = MainFrame

local ListTitle = Instance.new("TextLabel")
ListTitle.Size = UDim2.new(1, 0, 0, 25)
ListTitle.Position = UDim2.new(0, 0, 0, 0)
ListTitle.Text = "SAVED MACROS"
ListTitle.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
ListTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
ListTitle.Font = Enum.Font.Gotham
ListTitle.TextSize = 14
ListTitle.TextXAlignment = Enum.TextXAlignment.Left
ListTitle.Parent = ListContainer

local TitlePadding = Instance.new("UIPadding")
TitlePadding.PaddingLeft = UDim.new(0, 10)
TitlePadding.Parent = ListTitle

local MacroList = Instance.new("ScrollingFrame")
MacroList.Size = UDim2.new(1, 0, 1, -25)
MacroList.Position = UDim2.new(0, 0, 0, 25)
MacroList.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
MacroList.BorderSizePixel = 0
MacroList.ScrollBarThickness = 6
MacroList.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
MacroList.CanvasSize = UDim2.new(0, 0, 0, 0)
MacroList.AutomaticCanvasSize = Enum.AutomaticSize.Y
MacroList.Parent = ListContainer

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 2)
UIListLayout.Parent = MacroList

-- Control Buttons
local buttonYOffset = 310
local buttonWidth = 0.45
local buttonSpacing = 0.525

local RefreshButton = Instance.new("TextButton")
RefreshButton.Size = UDim2.new(buttonWidth, 0, 0, 35)
RefreshButton.Position = UDim2.new(0.025, 0, 0, buttonYOffset)
RefreshButton.Text = "🔄 REFRESH"
RefreshButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
RefreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshButton.Font = Enum.Font.GothamBold
RefreshButton.TextSize = 14
RefreshButton.Parent = MainFrame

local DeleteButton = Instance.new("TextButton")
DeleteButton.Size = UDim2.new(buttonWidth, 0, 0, 35)
DeleteButton.Position = UDim2.new(buttonSpacing, 0, 0, buttonYOffset)
DeleteButton.Text = "❌ DELETE"
DeleteButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
DeleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DeleteButton.Font = Enum.Font.GothamBold
DeleteButton.TextSize = 14
DeleteButton.Parent = MainFrame

-- New Macro Creation
local NewMacroFrame = Instance.new("Frame")
NewMacroFrame.Size = UDim2.new(1, -20, 0, 70)
NewMacroFrame.Position = UDim2.new(0, 10, 0, 355)
NewMacroFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
NewMacroFrame.BorderSizePixel = 0
NewMacroFrame.Parent = MainFrame

local MacroNameBox = Instance.new("TextBox")
MacroNameBox.Size = UDim2.new(0.65, 0, 0, 35)
MacroNameBox.Position = UDim2.new(0, 5, 0, 5)
MacroNameBox.PlaceholderText = "Enter Macro Name..."
MacroNameBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
MacroNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
MacroNameBox.Font = Enum.Font.Gotham
MacroNameBox.TextSize = 14
MacroNameBox.Parent = NewMacroFrame

local CreateButton = Instance.new("TextButton")
CreateButton.Size = UDim2.new(0.3, 0, 0, 35)
CreateButton.Position = UDim2.new(0.675, 0, 0, 5)
CreateButton.Text = "➕ CREATE"
CreateButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
CreateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CreateButton.Font = Enum.Font.GothamBold
CreateButton.TextSize = 14
CreateButton.Parent = NewMacroFrame

-- Action Buttons
local RecordButton = Instance.new("TextButton")
RecordButton.Size = UDim2.new(buttonWidth, 0, 0, 40)
RecordButton.Position = UDim2.new(0.025, 0, 0, 400)
RecordButton.Text = "⏺ RECORD"
RecordButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
RecordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RecordButton.Font = Enum.Font.GothamBold
RecordButton.TextSize = 16
RecordButton.Parent = MainFrame

local PlayButton = Instance.new("TextButton")
PlayButton.Size = UDim2.new(buttonWidth, 0, 0, 40)
PlayButton.Position = UDim2.new(buttonSpacing, 0, 0, 400)
PlayButton.Text = config.manualPlayEnabled and "✅ MANUAL PLAY" or "▶ MANUAL PLAY"
PlayButton.BackgroundColor3 = config.manualPlayEnabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 60, 60)
PlayButton.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayButton.Font = Enum.Font.GothamBold
PlayButton.TextSize = 16
PlayButton.Parent = MainFrame

-- Draggable GUI
local dragging = false
local dragStart, startPos

local function updateInput(input)
    local delta = input.Position - dragStart
    local newY = math.clamp(startPos.Y + delta.Y, 0, 1)
    MainFrame.Position = UDim2.new(0, 10, newY, -225)
    config.windowPosition = {x = 0, y = newY}
    saveConfig()
end

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position.Y.Scale
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateInput(input)
    end
end)

-- Macro List Functions
local function createMacroButton(macroName)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 35)
    button.Text = macroName
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.Parent = MacroList
    
    local buttonPadding = Instance.new("UIPadding")
    buttonPadding.PaddingLeft = UDim.new(0, 15)
    buttonPadding.Parent = button
    
    button.MouseButton1Click:Connect(function()
        if selectedMacro == macroName then
            button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            selectedMacro = nil
            config.selectedMacro = nil
            saveConfig()
            return
        end
        
        for _, otherButton in ipairs(MacroList:GetChildren()) do
            if otherButton:IsA("TextButton") then
                otherButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
        end
        
        button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        selectedMacro = macroName
        config.selectedMacro = macroName
        saveConfig()
    end)
    
    return button
end

local function refreshMacroList()
    for _, child in ipairs(MacroList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local success, files = pcall(function()
        local allFiles = listfiles("MacroTesting/Macros")
        local macroFiles = {}
        for _, filePath in ipairs(allFiles) do
            local fileName = filePath:match("^.+\\(.+).json$") or filePath:match("^.+/(.+).json$")
            if fileName then
                table.insert(macroFiles, fileName)
            end
        end
        return macroFiles
    end)
    
    if not success or #files == 0 then
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 0, 30)
        label.Text = success and "No macros found" or "Error loading macros"
        label.TextColor3 = success and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(255, 100, 100)
        label.BackgroundTransparency = 1
        label.Parent = MacroList
    else
        table.sort(files)
        for _, fileName in ipairs(files) do
            local button = createMacroButton(fileName)
            if fileName == config.selectedMacro then
                button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                selectedMacro = fileName
            end
        end
    end
end

-- Button Connections
RefreshButton.MouseButton1Click:Connect(refreshMacroList)

DeleteButton.MouseButton1Click:Connect(function()
    if not selectedMacro then return end
    local fileName = "MacroTesting/Macros/"..selectedMacro..".json"
    if isfile(fileName) then
        delfile(fileName)
        selectedMacro = nil
        config.selectedMacro = nil
        saveConfig()
        refreshMacroList()
    end
end)

CreateButton.MouseButton1Click:Connect(function()
    local macroName = trim(MacroNameBox.Text)
    if macroName == "" then return end
    
    macroName = macroName:gsub("[^%w%s_-]", ""):gsub("%s+", " ")
    if macroName == "" then return end
    
    local fileName = "MacroTesting/Macros/"..macroName..".json"
    if not isfile(fileName) then
        writefile(fileName, "[]")
        selectedMacro = macroName
        config.selectedMacro = macroName
        MacroNameBox.Text = ""
        saveConfig()
        refreshMacroList()
    else
        warn("Macro already exists")
    end
end)

RecordButton.MouseButton1Click:Connect(function()
    if isRecording then
        stopRecording()
    else
        startRecording()
    end
end)

PlayButton.MouseButton1Click:Connect(function()
    if isPlaying then
        if stopPlaying then stopPlaying() end
    else
        config.manualPlayEnabled = true
        saveConfig()
        PlayButton.Text = "✅ MANUAL PLAY"
        PlayButton.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
        stopPlaying = startPlaying(true)
    end
end)

-- Initialize
if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
local humanoid = LocalPlayer.Character:WaitForChild("Humanoid")

-- Movement tracking
humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
    if humanoid.MoveDirection.Magnitude > 0.1 then
        lastMovementTime = tick()
    end
end)

-- Start systems
refreshMacroList()

-- Auto-start if enabled
if config.manualPlayEnabled and selectedMacro then
    coroutine.wrap(function()
        wait(2)
        stopPlaying = startPlaying(true)
    end)()
end

-- Cleanup
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Delete then
        ScreenGui:Destroy()
    end
end)

-- Character respawn handling
LocalPlayer.CharacterAdded:Connect(function(character)
    humanoid = character:WaitForChild("Humanoid")
    humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
        if humanoid.MoveDirection.Magnitude > 0.1 then
            lastMovementTime = tick()
        end
    end)
    
    if isPlaying then
        if stopPlaying then stopPlaying() end
        wait(1)
        if config.manualPlayEnabled and not isPlaying and not isRecording then
            stopPlaying = startPlaying(true)
        end
    end
end)

print("Macro Recorder initialized successfully")
