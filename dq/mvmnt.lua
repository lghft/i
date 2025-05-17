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
    for _, folder in pairs(Workspace:GetDescendants()) do
        if folder.Name == "enemyFolder" then
            for _, enemy in pairs(folder:GetChildren()) do
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
        SafeTeleport(waypoint.Position + (waypoint.Action == Enum.PathWaypointAction.Jump and Vector3.new(0,5,0) or Vector3.zero))
        UpdatePredictionHistory(gregg)
        task.wait(0.025)
    end
    return true
end

-- Gregg Handling
local greggDetected = false
local macroPaused = false
local pauseTime = 0
local greggConnection = nil

local function handleGregg()
    local gregg = findGregg()
    if gregg and isPlaying and not greggDetected then
        greggDetected = true
        macroPaused = true
        pauseTime = tick() - playbackStartTime
        
        if stopPlaying then stopPlaying() end
        
        if EnhancedMoveToGregg(gregg) then
            local greggDefeated = false
            greggConnection = gregg.Humanoid.Died:Connect(function() greggDefeated = true end)
            
            while not greggDefeated and isEnemyAlive(gregg) do
                UpdatePredictionHistory(gregg)
                SafeTeleport(PredictPosition(gregg, Prediction.PREDICTION_FRAMES))
                wait(0.5)
            end
            
            if greggConnection then greggConnection:Disconnect() end
        end
        
        greggDetected = false
        macroPaused = false
        if config.manualPlayEnabled then
            stopPlaying = startPlaying(true, pauseTime)
        end
    end
end

-- Macro Management
local isRecording = false
local isPlaying = false
local selectedMacro = nil
local currentRecording = {}
local recordingStartTime = 0
local playbackStartTime = 0
local playbackIndex = 1
local stopRecording = nil
local stopPlaying = nil

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
    
    local files = {}
    local success, result = pcall(function()
        return listfiles("MacroTesting/Macros")
    end)
    
    if success then
        for _, filePath in ipairs(result) do
            local fileName = filePath:match("^.+\\(.+)%.json$") or filePath:match("^.+/(.+)%.json$")
            if fileName then
                table.insert(files, fileName)
            end
        end
    else
        warn("Failed to list macro files: "..tostring(result))
    end
    
    if #files == 0 then
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 0, 30)
        label.Text = "No macros found"
        label.TextColor3 = Color3.fromRGB(200, 200, 200)
        label.BackgroundTransparency = 1
        label.Parent = MacroList
    else
        table.sort(files)
        for _, fileName in ipairs(files) do
            createMacroButton(fileName)
        end
    end
end

local function startRecording()
    if isPlaying or isRecording then return end
    if not selectedMacro then return end
    
    isRecording = true
    currentRecording = {}
    recordingStartTime = tick()
    
    local connection = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            table.insert(currentRecording, {
                time = tick() - recordingStartTime,
                position = char.HumanoidRootPart.Position,
                moveDirection = char.Humanoid.MoveDirection
            })
        end
    end)
    
    stopRecording = function()
        connection:Disconnect()
        isRecording = false
        writefile("MacroTesting/Macros/"..selectedMacro..".json", HttpService:JSONEncode(currentRecording))
        refreshMacroList()
    end
end

local function startPlaying(manualTrigger, resumeTime)
    if isPlaying or isRecording then return end
    if not selectedMacro then return end
    
    local fileName = "MacroTesting/Macros/"..selectedMacro..".json"
    if not isfile(fileName) then return end
    
    local success, macroData = pcall(function()
        return HttpService:JSONDecode(readfile(fileName))
    end)
    
    if not success or not macroData then return end
    
    isPlaying = true
    playbackStartTime = tick() - (resumeTime or 0)
    playbackIndex = 1
    
    local connection = RunService.Heartbeat:Connect(function()
        if not isPlaying then
            connection:Disconnect()
            return
        end
        
        -- Handle Gregg detection
        if tick() - lastGreggCheck > greggCheckInterval then
            lastGreggCheck = tick()
            coroutine.wrap(handleGregg)()
        end
        
        if greggDetected then return end
        
        local currentTime = tick() - playbackStartTime
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        while playbackIndex <= #macroData and macroData[playbackIndex].time <= currentTime do
            playbackIndex = playbackIndex + 1
        end
        
        if playbackIndex > #macroData then
            isPlaying = false
            return
        end
        
        local prevFrame = macroData[playbackIndex - 1]
        local nextFrame = macroData[playbackIndex]
        
        if prevFrame and nextFrame then
            local alpha = (currentTime - prevFrame.time) / (nextFrame.time - prevFrame.time)
            char.HumanoidRootPart.CFrame = CFrame.new(
                prevFrame.position:Lerp(nextFrame.position, alpha)
            )
            char.Humanoid:Move(prevFrame.moveDirection:Lerp(nextFrame.moveDirection, alpha))
        end
    end)
    
    stopPlaying = function()
        isPlaying = false
        connection:Disconnect()
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

-- [Include all other GUI elements here following the same pattern]

-- Idle Detection
local lastMovementTime = tick()
local lastGreggCheck = 0
local greggCheckInterval = 1
local idleThreshold = 60 -- 1 minute

local function checkIdle()
    while true do
        wait(5)
        if not isPlaying and config.manualPlayEnabled and selectedMacro then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                if char.Humanoid.MoveDirection.Magnitude < 0.1 then
                    if tick() - lastMovementTime > idleThreshold then
                        if stopPlaying then stopPlaying() end
                        stopPlaying = startPlaying(true)
                    end
                else
                    lastMovementTime = tick()
                end
            end
        end
    end
end

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
coroutine.wrap(checkIdle)()
refreshMacroList()

-- Auto-start if enabled
if config.manualPlayEnabled and selectedMacro then
    coroutine.wrap(function()
        wait(2)
        stopPlaying = startPlaying(true)
    end)()
end
